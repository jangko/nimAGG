import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_vertex_sequence

export agg_conv_adaptor_vcgen, agg_vcgen_vertex_sequence

type
  ConvShortenPath*[VS] = object of ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  
proc initConvShortenPath*[VS](vs: var VS): ConvShortenPath[VS] =
  type base = ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  base(result).init(vs)

proc shorten*[VS](self: var ConvShortenPath[VS], s: float64) =
  type base = ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  base(self).generator().shorten(s)

proc shorten*[VS](self: var ConvShortenPath[VS]): float64 =
  type base = ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  base(self)generator().shorten()

proc rewind*[VS](self: var ConvShortenPath[VS], pathId: int) =
  type base = ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  mixin rewind
  base(self).rewind(pathId)

proc vertex*[VS](self: var ConvShortenPath[VS], x, y: var float64): uint =
  type base = ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  mixin vertex
  base(self).vertex(x, y)