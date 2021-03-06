import agg/[rendering_buffer, rasterizer_scanline_aa, scanline_p, renderer_scanline,
  conv_transform, conv_stroke, bspline, ellipse, gsv_text, pixfmt_rgb, color_rgba,
  renderer_base, calc, basics, trans_affine]
import ctrl/slider, ctrl/scale, parseutils, strutils, os, math, platform/support

const
  frameWidth = 800
  frameHeight = 600
  flipY = true
  #default_num_points = 20000

type
  ValueT = uint8

  AtomColor = enum
    atom_color_general
    atom_color_N
    atom_color_O
    atom_color_S
    atom_color_P
    atom_color_halogen

  AtomType = object
    x: float64
    y: float64
    label: string
    charge: int
    colorIdx: AtomColor

  BondType = object
    idx1, idx2: int
    x1, y1, x2, y2: float64
    order: int
    stereo: int
    topology: int

  Molecule = object
    atoms: seq[AtomType]
    bonds: seq[BondType]
    name: string
    avrLen: float64

iterator atom(self: var Molecule): var AtomType =
  for a in mitems(self.atoms):
    yield a

iterator bond(self: var Molecule): var BondType =
  for a in mitems(self.bonds):
    yield a

proc initMolecule(): Molecule =
  result.avrLen = 0
  result.name = ""

proc trimCRLF(str: string): string =
  if str.len == 0: return ""
  let s = skipWhile(str, {0x0D.chr, 0x0A.chr},  0)
  var e = str.len-1
  while e > 0:
    if str[e] in {0x0D.chr, 0x0A.chr}:
      dec e
    else: break
  result = str.substr(s,e)

proc getStr(buf: string, pos, len: int): string =
  var
    i = pos
    s = skipWhile(buf, Whitespace, i)

  inc(i, s)
  var e = parseUntil(buf, result, Whitespace, i)
  inc(i, e)
  if i > pos + len: i = pos + len
  result = buf.substr(pos+s, i-1)

proc getInt(buf: string, pos, len: int): int =
  result = parseInt(getStr(buf, pos, len))

proc getFloat(buf: string, pos, len: int): float64 =
  result = parseFloat(getStr(buf, pos, len))

proc read(self: var Molecule, fd: File): bool =
  var buf: string
  if not fd.readLine(buf): return false
  self.name = trimCRLF(buf)
  if not fd.readLine(buf): return false
  if not fd.readLine(buf): return false
  if not fd.readLine(buf): return false
  buf = trimCRLF(buf)

  var
    numAtoms = getInt(buf, 0, 3)
    numBonds = getInt(buf, 3, 3)

  if numAtoms == 0 or numBonds == 0:
    return false

  self.atoms = newSeq[AtomType](numAtoms)
  self.bonds = newSeq[BondType](numBonds)

  for atom in mitems(self.atoms):
    if not fd.readLine(buf): return false
    buf = trimCRLF(buf)

    atom.x = getFloat(buf, 1,  10)
    atom.y = getFloat(buf, 11, 10)
    atom.label = getStr(buf, 31, 3)
    atom.charge = getInt(buf, 38, 1)

    if atom.charge != 0: atom.charge = 4 - atom.charge

    case atom.label
    of "N": atom.colorIdx = atom_color_N
    of "O": atom.colorIdx = atom_color_O
    of "S": atom.colorIdx = atom_color_S
    of "P": atom.colorIdx = atom_color_P
    of "F", "Cl", "Br", "I": atom.colorIdx = atom_color_halogen
    else: atom.colorIdx = atom_color_general

  self.avrLen = 0.0
  for bond in mitems(self.bonds):
    if not fd.readLine(buf): return false
    buf = trimCRLF(buf)

    bond.idx1 = getInt(buf, 0, 3) - 1
    bond.idx2 = getInt(buf, 3, 3) - 1

    if bond.idx1 >= numAtoms or bond.idx2 >= numAtoms: return false

    bond.x1 = self.atoms[bond.idx1].x
    bond.y1 = self.atoms[bond.idx1].y
    bond.x2 = self.atoms[bond.idx2].x
    bond.y2 = self.atoms[bond.idx2].y

    bond.order    = getInt(buf, 7, 3)
    bond.stereo   = getInt(buf, 10, 3)
    bond.topology = getInt(buf, 13, 3)

    self.avrLen += sqrt((bond.x1 - bond.x2) * (bond.x1 - bond.x2) +
                        (bond.y1 - bond.y2) * (bond.y1 - bond.y2))

  self.avrLen = self.avrLen / float64(numBonds)

  while fd.readLine(buf):
    buf = trimCRLF(buf)
    if buf.len > 0 and buf[0] == '$': return true

  result = false

type
  Line = object
    x1, y1, x2, y2, dx, dy, thickness: float64
    vertex: int

proc initLine(): Line =
  result.x1 = 0.0
  result.y1 = 0.0
  result.x2 = 1.0
  result.y2 = 0.0
  result.thickness = 0.1

#proc initLine(x1, y1, x2, y2, thickness: float64): Line =
#  result.x1 = x1
#  result.y1 = y1
#  result.x2 = x2
#  result.y2 = y2
#  result.thickness = thickness

proc init(self: var Line, x1, y1, x2, y2: float64) =
  self.x1 = x1
  self.y1 = y1
  self.x2 = x2
  self.y2 = y2

proc thick(self: var Line, th: float64) =
  self.thickness = th

proc rewind(self: var Line, pathId: int) =
  calcOrthogonal(self.thickness*0.5, self.x1, self.y1, self.x2, self.y2, self.dx, self.dy)
  self.vertex = 0

proc vertex(self: var Line, x, y: var float64): uint =
  case self.vertex
  of 0:
    x = self.x1 - self.dx
    y = self.y1 - self.dy
    inc self.vertex
    return pathCmdMoveTo
  of 1:
    x = self.x2 - self.dx
    y = self.y2 - self.dy
    inc self.vertex
    return pathCmdLineTo
  of 2:
    x = self.x2 + self.dx
    y = self.y2 + self.dy
    inc self.vertex
    return pathCmdLineTo
  of 3:
    x = self.x1 + self.dx
    y = self.y1 + self.dy
    inc self.vertex
    return pathCmdLineTo
  else: discard
  return pathCmdStop

type
  SolidWedge = object
    x1, y1, x2, y2, dx, dy, thickness: float64
    vertex: int

proc initSolidWedge(): SolidWedge =
  result.x1 = 0.0
  result.y1 = 0.0
  result.x2 = 1.0
  result.y2 = 0.0
  result.thickness = 0.1

#proc initSolidWedge(x1, y1, x2, y2, thickness: float64): SolidWedge =
#  result.x1 = x1
#  result.y1 = y1
#  result.x2 = x2
#  result.y2 = y2
#  result.thickness = thickness

proc init(self: var SolidWedge, x1, y1, x2, y2: float64) =
  self.x1 = x1
  self.y1 = y1
  self.x2 = x2
  self.y2 = y2

proc thick(self: var SolidWedge, th: float64) =
  self.thickness = th

proc rewind(self: var SolidWedge, pathId: int) =
  calcOrthogonal(self.thickness*2.0, self.x1, self.y1, self.x2, self.y2, self.dx, self.dy)
  self.vertex = 0

proc vertex(self: var SolidWedge, x, y: var float64): uint =
  case self.vertex
  of 0:
    x = self.x1
    y = self.y1
    inc self.vertex
    return pathCmdMoveTo
  of 1:
    x = self.x2 - self.dx
    y = self.y2 - self.dy
    inc self.vertex
    return pathCmdLineTo
  of 2:
    x = self.x2 + self.dx
    y = self.y2 + self.dy
    inc self.vertex
    return pathCmdLineTo
  else: discard
  return pathCmdStop

type
  DashedWedge = object
    x1, y1, x2, y2: float64
    xt2, yt2, xt3, yt3: float64
    xd, yd: array[4, float64]
    thickness: float64
    numDashes, vertex: int

proc initDashedWedge(): DashedWedge =
  result.x1 = 0.0
  result.y1 = 0.0
  result.x2 = 1.0
  result.y2 = 0.0
  result.thickness = 0.1
  result.numDashes = 8

#proc initDashedWedge(x1, y1, x2, y2, thickness: float64, numDashes = 8): DashedWedge =
#  result.x1 = x2
#  result.y1 = y2
#  result.x2 = x1
#  result.y2 = y1
#  result.thickness = thickness
#  result.numDashes = numDashes

proc init(self: var DashedWedge, x1, y1, x2, y2: float64) =
  self.x1 = x2
  self.y1 = y2
  self.x2 = x1
  self.y2 = y1

#proc numDash(self: var DashedWedge, nd: int) =
#  self.numDashes = nd

proc thick(self: var DashedWedge, th: float64) =
  self.thickness = th

proc rewind(self: var DashedWedge, pathId: int) =
  var
    dx, dy: float64
  calcOrthogonal(self.thickness*2.0, self.x1, self.y1, self.x2, self.y2, dx, dy)
  self.xt2 = self.x2 - dx
  self.yt2 = self.y2 - dy
  self.xt3 = self.x2 + dx
  self.yt3 = self.y2 + dy
  self.vertex = 0

proc vertex(self: var DashedWedge, x, y: var float64): uint =
  if self.vertex < self.numDashes * 4:
    if (self.vertex mod 4) == 0:
      var
        k1 = float64(self.vertex div 4) / float64(self.numDashes)
        k2 = k1 + 0.4 / float64(self.numDashes)

      self.xd[0] = self.x1 + (self.xt2 - self.x1) * k1
      self.yd[0] = self.y1 + (self.yt2 - self.y1) * k1
      self.xd[1] = self.x1 + (self.xt2 - self.x1) * k2
      self.yd[1] = self.y1 + (self.yt2 - self.y1) * k2
      self.xd[2] = self.x1 + (self.xt3 - self.x1) * k2
      self.yd[2] = self.y1 + (self.yt3 - self.y1) * k2
      self.xd[3] = self.x1 + (self.xt3 - self.x1) * k1
      self.yd[3] = self.y1 + (self.yt3 - self.y1) * k1
      x = self.xd[0]
      y = self.yd[0]
      inc self.vertex
      return pathCmdMoveTo
    else:
      x = self.xd[self.vertex mod 4]
      y = self.yd[self.vertex mod 4]
      inc self.vertex
      return pathCmdLineTo
  result = pathCmdStop

type
  BondStyle = enum
    bond_single
    bond_wedged_solid
    bond_wedged_dashed
    bond_float64
    bond_float64_left
    bond_float64_right
    bond_triple

  BondVertexGenerator = object
    bond: ptr BondType
    thickness: float64
    style: BondStyle
    line1, line2, line3: Line
    solidWedge: SolidWedge
    dashedWedge: DashedWedge
    status: int

proc initBondVertexGenerator(bond: var BondType, thickness: float64): BondVertexGenerator =
  result.bond = bond.addr
  result.thickness = thickness
  result.style = bond_single
  if bond.order == 1:
    if bond.stereo == 1: result.style = bond_wedged_solid
    if bond.stereo == 6: result.style = bond_wedged_dashed
  if bond.order == 2:
    result.style = bond_float64
    if bond.topology == 1: result.style = bond_float64_left
    if bond.topology == 2: result.style = bond_float64_right
  if bond.order == 3: result.style = bond_triple

  result.line1 = initLine()
  result.line2 = initLine()
  result.line3 = initLine()
  result.solidWedge = initSolidWedge()
  result.dashedWedge = initDashedWedge()

  result.line1.thick(thickness)
  result.line2.thick(thickness)
  result.line3.thick(thickness)
  result.solidWedge.thick(thickness)
  result.dashedWedge.thick(thickness)

proc rewind(self: var BondVertexGenerator, pathId: int) =
  var
    dx, dy, dx1, dy1, dx2, dy2: float64

  case self.style
  of bond_wedged_solid:
    self.solidWedge.init(self.bond.x1, self.bond.y1, self.bond.x2, self.bond.y2)
    self.solidWedge.rewind(0)
  of bond_wedged_dashed:
    self.dashedWedge.init(self.bond.x1, self.bond.y1, self.bond.x2, self.bond.y2)
    self.dashedWedge.rewind(0)
  of bond_float64, bond_float64_left, bond_float64_right:
    calcOrthogonal(self.thickness, self.bond.x1, self.bond.y1,
      self.bond.x2, self.bond.y2, dx, dy)
    dx1 = 0
    dy1 = 0

    # To Do: ring perception and the proper drawing
    # of the float64 bonds in the aromatic rings.
    #if(self.style == bond_float64)
    dx1 = dx
    dx2 = dx
    dy1 = dy
    dy2 = dy

    self.line1.init(self.bond.x1 - dx1, self.bond.y1 - dy1,
      self.bond.x2 - dx1, self.bond.y2 - dy1)
    self.line1.rewind(0)

    self.line2.init(self.bond.x1 + dx2, self.bond.y1 + dy2,
      self.bond.x2 + dx2, self.bond.y2 + dy2)
    self.line2.rewind(0)
    self.status = 0
  of bond_triple:
    # To Do: triple bonds drawing.
    discard
  else:
    self.line1.init(self.bond.x1, self.bond.y1, self.bond.x2, self.bond.y2)
    self.line1.rewind(0)

proc vertex(self: var BondVertexGenerator, x, y: var float64): uint =
  var flag = pathCmdStop
  case self.style
  of bond_wedged_solid:
    return vertex(self.solidWedge, x, y)
  of bond_wedged_dashed:
    return vertex(self.dashedWedge, x, y)
  of bond_float64_left, bond_float64_right, bond_float64:
    if self.status == 0:
      flag = vertex(self.line1, x, y)
      if flag == pathCmdStop:
        self.status = 1
    if self.status == 1:
      flag = vertex(self.line2, x, y)
    return flag
  of bond_triple:
    discard
  else:
    discard
  return vertex(self.line1, x, y)

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    molecules: seq[Molecule]
    numMolecules: int
    curMolecule: int
    thickness, textSize: SliderCtrl[Rgba8]
    pdx, pdy, centerX, centerY: float64
    scale, prevScale, angle, prevAngle: float64
    mouseMove: bool
    atomColors: array[AtomColor, Rgba8]

proc newApp(format: PixFormat, flipY: bool, name: string): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  var
    startWidth = frameWidth.float64
    startHeight = frameHeight.float64

  result.molecules = newSeq[Molecule](10)
  result.curMolecule = 6
  result.thickness = newSliderCtrl[Rgba8](5, 5,  startWidth-5, 12)
  result.textSize  = newSliderCtrl[Rgba8](5, 20, startWidth-5, 27)
  result.pdx = 0.0
  result.pdy = 0.0
  result.centerX = startWidth / 2.0
  result.centerY = startHeight / 2.0
  result.scale = 1.0
  result.prevScale = 1.0
  result.angle = 0.0
  result.prevAngle = 0.0
  result.mouseMove = false

  result.thickness.label("Thickness=$1")
  result.textSize.label("Label Size=$1")

  result.addCtrl(result.thickness)
  result.addCtrl(result.textSize)

  var name = "resources$1$2" % [$DirSep, name]
  var fd = open(name, fmRead)

  result.numMolecules = 0
  if fd != nil:
    for m in mitems(result.molecules):
      m = initMolecule()
      if not m.read(fd): break
      inc result.numMolecules
    fd.close()
  else:
    echo "file not found"

  zeroMem(addr(result.atomColors[0.AtomColor]), sizeof(result.atomColors))
  result.atomColors[atom_color_general] = initRgba8(0,0,0)
  result.atomColors[atom_color_N]       = initRgba8(0,0,120)
  result.atomColors[atom_color_O]       = initRgba8(200,0,0)
  result.atomColors[atom_color_S]       = initRgba8(120,120,0)
  result.atomColors[atom_color_P]       = initRgba8(80,50,0)
  result.atomColors[atom_color_halogen] = initRgba8(0,200,0)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    ren    = initRendererScanlineAASolid(rb)
    width  = app.width()
    height = app.height()
    mol    = app.molecules[app.curMolecule].addr
    min_x  =  1e100
    max_x  = -1e100
    min_y  =  1e100
    max_y  = -1e100
    mtx    = initTransAffine()

  ras.clipBox(0.0, 0.0, rb.width().float64, rb.height().float64)
  rb.clear(initRgba(1,1,1))

  for atom in mol[].atom:
    if atom.x < min_x: min_x = atom.x
    if atom.y < min_y: min_y = atom.y
    if atom.x > max_x: max_x = atom.x
    if atom.y > max_y: max_y = atom.y

  mtx *= transAffineTranslation(-(max_x + min_x) * 0.5, -(max_y + min_y) * 0.5)

  var
    scale = width / (max_x - min_x)
    t = height / (max_y - min_y)

  if scale > t: scale = t

  var
    textSize = mol.avrLen * app.textSize.value() / 4.0
    thickness = mol.avrLen / sqrt(if app.scale < 0.0001: 0.0001 else: app.scale) / 8.0

  mtx *= transAffineScaling(scale*0.80, scale*0.80)
  mtx *= transAffineRotation(app.angle)
  mtx *= transAffineScaling(app.scale, app.scale)
  mtx *= transAffineTranslation(app.centerX, app.centerY)
  mtx *= transAffineResizing(app)

  ren.color(initRgba(0,0,0))
  for b in mol[].bond:
    var
      bond = initBondVertexGenerator(b, app.thickness.value() * thickness)
      tr   = initConvTransform(bond, mtx)
    ras.addPath(tr)
    renderScanlines(ras, sl, ren)


  var
    ell = initEllipse()
    tr  = initConvTransform(ell, mtx)

  for atom in mol[].atom:
    if atom.label != "C":
      ell.init(atom.x, atom.y, textSize * 2.5, textSize * 2.5, 20)
      ras.addPath(tr)
      ren.color(initRgba(1.0, 1.0, 1.0))
      renderScanlines(ras, sl, ren)


  textSize *= 3.0

  var
    label = initGsvText()
    ls = initConvStroke(label)
    lo = initConvTransform(ls, mtx)

  ls.lineJoin(LineJoin.roundJoin)
  ls.lineCap(LineCap.roundCap)
  ls.approximationScale(mtx.scale())

  for atom in mol[].atom:
    if atom.label != "C":
      ls.width(app.thickness.value() * thickness)
      label.text(atom.label)
      label.startPoint(atom.x - textSize/2, atom.y - textSize/2)
      label.size(textSize)
      ras.addPath(lo)
      ren.color(app.atomColors[atom.colorIdx])
      renderScanlines(ras, sl, ren)


  ls.approximationScale(1.0)

  var name = initConvTransform(ls, transAffineResizing(app))

  ls.width(1.5)
  label.text(mol[].name & "\nPageUp/Up: Prev Mol\nPageDn/Dn: Next Mol" )
  label.size(10.0)
  label.startPoint(10.0, frameHeight - 20.0)
  ras.reset()
  ras.addPath(name)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.thickness)
  renderCtrl(ras, sl, rb, app.textSize)

method onIdle(app: App) =
  app.angle += deg2rad(0.1)
  app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  app.mouseMove = true
  var
    x2 = x.float64
    y2 = y.float64

  app.transAffineResizing().inverseTransform(x2, y2)
  app.pdx = app.centerX - x2
  app.pdy = app.centerY - y2
  app.prevScale = app.scale
  app.prevAngle = app.angle + pi
  app.forceRedraw()

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.mouseMove = false

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x2 = float64(x)
    y2 = float64(y)

  app.transAffineResizing().inverseTransform(x2, y2)

  if app.mouseMove and mouseLeft in flags:
    var
      dx = x2 - app.centerX
      dy = y2 - app.centerY

    app.scale = app.prevScale *
                sqrt(dx * dx + dy * dy) /
                sqrt(app.pdx * app.pdx + app.pdy * app.pdy)

    app.angle = app.prevAngle + arctan2(dy, dx) - arctan2(app.pdy, app.pdx)
    app.forceRedraw()

  if app.mouseMove and mouseRight in flags:
    app.centerX = x2 + app.pdx
    app.centerY = y2 + app.pdy
    app.forceRedraw()

method onKey(app: App, x, y, key: int, flags: InputFlags) =
  if key.KeyCode in {key_left, key_up, key_page_up}:
    if app.curMolecule != 0:
      dec app.curMolecule
      app.forceRedraw()

  if key.KeyCode in {key_right, key_down, key_page_down}:
    if app.curMolecule < app.numMolecules - 1:
      inc app.curMolecule
      app.forceRedraw()

  if key == ' '.ord:
    app.waitMode(not app.waitMode())

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY, "molecule.sdf")
  app.caption("AGG - A Simple SDF Molecular Viewer")

  if app.init(frameWidth, frameHeight, {window_resize}, "mol_view"):
    return app.run()

  result = 1

discard main()
