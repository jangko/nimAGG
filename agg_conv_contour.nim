import agg_basics, agg_vcgen_contour, agg_conv_adaptor_vcgen, agg_math_stroke

type
  ConvContour*[VertexSource] = object of ConvAdaptorVcgen[VertexSource, VcgenContour, NullMarkers]
  base[VS] = ConvAdaptorVcgen[VS, VcgenContour, NullMarkers]

proc initConvContour*[VS](vs: var VS): ConvContour[VS] =
  base[VS](result).init(vs)

proc lineJoin*[VS](self: var ConvContour[VS], lj: LineJoin) = base[VS](self).generator().lineJoin(lj)
proc innerJoin*[VS](self: var ConvContour[VS], ij: InnerJoin) = base[VS](self).generator().innerJoin(ij)
proc width*[VS](self: var ConvContour[VS], w: float64) = base[VS](self).generator().width(w)
proc miterLimit*[VS](self: var ConvContour[VS], ml: float64) = base[VS](self).generator().miterLimit(ml)
proc miterLimitTheta*[VS](self: var ConvContour[VS], t: float64) = base[VS](self).generator().miterLimitTheta(t)
proc innerMiterLimit*[VS](self: var ConvContour[VS], ml: float64) = base[VS](self).generator().innerMiterLimit(ml)
proc approximationScale*[VS](self: var ConvContour[VS], cas: float64) = base[VS](self).generator().approximationScale(cas)
proc autoDetectOrientation*[VS](self: var ConvContour[VS], v: bool) = base[VS](self).generator().autoDetectOrientation(v)

proc lineJoin*[VS](self: ConvContour[VS]): LineJoin = base[VS](self).generator().lineJoin()
proc innerJoin*[VS](self: ConvContour[VS]): InnerJoin = base[VS](self).generator().innerJoin()
proc width*[VS](self: ConvContour[VS]): float64 = base[VS](self).generator().width()
proc miterLimit*[VS](self: ConvContour[VS]): float64 = base[VS](self).generator().miterLimit()
proc innerMiterLimit*[VS](self: ConvContour[VS]): float64 = base[VS](self).generator().innerMiterLimit()
proc approximationScale*[VS](self: ConvContour[VS]): float64 = base[VS](self).generator().approximationScale()
proc autoDetectOrientation*[VS](self: ConvContour[VS]): bool = base[VS](self).generator().autoDetectOrientation()