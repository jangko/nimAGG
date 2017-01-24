import agg_basics, agg_clip_liang_barsky

type
  VpgenClipPolygon* = object
    mClipBox: RectD
    mX1, mY1: float64
    mClipFlags: uint
    mX, mY: array[4, float64]
    mNumVertices: int
    mVertex: int
    mCmd: uint

proc initVpgenClipPolygon*(): VpgenClipPolygon =
  result.mClipBox = initRectD(0, 0, 1, 1)
  result.mX1 = 0
  result.mY1 = 0
  result.mClipFlags = 0
  result.mNumVertices = 0
  result.mVertex = 0
  result.mCmd = pathCmdMoveTo

template construct*(x: typedesc[VpgenClipPolygon]): untyped = initVpgenClipPolygon()

#------------------------------------------------------------------------
# Determine the clipping code of the vertex according to the
# Cyrus-Beck line clipping algorithm
#
#        |        |
#  0110  |  0010  | 0011
#        |        |
# -------+--------+-------- clip_box.y2
#        |        |
#  0100  |  0000  | 0001
#        |        |
# -------+--------+-------- clip_box.y1
#        |        |
#  1100  |  1000  | 1001
#        |        |
#  clip_box.x1  clip_box.x2
#
#
proc clippingFlags(self: var VpgenClipPolygon, x, y: float64): uint =
  if x < self.mClipBox.x1:
    if y > self.mClipBox.y2: return 6
    if y < self.mClipBox.y1: return 12
    return 4

  if x > self.mClipBox.x2:
    if y > self.mClipBox.y2: return 3
    if y < self.mClipBox.y1: return 9
    return 1

  if y > self.mClipBox.y2: return 2
  if y < self.mClipBox.y1: return 8
  result = 0

proc clipBox*(self: var VpgenClipPolygon, x1, y1, x2, y2: float64) =
  self.mClipBox.x1 = x1
  self.mClipBox.y1 = y1
  self.mClipBox.x2 = x2
  self.mClipBox.y2 = y2
  self.mClipBox.normalize()

proc x1*(self: var VpgenClipPolygon): float64 = self.mClipBox.x1
proc y1*(self: var VpgenClipPolygon): float64 = self.mClipBox.y1
proc x2*(self: var VpgenClipPolygon): float64 = self.mClipBox.x2
proc y2*(self: var VpgenClipPolygon): float64 = self.mClipBox.y2

proc autoClose*(x: typedesc[VpgenClipPolygon]): bool = true
proc autoUnclose*(x: typedesc[VpgenClipPolygon]): bool = false

proc reset*(self: var VpgenClipPolygon) =
  self.mVertex = 0
  self.mNumVertices = 0

proc moveTo*(self: var VpgenClipPolygon, x, y: float64) =
  self.mVertex = 0
  self.mNumVertices = 0
  self.mClipFlags = self.clippingFlags(x, y)
  if self.mClipFlags == 0:
    self.mX[0] = x
    self.mY[0] = y
    self.mNumVertices = 1

  self.mX1  = x
  self.mY1  = y
  self.mCmd = pathCmdMoveTo

proc lineTo*(self: var VpgenClipPolygon, x, y: float64) =
  self.mVertex = 0
  self.mNumVertices = 0
  let flags = self.clippingFlags(x, y)

  if self.mClipFlags == flags:
    if flags == 0:
      self.mX[0] = x
      self.mY[0] = y
      self.mNumVertices = 1
  else:
    self.mNumVertices = clipLiangBarsky(self.mX1, self.mY1,
      x, y, self.mClipBox, self.mX[0].addr, self.mY[0].addr)

  self.mClipFlags = flags
  self.mX1 = x
  self.mY1 = y

proc vertex*(self: var VpgenClipPolygon, x, y: var float64): uint =
  if self.mVertex < self.mNumVertices:
    x = self.mX[self.mVertex]
    y = self.mY[self.mVertex]
    inc self.mVertex
    var cmd = self.mCmd
    self.mCmd = pathCmdLineTo
    return cmd

  result = pathCmdStop

