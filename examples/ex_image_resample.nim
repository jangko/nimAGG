import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  renderer_scanline, path_storage, conv_transform, trans_affine, image_filters,
  trans_bilinear, trans_perspective, span_interpolator_linear, pixfmt_rgba,
  span_interpolator_trans, span_allocator, image_accessors, gamma_lut,
  span_image_filter_rgba, renderer_base, color_rgba, span_subdiv_adaptor,
  span_interpolator_persp, gsv_text, conv_stroke]
import strutils, os, math, ctrl/[slider, rbox, polygon], platform/support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre

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
  result.oldGamma = 2.0

  result.addCtrl(result.quad)
  result.addCtrl(result.transType)
  result.addCtrl(result.gamma)
  result.addCtrl(result.blur)

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
  app.x1 = 0.0
  app.y1 = 0.0
  app.x2 = app.rbufImg(0).width().float64
  app.y2 = app.rbufImg(0).height().float64

  var
    x1 = app.x1
    y1 = app.y1
    x2 = app.x2
    y2 = app.y2
    dx = app.width() / 2.0 - (x2 - x1) / 2.0
    dy = app.height() / 2.0 - (y2 - y1) / 2.0

  app.quad.xn(0) = floor(x1 + dx)
  app.quad.yn(0) = floor(y1 + dy)
  app.quad.xn(1) = floor(x2 + dx)
  app.quad.yn(1) = floor(y1 + dy)
  app.quad.xn(2) = floor(x2 + dx)
  app.quad.yn(2) = floor(y2 + dy)
  app.quad.xn(3) = floor(x1 + dx)
  app.quad.yn(3) = floor(y2 + dy)

  var pixf = initPixfmtRgba32(app.rbufImg(0))
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
    if app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
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
  ren.color(initRgba(0.3, 0.5, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  # Prepare the polygon to rasterize. Here we need to fill
  # the destination (transformed) polygon.
  app.ras.clipBox(0, 0, width, height)
  app.ras.reset()

  var b = 0.0
  app.ras.moveToD(app.quad.xn(0)-b, app.quad.yn(0)-b)
  app.ras.lineToD(app.quad.xn(1)+b, app.quad.yn(1)-b)
  app.ras.lineToD(app.quad.xn(2)+b, app.quad.yn(2)+b)
  app.ras.lineToD(app.quad.xn(3)-b, app.quad.yn(3)+b)

  var
    sa = initSpanAllocator[Rgba8]()
    filterKernel: ImageFilterBilinear
    filter  = initImageFilterLut(filterKernel, false)
    pixfImg = initPixfmtRgba32(app.rbufImg(0))
    imgSrc  = initImageAccessorClone(pixfImg)

  app.startTimer()
  case app.transType.curItem()
  of 0:
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)

    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 1:
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageResampleRgbaAffine(imgSrc, inter, filter)

    sg.blur(app.blur.value())
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 2:
    var
      mtx   = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinearSubdiv(mtx)
      sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 3:
    var mtx   = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
    if mtx.isValid():
      var
        inter = initSpanInterpolatorTrans(mtx)
        sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)

      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 4:
    var
      inter = initSpanInterpolatorPerspLerp(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      subdivAdaptor = initSpanSubdivAdaptor(inter)

    if inter.isValid():
      var sg = initSpanImageResampleRgba(imgSrc, subdivAdaptor, filter)
      sg.blur(app.blur.value())
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 5:
    var
      inter = initSpanInterpolatorPerspExact(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      subdivAdaptor = initSpanSubdivAdaptor(inter)

    if inter.isValid():
      var sg = initSpanImageResampleRgba(imgSrc, subdivAdaptor, filter)
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
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("AGG Example. Image Transformations with Resampling")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  if app.init(frameWidth, frameHeight, {window_resize}, "image_resample"):
    return app.run()

  result = 1

discard main()
