import agg_rasterizer_scanline_aa, agg_ellipse, agg_trans_affine, agg_conv_transform
import agg_scanline_u, agg_scanline_p, agg_image_accessors, agg_renderer_scanline
import agg_span_allocator, agg_span_interpolator_linear, agg_pixfmt_rgb
import agg_span_image_filter_rgb, ctrl_slider, ctrl_rbox, ctrl_cbox
import agg_color_rgba, nimBMP, os, strutils, times, math, agg_rendering_buffer
import agg_renderer_base, agg_gsv_text, agg_conv_stroke, agg_basics
import agg_image_filters

const
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    bmp: seq[BmpResult[string]]
    rbuf: seq[RenderingBuffer]
    radius, step: SliderCtrl[Rgba8]
    filters: RboxCtrl[Rgba8]
    normalize: CboxCtrl[Rgba8]
    run: CboxCtrl[Rgba8]
    singleStep: CboxCtrl[Rgba8]
    refresh: CboxCtrl[Rgba8]
    curAngle: float64
    curFilter, numSteps: int
    numPix: float64
    time1, time2: float64

proc initApp(): App =
  result.step   = newSliderCtrl[Rgba8](115,  5,    400, 11,     not flipY)
  result.radius = newSliderCtrl[Rgba8](115,  5+15, 400, 11+15,  not flipY)
  result.filters = newRboxCtrl[Rgba8](0.0, 0.0, 110.0, 210.0, not flipY)
  result.normalize   = newCboxCtrl[Rgba8](8.0, 215.0, "Normalize Filter", not flipY)
  result.run         = newCboxCtrl[Rgba8](8.0, 245.0, "RUN Test!", not flipY)
  result.single_step = newCboxCtrl[Rgba8](8.0, 230.0, "Single Step", not flipY)
  result.refresh     = newCboxCtrl[Rgba8](8.0, 265.0, "Refresh", not flipY)

  result.curAngle = 0.0
  result.curFilter = 1

  result.numSteps = 0
  result.numPix = 0.0

  result.time1 = 0.0
  result.time2 = 0.0
  result.run.textSize(7.5)
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
  result.bmp = newSeq[BmpResult[string]](10)
  result.rbuf = newSeq[RenderingBuffer](10)

proc loadImage(app: var App, idx: int, name: string) =
  app.bmp[idx] = loadBMP24("resources$1$2.bmp" % [$DirSep, name])
  if app.bmp[idx].width == 0 and app.bmp[idx].width == 0:
    echo "failed to load $1.bmp" % [name]
    quit(0)
  app.rbuf[idx] = initRenderingBuffer(cast[ptr ValueT](app.bmp[idx].data[0].addr),
    app.bmp[idx].width, app.bmp[idx].height, app.bmp[idx].width * pixWidth)

proc rbufImage(app: var App, idx: int): var RenderingBuffer =
  result = app.rbuf[idx]

proc getBmp(app: var App, idx: int): var BmpResult[string] =
  app.bmp[idx]

proc copyImgToImg(app: var App, dst, src: int) =
  deepCopy(app.bmp[dst], app.bmp[src])
  app.rbuf[dst] = initRenderingBuffer(cast[ptr ValueT](app.bmp[dst].data[0].addr),
    app.bmp[dst].width, app.bmp[dst].height, app.bmp[dst].width * pixWidth)

proc transformImage(app: var App, angle: float64) =
  var
    width   = app.rbufImage(0).width().float64
    height  = app.rbufImage(0).height().float64
    pixf    = initPixfmtRgb24(app.rbufImage(0))
    pixfPre = initPixfmtRgb24Pre(app.rbufImage(0))
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
    ell   = initEllipse(width  / 2.0, height / 2.0, r, r, 200)
    tr    = initConvTransform(ell, srcMtx)
    inter = initSpanInterpolatorLinear(imgMtx)
    filter  = initImageFilterLut()
    norm    = app.normalize.status()
    pixfImg = initPixFmtRgb24(app.rbufImage(1))
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

proc onDraw() =
  var app    = initApp()
  app.loadImage(0, "spheres")

  app.copyImgToImg(1, 0)
  app.copyImgToImg(2, 0)
  app.transformImage(0.0)

  var
    w = app.rbufImage(0).width() + 110
    h = app.rbufImage(0).height() + 40

  if w < 305: w = 305
  if h < 325: h = 325

  var
    buffer = newString(w * h * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), w, h, -w * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)

    #mtx    = initTransAffine()
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    buf    = "NSteps=" & $app.numSteps
    t      = initGsvText()
    pt     = initConvStroke(t)

  rb.clear(initRgba(1.0, 1.0, 1.0))
  rb.copyFrom(app.rbufImage(0), nil, 110, 35)

  t.startPoint(10.0, 295.0)
  t.size(10.0)
  t.text(buf)
  pt.width(1.5)
  ras.addPath(pt)
  renderScanlinesAASolid(ras, sl, rb, initrgba(0,0,0))

  if app.time1 != app.time2 and app.numPix > 0.0:

  #when defined(AGG_ACCURATE_TIME):
    buf = "$1 Kpix/sec" % [(app.numPix / (app.time2 - app.time1)).formatFloat(ffDecimal, 2)]
  #else:
    #buf = "$1 Kpix/sec" % [app.numPix / 1000.0 /(double(m_time2 - m_time1) / CLOCKS_PER_SEC))

    t.startPoint(10.0, 310.0)
    t.text(buf)
    ras.addPath(pt)
    renderScanlinesAASolid(ras, sl, rb, initRgba(0,0,0))

  if app.filters.curItem() >= 14:
    renderCtrl(ras, sl, rb, app.radius)

  renderCtrl(ras, sl, rb, app.step)
  renderCtrl(ras, sl, rb, app.filters)
  renderCtrl(ras, sl, rb, app.run)
  renderCtrl(ras, sl, rb, app.normalize)
  renderCtrl(ras, sl, rb, app.singleStep)
  renderCtrl(ras, sl, rb, app.refresh)

  saveBMP24("image_filters.bmp", buffer, w, h)

onDraw()