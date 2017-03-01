import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_vertex_sequence

type
  ConvShortenPath*[VS] = object of ConvAdaptorVcgen[VS, VcgenVertexSequence, NullMarkers]
  base[V] = ConvAdaptorVcgen[V, VcgenVertexSequence, NullMarkers]

proc initConvShortenPath*[VS](vs: var VS): ConvShortenPath[VS] =
  base[VS](result)(vs)

proc shorten*[VS](self: var ConvShortenPath[VS], s: float64) =
  base[VS](self).generator().shorten(s)

proc shorten*[VS](self: var ConvShortenPath[VS]): float64 =
  base[VS](self)generator().shorten()

proc rewind*[VS](self: var ConvShortenPath[VS], pathId: int) =
  base[VS](self).rewind(pathId)

proc vertex*[VS](self: var ConvShortenPath[VS], x, y: var float64): uint =
  base[VS](self).vertex(x, y)