import math

type
  GammaNone* = object

proc initGammaNone*(): GammaNone = discard
proc getGammaValue*(g: GammaNone, x: float64): float64 = x

type
  GammaPower* = object
    gamma: float64
    
proc getGammaValue*(g: GammaPower, x: float64): float64 =
  result = math.pow(x, g.gamma)
  
proc initGammaPower*(g = 1.0'f64): GammaPower =
  result.gamma = g
  
proc setGamma*(g: var GammaPower, gamma: float64) =
  g.gamma = gamma
  
proc getGamma*(g: GammaPower): float64 =
  result = g.gamma
  
type
  GammaThreshold* = object
    threshold: float64
    
proc getGammaValue*(g: GammaThreshold, x: float64): float64 =
  result = if x < g.threshold: 0.0 else: 1.0
    
proc initGammaThreshold*(t = 0.5'f64): GammaThreshold =
  result.threshold = t
  
proc setThreshold*(g: var GammaThreshold, t: float64) =
  g.threshold = t
  
proc getThreshold*(g: GammaThreshold): float64 =
  result = g.threshold

type
  GammaLinear* = object
    mStart, mEnd: float64
    
proc getGammaValue*(g: GammaLinear, x: float64): float64 =
  if x < g.mStart: return 0.0
  if x > g.mEnd: return 1.0
  result = (x - g.mStart) / (g.mEnd - g.mStart)
  
proc initGammaLinear(s = 0.0'f64, e = 1.0'f64): GammaLinear =
  result.mStart = s
  result.mEnd = e

proc setStart*(g: var GammaLinear, s: float64) =
  g.mStart = s
  
proc setEnd*(g: var GammaLinear, e: float64) =
  g.mEnd = e
  
proc getStart*(g: GammaLinear): float64 =
  result = g.mStart
  
proc getEnd*(g:  GammaLinear): float64 =
  result = g.mEnd
  
type
  GammaMultiply* = object
    mMul: float64
    
proc getGammaValue*(g: GammaMultiply, x: float64): float64 =    
  result = min(x * g.mMul, 1.0)
  
proc initGammaMultiply*(m = 1.0'f64): GammaMultiply =
  result.mMul = m
  
proc setMul*(g: var GammaMultiply, m: float64) =
  g.mMul = m
  
proc getMul*(g: GammaMultiply): float64 =
  result = g.mMul