import agg/[basics, pixfmt_rgb, color_rgba, renderer_base, rasterizer_scanline_aa,
  rendering_buffer, scanline_u, trans_affine, span_interpolator_linear, span_allocator,
  image_accessors, span_image_filter_rgb, renderer_scanline, image_filters, gamma_lut,
  path_storage, conv_stroke]
import strutils, ctrl/[rbox, slider, cbox], platform.support

const
  frameWidth = 500
  frameHeight = 340
  flipY = true

const
  V = 255

let
  image = [0'u8,V,0, 0,0,V, V,V,V, V,0,0,
           V,0,0,    0,0,0, V,V,V, V,V,V,
           V,V,V,    V,V,V, 0,0,V, V,0,0,
           0,0,V,    V,V,V, 0,0,0, 0,V,0,]

proc calcLut(filter: var ImageFilterLut, nb: int, norm: bool, radius: float64) =
  case nb
  of 1:  filter.calculate(construct(ImageFilterBilinear),       norm)
  of 2:  filter.calculate(construct(ImageFilterBicubic),        norm)
  of 3:  filter.calculate(construct(ImageFilterSpline16),       norm)
  of 4:  filter.calculate(construct(ImageFilterSpline36),       norm)
  of 5:  filter.calculate(construct(ImageFilterHanning),        norm)
  of 6:  filter.calculate(construct(ImageFilterHamming),        norm)
  of 7:  filter.calculate(construct(ImageFilterHermite),        norm)
  of 8:  filter.calculate(construct(ImageFilterKaiser),         norm)
  of 9:  filter.calculate(construct(ImageFilterQuadric),        norm)
  of 10: filter.calculate(construct(ImageFilterCatrom),         norm)
  of 11: filter.calculate(construct(ImageFilterGaussian),       norm)
  of 12: filter.calculate(construct(ImageFilterBessel),         norm)
  of 13: filter.calculate(construct(ImageFilterMitchell),       norm)
  of 14: filter.calculate(construct(ImageFilterSinc, radius),     norm)
  of 15: filter.calculate(construct(ImageFilterLanczos, radius),  norm)
  of 16: filter.calculate(construct(ImageFilterBlackman, radius), norm)
  else: discard

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    mGamma: SliderCtrl[Rgba8]
    mRadius: SliderCtrl[Rgba8]
    mFilters: RboxCtrl[Rgba8]
    mNormalize: CboxCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mGamma = newSliderCtrl[Rgba8](115,  5,    500-5, 11,    not flipY)
  result.mRadius = newSliderCtrl[Rgba8](115,  5+15, 500-5, 11+15, not flipY)
  result.mFilters = newRboxCtrl[Rgba8](0.0, 0.0, 110.0, 210.0,  not flipY)
  result.mNormalize = newCboxCtrl[Rgba8](8.0, 215.0, "Normalize Filter", not flipY)

  result.addCtrl(result.mGamma)
  result.addCtrl(result.mRadius)
  result.addCtrl(result.mFilters)
  result.addCtrl(result.mNormalize)

  result.mNormalize.textSize(7.5)
  result.mNormalize.status(true)
  result.mRadius.label("Filter Radius=$1")
  result.mRadius.setRange(2.0, 8.0)
  result.mRadius.value(4.0)
  result.mGamma.label("Gamma=$1")
  result.mGamma.setRange(0.5, 3.0)
  result.mGamma.value(1.0)

  result.mFilters.addItem("simple (NN)")
  result.mFilters.addItem("bilinear")
  result.mFilters.addItem("bicubic")
  result.mFilters.addItem("spline16")
  result.mFilters.addItem("spline36")
  result.mFilters.addItem("hanning")
  result.mFilters.addItem("hamming")
  result.mFilters.addItem("hermite")
  result.mFilters.addItem("kaiser")
  result.mFilters.addItem("quadric")
  result.mFilters.addItem("catrom")
  result.mFilters.addItem("gaussian")
  result.mFilters.addItem("bessel")
  result.mFilters.addItem("mitchell")
  result.mFilters.addItem("sinc")
  result.mFilters.addItem("lanczos")
  result.mFilters.addItem("blackman")
  result.mFilters.curItem(1)
  result.mFilters.borderWidth(0, 0)
  result.mFilters.backgroundColor(initRgba(0.0, 0.0, 0.0, 0.1))
  result.mFilters.textSize(6.0)
  result.mFilters.textThickness(0.85)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

    img    = initRenderingBuffer(cast[ptr ValueT](image[0].unsafeAddr), 4, 4, 4*3)
    para   = [200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0]
    mtx    = initTransAffine(para, 0, 0, 4, 4)
    inter  = initSpanInterpolatorLinear(mtx)
    sa     = initSpanAllocator[Rgba8]()
    pixf   = initPixFmtRgb24(img)
    source = initImageAccessorClone(pixf)
    filter = initImageFilterLut()
    norm   = app.mNormalize.status()
    radius = app.mRadius.value()
    mGamma = app.mGamma.value()
    gamma  = initGammaLut8(mGamma)


  ras.reset()
  ras.moveToD(para[0], para[1])
  ras.lineToD(para[2], para[3])
  ras.lineToD(para[4], para[5])
  ras.lineToD(para[6], para[7])
  rb.clear(initRgba(1, 1, 1))

  let i = app.mFilters.curItem()
  if i == 0:
    var sg = initSpanImageFilterRgbNN(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  else:
    filter.calcLut(i, norm, radius)
    var sg = initSpanImageFilterRgb(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)

    var
      x_start = 5.0
      x_end   = 195.0
      y_start = 235.0
      y_end   = frameHeight.float64 - 5.0
      #x_center = (x_start + x_end) / 2
      p = initPathStorage()
      stroke = initConvStroke(p)

    stroke.width(0.8)
    pf.applyGammaInv(gamma)

    for i in 0..16:
      let x = x_start + (x_end - x_start) * i.float64 / 16.0
      p.removeAll()
      p.moveTo(x+0.5, y_start)
      p.lineTo(x+0.5, y_end)
      ras.addPath(stroke)
      renderScanlinesAAsolid(ras, sl, rb, initRgba8(0, 0, 0, if i == 8: 255 else: 100))

    let ys = y_start + (y_end - y_start) / 6.0
    p.removeAll()
    p.moveTo(x_start, ys)
    p.lineTo(x_end,   ys)
    ras.addPath(stroke)
    renderScanlinesAAsolid(ras, sl, rb, initRgba8(0, 0, 0))

    var
      radius = filter.radius()
      n = uint(radius * 256 * 2)
      dx = (x_end - x_start) * radius / 8.0
      dy = y_end - ys
      weights = filter.weightArray()
      xs = (x_end + x_start)/2.0 - (filter.diameter().float64 * (x_end - x_start) / 32.0)
      nn = filter.diameter() * 256

    p.removeAll()
    p.moveTo(xs+0.5, ys + dy * weights[0].float64 / imageFilterScale.float64)
    for i in 1.. <nn:
      p.lineTo(xs + dx * i.float64 / n.float64 + 0.5, ys + dy * weights[i].float64 / imageFilterScale.float64)

    ras.addPath(stroke)
    renderScanlinesAAsolid(ras, sl, rb, initRgba8(100, 0, 0))

  renderCtrl(ras, sl, rb, app.mGamma)
  if app.mFilters.curItem() >= 14:
    renderCtrl(ras, sl, rb, app.mRadius)

  renderCtrl(ras, sl, rb, app.mFilters)
  renderCtrl(ras, sl, rb, app.mNormalize)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Image transformation filters comparison")

  if app.init(frameWidth, frameHeight, {window_resize}, "image_filters2"):
    return app.run()

  result = 1

discard main()
