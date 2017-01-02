import math

template `+`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

template `+=`*[T](p: ptr T, off: int) =
  p = p + off

template inc*[T](p: ptr T) =
  p = p + 1

template inc*[T](p: ptr T, off: int) =
  p = p + off

template `-`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

template `-=`*[T](p: ptr T, off: int) =
  p = p - off

template `[]`*[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]`*[O: enum; T](p: ptr T, off: O): T =
  (p + off.ord)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

template `[]=`*[O: enum; T](p: ptr T, off: O, val: T) =
  (p + off.ord)[] = val

template doWhile*(a: typed, b: typed) =
  while true:
    b
    if not a:
      break

type
  RowInfo*[T] = object
    x1*, x2*: int
    data*: ptr T

proc iround*(v: float64): int {.inline.} =
  result = if v < 0.0: (v - 0.5).int else: (v + 0.5).int

proc uround*(x: float64): int {.inline.} =
  result = math.round(x).int

proc iround*(v: float64, Limit: static[int]): int {.inline.} =
  if v < float64(-Limit): return -Limit
  if v > float64( Limit): return  Limit
  result = iround(v)

const
  coverShift* = 8                  #----cover_shift
  coverSize*  = 1 shl cover_shift  #----cover_size
  coverMask*  = cover_size - 1     #----cover_mask
  coverNone*  = 0                  #----cover_none
  coverFull*  = cover_mask         #----cover_full

  polySubpixelShift* = 8
  polySubpixelScale* = 1 shl polySubpixelShift
  polySubpixelMask*  = polySubpixelScale - 1

type
  FillingRule* = enum
   fillNonZero
   fillEvenOdd

type
  RectBase*[T] = object
    x1*, y1*, x2*, y2*: T

  RectI* = RectBase[int]
  RectF* = RectBase[float32]
  RectD* = RectBase[float64]

proc initRectBase*[T](x1, y1, x2, y2: T): RectBase[T] =
  result.x1 = x1
  result.y1 = y1
  result.x2 = x2
  result.y2 = y2

proc normalize*[T](r: var RectBase[T]) =
  if r.x1 > r.x2: swap(r.x1, r.x2)
  if r.y1 > r.y2: swap(r.y1, r.y2)

proc clip*[T](r: var RectBase[T], o: RectBase[T]): bool =
  if r.x2 > o.x2: r.x2 = o.x2
  if r.y2 > o.y2: r.y2 = o.y2
  if r.x1 < o.x1: r.x1 = o.x1
  if r.y1 < o.y1: r.y1 = o.y1
  result = r.x1 <= r.x2 and r.y1 <= r.y2

proc isValid*[T](r: RectBase[T]): bool =
  result = r.x1 <= r.x2 and r.y1 <= r.y2

proc hitTest*[T](r: RectBase[T], x, y: T): bool =
  result = x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2

proc intersectRectangles*[Rect](r1, r2: Rect): Rect {.inline.} =
  result = r1
  if result.x2 > r2.x2: result.x2 = r2.x2
  if result.y2 > r2.y2: result.y2 = r2.y2
  if result.x1 < r2.x1: result.x1 = r2.x1
  if result.y1 < r2.y1: result.y1 = r2.y1

proc uniteRectangles*[Rect](r1, r2: Rect): Rect {.inline.} =
  result = r1
  if result.x2 < r2.x2: result.x2 = r2.x2
  if result.y2 < r2.y2: result.y2 = r2.y2
  if result.x1 > r2.x1: result.x1 = r2.x1
  if result.y1 > r2.y1: result.y1 = r2.y1

const
  pathCmdStop*     = 0'u
  pathCmdMoveTo*   = 1'u
  pathCmdLineTo*   = 2'u
  pathCmdCurve3*   = 3'u
  pathCmdCurve4*   = 4'u
  pathCmdCurveN*   = 5'u
  pathCmdCatrom*   = 6'u
  pathCmdUbspline* = 7'u
  pathCmdEndPoly*  = 0x0F'u
  pathCmdMask*     = 0x0F'u
  
  pathFlagsNone*  = 0'u
  pathFlagsCcw*   = 0x10'u
  pathFlagsCw*    = 0x20'u
  pathFlagsClose* = 0x40'u
  pathFlagsMask*  = 0xF0'u
  
proc isVertex*(c: uint): bool {.inline.} =
  result = c >= pathCmdMoveTo and c < pathCmdEndPoly

proc isDrawing*(c: uint): bool {.inline.} =
  result = c >= pathCmdLineTo and c < pathCmdEndPoly

proc isStop*(c: uint): bool {.inline.} =
  result = c == pathCmdStop

proc isMoveTo*(c: uint): bool {.inline.} =
  result = c == pathCmdMoveTo

proc isLineTo*(c: uint): bool {.inline.} =
  result = c == pathCmdLineTo

proc isCurve*(c: uint): bool {.inline.} =
  result = c == pathCmdCurve3 or c == pathCmdCurve4

proc isCurve3*(c: uint): bool {.inline.} =
  result = c == pathCmdCurve3

proc isCurve4*(c: uint): bool {.inline.} =
  result = c == pathCmdCurve4

proc isEndPoly*(c: uint): bool {.inline.} =
  result = (c and pathCmdMask) == pathCmdEndPoly

proc isClose*(c: uint): bool {.inline.} =
  result = (c and (not (pathFlagsCw or pathFlagsCcw))) ==
           (pathCmdEndPoly or pathFlagsClose)

proc isNextPoly*(c: uint): bool {.inline.} =
  result = isStop(c) or isMoveTo(c) or isEndPoly(c)

proc isCw*(c: uint): bool {.inline.} =
  result = (c and pathFlagsCw) != 0

proc isCcw*(c: uint): bool {.inline.} =
  result = (c and pathFlagsCcw) != 0

proc isOriented*(c: uint): bool {.inline.} =
  result = (c and (pathFlagsCw or pathFlagsCcw)) != 0

proc isClosed*(c: uint): bool {.inline.} =
  result = (c and pathFlagsClose) != 0

proc getCloseFlag*(c: uint): uint {.inline.} =
  result = c and pathFlagsClose

proc clearOrientation*(c: uint): uint {.inline.} =
  result = c and (not (pathFlagsCw or pathFlagsCcw))

proc getOrientation*(c: uint): uint {.inline.} =
  result = c and (pathFlagsCw or pathFlagsCcw)

proc setOrientation*(c, o: uint): uint {.inline.} =
  result = clearOrientation(c) or o
