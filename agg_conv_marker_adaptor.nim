import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_vertex_sequence

export agg_vcgen_vertex_sequence
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
  
proc rewind*[V,M](self: var ConvMarkerAdaptor[V,M], pathId: int) {.inline.} = 
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(self).rewind(pathId)
  
proc vertex*[V,M](self: var ConvMarkerAdaptor[V,M], x, y: var float64): uint {.inline.} = 
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(self).vertex(x, y)
  
proc markers*[V,M](self: var ConvMarkerAdaptor[V,M]): var M =
  type base = ConvAdaptorVcgen[V, VcgenVertexSequence, M]
  base(self).markers()