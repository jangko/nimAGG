import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_trans_warp_magnifier
import agg_conv_segmentator, agg_bounding_rect, agg_color_rgba, agg_pixfmt_rgb
import agg_renderer_base, parse_lion, agg_platform_support
import ctrl_slider, math, agg_trans_affine

const
  frameWidth = 500
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mRadius: SliderCtrl[Rgba8]
    mMagn: SliderCtrl[Rgba8]
    lion: Lion
    x1, y1: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)
  result.mMagn   = newSliderCtrl[Rgba8](5,   5, 495,  12, not flipY)
  result.mRadius = newSliderCtrl[Rgba8](5,  20, 495,  27, not flipY)

  result.lion   = parseLion(frameWidth, frameHeight)
  result.addCtrl(result.mMagn)
  result.addCtrl(result.mRadius)

  result.mMagn.noTransform()
  result.mMagn.setRange(0.01, 4.0)
  result.mMagn.value(3.0)
  result.mMagn.label("Scale=$1")


  result.mRadius.noTransform()
  result.mRadius.setRange(0.0, 100.0)
  result.mRadius.value(70.0)
  result.mRadius.label("Radius=$1")

method onInit(app: App) =
  app.x1 = 200.0
  app.y1 = 150.0

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    mMagn   = app.mMagn.value()
    mRadius = app.mRadius.value()

  rb.clear(initRgba(1, 1, 1))

  var lens = initTransWarpMagnifier()
  lens.center(app.x1, app.y1)
  lens.magnification(mMagn)

  lens.radius(mRadius / mMagn)
  var mtx = initTransAffine()
  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineRotation(app.lion.angle + pi)
  mtx *= transAffineTranslation(app.width()/2, app.height()/2)

  var
    segm = initConvSegmentator(app.lion.path)
    transMtx = initConvTransform(segm, mtx)
    transLens = initConvTransform(transMtx, lens)

  renderAllPaths(ras, sl, ren, transLens, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)
  renderCtrl(ras, sl, rb, app.mMagn)
  renderCtrl(ras, sl, rb, app.mRadius)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.x1 = x.float64
    app.y1 = y.float64
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  app.onMouseButtonDown(x, y, flags)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Lion")

  if app.init(frameWidth, frameHeight, {window_resize}, "lion_lens"):
    return app.run()

  result = 1

discard main()
