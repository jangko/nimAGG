import agg_basics, agg_conv_adaptor_vpgen, agg_vpgen_segmentator

export agg_conv_adaptor_vpgen

type
  ConvSegmentator*[VertexSource] = object of ConvAdaptorVpgen[VertexSource, VpgenSegmentator]
  base[V] = ConvAdaptorVpgen[V, VpgenSegmentator]

proc initConvSegmentator*[V](vs: var V): ConvSegmentator[V] =
  base[V](result).init(vs)

proc approximationScale*[V](self: var ConvSegmentator[V], s: float64) =
  base[V](self).vpgen().approximationScale(s)

proc approximationScale*[V](self: ConvSegmentator[V]): float64 =
  base[V](self).vpgen().approximationScale()
  
proc rewind*[V](self: var ConvSegmentator[V], pathId: int) {.inline.} =
  base[V](self).rewind(pathId)
  
proc vertex*[V](self: var ConvSegmentator[V], x, y: var float64): uint  {.inline.} =
  base[V](self).vertex(x, y)