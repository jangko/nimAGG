import basics, conv_adaptor_vpgen, vpgen_clip_polyline

export conv_adaptor_vpgen, vpgen_clip_polyline
type
  ConvClipPolyline*[VertexSource] = object of ConvAdaptorVpgen[VertexSource, VpgenClipPolyline]

proc initConvClipPolyline*[VS](vs: var VS): ConvClipPolyline[VS] {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(result).init(vs)

proc clipBox*[VS](self: var ConvClipPolyline[VS], x1, y1, x2, y2: float64) {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(self).vpgen().clipBox(x1, y1, x2, y2)

proc x1*[VS](self: ConvClipPolyline[VS]): float64 {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(self).vpgen().x1()

proc y1*[VS](self: ConvClipPolyline[VS]): float64 {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(self).vpgen().y1()

proc x2*[VS](self: ConvClipPolyline[VS]): float64 {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(self).vpgen().x2()

proc y2*[VS](self: ConvClipPolyline[VS]): float64 {.inline.} =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolyline]
  base(self).vpgen().y2()
