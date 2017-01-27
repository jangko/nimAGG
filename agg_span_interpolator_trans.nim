import agg_basics

type
  SpanInterpolatorTrans*[Transformer] = object
    mTrans: ptr Transformer
    mX, mY: float64
    mIx, mIy: int

template getSubPixelShift*[T](x: typedesc[SpanInterpolatorTrans[T]]): int = 8
template getSubPixelScale*[T](x: typedesc[SpanInterpolatorTrans[T]]): int = 1 shl getSubPixelShift(x)

proc initSpanInterpolatorTrans*[T](trans: var T): SpanInterpolatorTrans[T] =
  result.mTrans = trans.addr
  
proc initSpanInterpolatorTrans*[T](trans: var T, x, y: float64, z: uint): SpanInterpolatorTrans[T] =
  result.mTrans = trans.addr
  result.begin(x, y, 0)

proc transformer*[T](self: SpanInterpolatorTrans[T]): var T = self.mTrans[]
proc transformer*[T](self: var SpanInterpolatorTrans[T], trans: var T) = 
  self.mTrans = trans.addr

proc begin*[T](self: var SpanInterpolatorTrans[T], x, y: float64, z: uint) =
  const subPixelScale = getSubPixelScale(self.type)
  self.mX = x
  self.mY = y
  self.mTrans[].transform(x, y)
  self.mIx = iround(x * subPixelScale)
  self.mIy = iround(y * subPixelScale)

proc inc*[T](self: var SpanInterpolatorTrans[T]) =
  const subPixelScale = getSubPixelScale(self.type)
  self.mX += 1.0
  var
    x = self.mX
    y = self.mY
  self.mTrans[].transform(x, y)
  self.mIx = iround(x * subPixelScale)
  self.mIy = iround(y * subPixelScale)

proc coordinates*[T](self: SpanInterpolatorTrans[T], x, y: var int) =
  x = self.mIx
  y = self.mIy
