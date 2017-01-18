import agg_basics, agg_conv_adaptor_vpgen, agg_vpgen_segmentator

type
  ConvSegmentator*[VertexSource] = object of ConvAdaptorVpgen[VertexSource, VpgenSegmentator]
  base[V] = ConvAdaptorVpgen[V, VpgenSegmentator]

proc initConvSegmentator*[V](vs: var V): ConvSegmentator[V] =
  base[V](result).init(vs)

proc approximationScale*[V](self: var ConvSegmentator[V], s: float64) =
  base[V](self).vpgen().approximationScale(s)

proc approximationScale*[V](self: ConvSegmentator[V]): float64 =
  base[V](self).vpgen().approximationScale()
