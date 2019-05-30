import basics, math

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

proc transparent*(c: var Rgba) =
  c.a = 0.0

proc opacity*(c: var Rgba, a: float64) =
  if a < 0.0: c.a = 0.0
  if a > 1.0: c.a = 1.0

proc opacity*(c: Rgba): float64 =
  result = c.a

proc premultiply*(c: var Rgba) =
  c.r = c.r * c.a
  c.g = c.g * c.a
  c.b = c.b * c.a

proc premultiply*(c: var Rgba, a: float64) =
  if (c.a <= 0.0) or (a <= 0.0):
    c.r = 0.0
    c.g = 0.0
    c.b = 0.0
    c.a = 0.0
    return

  c.a = a / c.a
  c.r = c.r * c.a
  c.g = c.g * c.a
  c.b = c.b * c.a

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

proc noColor*(x: typedesc[Rgba]): Rgba = initRgba()

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
  elif wl < 420.0:
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

template getValueT*(x: typedesc[Rgba8]): typedesc = uint8
template getCalcT*(x: typedesc[Rgba8]): typedesc = uint32
template getLongT*(x: typedesc[Rgba8]): typedesc = int32
template getBaseShift*(x: typedesc[Rgba8]): int = 8
template getBaseScale*(x: typedesc[Rgba8]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Rgba8]): int = getBaseScale(x) - 1
template construct*(x: typedesc[Rgba8], r,g,b: typed): untyped = initRgba8(r,g,b)
template construct*(x: typedesc[Rgba8], c: typed): untyped = initRgba8(c)
template construct*(x: typedesc[Rgba8], r,g,b,a: typed): untyped = initRgba8(r,g,b,a)

proc initRgba8*(r,g,b:uint): Rgba8 =
  type ValueT = getValueT(Rgba8)
  result.r = r.ValueT
  result.g = g.ValueT
  result.b = b.ValueT
  result.a = getBaseMask(Rgba8).ValueT

proc initRgba8*(r,g,b:int): Rgba8 {.inline.} =
  initRgba8(r.uint,g.uint,b.uint)

proc initRgba8*(r,g,b,a:uint): Rgba8 =
  type ValueT = getValueT(Rgba8)
  result.r = r.ValueT
  result.g = g.ValueT
  result.b = b.ValueT
  result.a = a.ValueT

proc initRgba8*(r,g,b,a:int): Rgba8 {.inline.} =
  initRgba8(r.uint,g.uint,b.uint,a.uint)

proc initRgba8*(c: Rgba): Rgba8 =
  type ValueT = getValueT(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  result.r = cast[ValueT](uround(c.r * baseMask))
  result.g = cast[ValueT](uround(c.g * baseMask))
  result.b = cast[ValueT](uround(c.b * baseMask))
  result.a = cast[ValueT](uround(c.a * baseMask))

proc initRgba8*(c: Rgba8, a: uint): Rgba8 =
  type ValueT = getValueT(Rgba8)
  result.r = c.r
  result.g = c.g
  result.b = c.b
  result.a = ValueT(a)

proc initRgba8*(c: Rgba8, a: int): Rgba8 {.inline.} =
  initRgba8(c, a.uint)

proc initRgba8*(c: Rgba8): Rgba8 = c

proc initRgba8*(c: Rgba, a: float64): Rgba8 =
  type ValueT = getValueT(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  result.r = ValueT(uround(c.r * baseMask))
  result.g = ValueT(uround(c.g * baseMask))
  result.b = ValueT(uround(c.b * baseMask))
  result.a = ValueT(uround(a * baseMask))

proc clear*(c: var Rgba8) =
  c.r = 0
  c.g = 0
  c.b = 0
  c.a = 0

proc transparent*(c: var Rgba8) =
  c.a = 0

proc opacity*(c: var Rgba8, a: float64) =
  type ValueT = getValueT(Rgba8)
  const baseMask = getBaseMask(Rgba8).float64
  var aa = a
  if a < 0.0: aa = 0.0
  if a > 1.0: aa = 1.0
  c.a = ValueT(uround(aa * baseMask))

proc opacity*(c: Rgba8): float64 {.discardable.} =
  const baseMask = getBaseMask(Rgba8).float64
  result = c.a.float64 / baseMask

proc premultiply*(c: var Rgba8) =
  type
    ValueT = getValueT(Rgba8)
    CalcT  = getCalcT(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)
    baseShift = getBaseShift(Rgba8)

  if c.a == baseMask: return
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return

  c.r = ValueT((CalcT(c.r) * c.a) shr baseShift)
  c.g = ValueT((CalcT(c.g) * c.a) shr baseShift)
  c.b = ValueT((CalcT(c.b) * c.a) shr baseShift)

proc premultiply*(c: var Rgba8, a: uint) =
  type
    ValueT = getValueT(Rgba8)
    CalcT  = getCalcT(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if c.a.int == baseMask and a.int >= baseMask: return
  if c.a == 0 or a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    c.a = 0
    return

  let r = (CalcT(c.r) * a.CalcT) div c.a
  let g = (CalcT(c.g) * a.CalcT) div c.a
  let b = (CalcT(c.b) * a.CalcT) div c.a
  c.r = ValueT(if r > a: a else: r)
  c.g = ValueT(if g > a: a else: g)
  c.b = ValueT(if b > a: a else: b)
  c.a = ValueT(a)

proc demultiply*(c: var Rgba8) =
  type
    ValueT = getValueT(Rgba8)
    CalcT  = getCalcT(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if c.a == baseMask: return
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return

  let r = (CalcT(c.r) * baseMask) div c.a
  let g = (CalcT(c.g) * baseMask) div c.a
  let b = (CalcT(c.b) * baseMask) div c.a
  c.r = ValueT(if r > CalcT(baseMask): CalcT(baseMask) else: r)
  c.g = ValueT(if g > CalcT(baseMask): CalcT(baseMask) else: g)
  c.b = ValueT(if b > CalcT(baseMask): CalcT(baseMask) else: b)

proc gradient*(self, c: Rgba8, k: float64): Rgba8 =
  type
    ValueT = getValueT(Rgba8)
    CalcT  = int
  const
    baseScale = getBaseScale(Rgba8)
    baseShift = getBaseShift(Rgba8)

  let ik = uround(k * baseScale).CalcT
  result.r = ValueT(CalcT(self.r) + (((CalcT(c.r) - CalcT(self.r)) * ik) shr baseShift))
  result.g = ValueT(CalcT(self.g) + (((CalcT(c.g) - CalcT(self.g)) * ik) shr baseShift))
  result.b = ValueT(CalcT(self.b) + (((CalcT(c.b) - CalcT(self.b)) * ik) shr baseShift))
  result.a = ValueT(CalcT(self.a) + (((CalcT(c.a) - CalcT(self.a)) * ik) shr baseShift))

proc add*(self: var Rgba8, c: Rgba8, cover: uint) =
  type
    ValueT = getValueT(Rgba8)
    CalcT  = getCalcT(Rgba8)
  const
    baseMask  = getBaseMask(Rgba8)

  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      let cr = self.r.CalcT + c.r.CalcT
      let cg = self.g.CalcT + c.g.CalcT
      let cb = self.b.CalcT + c.b.CalcT
      let ca = self.a.CalcT + c.a.CalcT
      self.r = if cr > CalcT(baseMask): ValueT(baseMask) else: cr.ValueT
      self.g = if cg > CalcT(baseMask): ValueT(baseMask) else: cg.ValueT
      self.b = if cb > CalcT(baseMask): ValueT(baseMask) else: cb.ValueT
      self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT
  else:
    let coverMask2 = (coverMask div 2).CalcT
    let cr = self.r.CalcT + ((c.r.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let cg = self.g.CalcT + ((c.g.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let cb = self.b.CalcT + ((c.b.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let ca = self.a.CalcT + ((c.a.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    self.r = if cr > CalcT(baseMask): ValueT(baseMask) else: cr.ValueT
    self.g = if cg > CalcT(baseMask): ValueT(baseMask) else: cg.ValueT
    self.b = if cb > CalcT(baseMask): ValueT(baseMask) else: cb.ValueT
    self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT

proc applyGammaDir*[GammaLUT](c: var Rgba8, gamma: GammaLUT) =
  c.r = gamma.dir(c.r)
  c.g = gamma.dir(c.g)
  c.b = gamma.dir(c.b)

proc applyGammaInv*[GammaLUT](c: var Rgba8, gamma: GammaLUT) =
  c.r = gamma.inv(c.r)
  c.g = gamma.inv(c.g)
  c.b = gamma.inv(c.b)

proc noColor*(x: typedesc[Rgba8]): Rgba8 =
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

template getValueT*(x: typedesc[Rgba16]): typedesc = uint16
template getCalcT*(x: typedesc[Rgba16]): typedesc = uint32
template getLongT*(x: typedesc[Rgba16]): typedesc = int64
template getBaseShift*(x: typedesc[Rgba16]): int = 16
template getBaseScale*(x: typedesc[Rgba16]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Rgba16]): int = getBaseScale(x) - 1
template construct*(x: typedesc[Rgba16], r,g,b: typed): untyped = initRgba16(r,g,b)
template construct*(x: typedesc[Rgba16], c: typed): untyped = initRgba16(c)
template construct*(x: typedesc[Rgba16], r,g,b,a: typed): untyped = initRgba16(r,g,b,a)

proc initRgba16*(r, g, b, a: uint): Rgba16 =
  type ValueT = getValueT(Rgba16)
  result.r = ValueT(r)
  result.g = ValueT(g)
  result.b = ValueT(b)
  result.a = ValueT(a)

proc initRgba16*(r, g, b: uint): Rgba16 =
  type ValueT = getValueT(Rgba16)
  result.r = ValueT(r)
  result.g = ValueT(g)
  result.b = ValueT(b)
  result.a = getBaseMask(Rgba16).ValueT

proc initRgba16*(c: Rgba16, a: uint): Rgba16 =
  type ValueT = getValueT(Rgba16)
  result.r = c.r
  result.g = c.g
  result.b = c.b
  result.a = ValueT(a)

proc initRgba16*(c: Rgba16): Rgba16 = c

proc initRgba16*(c: Rgba): Rgba16 =
  type ValueT = getValueT(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  result.r = ValueT(uround(c.r * baseMask))
  result.g = ValueT(uround(c.g * baseMask))
  result.b = ValueT(uround(c.b * baseMask))
  result.a = ValueT(uround(c.a * baseMask))

proc initRgba16*(c: Rgba, a: float64): Rgba16 =
  type ValueT = getValueT(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  result.r = ValueT(uround(c.r * baseMask))
  result.g = ValueT(uround(c.g * baseMask))
  result.b = ValueT(uround(c.b * baseMask))
  result.a = ValueT(uround(a * baseMask))

proc initRgba16*(c: Rgba8): Rgba16 =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  result.r = ValueT((CalcT(c.r) shl 8) or CalcT(c.r))
  result.g = ValueT((CalcT(c.g) shl 8) or CalcT(c.g))
  result.b = ValueT((CalcT(c.b) shl 8) or CalcT(c.b))
  result.a = ValueT((CalcT(c.a) shl 8) or CalcT(c.a))

proc initRgba16*(c: Rgba8, a: uint): Rgba16 =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  result.r = ValueT((CalcT(c.r) shl 8) or CalcT(c.r))
  result.g = ValueT((CalcT(c.g) shl 8) or CalcT(c.g))
  result.b = ValueT((CalcT(c.b) shl 8) or CalcT(c.b))
  result.a = ValueT((CalcT(a) shl 8) or CalcT(c.a))

proc clear*(c: var Rgba16) =
  c.r = 0
  c.g = 0
  c.b = 0
  c.b = 0

proc transparent*(c: var Rgba16) =
  c.a = 0

proc opacity*(c: var Rgba16, a: float64) =
  type ValueT = getValueT(Rgba16)
  const baseMask = getBaseMask(Rgba16).float64
  var aa = a
  if a < 0.0: aa = 0.0
  if a > 1.0: aa = 1.0
  c.a = ValueT(uround(aa * baseMask))

proc opacity*(c: var Rgba16): float64 =
  const baseMask = getBaseMask(Rgba16).float64
  result = c.a.float64 / baseMask

proc premultiply*(c: var Rgba16) =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)
    baseShift = getBaseShift(Rgba16)

  if c.a == baseMask: return
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return

  c.r = ValueT((CalcT(c.r) * c.a) shr baseShift)
  c.g = ValueT((CalcT(c.g) * c.a) shr baseShift)
  c.b = ValueT((CalcT(c.b) * c.a) shr baseShift)

proc premultiply*(c: var Rgba16, a: uint) =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if c.a.int == baseMask and a.int >= baseMask: return
  if c.a == 0 or a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    c.a = 0
    return

  let r = (CalcT(c.r) * a.CalcT) div c.a
  let g = (CalcT(c.g) * a.CalcT) div c.a
  let b = (CalcT(c.b) * a.CalcT) div c.a
  c.r = ValueT(if r > a: a else: r)
  c.g = ValueT(if g > a: a else: g)
  c.b = ValueT(if b > a: a else: b)
  c.a = ValueT(a)

proc demultiply*(c: var Rgba16) =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if c.a == baseMask: return
  if c.a == 0:
    c.r = 0
    c.g = 0
    c.b = 0
    return

  let r = (CalcT(c.r) * baseMask) div c.a
  let g = (CalcT(c.g) * baseMask) div c.a
  let b = (CalcT(c.b) * baseMask) div c.a
  c.r = ValueT(if r > CalcT(baseMask): CalcT(baseMask) else: r)
  c.g = ValueT(if g > CalcT(baseMask): CalcT(baseMask) else: g)
  c.b = ValueT(if b > CalcT(baseMask): CalcT(baseMask) else: b)

proc gradient*(self, c: Rgba16, k: float64): Rgba16 =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  const
    baseScale = getBaseScale(Rgba16)
    baseShift = getBaseShift(Rgba16)

  let ik = uround(k * baseScale).CalcT
  result.r = ValueT(CalcT(self.r) + (((CalcT(c.r) - self.r) * ik) shr baseShift))
  result.g = ValueT(CalcT(self.g) + (((CalcT(c.g) - self.g) * ik) shr baseShift))
  result.b = ValueT(CalcT(self.b) + (((CalcT(c.b) - self.b) * ik) shr baseShift))
  result.a = ValueT(CalcT(self.a) + (((CalcT(c.a) - self.a) * ik) shr baseShift))

proc add*(self: var Rgba16, c: Rgba16, cover: uint) =
  type
    ValueT = getValueT(Rgba16)
    CalcT  = getCalcT(Rgba16)
  const
    baseMask  = getBaseMask(Rgba16)

  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      let cr = self.r.CalcT + c.r.CalcT
      let cg = self.g.CalcT + c.g.CalcT
      let cb = self.b.CalcT + c.b.CalcT
      let ca = self.a.CalcT + c.a.CalcT
      self.r = if cr > CalcT(baseMask): ValueT(baseMask) else: cr.ValueT
      self.g = if cg > CalcT(baseMask): ValueT(baseMask) else: cg.ValueT
      self.b = if cb > CalcT(baseMask): ValueT(baseMask) else: cb.ValueT
      self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT
  else:
    let coverMask2 = (coverMask div 2).CalcT
    let cr = self.r.CalcT + ((c.r.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let cg = self.g.CalcT + ((c.g.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let cb = self.b.CalcT + ((c.b.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    let ca = self.a.CalcT + ((c.a.CalcT * cover.CalcT + coverMask2) shr coverShift.CalcT)
    self.r = if cr > CalcT(baseMask): ValueT(baseMask) else: cr.ValueT
    self.g = if cg > CalcT(baseMask): ValueT(baseMask) else: cg.ValueT
    self.b = if cb > CalcT(baseMask): ValueT(baseMask) else: cb.ValueT
    self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT

proc applyGammaDir*[GammaLUT](c: var Rgba16, gamma: GammaLUT) =
  c.r = gamma.dir(c.r)
  c.g = gamma.dir(c.g)
  c.b = gamma.dir(c.b)

proc applyGammaInv*[GammaLUT](c: var Rgba16, gamma: GammaLUT) =
  c.r = gamma.inv(c.r)
  c.g = gamma.inv(c.g)
  c.b = gamma.inv(c.b)

proc noColor*(x: typedesc[Rgba16]): Rgba16 =
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

proc rgba16Pre*(c: Rgba8, a: uint): Rgba16 {.inline.} =
  result = initRgba16(c,a)
  result.premultiply()

proc rgba16GammaDir*[GammaLUT](c: Rgba16, gamma: GammaLUT): Rgba16 {.inline.} =
  result = initRgba16(gamma.dir(c.r), gamma.dir(c.g), gamma.dir(c.b), c.a)

proc rgba16GammaInv*[GammaLUT](c: Rgba16, gamma: GammaLUT): Rgba16 {.inline.} =
  result = initRgba16(gamma.inv(c.r), gamma.inv(c.g), gamma.inv(c.b), c.a)