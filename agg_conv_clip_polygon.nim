import agg_basics, agg_conv_adaptor_vpgen, agg_vpgen_clip_polygon

type
  ConvClipPolygon*[VertexSource] = object of ConvAdaptorVpgen[VertexSource, VpgenClipPolygon]
  base[VS] = ConvAdaptorVpgen[VS, VpgenClipPolygon]

proc initConvClipPolygon*[VS](vs: var VS): ConvClipPolygon[VS] =
  base[VS](result).init(vs)

proc clipBox*[VS](self: var ConvClipPolygon[VS], x1, y1, x2, y2: float64) =
  base[VS](self).vpgen().clipBox(x1, y1, x2, y2)

proc x1*[VS](self: ConvClipPolygon[VS]): float64 = base[VS](self).vpgen().x1()
proc y1*[VS](self: ConvClipPolygon[VS]): float64 = base[VS](self).vpgen().y1()
proc x2*[VS](self: ConvClipPolygon[VS]): float64 = base[VS](self).vpgen().x2()
proc y2*[VS](self: ConvClipPolygon[VS]): float64 = base[VS](self).vpgen().y2()

proc rewind*[VS](self: var ConvClipPolygon[VS], pathId: int) {.inline.} = 
  base[V,M](self).rewind(pathId)
  
proc vertex*[VS](self: var ConvClipPolygon[VS], x, y: var float64): uint {.inline.} = 
  base[V,M](self).vertex(x, y)