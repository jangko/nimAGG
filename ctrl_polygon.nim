import ctrl_base, agg_basics, agg_conv_stroke, agg_ellipse
import agg_vcgen_stroke, agg_color_rgba, math

type
  SimplePolygonVertexSource* = object
    mPolygon: ptr float64
    mNumPoints: int
    mVertex: int
    mRoundOff: bool
    mClose: bool

proc initSimplePolygonVertexSource*(polygon: ptr float64,
  np: int, roundOff = false, close = true): SimplePolygonVertexSource =
  result.mPolygon   = polygon
  result.mNumPoints = np
  result.mVertex    = 0
  result.mRoundOff  = roundoff
  result.mClose     = close

proc close*(self: var SimplePolygonVertexSource, f: bool) =
  self.mClose = f

proc close*(self: SimplePolygonVertexSource): bool =
  self.mClose

proc rewind*(self: var SimplePolygonVertexSource, idx: int) =
  self.mVertex = 0

proc vertex*(self: var SimplePolygonVertexSource, x, y: var float64): uint =
  if self.mVertex > self.mNumPoints: return pathCmdStop
  if self.mVertex == self.mNumPoints:
    inc self.mVertex
    return pathCmdEndPoly or (if self.mClose: pathFlagsClose else: 0)
  x = self.mPolygon[self.mVertex * 2]
  y = self.mPolygon[self.mVertex * 2 + 1]

  if self.mRoundOff:
    x = math.floor(x) + 0.5
    y = math.floor(y) + 0.5
  inc self.mVertex
  result = if self.mVertex == 1: pathCmdMoveTo else: pathCmdLineTo


type
  PolygonCtrlImpl* = ref object of CtrlBase
    mPolygon: seq[float64]
    mNumPoints: int
    mNode, mEdge: int
    mVs: SimplePolygonVertexSource
    mStroke: ConvStroke[SimplePolygonVertexSource, NullMarkers]
    mEllipse: Ellipse
    mPointRadius: float64
    mStatus: int
    mDx, mDy: float64
    mInPolygonCheck: bool

proc init*(self: PolygonCtrlImpl, np: int, pointRadius = 5.0) =
  CtrlBase(self).init(0, 0, 1, 1, false)
  self.mPolygon = newSeq[float64](np * 2)
  self.mNumPoints = np
  self.mNode = -1
  self.mEdge = -1
  self.mVs = initSimplePolygonVertexSource(self.mPolygon[0].addr, self.mNumPoints, false)
  self.mStroke = initConvStroke(self.mVs)
  self.mPointRadius = pointRadius
  self.mStatus = 0
  self.mDx = 0.0
  self.mDy = 0.0
  self.mInPolygonCheck = true
  self.mStroke.width(1.0)

proc newPolygonCtrlImpl*(np: int, pointRadius = 5.0): PolygonCtrlImpl =
  new(result)
  result.init(np, pointRadius)

proc numPoints*(self: PolygonCtrlImpl): int =
  self.mNumPoints

proc xn*(self: PolygonCtrlImpl, n: int): var float64 =
  self.mPolygon[n * 2]

proc yn*(self: PolygonCtrlImpl, n: int): var float64 =
  self.mPolygon[n * 2 + 1]

proc polygon*(self: PolygonCtrlImpl): ptr float64 =
  self.mPolygon[0].addr

proc lineWidth*(self: PolygonCtrlImpl, w: float64) =
  self.mStroke.width(w)

proc lineWidth*(self: PolygonCtrlImpl): float64 =
  self.mStroke.width()

proc pointRadius*(self: PolygonCtrlImpl, r: float64) =
  self.mPointRadius = r

proc pointRadius*(self: PolygonCtrlImpl): float64 =
  self.mPointRadius

proc inPolygonCheck*(self: PolygonCtrlImpl, f: bool) =
  self.mInPolygonCheck = f

proc inPolygonCheck*(self: PolygonCtrlImpl): bool =
  self.mInPolygonCheck

proc close*(self: PolygonCtrlImpl, f: bool) =
  self.mVs.close(f)

proc close*(self: PolygonCtrlImpl): bool =
  self.mVs.close()

proc numPaths*(self: PolygonCtrlImpl): int = 1

proc rewind*(self: PolygonCtrlImpl, idx: int) =
  self.mStatus = 0
  self.mStroke.rewind(0)

proc vertex*(self: PolygonCtrlImpl, x, y: var float64): uint =
  var
    cmd = pathCmdStop
    r = self.mPointRadius
  if self.mStatus == 0:
    cmd = self.mStroke.vertex(x, y)
    if not isStop(cmd):
      self.transformXY(x, y)
      return cmd
    if self.mNode >= 0 and self.mNode == self.mStatus:
      r *= 1.2
    self.mEllipse.init(self.xn(self.mStatus), self.yn(self.mStatus), r, r, 32)
    inc self.mStatus

  cmd = self.mEllipse.vertex(x, y)
  if not isStop(cmd):
    self.transformXY(x, y)
    return cmd

  if self.mStatus >= self.mNumPoints:
    return pathCmdStop

  if self.mNode >= 0 and self.mNode == self.mStatus:
    r *= 1.2

  self.mEllipse.init(self.xn(self.mStatus), self.yn(self.mStatus), r, r, 32)
  inc self.mStatus

  cmd = self.mEllipse.vertex(x, y)
  if not isStop(cmd):
    self.transformXY(x, y)

  result = cmd

proc checkEdge(self: PolygonCtrlImpl, i: int, x, y: float64): bool =
  result = false
  var
    n1 = i
    n2 = (i + self.mNumPoints - 1) mod self.mNumPoints
    x1 = self.xn(n1)
    y1 = self.yn(n1)
    x2 = self.xn(n2)
    y2 = self.yn(n2)
    dx = x2 - x1
    dy = y2 - y1

  if sqrt(dx*dx + dy*dy) > 0.0000001:
    var
      x3 = x
      y3 = y
      x4 = x3 - dy
      y4 = y3 + dx
      den = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
      u1 = ((x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)) / den
      xi = x1 + u1 * (x2 - x1)
      yi = y1 + u1 * (y2 - y1)

    dx = xi - x
    dy = yi - y

    if (u1 > 0.0) and (u1 < 1.0) and (sqrt(dx*dx + dy*dy) <= self.mPointRadius):
      result = true

proc pointInPolygon(self: PolygonCtrlImpl, tx, ty: float64): bool =
  if self.mNumPoints < 3: return false
  if not self.mInPolygonCheck: return false

  var
    yflag0, yflag1, insideFlag: int
    vtx0, vty0, vtx1, vty1: float64

  vtx0 = self.xn(self.mNumPoints - 1)
  vty0 = self.yn(self.mNumPoints - 1)

  # get test bit for above/below X axis
  yflag0 = int(vty0 >= ty)

  vtx1 = self.xn(0)
  vty1 = self.yn(0)

  insideFlag = 0
  for j in 1..self.mNumPoints:
    yflag1 = int(vty1 >= ty)
    # Check if endpoints straddle (are on opposite sides) of X axis
    # (i.e. the Y's differ) if so, +X ray could intersect this edge.
    # The old test also checked whether the endpoints are both to the
    # right or to the left of the test point.  However, given the faster
    # intersection point computation used below, this test was found to
    # be a break-even proposition for most polygons and a loser for
    # triangles (where 50mod or more of the edges which survive this test
    # will cross quadrants and so have to have the X intersection computed
    # anyway).  I credit Joseph Samosky with inspiring me to try dropping
    # the "both left or both right" part of my code.
    if yflag0 != yflag1:
      # Check intersection of pgon segment with +X ray.
      # Note if >= point's X; if so, the ray hits it.
      # The division operation is aproced for the ">=" test by checking
      # the sign of the first vertex wrto the test point; idea inspired
      # by Joseph Samosky's and Mark Haigh-Hutchinson's different
      # polygon inclusion tests.
      if int((vty1-ty) * (vtx0-vtx1) >= (vtx1-tx) * (vty0-vty1)) == yflag1:
        insideFlag = insideFlag xor 1

    # Move to the next pair of vertices, retaining info as possible.
    yflag0 = yflag1
    vtx0 = vtx1
    vty0 = vty1

    let k = if j >= self.mNumPoints: j - self.mNumPoints else: j
    vtx1 = self.xn(k)
    vty1 = self.yn(k)
  result = insideFlag != 0

method inRect*(self: PolygonCtrlImpl, x, y: float64): bool =
  return false

method onMouseButtonDown*(self: PolygonCtrlImpl, x, y: float64): bool =
  var
    x = x
    y = y
  result = false
  self.mNode = -1
  self.mEdge = -1
  self.inverseTransformXY(x, y)
  for i in 0.. <self.mNumPoints:
    if sqrt( (x-self.xn(i)) * (x-self.xn(i)) + (y-self.yn(i)) * (y-self.yn(i)) ) < self.mPointRadius:
      self.mDx = x - self.xn(i)
      self.mDy = y - self.yn(i)
      self.mNode = i
      result = true
      break

  if not result:
    for i in 0.. <self.mNumPoints:
      if self.checkEdge(i, x, y):
        self.mDx = x
        self.mDy = y
        self.mEdge = i
        result = true
        break

  if not result:
    if self.pointInPolygon(x, y):
      self.mDx = x
      self.mDy = y
      self.mNode = self.mNumPoints
      result = true

method onMouseMove*(self: PolygonCtrlImpl, x, y: float64, buttonFlag: bool): bool =
  result = false
  var
    x = x
    y = y
    dx, dy: float64

  self.inverseTransformXY(x, y)
  if self.mNode == self.mNumPoints:
    dx = x - self.mDx
    dy = y - self.mDy
    for i in 0.. <self.mNumPoints:
      self.xn(i) += dx
      self.yn(i) += dy
    self.mDx = x
    self.mDy = y
    result = true
  else:
    if self.mEdge >= 0:
      var
        n1 = self.mEdge
        n2 = (n1 + self.mNumPoints - 1) mod self.mNumPoints
      dx = x - self.mDx
      dy = y - self.mDy
      self.xn(n1) += dx
      self.yn(n1) += dy
      self.xn(n2) += dx
      self.yn(n2) += dy
      self.mDx = x
      self.mDy = y
      result = true
    else:
      if self.mNode >= 0:
        self.xn(self.mNode) = x - self.mDx
        self.yn(self.mNode) = y - self.mDy
        result = true

method onMouseButtonUp*(self: PolygonCtrlImpl, x, y: float64): bool =
  result = (self.mNode >= 0) or (self.mEdge >= 0)
  self.mNode = -1
  self.mEdge = -1

method onArrowKeys*(self: PolygonCtrlImpl, left, right, down, up: bool): bool =
  return false

type
  PolygonCtrl*[ColorT] = ref object of PolygonCtrlImpl
    mColor: ColorT

proc newPolygonCtrl*[ColorT](np: int, pointRadius = 5.0): PolygonCtrl[ColorT] =
  new(result)
  PolygonCtrlImpl(result).init(np, pointRadius)
  when ColorT is not Rgba:
    result.mColor = construct(ColorT, initRgba(0.0, 0.0, 0.0))
  else:
    result.mColor = initRgba(0.0, 0.0, 0.0)

proc lineColor*[ColorT](self: PolygonCtrl[ColorT], c: ColorT) =
  self.mColor = c

proc color*[ColorT](self: PolygonCtrl[ColorT], i: int): ColorT =
  self.mColor
