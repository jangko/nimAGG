import agg_basics, agg_vertex_sequence

type
  Status = enum
    initial
    ready
    polygon
    ctrlB
    ctrlE
    ctrl1
    ctrl2
    endPoly
    stop

  VcgenSmoothPoly1* = object
    mSrcVertices: VertexSequence[VertexDist]
    mSmoothValue: float64
    mClosed: uint
    mStatus: Status
    mSrcVertex: int
    mCtrl1X, mCtrl1Y, mCtrl2X, mCtrl2Y: float64

proc initVcgenSmoothPoly1*(): VcgenSmoothPoly1 =
  result.mSrcVertices = initVertexSequence[VertexDist]()
  result.mSmoothValue = 0.5
  result.mClosed = 0
  result.mStatus = initial
  result.mSrcVertex = 0

template construct*(s: typedesc[VcgenSmoothPoly1]): untyped = initVcgenSmoothPoly1()

proc calculate(self: var VcgenSmoothPoly1, v0, v1, v2, v3: var VertexDist) =
  var
    k1 = v0.dist / (v0.dist + v1.dist)
    k2 = v1.dist / (v1.dist + v2.dist)

    xm1 = v0.x + (v2.x - v0.x) * k1
    ym1 = v0.y + (v2.y - v0.y) * k1
    xm2 = v1.x + (v3.x - v1.x) * k2
    ym2 = v1.y + (v3.y - v1.y) * k2

  self.mCtrl1X = v1.x + self.mSmoothValue * (v2.x - xm1)
  self.mCtrl1Y = v1.y + self.mSmoothValue * (v2.y - ym1)
  self.mCtrl2X = v2.x + self.mSmoothValue * (v1.x - xm2)
  self.mCtrl2Y = v2.y + self.mSmoothValue * (v1.y - ym2)

proc smoothValue*(self: var VcgenSmoothPoly1, v: float64) = self.mSmoothValue = v * 0.5
proc smoothValue*(self: VcgenSmoothPoly1): float64 = self.mSmoothValue * 2.0

# Vertex Generator Interface
proc removeAll*(self: var VcgenSmoothPoly1) =
  self.mSrcVertices.removeAll()
  self.mClosed = 0
  self.mStatus = initial

proc addVertex*(self: var VcgenSmoothPoly1, x, y: float64, cmd: uint) =
  self.mStatus = initial
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(VertexDist(x: x, y: y))
  else:
    if isVertex(cmd):
      self.mSrcVertices.add(VertexDist(x: x, y: y))
    else:
      self.mClosed = getCloseFlag(cmd)

# Vertex Source Interface
proc rewind*(self: var VcgenSmoothPoly1, pathId: int) =
  if self.mStatus == initial:
    self.mSrcVertices.close(self.mClosed != 0)
  self.mStatus = ready
  self.mSrcVertex = 0

proc vertex*(self: var VcgenSmoothPoly1, x, y: var float64): uint =
  var cmd: uint = pathCmdLineTo
  while not isStop(cmd):
    case self.mStatus
    of initial:
      self.rewind(0)
      self.mStatus = ready
    of ready:
      if self.mSrcVertices.size() <  2:
        cmd = pathCmdStop
        continue

      if self.mSrcVertices.size() == 2:
        x = self.mSrcVertices[self.mSrcVertex].x
        y = self.mSrcVertices[self.mSrcVertex].y
        inc self.mSrcVertex
        if self.mSrcVertex == 1: return pathCmdMoveTo
        if self.mSrcVertex == 2: return pathCmdLineTo
        cmd = pathCmdStop;
        continue

      cmd = pathCmdMoveTo
      self.mStatus = polygon
      self.mSrcVertex = 0
    of polygon:
      if self.mClosed != 0:
        if self.mSrcVertex >= self.mSrcVertices.size():
          x = self.mSrcVertices[0].x
          y = self.mSrcVertices[0].y
          self.mStatus = endPoly
          return pathCmdCurve4
      else:
        if self.mSrcVertex >= self.mSrcVertices.size() - 1:
          x = self.mSrcVertices[self.mSrcVertices.size() - 1].x
          y = self.mSrcVertices[self.mSrcVertices.size() - 1].y
          self.mStatus = endPoly
          return pathCmdCurve3

      self.calculate(self.mSrcVertices.prev(self.mSrcVertex),
                     self.mSrcVertices.curr(self.mSrcVertex),
                     self.mSrcVertices.next(self.mSrcVertex),
                     self.mSrcVertices.next(self.mSrcVertex + 1))

      x = self.mSrcVertices[self.mSrcVertex].x
      y = self.mSrcVertices[self.mSrcVertex].y
      inc self.mSrcVertex

      if self.mClosed != 0:
        self.mStatus = ctrl1
        return if self.mSrcVertex == 1: pathCmdMoveTo else: pathCmdCurve4
      else:
        if self.mSrcVertex == 1:
          self.mStatus = ctrlB
          return pathCmdMoveTo

        if self.mSrcVertex >= self.mSrcVertices.size() - 1:
          self.mStatus = ctrlE
          return pathCmdCurve3

        self.mStatus = ctrl1
        return pathCmdCurve4
    of ctrlB:
      x = self.mCtrl2X
      y = self.mCtrl2Y
      self.mStatus = polygon
      return pathCmdCurve3
    of ctrlE:
      x = self.mCtrl1X
      y = self.mCtrl1Y
      self.mStatus = polygon
      return pathCmdCurve3
    of ctrl1:
      x = self.mCtrl1X
      y = self.mCtrl1Y
      self.mStatus = ctrl2
      return pathCmdCurve4
    of ctrl2:
      x = self.mCtrl2X
      y = self.mCtrl2Y
      self.mStatus = polygon
      return pathCmdCurve4
    of endPoly:
      self.mStatus = stop
      return pathCmdEndPoly or self.mClosed
    of stop:
      return pathCmdStop
    else:
      discard

  result = cmd









