import agg_rendering_buffer, agg_conv_transform, agg_conv_stroke
import agg_scanline_u, agg_scanline_bin, agg_renderer_scanline, agg_rasterizer_outline_aa
import agg_rasterizer_scanline_aa, agg_span_allocator, agg_span_gouraud_rgba, agg_gamma_lut
import agg_arc, agg_bezier_arc, agg_pixfmt_rgb, agg_pixfmt_rgba, agg_bounding_rect
import ctrl_slider, ctrl_bezier, ctrl_rbox, ctrl_cbox, agg_math
import agg_rasterizer_compound_aa, agg_renderer_base, agg_color_rgba
import random, times, strutils, agg_gsv_text, agg_platform_support

const
  frameWidth = 400
  frameHeight = 400
  flipY = true

type
  ValueT = uint8

  MeshPoint = object
    x,y,dx,dy: float64
    color, dc: Rgba8

  MeshTriangle = object
    p1, p2, p3: int

  MeshEdge = object
    p1, p2: int
    tl, tr: int

proc initMeshPoint(x, y, dx, dy: float64; c, dc: Rgba8): MeshPoint =
  result.x = x
  result.y = y
  result.dx = dx
  result.dy = dy
  result.color = c
  result.dc = dc

proc initMeshTriangle(i, j, k: int): MeshTriangle =
  result.p1 = i
  result.p2 = j
  result.p3 = k

proc initMeshEdge(p1, p2, tl, tr: int): MeshEdge =
  result.p1 = p1
  result.p2 = p2
  result.tl = tl
  result.tr = tr

proc random(v1, v2: float64): float64 =
  result = (v2 - v1) * random(1000.0) / 999.0 + v1

type
  MeshCtrl = object
   cols, rows: int
   dragIdx: int
   dragDx, dragDy: float64
   cellW, cellH: float64
   startX, startY: float64
   vertices: seq[MeshPoint]
   triangles: seq[MeshTriangle]
   edges: seq[MeshEdge]

proc vertex(self: var MeshCtrl, i: int): var MeshPoint =
  self.vertices[i]

proc vertex(self: var MeshCtrl, x, y: int): var MeshPoint =
  self.vertices[y * self.rows + x]

iterator triangle(self: var MeshCtrl): var MeshTriangle =
  for c in mitems(self.triangles):
    yield c

iterator edge(self: var MeshCtrl): var MeshEdge =
  for c in mitems(self.edges):
    yield c

proc initMeshCtrl(): MeshCtrl =
  result.cols = 0
  result.rows = 0
  result.dragIdx = -1
  result.dragDx = 0
  result.dragDy = 0
  result.vertices = @[]
  result.triangles = @[]
  result.edges = @[]

proc generate(self: var MeshCtrl, cols, rows: int, cell_w, cell_h, start_x, start_y: float64) =
  self.cols = cols
  self.rows = rows
  self.cellW = cell_w
  self.cellH = cell_h
  self.startX = start_x
  self.startY = start_y

  self.vertices.setLen(0)
  var y = start_y
  for i in 0.. <self.rows:
    var x = start_x
    for j in 0.. <self.cols:
      let
        dx = random(-0.5, 0.5)
        dy = random(-0.5, 0.5)
        c  = initRgba8(random(0xFF), random(0xFF), random(0xFF))
        dc = initRgba8(random(1), random(1), random(1))
      self.vertices.add(initMeshPoint(x, y, dx, dy, c, dc))
      x += cell_w
    y += cell_h

  #  4---3
  #  |t2/|
  #  | / |
  #  |/t1|
  #  1---2
  self.triangles.setLen(0)
  self.edges.setLen(0)

  for i in 0.. <self.rows - 1:
    for j in 0.. <self.cols - 1:
      var
        p1 = i * self.cols + j
        p2 = p1 + 1
        p3 = p2 + self.cols
        p4 = p1 + self.cols

      self.triangles.add(initMeshTriangle(p1, p2, p3))
      self.triangles.add(initMeshTriangle(p3, p4, p1))

      var
        curr_cell = i * (self.cols - 1) + j
        left_cell = if j != 0: int(curr_cell - 1) else: -1
        bott_cell = if i != 0: int(curr_cell - (self.cols - 1)) else: -1
        curr_t1 = curr_cell * 2
        curr_t2 = curr_t1 + 1
        left_t1 = if (left_cell >= 0): left_cell * 2 else: -1
        left_t2 = if (left_cell >= 0): left_t1 + 1   else: -1
        bott_t1 = if(bott_cell >= 0): bott_cell * 2 else: -1
        bott_t2 = if(bott_cell >= 0): bott_t1 + 1   else: -1

      self.edges.add(initMeshEdge(p1, p2, curr_t1, bott_t2))
      self.edges.add(initMeshEdge(p1, p3, curr_t2, curr_t1))
      self.edges.add(initMeshEdge(p1, p4, left_t1, curr_t2))

      if j == self.cols - 2: # Last column
        self.edges.add(initMeshEdge(p2, p3, curr_t1, -1))

      if i == self.rows - 2: # Last row
        self.edges.add(initMeshEdge(p3, p4, curr_t2, -1))


proc randomize_points(self: var MeshCtrl, delta: float64) =
  for i in 0.. <self.rows:
    for j in 0.. <self.cols:
      var
        xc = j.float64 * self.cellW + self.startX
        yc = i.float64 * self.cellH + self.startY
        x1 = xc - self.cellW / 4
        y1 = yc - self.cellH / 4
        x2 = xc + self.cellW / 4
        y2 = yc + self.cellH / 4
        p = self.vertex(j, i).addr

      p.x += p.dx
      p.y += p.dy
      if p.x < x1: p.x = x1; p.dx = -p.dx
      if p.y < y1: p.y = y1; p.dy = -p.dy
      if p.x > x2: p.x = x2; p.dx = -p.dx
      if p.y > y2: p.y = y2; p.dy = -p.dy

proc rotateColors(self: var MeshCtrl) =
  for i in 1.. <self.vertices.len:
    var
      c = self.vertices[i].color.addr
      dc = self.vertices[i].dc.addr
      r = c.r.int + (if dc.r != 0: 5 else: -5)
      g = c.g.int + (if dc.g != 0: 5 else: -5)
      b = c.b.int + (if dc.b != 0: 5 else: -5)

    if r < 0:   r = 0;   dc.r = dc.r xor 1
    if r > 255: r = 255; dc.r = dc.r xor 1
    if g < 0:   g = 0;   dc.g = dc.g xor 1
    if g > 255: g = 255; dc.g = dc.g xor 1
    if b < 0:   b = 0;   dc.b = dc.b xor 1
    if b > 255: b = 255; dc.b = dc.b xor 1

    c.r = r.uint8
    c.g = g.uint8
    c.b = b.uint8

proc onMouseButtonDown(self: var MeshCtrl, x, y: int, flags: InputFlags): bool =
  if mouseLeft in flags:
    for i in 0.. <self.vertices.len():
      if calcDistance(x.float64, y.float64, self.vertices[i].x, self.vertices[i].y) < 5:
        self.dragIdx = i
        self.dragDx = x.float64 - self.vertices[i].x
        self.dragDy = y.float64 - self.vertices[i].y
        return true
  result = false

proc onMouseButtonUp(self: var MeshCtrl, x, y: int, flags: InputFlags): bool =
  result = self.dragIdx >= 0
  self.dragIdx = -1

proc onMouseMove(self: var MeshCtrl, x, y: int, flags: InputFlags): bool =
  if mouseLeft in flags:
    if self.dragIdx >= 0:
      self.vertices[self.dragIdx].x = x.float64 - self.dragDx
      self.vertices[self.dragIdx].y = y.float64 - self.dragDy
      return true
  else:
    return self.onMouseButtonUp(x, y, flags)
  result = false

type
  GouraudType = SpanGouraudRgba[Rgba8]
  StylesGouraud = object
    triangles: seq[GouraudType]

proc initStylesGouraud[Gamma](mesh: var MeshCtrl, gamma: var Gamma): StylesGouraud =
  result.triangles = newSeqOfCap[GouraudType](mesh.triangles.len)
  for t in mesh.triangle():
    var
      p1 = mesh.vertex(t.p1)
      p2 = mesh.vertex(t.p2)
      p3 = mesh.vertex(t.p3)
      c1 = p1.color
      c2 = p2.color
      c3 = p3.color

    c1.applyGammaDir(gamma)
    c2.applyGammaDir(gamma)
    c3.applyGammaDir(gamma)

    var gouraud = initSpanGouraudRgba[Rgba8](c1, c2, c3,
      p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, 0)
    gouraud.prepare()
    result.triangles.add(gouraud)

proc isSolid(self: StylesGouraud, style: int): bool = false
proc color(self: StylesGouraud, style: int): Rgba8 = initRgba8(0,0,0,0)
proc generateSpan(self: var StylesGouraud, span: ptr Rgba8, x, y, len, style: int) =
  self.triangles[style].generate(span, x, y, len)

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mesh: MeshCtrl
    gamma: GammaLut8

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mesh = initMeshCtrl()
  result.gamma = initGammaLut8()

method onInit(app: App) =
  app.mesh.generate(20, 20, 17, 17, 40, 40)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    slBin  = initScanlineBin()
    sa     = initSpanAllocator[Rgba8]()
    rasc   = initRasterizerCompoundAA()
    styles = initStylesGouraud(app.mesh, app.gamma)

  rb.clear(initRgba(0, 0, 0))

  app.startTimer()
  rasc.reset()

  #rasc.clip_box(40, 40, width() - 40, height() - 40)

  for e in app.mesh.edge():
    var
      p1 = app.mesh.vertex(e.p1)
      p2 = app.mesh.vertex(e.p2)
    rasc.styles(e.tl, e.tr)
    rasc.moveToD(p1.x, p1.y)
    rasc.lineToD(p2.x, p2.y)

  renderScanlinesCompound(rasc, sl, slBin, rb, sa, styles)
  let tm = app.elapsedtime()

  var
    t = initGsvText()
    pt = initConvStroke(t)
    buf = "$1 ms, $2 triangles, $3 tri/sec" % [tm.formatFloat(ffDecimal, 2),
      $app.mesh.triangles.len,
      (app.mesh.triangles.len.float64 / tm * 1000.0).formatFloat(ffDecimal, 2)]

  t.size(10.0)
  pt.width(1.5)
  pt.lineCap(LineCap.roundCap)
  pt.lineJoin(LineJoin.roundJoin)
  t.startPoint(10.0, 10.0)
  t.text(buf)

  ras.addPath(pt)
  renderScanlinesAASolid(ras, sl, rb, initRgba(1,1,1))

  if app.gamma.gamma() != 1.0:
    pf.applyGammaInv(app.gamma)

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if app.mesh.onMouseMove(x, y, flags):
    app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if app.mesh.onMouseButtonDown(x, y, flags):
    app.forceRedraw()

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  if app.mesh.onMouseButtonUp(x, y, flags):
    app.forceRedraw()

method onIdle(app: App) =
  app.mesh.randomizePoints(1.0)
  app.mesh.rotateColors()
  app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Gouraud Mesh")

  if app.init(frameWidth, frameHeight, {}, "gouraud_mesh"):
    app.waitMode(false)
    return app.run()

  result = 1

discard main()
