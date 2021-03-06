import basics, image_filters, span_interpolator_linear

type
  SpanImageFilter*[Source, Interpolator] = object of RootObj
    mSrc: ptr Source
    mInterpolator: ptr Interpolator
    mFilter: ptr ImageFilterLut
    mDxDbl, mDyDbl: float64
    mDxInt, mDyInt: int

proc init*[S, I](self: var SpanImageFilter[S, I], src: var S, interp: var I, filter: var ImageFilterLut) =
  self.mSrc = src.addr
  self.mInterpolator = interp.addr
  self.mFilter = filter.addr
  self.mDxDbl = 0.5
  self.mDyDbl = 0.5
  self.mDxInt = imageSubpixelScale div 2
  self.mDyInt = imageSubpixelScale div 2

proc init*[S, I](self: var SpanImageFilter[S, I], src: var S, interp: var I) =
  self.mSrc = src.addr
  self.mInterpolator = interp.addr
  self.mFilter = nil
  self.mDxDbl = 0.5
  self.mDyDbl = 0.5
  self.mDxInt = imageSubpixelScale div 2
  self.mDyInt = imageSubpixelScale div 2

proc attach*[S, I](self: var SpanImageFilter[S, I], v: var S) =
  self.mSrc = v.addr

proc source*[S, I](self: SpanImageFilter[S, I]): var S = self.mSrc[]
proc filter*[S, I](self: SpanImageFilter[S, I]): var ImageFilterLut = self.mFilter[]
proc interpolator*[S, I](self: SpanImageFilter[S, I]): var I = self.mInterpolator[]

proc filterDxInt*[S, I](self: SpanImageFilter[S, I]): int = self.mDxInt
proc filterDyInt*[S, I](self: SpanImageFilter[S, I]): int = self.mDyInt
proc filterDxDbl*[S, I](self: SpanImageFilter[S, I]): float64 = self.mDxDbl
proc filterDyDbl*[S, I](self: SpanImageFilter[S, I]): float64 = self.mDyDbl

proc interpolator*[S, I](self: var SpanImageFilter[S, I], v: var I) = self.mInterpolator = v.addr
proc filter*[S, I](self: var SpanImageFilter[S, I], v: var ImageFilterLut) = self.mFilter = v.addr
proc filterOffset*[S, I](self: var SpanImageFilter[S, I], dx, dy: float64) =
  self.mDxDbl = dx
  self.mDyDbl = dy
  self.mDxInt = iround(dx * imageSubpixelScale)
  self.mDyInt = iround(dy * imageSubpixelScale)

proc filterOffset*[S, I](self: var SpanImageFilter[S, I], d: float64) =
  self.filterOffset(d, d)

proc prepare*[S, I](self: SpanImageFilter[S, I]) = discard


type
  SpanImageResampleAffine*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]
    mRx*, mRy*, mRxInv*, mRyInv*: int
    mScaleLimit, mBlurX, mBlurY: float64

proc init*[S,I](self: var SpanImageResampleAffine[S,I]) =
  self.mScaleLimit = 200.0
  self.mBlurX = 1.0
  self.mBlurY = 1.0

proc init*[S,I](self: var SpanImageResampleAffine[S,I], src: var S,
  inter: var I, filter: var ImageFilterLut) =
  type
    base = SpanImageFilter[S, I]

  base(self).init(src, inter, filter)
  self.mScaleLimit = 200.0
  self.mBlurX = 1.0
  self.mBlurY = 1.0

proc initSpanImageResampleAffine*[S,I](): SpanImageResampleAffine[S,I] =
  result.init()

proc initSpanImageResampleAffine*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageResampleAffine[S,I] =
  result.init(src, inter, filter)

proc scaleLimit*[S,I](self: SpanImageResampleAffine[S,I]): int = uround(self.mScaleLimit)
proc scaleLimit*[S,I](self: var SpanImageResampleAffine[S,I], v: int) = self.mScaleLimit = v

proc blurX*[S,I](self: SpanImageResampleAffine[S,I]): float64 = self.mBlurX
proc blurY*[S,I](self: SpanImageResampleAffine[S,I]): float64 = self.mBlurY
proc blurX*[S,I](self: var SpanImageResampleAffine[S,I], v: float64) = self.mBlurX = v
proc blurY*[S,I](self: var SpanImageResampleAffine[S,I], v: float64) = self.mBlurY = v
proc blur*[S,I](self: var SpanImageResampleAffine[S,I], v: float64) =
  self.mBlurX = v
  self.mBlurY = v

proc prepare*[S,I](self: var SpanImageResampleAffine[S,I]) =
  type
    base = SpanImageFilter[S,I]

  var
    scaleX, scaleY: float64

  base(self).interpolator().transformer().scalingAbs(scaleX, scaleY)

  if scaleX * scaleY > self.mScaleLimit:
    scaleX = scaleX * self.mScaleLimit / (scaleX * scaleY)
    scaleY = scaleY * self.mScaleLimit / (scaleX * scaleY)

  if scaleX < 1: scaleX = 1
  if scaleY < 1: scaleY = 1

  if scaleX > self.mScaleLimit: scaleX = self.mScaleLimit
  if scaleY > self.mScaleLimit: scaleY = self.mScaleLimit

  scaleX *= self.mBlurX
  scaleY *= self.mBlurY

  if scaleX < 1: scaleX = 1
  if scaleY < 1: scaleY = 1

  self.mRx    = uround(    scaleX * float64(imageSubpixelScale))
  self.mRxInv = uround(1.0/scaleX * float64(imageSubpixelScale))

  self.mRy    = uround(    scaleY * float64(imageSubpixelScale))
  self.mRyInv = uround(1.0/scaleY * float64(imageSubpixelScale))

type
  SpanImageResample*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]
    mScaleLimit, mBlurX, mBlurY: int

proc initSpanImageResample*[S,I](): SpanImageResample[S,I] =
  result.mScaleLimit = 20
  result.mBlurX = imageSubpixelScale
  result.mBlurY = imageSubpixelScale

proc initSpanImageResample*[S,I](src: var S, inter: var I, filter: var ImageFilterLut): SpanImageResample[S,I] =
  type
    base = SpanImageFilter[S, I]

  base(result).init(src, inter, filter)
  result.mScaleLimit = 20
  result.mBlurX = imageSubpixelScale
  result.mBlurY = imageSubpixelScale

proc scaleLimit*[S,I](self: SpanImageResample[S,I]): int = self.mScaleLimit
proc scaleLimit*[S,I](self: var SpanImageResample[S,I], v: int) = self.mScaleLimit = v

proc blurX*[S,I](self: SpanImageResample[S,I]): float64 = float64(self.mBlurX) / float64(imageSubpixelScale)
proc blurY*[S,I](self: SpanImageResample[S,I]): float64 = float64(self.mBlurY) / float64(imageSubpixelScale)
proc blurX*[S,I](self: var SpanImageResample[S,I], v: float64) =
  self.mBlurX = uround(v * float64(imageSubpixelScale))
proc blurY*[S,I](self: var SpanImageResample[S,I], v: float64) =
  self.mBlurY = uround(v * float64(imageSubpixelScale))

proc blur*[S,I](self: var SpanImageResample[S,I], v: float64) =
  self.mBlurY = uround(v * float64(imageSubpixelScale))
  self.mBlurX = self.mBlurY

proc adjustScale*[S,I](self: var SpanImageResample[S,I], rx, ry: var int) =
  if rx < imageSubpixelScale: rx = imageSubpixelScale
  if ry < imageSubpixelScale: ry = imageSubpixelScale
  if rx > imageSubpixelScale * self.mScaleLimit:
    rx = imageSubpixelScale * self.mScaleLimit

  if ry > imageSubpixelScale * self.mScaleLimit:
    ry = imageSubpixelScale * self.mScaleLimit

  rx = sar((rx * self.mBlurX), imageSubpixelShift)
  ry = sar((ry * self.mBlurY), imageSubpixelShift)

  if rx < imageSubpixelScale: rx = imageSubpixelScale
  if ry < imageSubpixelScale: ry = imageSubpixelScale
