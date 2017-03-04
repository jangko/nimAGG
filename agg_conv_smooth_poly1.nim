import agg_basics, agg_vcgen_smooth_poly1, agg_conv_adaptor_vcgen
import agg_conv_curve, agg_curves

export agg_vcgen_smooth_poly1

type
  ConvSmoothPoly1*[VertexSource] = object of ConvAdaptorVcgen[VertexSource, VcgenSmoothPoly1, NullMarkers]

proc initConvSmoothPoly1*[VS](vs: var VS): ConvSmoothPoly1[VS] =
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(result).init(vs)

proc smoothValue*[VS](self: var ConvSmoothPoly1[VS], v: float64) = 
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(self).generator().smoothValue(v)
  
proc smoothValue*[VS](self: ConvSmoothPoly1[VS]): float64 = 
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(self).generator().smoothValue()

proc generator*[VS](self: var ConvSmoothPoly1[VS]): var VcgenSmoothPoly1 =
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(self).generator()
  
proc rewind*[VS](self: var ConvSmoothPoly1[VS], pathId: int) {.inline.} = 
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(self).rewind(pathId)
  
proc vertex*[VS](self: var ConvSmoothPoly1[VS], x, y: var float64): uint {.inline.} = 
  type base = ConvAdaptorVcgen[VS, VcgenSmoothPoly1, NullMarkers]
  base(self).vertex(x, y)

type
  ConvSmoothPoly1Curve*[VS] = object of ConvCurve1[ConvSmoothPoly1[VS], Curve3, Curve4]
    mSmooth: ConvSmoothPoly1[VS]

proc initConvSmoothPoly1Curve*[VS](vs: var VS): ConvSmoothPoly1Curve[VS] =
  type 
    vsa  = ConvSmoothPoly1[VS]
    base = ConvCurve1[vsa, Curve3, Curve4]
  base(result).init(result.mSmooth)
  result.mSmooth = initConvSmoothPoly1(vs)

proc smoothValue*[VS](self: var ConvSmoothPoly1Curve[VS], v: float64) = 
  self.mSmooth.generator().smoothValue(v)
  
proc smoothValue*[VS](self: ConvSmoothPoly1Curve[VS]): float64 = 
  self.mSmooth.generator().smoothValue()
  
proc approximationScale*[VS](self: var ConvSmoothPoly1Curve[VS], s: float64) =
  type 
    vsa  = ConvSmoothPoly1[VS]
    base = ConvCurve1[vsa, Curve3, Curve4]
  base(self).approximationScale(s)
  
proc approximationScale*[VS](self: ConvSmoothPoly1Curve[VS]): float64 =
  type 
    vsa  = ConvSmoothPoly1[VS]
    base = ConvCurve1[vsa, Curve3, Curve4]
  base(self).approximationScale()

proc rewind*[VS](self: var ConvSmoothPoly1Curve[VS], pathId: int) {.inline.} = 
  type 
    vsa  = ConvSmoothPoly1[VS]
    base = ConvCurve1[vsa, Curve3, Curve4]
  base(self).rewind(pathId)
  
proc vertex*[VS](self: var ConvSmoothPoly1Curve[VS], x, y: var float64): uint {.inline.} = 
  type 
    vsa  = ConvSmoothPoly1[VS]
    base = ConvCurve1[vsa, Curve3, Curve4]
  base(self).vertex(x, y)
