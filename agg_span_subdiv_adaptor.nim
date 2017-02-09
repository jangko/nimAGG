import agg_basics

type
  SpanSubdivAdaptor*[Interpolator] = object
    mSubdivShift: int
    mSubdivSize: int
    mSubdivMask: int
    mInterpolator: ptr Interpolator
    mSrcX: int
    mSrcY: float64
    mPos, mLen: int

const
  subPixelShift = 8
  subPixelScale = 1 shl subPixelShift

proc begin*[I](self: var SpanSubdivAdaptor[I], x, y: float64, len: int)

proc initSpanSubdivAdaptor*[I](): SpanSubdivAdaptor[I] =
  result.mSubdivShift = 4
  result.mSubdivSize  = 1 shl result.mSubdivShift
  result.mSubdivMask  = result.mSubdivSize - 1

proc initSpanSubdivAdaptor*[I](inter: var I, subDivShift = 4): SpanSubdivAdaptor[I] =
  result.mSubdivShift  = subDivShift
  result.mSubdivSize   = 1 shl result.mSubdivShift
  result.mSubdivMask   = result.mSubdivSize - 1
  result.mInterpolator = inter.addr

proc initSpanSubdivAdaptor*[I](inter: var I, x, y: float64, len: int, subDivShift = 4): SpanSubdivAdaptor[I] =
  result.mSubdivShift  = subDivShift
  result.mSubdivSize   = 1 shl result.mSubdivShift
  result.mSubdivMask   = result.mSubdivSize - 1
  result.mInterpolator = inter.addr
  result.begin(x, y, len)

proc interpolator*[I](self: var SpanSubdivAdaptor[I]): var I = self.mInterpolator[]
proc interpolator*[I](self: var SpanSubdivAdaptor[I], intr: var I) = self.mInterpolator = intr.addr

proc transformer*[I](self: var SpanSubdivAdaptor[I]): auto =
  result = self.mInterpolator[].transformer()

proc transformer*[I,T](self: var SpanSubdivAdaptor[I], trans: var T) =
  self.mInterpolator[].transformer(trans)

proc subDivShift*[I](self: var SpanSubdivAdaptor[I]): float64 = self.mSubdivShift
proc subDivShift*[I](self: var SpanSubdivAdaptor[I], shift: int) =
  self.mSubdivShift = shift
  self.mSubdivSize  = 1 shl self.mSubdivShift
  self.mSubdivMask  = self.mSubdivSize - 1

proc begin[I](self: var SpanSubdivAdaptor[I], x, y: float64, len: int) =
  self.mPos  = 1
  self.mSrcX = iround(x * subPixelScale) + subPixelScale
  self.mSrcY = y
  self.mLen  = len
  if len > self.mSubdivSize: len = self.mSubdivSize
  self.mInterpolator[].begin(x, y, len)

proc inc*[I](self: var SpanSubdivAdaptor[I]) =
  inc self.mInterpolator[]
  if self.mPos >= self.mSubdivSize:
    var len = self.mLen
    if len > self.mSubdivSize: len = self.mSubdivSize
    self.mInterpolator[].resynchronize(float64(self.mSrcX) / float64(subPixelScale) + len,
                                    self.mSrcY,
                                    len)
    self.mPos = 0

  self.mSrcX += subPixelScale
  inc self.mPos
  dec self.mLen

proc coordinates*[I](self: var SpanSubdivAdaptor[I], x, y: var int) =
  self.mInterpolator[].coordinates(x, y)

proc localScale*[I](self: var SpanSubdivAdaptor[I], x, y: var int) =
  self.mInterpolator[].localScale(x, y)
