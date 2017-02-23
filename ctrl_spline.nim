import agg_basics, agg_ellipse, agg_bspline, agg_conv_stroke, agg_math
import agg_path_storage, agg_trans_affine, agg_color_rgba, ctrl_base

type
  SplineCtrlImpl* = ref object of CtrlBase
    mNumPnt: int
    mXp, mYp: array[32, float64]
    mSpline: BSpline
    mSplineValues: array[256, float64]
    mSplineValues8: array[256, uint8]
    mBorderWidth: float64
    mBorderExtra: float64
    mCurveWidth: float64
    mPointSize: float64
    mXs1, mYs1, mXs2, mYs2: float64
    mCurvePnt: PathStorage
    mCurvePoly: ConvStroke[PathStorage, NullMarkers]
    mEllipse: Ellipse
    mIdx: int
    mVertex: int
    mVx, mVy: array[32, float64]
    mActivePnt, mMovePnt: int
    mPdx, mPdy: float64

proc calcSplineBox*(self: SplineCtrlImpl)
proc updateSpline*(self: SplineCtrlImpl)

proc init(self: SplineCtrlImpl, x1, y1, x2, y2: float64, numPnt: int, flipY = false) =
  CtrlBase(self).init(x1, y1, x2, y2, flipY)
  self.mNumPnt = numPnt
  self.mBorderWidth = 1.0
  self.mBorderExtra = 0.0
  self.mCurveWidth = 1.0
  self.mPointSize = 3.0
  self.mCurvePnt = initPathStorage()
  self.mCurvePoly = initConvStroke(self.mCurvePnt)
  self.mIdx = 0
  self.mVertex = 0
  self.mActivePnt = -1
  self.mMovePnt = -1
  self.mPdx = 0.0
  self.mPdy = 0.0
  if self.mNumPnt < 4:  self.mNumPnt = 4
  if self.mNumPnt > 32: self.mNumPnt = 32

  for i in 0.. <self.mNumPnt:
    self.mXp[i] = float64(i) / float64(self.mNumPnt - 1)
    self.mYp[i] = 0.5

  self.calcSplineBox()
  self.updateSpline()

proc newSplineCtrlImpl*(x1, y1, x2, y2: float64, numPnt: int, flipY = false): SplineCtrlImpl =
  new(result)
  result.init(x1, y1, x2, y2, numPnt, flipY)

proc borderWidth*(self: SplineCtrlImpl, t: float64, extra = 0.0) =
  self.mBorderWidth = t
  self.mBorderExtra = extra
  self.calcSplineBox()

proc calcSplineBox(self: SplineCtrlImpl) =
  self.mXs1 = self.m.x1 + self.mBorderWidth
  self.mYs1 = self.m.y1 + self.mBorderWidth
  self.mXs2 = self.m.x2 - self.mBorderWidth
  self.mYs2 = self.m.y2 - self.mBorderWidth

proc updateSpline(self: SplineCtrlImpl) =
  self.mSpline.init(self.mNumPnt, self.mXp[0].addr, self.mYp[0].addr)
  for i in 0.. <256:
    self.mSplineValues[i] = self.mSpline.get(float64(i) / 255.0)
    if self.mSplineValues[i] < 0.0: self.mSplineValues[i] = 0.0
    if self.mSplineValues[i] > 1.0: self.mSplineValues[i] = 1.0
    self.mSplineValues8[i] = uint8(self.mSplineValues[i] * 255.0)

proc calcCurve*(self: SplineCtrlImpl) =
  self.mCurvePnt.removeAll()
  self.mCurvePnt.moveTo(self.mXs1, self.mYs1 + (self.mYs2 - self.mYs1) * self.mSplineValues[0])
  for i in 1.. <256:
    self.mCurvePnt.lineTo(self.mXs1 + (self.mXs2 - self.mXs1) * float64(i) / 255.0,
                          self.mYs1 + (self.mYs2 - self.mYs1) * self.mSplineValues[i])

proc calcXp*(self: SplineCtrlImpl, idx: int): float64 =
  result = self.mXs1 + (self.mXs2 - self.mXs1) * self.mXp[idx]

proc calcYp*(self: SplineCtrlImpl, idx: int): float64 =
  result = self.mYs1 + (self.mYs2 - self.mYs1) * self.mYp[idx]

proc setXp*(self: SplineCtrlImpl, idx: int, val: float64) =
  var
    val = val
  if val < 0.0: val = 0.0
  if val > 1.0: val = 1.0

  if idx == 0:
    val = 0.0
  elif idx == self.mNumPnt - 1:
    val = 1.0
  else:
    if val < self.mXp[idx - 1] + 0.001: val = self.mXp[idx - 1] + 0.001
    if val > self.mXp[idx + 1] - 0.001: val = self.mXp[idx + 1] - 0.001
  self.mXp[idx] = val

proc setYp*(self: SplineCtrlImpl, idx: int, val: float64) =
  var
    val = val
  if val < 0.0: val = 0.0
  if val > 1.0: val = 1.0
  self.mYp[idx] = val

proc point*(self: SplineCtrlImpl, idx: int, x: float64, y: float64) =
  if idx < self.mNumPnt:
    self.setXp(idx, x)
    self.setYp(idx, y)

proc value*(self: SplineCtrlImpl, idx: int, y: float64) =
  if idx < self.mNumPnt:
    self.setYp(idx, y)

proc value*(self: SplineCtrlImpl, x: float64): float64 =
  var x = self.mSpline.get(x)
  if x < 0.0: x = 0.0
  if x > 1.0: x = 1.0
  result = x

# Set other parameters
proc curveWidth*(self: SplineCtrlImpl, t: float64) =
  self.mCurveWidth = t

proc pointSize*(self: SplineCtrlImpl, s: float64) =
  self.mPointSize = s

method inRect*(self: SplineCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and x <= self.m.x2 and y >= self.m.y1 and y <= self.m.y2

method onMouseButtonDown*(self: SplineCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)
  for i in 0.. <self.mNumPnt:
    var
      xp = self.calcXp(i)
      yp = self.calcYp(i)
    if calcDistance(x, y, xp, yp) <= self.mPointSize + 1:
       self.mPdx = xp - x
       self.mPdy = yp - y
       self.mActivePnt = i
       self.mMovePnt = i
       return true
  result = false

method onMouseButtonUp*(self: SplineCtrlImpl, x, y: float64): bool =
  if self.mMovePnt >= 0:
    self.mMovePnt = -1
    return true
  result = false

method onMouseMove*(self: SplineCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)
  if not buttonFlag:
    return self.onMouseButtonUp(x, y)

  if self.mMovePnt >= 0:
    var
      xp = x + self.mPdx
      yp = y + self.mPdy

    self.setXp(self.mMovePnt, (xp - self.mXs1) / (self.mXs2 - self.mXs1))
    self.setYp(self.mMovePnt, (yp - self.mYs1) / (self.mYs2 - self.mYs1))

    self.updateSpline()
    return true
  result = false

method onArrowKeys*(self: SplineCtrlImpl, left, right, down, up: bool): bool =
  result = false
  var
    kx = 0.0
    ky = 0.0
  if self.mActivePnt >= 0:
    kx = self.mXp[self.mActivePnt]
    ky = self.mYp[self.mActivePnt]
    if left:  kx -= 0.001; result = true
    if right: kx += 0.001; result = true
    if down:  ky -= 0.001; result = true
    if up:    ky += 0.001; result = true
  if result:
    self.setXp(self.mActivePnt, kx)
    self.setYp(self.mActivePnt, ky)
    self.updateSpline()

proc activePoint*(self: SplineCtrlImpl, i: int) =
  self.mActivePnt = i

proc spline*(self: SplineCtrlImpl): ptr float64 =
  self.mSplineValues[0].addr

proc spline8*(self: SplineCtrlImpl): ptr uint8 =
  self.mSplineValues8[0].addr

proc x*(self: SplineCtrlImpl, idx: int, x: float64) =
  self.mXp[idx] = x

proc y*(self: SplineCtrlImpl, idx: int, y: float64) =
  self.mYp[idx] = y

proc x*(self: SplineCtrlImpl, idx: int): float64 =
  self.mXp[idx]

proc y*(self: SplineCtrlImpl, idx: int): float64 =
  self.mYp[idx]

# Vertex soutce interface
proc numPaths*(self: SplineCtrlImpl): int = 5

proc rewind*(self: SplineCtrlImpl, idx: int) =
  self.mIdx = idx;

  case idx
  of 0:                 # Background
    self.mVertex = 0
    self.mVx[0] = self.m.x1 - self.mBorderExtra
    self.mVy[0] = self.m.y1 - self.mBorderExtra
    self.mVx[1] = self.m.x2 + self.mBorderExtra
    self.mVy[1] = self.m.y1 - self.mBorderExtra
    self.mVx[2] = self.m.x2 + self.mBorderExtra
    self.mVy[2] = self.m.y2 + self.mBorderExtra
    self.mVx[3] = self.m.x1 - self.mBorderExtra
    self.mVy[3] = self.m.y2 + self.mBorderExtra
  of 1:                 # Border
    self.mVertex = 0
    self.mVx[0] = self.m.x1
    self.mVy[0] = self.m.y1
    self.mVx[1] = self.m.x2
    self.mVy[1] = self.m.y1
    self.mVx[2] = self.m.x2
    self.mVy[2] = self.m.y2
    self.mVx[3] = self.m.x1
    self.mVy[3] = self.m.y2
    self.mVx[4] = self.m.x1 + self.mBorderWidth
    self.mVy[4] = self.m.y1 + self.mBorderWidth
    self.mVx[5] = self.m.x1 + self.mBorderWidth
    self.mVy[5] = self.m.y2 - self.mBorderWidth
    self.mVx[6] = self.m.x2 - self.mBorderWidth
    self.mVy[6] = self.m.y2 - self.mBorderWidth
    self.mVx[7] = self.m.x2 - self.mBorderWidth
    self.mVy[7] = self.m.y1 + self.mBorderWidth
  of 2:                 # Curve
    self.calcCurve()
    self.mCurvePoly.width(self.mCurveWidth)
    self.mCurvePoly.rewind(0)
  of 3:                 # Inactive points
    self.mCurvePnt.removeAll()
    for i in 0.. <self.mNumPnt:
      if i != self.mActivePnt:
        self.mEllipse.init(self.calcXp(i), self.calcYp(i),
                           self.mPointSize, self.mPointSize, 32)
        self.mCurvePnt.concatPath(self.mEllipse)
    self.mCurvePoly.rewind(0)
  of 4:                 # Active point
    self.mCurvePnt.removeAll()
    if self.mActivePnt >= 0:
      self.mEllipse.init(self.calcXp(self.mActivePnt), self.calcYp(self.mActivePnt),
                         self.mPointSize, self.mPointSize, 32)
      self.mCurvePnt.concat_path(self.mEllipse)
    self.mCurvePoly.rewind(0)
  else:
    discard

proc vertex*(self: SplineCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdLineTo
  case self.mIdx
  of 0:
    if self.mVertex == 0: cmd = pathCmdMoveTo
    if self.mVertex >= 4: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 1:
    if self.mVertex == 0 or self.mVertex == 4: cmd = pathCmdMoveTo
    if self.mVertex >= 8: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 2:
    cmd = self.mCurvePoly.vertex(x, y)
  of 3, 4:
    cmd = self.mCurvePnt.vertex(x, y)
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd

type
  SplineCtrl*[ColorT] = ref object of SplineCtrlImpl
    mBackgroundColor: ColorT
    mBorderColor: ColorT
    mCurveColor: ColorT
    mInactivePntColor: ColorT
    mActivePntColor: ColorT
    mColors: array[5, ptr ColorT]

proc newSplineCtrl*[ColorT](x1, y1, x2, y2: float64, numPnt: int, flipY = false): SplineCtrl[ColorT] =
  new(result)
  SplineCtrlImpl(result).init(x1, y1, x2, y2, numPnt, flipY)

  when ColorT is not Rgba:
    self.mBackgroundColor = construct(ColorT, initRgba(1.0, 1.0, 0.9))
    self.mBorderColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    self.mCurveColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    self.mInactivePntColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    self.mActivePntColor = construct(ColorT, initRgba(1.0, 0.0, 0.0))
  else:
    self.mBackgroundColor = initRgba(1.0, 1.0, 0.9)
    self.mBorderColor = initRgba(0.0, 0.0, 0.0)
    self.mCurveColor = initRgba(0.0, 0.0, 0.0)
    self.mInactivePntColor = initRgba(0.0, 0.0, 0.0)
    self.mActivePntColor = initRgba(1.0, 0.0, 0.0)

  result.mColors[0] = result.mBackgroundColor.addr
  result.mColors[1] = result.mBorderColor.addr
  result.mColors[2] = result.mCurveColor.addr
  result.mColors[3] = result.mInactivePntColor.addr
  result.mColors[4] = result.mActivePntColor.addr

# Set colors
proc backgroundColor*[ColorT](self: SplineCtrl[ColorT], c: ColorT) =
  self.mBackgroundColor = c

proc borderColor*[ColorT](self: SplineCtrl[ColorT], c: ColorT) =
  self.mBorderColor = c

proc curveColor*[ColorT](self: SplineCtrl[ColorT], c: ColorT) =
  self.mCurveColor = c

proc inactivePntColor*[ColorT](self: SplineCtrl[ColorT], c: ColorT) =
  self.mInactivePntColor = c

proc activePntColor*[ColorT](self: SplineCtrl[ColorT], c: ColorT) =
  self.mActivePntColor = c

proc color*[ColorT](self: SplineCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
