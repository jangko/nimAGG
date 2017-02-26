import agg_basics, agg_vcgen_bspline, agg_conv_adaptor_vcgen

export agg_vcgen_bspline

type
  ConvBspline*[VertexSource] = object of ConvAdaptorVcgen[VertexSource, VcgenBspline, NullMarkers]
  base[V] = ConvAdaptorVcgen[V, VcgenBspline, NullMarkers]

proc initConvBspline*[VS](vs: var VS): ConvBspline[VS] =
  base[VS](result).init(vs)

proc interpolationStep*[VS](self: var ConvBspline[VS], v: float64) = base[VS](self).generator().interpolationStep(v)
proc interpolationStep*[VS](self: ConvBspline[VS]): float64 = base[VS](self)generator().interpolationStep()

proc rewind*[VS](self: var ConvBspline[VS], pathId: int) {.inline.} = base[VS](self).rewind(pathId)
proc vertex*[VS](self: var ConvBspline[VS], x, y: var float64): uint {.inline.} = base[VS](self).vertex(x, y)