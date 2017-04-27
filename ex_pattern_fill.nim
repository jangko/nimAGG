import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_path_storage
import agg_trans_affine, agg_conv_transform, agg_conv_smooth_poly1
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_span_pattern_gray
import agg_span_pattern_rgb, agg_span_pattern_rgba, agg_image_accessors
import ctrl_slider, ctrl_rbox, ctrl_cbox, agg_pixfmt_rgba, agg_renderer_base
import agg_color_rgba, nimBMP, math, agg_basics, agg_conv_stroke, agg_color_gray
import agg_pixfmt_rgb, agg_pixfmt_gray, agg_platform_support

const pix_format = pix_format_bgra32

when pix_format == pix_format_gray8:
  type
    PixFmt = PixFmtGray8
    PixFmtPre = PixFmtGray8Pre
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternGray(a, b, c)
elif pix_format == pix_format_bgr24:
  type
    PixFmt = PixFmtBgr24
    PixFmtPre = PixFmtBgr24Pre
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternRgb(a, b, c)
else:
  type
    PixFmt = PixFmtBgra32
    PixFmtPre = PixFmtBgra32Pre
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternRgba(a, b, c)

const
  frameWidth = 640
  frameHeight = 480
  flipY = true

type
  ColorT = getColorT(PixFmt)

type
  App = ref object of PlatformSupport
    polygonAngle: SliderCtrl[ColorT]
    polygonScale: SliderCtrl[ColorT]
    patternAngle: SliderCtrl[ColorT]
    patternSize : SliderCtrl[ColorT]
    patternAlpha: SliderCtrl[ColorT]

    rotatePolygon: CboxCtrl[ColorT]
    rotatePattern: CboxCtrl[ColorT]
    tiePattern   : CboxCtrl[ColorT]

    polygonCx, polygonCy: float64
    dx, dy: float64
    flag: int
    pattern: seq[uint8]
    patternRbuf: RenderingBuffer
    ras: RasterizerScanlineAA
    sl: ScanlineP8
    ps: PathStorage

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.patternRbuf = initRenderingBuffer()
  result.ras = initRasterizerScanlineAA()
  result.sl = initScanlineP8()
  result.ps = initPathStorage()
  result.polygonAngle = newSliderCtrl[ColorT](5,    5,         145, 12,    not flipY)
  result.polygonScale = newSliderCtrl[ColorT](5,    5+14,      145, 12+14, not flipY)
  result.patternAngle = newSliderCtrl[ColorT](155,  5,         300, 12,    not flipY)
  result.patternSize  = newSliderCtrl[ColorT](155,  5+14,      300, 12+14, not flipY)
  result.patternAlpha = newSliderCtrl[ColorT](310,  5,         460, 12,    not flipY)
  result.rotatePolygon = newCboxCtrl[ColorT](5,   5+14+14,    "Rotate Polygon", not flipY)
  result.rotatePattern = newCboxCtrl[ColorT](5,   5+14+14+14, "Rotate Pattern", not flipY)
  result.tiePattern    = newCboxCtrl[ColorT](155, 5+14+14,    "Tie pattern to polygon", not flipY)

  result.addCtrl(result.polygonAngle )
  result.addCtrl(result.polygonScale )
  result.addCtrl(result.patternAngle )
  result.addCtrl(result.patternSize  )
  result.addCtrl(result.patternAlpha )
  result.addCtrl(result.rotatePolygon)
  result.addCtrl(result.rotatePattern)
  result.addCtrl(result.tiePattern   )

  result.flag = 0
  result.pattern = nil
  result.polygonAngle.label("Polygon Angle=$1")
  result.polygonAngle.setRange(-180.0, 180.0)
  result.polygonScale.label("Polygon Scale=$1")
  result.polygonScale.setRange(0.1, 5.0)
  result.polygonScale.value(1.0)
  result.patternAngle.label("Pattern Angle=$1")
  result.patternAngle.setRange(-180.0, 180.0)
  result.patternSize.label("Pattern Size=$1")
  result.patternSize.setRange(10, 40)
  result.patternSize.value(30)
  result.patternAlpha.label("Background Alpha=$1")
  result.patternAlpha.value(0.1)

proc createStar(app: App, xc, yc, r1, r2: float64, n: int, startAngle = 0.0) =
  app.ps.removeAll()
  var startAngle = startAngle * pi / 180.0

  for i in 0.. <n:
    let
       a = pi * 2.0 * i.float64 / n.float64 - pi / 2.0
       dx = cos(a + startAngle)
       dy = sin(a + startAngle)

    if (i and 1) != 0:
      app.ps.lineTo(xc + dx * r1, yc + dy * r1)
    else:
      if i != 0: app.ps.lineTo(xc + dx * r2, yc + dy * r2)
      else:      app.ps.moveTo(xc + dx * r2, yc + dy * r2)
  app.ps.closePolygon()

proc generatePattern(app: App) =
  let size = app.patternSize.value().int

  app.createStar(app.patternSize.value() / 2.0,
                 app.patternSize.value() / 2.0,
                 app.patternSize.value() / 2.5,
                 app.patternSize.value() / 6.0,
                 6, app.patternAngle.value())

  var
    smooth = initConvSmoothPoly1Curve(app.ps)
    stroke = initConvStroke(smooth)

  smooth.smoothValue(1.0)
  smooth.approximationScale(4.0)
  stroke.width(app.patternSize.value() / 15.0)

  app.pattern = newSeq[uint8](size * size * getPixElem(PixFmt))
  app.patternRbuf.attach(app.pattern[0].addr, size, size, size*getPixElem(PixFmt))

  var
    pixf = construct(PixFmt, app.patternRbuf)
    rb   = initRendererBase(pixf)
    rs   = initRendererScanlineAASolid(rb)

  rb.clear(rgbaPre(0.4, 0.0, 0.1, app.patternAlpha.value())) #Pattern background color

  app.ras.addPath(smooth)
  rs.color(initRgba8(110,130,50))
  renderScanlines(app.ras, app.sl, rs)

  app.ras.addPath(stroke)
  rs.color(initRgba8(0,50,80))
  renderScanlines(app.ras, app.sl, rs)

method onInit(app: App) =
  var
    initialWidth  = frameWidth.float64
    initialHeight = frameHeight.float64

  app.polygonCx = initialWidth / 2.0
  app.polygonCy = initialHeight / 2.0
  app.generatePattern()

method onDraw(app: App) =
  var
    width   = app.width()
    height  = app.height()
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfPre = construct(PixFmtPre, app.rbufWindow())
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    mtx     = initTransAffine()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  mtx *= transAffineTranslation(-app.polygonCx, -app.polygonCy)
  mtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
  mtx *= transAffineScaling(app.polygonScale.value())
  mtx *= transAffineTranslation(app.polygonCx, app.polygonCy)

  var r = app.initialWidth() / 3.0 - 8.0
  app.createStar(app.polygonCx, app.polygonCy, r, r / 1.45, 14)

  type
    WrapX = WrapModeRepeatAutoPow2
    WrapY = WrapModeRepeatAutoPow2

  var
    tr = initConvTransform(app.ps, mtx)
    imgPixf = construct(PixFmt, app.patternRbuf)
    imgSrc = initImageAccessorWrap[PixFmt, WrapX, WrapY](imgPixf)
    sa = initSpanAllocator[ColorT]()
    offsetX = 0
    offsetY = 0

  if app.tiePattern.status():
    offsetX = int(width-app.polygonCx)
    offsetY = int(height-app.polygonCy)

  var sg = initSpanPattern(imgSrc, offsetX, offsetY)

  # Alpha is meaningful for RGB only because RGBA has its own
  sg.alpha((app.patternAlpha.value() * 255.0))

  app.ras.addPath(tr)
  renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)

  renderCtrl(app.ras, app.sl, rb, app.polygonAngle)
  renderCtrl(app.ras, app.sl, rb, app.polygonScale)
  renderCtrl(app.ras, app.sl, rb, app.patternAngle)
  renderCtrl(app.ras, app.sl, rb, app.patternSize)
  renderCtrl(app.ras, app.sl, rb, app.patternAlpha)
  renderCtrl(app.ras, app.sl, rb, app.rotatePolygon)
  renderCtrl(app.ras, app.sl, rb, app.rotatePattern)
  renderCtrl(app.ras, app.sl, rb, app.tiePattern)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    var mtx = initTransAffine()
    mtx *= transAffineTranslation(-app.polygonCx, -app.polygonCy)
    mtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
    mtx *= transAffineScaling(app.polygonScale.value())
    mtx *= transAffineTranslation(app.polygonCx, app.polygonCy)

    var r = app.initialWidth() / 3.0 - 8.0
    app.createStar(app.polygonCx, app.polygonCy, r, r / 1.45, 14)

    var tr = initConvTransform(app.ps, mtx)
    app.ras.addPath(tr)
    if app.ras.hitTest(x, y):
      app.dx = x.float64 - app.polygonCx
      app.dy = y.float64 - app.polygonCy
      app.flag = 1

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    if app.flag != 0:
      app.polygonCx = x.float64 - app.dx
      app.polygonCy = y.float64 - app.dy
      app.forceRedraw()
  else:
    app.onMouseButtonUp(x, y, flags)

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.flag = 0

method onCtrlChange(app: App)  =
  if app.rotatePolygon.status() or app.rotatePattern.status():
    app.waitMode(false)
  else:
    app.waitMode(true)

  app.generatePattern()
  app.forceRedraw()

method onIdle(app: App)  =
  var redraw = false
  if app.rotatePolygon.status():
    app.polygonAngle.value(app.polygonAngle.value() + 0.5)
    if app.polygonAngle.value() >= 180.0:
      app.polygonAngle.value(app.polygonAngle.value() - 360.0)
    redraw = true

  if app.rotatePattern.status():
    app.patternAngle.value(app.patternAngle.value() - 0.5)
    if app.patternAngle.value() <= -180.0:
      app.patternAngle.value(app.patternAngle.value() + 360.0)
    app.generatePattern()
    redraw = true

  if redraw: app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format, flipY)
  app.caption("AGG Example. Anti-Aliasing Demo")

  if app.init(frameWidth, frameHeight, {window_resize}, "pattern_fill"):
    return app.run()

  result = 1

discard main()
