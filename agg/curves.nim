import basics, calc, math

const
  curveDistanceEpsilon*       = 1e-30
  curveCollinearityEpsilon    = 1e-30
  curveAngleToleranceEpsilon  = 0.01
  curveRecursionLimit         = 32

type
  CurveApproximationMethod* = enum
    curveInc
    curveDiv

  Curve3Inc* = object
    mNumSteps, mStep: int
    mScale, mStartX, mStartY: float64
    mEndX, mEndY, mFx, mFy: float64
    mDfx, mDfy, mDdfx, mDdfy: float64
    mSavedFx, mSavedFy, mSavedDfx, mSavedDfy: float64

proc init*(self: var Curve3Inc, x1, y1, x2, y2, x3, y3: float64)

proc initCurve3Inc*(): Curve3Inc =
  result.mNumSteps = 0
  result.mStep     = 0
  result.mScale    = 1.0

proc initCurve3Inc*(x1, y1, x2, y2, x3, y3: float64): Curve3Inc =
  result.mNumSteps = 0
  result.mStep     = 0
  result.mScale    = 1.0
  result.init(x1, y1, x2, y2, x3, y3)

proc reset*(self: var Curve3Inc) =
  self.mNumSteps = 0
  self.mStep = -1

proc approximationMethod*(self: var Curve3Inc, x: CurveApproximationMethod) = discard
proc approximationMethod*(self: Curve3Inc): CurveApproximationMethod = curveInc

proc approximationScale*(self: var Curve3Inc, s: float64) =
  self.mScale = s

proc approximationScale*(self: Curve3Inc): float64 =
  result = self.mScale

proc angleTolerance*(self: var Curve3Inc, x: float64) = discard
proc angleTolerance*(self: Curve3Inc): float64 = 0.0

proc cuspLimit*(self: var Curve3Inc, x: float64) = discard
proc cuspLimit*(self: Curve3Inc): float64 = 0.0

proc init(self: var Curve3Inc, x1, y1, x2, y2, x3, y3: float64) =
  self.mStartX = x1
  self.mStartY = y1
  self.mEndX   = x3
  self.mEndY   = y3

  var
    dx1 = x2 - x1
    dy1 = y2 - y1
    dx2 = x3 - x2
    dy2 = y3 - y2
    len = sqrt(dx1 * dx1 + dy1 * dy1) + sqrt(dx2 * dx2 + dy2 * dy2)

  self.mNumSteps = uround(len * 0.25 * self.mScale)
  if self.mNumSteps < 4:
    self.mNumSteps = 4

  var
    subdivideStep  = 1.0 / self.mNumSteps.float64
    subdivideStep2 = subdivideStep * subdivideStep
    tmpx = (x1 - x2 * 2.0 + x3) * subdivideStep2
    tmpy = (y1 - y2 * 2.0 + y3) * subdivideStep2

  self.mSavedFx = x1
  self.mFx = x1
  self.mSavedFy = y1
  self.mFy = y1

  self.mDfx = tmpx + (x2 - x1) * (2.0 * subdivideStep)
  self.mSavedDfx = self.mDfx
  self.mDfy = tmpy + (y2 - y1) * (2.0 * subdivideStep)
  self.mSavedDfy = self.mDfy

  self.mDdfx = tmpx * 2.0
  self.mDdfy = tmpy * 2.0

  self.mStep = self.mNumSteps

proc rewind*(self: var Curve3Inc, pathId: int) =
  if self.mNumSteps == 0:
    self.mStep = -1
    return

  self.mStep = self.mNumSteps
  self.mFx   = self.mSavedFx
  self.mFy   = self.mSavedFy
  self.mDfx  = self.mSavedDfx
  self.mDfy  = self.mSavedDfy

proc vertex*(self: var Curve3Inc, x, y: var float64): uint =
  if self.mStep < 0: return pathCmdStop
  if self.mStep == self.mNumSteps:
    x = self.mStartX
    y = self.mStartY
    dec self.mStep
    return pathCmdMoveTo

  if self.mStep == 0:
    x = self.mEndX
    y = self.mEndY
    dec self.mStep
    return pathCmdLineTo

  self.mFx  += self.mDfx
  self.mFy  += self.mDfy
  self.mDfx += self.mDdfx
  self.mDfy += self.mDdfy;
  x = self.mFx
  y = self.mFy
  dec self.mStep
  return pathCmdLineTo

type
  Curve3Div* = object
    mApproximationScale: float64
    mDistanceToleranceSquare: float64
    mAngleTolerance: float64
    mCount: int
    mPoints: seq[PointD]

proc init*(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64)

proc initCurve3Div*(): Curve3Div =
  result.mApproximationScale = 1.0
  result.mAngleTolerance = 0.0
  result.mCount = 0
  result.mPoints = @[]

proc initCurve3Div*(x1, y1, x2, y2, x3, y3: float64): Curve3Div =
  result.mApproximationScale = 1.0
  result.mAngleTolerance = 0.0
  result.mCount = 0
  result.mPoints = @[]
  result.init(x1, y1, x2, y2, x3, y3)

proc reset*(self: var Curve3Div) =
  self.mPoints.setLen(0)
  self.mCount = 0

proc approximationMethod*(self: var Curve3Div, x: CurveApproximationMethod) = discard
proc approximationMethod*(self: Curve3Div): CurveApproximationMethod = curveDiv

proc approximationScale*(self: var Curve3Div, s: float64) = self.mApproximationScale = s
proc approximationScale*(self: Curve3Div): float64 = self.mApproximationScale

proc angleTolerance*(self: var Curve3Div, a: float64) = self.mAngleTolerance = a
proc angleTolerance*(self: Curve3Div): float64 = self.mAngleTolerance

proc cuspLimit*(self: var Curve3Div, x: float64) = discard
proc cuspLimit*(self: Curve3Div): float64 = 0.0

proc rewind*(self: var Curve3Div, pathId: int) =
  self.mCount = 0

proc vertex*(self: var Curve3Div, x,y: var float64): uint =
  if self.mCount >= self.mPoints.len: return pathCmdStop
  let p = self.mPoints[self.mCount].addr
  x = p.x
  y = p.y
  inc self.mCount
  return if self.mCount == 1: pathCmdMoveTo else: pathCmdLineTo

proc bezier(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64)
proc recursiveBezier(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64, level: int)

proc init(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64) =
  self.mPoints.setLen(0)
  self.mDistanceToleranceSquare = 0.5 / self.mApproximationScale
  self.mDistanceToleranceSquare *= self.mDistanceToleranceSquare
  self.bezier(x1, y1, x2, y2, x3, y3)
  self.mCount = 0

proc recursiveBezier(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64, level: int) =
  if level > curveRecursionLimit:
    return

  # Calculate all the mid-points of the line segments
  #----------------------
  var
    x12   = (x1 + x2) / 2
    y12   = (y1 + y2) / 2
    x23   = (x2 + x3) / 2
    y23   = (y2 + y3) / 2
    x123  = (x12 + x23) / 2
    y123  = (y12 + y23) / 2

    dx = x3-x1
    dy = y3-y1
    d = abs(((x2 - x3) * dy - (y2 - y3) * dx))
    da: float64

  if d > curveCollinearityEpsilon:
    # Regular of
    if d * d <= self.mDistanceToleranceSquare * (dx*dx + dy*dy):
      # If the curvature doesn't exceed the distance_tolerance value
      # we tend to finish subdivisions.
      if self.mAngleTolerance < curveAngleToleranceEpsilon:
        self.mPoints.add(PointD(x: x123, y: y123))
        return


      # Angle & Cusp Condition
      da = abs(arctan2(y3 - y2, x3 - x2) - arctan2(y2 - y1, x2 - x1))
      if da >= pi: da = 2*pi - da

      if da < self.mAngleTolerance:
        # Finally we can stop the recursion
        self.mPoints.add(PointD(x: x123, y: y123))
        return
  else:
    # Collinear of
    da = dx*dx + dy*dy
    if da == 0:
      d = calcSqdistance(x1, y1, x2, y2)
    else:
      d = ((x2 - x1)*dx + (y2 - y1)*dy) / da
      if d > 0 and d < 1:
        # Simple collinear of, 1---2---3
        # We can leave just two endpoints
        return

      if d <= 0:   d = calcSqdistance(x2, y2, x1, y1)
      elif d >= 1: d = calcSqdistance(x2, y2, x3, y3)
      else:        d = calcSqdistance(x2, y2, x1 + d*dx, y1 + d*dy)

    if d < self.mDistanceToleranceSquare:
      self.mPoints.add(PointD(x: x2, y: y2))
      return

  # Continue subdivision
  #----------------------
  self.recursiveBezier(x1, y1, x12, y12, x123, y123, level + 1)
  self.recursiveBezier(x123, y123, x23, y23, x3, y3, level + 1)

proc bezier(self: var Curve3Div, x1, y1, x2, y2, x3, y3: float64) =
  self.mPoints.add(PointD(x: x1, y: y1))
  self.recursiveBezier(x1, y1, x2, y2, x3, y3, 0)
  self.mPoints.add(PointD(x: x3, y: y3))

type
  Curve4Points* = object
    cp: array[8, float64]

proc initCurve4Points*(): Curve4Points = discard
proc initCurve4Points*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Points =
  result.cp[0] = x1; result.cp[1] = y1; result.cp[2] = x2; result.cp[3] = y2
  result.cp[4] = x3; result.cp[5] = y3; result.cp[6] = x4; result.cp[7] = y4

proc init*(self: var Curve4Points, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  self.cp[0] = x1; self.cp[1] = y1; self.cp[2] = x2; self.cp[3] = y2
  self.cp[4] = x3; self.cp[5] = y3; self.cp[6] = x4; self.cp[7] = y4

proc `[]`*(self: Curve4Points, i: int): float64 = self.cp[i]

type
  Curve4Inc* = object
    mNumSteps, mStep: int
    mScale, mStartX, mStartY: float64
    mEndX, mEndY, mFx, mFy: float64
    mDfx, mDfy, mDdfx, mDdfy: float64
    mDddfx, mDddfy, mSavedFx, mSavedFy: float64
    mSavedDfx, mSavedDfy, mSavedDdfx, mSavedDdfy: float64

proc init*(self: var Curve4Inc, x1, y1, x2, y2, x3, y3, x4, y4: float64)

proc initCurve4Inc*(): Curve4Inc =
  result.mNumSteps = 0
  result.mStep     = 0
  result.mScale    = 1.0

proc initCurve4Inc*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Inc =
  result.mNumSteps = 0
  result.mStep     = 0
  result.mScale    = 1.0
  result.init(x1, y1, x2, y2, x3, y3, x4, y4)

proc initCurve4Inc*(cp: Curve4Points): Curve4Inc =
  result.mNumSteps = 0
  result.mStep     = 0
  result.mScale    = 1.0
  result.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc reset*(self: var Curve4Inc) =
  self.mNumSteps = 0
  self.mStep = -1

proc init*(self: var Curve4Inc, cp: Curve4Points) =
  self.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc approximationMethod*(self: var Curve4Inc, x: CurveApproximationMethod) = discard
proc approximationMethod*(self: var Curve4Inc, ): CurveApproximationMethod = curveInc

proc approximationScale*(self: var Curve4Inc, s: float64) = self.mScale = s
proc approximationScale*(self: Curve4Inc): float64 = self.mScale

proc angleTolerance*(self: var Curve4Inc, x: float64) = discard
proc angleTolerance*(self: Curve4Inc): float64 = 0.0

proc cuspLimit*(self: var Curve4Inc, x: float64) = discard
proc cuspLimit*(self: Curve4Inc): float64 = 0.0

proc init(self: var Curve4Inc, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  self.mStartX = x1
  self.mStartY = y1
  self.mEndX   = x4
  self.mEndY   = y4

  var
    dx1 = x2 - x1
    dy1 = y2 - y1
    dx2 = x3 - x2
    dy2 = y3 - y2
    dx3 = x4 - x3
    dy3 = y4 - y3
    len = (sqrt(dx1 * dx1 + dy1 * dy1) +
          sqrt(dx2 * dx2 + dy2 * dy2) +
          sqrt(dx3 * dx3 + dy3 * dy3)) * 0.25 * self.mScale

  self.mNumSteps = uround(len)

  if self.mNumSteps < 4:
    self.mNumSteps = 4

  var
    subdivideStep  = 1.0 / self.mNumSteps.float64
    subdivideStep2 = subdivideStep * subdivideStep
    subdivideStep3 = subdivideStep * subdivideStep * subdivideStep

    pre1 = 3.0 * subdivideStep
    pre2 = 3.0 * subdivideStep2
    pre4 = 6.0 * subdivideStep2
    pre5 = 6.0 * subdivideStep3

    tmp1x = x1 - x2 * 2.0 + x3
    tmp1y = y1 - y2 * 2.0 + y3

    tmp2x = (x2 - x3) * 3.0 - x1 + x4
    tmp2y = (y2 - y3) * 3.0 - y1 + y4

  self.mSavedFx = x1
  self.mFx = x1
  self.mSavedFy = y1
  self.mFy = y1

  self.mDfx = (x2 - x1) * pre1 + tmp1x * pre2 + tmp2x * subdivideStep3
  self.mSavedDfx = self.mDfx
  self.mDfy = (y2 - y1) * pre1 + tmp1y * pre2 + tmp2y * subdivideStep3
  self.mSavedDfy = self.mDfy

  self.mDdfx = tmp1x * pre4 + tmp2x * pre5
  self.mSavedDdfx = self.mDdfx
  self.mDdfy = tmp1y * pre4 + tmp2y * pre5
  self.mSavedDdfy = self.mDdfy

  self.mDddfx = tmp2x * pre5
  self.mDddfy = tmp2y * pre5

  self.mStep = self.mNumSteps

proc rewind*(self: var Curve4Inc, pathId: int) =
  if self.mNumSteps == 0:
    self.mStep = -1
    return

  self.mStep = self.mNumSteps
  self.mFx   = self.mSavedFx
  self.mFy   = self.mSavedFy
  self.mDfx  = self.mSavedDfx
  self.mDfy  = self.mSavedDfy
  self.mDdfx = self.mSavedDdfx
  self.mDdfy = self.mSavedDdfy

proc vertex*(self: var Curve4Inc, x, y: var float64): uint =
  if self.mStep < 0: return pathCmdStop
  if self.mStep == self.mNumSteps:
    x = self.mStartX
    y = self.mStartY
    dec self.mStep
    return pathCmdMoveTo

  if self.mStep == 0:
    x = self.mEndX
    y = self.mEndY
    dec self.mStep
    return pathCmdLineTo

  self.mFx   += self.mDfx
  self.mFy   += self.mDfy
  self.mDfx  += self.mDdfx
  self.mDfy  += self.mDdfy
  self.mDdfx += self.mDddfx
  self.mDdfy += self.mDddfy

  x = self.mFx
  y = self.mFy
  dec self.mStep
  return pathCmdLineTo

proc catromToBezier*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Points {.inline.} =
  # Trans. matrix Catmull-Rom to Bezier
  #
  #  0     1     0     0
  #  -1/6  1     1/6   0
  #  0     1/6   1     -1/6
  #  0     0     1     0
  #
  result = initCurve4Points(x2, y2,
    (-x1 + 6*x2 + x3) / 6,
    (-y1 + 6*y2 + y3) / 6,
    ( x2 + 6*x3 - x4) / 6,
    ( y2 + 6*y3 - y4) / 6, x3, y3)

proc catromToBezier*(cp: Curve4Points): Curve4Points {.inline.}=
  result = catromToBezier(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc ubsplineToBezier*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Points {.inline.} =
  # Trans. matrix Uniform BSpline to Bezier
  #
  #  1/6   4/6   1/6   0
  #  0     4/6   2/6   0
  #  0     2/6   4/6   0
  #  0     1/6   4/6   1/6
  #
  result = initCurve4Points(
    (x1 + 4*x2 + x3) / 6,
    (y1 + 4*y2 + y3) / 6,
    (4*x2 + 2*x3) / 6,
    (4*y2 + 2*y3) / 6,
    (2*x2 + 4*x3) / 6,
    (2*y2 + 4*y3) / 6,
    (x2 + 4*x3 + x4) / 6,
    (y2 + 4*y3 + y4) / 6)

proc ubsplineToBezier*(cp: Curve4Points): Curve4Points {.inline.} =
  result = ubsplineToBezier(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc hermiteToBezier*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Points {.inline.} =
  # Trans. matrix Hermite to Bezier
  #
  #  1     0     0     0
  #  1     0     1/3   0
  #  0     1     0     -1/3
  #  0     1     0     0
  #
  result = initCurve4Points(x1, y1,
    (3*x1 + x3) / 3,
    (3*y1 + y3) / 3,
    (3*x2 - x4) / 3,
    (3*y2 - y4) / 3, x2, y2)

proc hermiteToBezier*(cp: Curve4Points): Curve4Points {.inline.} =
  result = hermiteToBezier(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])


type
  Curve4Div* = object
    mApproximationScale: float64
    mDistanceToleranceSquare: float64
    mAngleTolerance: float64
    mCuspLimit: float64
    mCount: int
    mPoints: seq[PointD]

proc init*(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64)

proc initCurve4Div*(): Curve4Div =
  result.mApproximationScale = 1.0
  result.mAngleTolerance = 0.0
  result.mCuspLimit = 0.0
  result.mCount = 0
  result.mPoints = @[]

proc initCurve4Div*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4Div =
  result.mApproximationScale = 1.0
  result.mAngleTolerance = 0.0
  result.mCuspLimit = 0.0
  result.mCount = 0
  result.mPoints = @[]
  result.init(x1, y1, x2, y2, x3, y3, x4, y4)

proc initCurve4Div*(cp: Curve4Points): Curve4Div =
  result.mApproximationScale = 1.0
  result.mAngleTolerance = 0.0
  result.mCount = 0
  result.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc reset*(self: var Curve4Div) =
  self.mPoints.setLen(0)
  self.mCount = 0

proc init*(self: var Curve4Div, cp: Curve4Points) =
  self.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc approximationMethod*(self: var Curve4Div, x: CurveApproximationMethod) = discard
proc approximationMethod*(self: Curve4Div): CurveApproximationMethod = curveDiv

proc approximationScale*(self: var Curve4Div, s: float64) = self.mApproximationScale = s
proc approximationScale*(self: Curve4Div): float64 = self.mApproximationScale

proc angleTolerance*(self: var Curve4Div, a: float64) = self.mAngleTolerance = a
proc angleTolerance*(self: Curve4Div): float64 = self.mAngleTolerance

proc cuspLimit*(self: var Curve4Div, v: float64) =
  self.mCuspLimit = if v == 0.0: 0.0 else: pi - v

proc cuspLimit*(self: var Curve4Div): float64 =
  result = if self.mCuspLimit == 0.0: 0.0 else: pi - self.mCuspLimit

proc rewind*(self: var Curve4Div, pathId: int) =
  self.mCount = 0

proc vertex*(self: var Curve4Div, x,y: var float64): uint =
  if self.mCount >= self.mPoints.len: return pathCmdStop
  let p = self.mPoints[self.mCount].addr
  x = p.x
  y = p.y
  inc self.mCount
  result = if self.mCount == 1: pathCmdMoveTo else: pathCmdLineTo

proc bezier(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64)
proc recursiveBezier(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64, level: int)

proc init(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  self.mPoints.setLen(0)
  self.mDistanceToleranceSquare = 0.5 / self.mApproximationScale
  self.mDistanceToleranceSquare *= self.mDistanceToleranceSquare
  self.bezier(x1, y1, x2, y2, x3, y3, x4, y4)
  self.mCount = 0

proc recursiveBezier(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64, level: int) =
  if level > curveRecursionLimit:
    return

  # Calculate all the mid-points of the line segments
  var
    x12   = (x1 + x2) / 2
    y12   = (y1 + y2) / 2
    x23   = (x2 + x3) / 2
    y23   = (y2 + y3) / 2
    x34   = (x3 + x4) / 2
    y34   = (y3 + y4) / 2
    x123  = (x12 + x23) / 2
    y123  = (y12 + y23) / 2
    x234  = (x23 + x34) / 2
    y234  = (y23 + y34) / 2
    x1234 = (x123 + x234) / 2
    y1234 = (y123 + y234) / 2

    # Try to approximate the full cubic curve by a single straight line
    dx = x4-x1
    dy = y4-y1

    d2 = abs(((x2 - x4) * dy - (y2 - y4) * dx))
    d3 = abs(((x3 - x4) * dy - (y3 - y4) * dx))
    da1, da2, k: float64

  let opt = (int(d2 > curveCollinearityEpsilon) shl 1) + int(d3 > curveCollinearityEpsilon)
  case opt
  of 0:
    # All collinear OR p1==p4
    k = dx*dx + dy*dy
    if k == 0:
      d2 = calcSqdistance(x1, y1, x2, y2)
      d3 = calcSqdistance(x4, y4, x3, y3)
    else:
      k   = 1 / k
      da1 = x2 - x1
      da2 = y2 - y1
      d2  = k * (da1*dx + da2*dy)
      da1 = x3 - x1
      da2 = y3 - y1
      d3  = k * (da1*dx + da2*dy)
      if d2 > 0 and d2 < 1 and d3 > 0 and d3 < 1:
        # Simple collinear of, 1---2---3---4
        # We can leave just two endpoints
        return

      if d2 <= 0:   d2 = calcSqdistance(x2, y2, x1, y1)
      elif d2 >= 1: d2 = calcSqdistance(x2, y2, x4, y4)
      else:         d2 = calcSqdistance(x2, y2, x1 + d2*dx, y1 + d2*dy)

      if d3 <= 0:   d3 = calcSqdistance(x3, y3, x1, y1)
      elif d3 >= 1: d3 = calcSqdistance(x3, y3, x4, y4)
      else:         d3 = calcSqdistance(x3, y3, x1 + d3*dx, y1 + d3*dy)

    if d2 > d3:
      if d2 < self.mDistanceToleranceSquare:
        self.mPoints.add(PointD(x: x2, y: y2))
        return
    else:
      if d3 < self.mDistanceToleranceSquare:
        self.mPoints.add(PointD(x: x3, y: y3))
        return
  of 1:
    # p1,p2,p4 are collinear, p3 is significant
    #----------------------
    if d3 * d3 <= self.mDistanceToleranceSquare * (dx*dx + dy*dy):
      if self.mAngleTolerance < curveAngleToleranceEpsilon:
        self.mPoints.add(PointD(x: x23, y: y23))
        return

      # Angle Condition
      #----------------------
      da1 = abs(arctan2(y4 - y3, x4 - x3) - arctan2(y3 - y2, x3 - x2))
      if da1 >= pi: da1 = 2*pi - da1

      if da1 < self.mAngleTolerance:
        self.mPoints.add(PointD(x: x2, y: y2))
        self.mPoints.add(PointD(x: x3, y: y3))
        return

      if self.mCuspLimit != 0.0:
        if da1 > self.mCuspLimit:
          self.mPoints.add(PointD(x: x3, y: y3))
          return
  of 2:
    # p1,p3,p4 are collinear, p2 is significant
    #----------------------
    if d2 * d2 <= self.mDistanceToleranceSquare * (dx*dx + dy*dy):
      if self.mAngleTolerance < curveAngleToleranceEpsilon:
        self.mPoints.add(PointD(x: x23, y: y23))
        return

      # Angle Condition
      #----------------------
      da1 = abs(arctan2(y3 - y2, x3 - x2) - arctan2(y2 - y1, x2 - x1))
      if da1 >= pi: da1 = 2*pi - da1

      if da1 < self.mAngleTolerance:
        self.mPoints.add(PointD(x: x2, y: y2))
        self.mPoints.add(PointD(x: x3, y: y3))
        return

      if self.mCuspLimit != 0.0:
        if da1 > self.mCuspLimit:
          self.mPoints.add(PointD(x: x2, y: y2))
          return
  of 3:
    # Regular of
    #-----------------
    if (d2 + d3)*(d2 + d3) <= self.mDistanceToleranceSquare * (dx*dx + dy*dy):
      # If the curvature doesn't exceed the distance_tolerance value
      # we tend to finish subdivisions.
      #----------------------
      if self.mAngleTolerance < curveAngleToleranceEpsilon:
        self.mPoints.add(PointD(x: x23, y: y23))
        return


      # Angle & Cusp Condition
      #----------------------
      k   = arctan2(y3 - y2, x3 - x2)
      da1 = abs(k - arctan2(y2 - y1, x2 - x1))
      da2 = abs(arctan2(y4 - y3, x4 - x3) - k)
      if da1 >= pi: da1 = 2*pi - da1
      if da2 >= pi: da2 = 2*pi - da2

      if da1 + da2 < self.mAngleTolerance:
        # Finally we can stop the recursion
        #----------------------
        self.mPoints.add(PointD(x: x23, y: y23))
        return

      if self.mCuspLimit != 0.0:
        if da1 > self.mCuspLimit:
          self.mPoints.add(PointD(x: x2, y: y2))
          return

        if da2 > self.mCuspLimit:
          self.mPoints.add(PointD(x: x3, y: y3))
          return
  else:
    discard

  # Continue subdivision
  self.recursiveBezier(x1, y1, x12, y12, x123, y123, x1234, y1234, level + 1)
  self.recursiveBezier(x1234, y1234, x234, y234, x34, y34, x4, y4, level + 1)

#------------------------------------------------------------------------
proc bezier(self: var Curve4Div, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  self.mPoints.add(PointD(x: x1, y: y1))
  self.recursiveBezier(x1, y1, x2, y2, x3, y3, x4, y4, 0)
  self.mPoints.add(PointD(x: x4, y: y4))

type
  Curve3* = object
    mCurveInc: Curve3Inc
    mCurveDiv: Curve3Div
    mApproximationMethod: CurveApproximationMethod

proc init*(self: var Curve3, x1, y1, x2, y2, x3, y3: float64)

proc initCurve3*(): Curve3 =
  result.mApproximationMethod = curveDiv
  result.mCurveInc = initCurve3Inc()
  result.mCurveDiv = initCurve3Div()

proc initCurve3*(x1, y1, x2, y2, x3, y3: float64): Curve3 =
  result.mApproximationMethod = curveDiv
  result.mCurveInc = initCurve3Inc()
  result.mCurveDiv = initCurve3Div()
  result.init(x1, y1, x2, y2, x3, y3)

template construct*(x: typedesc[Curve3]): untyped = initCurve3()

proc reset*(self: var Curve3) =
  self.mCurveInc.reset()
  self.mCurveDiv.reset()

proc init(self: var Curve3, x1, y1, x2, y2, x3, y3: float64) =
  if self.mApproximationMethod == curveInc:
    self.mCurveInc.init(x1, y1, x2, y2, x3, y3)
  else:
    self.mCurveDiv.init(x1, y1, x2, y2, x3, y3)

proc approximationMethod*(self: var Curve3, v: CurveApproximationMethod) =
  self.mApproximationMethod = v

proc approximationMethod*(self: Curve3): CurveApproximationMethod =
  self.mApproximationMethod

proc approximationScale*(self: var Curve3, s: float64) =
  self.mCurveInc.approximationScale(s)
  self.mCurveDiv.approximationScale(s)

proc approximationScale*(self: Curve3): float64 =
  self.mCurveInc.approximationScale()

proc angleTolerance*(self: var Curve3, a: float64) =
  self.mCurveDiv.angleTolerance(a)

proc angleTolerance*(self: Curve3): float64 =
  self.mCurveDiv.angleTolerance()

proc cuspLimit*(self: var Curve3,v: float64) =
  self.mCurveDiv.cuspLimit(v)

proc cuspLimit*(self: Curve3): float64 =
  self.mCurveDiv.cuspLimit()

proc rewind*(self: var Curve3, pathId: int) =
  if self.mApproximationMethod == curveInc:
    self.mCurveInc.rewind(pathId)
  else:
    self.mCurveDiv.rewind(pathId)

proc vertex*(self: var Curve3, x, y: var float64): uint =
  if self.mApproximationMethod == curveInc:
    return self.mCurveInc.vertex(x, y)
  return self.mCurveDiv.vertex(x, y)

type
  Curve4* = object
    mCurveInc: Curve4Inc
    mCurveDiv: Curve4Div
    mApproximationMethod: CurveApproximationMethod

proc init*(self: var Curve4, x1, y1, x2, y2, x3, y3, x4, y4: float64)

proc initCurve4*(): Curve4 =
  result.mApproximationMethod = curveDiv
  result.mCurveInc = initCurve4Inc()
  result.mCurveDiv = initCurve4Div()

proc initCurve4*(x1, y1, x2, y2, x3, y3, x4, y4: float64): Curve4 =
  result.mApproximationMethod = curveDiv
  result.mCurveInc = initCurve4Inc()
  result.mCurveDiv = initCurve4Div()
  result.init(x1, y1, x2, y2, x3, y3, x4, y4)

proc initCurve4*(cp: Curve4Points): Curve4 =
  result.mApproximationMethod = curveDiv
  result.mCurveInc = initCurve4Inc()
  result.mCurveDiv = initCurve4Div()
  result.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

template construct*(x: typedesc[Curve4]): untyped = initCurve4()

proc reset*(self: var Curve4) =
  self.mCurveInc.reset()
  self.mCurveDiv.reset()

proc init(self: var Curve4, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  if self.mApproximationMethod == curveInc:
    self.mCurveInc.init(x1, y1, x2, y2, x3, y3, x4, y4)
  else:
    self.mCurveDiv.init(x1, y1, x2, y2, x3, y3, x4, y4)

proc init*(self: var Curve4, cp: Curve4Points) =
  self.init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7])

proc approximationMethod*(self: var Curve4, v: CurveApproximationMethod) =
  self.mApproximationMethod = v

proc approximationMethod*(self: Curve4): CurveApproximationMethod =
  self.mApproximationMethod

proc approximationScale*(self: var Curve4, s: float64) =
  self.mCurveInc.approximationScale(s)
  self.mCurveDiv.approximationScale(s)

proc approximationScale*(self: Curve4): float64 =
  self.mCurveInc.approximationScale()

proc angleTolerance*(self: var Curve4, v: float64) =
  self.mCurveDiv.angleTolerance(v)

proc angleTolerance*(self: var Curve4): float64 =
  self.mCurveDiv.angleTolerance()

proc cuspLimit*(self: var Curve4, v: float64) =
  self.mCurveDiv.cuspLimit(v)

proc cuspLimit*(self: var Curve4): float64 =
  self.mCurveDiv.cuspLimit()

proc rewind*(self: var Curve4, pathId: int) =
  if self.mApproximationMethod == curveInc:
    self.mCurveInc.rewind(pathId)
  else:
    self.mCurveDiv.rewind(pathId)

proc vertex*(self: var Curve4, x, y: var float64): uint =
  if self.mApproximationMethod == curveInc:
    return self.mCurveInc.vertex(x, y)
  return self.mCurveDiv.vertex(x, y)
