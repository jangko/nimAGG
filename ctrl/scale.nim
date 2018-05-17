import agg/[basics, ellipse, trans_affine, color_rgba, calc]
import ctrl_base
export ctrl_base

type
  Move = enum
    moveNothing
    moveValue1
    moveValue2
    moveSlider

  ScaleCtrlImpl* = ref object of CtrlBase
    mBorderWidth: float64
    mBorderExtra: float64
    mValue1, mValue2: float64
    mMinD: float64
    mXs1, mYs1, mXs2, mYs2: float64
    mPdx, mPdy: float64
    mMoveWhat: Move
    mVx, mVy: array[32, float64]
    mEllipse: Ellipse
    mIdx, mVertex: int

proc calcBox*(self: ScaleCtrlImpl)

proc init(self: ScaleCtrlImpl, x1, y1, x2, y2: float64, flipY = false) =
  CtrlBase(self).init(x1, y1, x2, y2, flipY)
  self.mBorderWidth = 1.0
  self.mBorderExtra = if abs(x2 - x1) > abs(y2 - y1): (y2 - y1) / 2 else: (x2 - x1) / 2
  self.mPdx = 0.0
  self.mPdy = 0.0
  self.mMoveWhat = moveNothing
  self.mValue1 = 0.3
  self.mValue2 = 0.7
  self.mMinD = 0.01
  self.calcBox()

proc newScaleCtrlImpl*(x1, y1, x2, y2: float64, flipY = false): ScaleCtrlImpl =
  new(result)
  result.init(x1, y1, x2, y2, flipY)

proc calcBox(self: ScaleCtrlImpl) =
  self.mXs1 = self.m.x1 + self.mBorderWidth
  self.mYs1 = self.m.y1 + self.mBorderWidth
  self.mXs2 = self.m.x2 - self.mBorderWidth
  self.mYs2 = self.m.y2 - self.mBorderWidth

proc borderWidth*(self: ScaleCtrlImpl, t: float64, extra=0.0) =
  self.mBorderWidth = t
  self.mBorderExtra = extra
  self.calcBox()

proc resize*(self: ScaleCtrlImpl, x1, y1, x2, y2: float64) =
  self.m.x1 = x1
  self.m.y1 = y1
  self.m.x2 = x2
  self.m.y2 = y2
  self.calcBox()
  self.mBorderExtra = if abs(x2 - x1) > abs(y2 - y1): (y2 - y1) / 2 else: (x2 - x1) / 2

proc minDelta*(self: ScaleCtrlImpl): float64 =
  self.mMinD

proc minDelta*(self: ScaleCtrlImpl, d: float64) =
  self.mMinD = d

proc value1*(self: ScaleCtrlImpl): float64 =
  self.mValue1

proc value2*(self: ScaleCtrlImpl): float64 =
  self.mValue2

proc value1*(self: ScaleCtrlImpl, value: float64) =
  var value = value
  if value < 0.0: value = 0.0
  if value > 1.0: value = 1.0
  if self.mValue2 - value < self.mMinD: value = self.mValue2 - self.mMinD
  self.mValue1 = value

proc value2*(self: ScaleCtrlImpl, value: float64) =
  var value = value
  if value < 0.0: value = 0.0
  if value > 1.0: value = 1.0
  if self.mValue1 + value < self.mMinD: value = self.mValue1 + self.mMinD
  self.mValue2 = value

proc move*(self: ScaleCtrlImpl, d: float64) =
  self.mValue1 += d
  self.mValue2 += d
  if self.mValue1 < 0.0:
    self.mValue2 -= self.mValue1
    self.mValue1 = 0.0
  if self.mValue2 > 1.0:
    self.mValue1 -= self.mValue2 - 1.0
    self.mValue2 = 1.0

method inRect*(self: ScaleCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and x <= self.m.x2 and y >= self.m.y1 and y <= self.m.y2

method onMouseButtonDown*(self: ScaleCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  var
    xp1, xp2, ys1, ys2, xp, yp: float64

  if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
    xp1 = self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue1
    xp2 = self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue2
    ys1 = self.m.y1 - self.mBorderExtra / 2.0
    ys2 = self.m.y2 + self.mBorderExtra / 2.0
    yp = (self.mYs1 + self.mYs2) / 2.0

    if x > xp1 and y > ys1 and x < xp2 and y < ys2:
      self.mPdx = xp1 - x
      self.mMoveWhat = moveSlider
      return true

    #if x < xp1 and calcDistance(x, y, xp1, yp) <= self.m.y2 - self.m.y1)
    if calcDistance(x, y, xp1, yp) <= self.m.y2 - self.m.y1:
      self.mPdx = xp1 - x
      self.mMoveWhat = moveValue1
      return true

    #if x > xp2 and calcDistance(x, y, xp2, yp) <= self.m.y2 - self.m.y1)
    if calcDistance(x, y, xp2, yp) <= self.m.y2 - self.m.y1:
      self.mPdx = xp2 - x;
      self.mMoveWhat = moveValue2;
      return true
  else:
    xp1 = self.m.x1 - self.mBorderExtra / 2.0
    xp2 = self.m.x2 + self.mBorderExtra / 2.0
    ys1 = self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue1
    ys2 = self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue2
    xp = (self.mXs1 + self.mXs2) / 2.0

    if x > xp1 and y > ys1 and x < xp2 and y < ys2:
      self.mPdy = ys1 - y
      self.mMoveWhat = moveSlider
      return true

    #if y < ys1 and calcDistance(x, y, xp, ys1) <= self.m.x2 - self.m.x1)
    if calcDistance(x, y, xp, ys1) <= self.m.x2 - self.m.x1:
      self.mPdy = ys1 - y
      self.mMoveWhat = moveValue1
      return true

    #if y > ys2 and calcDistance(x, y, xp, ys2) <= self.m.x2 - self.m.x1)
    if calcDistance(x, y, xp, ys2) <= self.m.x2 - self.m.x1:
      self.mPdy = ys2 - y
      self.mMoveWhat = moveValue2
      return true
  result = false

method onMouseMove*(self: ScaleCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)
  if not buttonFlag:
    return self.onMouseButtonUp(x, y)

  var
    xp = x + self.mPdx
    yp = y + self.mPdy
    dv: float64

  case self.mMoveWhat
  of moveValue1:
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mValue1 = (xp - self.mXs1) / (self.mXs2 - self.mXs1)
    else:
      self.mValue1 = (yp - self.mYs1) / (self.mYs2 - self.mYs1)
    if self.mValue1 < 0.0: self.mValue1 = 0.0
    if self.mValue1 > self.mValue2 - self.mMinD: self.mValue1 = self.mValue2 - self.mMinD
    return true
  of moveValue2:
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mValue2 = (xp - self.mXs1) / (self.mXs2 - self.mXs1)
    else:
      self.mValue2 = (yp - self.mYs1) / (self.mYs2 - self.mYs1)
    if self.mValue2 > 1.0: self.mValue2 = 1.0
    if self.mValue2 < self.mValue1 + self.mMinD: self.mValue2 = self.mValue1 + self.mMinD
    return true
  of moveSlider:
    dv = self.mValue2 - self.mValue1
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mValue1 = (xp - self.mXs1) / (self.mXs2 - self.mXs1)
    else:
      self.mValue1 = (yp - self.mYs1) / (self.mYs2 - self.mYs1)
    self.mValue2 = self.mValue1 + dv
    if self.mValue1 < 0.0:
      dv = self.mValue2 - self.mValue1
      self.mValue1 = 0.0
      self.mValue2 = self.mValue1 + dv
    if self.mValue2 > 1.0:
      dv = self.mValue2 - self.mValue1
      self.mValue2 = 1.0
      self.mValue1 = self.mValue2 - dv
    return true
  else:
    discard
  result = false

method onMouseButtonUp*(self: ScaleCtrlImpl, x, y: float64): bool =
  self.mMoveWhat = moveNothing
  result = false

method onArrowKeys*(self: ScaleCtrlImpl, left, right, down, up: bool): bool =
    #[if right or up)
        self.mValue += 0.005;
        if self.mValue > 1.0) self.mValue = 1.0;
        return true
    if left or down)
        self.mValue -= 0.005;
        if self.mValue < 0.0) self.mValue = 0.0;
        return true
    }]#
  result = false

# Vertex soutce interface
proc numPaths*(self: ScaleCtrlImpl): int = 5

proc rewind*(self: ScaleCtrlImpl, idx: int) =
  self.mIdx = idx
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
  of 2:                 # pointer1
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mEllipse.init(self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue1,
                        (self.mYs1 + self.mYs2) / 2.0,
                         self.m.y2 - self.m.y1,
                         self.m.y2 - self.m.y1, 32)
    else:
      self.mEllipse.init((self.mXs1 + self.mXs2) / 2.0,
                          self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue1,
                          self.m.x2 - self.m.x1,
                          self.m.x2 - self.m.x1, 32)
    self.mEllipse.rewind(0)
  of 3:                 # pointer2
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mEllipse.init(self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue2,
                        (self.mYs1 + self.mYs2) / 2.0,
                         self.m.y2 - self.m.y1,
                         self.m.y2 - self.m.y1, 32)
    else:
      self.mEllipse.init((self.mXs1 + self.mXs2) / 2.0,
                          self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue2,
                          self.m.x2 - self.m.x1,
                          self.m.x2 - self.m.x1, 32)
    self.mEllipse.rewind(0)
  of 4:                 # slider
    self.mVertex = 0
    if abs(self.m.x2 - self.m.x1) > abs(self.m.y2 - self.m.y1):
      self.mVx[0] = self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue1
      self.mVy[0] = self.m.y1 - self.mBorderExtra / 2.0
      self.mVx[1] = self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue2
      self.mVy[1] = self.mVy[0]
      self.mVx[2] = self.mVx[1]
      self.mVy[2] = self.m.y2 + self.mBorderExtra / 2.0
      self.mVx[3] = self.mVx[0]
      self.mVy[3] = self.mVy[2]
    else:
      self.mVx[0] = self.m.x1 - self.mBorderExtra / 2.0
      self.mVy[0] = self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue1
      self.mVx[1] = self.mVx[0]
      self.mVy[1] = self.mYs1 + (self.mYs2 - self.mYs1) * self.mValue2
      self.mVx[2] = self.m.x2 + self.mBorderExtra / 2.0
      self.mVy[2] = self.mVy[1]
      self.mVx[3] = self.mVx[2]
      self.mVy[3] = self.mVy[0]
  else:
    discard

proc vertex*(self: ScaleCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdLineTo
  case self.mIdx
  of 0, 4:
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
  of 2, 3:
    cmd = self.mEllipse.vertex(x, y)
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd


type
  ScaleCtrl*[ColorT] = ref object of ScaleCtrlImpl
    mBackgroundColor: ColorT
    mBorderColor: ColorT
    mPointersColor: ColorT
    mSliderColor: ColorT
    mColors: array[5, ptr ColorT]

proc newScaleCtrl*[ColorT](x1, y1, x2, y2: float64, flipY = false): ScaleCtrl[ColorT] =
  new(result)
  ScaleCtrlImpl(result).init(x1, y1, x2, y2, flipY)

  when ColorT is not Rgba:
    result.mBackgroundColor = construct(ColorT, initRgba(1.0, 0.9, 0.8))
    result.mBorderColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mPointersColor = construct(ColorT, initRgba(0.8, 0.0, 0.0, 0.8))
    result.mSliderColor = construct(ColorT, initRgba(0.2, 0.1, 0.0, 0.6))
  else:
    result.mBackgroundColor = initRgba(1.0, 0.9, 0.8)
    result.mBorderColor = initRgba(0.0, 0.0, 0.0)
    result.mPointersColor = initRgba(0.8, 0.0, 0.0, 0.8)
    result.mSliderColor = initRgba(0.2, 0.1, 0.0, 0.6)

  result.mColors[0] = result.mBackgroundColor.addr
  result.mColors[1] = result.mBorderColor.addr
  result.mColors[2] = result.mPointersColor.addr
  result.mColors[3] = result.mPointersColor.addr
  result.mColors[4] = result.mSliderColor.addr

proc backgroundColor*[ColorT](self: ScaleCtrl[ColorT], c: ColorT) =
  self.mBackgroundColor = c

proc borderColor*[ColorT](self: ScaleCtrl[ColorT], c: ColorT) =
  self.mBorderColor = c

proc pointersColor*[ColorT](self: ScaleCtrl[ColorT], c: ColorT) =
  self.mPointersColor = c

proc sliderColor*[ColorT](self: ScaleCtrl[ColorT], c: ColorT) =
  self.mSliderColor = c

proc color*[ColorT](self: ScaleCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
