import agg_basics, agg_vcgen_dash, agg_conv_adaptor_vcgen

type
  ConvDash*[VertexSource, Markers] = object of ConvAdaptorVcgen[VertexSource, VcgenDash, Markers]
  base[VS,M] = ConvAdaptorVcgen[VS, VcgenDash, M]

proc initConvDash1*[VS, M](vs: var VS): ConvDash[VS, M] =
  base[VS,M](result).init(vs)

proc initConvDash*[VS](vs: var VS): auto =
  result = initconvDash1[VS, NullMarkers](vs)

proc removeAllDashes*[VS, M](self: var ConvDash[VS, M]) =
  base[VS,M](self).generator().removeAllDashes() 

proc addDash*[VS, M](self: var ConvDash[VS, M], dashLen, gapLen: float64) =
  base[VS,M](self).generator().addDash(dashLen, gapLen) 

proc dashStart*[VS, M](self: var ConvDash[VS, M], ds: float64) =
  base[VS,M](self).generator().dashStart(ds) 

proc shorten*[VS, M](self: var ConvDash[VS, M], s: float64) = base[VS,M](self).generator().shorten(s)
proc shorten*[VS, M](self: ConvDash[VS, M]): float64 = base[VS,M](self).generator().shorten()