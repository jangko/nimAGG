import agg_basics, agg_conv_stroke, agg_gsv_text, agg_trans_affine
import agg_color_rgba, ctrl_base

type
  CboxCtrlImpl* = ref object of CtrlBase
    mTextThickness: float64
    mTextHeight: float64
    mTextWidth: float64
    mLabel: string
    mStatus: bool
    mVx, mVy: array[32, float64]
    mText: GsvText
    mTextPoly: ConvStroke[GsvText, NullMarkers]
    mIdx: int
    mVertex: int

proc init(self: CboxCtrlImpl, x, y: float64, label: string, flipY = false) =
  CtrlBase(self).init(x, y, x + 9.0 * 1.5, y + 9.0 * 1.5, flipY)
  self.mTextThickness = 1.5
  self.mTextHeight = 9.0
  self.mTextWidth = 0.0
  self.mStatus = false
  self.mText = initGsvText()
  self.mTextPoly = initConvStroke(self.mText)
  self.mLabel = label

proc newCboxCtrlImpl*(x, y: float64, label: string, flipY = false): CboxCtrlImpl =
  new(result)
  result.init(x, y, label, flipY)

proc textThickness*(self: CboxCtrlImpl, t: float64) =
  self.mTextThickness = t

proc label*(self: CboxCtrlImpl): string =
  self.mLabel

proc status*(self: CboxCtrlImpl): bool =
  self.mStatus

proc status*(self: CboxCtrlImpl, st: bool) =
  self.mStatus = st

proc textSize*(self: CboxCtrlImpl, h: float64, w = 0.0) =
  self.mTextWidth = w
  self.mTextHeight = h

proc label*(self: CboxCtrlImpl, s: string) =
  self.mLabel = s

method onMouseButtonDown*(self: CboxCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  if x >= self.m.x1 and y >= self.m.y1 and x <= self.m.x2 and y <= self.m.y2:
    self.mStatus = not self.mStatus
    return true
  result = false

method onMouseMove*(self: CboxCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  false

method inRect*(self: CboxCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  result = x >= self.m.x1 and y >= self.m.y1 and x <= self.m.x2 and y <= self.m.y2

method onMouseButtonUp*(self: CboxCtrlImpl, x, y: float64): bool =
  false

method onArrowKeys*(self: CboxCtrlImpl, left, right, down, up: bool): bool =
  false

# Vertex soutce interface
proc numPaths*(self: CboxCtrlImpl): int = 3

proc rewind*(self: CboxCtrlImpl, idx: int) =
  self.mIdx = idx

  var
    d2, t: float64

  case idx
  of 0:                 # Border
    self.mVertex = 0
    self.mVx[0] = self.m.x1
    self.mVy[0] = self.m.y1
    self.mVx[1] = self.m.x2
    self.mVy[1] = self.m.y1
    self.mVx[2] = self.m.x2
    self.mVy[2] = self.m.y2
    self.mVx[3] = self.m.x1
    self.mVy[3] = self.m.y2
    self.mVx[4] = self.m.x1 + self.mTextThickness
    self.mVy[4] = self.m.y1 + self.mTextThickness
    self.mVx[5] = self.m.x1 + self.mTextThickness
    self.mVy[5] = self.m.y2 - self.mTextThickness
    self.mVx[6] = self.m.x2 - self.mTextThickness
    self.mVy[6] = self.m.y2 - self.mTextThickness
    self.mVx[7] = self.m.x2 - self.mTextThickness
    self.mVy[7] = self.m.y1 + self.mTextThickness
  of 1:                 # Text
    self.mText.text(self.mLabel)
    self.mText.start_point(self.m.x1 + self.mTextHeight * 2.0, self.m.y1 + self.mTextHeight / 5.0)
    self.mText.size(self.mTextHeight, self.mTextWidth)
    self.mTextPoly.width(self.mTextThickness)
    self.mTextPoly.lineJoin(roundJoin)
    self.mTextPoly.lineCap(roundCap)
    self.mTextPoly.rewind(0)
  of 2:                 # Active item
    self.mVertex = 0
    d2 = (self.m.y2 - self.m.y1) / 2.0
    t = self.mTextThickness * 1.5
    self.mVx[0] = self.m.x1 + self.mTextThickness
    self.mVy[0] = self.m.y1 + self.mTextThickness
    self.mVx[1] = self.m.x1 + d2
    self.mVy[1] = self.m.y1 + d2 - t
    self.mVx[2] = self.m.x2 - self.mTextThickness
    self.mVy[2] = self.m.y1 + self.mTextThickness
    self.mVx[3] = self.m.x1 + d2 + t
    self.mVy[3] = self.m.y1 + d2
    self.mVx[4] = self.m.x2 - self.mTextThickness
    self.mVy[4] = self.m.y2 - self.mTextThickness
    self.mVx[5] = self.m.x1 + d2
    self.mVy[5] = self.m.y1 + d2 + t
    self.mVx[6] = self.m.x1 + self.mTextThickness
    self.mVy[6] = self.m.y2 - self.mTextThickness
    self.mVx[7] = self.m.x1 + d2 - t
    self.mVy[7] = self.m.y1 + d2
  else:
    discard

proc vertex*(self: CboxCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdLineTo
  case self.mIdx
  of 0:
    if self.mVertex == 0 or self.mVertex == 4: cmd = pathCmdMoveTo
    if self.mVertex >= 8: cmd = pathCmdStop
    x = self.mVx[self.mVertex]
    y = self.mVy[self.mVertex]
    inc self.mVertex
  of 1:
    cmd = self.mTextPoly.vertex(x, y)
  of 2:
    if self.mStatus:
      if self.mVertex == 0: cmd = pathCmdMoveTo
      if self.mVertex >= 8: cmd = pathCmdStop
      x = self.mVx[self.mVertex]
      y = self.mVy[self.mVertex]
      inc self.mVertex
    else:
      cmd = pathCmdStop
  else:
    cmd = pathCmdStop

  if not isStop(cmd):
    self.transformXY(x, y)
  result = cmd


type
  CboxCtrl*[ColorT] = ref object of CboxCtrlImpl
    mTextColor: ColorT
    mInactiveColor: ColorT
    mActiveColor: ColorT
    mColors: array[3, ptr ColorT]

proc initCboxCtrl*[ColorT](x, y: float64, label: string, flipY = false): CboxCtrl[ColorT] =
  new(result)
  CboxCtrlImpl(result).init(x, y, label, flipY)

  when ColorT is not Rgba:
    result.mTextColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
    result.mInactiveColor = construct(ColorT,initRgba(0.0, 0.0, 0.0))
    result.mActiveColor = construct(ColorT,initRgba(0.4, 0.0, 0.0) )
  else:
    result.mTextColor = initRgba(0.0, 0.0, 0.0)
    result.mInactiveColor = initRgba(0.0, 0.0, 0.0)
    result.mActiveColor = initRgba(0.4, 0.0, 0.0)

  result.mColors[0] = result.mInactiveColor.addr
  result.mColors[1] = result.mTextColor.addr
  result.mColors[2] = result.mActiveColor.addr

proc textColor*[ColorT](self: CboxCtrl[ColorT], c: ColorT) =
  self.mTextColor = c

proc inactiveColor*[ColorT](self: CboxCtrl[ColorT], c: ColorT) =
  self.mInactiveColor = c

proc activeColor*[ColorT](self: CboxCtrl[ColorT], c: ColorT) =
  self.mActiveColor = c

proc color*[ColorT](self: CboxCtrl[ColorT], i: int): ColorT =
  self.mColors[i][]
