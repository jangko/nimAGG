import agg_basics, agg_color_rgba

type
  Gray8* = object
    v*: uint8
    a*: uint8

template getValueType*(x: typedesc[Gray8]): typedesc = uint8
template getCalcType*(x: typedesc[Gray8]): typedesc = uint32
template getLongType*(x: typedesc[Gray8]): typedesc = int32
template getBaseShift*(x: typedesc[Gray8]): int = 8
template getBaseScale*(x: typedesc[Gray8]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Gray8]): int = getBaseScale(x) - 1
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
  type ValueType = getValueType(Gray8)
  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueType
  result.a = uround(c.a * baseMask).ValueType

proc initGray8*(c: Rgba, a: float64): Gray8 =
  const baseMask = getBaseMask(Gray8).float64
  type ValueType = getValueType(Gray8)

  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueType
  result.a = uround(a * baseMask).ValueType

proc initGray8*(c: Rgba8): Gray8 =
  type
    ValueType = getValueType(Gray8)
    CalcType = getCalcType(Gray8)
  result.v = ((c.r.CalcType*77 + c.g.CalcType*150 + c.b.CalcType*29) shr 8).ValueType
  result.a = c.a

proc initGray8*(c: Rgba8, a: uint): Gray8 =
  type
    ValueType = getValueType(Gray8)
    CalcType = getCalcType(Gray8)
  result.v = ((c.r.CalcType*77 + c.g.CalcType*150 + c.b.CalcType*29) shr 8).ValueType
  result.a = a.ValueType

proc clear*(self: var Gray8) =
  self.v = 0
  self.a = 0

proc transparent*(self: var Gray8) =
  self.a = 0

proc opacity*(self: var Gray8, a: float64) =
  const baseMask = getBaseMask(Gray8).float64
  type ValueType = getValueType(Gray8)

  var a = a
  if a < 0.0: a = 0.0
  if a > 1.0: a = 1.0
  self.a = uround(a * baseMask).ValueType

proc opacity*(self: Gray8): float64 =
  const baseMask = getBaseMask(Gray8).float64
  result = self.a.float64 / baseMask

proc premultiply*(self: var Gray8): var Gray8 {.discardable.} =
  const
    baseMask = getBaseMask(Gray8)
    baseShift = getBaseShift(Gray8)

  type
    CalcType = getCalcType(Gray8)
    ValueType = getValueType(Gray8)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
  result = self

  self.v = ValueType((CalcType(self.v) * CalcType(self.a)) shr baseShift)
  result = self

proc premultiply*(self: var Gray8, a: uint): var Gray8 {.discardable.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcType = getCalcType(Gray8)
    ValueType = getValueType(Gray8)

  if self.a == baseMask and a.int >= baseMask: return self
  if self.a == 0 or a == 0:
      self.v = 0
      self.a = 0
  result = self
  let v = (CalcType(self.v) * CalcType(a)) div self.a
  self.v = ValueType(if v > a: a else: v)
  self.a = ValueType(a)
  result = self

proc demultiply*(self: var Gray8): var Gray8 {.discardable.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcType = getCalcType(Gray8)
    ValueType = getValueType(Gray8)

  if self.a == baseMask: return self
  if self.a == 0:
      self.v = 0
  result = self
  let v = (CalcType(self.v) * baseMask) div self.a
  self.v = ValueType(if v.int > baseMask: baseMask else: v.int)
  result = self

proc gradient*(self: var Gray8, c: Gray8, k: float64): Gray8 =
  type
    CalcType = getCalcType(Gray8)
    ValueType = getValueType(Gray8)

  const
    baseScale = getBaseScale(Gray8)
    baseShift = getBaseShift(Gray8).CalcType

  let ik = uround(k * baseScale).CalcType
  result.v = ValueType(CalcType(self.v) + (((CalcType(c.v) - CalcType(self.v)) * ik) shr baseShift))
  result.a = ValueType(CalcType(self.a) + (((CalcType(c.a) - CalcType(self.a)) * ik) shr baseShift))


proc add*(self: var Gray8, c: Gray8, cover: uint) {.inline.} =
  const baseMask = getBaseMask(Gray8)
  type
    CalcType = getCalcType(Gray8)
    ValueType = getValueType(Gray8)

  var cv, ca: CalcType
  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      cv = self.v + c.v; self.v = if cv > CalcType(baseMask): ValueType(baseMask) else: cv.ValueType
      ca = self.a + c.a; self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType
  else:
    cv = self.v.CalcType + ((c.v.CalcType * cover.CalcType + coverMask div 2) shr coverShift)
    ca = self.a.CalcType + ((c.a.CalcType * cover.CalcType + coverMask div 2) shr coverShift)
    self.v = if cv > CalcType(baseMask): ValueType(baseMask) else: cv.ValueType
    self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType

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

template getValueType*(x: typedesc[Gray16]): typedesc = uint16
template getCalcType*(x: typedesc[Gray16]): typedesc = uint32
template getLongType*(x: typedesc[Gray16]): typedesc = int64
template getBaseShift*(x: typedesc[Gray16]): int = 16
template getBaseScale*(x: typedesc[Gray16]): int = 1 shl getBaseShift(x)
template getBaseMask*(x: typedesc[Gray16]): int = getBaseScale(x) - 1
template construct*(x: typedesc[Gray16], v: typed): untyped = initGray16(v)

proc initGray16*(v: uint): Gray16 =
  type ValueType = getValueType(Gray16)
  const baseMask = getBaseMask(Gray16)
  result.v = v.ValueType
  result.a = baseMask.ValueType

proc initGray16*(v, a: uint): Gray16 =
  type ValueType = getValueType(Gray16)
  result.v = v.ValueType
  result.a = a.ValueType

proc initGray16*(c: Gray16, a: uint): Gray16 =
  type ValueType = getValueType(Gray16)
  result.v = c.v
  result.a = a.ValueType

proc initGray16*(c: Gray16): Gray16 = c

proc initGray16*(c: Rgba): Gray16 =
  type ValueType = getValueType(Gray16)
  const baseMask = getBaseMask(Gray16).float64
  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueType
  result.a = uround(c.a * baseMask).ValueType

proc initGray16*(c: Rgba, a: float64): Gray16 =
  type ValueType = getValueType(Gray16)
  const baseMask = getBaseMask(Gray16).float64

  result.v = uround((0.299*c.r + 0.587*c.g + 0.114*c.b) * baseMask).ValueType
  result.a = uround(a * baseMask).ValueType

proc initGray16*(c: Rgba8): Gray16 =
  type
    ValueType = getValueType(Gray16)
    CalcType = getCalcType(Gray16)
  result.v = (c.r.CalcType*77 + c.g.CalcType*150 + c.b.CalcType*29).ValueType
  result.a = (ValueType(c.a) shl 8) or c.a

proc initGray16*(c: Rgba8, a: uint): Gray16 =
  type
    ValueType = getValueType(Gray16)
    CalcType = getCalcType(Gray16)
  result.v = (c.r.CalcType*77 + c.g.CalcType*150 + c.b.CalcType*29).ValueType
  result.a = (ValueType(a) shl 8) or c.a

proc clear*(self: var Gray16) =
  self.v = 0
  self.a = 0

proc transparent*(self: var Gray16): var Gray16 {.discardable.} =
  self.a = 0
  result = self

proc opacity*(self: var Gray16, a: float64) =
  type ValueType = getValueType(Gray16)
  const baseMask = getBaseMask(Gray16)
  var a = a
  if a < 0.0: a = 0.0
  if a > 1.0: a = 1.0
  self.a = uround(a * float64(baseMask)).ValueType

proc opacity*(self: Gray16): float64 =
  const baseMask = getBaseMask(Gray16)
  result = float64(self.a) / float64(baseMask)

proc premultiply*(self: var Gray16): var Gray16 {.discardable.} =
  type
    ValueType = getValueType(Gray16)
    CalcType = getCalcType(Gray16)
  const
    baseMask = getBaseMask(Gray16)
    baseShift = getBaseShift(Gray16)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
    result = self

  self.v = ValueType((CalcType(self.v) * self.a) shr baseShift)
  result = self

proc premultiply*(self: var Gray16, a: uint): var Gray16 {.discardable.} =
  type
    ValueType = getValueType(Gray16)
    CalcType = getCalcType(Gray16)
  const baseMask = getBaseMask(Gray16)
  if self.a == baseMask and a.int >= baseMask: return self
  if self.a == 0 or a == 0:
    self.v = 0
    self.a = 0
    result = self

  let v = (CalcType(self.v) * a.CalcType) div self.a
  self.v = ValueType(if v > a: a else: v)
  self.a = ValueType(a)
  result = self

proc demultiply*(self: var Gray16): var Gray16 {.discardable.} =
  type
    CalcType = getCalcType(Gray16)
    ValueType = getValueType(Gray16)
  const baseMask = getBaseMask(Gray16)

  if self.a == baseMask: return self
  if self.a == 0:
    self.v = 0
    result = self

  let v = (CalcType(self.v) * baseMask.CalcType) div self.a
  self.v = ValueType(if v > baseMask.CalcType: baseMask.CalcType else: v)
  result = self

proc gradient*(self: var Gray16, c: Gray16, k: float64): Gray16 =
  type
    CalcType = getCalcType(Gray16)
    ValueType = getValueType(Gray16)
  const
    baseScale = getBaseScale(Gray16)
    baseShift = getBaseShift(Gray16)

  let ik = uround(k * baseScale).CalcType
  result.v = ValueType(CalcType(self.v) + (((CalcType(c.v) - self.v) * ik) shr baseShift))
  result.a = ValueType(CalcType(self.a) + (((CalcType(c.a) - self.a) * ik) shr baseShift))

proc add*(self: var Gray16, c: Gray16, cover: uint) {.inline.} =
  type
    ValueType = getValueType(Gray16)
    CalcType = getCalcType(Gray16)
  const baseMask = getBaseMask(Gray16)

  var cv, ca: CalcType
  if cover == coverMask:
    if c.a == baseMask:
      self = c
    else:
      cv = self.v + c.v; self.v = if cv > CalcType(baseMask): ValueType(baseMask) else: cv.ValueType
      ca = self.a + c.a; self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType
  else:
    cv = self.v.CalcType + ((c.v.CalcType * cover.CalcType + coverMask div 2) shr coverShift)
    ca = self.a.CalcType + ((c.a.CalcType * cover.CalcType + coverMask div 2) shr coverShift)
    self.v = if cv > CalcType(baseMask): ValueType(baseMask) else: cv.ValueType
    self.a = if ca > CalcType(baseMask): ValueType(baseMask) else: ca.ValueType

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
