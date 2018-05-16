import agg / [basics, ellipse, trans_affine, color_rgba, gsv_text,
  calc, conv_stroke, path_storage]
import ctrl_base, strutils

export ctrl_base

type
  SliderCtrlImpl* = ref object of CtrlBase
    mBorderWidth: float64
    mBorderExtra: float64
    mTextThickness: float64
    mValue: float64
    mPreviewValue: float64
    mMin, mMax: float64
    mNumSteps: int
    mDescending: bool
    mLabel: string
    mXs1, mYs1, mXs2, mYs2, mPdx: float64
    mMouseMove: bool
    mVx, mVy: array[32, float64]
    mEllipse: Ellipse
    mIdx, mVertex: int
    mText: GsvText
    mTextPoly: ConvStroke[GsvText, NullMarkers]
    mStorage: PathStorage

proc calcBox*(self: SliderCtrlImpl)

proc init(self: SliderCtrlImpl, x1, y1, x2, y2: float64, flipY = false) =
  CtrlBase(self).init(x1, y1, x2, y2, flipY)
  self.mBorderWidth = 1.0
  self.mBorderExtra = (y2 - y1) / 2
  self.mTextThickness = 1.0
  self.mPdx = 0.0
  self.mMouseMove = false
  self.mValue = 0.5
  self.mPreviewValue = 0.5
  self.mMin = 0.0
  self.mMax = 1.0
  self.mNumSteps = 0
  self.mDescending = false
  self.mText = initGsvText()
  self.mTextPoly = initConvStroke(self.mText)
  self.mStorage = initPathStorage()
  self.mLabel = ""
  self.calcBox()

proc newSliderCtrlImpl*(x1, y1, x2, y2: float64, flipY = false): SliderCtrlImpl =
  new(result)
  result.init(x1, y1, x2, y2, flipY)

proc calcBox(self: SliderCtrlImpl) =
  self.mXs1 = self.m.x1 + self.mBorderWidth
  self.mYs1 = self.m.y1 + self.mBorderWidth
  self.mXs2 = self.m.x2 - self.mBorderWidth
  self.mYs2 = self.m.y2 - self.mBorderWidth

proc normalizeValue*(self: SliderCtrlImpl, previewValueFlag: bool): bool =
  result = true
  if self.mNumSteps != 0:
    var step = int(self.mPreviewValue * self.mNumSteps.float64 + 0.5)
    result = self.mValue != (step.float64 / float64(self.mNumSteps))
    self.mValue = step.float64 / float64(self.mNumSteps)
  else:
    self.mValue = self.mPreviewValue

  if previewValueFlag:
    self.mPreviewValue = self.mValue

proc setRange*(self: SliderCtrlImpl, min, max: float64) =
  self.mMin = min
  self.mMax = max

proc numSteps*(self: SliderCtrlImpl, num: int) =
  self.mNumSteps = num

proc textThickness*(self: SliderCtrlImpl, t: float64) =
  self.mTextThickness = t

proc descending*(self: SliderCtrlImpl): bool =
  self.mDescending

proc descending*(self: SliderCtrlImpl, v: bool) =
  self.mDescending = v

proc value*(self: SliderCtrlImpl): float64 =
  self.mValue * (self.mMax - self.mMin) + self.mMin

proc borderWidth*(self: SliderCtrlImpl, t: float64, extra = 0.0) =
  self.mBorderWidth = t
  self.mBorderExtra = extra
  self.calcBox()

proc value*(self: SliderCtrlImpl, value: float64) =
  self.mPreviewValue = (value - self.mMin) / (self.mMax - self.mMin)
  if self.mPreviewValue > 1.0: self.mPreviewValue = 1.0
  if self.mPreviewValue < 0.0: self.mPreviewValue = 0.0
  discard self.normalizeValue(true)

proc label*(self: SliderCtrlImpl, fmt: string) =
  self.mLabel = fmt

method inRect*(self: SliderCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and x <= self.m.x2 and y >= self.m.y1 and y <= self.m.y2

method onMouseButtonDown*(self: SliderCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)

  var
    xp = self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue
    yp = (self.mYs1 + self.mYs2) / 2.0

  if calcDistance(x, y, xp, yp) <= self.m.y2 - self.m.y1:
    self.mPdx = xp - x
    self.mMouseMove = true
    return true
  result = false

method onMouseMove*(self: SliderCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)

  if not buttonFlag:
    discard self.onMouseButtonUp(x, y)
    return false

  if self.mMouseMove:
    var
      xp = x + self.mPdx
    self.mPreviewValue = (xp - self.mXs1) / (self.mXs2 - self.mXs1)
    if self.mPreviewValue < 0.0: self.mPreviewValue = 0.0
    if self.mPreviewValue > 1.0: self.mPreviewValue = 1.0
    return true
  result = false

method onMouseButtonUp*(self: SliderCtrlImpl, x, y: float64): bool =
  self.mMouseMove = false
  discard self.normalizeValue(true)
  true

method onArrowKeys*(self: SliderCtrlImpl, left, right, down, up: bool): bool =
  var d = 0.005
  if self.mNumSteps != 0: d = 1.0 / self.mNumSteps.float64

  if right or up:
    self.mPreviewValue += d
    if self.mPreviewValue > 1.0: self.mPreviewValue = 1.0
    discard self.normalizeValue(true)
    return true

  if left or down:
    self.mPreviewValue -= d
    if self.mPreviewValue < 0.0: self.mPreviewValue = 0.0
    discard self.normalizeValue(true)
    return true
  result = false

# Vertex source interface
proc numPaths*(self: SliderCtrlImpl): int = 6

proc rewind*(self: SliderCtrlImpl, idx: int) =
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
  of 1:                 # Triangle
    self.mVertex = 0
    if self.mDescending:
      self.mVx[0] = self.m.x1
      self.mVy[0] = self.m.y1
      self.mVx[1] = self.m.x2
      self.mVy[1] = self.m.y1
      self.mVx[2] = self.m.x1
      self.mVy[2] = self.m.y2
      self.mVx[3] = self.m.x1
      self.mVy[3] = self.m.y1
    else:
      self.mVx[0] = self.m.x1
      self.mVy[0] = self.m.y1
      self.mVx[1] = self.m.x2
      self.mVy[1] = self.m.y1
      self.mVx[2] = self.m.x2
      self.mVy[2] = self.m.y2
      self.mVx[3] = self.m.x1
      self.mVy[3] = self.m.y1
  of 2:
    self.mText.text(self.mLabel)
    if self.mLabel.len != 0:
      var buf = self.mLabel % [formatFloat(self.value(), ffDecimal, 2)]
      self.mText.text(buf)
    self.mText.startPoint(self.m.x1, self.m.y1)
    self.mText.size((self.m.y2 - self.m.y1) * 1.2, self.m.y2 - self.m.y1)
    self.mTextPoly.width(self.mTextThickness)
    self.mTextPoly.lineJoin(roundJoin)
    self.mTextPoly.lineCap(roundCap)
    self.mTextPoly.rewind(0)
  of 3:                 # pointer preview
    self.mEllipse.init(self.mXs1 + (self.mXs2 - self.mXs1) * self.mPreviewValue,
                      (self.mYs1 + self.mYs2) / 2.0,
                       self.m.y2 - self.m.y1,
                       self.m.y2 - self.m.y1, 32)
  of 4:                 # pointer
    discard self.normalizeValue(false)
    self.mEllipse.init(self.mXs1 + (self.mXs2 - self.mXs1) * self.mValue,
                      (self.mYs1 + self.mYs2) / 2.0,
                       self.m.y2 - self.m.y1,
                       self.m.y2 - self.m.y1, 32)
    self.mEllipse.rewind(0)
  of 5:
    self.mStorage.removeAll()
    if self.mNumSteps != 0:
      var d = (self.mXs2 - self.mXs1) / self.mNumSteps.float64
      if d > 0.004: d = 0.004
      for i in 0..<self.mNumSteps + 1:
        var x = self.mXs1 + (self.mXs2 - self.mXs1) * i.float64 / self.mNumSteps.float64
        self.mStorage.moveTo(x, self.m.y1)
        self.mStorage.lineTo(x - d * (self.m.x2 - self.m.x1), self.m.y1 - self.mBorderExtra)
        self.mStorage.lineTo(x + d * (self.m.x2 - self.m.x1), self.m.y1 - self.mBorderExtra)
  else:
    discard

proc vertex*(self: SliderCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdLineTo
  case self.mIdx
  of 0:
    if self.mVertex == 0: cmd = pathCmdMoveTo
    if self.mVertex >= 4: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 1:
    if self.mVertex == 0: cmd = pathCmdMoveTo
    if self.mVertex >= 4: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 2:
    cmd = self.mTextPoly.vertex(x, y)
  of 3, 4:
    cmd = self.mEllipse.vertex(x, y)
  of 5:
    cmd = self.mStorage.vertex(x, y)
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd

type
  SliderCtrl*[ColorT] = ref object of SliderCtrlImpl
    mBackgroundColor: ColorT
    mTriangleColor: ColorT
    mTextColor: ColorT
    mPointerPreviewColor: ColorT
    mPointerColor: ColorT
    mColors: array[6, ptr ColorT]

proc newSliderCtrl*[ColorT](x1, y1, x2, y2: float64, flipY = false): SliderCtrl[ColorT] =
  new(result)
  SliderCtrlImpl(result).init(x1, y1, x2, y2, flipY)

  when ColorT is not Rgba:
    result.mBackgroundColor = construct(ColorT, initRgba(1.0, 0.9, 0.8))
    result.mTriangleColor = construct(ColorT, initRgba(0.7, 0.6, 0.6))
    result.mTextColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mPointerPreviewColor = construct(ColorT, initRgba(0.6, 0.4, 0.4, 0.4))
    result.mPointerColor = construct(ColorT, initRgba(0.8, 0.0, 0.0, 0.6))
  else:
    result.mBackgroundColor = initRgba(1.0, 0.9, 0.8)
    result.mTriangleColor = initRgba(0.7, 0.6, 0.6)
    result.mTextColor = initRgba(0.0, 0.0, 0.0)
    result.mPointerPreviewColor = initRgba(0.6, 0.4, 0.4, 0.4)
    result.mPointerColor = initRgba(0.8, 0.0, 0.0, 0.6)

  result.mColors[0] = result.mBackgroundColor.addr
  result.mColors[1] = result.mTriangleColor.addr
  result.mColors[2] = result.mTextColor.addr
  result.mColors[3] = result.mPointerPreviewColor.addr
  result.mColors[4] = result.mPointerColor.addr
  result.mColors[5] = result.mTextColor.addr

proc backgroundColor*[ColorT](self: SliderCtrl[ColorT], c: ColorT) =
  self.mBackgroundColor = c

proc pointerColor*[ColorT](self: SliderCtrl[ColorT], c: ColorT) =
  self.mPointerColor = c

proc color*[ColorT](self: SliderCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
