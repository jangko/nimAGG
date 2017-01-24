import agg_basics

type
  SpanInterpolatorAdaptor*[Interpolator, Distortion] = object of Interpolator
    mDistortion: ptr Distortion

proc initSpanInterpolatorAdaptor*[I,D](): SpanInterpolatorAdaptor[I,D] =
  discard

proc initSpanInterpolatorAdaptor*[I,D,TransType](trans: var TransType,
  dist: var D): SpanInterpolatorAdaptor[I,D] =
  I(result).init(trans)
  self.mDistortion = dist.addr

proc initSpanInterpolatorAdaptor*[I,D,TransType](trans: var TransType,
  dist: var D, x, y: float64, len: int): SpanInterpolatorAdaptor[I,D] =
  I(result).init(trans, x, y, len)
  self.mDistortion = dist.addr

proc distortion*[I,D](self: SpanInterpolatorAdaptor[I,D]): var D =
  result = self.mDistortion[]

proc distortion*[I,D](self: var SpanInterpolatorAdaptor[I,D], dist: var D) =
  self.mDistortion = dist.addr

proc coordinates*[I,D](self: var SpanInterpolatorAdaptor[I,D], x, y: var int) =
  I(self).coordinates(x, y)
  self.mDistortion[].calculate(x, y)
