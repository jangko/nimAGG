import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_trans_affine
import agg_trans_bilinear, agg_trans_perspective, agg_span_interpolator_linear
import agg_span_interpolator_trans, agg_span_allocator, agg_image_accessors
import ctrl_rbox, ctrl_polygon, agg_pixfmt_rgb, agg_span_image_filter_rgb
import agg_renderer_base, agg_color_rgba, strutils, os, math
import agg_image_filters, agg_span_subdiv_adaptor, agg_gamma_lut, ctrl_slider
import agg_span_interpolator_persp, times, agg_gsv_text, agg_conv_stroke
import agg_platform_support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24
  PixFmtPre = PixFmtBgr24Pre

  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    gammaLut: GammaLut8
    gamma, blur: SliderCtrl[Rgba8]

    oldGamma: float64
    quad: PolygonCtrl[Rgba8]
    transType: RboxCtrl[Rgba8]

    testFlag: bool
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    x1, y1, x2, y2: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.gammaLut = initGammaLut8(2.0)
  result.transType = newRboxCtrl[Rgba8](400, 5.0, 430+170.0, 100.0, not flipY)
  result.gamma = newSliderCtrl[Rgba8](5.0, 5.0+15*0, 400-5, 10.0+15*0, not flipY)
  result.blur  = newSliderCtrl[Rgba8](5.0, 5.0+15*1, 400-5, 10.0+15*1, not flipY)

  result.addCtrl(result.quad)
  result.addCtrl(result.transType)
  result.addCtrl(result.gamma)
  result.addCtrl(result.blur)

  result.oldGamma = 2.0
  result.quad.noTransform()

  result.testFlag = false
  result.transType.textSize(7)
  result.transType.textThickness(1)
  result.transType.addItem("Affine No Resample")
  result.transType.addItem("Affine Resample")
  result.transType.addItem("Perspective No Resample LERP")
  result.transType.addItem("Perspective No Resample Exact")
  result.transType.addItem("Perspective Resample LERP")
  result.transType.addItem("Perspective Resample Exact")
  result.transType.curItem(5)

  result.gamma.setRange(0.5, 3.0)
  result.gamma.value(2.0)
  result.gamma.label("Gamma=$1")
  result.blur.setRange(0.5, 2.0)
  result.blur.value(1.0)
  result.blur.label("Blur=$1")

  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()

method onInit(app: App) =
  app.x1  = -150.0
  app.y1  = -150.0
  app.x2  = 150.0
  app.y2  = 150.0

  var
    trans_x1 = -200.0
    trans_y1 = -200.0
    trans_x2 =  200.0
    trans_y2 =  200.0
    dx = frameWidth.float64  / 2.0 - (trans_x2 + trans_x1) / 2.0
    dy = frameHeight.float64 / 2.0 - (trans_y2 + trans_y1) / 2.0

  app.quad.xn(0) = floor(trans_x1 + dx)
  app.quad.yn(0) = floor(trans_y1 + dy)
  app.quad.xn(1) = floor(trans_x2 + dx)
  app.quad.yn(1) = floor(trans_y1 + dy)
  app.quad.xn(2) = floor(trans_x2 + dx)
  app.quad.yn(2) = floor(trans_y2 + dy)
  app.quad.xn(3) = floor(trans_x1 + dx)
  app.quad.yn(3) = floor(trans_y2 + dy)

  var pixf = construct(PixFmt, app.rbufImg(0))
  pixf.applyGammaDir(app.gammaLut)

method onDraw(app: App) =
  var
    width   = app.width()
    height  = app.height()
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfPre = construct(PixFmtPre, app.rbufWindow())
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    ren     = initRendererScanlineAASolid(rb)

  if app.gamma.value() != app.oldGamma:
    app.gammaLut.gamma(app.gamma.value())
    if app.loadImg(0, "resources" & DirSep & "agg.bmp"):
      var pixf = construct(PixFmt, app.rbufImg(0))
      pixf.applyGammaDir(app.gammaLut)
      app.oldGamma = app.gamma.value()

  rb.clear(initRgba(1, 1, 1))

  if app.transType.curItem() == 0:
    # For the affine parallelogram transformations we
    # calculate the 4-th (implicit) point of the parallelogram
    app.quad.xn(3) = app.quad.xn(0) + (app.quad.xn(2) - app.quad.xn(1))
    app.quad.yn(3) = app.quad.yn(0) + (app.quad.yn(2) - app.quad.yn(1))


  # Render the "quad" tool and controls
  app.ras.addPath(app.quad)
  ren.color(initRgba(0, 0.3, 0.5, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  # Prepare the polygon to rasterize. Here we need to fill
  # the destination (transformed) polygon.
  app.ras.clip_box(0, 0, width, height)
  app.ras.reset()

  var b = 0.0
  app.ras.moveToD(app.quad.xn(0)-b, app.quad.yn(0)-b)
  app.ras.lineToD(app.quad.xn(1)+b, app.quad.yn(1)-b)
  app.ras.lineToD(app.quad.xn(2)+b, app.quad.yn(2)+b)
  app.ras.lineToD(app.quad.xn(3)-b, app.quad.yn(3)+b)

  type
    WrapT = WrapModeReflectAutoPow2

  var
    sa = initSpanAllocator[Rgba8]()
    filterKernel: ImageFilterHanning
    filter  = initImageFilterLut(filterKernel, true)
    imgPixf = construct(PixFmt, app.rbufImg(0))
    imgSrc  = initImageAccessorWrap[PixFmt, WrapT, WrapT](imgPixf)

  app.startTimer()
  case app.transType.curItem()
  of 0:
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)

    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 1:
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageResampleRgbAffine(imgSrc, inter, filter)

    sg.blur(app.blur.value())
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 2:
    var
      mtx   = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinearSubdiv(mtx)
      sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 3:
    var mtx   = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
    if mtx.isValid():
      var
        inter = initSpanInterpolatorTrans(mtx)
        sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)

      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 4:
    var
      inter = initSpanInterpolatorPerspLerp(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      subdivAdaptor = initSpanSubdivAdaptor(inter)

    if inter.isValid():
      var sg = initSpanImageResampleRgb(imgSrc, subdivAdaptor, filter)
      sg.blur(app.blur.value())
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 5:
    var
      inter = initSpanInterpolatorPerspExact(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      subdivAdaptor = initSpanSubdivAdaptor(inter)

    if inter.isValid():
      var sg = initSpanImageResampleRgb(imgSrc, subdivAdaptor, filter)
      sg.blur(app.blur.value())
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  else: discard

  let tm = app.elapsedTime()
  pixf.applyGammaInv(app.gammaLut)

  var
    t = initGsvText()
    pt = initConvStroke(t)
    buf = "$1 ms" % [tm.formatFloat(ffDecimal, 2)]

  t.size(10.0)
  pt.width(1.5)
  t.startPoint(10.0, 70.0)
  t.text(buf)

  app.ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(app.ras, app.sl, ren)

  renderCtrl(app.ras, app.sl, rb, app.transType)
  renderCtrl(app.ras, app.sl, rb, app.gamma)
  renderCtrl(app.ras, app.sl, rb, app.blur)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Pattern Transformations with Resampling")

  if not app.loadImg(0, "resources" & DirSep & "agg.bmp"):
    app.message("failed to load agg.bmp")
    return 1

  if app.init(frameWidth, frameHeight, {window_resize}, "pattern_resample"):
    return app.run()

  result = 1

discard main()
