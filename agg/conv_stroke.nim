import basics, conv_adaptor_vcgen, vcgen_stroke, math_stroke

export conv_adaptor_vcgen, math_stroke

type
  ConvStroke*[VertexSource, Markers] = object of ConvAdaptorVcgen[VertexSource, VcgenStroke, Markers]

proc initConvStrokeAux*[V,M](vs: var V): ConvStroke[V,M] =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(result).init(vs)

proc initConvStroke*[V](vs: var V): auto =
  initConvStrokeAux[V,NullMarkers](vs)

proc markers*[V,M](self: var ConvStroke[V,M]): var M =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).markers()

proc lineCap*[V,M](self: var ConvStroke[V,M], lc: LineCap) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().lineCap(lc)

proc lineJoin*[V,M](self: var ConvStroke[V,M], lj: LineJoin) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().lineJoin(lj)

proc innerJoin*[V,M](self: var ConvStroke[V,M], ij: InnerJoin) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().innerJoin(ij)

proc lineCap*[V,M](self: var ConvStroke[V,M]): LineCap =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().lineCap

proc lineJoin*[V,M](self: var ConvStroke[V,M]): LineJoin =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().lineJoin

proc innerJoin*[V,M](self: var ConvStroke[V,M]): InnerJoin =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().innerJoin

proc width*[V,M](self: var ConvStroke[V,M], w: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().width(w)

proc miterLimit*[V,M](self: var ConvStroke[V,M], ml: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().miterLimit(ml)

proc miterLimitTheta*[V,M](self: var ConvStroke[V,M], t: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().miterLimitTheta(t)

proc innerMiterLimit*[V,M](self: var ConvStroke[V,M], ml: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().innerMiterLimit(ml)

proc approximationScale*[V,M](self: var ConvStroke[V,M], asc: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().approximationScale(asc)

proc width*[V,M](self: var ConvStroke[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().width()

proc miterLimit*[V,M](self: var ConvStroke[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().miterLimit()

proc innerMiterLimit*[V,M](self: var ConvStroke[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().innerMiterLimit()

proc approximationScale*[V,M](self: var ConvStroke[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().approximationScale()

proc shorten*[V,M](self: var ConvStroke[V,M], s: float64) =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().shorten(s)

proc shorten*[V,M](self: ConvStroke[V,M]): float64 =
  type base = ConvAdaptorVcgen[V, VcgenStroke, M]
  base(self).generator().shorten()
