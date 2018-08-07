import agg/[basics, rendering_buffer, rasterizer_scanline_aa, renderer_outline_aa,
  rasterizer_outline_aa, scanline_p, renderer_scanline, path_storage, conv_transform,
  bounding_rect, pixfmt_rgb, renderer_base, color_rgba, trans_affine,
  conv_stroke, gamma_functions]
import ctrl/slider, ctrl/cbox, math, platform/support, parse_lion

const
  frameWidth = 512
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mWidth: SliderCtrl[Rgba8]
    mScanline: CBoxCtrl[Rgba8]
    lion: Lion

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mWidth    = newSliderCtrl[Rgba8](5, 5, 150, 12, not flipY)
  result.mScanline = newCBoxCtrl[Rgba8](160, 5, "Use Scanline Rasterizer", not flipY)

  result.lion   = parseLion(frameWidth, frameHeight)
  result.addCtrl(result.mWidth)
  result.addCtrl(result.mScanline)

  result.mWidth.noTransform()
  result.mWidth.setRange(0.0, 4.0)
  result.mWidth.value(1.0)
  result.mWidth.label("Width $1")

  result.mScanline.noTransform()

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)
    ren = initRendererScanlineAASolid(rb)
    sl  = initScanlineP8()
    ras = initRasterizerScanlineAA()

  let
    width  = app.width()
    height = app.height()
    mode   = app.mScanline.status()
    kWidth = app.mWidth.value()

  rb.clear(initRgba(1,1,1))

  var mtx = initTransAffine()
  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineScaling(app.lion.scale, app.lion.scale)
  mtx *= transAffineRotation(app.lion.angle + pi)
  mtx *= transAffineSkewing(app.lion.skewX/1000.0, app.lion.skewY/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)

  if mode:
    var stroke = initConvStroke(app.lion.path)
    stroke.width(kWidth)
    stroke.lineJoin(roundJoin)
    var trans = initConvTransform(stroke, mtx)
    renderAllPaths(ras, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)
  else:
    var
      w       = kWidth * mtx.scale()
      gammaF  = initGammaNone()
      profile = initLineProfileAA(w, gammaF)
      renc    = initRendererOutlineAA(rb, profile)
      rasc    = initRasterizerOutlineAA(renc)
      trans   = initConvTransform(app.lion.path, mtx)

    renderAllPaths(rasc, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  renderCtrl(ras, sl, rb, app.mWidth)
  renderCtrl(ras, sl, rb, app.mScanline)

proc transform(app: App, width, height, x, y: float64) =
  var
    x = x - width / 2
    y = y - height / 2
  app.lion.angle = arctan2(y, x)
  app.lion.scale = sqrt(y * y + x * x) / 100.0

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    var
      width = app.rbufWindow().width().float64
      height = app.rbufWindow().height().float64
    app.transform(width, height, x.float64, y.float64)
    app.forceRedraw()

  if mouseRight in flags:
    app.lion.skewX = x.float64
    app.lion.skewY = y.float64
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  app.onMouseButtonDown(x, y, flags)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Lion")

  if app.init(frameWidth, frameHeight, {window_resize}, "lion_outline"):
    return app.run()

  result = 1

discard main()
