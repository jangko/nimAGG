import agg_basics, agg_vcgen_smooth_poly1, agg_conv_adaptor_vcgen, agg_conv_curve

type
  ConvSmoothPoly1*[VertexSource] = object of ConvAdaptorVcgen[VertexSource, VcgenSmoothPoly1, NullMarkers]
  base[VS] = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]

proc initConvSmoothPoly1*[VS](vs: var VS): ConvSmoothPoly1[VS] =
  base[VS](result).init(vs)
    
proc smoothValue*[VS](self: var ConvSmoothPoly1[VS], v: float64) = base[VS](self).generator().smoothValue(v)
proc smoothValue*[VS](self: ConvSmoothPoly1[VS]): float64 = base[VS](self).generator().smoothValue()

#type
#  ConvSmoothPoly1Curve*[VertexSource] = object of ConvCurve[ConvSmoothPoly1[VertexSource]]
#    mSmooth: ConvSmoothPoly1[VertexSource]
#
#proc initConvSmoothPoly1Curve*[VS](vs: var VS): ConvSmoothPoly1Curve[VS] =
#  ConvCurve[ConvSmoothPoly1[VS]](result).init(result.mSmooth)
#  self.mSmooth = initConvSmoothPoly1(vs)
#
#proc smoothValue*(self: var ConvSmoothPoly1Curve[VS], v: float64) = self.mSmooth.generator().smoothValue(v)
#proc smoothValue*(self: ConvSmoothPoly1Curve[VS]): float64 = self.mSmooth.generator().smoothValue()
