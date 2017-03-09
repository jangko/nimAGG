import agg_rendering_buffer, agg_trans_viewport, agg_path_storage, agg_conv_transform
import agg_conv_curve, agg_conv_stroke, agg_gsv_text, agg_scanline_u, agg_scanline_bin
import agg_renderer_scanline, agg_rasterizer_scanline_aa, agg_rasterizer_compound_aa
import agg_span_allocator, agg_gamma_lut, agg_pixfmt_rgba, agg_bounding_rect, agg_color_gray
import agg_color_rgba, nimBMP, agg_trans_affine, strutils, agg_basics, agg_math
import random, os, strutils, agg_renderer_base, math

const
  frameWidth = 655
  frameHeight = 520
  flipY = false
  pixWidth = 4

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
    fd: File

proc initCompoundShape(): CompoundShape =
  result.path   = initPathStorage()
  result.affine = initTransAffine()
  result.curve  = initConvCurve(result.path)
  result.trans  = initConvTransform(result.curve, result.affine)
  result.styles = @[]

proc open(self: var CompoundShape, name: string) =
  self.fd = open(name, fmRead)

proc readNext(self: var CompoundShape): bool =
  self.path.removeAll()
  self.styles.setLen(0)

  var
    ax, ay, cx, cy: float64

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
        ax = parseFloat(parts[4])
        ay = parseFloat(parts[5])
        self.path.moveTo(ax, ay)
        self.styles.add(style)
      of 'C':
        var parts = buf.split(WhiteSpace)
        cx = parseFloat(parts[1])
        cy = parseFloat(parts[2])
        ax = parseFloat(parts[3])
        ay = parseFloat(parts[4])
        self.path.curve3(cx, cy, ax, ay)
      of 'L':
        var parts = buf.split(WhiteSpace)
        ax = parseFloat(parts[1])
        ay = parseFloat(parts[2])
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

proc scale(self: CompoundShape): float64 =
  self.affine.scale()

proc scale(self: var CompoundShape, w, h: float64) =
  self.affine.reset()
  var x1, y1, x2, y2: float64
  discard boundingRect(self.path, self, 0, self.styles.len, x1, y1, x2, y2)
  if x1 < x2 and y1 < y2:
    var vp = initTransViewport()
    vp.preserveAspectRatio(0.5, 0.5, aspectRatioMeet)
    vp.worldViewport(x1, y1, x2, y2)
    vp.deviceViewport(0, 0, w, h)
    self.affine = vp.toAffine()
  self.curve.approximationScale(0.03)

proc approximationScale(self: var CompoundShape, s: float64) =
  self.curve.approximationScale(self.affine.scale() * s)

proc hitTest(self: var CompoundShape, x, y, r: float64): int =
  var
    x = x
    y = y
  self.affine.inverseTransform(x, y)
  var r = r / self.affine.scale()

  for i in 0.. <self.path.totalVertices():
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
  TestStyles = object
    solidColors: ptr Rgba8
    gradient: ptr Rgba8
        
proc initTestStyles(solidColors, gradient: ptr Rgba8): TestStyles =
  result.solidColors = solidColors
  result.gradient = gradient

proc isSolid(self: TestStyles, style: int): bool =
  result = true

proc color(self: TestStyles, style: int): Rgba8 =
  self.solidColors[style]
    
proc generateSpan(self: TestStyles, span: ptr Rgba8, x, y, len: int, style: int) =
  copyMem(span, self.gradient + x, sizeof(Rgba8) * len)
      
type
  App = object
    shape: CompoundShape
    colors: array[100, Rgba8]
    scale: TransAffine
    gamma: GammaLut8
    gradient: seq[Rgba8]
    pointIdx, hitX, hitY: int
    
proc initApp(): App =
  result.shape = initCompoundShape()
  result.scale = initTransAffine()
  result.pointIdx = -1
  result.hitX = -1
  result.hitY = -1
  result.gamma = initGammaLut8()
  result.gamma.gamma(2.0)
  result.gradient = @[]

  for i in 0.. <100:
    result.colors[i] = initRgba8(random(0xFF), random(0xFF), random(0xFF), 230)
    result.colors[i].applyGammaDir(result.gamma)
    result.colors[i].premultiply()
        
proc open(app: var App, name: string): bool =
  app.shape.open("resources$1$2" % [$DirSep, name])

proc readNext(app: var App) =
  discard app.shape.readNext()
  app.shape.scale(frameWidth.float64, frameHeight.float64)

proc onDraw() =
  var app    = initApp()
  discard app.open("shapes.txt")
  app.readNext()
  
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pixf   = initPixfmtRgba32(rbuf)
    rb     = initRendererBase(pixf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineU8()
    slBin  = initScanlineBin()
    ras    = initRasterizerScanlineAA()
    rasc   = initRasterizerCompoundAA()
    shape  = initConvTransform(app.shape, app.scale)
    stroke = initConvStroke(shape)    
    sa     = initSpanAllocator[Rgba8]()
    width  = frameWidth.float64
    height = frameHeight.float64
  
  rb.clear(initRgba(1.0, 1.0, 0.95))
  app.gradient.setLen(frameWidth)
  var styleHandler = initTestStyles(app.colors[0].addr, app.gradient[0].addr)
  
  var
    c1 = initRgba(255, 0, 0, 180)
    c2 = initRgba(0, 0, 255, 180)
    
  for i in 0.. <width.int:
    app.gradient[i] = initRgba8(c1.gradient(c2, i.float64 / width))
    app.gradient[i].premultiply()
  
  app.shape.approximationScale(app.scale.scale())
    
  # Fill shape
  rasc.clipBox(0, 0, width, height)
  rasc.reset()
  
  rasc.fillingRule(fillEvenOdd)
  #start_timer()
  
  for i in 0.. <app.shape.paths():
    if app.shape.style(i).leftFill >= 0 or app.shape.style(i).rightFill >= 0:
      rasc.styles(app.shape.style(i).leftFill, app.shape.style(i).rightFill)
      rasc.addPath(shape, app.shape.style(i).pathId)
  renderScanlinesCompound(rasc, sl, slBin, rb, sa, styleHandler)
  
  #double tfill = elapsed_time()
  
  # Hit-test test
  var drawStrokes = true
  if app.hitX >= 0 and app.hitY >= 0:
    if rasc.hitTest(app.hitX, app.hitY):
      drawStrokes = false
    
  # Draw strokes
  #start_timer()
  if draw_strokes:
    ras.clipBox(0, 0, width, height)
    stroke.width(sqrt(app.scale.scale()))
    stroke.lineJoin(roundJoin)
    stroke.lineCap(roundCap)
    for i in 0.. <app.shape.paths():
      ras.reset()
      if app.shape.style(i).line >= 0:
        ras.addPath(stroke, app.shape.style(i).pathId)
        ren.color(initRgba8(0,0,0, 128))
        renderScanlines(ras, sl, ren)
  #[
  double tstroke = elapsed_time()
  
  
  char buf[256];
  agg::gsv_text t;
  t.size(8.0)
  t.flip(true)
  
  agg::conv_stroke<agg::gsv_text> ts(t)
  ts.width(1.6)
  ts.line_cap(agg::round_cap)
  
  sprintf(buf, "Fill=%.2fms (%dFPS) Stroke=%.2fms (%dFPS) Total=%.2fms (%dFPS)\n\n"
              "Space: Next Shape\n\n"
              "+/- : ZoomIn/ZoomOut (with respect to the mouse pointer)",
              tfill, int(1000.0 / tfill),
              tstroke, int(1000.0 / tstroke),
              tfill+tstroke, int(1000.0 / (tfill+tstroke)))
  
  t.start_point(10.0, 20.0)
  t.text(buf)
  
  ras.add_path(ts)
  ren.color(agg::rgba(0,0,0))
  agg::render_scanlines(ras, sl, ren)
  
  if(m_gamma.gamma() != 1.0)
      pixf.apply_gamma_inv(m_gamma)
  ]#
  
  saveBMP32("flash_rasterizer.bmp", buffer, frameWidth, frameHeight)

onDraw()