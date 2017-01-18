import agg_basics, agg_vcgen_bspline, agg_conv_adaptor_vcgen

type
  ConvBspline*[VertexSource] = object of ConvAdaptorVcgen[VertexSource, VcgenBspline, NullMarkers]
  base[V] = ConvAdaptorVcgen[V, VcgenBspline, NullMarkers]

proc initConvBspline*[VS](vs: var VS): ConvBspline[VS] =
  base[VS](result)(vs)

proc interpolationStep*[VS](self: var ConvBspline[VS], v: float64) = base[VS](self).generator().interpolationStep(v)
proc interpolationStep*[VS](self: ConvBspline[VS]): float64 = base[VS](self)generator().interpolationStep()
