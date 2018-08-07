import agg/[rasterizer_scanline_aa, ellipse, trans_affine, conv_transform,
  scanline_u, scanline_p, image_accessors, renderer_scanline, color_rgba,
  span_allocator, span_interpolator_linear, pixfmt_rgb, span_image_filter_rgb,
  rendering_buffer, renderer_base, gsv_text, conv_stroke, basics, image_filters]
import ctrl/[slider, rbox, cbox], os, strutils, math, platform/support

const
  flipY = true

type
  PixFmt = PixFmtBgr24
  PixFmtPre = PixFmtBgr24Pre

  App = ref object of PlatformSupport
    radius, step: SliderCtrl[Rgba8]
    filters: RboxCtrl[Rgba8]
    normalize: CboxCtrl[Rgba8]
    runTest: CboxCtrl[Rgba8]
    singleStep: CboxCtrl[Rgba8]
    refresh: CboxCtrl[Rgba8]
    curAngle: float64
    curFilter, numSteps: int
    numPix: float64
    time1, time2: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.step   = newSliderCtrl[Rgba8](115,  5,    400, 11,     not flipY)
  result.radius = newSliderCtrl[Rgba8](115,  5+15, 400, 11+15,  not flipY)
  result.filters    = newRboxCtrl[Rgba8](0.0, 0.0, 110.0, 210.0, not flipY)
  result.normalize  = newCboxCtrl[Rgba8](8.0, 215.0, "Normalize Filter", not flipY)
  result.runTest    = newCboxCtrl[Rgba8](8.0, 245.0, "RUN Test!", not flipY)
  result.singleStep = newCboxCtrl[Rgba8](8.0, 230.0, "Single Step", not flipY)
  result.refresh    = newCboxCtrl[Rgba8](8.0, 265.0, "Refresh", not flipY)

  result.addCtrl(result.step)
  result.addCtrl(result.radius)
  result.addCtrl(result.filters)
  result.addCtrl(result.normalize)
  result.addCtrl(result.runTest)
  result.addCtrl(result.singleStep)
  result.addCtrl(result.refresh)

  result.curAngle = 0.0
  result.curFilter = 1

  result.numSteps = 0
  result.numPix = 0.0

  result.time1 = 0.0
  result.time2 = 0.0
  result.runTest.textSize(7.5)
  result.singleStep.textSize(7.5)
  result.normalize.textSize(7.5)
  result.refresh.textSize(7.5)
  result.normalize.status(true)

  result.radius.label("Filter Radius=$1")
  result.step.label("Step=$1")
  result.radius.setRange(2.0, 8.0)
  result.radius.value(4.0)
  result.step.setRange(1.0, 10.0)
  result.step.value(5.0)

  result.filters.addItem("simple (NN)")
  result.filters.addItem("bilinear")
  result.filters.addItem("bicubic")
  result.filters.addItem("spline16")
  result.filters.addItem("spline36")
  result.filters.addItem("hanning")
  result.filters.addItem("hamming")
  result.filters.addItem("hermite")
  result.filters.addItem("kaiser")
  result.filters.addItem("quadric")
  result.filters.addItem("catrom")
  result.filters.addItem("gaussian")
  result.filters.addItem("bessel")
  result.filters.addItem("mitchell")
  result.filters.addItem("sinc")
  result.filters.addItem("lanczos")
  result.filters.addItem("blackman")
  result.filters.curItem(0)

  result.filters.borderWidth(0, 0)
  result.filters.backgroundColor(initRgba(0.0, 0.0, 0.0, 0.1))
  result.filters.textSize(6.0)
  result.filters.textThickness(0.85)

proc transformImage(app: App, angle: float64) =
  var
    width   = app.rbufImg(0).width().float64
    height  = app.rbufImg(0).height().float64
    pixf    = construct(PixFmt, app.rbufImg(0))
    pixfPre = construct(PixfmtPre, app.rbufImg(0))
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    ras     = initRasterizerScanlineAA()
    sl      = initScanlineU8()
    sa      = initSpanAllocator[Rgba8]()
    srcMtx  = initTransAffine()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  srcMtx *= transAffineTranslation(-width/2.0, -height/2.0)
  srcMtx *= transAffineRotation(angle * pi / 180.0)
  srcMtx *= transAffineTranslation(width/2.0, height/2.0)

  var imgMtx = srcMtx
  imgMtx.invert()

  var r = width
  if height < r: r = height

  r *= 0.5
  r -= 4.0
  var
    ell   = initEllipse(width / 2.0, height / 2.0, r, r, 200)
    tr    = initConvTransform(ell, srcMtx)
    inter = initSpanInterpolatorLinear(imgMtx)
    filter  = initImageFilterLut()
    norm    = app.normalize.status()
    pixfImg = construct(PixFmt, app.rbufImg(1))
    source  = initImageAccessorClip(pixfImg, rgbaPre(0,0,0,0))
    #stroke = initConvStroke(ell)
    #ren = initRendererScanlineAASolid(rb)

  app.numPix += r * r * pi

  #stroke.width(1.5)
  #ras.addPath(stroke)
  #ren.color(initRgba(0.0, 0.0, 0.0))
  #renderScanlines(ras, sl, ren)

  case app.filters.curItem()
  of 0:
    var sg = initSpanImageFilterRgbNN(source, inter)
    ras.addPath(tr)
    renderScanlinesAA(ras, sl, rbPre, sa, sg)
  of 1:
    var sg = initSpanImageFilterRgbBilinearClip(pixfImg, rgbaPre(0,0,0,0), inter)
    ras.addPath(tr)
    renderScanlinesAA(ras, sl, rbPre, sa, sg)
  of 5..7:
    case app.filters.curItem()
    of 5:  filter.calculate(construct(ImageFilterHanning), norm)
    of 6:  filter.calculate(construct(ImageFilterHamming), norm)
    of 7:  filter.calculate(construct(ImageFilterHermite), norm)
    else: discard
    var sg = initSpanImageFilterRgb2x2(source, inter, filter)
    ras.addPath(tr)
    renderScanlinesAA(ras, sl, rbPre, sa, sg)
  of 2,3,4,8,9,10,11,12,13,14,15,16:
    case app.filters.curItem()
    of 2:  filter.calculate(construct(ImageFilterBicubic),                  norm)
    of 3:  filter.calculate(construct(ImageFilterSpline16),                 norm)
    of 4:  filter.calculate(construct(ImageFilterSpline36),                 norm)
    of 8:  filter.calculate(construct(ImageFilterKaiser),                   norm)
    of 9:  filter.calculate(construct(ImageFilterQuadric),                  norm)
    of 10: filter.calculate(construct(ImageFilterCatrom),                   norm)
    of 11: filter.calculate(construct(ImageFilterGaussian),                 norm)
    of 12: filter.calculate(construct(ImageFilterBessel),                   norm)
    of 13: filter.calculate(construct(ImageFilterMitchell),                 norm)
    of 14: filter.calculate(construct(ImageFilterSinc, app.radius.value()),     norm)
    of 15: filter.calculate(construct(ImageFilterLanczos, app.radius.value()),  norm)
    of 16: filter.calculate(construct(ImageFilterBlackman, app.radius.value()), norm)
    else: discard
    var sg = initSpanImageFilterRgb(source, inter, filter)
    ras.addPath(tr)
    renderScanlinesAA(ras, sl, rbPre, sa, sg)
  else:
    discard

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    buf    = "NSteps=" & $app.numSteps
    t      = initGsvText()
    pt     = initConvStroke(t)

  rb.clear(initRgba(1.0, 1.0, 1.0))
  rb.copyFrom(app.rbufImg(0), nil, 110, 35)

  t.startPoint(10.0, 295.0)
  t.size(10.0)
  t.text(buf)
  pt.width(1.5)
  ras.addPath(pt)
  renderScanlinesAASolid(ras, sl, rb, initrgba(0,0,0))

  if app.time1 != app.time2 and app.numPix > 0.0:
    buf = "$1 Kpix/sec" % [(app.numPix / (app.time2 - app.time1)).formatFloat(ffDecimal, 2)]
    t.startPoint(10.0, 310.0)
    t.text(buf)
    ras.addPath(pt)
    renderScanlinesAASolid(ras, sl, rb, initRgba(0,0,0))

  if app.filters.curItem() >= 14:
    renderCtrl(ras, sl, rb, app.radius)

  renderCtrl(ras, sl, rb, app.step)
  renderCtrl(ras, sl, rb, app.filters)
  renderCtrl(ras, sl, rb, app.runTest)
  renderCtrl(ras, sl, rb, app.normalize)
  renderCtrl(ras, sl, rb, app.singleStep)
  renderCtrl(ras, sl, rb, app.refresh)

method onCtrlChange(app: App) =
  if app.singleStep.status():
    app.curAngle += app.step.value()
    app.copyImgToImg(1, 0)
    app.transformImage(app.step.value())
    inc app.numSteps
    app.forceRedraw()
    app.singleStep.status(false)

  if app.runTest.status():
    app.startTimer()
    app.time2 = app.elapsedTime()
    app.time1 = app.time2
    app.numPix = 0.0
    app.waitMode(false)

  if app.refresh.status() or app.filters.curItem() != app.curFilter:
    app.startTimer()
    app.time1 = 0
    app.time2 = 0
    app.numPix = 0.0
    app.curAngle = 0.0
    app.copyImgToImg(1, 2)
    app.transformImage(0.0)
    app.refresh.status(false)
    app.curFilter = app.filters.curItem()
    app.numSteps = 0
    app.forceRedraw()

method onIdle(app: App) =
  if app.runTest.status():
    if app.curAngle < 360.0:
      app.curAngle += app.step.value()
      app.copyImgToImg(1, 0)
      app.startTimer()
      app.transformImage(app.step.value())
      app.time2 += app.elapsedTime()
      inc app.numSteps
    else:
      app.curAngle = 0.0
      app.waitMode(true)
      app.runTest.status(false)
    app.forceRedraw()
  else:
    app.waitMode(true)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Image transformation filters comparison")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  app.copyImgToImg(1, 0)
  app.copyImgToImg(2, 0)
  app.transformImage(0.0)

  var
    w = app.rbufImg(0).width() + 110
    h = app.rbufImg(0).height() + 40

  if w < 305: w = 305
  if h < 325: h = 325

  if app.init(w, h, {}, "image_filters"):
    return app.run()

  result = 1

discard main()
