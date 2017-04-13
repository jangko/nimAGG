import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_ellipse
import agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_pixfmt_rgb, agg_scanline_p, agg_renderer_scanline, agg_image_filters
import agg_renderer_base, agg_color_rgba, agg_path_storage, nimBMP
import math, agg_basics, strutils, ctrl_slider, ctrl_cbox

type
  FilterBase = ref object of RootObj
    name: string
    radius: proc(): float64
    setRadius: proc(r: float64)
    calcWeight: proc(x: float64): float64

  ImageFNoRadius[Filter] = ref object of FilterBase
    mFilter: Filter

  ImageF[Filter] = ref object of FilterBase
    mFilter: Filter

proc initImageFNoRadius[Filter](name: string): FilterBase =
  var res = new(ImageFNoRadius[Filter])
  res.name = name
  res.mFilter = construct(Filter)
  res.radius = proc(): float64 =
    res.mFilter.radius()

  res.setRadius = proc(r: float64) =
    discard

  res.calcWeight = proc(x: float64): float64 =
    res.mFilter.calcWeight(abs(x))
  result = res

proc initImageF[Filter](name: string): ImageF[Filter] =
  var res = new(ImageF[Filter])
  res.name = name
  res.mFilter = construct(Filter, 2.0)
  res.radius = proc(): float64 =
    res.mFilter.radius()

  res.setRadius = proc(r: float64) =
    res.mFilter = construct(Filter, r)

  res.calcWeight = proc(x: float64): float64 =
    res.mFilter.calcWeight(abs(x))
  result = res

const
  frameWidth = 780
  frameHeight = 300
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

proc initFilters(): array[16, FilterBase] =
  result[0 ] = initImageFNoRadius[ImageFilterBilinear]("bilinear")
  result[1 ] = initImageFNoRadius[ImageFilterBicubic]("bicubic")
  result[2 ] = initImageFNoRadius[ImageFilterSpline16]("spline16")
  result[3 ] = initImageFNoRadius[ImageFilterSpline36]("spline36")
  result[4 ] = initImageFNoRadius[ImageFilterHanning]("hanning")
  result[5 ] = initImageFNoRadius[ImageFilterHamming]("hamming")
  result[6 ] = initImageFNoRadius[ImageFilterHermite]("hermite")
  result[7 ] = initImageFNoRadius[ImageFilterKaiser]("kaiser")
  result[8 ] = initImageFNoRadius[ImageFilterQuadric]("quadric")
  result[9 ] = initImageFNoRadius[ImageFilterCatrom]("catrom")
  result[10] = initImageFNoRadius[ImageFilterGaussian]("gaussian")
  result[11] = initImageFNoRadius[ImageFilterBessel]("bessel")
  result[12] = initImageFNoRadius[ImageFilterMitchell]("mitchell")
  result[13] = initImageF[ImageFilterSinc]("sinc")
  result[14] = initImageF[ImageFilterLanczos]("lanczos")
  result[15] = initImageF[ImageFilterBlackman]("blackman")

type
  App = object
    mRadius: SliderCtrl[Rgba8]
    mBilinear: CboxCtrl[Rgba8]
    mBicubic: CboxCtrl[Rgba8]
    mSpline16: CboxCtrl[Rgba8]
    mSpline36: CboxCtrl[Rgba8]
    mHanning: CboxCtrl[Rgba8]
    mHamming: CboxCtrl[Rgba8]
    mHermite: CboxCtrl[Rgba8]
    mKaiser: CboxCtrl[Rgba8]
    mQuadric: CboxCtrl[Rgba8]
    mCatrom: CboxCtrl[Rgba8]
    mGaussian: CboxCtrl[Rgba8]
    mBessel: CboxCtrl[Rgba8]
    mMitchell: CboxCtrl[Rgba8]
    mSinc: CboxCtrl[Rgba8]
    mLanczos: CboxCtrl[Rgba8]
    mBlackman: CboxCtrl[Rgba8]
    mFilters: array[16, CboxCtrl[Rgba8]]

proc initApp(): App =
  result.mRadius   = newSliderCtrl[Rgba8](5.0, 5.0, 780-5, 10.0,       not flipY)
  result.mBilinear = newCboxCtrl[Rgba8](8.0, 30.0+15*0,  "bilinear", not flipY)
  result.mBicubic  = newCboxCtrl[Rgba8](8.0, 30.0+15*1,  "bicubic ", not flipY)
  result.mSpline16 = newCboxCtrl[Rgba8](8.0, 30.0+15*2,  "spline16", not flipY)
  result.mSpline36 = newCboxCtrl[Rgba8](8.0, 30.0+15*3,  "spline36", not flipY)
  result.mHanning  = newCboxCtrl[Rgba8](8.0, 30.0+15*4,  "hanning ", not flipY)
  result.mHamming  = newCboxCtrl[Rgba8](8.0, 30.0+15*5,  "hamming ", not flipY)
  result.mHermite  = newCboxCtrl[Rgba8](8.0, 30.0+15*6,  "hermite ", not flipY)
  result.mKaiser   = newCboxCtrl[Rgba8](8.0, 30.0+15*7,  "kaiser  ", not flipY)
  result.mQuadric  = newCboxCtrl[Rgba8](8.0, 30.0+15*8,  "quadric ", not flipY)
  result.mCatrom   = newCboxCtrl[Rgba8](8.0, 30.0+15*9,  "catrom  ", not flipY)
  result.mGaussian = newCboxCtrl[Rgba8](8.0, 30.0+15*10, "gaussian", not flipY)
  result.mBessel   = newCboxCtrl[Rgba8](8.0, 30.0+15*11, "bessel  ", not flipY)
  result.mMitchell = newCboxCtrl[Rgba8](8.0, 30.0+15*12, "mitchell", not flipY)
  result.mSinc     = newCboxCtrl[Rgba8](8.0, 30.0+15*13, "sinc    ", not flipY)
  result.mLanczos  = newCboxCtrl[Rgba8](8.0, 30.0+15*14, "lanczos ", not flipY)
  result.mBlackman = newCboxCtrl[Rgba8](8.0, 30.0+15*15, "blackman", not flipY)

  result.mFilters[ 0] = result.mBilinear
  result.mFilters[ 1] = result.mBicubic
  result.mFilters[ 2] = result.mSpline16
  result.mFilters[ 3] = result.mSpline36
  result.mFilters[ 4] = result.mHanning
  result.mFilters[ 5] = result.mHamming
  result.mFilters[ 6] = result.mHermite
  result.mFilters[ 7] = result.mKaiser
  result.mFilters[ 8] = result.mQuadric
  result.mFilters[ 9] = result.mCatrom
  result.mFilters[10] = result.mGaussian
  result.mFilters[11] = result.mBessel
  result.mFilters[12] = result.mMitchell
  result.mFilters[13] = result.mSinc
  result.mFilters[14] = result.mLanczos
  result.mFilters[15] = result.mBlackman

  result.mRadius.setRange(2.0, 8.0)
  result.mRadius.value(4.0)
  result.mRadius.label("Radius=$1")

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()

    initial_width = frameWidth.float64
    initial_height = frameHeight.float64
    x_start  = 125.0
    x_end    = initial_width - 15.0
    y_start  = 10.0
    y_end    = initial_height - 10.0
    x_center = (x_start + x_end) / 2
    ys = y_start + (y_end - y_start) / 6.0
    mRadius = 4.0

    path   = initPathStorage()
    pl     = initConvStroke(path)
    mtx    = initTransAffine()
    tr     = initConvTransform(pl, mtx)
    filters = initFilters()


  proc setBackground() =
    rb.clear(initRgba(1.0, 1.0, 1.0))

    for i in 0..16:
      let x = x_start + (x_end - x_start) * i.float / 16.0
      path.removeAll()
      path.moveTo(x+0.5, y_start)
      path.lineTo(x+0.5, y_end)
      ras.addPath(tr)
      ren.color(initRgba8(0, 0, 0, if i == 8: 255 else: 100))
      renderScanlines(ras, sl, ren)

    path.removeAll()
    path.moveTo(x_start, ys)
    path.lineTo(x_end,   ys)
    ras.addPath(tr)
    ren.color(initRgba8(0, 0, 0))
    renderScanlines(ras, sl, ren)
    pl.width(1.0)

  var i = 0
  for filter in filters:
    for c in app.mFilters:
      c.status(false)

    app.mFilters[i].status(true)

    setBackground()
    filter.setRadius(mRadius)
    var
      radius = filter.radius()
      n = int(radius * 256 * 2)
      dy = y_end - ys
      xs = (x_end + x_start)/2.0 - (radius * (x_end - x_start) / 16.0)
      dx = (x_end - x_start) * radius / 8.0

    path.removeAll()
    path.moveTo(xs+0.5, ys + dy * filter.calcWeight(-radius))
    for j in 1.. <n:
      path.lineTo(xs + dx * j.float64 / n.float64 + 0.5, ys + dy * filter.calcWeight(j.float64 / 256.0 - radius))

    ras.addPath(tr)
    ren.color(initRgba8(100, 0, 0))
    renderScanlines(ras, sl, ren)

    path.removeAll()
    let ir = int(ceil(radius) + 0.1)

    for xint in 0..255:
      var sum = 0.0
      for xfract in -ir.. <ir:
        var xf = xint.float64/256.0 + xfract.float64
        if xf >= -radius or xf <= radius:
          sum += filter.calcWeight(xf)

      var
        x = x_center + ((-128.0 + xint.float64) / 128.0) * radius * (x_end - x_start) / 16.0
        y = ys + sum * 256 - 256

      if xint == 0: path.moveTo(x, y)
      else:         path.lineTo(x, y)

    ras.addPath(tr)
    ren.color(initRgba8(0, 100, 0))
    renderScanlines(ras, sl, ren)

    var
      normalized = initImageFilterLut(filter[])
      weights = normalized.weightArray()

    xs = (x_end + x_start)/2.0 - (normalized.diameter().float64 * (x_end - x_start) / 32.0)
    var nn = normalized.diameter() * 256
    path.removeAll()
    path.moveTo(xs+0.5, ys + dy * weights[0].float64 / imageFilterScale)

    for j in 1.. <nn:
      path.lineTo(xs + dx * j.float64 / n.float64 + 0.5, ys + dy * weights[j].float64 / imageFilterScale)

    ras.addPath(tr)
    ren.color(initRgba8(0, 0, 100, 255))
    renderScanlines(ras, sl, ren)

    for c in mitems(app.mFilters):
      renderCtrl(ras, sl, rb, c)

    if app.mSinc.status() or app.mLanczos.status() or app.mBlackman.status():
      renderCtrl(ras, sl, rb, app.mRadius)

    let name = "image_filter_graph_$1_$2.bmp" % [$i, filter.name]
    echo name
    saveBMP24(name, buffer, frameWidth, frameHeight)
    inc i

onDraw()