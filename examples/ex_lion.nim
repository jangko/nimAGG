import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, path_storage, conv_transform, bounding_rect, pixfmt_rgb,
  color_rgba, renderer_base, trans_affine, path_length]
import parse_lion, platform.support, ctrl.slider, math

const
  frameWidth = 512
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mAlpha: SliderCtrl[Rgba8]
    lion: Lion

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mAlpha = newSliderCtrl[Rgba8](5, 5, 512-5, 12, not flipY)
  result.lion   = parseLion(frameWidth, frameHeight)

  result.addCtrl(result.mAlpha)
  result.mAlpha.noTransform()
  result.mAlpha.label("Alpha $1")
  result.mAlpha.value(0.8)

method onResize(app: App, sx, sy: int) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)
  rb.clear(initRgba(1, 1, 1))

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
    alpha  = app.mAlpha.value()

  for i in 0.. <app.lion.numPaths:
    app.lion.colors[i].a = uint8(alpha * 255)

  var mtx = initTransAffine()
  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineScaling(app.lion.scale, app.lion.scale)
  mtx *= transAffineRotation(app.lion.angle + pi)
  mtx *= transAffineSkewing(app.lion.skewX/1000.0, app.lion.skewY/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)

  # This code renders the lion:
  var trans = initConvTransform(app.lion.path, mtx)
  renderAllPaths(ras, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  renderCtrl(ras, sl, rb, app.mAlpha)

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

  if app.init(frameWidth, frameHeight, {window_resize}, "lion"):
    return app.run()

  result = 1

discard main()
