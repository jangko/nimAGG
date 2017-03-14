import agg_basics

type
  SpanInterpolatorAdaptor*[Interpolator, Distortion] = object of Interpolator
    mDistortion: ptr Distortion
    
template getSubPixelShift*[I,D](x: typedesc[SpanInterpolatorAdaptor[I,D]]): int = 
  mixin getSubPixelShift
  getSubPixelShift(I.type)
  
template getSubPixelScale*[I,D](x: typedesc[SpanInterpolatorAdaptor[I,D]]): int = 
  mixin getSubPixelScale
  getSubPixelScale(I.type)
  
proc initSpanInterpolatorAdaptorAux*[I,D](): SpanInterpolatorAdaptor[I,D] =
  discard

proc initSpanInterpolatorAdaptorAux*[I,D,TransType](trans: var TransType,
  dist: var D): SpanInterpolatorAdaptor[I,D] =
  mixin init
  I(result).init(trans)
  result.mDistortion = dist.addr

proc initSpanInterpolatorAdaptorAux*[I,D,TransType](trans: var TransType,
  dist: var D, x, y: float64, len: int): SpanInterpolatorAdaptor[I,D] =
  mixin init
  I(result).init(trans, x, y, len)
  result.mDistortion = dist.addr

template initSpanInterpolatorAdaptor*[I](trans, dist: untyped): untyped =
  initSpanInterpolatorAdaptorAux[I, dist.type, trans.type](trans, dist)

template initSpanInterpolatorAdaptor*[I](trans, dist: typed, x, y :float64, len: int): untyped =
  initSpanInterpolatorAdaptorAux[I, dist.type, trans.type](trans, dist, x, y, len)

proc distortion*[I,D](self: SpanInterpolatorAdaptor[I,D]): var D =
  result = self.mDistortion[]

proc distortion*[I,D](self: var SpanInterpolatorAdaptor[I,D], dist: var D) =
  self.mDistortion = dist.addr

proc coordinates*[I,D](self: var SpanInterpolatorAdaptor[I,D], x, y: var int) =
  mixin coordinates
  I(self).coordinates(x, y)
  self.mDistortion[].calculate(x, y)

proc begin*[I,D](self: var SpanInterpolatorAdaptor[I,D], x, y: float64, len: int) {.inline.} =
  mixin begin
  I(self).begin(x, y, len)

proc inc*[I,D](self: var SpanInterpolatorAdaptor[I,D]) {.inline.} =
  mixin inc
  I(self).inc()
  
proc transformer*[I,D](self: SpanInterpolatorAdaptor[I,D]): auto = 
  mixin transformer
  I(self).transformer()
  
proc transformer*[I,D,T](self: var SpanInterpolatorAdaptor[I,D], trans: var T) =
  mixin transformer
  I(self).transformer(trans)
  