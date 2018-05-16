import agg/[rendering_buffer, trans_viewport, path_storage, conv_transform,
  conv_curve, conv_stroke, gsv_text, scanline_u, renderer_scanline,
  rasterizer_scanline_aa, span_allocator, gamma_lut, pixfmt_rgba, bounding_rect,
  color_rgba, trans_affine, basics, calc, renderer_base]
import random, os, strutils, math, platform.support

const
  frameWidth = 655
  frameHeight = 520
  flipY = false

type
  ValueT = uint8

  PathStyle = object
    pathId: int
    leftFill, rightFill: int
    line: int

  CompoundShape = object
    path: PathStorage
    affine: TransAffine
    curve: ConvCurve[PathStorage]
    trans: ConvTransform[ConvCurve[PathStorage], TransAffine]
    styles: seq[PathStyle]
    x1, y1, x2, y2: float64
    minStyle, maxStyle: int
    fd: File

proc initCompoundShape(): CompoundShape =
  result.path   = initPathStorage()
  result.affine = initTransAffine()
  result.curve  = initConvCurve(result.path)
  result.trans  = initConvTransform(result.curve, result.affine)
  result.styles = @[]
  result.minStyle = 0x7FFFFFFF
  result.maxStyle = -0x7FFFFFFF

proc open(self: var CompoundShape, name: string): bool =
  self.fd = open(name, fmRead)
  result = self.fd != nil

proc readNext(self: var CompoundShape): bool =
  self.path.removeAll()
  self.styles.setLen(0)

  var
    ax, ay, cx, cy: float64

  self.minStyle = 0x7FFFFFFF
  self.maxStyle = -0x7FFFFFFF

  if self.fd != nil:
    var
      buf: string
      fd = self.fd

    while true:
      if not fd.readLine(buf): return false
      if buf[0] == '=': break

    while fd.readLine(buf):
      case buf[0]
      of '!': break
      of 'P':
        # BeginPath
        var style: PathStyle
        style.pathId = self.path.startNewPath()
        var parts = buf.split(WhiteSpace)
        style.leftFill = parseInt(parts[1])
        style.rightFill = parseInt(parts[2])
        style.line = parseInt(parts[3])
        ax = parseInt(parts[4]).float64
        ay = parseInt(parts[5]).float64
        self.path.moveTo(ax, ay)
        self.styles.add(style)
        if style.leftFill >= 0:
          if style.leftFill < self.minStyle: self.minStyle = style.leftFill
          if style.leftFill > self.maxStyle: self.maxStyle = style.leftFill
        if style.rightFill >= 0:
          if style.rightFill < self.minStyle: self.minStyle = style.rightFill
          if style.rightFill > self.maxStyle: self.maxStyle = style.rightFill
      of 'C':
        var parts = buf.split(WhiteSpace)
        cx = parseInt(parts[1]).float64
        cy = parseInt(parts[2]).float64
        ax = parseInt(parts[3]).float64
        ay = parseInt(parts[4]).float64
        self.path.curve3(cx, cy, ax, ay)
      of 'L':
        var parts = buf.split(WhiteSpace)
        ax = parseInt(parts[1]).float64
        ay = parseInt(parts[2]).float64
        self.path.lineTo(ax, ay)
      of '<':
        # EndPath
        discard
      else:
        discard
    return true
  result = false

proc `[]`(self: CompoundShape, i: int): int =
  self.styles[i].pathId

proc paths(self: CompoundShape): int =
  self.styles.len

proc style(self: CompoundShape, i: int): PathStyle =
  self.styles[i]

proc rewind(self: var CompoundShape, pathId: int) =
  self.trans.rewind(pathId)

proc vertex(self: var CompoundShape, x, y: var float64): uint =
  self.trans.vertex(x, y)

#proc scale(self: CompoundShape): float64 =
#  self.affine.scale()

proc scale(self: var CompoundShape, w, h: float64) =
  self.affine.reset()
  var x1, y1, x2, y2: float64
  discard boundingRect(self.path, self, 0, self.styles.len, x1, y1, x2, y2)
  if x1 < x2 and y1 < y2:
    var vp = initTransViewport()
    vp.preserveAspectRatio(0.5, 0.5, aspectRatioMeet)
    vp.setWorldViewport(x1, y1, x2, y2)
    vp.setDeviceViewport(0, 0, w, h)
    self.affine = vp.toAffine()
  self.curve.approximationScale(self.affine.scale())

proc approximationScale(self: var CompoundShape, s: float64) =
  self.curve.approximationScale(self.affine.scale() * s)

proc hitTest(self: var CompoundShape, x, y, r: float64): int =
  var
    x = x
    y = y
  self.affine.inverseTransform(x, y)
  var r = r / self.affine.scale()

  for i in 0..<self.path.totalVertices():
    var
      vx, vy: float64
      cmd = self.path.vertex(i, vx, vy)
    if isVertex(cmd):
      if calcDistance(x, y, vx, vy) <= r:
        return i
  result = -1

proc modify_vertex(self: var CompoundShape, i: int, x, y: float64) =
  var
    x = x
    y = y
  self.affine.inverseTransform(x, y)
  self.path.modifyVertex(i, x, y)

type
  PixFmt = PixFmtBgra32Pre

  App = ref object of PlatformSupport
    shape: CompoundShape
    colors: array[100, Rgba8]
    scale: TransAffine
    gamma: GammaLut8
    pointIdx: int

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.shape = initCompoundShape()
  result.scale = initTransAffine()
  result.pointIdx = -1
  result.gamma = initGammaLut8()
  result.gamma.gamma(2.0)

  randomize()
  for i in 0..<100:
    result.colors[i] = initRgba8(rand(0xFF), rand(0xFF), rand(0xFF), 230)
    result.colors[i].applyGammaDir(result.gamma)
    result.colors[i].premultiply()

proc open(app: App, name: string): bool =
  app.shape.open("resources$1$2" % [$DirSep, name])

proc readNext(app: App) =
  discard app.shape.readNext()
  app.shape.scale(frameWidth.float64, frameHeight.float64)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    shape  = initConvTransform(app.shape, app.scale)
    stroke = initConvStroke(shape)
    tmpPath= initPathStorage()
    width  = frameWidth.float64
    height = frameHeight.float64

  rb.clear(initRgba(1.0, 1.0, 0.95))
  app.shape.approximation_scale(app.scale.scale())
  ras.clipBox(0, 0, width, height)

  # This is an alternative method of Flash rasterization.
  # We decompose the compound shape into separate paths
  # and select the ones that fit the given style (left or right).
  # So that, we form a sub-shape and draw it as a whole.
  #
  # Here the regular scanline rasterizer is used, but it doesn't
  # automatically close the polygons. So that, the rasterizer
  # actually works with a set of polylines instead of polygons.
  # Of course, the data integrity must be preserved, that is,
  # the polylines must eventually form a closed contour
  # (or a set of closed contours). So that, first we set
  # auto_close(false)
  #
  # The second important thing is that one path can be rasterized
  # twice, if it has both, left and right fill. Sometimes the
  # path has equal left and right fill, so that, the same path
  # will be added twice even for a single sub-shape. If the
  # rasterizer can tolerate these degenerates you can add them,
  # but it's also fine just to omit them.
  #
  # The third thing is that for one side (left or right)
  # you should invert the direction of the paths.
  #
  # The main disadvantage of this method is imperfect stitching
  # of the adjacent polygons. The problem can be solved if we use
  # compositing operation "plus" instead of alpha-blend. But
  # in this case we are forced to use an RGBA buffer, clean it with
  # zero, rasterize using "plus" operation, and then alpha-blend
  # the result over the final scene. It can be too expensive.

  ras.autoClose(false)

  app.startTimer()
  for s in app.shape.minStyle..app.shape.maxStyle:
    ras.reset()
    for i in 0..<app.shape.paths():
      var style = app.shape.style(i)
      if style.leftFill != style.rightFill:
        if style.leftFill == s:
          ras.addPath(shape, style.pathId)
        if style.rightFill == s:
          tmpPath.removeAll()
          tmpPath.concatPath(shape, style.pathId)
          tmpPath.invertPolygon(0)
          ras.addPath(tmpPath)
    renderScanlinesAASolid(ras, sl, rb, app.colors[s])
  let tfill = app.elapsedTime()

  ras.autoClose(true)
  # Draw strokes
  app.startTimer()
  stroke.width(sqrt(app.scale.scale()))
  stroke.lineJoin(roundJoin)
  stroke.lineCap(roundCap)
  for i in 0..<app.shape.paths():
    ras.reset()
    if app.shape.style(i).line >= 0:
      ras.addPath(stroke, app.shape.style(i).pathId)
      ren.color(initRgba8(0,0,0, 128))
      renderScanlines(ras, sl, ren)
  let tstroke = app.elapsedTime()

  var
    t   = initGsvText()
    ts  = initConvStroke(t)
    buf = "Fill=$1ms ($2FPS) Stroke=$3ms ($4FPS) Total=$5ms ($6FPS)\n"

  buf.add "Space: Next Shape\n+/- : ZoomIn/ZoomOut (with respect to the mouse pointer)"
  buf = buf % [tfill.formatFloat(ffDecimal,2), $int(1000.0/tfill),
    tstroke.formatFloat(ffDecimal,2), $int(1000.0/tstroke),
    (tfill+tstroke).formatFloat(ffDecimal,2), $int(1000.0 / (tfill+tstroke))]

  t.size(8.0)
  t.flip(true)
  ts.width(1.6)
  ts.lineCap(roundCap)
  t.startPoint(10.0, 20.0)
  t.text(buf)
  ras.addPath(ts)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  if app.gamma.gamma() != 1.0:
    pf.applyGammaInv(app.gamma)

method onKey(app: App, x, y, key: int, flags: InputFlags) =
  var
    x = x.float64
    y = y.float64

  if key == ' '.ord:
    discard app.shape.readNext()
    app.shape.scale(app.width(), app.height())
    app.forceRedraw()

  if key == '+'.ord or key == key_kp_plus.ord:
      app.scale *= transAffineTranslation(-x, -y)
      app.scale *= transAffineScaling(1.1)
      app.scale *= transAffineTranslation(x, y)
      app.forceRedraw()

  if key == '-'.ord or key == key_kp_minus.ord:
    app.scale *= transAffineTranslation(-x, -y)
    app.scale *= transAffineScaling(1/1.1)
    app.scale *= transAffineTranslation(x, y)
    app.forceRedraw()

  if key == key_left.ord:
    app.scale *= transAffineTranslation(-x, -y)
    app.scale *= transAffineRotation(-pi / 20.0)
    app.scale *= transAffineTranslation(x, y)
    app.forceRedraw()

  if key == key_right.ord:
    app.scale *= transAffineTranslation(-x, -y)
    app.scale *= transAffineRotation(pi / 20.0)
    app.scale *= transAffineTranslation(x, y)
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.onMouseButtonUp(x, y, flags)
  else:
    if app.pointIdx >= 0:
      var
        xd = x.float64
        yd = y.float64
      app.scale.inverseTransform(xd, yd)
      app.shape.modifyVertex(app.pointIdx, xd, yd)
      app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    var
      xd = x.float64
      yd = y.float64
      r  = 4.0 / app.scale.scale()
    app.scale.inverseTransform(xd, yd)
    app.pointIdx = app.shape.hitTest(xd, yd, r)
    app.forceRedraw()

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.pointIdx = -1

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("AGG Example - Flash Rasterizer")

  if not app.open("shapes.txt"):
    app.message("failed to load shapes.txt")
    return 1

  app.readNext()
  app.readNext()

  if app.init(frameWidth, frameHeight, {window_resize}, "flash_rasterizer2"):
    return app.run()

  result = 1

discard main()
