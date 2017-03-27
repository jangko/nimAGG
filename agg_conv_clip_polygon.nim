import agg_basics, agg_conv_adaptor_vpgen, agg_vpgen_clip_polygon

export agg_conv_adaptor_vpgen, agg_vpgen_clip_polygon
type
  ConvClipPolygon*[VertexSource] = object of ConvAdaptorVpgen[VertexSource, VpgenClipPolygon]  

proc initConvClipPolygon*[VS](vs: var VS): ConvClipPolygon[VS] =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base(result).init(vs)

proc clipBox*[VS](self: var ConvClipPolygon[VS], x1, y1, x2, y2: float64) =
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base(self).vpgen().clipBox(x1, y1, x2, y2)

proc x1*[VS](self: ConvClipPolygon[VS]): float64 = 
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base[VS](self).vpgen().x1()
  
proc y1*[VS](self: ConvClipPolygon[VS]): float64 = 
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base[VS](self).vpgen().y1()
  
proc x2*[VS](self: ConvClipPolygon[VS]): float64 = 
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base[VS](self).vpgen().x2()
  
proc y2*[VS](self: ConvClipPolygon[VS]): float64 = 
  type base = ConvAdaptorVpgen[VS, VpgenClipPolygon]
  base[VS](self).vpgen().y2()
