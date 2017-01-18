import agg_basics, math

type
  VpgenSegmentator* = object
    mApproximationScale: float64
    mX1, mY1, mDx, mDy: float64
    mDl, mDdl: float64
    mCmd: uint

proc initVpgenSegmentator*(): VpgenSegmentator =
  result.mApproximationScale = 1.0

template construct*(x: typedesc[VpgenSegmentator]): untyped = initVpgenSegmentator()

proc approximationScale*(self: var VpgenSegmentator, s: float64) =
  self.mApproximationScale = s

proc approximationScale*(self: var VpgenSegmentator): float64 =
  self.mApproximationScale

proc autoClose*(x: typedesc[VpgenSegmentator]): bool = false
proc autoUnclose*(x: typedesc[VpgenSegmentator]): bool = false

proc reset*(self: var VpgenSegmentator) =
  self.mCmd = pathCmdStop

proc moveTo*(self: var VpgenSegmentator, x, y: float64) =
  self.mX1 = x
  self.mY1 = y
  self.mDx = 0.0
  self.mDy = 0.0
  self.mDl = 2.0
  self.mDdl = 2.0
  self.mCmd = pathCmdMoveTo

proc lineTo*(self: var VpgenSegmentator, x, y: float64) =
  self.mX1 += self.mDx
  self.mY1 += self.mDy
  self.mDx  = x - self.mX1
  self.mDy  = y - self.mY1

  var len = sqrt(self.mDx * self.mDx + self.mDy * self.mDy) * self.mApproximationScale
  if len < 1e-30: len = 1e-30
  self.mDdl = 1.0 / len
  self.mDl  = if self.mCmd == pathCmdMoveTo: 0.0 else: self.mDdl
  if self.mCmd == pathCmdStop: self.mCmd = pathCmdLineTo

proc vertex*(self: var VpgenSegmentator, x, y: var float64): uint =
  if self.mCmd == pathCmdStop: return pathCmdStop

  let cmd = self.mCmd
  self.mCmd = pathCmdLineTo
  if self.mDl >= 1.0 - self.mDdl:
    self.mDl = 1.0
    self.mCmd = pathCmdStop
    x = self.mX1 + self.mDx
    y = self.mY1 + self.mDy
    return cmd

  x = self.mX1 + self.mDx * self.mDl
  y = self.mY1 + self.mDy * self.mDl
  self.mDl += self.mDdl
  result = cmd
