import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_ellipse
import agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_pixfmt_rgb, agg_scanline_p, agg_renderer_scanline, agg_image_filters
import agg_renderer_base, agg_color_rgba, agg_path_storage, nimBMP
import math, agg_basics, strutils

type
  FilterBase = object of RootObj
    name: string
    radiusI: proc(self: FilterBase): float64
    setRadiusI: proc(self: var FilterBase, r: float64)
    calcWeightI: proc(self: FilterBase, x: float64): float64

proc radius(self: FilterBase): float64 =
  self.radiusI(self)

proc radius(self: var FilterBase, r: float64) =
  self.setRadiusI(self, r)

proc calcWeight(self: FilterBase, x: float64): float64 =
  self.calcWeightI(self, x)

type
  ImageFNoRadius[Filter] = object of FilterBase
    mFilter: Filter

proc FNR_Radius[Filter](self: FilterBase): float64 =
  type selfT = ImageFNoRadius[Filter]
  selfT(self).mFilter.radius()

proc FNR_SetRadius[Filter](self: var FilterBase, r: float64) =
  discard

proc FNR_CalcWeight[Filter](self: FilterBase, x: float64): float64 =
  type selfT = ImageFNoRadius[Filter]
  selfT(self).mFilter.calcWeight(abs(x))

proc initImageFNoRadius[Filter](name: string): ImageFNoRadius[Filter] =
  result.name = name
  result.mFilter = construct(Filter)
  result.radiusI = FNR_Radius[Filter]
  result.setRadiusI = FNR_SetRadius[Filter]
  result.calcWeightI = FNR_CalcWeight[Filter]

type
  ImageF[Filter] = object of FilterBase
    mFilter: Filter

proc F_Radius[Filter](self: FilterBase): float64 =
  type selfT = ImageF[Filter]
  selfT(self).mFilter.radius()

proc F_SetRadius[Filter](self: var FilterBase, r: float64) =
  type selfT = ImageF[Filter]
  selfT(self).mFilter = construct(Filter, r)

proc F_CalcWeight[Filter](self: FilterBase, x: float64): float64 =
  type selfT = ImageF[Filter]
  selfT(self).mFilter.calcWeight(abs(x))

proc initImageF[Filter](name: string): ImageF[Filter] =
  result.name = name
  result.mFilter = construct(Filter, 2.0)
  result.radiusI = F_Radius[Filter]
  result.setRadiusI = F_SetRadius[Filter]
  result.calcWeightI = F_CalcWeight[Filter]

const
  frameWidth = 780
  frameHeight = 300
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
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

    filter1 = initImageFNoRadius[ImageFilterBilinear]("bilinear")
    filter2 = initImageFNoRadius[ImageFilterBicubic]("bicubic")
    filter3 = initImageFNoRadius[ImageFilterSpline16]("spline16")
    filter4 = initImageFNoRadius[ImageFilterSpline36]("spline36")
    filter5 = initImageFNoRadius[ImageFilterHanning]("hanning")
    filter6 = initImageFNoRadius[ImageFilterHamming]("hamming")
    filter7 = initImageFNoRadius[ImageFilterHermite]("hermite")
    filter8 = initImageFNoRadius[ImageFilterKaiser]("kaiser")
    filter9 = initImageFNoRadius[ImageFilterQuadric]("quadric")
    filter10 = initImageFNoRadius[ImageFilterCatrom]("catrom")
    filter11 = initImageFNoRadius[ImageFilterGaussian]("gaussian")
    filter12 = initImageFNoRadius[ImageFilterBessel]("bessel")
    filter13 = initImageFNoRadius[ImageFilterMitchell]("mitchell")
    filter14 = initImageF[ImageFilterSinc]("sinc")
    filter15 = initImageF[ImageFilterLanczos]("lanczos")
    filter16 = initImageF[ImageFilterBlackman]("blackman")
    filters: array[16, ptr FilterBase]

  filters[0] = filter1.addr
  filters[1] = filter2.addr
  filters[2] = filter3.addr
  filters[3] = filter4.addr
  filters[4] = filter5.addr
  filters[5] = filter6.addr
  filters[6] = filter7.addr
  filters[7] = filter8.addr
  filters[8] = filter9.addr
  filters[9] = filter10.addr
  filters[10] = filter11.addr
  filters[11] = filter12.addr
  filters[12] = filter13.addr
  filters[13] = filter14.addr
  filters[14] = filter15.addr
  filters[15] = filter16.addr

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
    setBackground()
    filter[].radius(mRadius)
    var
      radius = filter[].radius()
      n = int(radius * 256 * 2)
      dy = y_end - ys
      xs = (x_end + x_start)/2.0 - (radius * (x_end - x_start) / 16.0)
      dx = (x_end - x_start) * radius / 8.0

    path.removeAll()
    path.moveTo(xs+0.5, ys + dy * filter[].calcWeight(-radius))
    for j in 1.. <n:
      path.lineTo(xs + dx * j.float64 / n.float64 + 0.5, ys + dy * filter[].calcWeight(j.float64 / 256.0 - radius))

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
          sum += filter[].calcWeight(xf)

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
    saveBMP24("image_filter_graph_$1_$2.bmp" % [$i, filter[].name], buffer, frameWidth, frameHeight)
    inc i

onDraw()