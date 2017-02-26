import agg_array, agg_ellipse, agg_conv_stroke, agg_gsv_text, agg_trans_affine
import agg_color_rgba, ctrl_base, agg_math, agg_basics

export ctrl_base

type
  RboxCtrlImpl* = ref object of CtrlBase
    mBorderWidth: float64
    mBorderExtra: float64
    mTextThickness: float64
    mTextHeight: float64
    mTextWidth: float64
    mItems: seq[string]
    mNumItems: int
    mCurItem: int
    mXs1, mYs1, mXs2, mYs2: float64
    mVx, mVy: array[32, float64]
    mDrawItem: int
    mDy: float64
    mEllipse: Ellipse
    mEllipsePoly: ConvStroke[Ellipse, NullMarkers]
    mText: GsvText
    mTextPoly: ConvStroke[GsvText, NullMarkers]
    mIdx: int
    mVertex: int

proc calcRbox*(self: RboxCtrlImpl)

proc init(self: RboxCtrlImpl, x1, y1, x2, y2: float64, flipY = false) =
  CtrlBase(self).init(x1, y1, x2, y2, flipY)
  self.mBorderWidth = 1.0
  self.mBorderExtra = 0.0
  self.mTextThickness = 1.5
  self.mTextHeight = 9.0
  self.mTextWidth = 0.0
  self.mNumItems = 0
  self.mCurItem = -1
  self.mText = initGsvText()
  self.mItems = @[]
  self.mEllipsePoly = initConvStroke(self.mEllipse)
  self.mTextPoly = initConvStroke(self.mText)
  self.mIdx = 0
  self.mVertex = 0
  self.calcRbox()

proc newRboxCtrlImpl*(x1, y1, x2, y2: float64, flipY = false): RboxCtrlImpl =
  new(result)
  result.init(x1, y1, x2, y2, flipY)

proc textThickness*(self: RboxCtrlImpl, t: float64) =
  self.mTextThickness = t

proc curItem*(self: RboxCtrlImpl): int =
  self.mCurItem

proc curItem*(self: RboxCtrlImpl, i: int) =
  self.mCurItem = i

proc calcRbox(self: RboxCtrlImpl) =
  self.mXs1 = self.m.x1 + self.mBorderWidth
  self.mYs1 = self.m.y1 + self.mBorderWidth
  self.mXs2 = self.m.x2 - self.mBorderWidth
  self.mYs2 = self.m.y2 - self.mBorderWidth

proc addItem*(self: RboxCtrlImpl, text: string) =
  self.mItems.add text
  inc self.mNumItems

proc borderWidth*(self: RboxCtrlImpl, t: float64, extra = 0.0) =
  self.mBorderWidth = t
  self.mBorderExtra = extra
  self.calcRbox()

proc textSize*(self: RboxCtrlImpl, h: float64, w = 0.0) =
  self.mTextWidth = w
  self.mTextHeight = h

method inRect*(self: RboxCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and x <= self.m.x2 and y >= self.m.y1 and y <= self.m.y2

method onMouseButtonDown*(self: RboxCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)
  for i in 0.. <self.mNumItems:
    var
      xp = self.mXs1 + self.mDy / 1.3
      yp = self.mYs1 + self.mDy * i.float64 + self.mDy / 1.3
    if calcDistance(x, y, xp, yp) <= self.mTextHeight / 1.5:
      self.mCurItem = i
      return true

  result = false

method onMouseMove*(self: RboxCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  false

method onMouseButtonUp*(self: RboxCtrlImpl, x, y: float64): bool =
  false

method onArrowKeys*(self: RboxCtrlImpl, left, right, down, up: bool): bool =
  if self.mCurItem >= 0:
    if up or right:
      inc self.mCurItem
      if self.mCurItem >= self.mNumItems:
        self.mCurItem = 0
      return true

    if down or left:
      dec self.mCurItem
      if self.mCurItem < 0:
        self.mCurItem = self.mNumItems - 1
      return true
  return false

# Vertex soutce interface
proc numPaths*(self: RboxCtrlImpl): int = 5

proc rewind*(self: RboxCtrlImpl, idx: int) =
  self.mIdx = idx
  self.mDy = self.mTextHeight * 2.0
  self.mDrawItem = 0

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
  of 2:                 # Text
    self.mText.text(self.mItems[0])
    self.mText.startPoint(self.mXs1 + self.mDy * 1.5, self.mYs1 + self.mDy / 2.0)
    self.mText.size(self.mTextHeight, self.mTextWidth)
    self.mTextPoly.width(self.mTextThickness)
    self.mTextPoly.lineJoin(roundJoin)
    self.mTextPoly.lineCap(roundCap)
    self.mTextPoly.rewind(0)
  of 3:                 # Inactive items
    self.mEllipse.init(self.mXs1 + self.mDy / 1.3,
                       self.mYs1 + self.mDy / 1.3,
                       self.mTextHeight / 1.5,
                       self.mTextHeight / 1.5, 32)
    self.mEllipsePoly.width(self.mTextThickness)
    self.mEllipsePoly.rewind(0)
  of 4:                 # Active Item
    if self.mCurItem >= 0:
      self.mEllipse.init(self.mXs1 + self.mDy / 1.3,
                         self.mYs1 + self.mDy * self.mCurItem.float64 + self.mDy / 1.3,
                         self.mTextHeight / 2.0,
                         self.mTextHeight / 2.0, 32)
      self.mEllipse.rewind(0)
  else:
    discard

proc vertex*(self: RboxCtrlImpl, x, y: var float64): uint =
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
    cmd = self.mTextPoly.vertex(x, y)
    if isStop(cmd):
      inc self.mDrawItem
      if self.mDrawItem >= self.mNumItems:
        discard
      else:
        self.mText.text(self.mItems[self.mDrawItem])
        self.mText.start_point(self.mXs1 + self.mDy * 1.5,
                               self.mYs1 + self.mDy * (self.mDrawItem + 1).float64 - self.mDy / 2.0)
        self.mTextPoly.rewind(0)
        cmd = self.mTextPoly.vertex(x, y)
  of 3:
    cmd = self.mEllipsePoly.vertex(x, y)
    if isStop(cmd):
      inc self.mDrawItem
      if self.mDrawItem >= self.mNumItems:
        discard
      else:
        self.mEllipse.init(self.mXs1 + self.mDy / 1.3,
                           self.mYs1 + self.mDy * self.mDrawItem.float64 + self.mDy / 1.3,
                           self.mTextHeight / 1.5,
                           self.mTextHeight / 1.5, 32)
        self.mEllipsePoly.rewind(0)
        cmd = self.mEllipsePoly.vertex(x, y)
  of 4:
    if self.mCurItem >= 0:
      cmd = self.mEllipse.vertex(x, y)
    else:
      cmd = pathCmdStop
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd

type
  RboxCtrl*[ColorT] = ref object of RboxCtrlImpl
    mBackgroundColor: ColorT
    mBorderColor: ColorT
    mTextColor: ColorT
    mInactiveColor: ColorT
    mActiveColor: ColorT
    mColors: array[5, ptr ColorT]

proc newRboxCtrl*[ColorT](x1, y1, x2, y2: float64, flipY = false): RboxCtrl[ColorT] =
  new(result)
  RboxCtrlImpl(result).init(x1, y1, x2, y2, flipY)

  when ColorT is not Rgba:
    result.mBackgroundColor = construct(ColorT, initRgba(1.0, 1.0, 0.9))
    result.mBorderColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mTextColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mInactiveColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mActiveColor = construct(ColorT, initRgba(0.4, 0.0, 0.0))
  else:
    result.mBackgroundColor = initRgba(1.0, 1.0, 0.9)
    result.mBorderColor = initRgba(0.0, 0.0, 0.0)
    result.mTextColor = initRgba(0.0, 0.0, 0.0)
    result.mInactiveColor = initRgba(0.0, 0.0, 0.0)
    result.mActiveColor = initRgba(0.4, 0.0, 0.0)

  result.mColors[0] = result.mBackgroundColor.addr
  result.mColors[1] = result.mBorderColor.addr
  result.mColors[2] = result.mTextColor.addr
  result.mColors[3] = result.mInactiveColor.addr
  result.mColors[4] = result.mActiveColor.addr

proc backgroundColor*[ColorT](self: RboxCtrl[ColorT], c: ColorT) =
  self.mBackgroundColor = c

proc borderColor*[ColorT](self: RboxCtrl[ColorT], c: ColorT) =
  self.mBorderColor = c

proc textColor*[ColorT](self: RboxCtrl[ColorT], c: ColorT) =
  self.mTextColor = c

proc inactiveColor*[ColorT](self: RboxCtrl[ColorT], c: ColorT) =
  self.mInactiveColor = c

proc activeColor*[ColorT](self: RboxCtrl[ColorT], c: ColorT) =
  self.mActiveColor = c

proc color*[ColorT](self: RboxCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
