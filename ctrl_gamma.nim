import agg_basics, agg_gamma_spline, agg_ellipse, agg_conv_stroke
import agg_gsv_text, agg_trans_affine, agg_color_rgba, ctrl_base
import agg_math, strutils

export ctrl_base

type
  GammaCtrlImpl* = ref object of CtrlBase
    mGammaSpline: GammaSpline
    mBorderWidth, mBorderExtra: float64
    mCurveWidth, mGridWidth: float64
    mTextThickness, mPointSize: float64
    mTextHeight, mTextWidth: float64
    mXc1, mYc1, mXc2, mYc2: float64
    mXs1, mYs1, mXs2, mYs2: float64
    mXt1, mYt1, mXt2, mYt2: float64
    mCurvePoly: ConvStroke[GammaSpline, NullMarkers]
    mEllipse: Ellipse
    mText: GsvText
    mTextPoly: ConvStroke[GsvText, NullMarkers]
    mIdx, mVertex: int
    mVx, mVy: array[32, float64]
    mXp1, mYp1, mXp2, mYp2: float64
    mP1Active: bool
    mMousePoint: int
    mPdx, mPdy: float64

proc calcSplineBox*(self: GammaCtrlImpl)

proc init(self: GammaCtrlImpl, x1, y1, x2, y2: float64, flipY = false) =
  CtrlBase(self).init(x1, y1, x2, y2, flipY)
  self.mBorderWidth = 2.0
  self.mBorderExtra = 0.0
  self.mCurveWidth = 2.0
  self.mGridWidth = 0.2
  self.mTextThickness = 1.5
  self.mPointSize = 5.0
  self.mTextHeight = 9.0
  self.mTextWidth = 0.0
  self.mXc1 = x1
  self.mYc1 = y1
  self.mXc2 = x2
  self.mYc2 = y2 - self.mTextHeight * 2.0
  self.mXt1 = x1
  self.mYt1 = y2 - self.mTextHeight * 2.0
  self.mXt2 = x2
  self.mYt2 = y2
  self.mGammaSpline = initGammaSpline()
  self.mText = initGsvText()
  self.mCurvePoly = initConvStroke(self.mGammaSpline)
  self.mTextPoly = initConvStroke(self.mText)
  self.mIdx = 0
  self.mVertex = 0
  self.mP1Active = true
  self.mMousePoint = 0
  self.mPdx = 0.0
  self.mPdy = 0.0
  self.calcSplineBox()

proc newGammaCtrlImpl*(x1, y1, x2, y2: float64, flipY = false): GammaCtrlImpl =
  new(result)
  result.init(x1, y1, x2 ,y2, flipY)

proc calcSplineBox(self: GammaCtrlImpl) =
  self.mXs1 = self.mXc1 + self.mBorderWidth
  self.mYs1 = self.mYc1 + self.mBorderWidth
  self.mXs2 = self.mXc2 - self.mBorderWidth
  self.mYs2 = self.mYc2 - self.mBorderWidth * 0.5

proc calcPoints*(self: GammaCtrlImpl) =
  var kx1, ky1, kx2, ky2: float64
  self.mGammaSpline.getValues(kx1, ky1, kx2, ky2)
  self.mXp1 = self.mXs1 + (self.mXs2 - self.mXs1) * kx1 * 0.25
  self.mYp1 = self.mYs1 + (self.mYs2 - self.mYs1) * ky1 * 0.25
  self.mXp2 = self.mXs2 - (self.mXs2 - self.mXs1) * kx2 * 0.25
  self.mYp2 = self.mYs2 - (self.mYs2 - self.mYs1) * ky2 * 0.25

proc calcValues*(self: GammaCtrlImpl) =
  var kx1, ky1, kx2, ky2: float64
  kx1 = (self.mXp1 - self.mXs1) * 4.0 / (self.mXs2 - self.mXs1)
  ky1 = (self.mYp1 - self.mYs1) * 4.0 / (self.mYs2 - self.mYs1)
  kx2 = (self.mXs2 - self.mXp2) * 4.0 / (self.mXs2 - self.mXs1)
  ky2 = (self.mYs2 - self.mYp2) * 4.0 / (self.mYs2 - self.mYs1)
  self.mGammaSpline.values(kx1, ky1, kx2, ky2)

proc textSize*(self: GammaCtrlImpl, h: float64, w = 0.0'f64) =
  self.mTextWidth = w
  self.mTextHeight = h
  self.mYc2 = self.m.y2 - self.mTextHeight * 2.0
  self.mYt1 = self.m.y2 - self.mTextHeight * 2.0
  self.calcSplineBox()

proc borderWidth*(self: GammaCtrlImpl, t: float64, extra = 0.0) =
  self.mBorderWidth = t
  self.mBorderExtra = extra
  self.calcSplineBox()

proc values*(self: GammaCtrlImpl, kx1, ky1, kx2, ky2: float64) =
  self.mGammaSpline.values(kx1, ky1, kx2, ky2)

proc values*(self: GammaCtrlImpl, kx1, ky1, kx2, ky2: var float64) =
  self.mGammaSpline.getValues(kx1, ky1, kx2, ky2)

# Set other parameters
proc curveWidth*(self: GammaCtrlImpl, t: float64) =
  self.mCurveWidth = t

proc gridWidth*(self: GammaCtrlImpl, t: float64) =
  self.mGridWidth = t

proc textThickness*(self: GammaCtrlImpl, t: float64) =
  self.mTextThickness = t

proc pointSize*(self: GammaCtrlImpl, s: float64) =
  self.mPointSize = s
proc getGammaValue*(self: GammaCtrlImpl, x :float64): float64 =
  self.mGammaSpline.y(x)

method inRect*(self: GammaCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and x <= self.m.x2 and y >= self.m.y1 and y <= self.m.y2

method onMouseButtonDown*(self: GammaCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  self.calcPoints()

  if calcDistance(x, y, self.mXp1, self.mYp1) <= self.mPointSize + 1:
    self.mMousePoint = 1
    self.mPdx = self.mXp1 - x
    self.mPdy = self.mYp1 - y
    self.mP1Active = true
    return true

  if calcDistance(x, y, self.mXp2, self.mYp2) <= self.mPointSize + 1:
    self.mMousePoint = 2
    self.mPdx = self.mXp2 - x
    self.mPdy = self.mYp2 - y
    self.mP1Active = false
    return true

  return false

method onMouseButtonUp*(self: GammaCtrlImpl, x, y: float64): bool =
  if self.mMousePoint != 0:
    self.mMousePoint = 0
    return true
  return false

method onMouseMove*(self: GammaCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  if not buttonFlag:
    return self.onMouseButtonUp(x, y)

  if self.mMousePoint == 1:
    self.mXp1 = x + self.mPdx
    self.mYp1 = y + self.mPdy
    self.calcValues()
    return true
  if self.mMousePoint == 2:
    self.mXp2 = x + self.mPdx
    self.mYp2 = y + self.mPdy
    self.calcValues()
    return true
  return false

method onArrowKeys*(self: GammaCtrlImpl, left, right, down, up: bool): bool =
  result = false
  var kx1, ky1, kx2, ky2: float64
  self.mGammaSpline.values(kx1, ky1, kx2, ky2)
  if self.mP1Active:
    if left: kx1 -= 0.005; result = true
    if right: kx1 += 0.005; result = true
    if down: ky1 -= 0.005; result = true
    if up: ky1 += 0.005; result = true
  else:
    if left: kx2 += 0.005; result = true
    if right: kx2 -= 0.005; result = true
    if down: ky2 += 0.005; result = true
    if up: ky2 -= 0.005; result = true
  if result:
    self.mGammaSpline.values(kx1, ky1, kx2, ky2)

proc changeActivePoint*(self: GammaCtrlImpl) =
  self.mP1Active = if self.mP1Active: false else: true

# A copy of agg::gamma_spline interface
proc gamma*(self: GammaCtrlImpl): ptr uint8 =
  self.mGammaSpline.gamma()

proc y*(self: GammaCtrlImpl, x: float64): float64 =
  self.mGammaSpline.y(x)

proc getGammaSpline*(self: GammaCtrlImpl): var GammaSpline =
  self.mGammaSpline

# Vertex soutce interface
proc numPaths*(self: GammaCtrlImpl): int = 7

proc rewind*(self: GammaCtrlImpl, idx: int) =
  var
    kx1, ky1, kx2, ky2: float64

  self.mIdx = idx

  case idx
  of 0:                 # Background
    self.mVertex = 0;
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
    self.mVx[8] = self.mXc1 + self.mBorderWidth
    self.mVy[8] = self.mYc2 - self.mBorderWidth * 0.5
    self.mVx[9] = self.mXc2 - self.mBorderWidth
    self.mVy[9] = self.mYc2 - self.mBorderWidth * 0.5
    self.mVx[10] = self.mXc2 - self.mBorderWidth
    self.mVy[10] = self.mYc2 + self.mBorderWidth * 0.5
    self.mVx[11] = self.mXc1 + self.mBorderWidth
    self.mVy[11] = self.mYc2 + self.mBorderWidth * 0.5
  of 2:                 # Curve
    self.mGammaSpline.box(self.mXs1, self.mYs1, self.mXs2, self.mYs2)
    self.mCurvePoly.width(self.mCurveWidth)
    self.mCurvePoly.rewind(0)
  of 3:                 # Grid
    self.mVertex = 0
    self.mVx[0] = self.mXs1
    self.mVy[0] = (self.mYs1 + self.mYs2) * 0.5 - self.mGridWidth * 0.5
    self.mVx[1] = self.mXs2
    self.mVy[1] = (self.mYs1 + self.mYs2) * 0.5 - self.mGridWidth * 0.5
    self.mVx[2] = self.mXs2
    self.mVy[2] = (self.mYs1 + self.mYs2) * 0.5 + self.mGridWidth * 0.5
    self.mVx[3] = self.mXs1
    self.mVy[3] = (self.mYs1 + self.mYs2) * 0.5 + self.mGridWidth * 0.5
    self.mVx[4] = (self.mXs1 + self.mXs2) * 0.5 - self.mGridWidth * 0.5
    self.mVy[4] = self.mYs1
    self.mVx[5] = (self.mXs1 + self.mXs2) * 0.5 - self.mGridWidth * 0.5
    self.mVy[5] = self.mYs2
    self.mVx[6] = (self.mXs1 + self.mXs2) * 0.5 + self.mGridWidth * 0.5
    self.mVy[6] = self.mYs2
    self.mVx[7] = (self.mXs1 + self.mXs2) * 0.5 + self.mGridWidth * 0.5
    self.mVy[7] = self.mYs1
    self.calcPoints()
    self.mVx[8] = self.mXs1
    self.mVy[8] = self.mYp1 - self.mGridWidth * 0.5
    self.mVx[9] = self.mXp1 - self.mGridWidth * 0.5
    self.mVy[9] = self.mYp1 - self.mGridWidth * 0.5
    self.mVx[10] = self.mXp1 - self.mGridWidth * 0.5
    self.mVy[10] = self.mYs1
    self.mVx[11] = self.mXp1 + self.mGridWidth * 0.5
    self.mVy[11] = self.mYs1
    self.mVx[12] = self.mXp1 + self.mGridWidth * 0.5
    self.mVy[12] = self.mYp1 + self.mGridWidth * 0.5
    self.mVx[13] = self.mXs1
    self.mVy[13] = self.mYp1 + self.mGridWidth * 0.5
    self.mVx[14] = self.mXs2
    self.mVy[14] = self.mYp2 + self.mGridWidth * 0.5
    self.mVx[15] = self.mXp2 + self.mGridWidth * 0.5
    self.mVy[15] = self.mYp2 + self.mGridWidth * 0.5
    self.mVx[16] = self.mXp2 + self.mGridWidth * 0.5
    self.mVy[16] = self.mYs2
    self.mVx[17] = self.mXp2 - self.mGridWidth * 0.5
    self.mVy[17] = self.mYs2
    self.mVx[18] = self.mXp2 - self.mGridWidth * 0.5
    self.mVy[18] = self.mYp2 - self.mGridWidth * 0.5
    self.mVx[19] = self.mXs2
    self.mVy[19] = self.mYp2 - self.mGridWidth * 0.5
  of 4:                 # Point1
    self.calcPoints()
    if self.mP1Active: self.mEllipse.init(self.mXp2, self.mYp2, self.mPointSize, self.mPointSize, 32)
    else:              self.mEllipse.init(self.mXp1, self.mYp1, self.mPointSize, self.mPointSize, 32)
  of 5:                 # Point2
    self.calcPoints()
    if self.mP1Active: self.mEllipse.init(self.mXp1, self.mYp1, self.mPointSize, self.mPointSize, 32)
    else:              self.mEllipse.init(self.mXp2, self.mYp2, self.mPointSize, self.mPointSize, 32)
  of 6:                 # Text
    self.mGammaSpline.getValues(kx1, ky1, kx2, ky2)
    var tbuf = "$1 $2 $3 $4" % [kx1.formatFloat(ffDecimal, 3),
      ky1.formatFloat(ffDecimal, 3),
      kx2.formatFloat(ffDecimal, 3),
      ky2.formatFloat(ffDecimal, 3)]
    self.mText.text(tbuf)
    self.mText.size(self.mTextHeight, self.mTextWidth)
    self.mText.start_point(self.mXt1 + self.mBorderWidth * 2.0, (self.mYt1 + self.mYt2) * 0.5 - self.mTextHeight * 0.5)
    self.mTextPoly.width(self.mTextThickness)
    self.mTextPoly.lineJoin(roundJoin)
    self.mTextPoly.lineCap(roundCap)
    self.mTextPoly.rewind(0)
  else:
    discard

proc vertex*(self: GammaCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdLineTo
  case self.mIdx
  of 0:
    if self.mVertex == 0: cmd = pathCmdMoveTo
    if self.mVertex >= 4: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 1:
    if self.mVertex == 0 or self.mVertex == 4 or self.mVertex == 8: cmd = pathCmdMoveTo
    if self.mVertex >= 12: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 2:
    cmd = self.mCurvePoly.vertex(x, y)
  of 3:
    if self.mVertex == 0 or
      self.mVertex == 4 or
      self.mVertex == 8 or
      self.mVertex == 14: cmd = pathCmdMoveTo

    if self.mVertex >= 20: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 4, 5: # Point1, Point2
    cmd = self.mEllipse.vertex(x, y)
  of 6:
    cmd = self.mTextPoly.vertex(x, y)
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)
  result = cmd

type
  GammaCtrl*[ColorT] = ref object of GammaCtrlImpl
    mBackgroundColor: ColorT
    mBorderColor: ColorT
    mCurveColor: ColorT
    mGridColor: ColorT
    mInactivePntColor: ColorT
    mActivePntColor: ColorT
    mTextColor: ColorT
    mColors: array[7, ptr ColorT]

proc newGammaCtrl*[ColorT](x1, y1, x2, y2: float64, flipY = false): GammaCtrl[ColorT] =
  new(result)
  GammaCtrlImpl(result).init(x1, y1, x2, y2, flipY)

  when ColorT is not Rgba:
    result.mBackgroundColor = construct(ColorT, initRgba(1.0, 1.0, 0.9))
    result.mBorderColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mCurveColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mGridColor = construct(ColorT, initRgba(0.2, 0.2, 0.0))
    result.mInactivePntColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mActivePntColor = construct(ColorT, initRgba(1.0, 0.0, 0.0))
    result.mTextColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
  else:
    result.mBackgroundColor = initRgba(1.0, 1.0, 0.9)
    result.mBorderColor = initRgba(0.0, 0.0, 0.0)
    result.mCurveColor = initRgba(0.0, 0.0, 0.0)
    result.mGridColor = initRgba(0.2, 0.2, 0.0)
    result.mInactivePntColor = initRgba(0.0, 0.0, 0.0)
    result.mActivePntColor = initRgba(1.0, 0.0, 0.0)
    result.mTextColor = initRgba(0.0, 0.0, 0.0)

  result.mColors[0] = result.mBackgroundColor.addr
  result.mColors[1] = result.mBorderColor.addr
  result.mColors[2] = result.mCurveColor.addr
  result.mColors[3] = result.mGridColor.addr
  result.mColors[4] = result.mInactivePntColor.addr
  result.mColors[5] = result.mActivePntColor.addr
  result.mColors[6] = result.mTextColor.addr

# Set colors
proc backgroundColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mBackgroundColor = c

proc borderColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mBorderColor = c

proc curveColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mCurveColor = c

proc gridColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mGridColor = c

proc inactivePntColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mInactivePntColor = c

proc activePntColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mActivePntColor = c

proc textColor*[ColorT](self: GammaCtrl[ColorT], c: ColorT) =
  self.mTextColor = c

proc color*[ColorT](self: GammaCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
