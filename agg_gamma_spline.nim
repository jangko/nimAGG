import agg_basics, agg_bspline

type
  GammaSpline* = object
    mGamma: array[256, uint8]
    mX, mY: array[4, float64]
    mSpline: BSpline
    mX1, mY1, mX2, mY2: float64
    mCurX: float64

proc values*(self: var GammaSpline, kx1, ky1, kx2, ky2: float64)

proc initGammaSpline*(): GammaSpline =
  result.mX1 = 0.0
  result.mY1 = 0.0
  result.mX2 = 10.0
  result.mY2 = 10.0
  result.mCurX = 0.0
  result.values(1.0, 1.0, 1.0, 1.0)

proc y*(self: var GammaSpline, x: float64): float64 =
  var x = x
  if x < 0.0: x = 0.0
  if x > 1.0: x = 1.0
  var val = self.mSpline.get(x)
  if val < 0.0: val = 0.0
  if val > 1.0: val = 1.0
  val

proc values(self: var GammaSpline, kx1, ky1, kx2, ky2: float64) =
  var
    kx1 = kx1
    ky1 = ky1
    kx2 = kx2
    ky2 = ky2

  if kx1 < 0.001: kx1 = 0.001
  if kx1 > 1.999: kx1 = 1.999
  if ky1 < 0.001: ky1 = 0.001
  if ky1 > 1.999: ky1 = 1.999
  if kx2 < 0.001: kx2 = 0.001
  if kx2 > 1.999: kx2 = 1.999
  if ky2 < 0.001: ky2 = 0.001
  if ky2 > 1.999: ky2 = 1.999

  self.mX[0] = 0.0
  self.mY[0] = 0.0
  self.mX[1] = kx1 * 0.25
  self.mY[1] = ky1 * 0.25
  self.mX[2] = 1.0 - kx2 * 0.25
  self.mY[2] = 1.0 - ky2 * 0.25
  self.mX[3] = 1.0
  self.mY[3] = 1.0

  self.mSpline.init(4, self.mX[0].addr, self.mY[0].addr)
  for i in 0.. <256:
    self.mGamma[i] = uint8(self.y(float64(i) / 255.0) * 255.0)

proc values*(self: var GammaSpline, kx1, ky1, kx2, ky2: var float64) =
  kx1 = self.mX[1] * 4.0
  ky1 = self.mY[1] * 4.0
  kx2 = (1.0 - self.mX[2]) * 4.0
  ky2 = (1.0 - self.mY[2]) * 4.0

proc box*(self: var GammaSpline, x1, y1, x2, y2: float64) =
  self.mX1 = x1
  self.mY1 = y1
  self.mX2 = x2
  self.mY2 = y2

proc rewind*(self: var GammaSpline, idx: int) =
  self.mCurX = 0.0

proc vertex*(self: var GammaSpline, vx, vy: var float64): uint =
  if self.mCurX == 0.0:
    vx = self.mX1
    vy = self.mY1
    self.mCurX += 1.0 / (self.mX2 - self.mX1)
    return pathCmdMoveTo

  if self.mCurX > 1.0:
    return pathCmdStop

  vx = self.mX1 + self.mCurX * (self.mX2 - self.mX1)
  vy = self.mY1 + self.y(self.mCurX) * (self.mY2 - self.mY1)

  self.mCurX += 1.0 / (self.mX2 - self.mX1)
  result = pathCmdLineTo
