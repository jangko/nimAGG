import agg_basics, math

type  
  order_rgb* {.pure.} = enum
    R=0, G=1, B=2
    
  order_bgr* {.pure.} = enum
    B=0, G=1, R=2

  order_rgba* {.pure.} = enum 
    R=0, G=1, B=2, A=3
    
  order_argb* {.pure.} = enum 
    A=0, R=1, G=2, B=3
    
  order_abgr* {.pure.} = enum 
    A=0, B=1, G=2, R=3
    
  order_bgra* {.pure.} = enum 
    B=0, G=1, R=2, A=3

  rgba* = object
    r*, g*, b*, a*: float64
    
  rgba8* = object
    r*, g*, b*, a*: uint8
  
  rgba16* = object
    r*, g*, b*, a*: uint16
    
proc initRgba*(): rgba =
  result = rgba(r:0.0, g:0.0, b:0.0, a:0.0)
  
proc initRgba*(r,g,b: float64, a=1.0'f64): rgba =
  result = rgba(r:r, g:g, b:b, a:a)
  
proc initRgba*(c: rgba, a: float64): rgba =
  result = rgba(r:c.r, g:c.g, b:c.b, a:a)

proc clear*(c: var rgba) =
  c.r = 0.0; c.g = 0.0; c.b = 0.0; c.a = 0.0
  
proc transparent*(c: var rgba): var rgba {.discardable.} =
  c.a = 0.0
  result = c
  
proc opacity*(c: var rgba, a: float64): var rgba {.discardable.} =
  if a < 0.0: c.a = 0.0
  if a > 1.0: c.a = 1.0
  result = c
  
proc opacity*(c: rgba): float64 =
  result = c.a
        
proc premultiply*(c: var rgba): var rgba {.discardable.} =
  c.r = c.r * c.a
  c.g = c.g * c.a
  c.b = c.b * c.a
  result = c
        
proc premultiply*(c: var rgba, a: float64): var rgba {.discardable.} =
  if (c.a <= 0.0) or (a <= 0.0):
    c.r = 0.0
    c.g = 0.0
    c.b = 0.0
    c.a = 0.0
    return c
  
  c.a = a / c.a
  c.r = c.r * c.a
  c.g = c.g * c.a
  c.b = c.b * c.a
  result = c
        
proc demultiply*(c: var rgba): var rgba {.discardable.} =
  if c.a == 0.0:
    c.r = 0.0
    c.g = 0.0
    c.b = 0.0
    c.a = 0.0
    return c
            
  let a = 1.0 / c.a
  c.r = c.r * a
  c.g = c.r * a
  c.b = c.r * a
  result = c
        
proc gradient*(a, c: rgba, k: float64): rgba =
  result.r = a.r + (c.r - a.r) * k
  result.g = a.g + (c.g - a.g) * k
  result.b = a.b + (c.b - a.b) * k
  result.a = a.a + (c.a - a.a) * k
        
proc rgba_no_color*(): rgba = initRgba()
        
proc rgba_from_wavelength*(wl: float64, gamma = 1.0'f64): rgba =
  var t = initRgba(0.0, 0.0, 0.0)

  if(wl >= 380.0) and (wl <= 440.0):
    t.r = -1.0 * (wl - 440.0) / (440.0 - 380.0)
    t.b = 1.0
  elif(wl >= 440.0) and (wl <= 490.0):
    t.g = (wl - 440.0) / (490.0 - 440.0)
    t.b = 1.0
  elif(wl >= 490.0) and (wl <= 510.0):
    t.g = 1.0
    t.b = -1.0 * (wl - 510.0) / (510.0 - 490.0)
  elif(wl >= 510.0) and (wl <= 580.0):
    t.r = (wl - 510.0) / (580.0 - 510.0)
    t.g = 1.0
  elif(wl >= 580.0) and (wl <= 645.0):
    t.r = 1.0
    t.g = -1.0 * (wl - 645.0) / (645.0 - 580.0)
  elif(wl >= 645.0) and (wl <= 780.0):
    t.r = 1.0

  var s = 1.0'f64
  if wl > 700.0: 
    s = 0.3 + 0.7 * (780.0 - wl) / (780.0 - 700.0)
  elif wl <  420.0:
    s = 0.3 + 0.7 * (wl - 380.0) / (420.0 - 380.0)

  t.r = math.pow(t.r * s, gamma)
  t.g = math.pow(t.g * s, gamma)
  t.b = math.pow(t.b * s, gamma)
  result = t
        
proc rgba_pre*(r, g, b: float64, a = 1.0'f64): rgba {.inline.} =
  result = initRgba(r, g, b, a)
  result.premultiply()
    
proc rgba_pre*(c: rgba): rgba {.inline.} =
  result = c
  result.premultiply()
  
proc rgba_pre*(c: rgba, a: float64): rgba {.inline.} =
  result = initRgba(c, a)
  result.premultiply()

proc initRgba*(wavelen: float64, gamma = 1.0'f64): rgba =
  result = rgba_from_wavelength(wavelen, gamma)
        
template get_value_type*(x: typedesc[rgba8]): typedesc = uint8
template get_calc_type*(x: typedesc[rgba8]): typedesc = uint32
template get_long_type*(x: typedesc[rgba8]): typedesc = int32
template get_base_shift*(x: typedesc[rgba8]): int = 8
template get_base_scale*(x: typedesc[rgba8]): int = 1 shl get_base_shift(x)
template get_base_mask*(x: typedesc[rgba8]): int = get_base_scale(x) - 1

proc initRgba8*(r,g,b:uint): rgba8 =
  type value_type = get_value_type(rgba8)
  result.r = r.value_type
  result.g = g.value_type
  result.b = b.value_type
  result.a = get_base_mask(rgba8).value_type
        
proc initRgba8*(c: rgba): rgba8 =
  type value_type = get_value_type(rgba8)
  const base_mask = get_base_mask(rgba8).float64
  result.r = value_type(uround(c.r * base_mask))
  result.g = value_type(uround(c.g * base_mask))
  result.b = value_type(uround(c.b * base_mask))
  result.a = value_type(uround(c.a * base_mask))
            
            
template get_value_type*(x: typedesc[rgba16]): typedesc = uint16
template get_calc_type*(x: typedesc[rgba16]): typedesc = uint32
template get_long_type*(x: typedesc[rgba16]): typedesc = int64
template get_base_shift*(x: typedesc[rgba16]): int = 16
template get_base_scale*(x: typedesc[rgba16]): int = 1 shl get_base_shift(x)
template get_base_mask*(x: typedesc[rgba16]): int = get_base_scale(x) - 1

