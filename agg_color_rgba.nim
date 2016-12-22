import agg_basics, math

type  
  OrderRgb* {.pure.} = enum
    R=0, G=1, B=2
    
  OrderBgr* {.pure.} = enum
    B=0, G=1, R=2

  OrderRgba* {.pure.} = enum 
    R=0, G=1, B=2, A=3
    
  OrderArgb* {.pure.} = enum 
    A=0, R=1, G=2, B=3
    
  OrderAbgr* {.pure.} = enum 
    A=0, B=1, G=2, R=3
    
  OrderBgra* {.pure.} = enum 
    B=0, G=1, R=2, A=3

  Rgba* = object
    r*, g*, b*, a*: float64
    
  Rgba8* = object
    r*, g*, b*, a*: uint8
  
  Rgba16* = object
    r*, g*, b*, a*: uint16
    
proc initRgba*(): Rgba =
  result = Rgba(r:0.0, g:0.0, b:0.0, a:0.0)
  
proc initRgba*(r,g,b: float64, a=1.0'f64): Rgba =
  result = Rgba(r:r, g:g, b:b, a:a)
  
proc initRgba*(c: Rgba, a: float64): Rgba =
  result = Rgba(r:c.r, g:c.g, b:c.b, a:a)

proc clear*(c: var Rgba) =
  c.r = 0.0; c.g = 0.0; c.b = 0.0; c.a = 0.0
  
proc transparent*(c: var Rgba): var Rgba {.discardable.} =
  c.a = 0.0
  result = c
  
proc opacity*(c: var Rgba, a: float64): var Rgba {.discardable.} =
  if a < 0.0: c.a = 0.0
  if a > 1.0: c.a = 1.0
  result = c
  
proc opacity*(c: Rgba): float64 =
  result = c.a
        
proc premultiply*(c: var Rgba): var Rgba {.discardable.} =
  c.r = c.r * c.a
  c.g = c.g * c.a
  c.b = c.b * c.a
  result = c
        
proc premultiply*(c: var Rgba, a: float64): var Rgba {.discardable.} =
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
        
proc demultiply*(c: var Rgba): var Rgba {.discardable.} =
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
        
proc gradient*(a, c: Rgba, k: float64): Rgba =
  result.r = a.r + (c.r - a.r) * k
  result.g = a.g + (c.g - a.g) * k
  result.b = a.b + (c.b - a.b) * k
  result.a = a.a + (c.a - a.a) * k
        
proc RgbaNoColor*(): Rgba = initRgba()
        
proc RgbaFromWavelength*(wl: float64, gamma = 1.0'f64): Rgba =
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
        
proc Rgba_pre*(r, g, b: float64, a = 1.0'f64): Rgba {.inline.} =
  result = initRgba(r, g, b, a)
  result.premultiply()
    
proc Rgba_pre*(c: Rgba): Rgba {.inline.} =
  result = c
  result.premultiply()
  
proc Rgba_pre*(c: Rgba, a: float64): Rgba {.inline.} =
  result = initRgba(c, a)
  result.premultiply()

proc initRgba*(wavelen: float64, gamma = 1.0'f64): Rgba =
  result = RgbaFromWavelength(wavelen, gamma)
        
template getValueType*(x: typedesc[Rgba8]): typedesc = uint8
template getCalcType*(x: typedesc[Rgba8]): typedesc = uint32
template getLongType*(x: typedesc[Rgba8]): typedesc = int32
template getBaseShift*(x: typedesc[Rgba8]): int = 8
template getBaseScale*(x: typedesc[Rgba8]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Rgba8]): int = getBaseScale(x) - 1

proc initRgba8*(r,g,b:uint): Rgba8 =
  type ValueType = getValueType(Rgba8)
  result.r = r.ValueType
  result.g = g.ValueType
  result.b = b.ValueType
  result.a = getBaseMask(Rgba8).ValueType
        
proc initRgba8*(c: Rgba): Rgba8 =
  type ValueType = getValueType(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  result.r = ValueType(uround(c.r * baseMask))
  result.g = ValueType(uround(c.g * baseMask))
  result.b = ValueType(uround(c.b * baseMask))
  result.a = ValueType(uround(c.a * baseMask))
            
            
template getValueType*(x: typedesc[Rgba16]): typedesc = uint16
template getCalcType*(x: typedesc[Rgba16]): typedesc = uint32
template getLongType*(x: typedesc[Rgba16]): typedesc = int64
template getBaseShift*(x: typedesc[Rgba16]): int = 16
template getBaseScale*(x: typedesc[Rgba16]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Rgba16]): int = getBaseScale(x) - 1

