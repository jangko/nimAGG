import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_stroke, agg_math_stroke

export agg_conv_adaptor_vcgen

type
  ConvStroke*[VertexSource, Markers] = object of ConvAdaptorVcgen[VertexSource, VcgenStroke, Markers]
  base[V, M] = ConvAdaptorVcgen[V, VcgenStroke, M]

proc initConvStroke*[VertexSource](vs: var VertexSource): ConvStroke[VertexSource, NullMarkers] =
  ConvAdaptorVcgen[VertexSource, VcgenStroke, NullMarkers](result).init(vs)

proc lineCap*[V,M](self: var ConvStroke[V,M], lc: LineCap) = base[V,M](self).generator().lineCap(lc)
proc lineJoin*[V,M](self: var ConvStroke[V,M], lj: LineJoin) = base[V,M](self).generator().lineJoin(lj)
proc innerJoin*[V,M](self: var ConvStroke[V,M], ij: InnerJoin) = base[V,M](self).generator().innerJoin(ij)

proc lineCap*[V,M](self: ConvStroke[V,M]): LineCap = base[V,M](self).generator().lineCap
proc lineJoin*[V,M](self: ConvStroke[V,M]): LineJoin = base[V,M](self).generator().lineJoin
proc innerJoin*[V,M](self: ConvStroke[V,M]): InnerJoin = base[V,M](self).generator().innerJoin

proc width*[V,M](self: var ConvStroke[V,M], w: float64) = base[V,M](self).generator().width(w)
proc miterLimit*[V,M](self: var ConvStroke[V,M], ml: float64) = base[V,M](self).generator().miterLimit(ml)
proc miterLimitTheta*[V,M](self: var ConvStroke[V,M], t: float64) = base[V,M](self).generator().miterLimitTheta(t)
proc innerMiterLimit*[V,M](self: var ConvStroke[V,M], ml: float64) = base[V,M](self).generator().innerMiterLimit(ml)
proc approximationCcale*[V,M](self: var ConvStroke[V,M], asc: float64) = base[V,M](self).generator().approximationScale(asc)

proc width*[V,M](self: ConvStroke[V,M]): float64 = base[V,M](self).generator().width()
proc miterLimit*[V,M](self: ConvStroke[V,M]): float64 = base[V,M](self).generator().miterLimit()
proc innerMiterLimit*[V,M](self: ConvStroke[V,M]): float64 = base[V,M](self).generator().innerMiterLimit()
proc approximationScale*[V,M](self: ConvStroke[V,M]): float64 = base[V,M](self).generator().approximationScale()

proc shorten*[V,M](self: var ConvStroke[V,M], s: float64) = base[V,M](self).shorten(s)
proc shorten*[V,M](self: ConvStroke[V,M]): float64 = base[V,M](self).shorten()

proc rewind*[V,M](self: var ConvStroke[V,M], pathId: int) = base[V,M](self).rewind(pathId)
proc vertex*[V,M](self: var ConvStroke[V,M], x, y: var float64): uint = base[V,M](self).vertex(x, y)