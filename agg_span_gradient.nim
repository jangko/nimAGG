import agg_basics, agg_math, math, strutils

const
  gradientSubpixelShift* = 4
  gradientSubpixelScale* = 1 shl gradientSubpixelShift
  gradientSubpixelMask*  = gradientSubpixelScale - 1

type
  SpanGradient*[Interpolator, GradientF, ColorF] = object
    mInterpolator: ptr Interpolator
    mGradientF: ptr GradientF
    mColorF: ptr ColorF
    mD1, mD2: int

template getDownscaleShift*[I,G,C](x: typedesc[SpanGradient[I,G,C]]): int = 
  mixin getSubPixelShift
  (getSubPixelShift(I.type) - gradientSubpixelShift)

proc initSpanGradient*[I,G,C](inter: var I,
  gradientF: var G, colorF: var C, d1, d2: float64): SpanGradient[I,G,C] =
  result.mInterpolator = inter.addr
  result.mGradientF = gradientF.addr
  result.mColorF = colorF.addr
  result.mD1 = iround(d1 * gradientSubpixelScale)
  result.mD2 = iround(d2 * gradientSubpixelScale)

proc interpolator*[Interpolator,G,C](self: SpanGradient[Interpolator,G,C]): var Interpolator =
  self.mInterpolator[]

proc gradientFunction*[I,GradientF,C](self: SpanGradient[I,GradientF,C]): var GradientF =
  self.mGradientF[]

proc colorFunction*[I,G,ColorF](self: SpanGradient[I,G,ColorF]): var ColorF =
  self.mColorF[]

proc d1*[I,G,C](self: SpanGradient[I,G,C]): float64 =
  float64(self.mD1) / gradientSubpixelScale

proc d2*[I,G,C](self: SpanGradient[I,G,C]): float64 =
  float64(self.mD2) / gradientSubpixelScale

proc interpolator*[Interpolator,G,C](self: var SpanGradient[Interpolator,G,C], i: var Interpolator) =
  self.mInterpolator = i.addr

proc gradientFunction*[I,GradientF,C](self: var SpanGradient[I,GradientF,C], gf: var GradientF) =
  self.mGradientF = gf.addr

proc colorFunction*[I,G,ColorF](self: var SpanGradient[I,G,ColorF], cf: var ColorF) =
  self.mColorF = cf.addr

proc d1*[I,G,C](self: var SpanGradient[I,G,C], v: float64) = self.mD1 = iround(v * gradientSubpixelScale)
proc d2*[I,G,C](self: var SpanGradient[I,G,C], v: float64) = self.mD2 = iround(v * gradientSubpixelScale)

proc prepare*[I,G,C](self: SpanGradient[I,G,C]) = discard

proc generate*[I,G,C,ColorT](self: var SpanGradient[I,G,C], span: ptr ColorT, x, y, len: int) =
  const downScaleShift = getDownscaleShift(self.type)
  var
    dd = self.mD2 - self.mD1
    x = x
    y = y
    span = span
    len = len

  if dd < 1: dd = 1
  self.mInterpolator[].begin(x.float64+0.5, y.float64+0.5, len)

  doWhile len != 0:
    self.mInterpolator[].coordinates(x, y)
    var d = self.mGradientF[].calculate(sar(x, downScaleShift), sar(y, downScaleShift), self.mD2)
    d = ((d - self.mD1) * self.mColorF[].len) div dd
    if d < 0: d = 0
    if d >= self.mColorF[].len: d = self.mColorF[].len - 1
    span[] = self.mColorF[][d]
    inc span
    inc self.mInterpolator[]
    dec len


type
  GradientLinearColor*[ColorT] = object
    mC1, mC2: ColorT
    mSize: int
    
proc initGradientLinearColor*[ColorT](): GradientLinearColor[ColorT] =
  discard

proc initGradientLinearColor*[ColorT](c1, c2: ColorT, size = 256): GradientLinearColor[ColorT] =
  result.mC1 = c1
  result.mC2 = c2
  result.mSize = size

proc len*[ColorT](self: GradientLinearColor[ColorT]): int = self.mSize

proc `[]`*[ColorT](self: var GradientLinearColor[ColorT], v: int): ColorT =
  self.mC1.gradient(self.mC2, v.float64 / float64(self.mSize - 1))

proc colors*[ColorA, ColorB](self: var GradientLinearColor[ColorA], c1, c2: ColorB, size = 256) =
  when ColorA is not ColorB:
    self.mC1 = construct(ColorA, c1)
    self.mC2 = construct(ColorA, c2)
  else:
    self.mC1 = c1
    self.mC2 = c2
  self.mSize = size

type
  GradientCircle* = object

# Actually the same as radial. Just for compatibility
proc calculate*(self: GradientCircle, x, y, d: int): int {.inline.} =
  fastSqrt(x*x + y*y)

type
  GradientRadial* = object

proc calculate*(self: GradientRadial, x, y, d: int): int {.inline.} =
  fastSqrt(x*x + y*y)

type
  GradientRadialD* = object

proc calculate*(self: GradientRadialD, x, y, d: int): int {.inline.} =
  uround(sqrt(float64(x)*float64(x) + float64(y)*float64(y)))

type
  GradientRadialFocus* = object
    mR, mFx, mFy: int
    mR2, mFx2, mFy2, mMul: float64

proc updateValues(self: var GradientRadialFocus) =
  # Calculate the invariant values. In of the focal center
  # lies exactly on the gradient circle the divisor degenerates
  # into zero. In this of we just move the focal center by
  # one subpixel unit possibly in the direction to the origin (0,0)
  # and calculate the values again.
  self.mR2  = float64(self.mR)  * float64(self.mR)
  self.mFx2 = float64(self.mFx) * float64(self.mFx)
  self.mFy2 = float64(self.mFy) * float64(self.mFy)
  var d = self.mR2 - (self.mFx2 + self.mFy2)
  if d == 0:
    if self.mFx != 0:
      if self.mFx < 0: inc self.mFx else: dec self.mFx
    if self.mFy != 0:
      if self.mFy < 0: inc self.mFy else: dec self.mFy
    self.mFx2 = float64(self.mFx) * float64(self.mFx)
    self.mFy2 = float64(self.mFy) * float64(self.mFy)
    d = self.mR2 - (self.mFx2 + self.mFy2)

  self.mMul = float64(self.mR) / d

proc initGradientRadialFocus*(): GradientRadialFocus =
  result.mR  = 100 * gradientSubpixelScale
  result.mFx = 0
  result.mFy = 0
  result.updateValues()

proc initGradientRadialFocus*(r, fx, fy: float64): GradientRadialFocus =
  result.mR  = iround(r  * gradientSubpixelScale)
  result.mFx = iround(fx * gradientSubpixelScale)
  result.mFy = iround(fy * gradientSubpixelScale)
  result.updateValues()

proc init*(self: var GradientRadialFocus, r, fx, fy: float64) =
  self.mR  = iround(r  * gradientSubpixelScale)
  self.mFx = iround(fx * gradientSubpixelScale)
  self.mFy = iround(fy * gradientSubpixelScale)
  self.updateValues()

proc radius*(self: GradientRadialFocus): float64 = float64(self.mR)  / gradientSubpixelScale
proc focusX*(self: GradientRadialFocus): float64 = float64(self.mFx) / gradientSubpixelScale
proc focusY*(self: GradientRadialFocus): float64 = float64(self.mFy) / gradientSubpixelScale

proc calculate*(self: var GradientRadialFocus, x, y, d: int): int =
  var
    fx = self.mFx.float64
    fy = self.mFy.float64
    dx = x.float64 - fx
    dy = y.float64 - fy
    d2 = dx * fy - dy * fx
    d3 = self.mR2 * (dx * dx + dy * dy) - d2 * d2
  iround((dx * fx + dy * fx + sqrt(abs(d3))) * self.mMul)

type
  GradientX* = object

proc initGradientX*(): GradientX = discard
proc calculate*(self: GradientX, x, y, d: int): int {.inline.} = x

type
  GradientY* = object

proc calculate*(self: GradientY, x, y, d: int): int {.inline.} = y

type
  GradientDiamond* = object

proc calculate*(self: GradientDiamond, x, y, d: int): int {.inline.} =
  let ax = abs(x)
  let ay = abs(y)
  result = if ax > ay: ax else: ay

type
  GradientXY* = object

proc calculate*(self: GradientXY, x, y, d: int): int {.inline.} =
  result = abs(x) * abs(y) div d

type
  GradientSqrtXY* = object

proc calculate*(self: GradientSqrtXY, x, y, d: int): int {.inline.} =
  fastSqrt(abs(x) * abs(y))

type
  GradientConic* = object

proc calculate*(self: GradientConic, x, y, d: int): int {.inline.} =
  uround(abs(arctan2(float64(y), float64(x))) * float64(d) / pi)

type
  GradientRepeatAdaptor*[GradientF] = object
    mGradient: ptr GradientF

proc initGradientRepeatAdaptor*[GradientF](gf: var GradientF): GradientRepeatAdaptor[GradientF] =
  result.mGradient = gf.addr

proc calculate*[GradientF](self: var GradientRepeatAdaptor[GradientF], x, y, d: int): int {.inline.} =
  result = self.mGradient[].calculate(x, y, d) mod d
  if result < 0: result += d

type
  GradientReflectAdaptor*[GradientF] = object
    mGradient: ptr GradientF

proc initGradientReflectAdaptor*[GradientF](gf: var GradientF): GradientReflectAdaptor[GradientF] =
  result.mGradient = gf.addr
  
template construct*[T](x: typedesc[GradientReflectAdaptor[T]], val: untyped): untyped = initGradientReflectAdaptor(val)

proc calculate*[GradientF](self: var GradientReflectAdaptor[GradientF], x, y, d: int): int {.inline.} =
  let d2 = d shl 1
  result = self.mGradient[].calculate(x, y, d) mod d2
  if result <  0: result += d2
  if result >= d: result  = d2 - result
