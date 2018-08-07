import agg/[basics, rendering_buffer, rasterizer_scanline_aa, conv_curve,
  conv_contour, conv_stroke, scanline_p, renderer_scanline, pixfmt_rgb,
  color_rgba, renderer_base, path_storage, trans_affine, conv_transform]
import platform/support, ctrl/[slider, rbox, cbox]

const
  frameWidth = 440
  frameHeight = 330
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    close: RboxCtrl[Rgba8]
    width: SliderCtrl[Rgba8]
    autoDetect: CboxCtrl[Rgba8]
    path: PathStorage

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.close = newRboxCtrl[Rgba8](10.0, 10.0, 130.0, 80.0, not flipY)
  result.width = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 130 + 300.0, 10.0 + 8.0 + 4.0, not flipY)
  result.autoDetect = newCboxCtrl[Rgba8](130 + 10.0, 10.0 + 4.0 + 16.0,
    "Autodetect orientation if not defined", not flipY)

  result.addCtrl(result.close)
  result.addCtrl(result.width)
  result.addCtrl(result.autoDetect)

  result.close.addItem("Close")
  result.close.addItem("Close CW")
  result.close.addItem("Close CCW")
  result.close.curItem(0)
  result.width.setRange(-100.0, 100.0)
  result.width.value(0.0)
  result.width.label("Width=$1")
  result.path = initPathStorage()

proc composePath(app: App) =

  var flag = 0.uint
  if app.close.curItem() == 1: flag = pathFlagsCw
  if app.close.curItem() == 2: flag = pathFlagsCcw

  app.path.removeAll()
  app.path.moveTo(28.47, 6.45)
  app.path.curve3(21.58, 1.12, 19.82, 0.29)
  app.path.curve3(17.19, -0.93, 14.21, -0.93)
  app.path.curve3(9.57, -0.93, 6.57, 2.25)
  app.path.curve3(3.56, 5.42, 3.56, 10.60)
  app.path.curve3(3.56, 13.87, 5.03, 16.26)
  app.path.curve3(7.03, 19.58, 11.99, 22.51)
  app.path.curve3(16.94, 25.44, 28.47, 29.64)
  app.path.lineTo(28.47, 31.40)
  app.path.curve3(28.47, 38.09, 26.34, 40.58)
  app.path.curve3(24.22, 43.07, 20.17, 43.07)
  app.path.curve3(17.09, 43.07, 15.28, 41.41)
  app.path.curve3(13.43, 39.75, 13.43, 37.60)
  app.path.lineTo(13.53, 34.77)
  app.path.curve3(13.53, 32.52, 12.38, 31.30)
  app.path.curve3(11.23, 30.08, 9.38, 30.08)
  app.path.curve3(7.57, 30.08, 6.42, 31.35)
  app.path.curve3(5.27, 32.62, 5.27, 34.81)
  app.path.curve3(5.27, 39.01, 9.57, 42.53)
  app.path.curve3(13.87, 46.04, 21.63, 46.04)
  app.path.curve3(27.59, 46.04, 31.40, 44.04)
  app.path.curve3(34.28, 42.53, 35.64, 39.31)
  app.path.curve3(36.52, 37.21, 36.52, 30.71)
  app.path.lineTo(36.52, 15.53)
  app.path.curve3(36.52, 9.13, 36.77, 7.69)
  app.path.curve3(37.01, 6.25, 37.57, 5.76)
  app.path.curve3(38.13, 5.27, 38.87, 5.27)
  app.path.curve3(39.65, 5.27, 40.23, 5.62)
  app.path.curve3(41.26, 6.25, 44.19, 9.18)
  app.path.lineTo(44.19, 6.45)
  app.path.curve3(38.72, -0.88, 33.74, -0.88)
  app.path.curve3(31.35, -0.88, 29.93, 0.78)
  app.path.curve3(28.52, 2.44, 28.47, 6.45)
  app.path.closePolygon(flag)

  app.path.moveTo(28.47, 9.62)
  app.path.lineTo(28.47, 26.66)
  app.path.curve3(21.09, 23.73, 18.95, 22.51)
  app.path.curve3(15.09, 20.36, 13.43, 18.02)
  app.path.curve3(11.77, 15.67, 11.77, 12.89)
  app.path.curve3(11.77, 9.38, 13.87, 7.06)
  app.path.curve3(15.97, 4.74, 18.70, 4.74)
  app.path.curve3(22.41, 4.74, 28.47, 9.62)
  app.path.closePolygon(flag)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    mtx    = initTransAffine()
    trans  = initConvTransform(app.path, mtx)
    curve  = initConvCurve(trans)
    contour = initConvContour(curve)

  rb.clear(initRgba(1.0, 1.0, 1.0))
  mtx *= transAffineScaling(4.0)
  mtx *= transAffineTranslation(150, 100)

  contour.width(app.width.value())
  #contour.inner_join(agg::inner_bevel);
  #contour.line_join(agg::miter_join);
  #contour.inner_line_join(agg::miter_join);
  #contour.inner_miter_limit(4.0);
  contour.autoDetectOrientation(app.autoDetect.status())

  app.composePath()
  ras.addPath(contour)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0,0,0))

  renderCtrl(ras, sl, rb, app.close)
  renderCtrl(ras, sl, rb, app.width)
  renderCtrl(ras, sl, rb, app.autoDetect)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Contour Tool & Polygon Orientation")

  if app.init(frameWidth, frameHeight, {}, "conv_contour"):
    return app.run()

  result = 1

discard main()
