import agg_math, agg_ellipse, agg_trans_affine, agg_color_rgba
import agg_conv_stroke, agg_conv_curve, ctrl_polygon
import agg_basics, agg_curves, ctrl_base

export ctrl_base, agg_curves

type
  BezierCtrlImpl* = ref object of CtrlBase
    mCurve: Curve4
    mEllipse: Ellipse
    mStroke: ConvStroke[Curve4, NullMarkers]
    mPoly: PolygonCtrlImpl
    mIdx: int

proc init(self: BezierCtrlImpl) =
  CtrlBase(self).init(0,0,1,1,false)
  self.mCurve  = initCurve4()
  self.mStroke = initConvStroke(self.mCurve)
  self.mPoly   = newPolygonCtrlImpl(4, 5.0)
  self.mIdx    = 0
  self.mPoly.inPolygonCheck(false)
  self.mPoly.xn(0) = 100.0
  self.mPoly.yn(0) =   0.0
  self.mPoly.xn(1) = 100.0
  self.mPoly.yn(1) =  50.0
  self.mPoly.xn(2) =  50.0
  self.mPoly.yn(2) = 100.0
  self.mPoly.xn(3) =   0.0
  self.mPoly.yn(3) = 100.0


proc newBezierCtrlImpl*(): BezierCtrlImpl =
  new(result)
  result.init()

proc curve*(self: BezierCtrlImpl): var Curve4 =
  self.mCurve.init(self.mPoly.xn(0), self.mPoly.yn(0),
                   self.mPoly.xn(1), self.mPoly.yn(1),
                   self.mPoly.xn(2), self.mPoly.yn(2),
                   self.mPoly.xn(3), self.mPoly.yn(3))
  self.mCurve

proc curve*(self: BezierCtrlImpl, x1, y1, x2, y2, x3, y3, x4, y4: float64) =
  self.mPoly.xn(0) = x1
  self.mPoly.yn(0) = y1
  self.mPoly.xn(1) = x2
  self.mPoly.yn(1) = y2
  self.mPoly.xn(2) = x3
  self.mPoly.yn(2) = y3
  self.mPoly.xn(3) = x4
  self.mPoly.yn(3) = y4
  discard self.curve()

proc x1*(self: BezierCtrlImpl): float64 = self.mPoly.xn(0)
proc y1*(self: BezierCtrlImpl): float64 = self.mPoly.yn(0)
proc x2*(self: BezierCtrlImpl): float64 = self.mPoly.xn(1)
proc y2*(self: BezierCtrlImpl): float64 = self.mPoly.yn(1)
proc x3*(self: BezierCtrlImpl): float64 = self.mPoly.xn(2)
proc y3*(self: BezierCtrlImpl): float64 = self.mPoly.yn(2)
proc x4*(self: BezierCtrlImpl): float64 = self.mPoly.xn(3)
proc y4*(self: BezierCtrlImpl): float64 = self.mPoly.yn(3)

proc x1*(self: BezierCtrlImpl, x: float64) = self.mPoly.xn(0) = x
proc y1*(self: BezierCtrlImpl, y: float64) = self.mPoly.yn(0) = y
proc x2*(self: BezierCtrlImpl, x: float64) = self.mPoly.xn(1) = x
proc y2*(self: BezierCtrlImpl, y: float64) = self.mPoly.yn(1) = y
proc x3*(self: BezierCtrlImpl, x: float64) = self.mPoly.xn(2) = x
proc y3*(self: BezierCtrlImpl, y: float64) = self.mPoly.yn(2) = y
proc x4*(self: BezierCtrlImpl, x: float64) = self.mPoly.xn(3) = x
proc y4*(self: BezierCtrlImpl, y: float64) = self.mPoly.yn(3) = y

proc lineWidth*(self: BezierCtrlImpl, w: float64) = self.mStroke.width(w)
proc lineWidth*(self: BezierCtrlImpl): float64 = self.mStroke.width()

proc pointRadius*(self: BezierCtrlImpl, r: float64) = self.mPoly.pointRadius(r)
proc pointRadius*(self: BezierCtrlImpl): float64 = self.mPoly.pointRadius()

method inRect*(self: BezierCtrlImpl, x, y: float64): bool =
  return false

method onMouseButtonDown*(self: BezierCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  self.mPoly.onMouseButtonDown(x, y)

method onMouseMove*(self: BezierCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  self.mPoly.onMouseMove(x, y, buttonFlag)

method onMouseButtonUp*(self: BezierCtrlImpl, x, y: float64): bool =
  self.mPoly.onMouseButtonUp(x, y)

method onArrowKeys*(self: BezierCtrlImpl, left, right, down, up: bool): bool =
  self.mPoly.onArrowKeys(left, right, down, up)

# Vertex source interface
proc numPaths*(self: BezierCtrlImpl): int =  7

proc rewind*(self: BezierCtrlImpl, idx: int) =
  self.mIdx = idx

  self.mCurve.approximationScale(self.scale())
  case idx
  of 0: # Control line 1
    self.mCurve.init(self.mPoly.xn(0),  self.mPoly.yn(0),
                    (self.mPoly.xn(0) + self.mPoly.xn(1)) * 0.5,
                    (self.mPoly.yn(0) + self.mPoly.yn(1)) * 0.5,
                    (self.mPoly.xn(0) + self.mPoly.xn(1)) * 0.5,
                    (self.mPoly.yn(0) + self.mPoly.yn(1)) * 0.5,
                     self.mPoly.xn(1),  self.mPoly.yn(1))
    self.mStroke.rewind(0)
  of 1: # Control line 2
    self.mCurve.init(self.mPoly.xn(2),  self.mPoly.yn(2),
                    (self.mPoly.xn(2) + self.mPoly.xn(3)) * 0.5,
                    (self.mPoly.yn(2) + self.mPoly.yn(3)) * 0.5,
                    (self.mPoly.xn(2) + self.mPoly.xn(3)) * 0.5,
                    (self.mPoly.yn(2) + self.mPoly.yn(3)) * 0.5,
                     self.mPoly.xn(3),  self.mPoly.yn(3))
    self.mStroke.rewind(0)
  of 2: # Curve itself
    self.mCurve.init(self.mPoly.xn(0), self.mPoly.yn(0),
                     self.mPoly.xn(1), self.mPoly.yn(1),
                     self.mPoly.xn(2), self.mPoly.yn(2),
                     self.mPoly.xn(3), self.mPoly.yn(3))
    self.mStroke.rewind(0)
  of 3: # Point 1
    self.mEllipse.init(self.mPoly.xn(0), self.mPoly.yn(0), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  of 4: # Point 2
    self.mEllipse.init(self.mPoly.xn(1), self.mPoly.yn(1), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  of 5: # Point 3
    self.mEllipse.init(self.mPoly.xn(2), self.mPoly.yn(2), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  of 6: # Point 4
    self.mEllipse.init(self.mPoly.xn(3), self.mPoly.yn(3), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  else:
    discard

proc vertex*(self: BezierCtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdStop
  case self.mIdx
  of 0, 1, 2:
    cmd = self.mStroke.vertex(x, y)
  of 3, 4, 5, 6, 7:
    cmd = self.mEllipse.vertex(x, y)
  else:
    discard

  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd

type
  BezierCtrl*[ColorT] = ref object of BezierCtrlImpl
    mColor: ColorT

proc newBezierCtrl*[ColorT](): BezierCtrl[ColorT] =
  new(result)
  BezierCtrlImpl(result).init()
  when ColorT is not Rgba:
    result.mColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
  else:
    result.mColor = initRgba(0.0, 0.0, 0.0)

proc lineColor*[ColorT](self: BezierCtrl[ColorT], c: ColorT) =
  self.mColor = c

proc color*[ColorT](self: BezierCtrl[ColorT], i: int): ColorT =
  self.mColor


type
  Curve3CtrlImpl* = ref object of CtrlBase
    mCurve: Curve3
    mEllipse: Ellipse
    mStroke: ConvStroke[Curve3, NullMarkers]
    mPoly: PolygonCtrlImpl
    mIdx: int

proc init(self: Curve3CtrlImpl) =
  CtrlBase(self).init(0,0,1,1,false)
  self.mStroke = initConvStroke(self.mCurve)
  self.mPoly = newPolygonCtrlImpl(3, 5.0)
  self.mIdx = 0
  self.mPoly.inPolygonCheck(false)
  self.mPoly.xn(0) = 100.0
  self.mPoly.yn(0) =   0.0
  self.mPoly.xn(1) = 100.0
  self.mPoly.yn(1) =  50.0
  self.mPoly.xn(2) =  50.0
  self.mPoly.yn(2) = 100.0

proc newCurve3CtrlImpl*(): Curve3CtrlImpl =
  new(result)
  result.init()

proc curve*(self: Curve3CtrlImpl): var Curve3 =
  self.mCurve.init(self.mPoly.xn(0), self.mPoly.yn(0),
                   self.mPoly.xn(1), self.mPoly.yn(1),
                   self.mPoly.xn(2), self.mPoly.yn(2))
  self.mCurve

proc curve*(self: Curve3CtrlImpl, x1, y1, x2, y2, x3, y3: float64) =
  self.mPoly.xn(0) = x1
  self.mPoly.yn(0) = y1
  self.mPoly.xn(1) = x2
  self.mPoly.yn(1) = y2
  self.mPoly.xn(2) = x3
  self.mPoly.yn(2) = y3
  discard self.curve()

proc x1*(self: Curve3CtrlImpl): float64 = self.mPoly.xn(0)
proc y1*(self: Curve3CtrlImpl): float64 = self.mPoly.yn(0)
proc x2*(self: Curve3CtrlImpl): float64 = self.mPoly.xn(1)
proc y2*(self: Curve3CtrlImpl): float64 = self.mPoly.yn(1)
proc x3*(self: Curve3CtrlImpl): float64 = self.mPoly.xn(2)
proc y3*(self: Curve3CtrlImpl): float64 = self.mPoly.yn(2)

proc x1*(self: Curve3CtrlImpl, x: float64) = self.mPoly.xn(0) = x
proc y1*(self: Curve3CtrlImpl, y: float64) = self.mPoly.yn(0) = y
proc x2*(self: Curve3CtrlImpl, x: float64) = self.mPoly.xn(1) = x
proc y2*(self: Curve3CtrlImpl, y: float64) = self.mPoly.yn(1) = y
proc x3*(self: Curve3CtrlImpl, x: float64) = self.mPoly.xn(2) = x
proc y3*(self: Curve3CtrlImpl, y: float64) = self.mPoly.yn(2) = y

proc lineWidth*(self: Curve3CtrlImpl, w: float64) = self.mStroke.width(w)
proc lineWidth*(self: Curve3CtrlImpl): float64 = self.mStroke.width()

proc pointRadius*(self: Curve3CtrlImpl, r: float64) = self.mPoly.pointRadius(r)
proc pointRadius*(self: Curve3CtrlImpl): float64 = self.mPoly.pointRadius()

method inRect*(self: Curve3CtrlImpl, x, y: float64): bool =
  false

method onMouseButtonDown*(self: Curve3CtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  self.inverseTransformXY(x, y)
  self.mPoly.onMouseButtonDown(x, y)

method onMouseMove*(self: Curve3CtrlImpl, x, y: float64, buttonFlag: bool): bool =
  var
    x = x
    y = y

  self.inverseTransformXY(x, y)
  self.mPoly.onMouseMove(x, y, buttonFlag)

method onMouseButtonUp*(self: Curve3CtrlImpl, x, y: float64): bool =
  self.mPoly.onMouseButtonUp(x, y)

method onArrowKeys*(self: Curve3CtrlImpl, left, right, down, up: bool): bool =
  self.mPoly.onArrowKeys(left, right, down, up)

# Vertex source interface
proc numPaths*(self: Curve3CtrlImpl): int =  6

proc rewind*(self: Curve3CtrlImpl, idx: int) =
  self.mIdx = idx

  case idx
  of 0:                 # Control line
    self.mCurve.init(self.mPoly.xn(0),  self.mPoly.yn(0),
                    (self.mPoly.xn(0) + self.mPoly.xn(1)) * 0.5,
                    (self.mPoly.yn(0) + self.mPoly.yn(1)) * 0.5,
                     self.mPoly.xn(1),  self.mPoly.yn(1))
    self.mStroke.rewind(0)
  of 1:                 # Control line 2
    self.mCurve.init(self.mPoly.xn(1),  self.mPoly.yn(1),
                    (self.mPoly.xn(1) + self.mPoly.xn(2)) * 0.5,
                    (self.mPoly.yn(1) + self.mPoly.yn(2)) * 0.5,
                     self.mPoly.xn(2),  self.mPoly.yn(2))
    self.mStroke.rewind(0)
  of 2:                 # Curve itself
    self.mCurve.init(self.mPoly.xn(0), self.mPoly.yn(0),
                     self.mPoly.xn(1), self.mPoly.yn(1),
                     self.mPoly.xn(2), self.mPoly.yn(2))
    self.mStroke.rewind(0)
  of 3:                 # Point 1
    self.mEllipse.init(self.mPoly.xn(0), self.mPoly.yn(0), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  of 4:                 # Point 2
    self.mEllipse.init(self.mPoly.xn(1), self.mPoly.yn(1), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  of 5:                 # Point 3
    self.mEllipse.init(self.mPoly.xn(2), self.mPoly.yn(2), self.pointRadius(), self.pointRadius(), 20)
    self.mEllipse.rewind(0)
  else:
    discard

proc vertex*(self: Curve3CtrlImpl, x, y: var float64): uint =
  var cmd = pathCmdStop
  case self.mIdx
  of 0, 1, 2:
    cmd = self.mStroke.vertex(x, y)
  of 3, 4, 5, 6:
    cmd = self.mEllipse.vertex(x, y)
  else:
    discard

  if not isStop(cmd):
    self.transformXY(x, y)
  result = cmd

type
  Curve3Ctrl*[ColorT] = ref object of Curve3CtrlImpl
    mColor: ColorT

proc newCurve3Ctrl*[ColorT](): Curve3Ctrl[ColorT] =
  new(result)
  Curve3CtrlImpl(result).init()
  when ColorT is not Rgba:
    result.mColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
  else:
    result.mColor = initRgba(0.0, 0.0, 0.0)

proc lineColor*[ColorT](self: Curve3Ctrl[ColorT], c: ColorT) =
  self.mColor = c

proc color*[ColorT](self: Curve3Ctrl[ColorT], i: int): ColorT =
  self.mColor