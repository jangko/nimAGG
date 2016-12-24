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
  c.g = c.g * a
  c.b = c.b * a
  result = c

proc gradient*(a, c: Rgba, k: float64): Rgba =
  result.r = a.r + (c.r - a.r) * k
  result.g = a.g + (c.g - a.g) * k
  result.b = a.b + (c.b - a.b) * k
  result.a = a.a + (c.a - a.a) * k

proc rgbaNoColor*(): Rgba = initRgba()

proc rgbaFromWavelength*(wl: float64, gamma = 1.0'f64): Rgba =
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

proc rgbaPre*(r, g, b: float64, a = 1.0'f64): Rgba {.inline.} =
  result = initRgba(r, g, b, a)
  result.premultiply()

proc rgbaPre*(c: Rgba): Rgba {.inline.} =
  result = c
  result.premultiply()

proc rgbaPre*(c: Rgba, a: float64): Rgba {.inline.} =
  result = initRgba(c, a)
  result.premultiply()

proc initRgba*(wavelen: float64, gamma = 1.0'f64): Rgba =
  result = rgbaFromWavelength(wavelen, gamma)

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

proc initRgba8*(r,g,b,a:uint): Rgba8 =
  type ValueType = getValueType(Rgba8)
  result.r = r.ValueType
  result.g = g.ValueType
  result.b = b.ValueType
  result.a = a.ValueType

proc initRgba8*(c: Rgba): Rgba8 =
  type ValueType = getValueType(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  result.r = ValueType(uround(c.r * baseMask))
  result.g = ValueType(uround(c.g * baseMask))
  result.b = ValueType(uround(c.b * baseMask))
  result.a = ValueType(uround(c.a * baseMask))

proc initRgba8*(c: Rgba8, a: uint): Rgba8 =
  type ValueType = getValueType(Rgba8)
  result.r = c.r
  result.g = c.g
  result.b = c.b
  result.a = ValueType(a)

proc initRgba8*(c: Rgba, a: float64): Rgba8 =
  type ValueType = getValueType(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  result.r = ValueType(uround(c.r * baseMask))
  result.g = ValueType(uround(c.g * baseMask))
  result.b = ValueType(uround(c.b * baseMask))
  result.a = ValueType(uround(a   * baseMask))

proc clear*(c: var Rgba8) =
  c.r = 0
  c.g = 0
  c.b = 0
  c.a = 0

proc transparent*(c: var Rgba8): var Rgba8 {.discardable.} =
  c.a = 0
  result = c

proc opacity*(c: var Rgba8, a: float64): var Rgba8 {.discardable.} =
  type ValueType = getValueType(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  var aa = a
  if a < 0.0: aa = 0.0
  if a > 1.0: aa = 1.0
  c.a = ValueType(uround(aa * baseMask))
  result = c

proc opacity*(c: Rgba8): float64 {.discardable.} =
  const baseMask = getBaseMask(Rgba8).float64
  result = c.a.float64 / baseMask

proc premultiply*(c: var Rgba8): var Rgba8 {.discardable, inline.} =
  type
    ValueType = getValueType(Rgba8)
    CalcType  = getCalcType(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)
    baseShift = getBaseShift(Rgba8)

  if c.a == baseMask: return c
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return c

  c.r = ValueType((CalcType(c.r) * c.a) shr baseShift)
  c.g = ValueType((CalcType(c.g) * c.a) shr baseShift)
  c.b = ValueType((CalcType(c.b) * c.a) shr baseShift)
  result = c

proc premultiply*(c: var Rgba8, a: uint): var Rgba8 {.discardable, inline.} =
  type
    ValueType = getValueType(Rgba8)
    CalcType  = getCalcType(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if c.a.int == baseMask and a.int >= baseMask: return c
  if c.a == 0 or a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    c.a = 0
    return c

  let r = (CalcType(c.r) * a.CalcType) div c.a
  let g = (CalcType(c.g) * a.CalcType) div c.a
  let b = (CalcType(c.b) * a.CalcType) div c.a
  c.r = ValueType(if r > a: a else: r)
  c.g = ValueType(if g > a: a else: g)
  c.b = ValueType(if b > a: a else: b)
  c.a = ValueType(a)
  result = c

proc demultiply*(c: var Rgba8): var Rgba8 {.discardable, inline.} =
  type
    ValueType = getValueType(Rgba8)
    CalcType  = getCalcType(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if c.a == baseMask: return c
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return c

  let r = (CalcType(c.r) * baseMask) div c.a
  let g = (CalcType(c.g) * baseMask) div c.a
  let b = (CalcType(c.b) * baseMask) div c.a
  c.r = ValueType(if r > CalcType(baseMask): CalcType(baseMask) else: r)
  c.g = ValueType(if g > CalcType(baseMask): CalcType(baseMask) else: g)
  c.b = ValueType(if b > CalcType(baseMask): CalcType(baseMask) else: b)
  result = c

proc gradient*(self, c: Rgba8, k: float64): Rgba8 =
  type
    ValueType = getValueType(Rgba8)
    CalcType  = getCalcType(Rgba8)
  const
    baseScale = getBaseScale(Rgba8)
    baseShift = getBaseShift(Rgba8)

  let ik = uround(k * baseScale).CalcType
  result.r = ValueType(CalcType(self.r) + (((CalcType(c.r) - self.r) * ik) shr baseShift))
  result.g = ValueType(CalcType(self.g) + (((CalcType(c.g) - self.g) * ik) shr baseShift))
  result.b = ValueType(CalcType(self.b) + (((CalcType(c.b) - self.b) * ik) shr baseShift))
  result.a = ValueType(CalcType(self.a) + (((CalcType(c.a) - self.a) * ik) shr baseShift))

proc add*(self: var Rgba8, c: Rgba8, cover: uint) =
  type
    ValueType = getValueType(Rgba8)
    CalcType  = getCalcType(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      let cr = self.r.CalcType + c.r.CalcType
      let cg = self.g.CalcType + c.g.CalcType
      let cb = self.b.CalcType + c.b.CalcType
      let ca = self.a.CalcType + c.a.CalcType
      self.r = if cr > CalcType(baseMask): ValueType(baseMask) else: cr.ValueType
      self.g = if cg > CalcType(baseMask): ValueType(baseMask) else: cg.ValueType
      self.b = if cb > CalcType(baseMask): ValueType(baseMask) else: cb.ValueType
      self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType
  else:
    let coverMask2 = (coverMask div 2).CalcType
    let cr = self.r.CalcType + ((c.r.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let cg = self.g.CalcType + ((c.g.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let cb = self.b.CalcType + ((c.b.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let ca = self.a.CalcType + ((c.a.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    self.r = if cr > CalcType(baseMask): ValueType(baseMask) else: cr.ValueType
    self.g = if cg > CalcType(baseMask): ValueType(baseMask) else: cg.ValueType
    self.b = if cb > CalcType(baseMask): ValueType(baseMask) else: cb.ValueType
    self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType

proc applyGammaDir*[GammaLUT](c: var Rgba8, gamma: GammaLUT) =
  c.r = gamma.dir(c.r)
  c.g = gamma.dir(c.g)
  c.b = gamma.dir(c.b)

proc applyGammaInv*[GammaLUT](c: var Rgba8, gamma: GammaLUT) =
  c.r = gamma.inv(c.r)
  c.g = gamma.inv(c.g)
  c.b = gamma.inv(c.b)

proc rgba8NoColor*(): Rgba8 =
  result = Rgba8(r:0,g:0,b:0,a:0)

proc rgba8FromWavelength*(wl: float64, gamma = 1.0'f64): Rgba8 {.inline.} =
  result = initRgba8(rgbaFromWavelength(wl, gamma))

proc rgba8Pre*(r, g, b, a: uint): Rgba8 {.inline.} =
  result = initRgba8(r,g,b,a)
  result.premultiply()

proc rgba8Pre*(r, g, b: uint): Rgba8 {.inline.} =
  const
    baseMask  = getBaseMask(Rgba8)
  result = initRgba8(r,g,b,baseMask)
  result.premultiply()

proc rgba8Pre*(c: Rgba8): Rgba8 {.inline.} =
  result = c
  result.premultiply()

proc rgba8Pre*(c: Rgba8, a: uint): Rgba8 {.inline.} =
  result = initRgba8(c,a)
  result.premultiply()

proc rgba8Pre*(c: Rgba): Rgba8 {.inline.} =
  result = initRgba8(c)
  result.premultiply()

proc rgba8Pre*(c: Rgba, a: float64): Rgba8 {.inline.} =
  result = initRgba8(c,a)
  result.premultiply()

proc rgb8Packed*(v: uint): Rgba8 {.inline.} =
  result = initRgba8((v shr 16) and 0xFF, (v shr 8) and 0xFF, v and 0xFF)

proc bgr8Packed*(v: uint): Rgba8 {.inline.} =
  result = initRgba8(v and 0xFF, (v shr 8) and 0xFF, (v shr 16) and 0xFF)

proc argb8Packed*(v: uint): Rgba8 {.inline.} =
  result = initRgba8((v shr 16) and 0xFF, (v shr 8) and 0xFF, v and 0xFF, v shr 24)

proc rgba8GammaDir*[GammaLUT](c: Rgba8, gamma: GammaLUT): Rgba8 {.inline.} =
  result = initRgba8(gamma.dir(c.r), gamma.dir(c.g), gamma.dir(c.b), c.a)

proc rgba8GammaInv*[GammaLUT](c: Rgba8, gamma: GammaLUT): Rgba8 {.inline.} =
  result = initRgba8(gamma.inv(c.r), gamma.inv(c.g), gamma.inv(c.b), c.a)

template getValueType*(x: typedesc[Rgba16]): typedesc = uint16
template getCalcType*(x: typedesc[Rgba16]): typedesc = uint32
template getLongType*(x: typedesc[Rgba16]): typedesc = int64
template getBaseShift*(x: typedesc[Rgba16]): int = 16
template getBaseScale*(x: typedesc[Rgba16]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Rgba16]): int = getBaseScale(x) - 1

proc initRgba16*(r, g, b, a: uint): Rgba16 =
  type ValueType = getValueType(Rgba16)
  result.r = ValueType(r)
  result.g = ValueType(g)
  result.b = ValueType(b)
  result.a = ValueType(a)

proc initRgba16*(r, g, b: uint): Rgba16 =
  type ValueType = getValueType(Rgba16)
  result.r = ValueType(r)
  result.g = ValueType(g)
  result.b = ValueType(b)
  result.a = getBaseMask(Rgba16).ValueType

proc initRgba16*(c: Rgba16, a: uint): Rgba16 =
  type ValueType = getValueType(Rgba16)
  result.r = c.r
  result.g = c.g
  result.b = c.b
  result.a = ValueType(a)

proc initRgba16*(c: Rgba): Rgba16 =
  type ValueType = getValueType(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  result.r = ValueType(uround(c.r * baseMask))
  result.g = ValueType(uround(c.g * baseMask))
  result.b = ValueType(uround(c.b * baseMask))
  result.a = ValueType(uround(c.a * baseMask))

proc initRgba16*(c: Rgba, a: float64): Rgba16 =
  type ValueType = getValueType(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  result.r = ValueType(uround(c.r * baseMask))
  result.g = ValueType(uround(c.g * baseMask))
  result.b = ValueType(uround(c.b * baseMask))
  result.a = ValueType(uround(a   * baseMask))

proc initRgba16*(c: Rgba8): Rgba16 =
  type ValueType = getValueType(Rgba16)
  result.r = (ValueType(c.r) shl 8.ValueType) or c.r.ValueType
  result.g = (ValueType(c.g) shl 8.ValueType) or c.g.ValueType
  result.b = (ValueType(c.b) shl 8.ValueType) or c.b.ValueType
  result.a = (ValueType(c.a) shl 8.ValueType) or c.a.ValueType

proc initRgba16*(c: Rgba8, a: float64): Rgba16 =
  type ValueType = getValueType(Rgba16)
  result.r = (ValueType(c.r) shl 8.ValueType) or c.r.ValueType
  result.g = (ValueType(c.g) shl 8.ValueType) or c.g.ValueType
  result.b = (ValueType(c.b) shl 8.ValueType) or c.b.ValueType
  result.a = (ValueType(a)   shl 8.ValueType) or c.a.ValueType

proc clear*(c: var Rgba16) =
  c.r = 0
  c.g = 0
  c.b = 0
  c.b = 0

proc transparent*(c: var Rgba16): var Rgba16 {.discardable.} =
  c.a = 0
  result = c

proc opacity*(c: var Rgba16, a: float64): var Rgba16 {.discardable.} =
  type ValueType = getValueType(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  var aa = a
  if a < 0.0: aa = 0.0
  if a > 1.0: aa = 1.0
  c.a = ValueType(uround(aa * baseMask))
  result = c

proc opacity*(c: var Rgba16): float64 =
  const baseMask = getBaseMask(Rgba16).float64
  result = c.a.float64 / baseMask
  
proc premultiply*(c: var Rgba16): var Rgba16 {.discardable.} =
  type
    ValueType = getValueType(Rgba16)
    CalcType  = getCalcType(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)
    baseShift = getBaseShift(Rgba16)

  if c.a == baseMask: return c
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return c

  c.r = ValueType((CalcType(c.r) * c.a) shr baseShift)
  c.g = ValueType((CalcType(c.g) * c.a) shr baseShift)
  c.b = ValueType((CalcType(c.b) * c.a) shr baseShift)
  result = c
  
proc premultiply*(c: var Rgba16, a: uint): var Rgba16 {.discardable, inline.} =
  type
    ValueType = getValueType(Rgba16)
    CalcType  = getCalcType(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if c.a.int == baseMask and a.int >= baseMask: return c
  if c.a == 0 or a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    c.a = 0
    return c

  let r = (CalcType(c.r) * a.CalcType) div c.a
  let g = (CalcType(c.g) * a.CalcType) div c.a
  let b = (CalcType(c.b) * a.CalcType) div c.a
  c.r = ValueType(if r > a: a else: r)
  c.g = ValueType(if g > a: a else: g)
  c.b = ValueType(if b > a: a else: b)
  c.a = ValueType(a)
  result = c

proc demultiply*(c: var Rgba16): var Rgba16 {.discardable, inline.} =
  type
    ValueType = getValueType(Rgba16)
    CalcType  = getCalcType(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if c.a == baseMask: return c
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return c

  let r = (CalcType(c.r) * baseMask) div c.a
  let g = (CalcType(c.g) * baseMask) div c.a
  let b = (CalcType(c.b) * baseMask) div c.a
  c.r = ValueType(if r > CalcType(baseMask): CalcType(baseMask) else: r)
  c.g = ValueType(if g > CalcType(baseMask): CalcType(baseMask) else: g)
  c.b = ValueType(if b > CalcType(baseMask): CalcType(baseMask) else: b)
  result = c
  
proc gradient*(self, c: Rgba16, k: float64): Rgba16 =
  type
    ValueType = getValueType(Rgba16)
    CalcType  = getCalcType(Rgba16)
  const
    baseScale = getBaseScale(Rgba16)
    baseShift = getBaseShift(Rgba16)

  let ik = uround(k * baseScale).CalcType
  result.r = ValueType(CalcType(self.r) + (((CalcType(c.r) - self.r) * ik) shr baseShift))
  result.g = ValueType(CalcType(self.g) + (((CalcType(c.g) - self.g) * ik) shr baseShift))
  result.b = ValueType(CalcType(self.b) + (((CalcType(c.b) - self.b) * ik) shr baseShift))
  result.a = ValueType(CalcType(self.a) + (((CalcType(c.a) - self.a) * ik) shr baseShift))

proc add*(self: var Rgba16, c: Rgba16, cover: uint) =
  type
    ValueType = getValueType(Rgba16)
    CalcType  = getCalcType(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      let cr = self.r.CalcType + c.r.CalcType
      let cg = self.g.CalcType + c.g.CalcType
      let cb = self.b.CalcType + c.b.CalcType
      let ca = self.a.CalcType + c.a.CalcType
      self.r = if cr > CalcType(baseMask): ValueType(baseMask) else: cr.ValueType
      self.g = if cg > CalcType(baseMask): ValueType(baseMask) else: cg.ValueType
      self.b = if cb > CalcType(baseMask): ValueType(baseMask) else: cb.ValueType
      self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType
  else:
    let coverMask2 = (coverMask div 2).CalcType
    let cr = self.r.CalcType + ((c.r.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let cg = self.g.CalcType + ((c.g.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let cb = self.b.CalcType + ((c.b.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    let ca = self.a.CalcType + ((c.a.CalcType * cover.CalcType + coverMask2) shr coverShift.CalcType)
    self.r = if cr > CalcType(baseMask): ValueType(baseMask) else: cr.ValueType
    self.g = if cg > CalcType(baseMask): ValueType(baseMask) else: cg.ValueType
    self.b = if cb > CalcType(baseMask): ValueType(baseMask) else: cb.ValueType
    self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType

proc applyGammaDir*[GammaLUT](c: var Rgba16, gamma: GammaLUT) =
  c.r = gamma.dir(c.r)
  c.g = gamma.dir(c.g)
  c.b = gamma.dir(c.b)

proc applyGammaInv*[GammaLUT](c: var Rgba16, gamma: GammaLUT) =
  c.r = gamma.inv(c.r)
  c.g = gamma.inv(c.g)
  c.b = gamma.inv(c.b)
  
proc rgba16NoColor*(): Rgba16 =
  result = Rgba16(r:0,g:0,b:0,a:0)

proc rgab16FromWavelength*(wl: float64, gamma = 1.0'f64): Rgba16 =
  result = initRgba16(rgbaFromWavelength(wl, gamma))

proc rgba16Pre*(r, g, b, a: uint): Rgba16 {.inline.} =
  result = initRgba16(r,g,b,a)
  result.premultiply()
  
proc rgba16Pre*(r, g, b: uint): Rgba16 {.inline.} =
  const baseMask = getBaseMask(Rgba16)
  result = initRgba16(r,g,b,baseMask)
  result.premultiply()
  
proc rgba16Pre*(c: Rgba16, a: uint): Rgba16 {.inline.} =
  result = initRgba16(c,a)
  result.premultiply()

proc rgba16Pre*(c: Rgba): Rgba16 {.inline.} =
  result = initRgba16(c)
  result.premultiply()

proc rgba16Pre*(c: Rgba, a: float64): Rgba16 {.inline.} =
  result = initRgba16(c,a)
  result.premultiply()
  
proc rgba16Pre*(c: Rgba8): Rgba16 {.inline.} =
  result = initRgba16(c)
  result.premultiply()
  
proc rgba16Pre*(c: Rgba8, a: float64): Rgba16 {.inline.} =
  result = initRgba16(c,a)
  result.premultiply()

proc rgba16GammaDir*[GammaLUT](c: Rgba16, gamma: GammaLUT): Rgba16 {.inline.} =
  result = initRgba16(gamma.dir(c.r), gamma.dir(c.g), gamma.dir(c.b), c.a)

proc rgba16GammaInv*[GammaLUT](c: Rgba16, gamma: GammaLUT): Rgba16 {.inline.} =
  result = initRgba16(gamma.inv(c.r), gamma.inv(c.g), gamma.inv(c.b), c.a)