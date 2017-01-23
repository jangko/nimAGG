import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_vertex_sequence

type
  ConvMarkerAdaptor*[VertexSource, Markers] = object of ConvAdaptorVcgen[VertexSource, VcgenVertexSequence, NullMarkers]
  base[V,M] = ConvAdaptorVcgen[V, VcgenVertexSequence, M]

proc initConvMarkerAdaptor*[V, M](vs: var V): ConvMarkerAdaptor[V, M] =
  base[V,M](result).init(vs)
   
proc shorten*[V, M](self: var ConvMarkerAdaptor[V, M], s: float64) = base[V,M](self).generator().shorten(s)
proc shorten*[V, M](self: ConvMarkerAdaptor[V, M]): float64 = base[V,M](self).generator().shorten()
