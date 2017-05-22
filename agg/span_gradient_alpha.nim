import basics, span_gradient

type
  SpanGradientAlpha*[Interpolator, GradientF, AlphaF] = object
    mInterpolator: ptr Interpolator
    mGradientF: ptr GradientF
    mAlphaF: ptr AlphaF
    mD1, mD2: int

template getDownscaleShift*[I,G,A](x: typedesc[SpanGradientAlpha[I,G,A]]): int =
  getSubPixelShift(I.type) - gradientSubpixelShift

proc initSpanGradientAlpha*[I,G,A](): SpanGradientAlpha[I,G,A] =
  discard

proc initSpanGradientAlpha*[I,G,A](inter: var I,
  gradientF: var G, alphaF: var A, d1, d2: float64): SpanGradientAlpha[I,G,A] =
  result.mInterpolator = inter.addr
  result.mGradientF = gradientF.addr
  result.mAlphaF = alphaF.addr
  result.mD1 = iround(d1 * gradientSubpixelScale)
  result.mD2 = iround(d2 * gradientSubpixelScale)

proc interpolator*[I,G,A](self: SpanGradientAlpha[I,G,A]): var I = self.mInterpolator[]
proc gradientFunction*[I,G,A](self: SpanGradientAlpha[I,G,A]): var G = self.mGradientF[]
proc alphaFunction*[I,G,A](self: SpanGradientAlpha[I,G,A]): var A = self.mAlphaF[]

proc d1*[I,G,A](self: SpanGradientAlpha[I,G,A]): float64 = float64(self.mD1) / gradientSubpixelScale
proc d2*[I,G,A](self: SpanGradientAlpha[I,G,A]): float64 = float64(self.mD2) / gradientSubpixelScale

proc interpolator*[I,G,A](self: var SpanGradientAlpha[I,G,A], i: var I) = self.mInterpolator = i.addr
proc gradientFunction*[I,G,A](self: var SpanGradientAlpha[I,G,A], gf: var G) = self.mGradientF = gf.addr
proc alphaFunction*[I,G,A](self: var SpanGradientAlpha[I,G,A], af: var A) = self.mAlphaF = af.addr
proc d1*[I,G,A](self: var SpanGradientAlpha[I,G,A], v: float64) =
  self.mD1 = iround(v * gradientSubpixelScale)

proc d2*[I,G,A](self: var SpanGradientAlpha[I,G,A], v: float64) =
  self.mD2 = iround(v * gradientSubpixelScale)

proc prepare*[I,G,A](self: SpanGradientAlpha[I,G,A]) = discard

proc generate*[I,G,A, ColorT](self: var SpanGradientAlpha[I,G,A], span: ptr ColorT, x, y, len: int) =
  var
    len = len
    dd = self.mD2 - self.mD1
    x = x
    y = y
    span = span

  const downScaleShift = getDownscaleShift(SpanGradientAlpha[I,G,A])

  if dd < 1: dd = 1
  self.mInterpolator[].begin(x.float64+0.5, y.float64+0.5, len)
  doWhile len != 0:
    self.mInterpolator[].coordinates(x, y)
    var d = self.mGradientF[].calculate(sar(x, downScaleShift), sar(y, downScaleShift), self.mD2)
    d = ((d - self.mD1) * self.mAlphaF[].len) div dd
    if d < 0: d = 0
    if d >= self.mAlphaF[].len: d = self.mAlphaF[].len - 1
    span.a = self.mAlphaF[][d]
    inc span
    inc self.mInterpolator[]
    dec len

type
  GradientAlphaX*[ColorT] = object
  GradientAlphaXU8* = object
  GradientAlphaOneMunusXU8* = object

proc `[]`*[A,ColorT](z: typedesc[GradientAlphaX[ColorT]], x: A): A = x
proc `[]`*[A](z: typedesc[GradientAlphaXU8], x: A): A = x
proc `[]`*[A](z: typedesc[GradientAlphaOneMunusXU8], x: A): A = 255-x
