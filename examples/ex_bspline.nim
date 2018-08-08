import agg/[rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, conv_bspline, basics, color_rgba, pixfmt_rgb,
  renderer_base, conv_stroke]
import ctrl/[cbox, slider, polygon]
import platform/support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    mPoly: PolygonCtrl[Rgba8]
    mNumPoints: SliderCtrl[Rgba8]
    mClose: CboxCtrl[Rgba8]
    mFlip: int

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mPoly = newPolygonCtrl[Rgba8](6, 5.0)
  result.mNumPoints = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mClose = newCboxCtrl[Rgba8](350, 5.0,  "Close", not flipY)
  result.mflip = 0

  result.addCtrl(result.mPoly)
  result.addCtrl(result.mNumPoints)
  result.addCtrl(result.mClose)

  result.mNumPoints.setRange(1.0, 40.0)
  result.mNumPoints.value(20.0)
  result.mNumPoints.label("Number of intermediate Points = $1")

  if result.mflip != 0:
    result.mPoly.xn(0) = 100
    result.mPoly.yn(0) = frameHeight - 100
    result.mPoly.xn(1) = frameWidth - 100
    result.mPoly.yn(1) = frameHeight - 100
    result.mPoly.xn(2) = frameWidth - 100
    result.mPoly.yn(2) = 100
    result.mPoly.xn(3) = 100
    result.mPoly.yn(3) = 100
  else:
    result.mPoly.xn(0) = 100
    result.mPoly.yn(0) = 100
    result.mPoly.xn(1) = frameWidth - 100
    result.mPoly.yn(1) = 100
    result.mPoly.xn(2) = frameWidth - 100
    result.mPoly.yn(2) = frameHeight - 100
    result.mPoly.xn(3) = 100
    result.mPoly.yn(3) = frameHeight - 100

  result.mPoly.xn(4) = frameWidth.float64 / 2.0
  result.mPoly.yn(4) = frameHeight.float64 / 2.0
  result.mPoly.xn(5) = frameWidth.float64 / 2.0
  result.mPoly.yn(5) = frameHeight.float64 / 3.0

method onDraw(app: App) =
  var
    pf   = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pf)
    sl   = initScanlineP8()
    ras  = initRasterizerScanlineAA()

  rb.clear(initRgba(1.0, 1.0, 0.95))

  var
    path    = initSimplePolygonVertexSource(app.mPoly.polygon(), app.mPoly.numPoints(), false, app.mClose.status())
    bspline = initConvBspline(path)
    stroke  = initConvStroke(bspline)

  bspline.interpolationStep(1.0 / app.mNumPoints.value())
  stroke.width(2.0)
  ras.addPath(stroke)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0, 0, 0))

  # Render the "poly" tool and controls
  ras.addPath(app.mPoly)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0, 0.3, 0.5, 0.6))

  renderCtrl(ras, sl, rb, app.mClose)
  renderCtrl(ras, sl, rb, app.mNumPoints)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. BSpline Interpolator")

  if app.init(frameWidth, frameHeight, {window_resize}, "bspline"):
    return app.run()

  result = 1

discard main()
