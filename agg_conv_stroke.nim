import agg_basics, agg_conv_adaptor_vcgen, agg_vcgen_stroke, agg_math_stroke

type
  ConvStroke*[VertexSource, Markers] = object
    base: ConvAdaptorVcgen[VertexSource, VcgenStroke, Markers]
  
proc initConvStroke*[VertexSource](vs: VertexSource): ConvStroke[VertexSource, NullMarkers] =
  result.base = newConvAdaptorVcgen[VertexSource, VcgenStroke, NullMarkers](vs)

proc lineCap*[V,M](self: ConvStroke[V,M], lc: LineCap) = self.base.generator().lineCap(lc)
proc lineJoin*[V,M](self: ConvStroke[V,M], lj: LineJoin) = self.base.generator().lineJoin(lj)
proc innerJoin*[V,M](self: ConvStroke[V,M], ij: InnerJoin) = self.base.generator().innerJoin(ij)

proc lineCap*[V,M](self: ConvStroke[V,M]): LineCap = self.base.generator().lineCap
proc lineJoin*[V,M](self: ConvStroke[V,M]): LineJoin = self.base.generator().lineJoin
proc innerJoin*[V,M](self: ConvStroke[V,M]): InnerJoin = self.base.generator().innerJoin

proc width*[V,M](self: ConvStroke[V,M], w: float64) = self.base.generator().width(w)
proc miterLimit*[V,M](self: ConvStroke[V,M], ml: float64) = self.base.generator().miterLimit(ml)
proc miterLimitTheta*[V,M](self: ConvStroke[V,M], t: float64) = self.base.generator().miterLimitTheta(t)
proc innerMiterLimit*[V,M](self: ConvStroke[V,M], ml: float64) = self.base.generator().innerMiterLimit(ml)
proc approximationCcale*[V,M](self: ConvStroke[V,M], asc: float64) = self.base.generator().approximationScale(asc)

proc width*[V,M](self: ConvStroke[V,M]): float64 = self.base.generator().width()
proc miterLimit*[V,M](self: ConvStroke[V,M]): float64 = self.base.generator().miterLimit()
proc innerMiterLimit*[V,M](self: ConvStroke[V,M]): float64 = self.base.generator().innerMiterLimit()
proc approximationScale*[V,M](self: ConvStroke[V,M]): float64 = self.base.generator().approximationScale()

proc shorten*[V,M](self: ConvStroke[V,M], s: float64) = self.base.shorten(s)
proc shorten*[V,M](self: ConvStroke[V,M]): float64 = self.base.shorten()

proc rewind*[V,M](self: var ConvStroke[V,M], pathId: int)  =
  self.base.rewind(pathId)
  
proc vertex*[V,M](self: var ConvStroke[V,M], x, y: var float64): uint =
  result = self.base.vertex(x, y)