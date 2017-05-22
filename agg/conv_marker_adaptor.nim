import basics, conv_adaptor_vcgen, vcgen_vertex_sequence

export vcgen_vertex_sequence
type
  ConvMarkerAdaptor*[VertexSource, Markers] = object of ConvAdaptorVcgen[VertexSource, VcgenVertexSequence, Markers]

proc initConvMarkerAdaptorAux*[V,M](vs: var V): ConvMarkerAdaptor[V,M] =
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(result).init(vs)

proc initConvMarkerAdaptor*[V](vs: var V): auto =
  initConvMarkerAdaptorAux[V, NullMarkers](vs)

proc shorten*[V,M](self: var ConvMarkerAdaptor[V,M], s: float64) =
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(self).generator().shorten(s)

proc shorten*[V,M](self: ConvMarkerAdaptor[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(self).generator().shorten()
