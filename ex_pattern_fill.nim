import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_path_storage
import agg_trans_affine, agg_conv_transform, agg_conv_smooth_poly1
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_span_pattern_gray
import agg_span_pattern_rgb, agg_span_pattern_rgba, agg_image_accessors
import ctrl_slider, ctrl_rbox, ctrl_cbox, agg_pixfmt_rgba, agg_renderer_base
import agg_color_rgba, nimBMP, math, agg_basics, agg_conv_stroke, agg_color_gray
import agg_pixfmt_rgb, agg_pixfmt_gray

when defined(pix_format_gray):
  type
    ColorT = Gray8
    PixFmt = PixFmtGray8
  const pixWidth = 1
  template initPixFmt(rbuf: untyped): untyped =
    initPixFmtGray8(rbuf)
  template initPixFmtPre(rbuf: untyped): untyped =
    initPixFmtGray8Pre(rbuf)
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternGray(a, b, c)
  template saveBMP(n, b, w, h: typed) =
    saveBMP8(n, buffer, w, h)
elif defined(pix_format_rgb):
  type
    ColorT = Rgba8
    PixFmt = PixFmtRgb24
  const pixWidth = 3
  template initPixFmt(rbuf: untyped): untyped =
    initPixFmtRgb24(rbuf)
  template initPixFmtPre(rbuf: untyped): untyped =
    initPixFmtRgb24Pre(rbuf)
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternRgb(a, b, c)
  template saveBMP(n, b, w, h: typed) =
    saveBMP24(n, b, w, h)
else:
  type
    ColorT = Rgba8
    PixFmt = PixFmtRgba32
  const pixWidth = 4
  template initPixFmt(rbuf: untyped): untyped =
    initPixFmtRgba32(rbuf)
  template initPixFmtPre(rbuf: untyped): untyped =
    initPixFmtRgba32Pre(rbuf)
  template initSpanPattern(a, b, c: untyped): untyped =
    initSpanPatternRgba(a, b, c)
  template saveBMP(n, b, w, h: typed) =
    saveBMP32(n, b, w, h)
const
  frameWidth = 640
  frameHeight = 480
  flipY = true

type
  ValueT = uint8

type
  App = object
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

proc initApp(): App =
  result.patternRbuf = initRenderingBuffer()
  result.ras = initRasterizerScanlineAA()
  result.sl = initScanlineP8()
  result.ps = initPathStorage()
  result.polygon_angle = newSliderCtrl[ColorT](5,    5,         145, 12,    not flipY)
  result.polygon_scale = newSliderCtrl[ColorT](5,    5+14,      145, 12+14, not flipY)
  result.pattern_angle = newSliderCtrl[ColorT](155,  5,         300, 12,    not flipY)
  result.pattern_size  = newSliderCtrl[ColorT](155,  5+14,      300, 12+14, not flipY)
  result.pattern_alpha = newSliderCtrl[ColorT](310,  5,         460, 12,    not flipY)
  result.rotate_polygon = newCboxCtrl[ColorT](5,   5+14+14,    "Rotate Polygon", not flipY)
  result.rotate_pattern = newCboxCtrl[ColorT](5,   5+14+14+14, "Rotate Pattern", not flipY)
  result.tie_pattern    = newCboxCtrl[ColorT](155, 5+14+14,    "Tie pattern to polygon", not flipY)
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

proc createStar(app: var App, xc, yc, r1, r2: float64, n: int, startAngle = 0.0) =
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

proc generatePattern(app: var App) =
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

  app.pattern = newSeq[uint8](size * size * pixWidth)
  app.patternRbuf.attach(app.pattern[0].addr, size, size, size*pixWidth)

  var
    pixf = initPixFmt(app.patternRbuf)
    rb   = initRendererBase(pixf)
    rs   = initRendererScanlineAASolid(rb)

  rb.clear(rgbaPre(0.4, 0.0, 0.1, app.patternAlpha.value())) #Pattern background color

  app.ras.addPath(smooth)
  rs.color(initRgba8(110,130,50))
  renderScanlines(app.ras, app.sl, rs)

  app.ras.addPath(stroke)
  rs.color(initRgba8(0,50,80))
  renderScanlines(app.ras, app.sl, rs)

proc onDraw() =
  var
    app    = initApp()
    initialWidth = frameWidth.float64
    initialHeight = frameHeight.float64

  app.polygonCx = initialWidth / 2.0
  app.polygonCy = initialHeight / 2.0
  app.generatePattern()

  var
    buffer  = newString(frameWidth * frameHeight * pixWidth)
    rbuf    = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    width   = frameWidth.float64
    height  = frameHeight.float64
    pixf    = initPixFmt(rbuf)
    pixfPre = initPixFmtPre(rbuf)
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    mtx     = initTransAffine()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  mtx *= transAffineTranslation(-app.polygonCx, -app.polygonCy)
  mtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
  mtx *= transAffineScaling(app.polygonScale.value())
  mtx *= transAffineTranslation(app.polygonCx, app.polygonCy)

  var r = initialWidth / 3.0 - 8.0
  app.createStar(app.polygonCx, app.polygonCy, r, r / 1.45, 14)

  type
    WrapX = WrapModeRepeatAutoPow2
    WrapY = WrapModeRepeatAutoPow2

  var
    tr = initConvTransform(app.ps, mtx)
    imgPixf = initPixFmt(app.patternRbuf)
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

  saveBMP("pattern_fill.bmp", buffer, frameWidth, frameHeight)

onDraw()