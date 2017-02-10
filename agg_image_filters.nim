import agg_basics, math, agg_math, strutils

const
  imageFilterShift* = 14
  imageFilterScale* = 1 shl imageFilterShift
  imageFilterMask*  = imageFilterScale - 1

const
  imageSubpixelShift* = 8
  imageSubpixelScale* = 1 shl imageSubpixelShift
  imageSubpixelMask*  = imageSubpixelScale - 1

type
  ImageFilterLut* = object of RootObj
    mRadius: float64
    mDiameter: int
    mStart: int
    mWeightArray: seq[int16]

proc init(self: var ImageFilterLut) =
  self.mRadius = 0
  self.mDiameter = 0
  self.mStart = 0
  self.mWeightArray = @[]

proc radius*(self: ImageFilterLut): float64 = self.mRadius
proc diameter*(self: ImageFilterLut): int = self.mDiameter
proc start*(self: ImageFilterLut): int = self.mStart
proc weightArray*(self: var ImageFilterLut): ptr int16 = self.mWeightArray[0].addr

proc normalize(self: var ImageFilterLut) =
  var flip = 1

  for i in 0.. <imageSubpixelScale:
    while true:
      var sum = 0
      for j in 0.. <self.mDiameter:
        sum += self.mWeightArray[j * imageSubpixelScale + i]

      if sum == imageFilterScale: break

      var k = float64(imageFilterScale) / float64(sum)
      sum = 0
      for j in 0.. <self.mDiameter:
        let t = iround(self.mWeightArray[j * imageSubpixelScale + i].float64 * k)
        sum += t
        self.mWeightArray[j * imageSubpixelScale + i] = t.int16

      sum -= imageFilterScale
      var inc = if sum > 0: -1 else: 1

      var j = 0
      while j < self.mDiameter and sum != 0:
        flip = flip xor 1
        var
          idx = if flip  != 0: self.mDiameter div 2 + j div 2 else: self.mDiameter div 2 - j div 2
          v = self.mWeightArray[idx * imageSubpixelScale + i]
        if v < imageFilterScale:
          self.mWeightArray[idx * imageSubpixelScale + i] += inc.int16
          sum += inc
        inc j

  var pivot = self.mDiameter shl (imageSubpixelShift - 1)
  for i in 0.. <pivot:
    self.mWeightArray[pivot + i] = self.mWeightArray[pivot - i]

  var stop = (self.diameter() shl imageSubpixelShift) - 1
  self.mWeightArray[0] = self.mWeightArray[stop]

proc reallocLut(self: var ImageFilterLut, radius: float64) =
  self.mRadius = radius
  self.mDiameter = ceil(radius).int * 2
  self.mStart = -int(self.mDiameter / 2 - 1)
  let size = self.mDiameter shl imageSubpixelShift
  if size > self.mWeightArray.len:
    self.mWeightArray.setLen(size)

proc calculate*[FilterF](self: var ImageFilterLut, filter: var FilterF, normalization = true) =
  mixin radius
  var r = filter.radius()
  self.reallocLut(r)

  let pivot = self.diameter() shl (imageSubpixelShift - 1)
  for i in 0.. <pivot:
    let x = float64(i) / float64(imageSubpixelScale)
    let y = filter.calcWeight(x)
    let z = iround(y * imageFilterScale).int16
    self.mWeightArray[pivot + i] = z
    self.mWeightArray[pivot - i] = z

  let stop = (self.diameter() shl imageSubpixelShift) - 1
  self.mWeightArray[0] = self.mWeightArray[stop]
  if normalization:
    self.normalize()

proc initImageFilterLut*[FilterF](filter: var FilterF, normalization = true): ImageFilterLut =
  result.init()
  result.calculate(filter, normalization)

type
  ImageFilter*[FilterF] = object of ImageFilterLut
    mFilterF: FilterF

proc initImageFilter*[FilterF](): ImageFilter[FilterF] =
  ImageFilterLut(result).init()
  result.mFilterF.calculate()

type
  ImageFilterBilinear* = object

proc construct*(x: typedesc[ImageFilterBilinear]): ImageFilterBilinear =
  discard

proc radius*(self: ImageFilterBilinear): float64 = 1.0

proc calcWeight*(self: ImageFilterBilinear, x: float64): float64 =
  result = 1.0 - x

type
  ImageFilterHanning* = object

proc construct*(x: typedesc[ImageFilterHanning]): ImageFilterHanning =
  discard

proc radius*(self: ImageFilterHanning): float64 = 1.0

proc calcWeight*(self: ImageFilterHanning, x: float64): float64 =
  result = 0.5 + 0.5 * cos(pi * x)

type
  ImageFilterHamming* = object

proc construct*(x: typedesc[ImageFilterHamming]): ImageFilterHamming =
  discard

proc radius*(self: ImageFilterHamming): float64 = 1.0

proc calcWeight*(self: ImageFilterHamming, x: float64): float64 =
  result = 0.54 + 0.46 * cos(pi * x)

type
  ImageFilterHermite* = object

proc construct*(x: typedesc[ImageFilterHermite]): ImageFilterHermite =
  discard

proc radius*(self: ImageFilterHermite): float64 = 1.0

proc calcWeight*(self: ImageFilterHermite, x: float64): float64 =
  result = (2.0 * x - 3.0) * x * x + 1.0

type
  ImageFilterQuadric* = object

proc construct*(x: typedesc[ImageFilterQuadric]): ImageFilterQuadric =
  discard

proc radius*(self: ImageFilterQuadric): float64 = 1.5

proc calcWeight*(self: ImageFilterQuadric, x: float64): float64 =
  if x < 0.5: return 0.75 - x * x
  if x < 1.5:
    let t = x - 1.5
    return 0.5 * t * t
  result = 0.0

type
  ImageFilterBicubic* = object

proc construct*(x: typedesc[ImageFilterBicubic]): ImageFilterBicubic =
  discard

proc pow3(x: float64): float64 =
  result = if x <= 0.0: 0.0 else: x * x * x

proc radius*(self: ImageFilterbicubic): float64 = 2.0

proc calcWeight*(self: ImageFilterbicubic, x: float64): float64 =
  result = (1.0/6.0) *
    (pow3(x + 2) - 4 * pow3(x + 1) + 6 * pow3(x) - 4 * pow3(x - 1))

type
  ImageFilterKaiser* = object
    a, i0a, epsilon: float64

proc bessel_i0(self: ImageFilterKaiser, x: float64): float64 =
  var
    sum = 1.0
    y = x * x / 4.0
    t = y
    i = 2

  while t > self.epsilon:
    sum += t
    t *= float64(y) / (i * i).float64
    inc i

  result = sum

proc initImageFilterKaiser*(b = 6.33): ImageFilterKaiser =
  result.a = b
  result.epsilon = 1e-12
  result.i0a = 1.0 / result.bessel_i0(b)

proc construct*(x: typedesc[ImageFilterKaiser]): ImageFilterKaiser =
  initImageFilterKaiser()

proc radius*(self: ImageFilterKaiser): float64 = 1.0

proc calcWeight*(self: ImageFilterKaiser, x: float64): float64 =
  result = self.bessel_i0(self.a * sqrt(1.0 - x * x)) * self.i0a

type
  ImageFilterCatrom* = object

proc construct*(x: typedesc[ImageFilterCatrom]): ImageFilterCatrom =
  discard

proc radius*(self: ImageFilterCatrom): float64 = 2.0

proc calcWeight*(self: ImageFilterCatrom, x: float64): float64 =
  if x <  1.0: return 0.5 * (2.0 + x * x * (-5.0 + x * 3.0))
  if x <  2.0: return 0.5 * (4.0 + x * (-8.0 + x * (5.0 - x)))
  return 0.0

type
  ImageFilterMitchell* = object
    p0, p2, p3: float64
    q0, q1, q2, q3: float64

const
  onethird = 1.0 / 3.0

proc initImageFilterMitchell*(b = onethird, c = onethird): ImageFilterMitchell =
  result.p0 = (6.0 - 2.0 * b) / 6.0
  result.p2 = (-18.0 + 12.0 * b + 6.0 * c) / 6.0
  result.p3 = (12.0 - 9.0 * b - 6.0 * c) / 6.0
  result.q0 = (8.0 * b + 24.0 * c) / 6.0
  result.q1 = (-12.0 * b - 48.0 * c) / 6.0
  result.q2 = (6.0 * b + 30.0 * c) / 6.0
  result.q3 = (-b - 6.0 * c) / 6.0

proc construct*(x: typedesc[ImageFilterMitchell]): ImageFilterMitchell =
  initImageFilterMitchell()

proc radius*(self: ImageFilterMitchell): float64 =  2.0

proc calcWeight*(self: ImageFilterMitchell, x: float64): float64 =
  if x < 1.0: return self.p0 + x * x * (self.p2 + x * self.p3)
  if x < 2.0: return self.q0 + x * (self.q1 + x * (self.q2 + x * self.q3))
  result = 0.0

type
  ImageFilterSpline16* = object

proc construct*(x: typedesc[ImageFilterSpline16]): ImageFilterSpline16 =
  discard

proc radius*(self: ImageFilterSpline16): float64 = 2.0

proc calcWeight*(self: ImageFilterSpline16, x: float64): float64 =
  if x < 1.0:
    return ((x - 9.0/5.0 ) * x - 1.0/5.0 ) * x + 1.0;

  result = ((-1.0/3.0 * (x-1) + 4.0/5.0) * (x-1) - 7.0/15.0 ) * (x-1)

type
  ImageFilterSpline36* = object

proc construct*(x: typedesc[ImageFilterSpline36]): ImageFilterSpline36 =
  discard

proc radius*(self: ImageFilterSpline36): float64 = 3.0

proc calcWeight*(self: ImageFilterSpline36, x: float64): float64 =
  if x < 1.0:
    return ((13.0/11.0 * x - 453.0/209.0) * x - 3.0/209.0) * x + 1.0

  if x < 2.0:
    return ((-6.0/11.0 * (x-1) + 270.0/209.0) * (x-1) - 156.0/ 209.0) * (x-1)

  result = ((1.0/11.0 * (x-2) - 45.0/209.0) * (x-2) +  26.0/209.0) * (x-2)


type
  ImageFilterGaussian* = object

proc construct*(x: typedesc[ImageFilterGaussian]): ImageFilterGaussian =
  discard

proc radius*(self: ImageFilterGaussian): float64 = 2.0

proc calcWeight*(self: ImageFilterGaussian, x: float64): float64 =
  result = exp(-2.0 * x * x) * sqrt(2.0 / pi)

type
  ImageFilterBessel* = object

proc construct*(x: typedesc[ImageFilterBessel]): ImageFilterBessel =
  discard

proc radius*(self: ImageFilterBessel): float64 = 3.2383

proc calcWeight*(self: ImageFilterBessel, x: float64): float64 =
  result = if x == 0.0: pi / 4.0 else: besj(pi * x, 1) / (2.0 * x)

type
  ImageFilterSinc* = object
    mRadius: float64

proc initImageFilterSinc*(r: float64): ImageFilterSinc =
  result.mRadius = if r < 2.0: 2.0 else: r

proc construct*(x: typedesc[ImageFilterSinc], r: float64): ImageFilterSinc =
  initImageFilterSinc(r)

proc radius*(self: ImageFilterSinc): float64 = self.mRadius
proc calcWeight*(self: ImageFilterSinc, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  x *= pi
  result = sin(x) / x

type
  ImageFilterLanczos* = object
    mRadius: float64

proc initImageFilterLanczos*(r: float64): ImageFilterLanczos =
  result.mRadius = if r < 2.0: 2.0 else: r

proc construct*(x: typedesc[ImageFilterLanczos], r: float64): ImageFilterLanczos =
  initImageFilterLanczos(r)

proc radius*(self: ImageFilterLanczos): float64 = self.mRadius
proc calcWeight*(self: ImageFilterLanczos, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  if x > self.mRadius: return 0.0
  x *= pi
  let xr = x / self.mRadius
  result = (sin(x) / x) * (sin(xr) / xr)

type
  ImageFilterBlackman* = object
    mRadius: float64

proc initImageFilterBlackman*(r: float64): ImageFilterBlackman =
  result.mRadius = if r < 2.0: 2.0 else: r

proc construct*(x: typedesc[ImageFilterBlackman], r: float64): ImageFilterBlackman =
  initImageFilterBlackman(r)

proc radius*(self: ImageFilterBlackman): float64 = self.mRadius
proc calcWeight*(self: ImageFilterBlackman, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  if x > self.mRadius: return 0.0
  x *= pi
  let xr = x / self.mRadius
  result = (sin(x) / x) * (0.42 + 0.5*cos(xr) + 0.08*cos(2*xr))

proc ImageFiltersinc36*(): ImageFilterSinc =
  result = initImageFilterSinc(3.0)

proc ImageFiltersinc64*(): ImageFilterSinc =
  result = initImageFilterSinc(4.0)

proc ImageFiltersinc100*(): ImageFilterSinc =
  result = initImageFilterSinc(5.0)

proc ImageFiltersinc144*(): ImageFilterSinc =
  result = initImageFilterSinc(6.0)

proc ImageFiltersinc196*(): ImageFilterSinc =
  result = initImageFilterSinc(7.0)

proc ImageFiltersinc256*(): ImageFilterSinc =
  result = initImageFilterSinc(8.0)

proc ImageFilterLanczos36*(): ImageFilterLanczos =
  result = initImageFilterLanczos(3.0)

proc ImageFilterLanczos64*(): ImageFilterLanczos =
  result = initImageFilterLanczos(4.0)

proc ImageFilterLanczos100*(): ImageFilterLanczos =
  result = initImageFilterLanczos(5.0)

proc ImageFilterLanczos144*(): ImageFilterLanczos =
  result = initImageFilterLanczos(6.0)

proc ImageFilterLanczos196*(): ImageFilterLanczos =
  result = initImageFilterLanczos(7.0)

proc ImageFilterLanczos256*(): ImageFilterLanczos =
  result = initImageFilterLanczos(8.0)

proc ImageFilterBlackman36*(): ImageFilterBlackman =
  result = initImageFilterBlackman(3.0)

proc ImageFilterBlackman64*(): ImageFilterBlackman =
  result = initImageFilterBlackman(4.0)

proc ImageFilterBlackman100*(): ImageFilterBlackman =
  result = initImageFilterBlackman(5.0)

proc ImageFilterBlackman144*(): ImageFilterBlackman =
  result = initImageFilterBlackman(6.0)

proc ImageFilterBlackman196*(): ImageFilterBlackman =
  result = initImageFilterBlackman(7.0)

proc ImageFilterBlackman256*(): ImageFilterBlackman =
  result = initImageFilterBlackman(8.0)
