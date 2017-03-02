import agg_basics, agg_color_rgba

type
  Gray8* = object
    v*: uint8
    a*: uint8

template getValueT*(x: typedesc[Gray8]): typedesc = uint8
template getCalcT*(x: typedesc[Gray8]): typedesc = uint32
template getLongT*(x: typedesc[Gray8]): typedesc = int32
template getBaseShift*(x: typedesc[Gray8]): int = 8
template getBaseScale*(x: typedesc[Gray8]): int = (1 shl getBaseShift(x))
template getBaseMask*(x: typedesc[Gray8]): int = (getBaseScale(x) - 1)
template construct*(x: typedesc[Gray8], v: typed): untyped = initGray8(v)

proc initGray8*(v: uint): Gray8 =
  const baseMask = getBaseMask(Gray8)
  result.v = v.uint8
  result.a = baseMask.uint8

proc initGray8*(v, a: uint): Gray8 =
  result.v = v.uint8
  result.a = a.uint8

proc initGray8*(c: Gray8, a: uint): Gray8 =
  result.v = c.v
  result.a = a.uint8

proc initGray8*(c: Gray8): Gray8 = c

proc initGray8*(c: Rgba): Gray8 =
  const baseMask = getBaseMask(Gray8).float64
  type ValueT = getValueT(Gray8)
  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueT
  result.a = uround(c.a * baseMask).ValueT

proc initGray8*(c: Rgba, a: float64): Gray8 =
  const baseMask = getBaseMask(Gray8).float64
  type ValueT = getValueT(Gray8)

  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueT
  result.a = uround(a * baseMask).ValueT

proc initGray8*(c: Rgba8): Gray8 =
  type
    ValueT = getValueT(Gray8)
    CalcT = getCalcT(Gray8)
  result.v = ((c.r.CalcT*77 + c.g.CalcT*150 + c.b.CalcT*29) shr 8).ValueT
  result.a = c.a

proc initGray8*(c: Rgba8, a: uint): Gray8 =
  type
    ValueT = getValueT(Gray8)
    CalcT = getCalcT(Gray8)
  result.v = ((c.r.CalcT*77 + c.g.CalcT*150 + c.b.CalcT*29) shr 8).ValueT
  result.a = a.ValueT

proc initRgba8*(c: Gray8): Rgba8 =
  result.r = c.v
  result.g = c.v
  result.b = c.v
  result.a = c.a

proc clear*(self: var Gray8) =
  self.v = 0
  self.a = 0

proc transparent*(self: var Gray8) =
  self.a = 0

proc opacity*(self: var Gray8, a: float64) =
  const baseMask = getBaseMask(Gray8).float64
  type ValueT = getValueT(Gray8)

  var a = a
  if a < 0.0: a = 0.0
  if a > 1.0: a = 1.0
  self.a = uround(a * baseMask).ValueT

proc opacity*(self: Gray8): float64 =
  const baseMask = getBaseMask(Gray8).float64
  result = self.a.float64 / baseMask

proc premultiply*(self: var Gray8): var Gray8 {.discardable.} =
  const
    baseMask = getBaseMask(Gray8)
    baseShift = getBaseShift(Gray8)

  type
    CalcT = getCalcT(Gray8)
    ValueT = getValueT(Gray8)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
  result = self

  self.v = ValueT((CalcT(self.v) * CalcT(self.a)) shr baseShift)
  result = self

proc premultiply*(self: var Gray8, a: uint): var Gray8 {.discardable.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcT = getCalcT(Gray8)
    ValueT = getValueT(Gray8)

  if self.a == baseMask and a.int >= baseMask: return self
  if self.a == 0 or a == 0:
      self.v = 0
      self.a = 0
  result = self
  let v = (CalcT(self.v) * CalcT(a)) div self.a
  self.v = ValueT(if v > a: a else: v)
  self.a = ValueT(a)
  result = self

proc demultiply*(self: var Gray8): var Gray8 {.discardable.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcT = getCalcT(Gray8)
    ValueT = getValueT(Gray8)

  if self.a == baseMask: return self
  if self.a == 0:
      self.v = 0
  result = self
  let v = (CalcT(self.v) * baseMask) div self.a
  self.v = ValueT(if v.int > baseMask: baseMask else: v.int)
  result = self

proc gradient*(self: var Gray8, c: Gray8, k: float64): Gray8 =
  type
    CalcT = getCalcT(Gray8)
    ValueT = getValueT(Gray8)

  const
    baseScale = getBaseScale(Gray8)
    baseShift = getBaseShift(Gray8).CalcT

  let ik = uround(k * baseScale).CalcT
  result.v = ValueT(CalcT(self.v) + (((CalcT(c.v) - CalcT(self.v)) * ik) shr baseShift))
  result.a = ValueT(CalcT(self.a) + (((CalcT(c.a) - CalcT(self.a)) * ik) shr baseShift))


proc add*(self: var Gray8, c: Gray8, cover: uint) {.inline.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcT = getCalcT(Gray8)
    ValueT = getValueT(Gray8)

  var cv, ca: CalcT
  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      cv = self.v + c.v; self.v = if cv > CalcT(baseMask): ValueT(baseMask) else: cv.ValueT
      ca = self.a + c.a; self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT
  else:
    cv = self.v.CalcT + ((c.v.CalcT * cover.CalcT + coverMask div 2) shr coverShift)
    ca = self.a.CalcT + ((c.a.CalcT * cover.CalcT + coverMask div 2) shr coverShift)
    self.v = if cv > CalcT(baseMask): ValueT(baseMask) else: cv.ValueT
    self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT

proc noColor*(x: typedesc[Gray8]): Gray8 = Gray8(v: 0, a: 0)

proc Gray8Pre*(v: uint): Gray8 =
  const baseMask = getBaseMask(Gray8)
  result = initGray8(v, baseMask)
  result.premultiply()

proc Gray8Pre*(v, a: uint): Gray8 =
  result = initGray8(v,a)
  result.premultiply()

proc Gray8Pre*(c: Gray8, a: uint): Gray8 =
  result = initGray8(c,a)
  result.premultiply()

proc Gray8Pre*(c: Rgba): Gray8 =
  result = initGray8(c)
  result.premultiply()

proc Gray8Pre*(c: Rgba, a: float64): Gray8 =
  result = initGray8(c,a)
  result.premultiply()

proc Gray8Pre*(c: Rgba8): Gray8 =
  result = initGray8(c)
  result.premultiply()

proc Gray8Pre*(c: Rgba8, a: uint): Gray8 =
  result = initGray8(c,a)
  result.premultiply()


type
  Gray16* = object
    v*: uint16
    a*: uint16

template getValueT*(x: typedesc[Gray16]): typedesc = uint16
template getCalcT*(x: typedesc[Gray16]): typedesc = uint32
template getLongT*(x: typedesc[Gray16]): typedesc = int64
template getBaseShift*(x: typedesc[Gray16]): int = 16
template getBaseScale*(x: typedesc[Gray16]): int = (1 shl getBaseShift(x))
template getBaseMask*(x: typedesc[Gray16]): int = (getBaseScale(x) - 1)
template construct*(x: typedesc[Gray16], v: typed): untyped = initGray16(v)

proc initGray16*(v: uint): Gray16 =
  type ValueT = getValueT(Gray16)
  const baseMask = getBaseMask(Gray16)
  result.v = v.ValueT
  result.a = baseMask.ValueT

proc initGray16*(v, a: uint): Gray16 =
  type ValueT = getValueT(Gray16)
  result.v = v.ValueT
  result.a = a.ValueT

proc initGray16*(c: Gray16, a: uint): Gray16 =
  type ValueT = getValueT(Gray16)
  result.v = c.v
  result.a = a.ValueT

proc initGray16*(c: Gray16): Gray16 = c

proc initGray16*(c: Rgba): Gray16 =
  type ValueT = getValueT(Gray16)
  const baseMask = getBaseMask(Gray16).float64
  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueT
  result.a = uround(c.a * baseMask).ValueT

proc initGray16*(c: Rgba, a: float64): Gray16 =
  type ValueT = getValueT(Gray16)
  const baseMask = getBaseMask(Gray16).float64

  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueT
  result.a = uround(a * baseMask).ValueT

proc initGray16*(c: Rgba8): Gray16 =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  result.v = (c.r.CalcT*77 + c.g.CalcT*150 + c.b.CalcT*29).ValueT
  result.a = (ValueT(c.a) shl 8) or c.a

proc initGray16*(c: Rgba16): Gray16 =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  result.v = (c.r.CalcT*19595 + c.g.CalcT*36469 + c.b.CalcT*7471).ValueT
  result.a = c.a

proc initGray16*(c: Rgba8, a: uint): Gray16 =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  result.v = (c.r.CalcT*77 + c.g.CalcT*150 + c.b.CalcT*29).ValueT
  result.a = (ValueT(a) shl 8) or c.a

proc initRgba16*(c: Gray16): Rgba16 =
  result.r = c.v
  result.g = c.v
  result.b = c.v
  result.a = c.a

proc clear*(self: var Gray16) =
  self.v = 0
  self.a = 0

proc transparent*(self: var Gray16): var Gray16 {.discardable.} =
  self.a = 0
  result = self

proc opacity*(self: var Gray16, a: float64) =
  type ValueT = getValueT(Gray16)
  const baseMask = getBaseMask(Gray16)
  var a = a
  if a < 0.0: a = 0.0
  if a > 1.0: a = 1.0
  self.a = uround(a * float64(baseMask)).ValueT

proc opacity*(self: Gray16): float64 =
  const baseMask = getBaseMask(Gray16)
  result = float64(self.a) / float64(baseMask)

proc premultiply*(self: var Gray16): var Gray16 {.discardable.} =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  const
    baseMask = getBaseMask(Gray16)
    baseShift = getBaseShift(Gray16)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
    result = self

  self.v = ValueT((CalcT(self.v) * self.a) shr baseShift)
  result = self

proc premultiply*(self: var Gray16, a: uint): var Gray16 {.discardable.} =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  const baseMask = getBaseMask(Gray16)
  if self.a == baseMask and a.int >= baseMask: return self
  if self.a == 0 or a == 0:
    self.v = 0
    self.a = 0
    result = self

  let v = (CalcT(self.v) * a.CalcT) div self.a
  self.v = ValueT(if v > a: a else: v)
  self.a = ValueT(a)
  result = self

proc demultiply*(self: var Gray16): var Gray16 {.discardable.} =
  type
    CalcT = getCalcT(Gray16)
    ValueT = getValueT(Gray16)
  const baseMask = getBaseMask(Gray16)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
    result = self

  let v = (CalcT(self.v) * baseMask.CalcT) div self.a
  self.v = ValueT(if v > baseMask.CalcT: baseMask.CalcT else: v)
  result = self

proc gradient*(self: var Gray16, c: Gray16, k: float64): Gray16 =
  type
    CalcT = getCalcT(Gray16)
    ValueT = getValueT(Gray16)
  const
    baseScale = getBaseScale(Gray16)
    baseShift = getBaseShift(Gray16)

  let ik = uround(k * baseScale).CalcT
  result.v = ValueT(CalcT(self.v) + (((CalcT(c.v) - self.v) * ik) shr baseShift))
  result.a = ValueT(CalcT(self.a) + (((CalcT(c.a) - self.a) * ik) shr baseShift))

proc add*(self: var Gray16, c: Gray16, cover: uint) {.inline.} =
  type
    ValueT = getValueT(Gray16)
    CalcT = getCalcT(Gray16)
  const baseMask = getBaseMask(Gray16)

  var cv, ca: CalcT
  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      cv = self.v + c.v; self.v = if cv > CalcT(baseMask): ValueT(baseMask) else: cv.ValueT
      ca = self.a + c.a; self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT
  else:
    cv = self.v.CalcT + ((c.v.CalcT * cover.CalcT + coverMask div 2) shr coverShift)
    ca = self.a.CalcT + ((c.a.CalcT * cover.CalcT + coverMask div 2) shr coverShift)
    self.v = if cv > CalcT(baseMask): ValueT(baseMask) else: cv.ValueT
    self.a = if ca > CalcT(baseMask): ValueT(baseMask) else: ca.ValueT

proc noColor*(x: typedesc[Gray16]): Gray16 = Gray16(v:0, a:0)

proc Gray16Pre*(v: uint): Gray16 =
  const baseMask = getBaseMask(Gray16)
  result = initGray16(v, baseMask)
  result.premultiply()

proc Gray16Pre*(v, a: uint): Gray16 =
  result = initGray16(v,a)
  result.premultiply()

proc Gray16Pre*(c: Gray16, a: uint): Gray16 =
  result = initGray16(c,a)
  result.premultiply()

proc Gray16Pre*(c: Rgba): Gray16 =
  result = initGray16(c)
  result.premultiply()

proc Gray16Pre*(c: Rgba, a: float64): Gray16 =
  result = initGray16(c,a)
  result.premultiply()

proc Gray16Pre*(c: Rgba8): Gray16 =
  result = initGray16(c)
  result.premultiply()

proc Gray16Pre*(c: Rgba8, a: uint): Gray16 =
  result = initGray16(c,a)
  result.premultiply()
