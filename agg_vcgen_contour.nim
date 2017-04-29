import agg_basics, agg_math_stroke, agg_vertex_sequence, agg_math, agg_array

type
  Status = enum
    initial
    ready
    outline
    outVertices
    endPoly
    stop

  VcgenContour* = object
    mStroker: MathStroke
    mWidth: float64
    mSrcVertices: VertexSequence[VertexDist]
    mOutVertices: PodBVector[PointD]
    mStatus: Status
    mSrcVertex, mOutVertex: int
    mClosed, mOrientation: uint
    mAutoDetect: bool

proc initVcgenContour*(): VcgenContour =
  result.mStroker = initMathStroke()
  result.mWidth = 1
  result.mSrcVertices = initVertexSequence[VertexDist]()
  result.mOutVertices = initPodBVector[PointD]()
  result.mStatus = initial
  result.mSrcVertex = 0
  result.mClosed = 0
  result.mOrientation = 0
  result.mAutoDetect = false

template construct*(x: typedesc[VcgenContour]): untyped = initVcgenContour()

proc lineCap*(self: var VcgenContour, lc: LineCap) = self.mStroker.lineCap(lc)
proc lineJoin*(self: var VcgenContour, lj: LineJoin) = self.mStroker.lineJoin(lj)
proc innerJoin*(self: var VcgenContour, ij: InnerJoin) = self.mStroker.innerJoin(ij)

proc lineCap*(self: VcgenContour): LineCap = self.mStroker.lineCap()
proc lineJoin*(self: VcgenContour): LineJoin = self.mStroker.lineJoin()
proc innerJoin*(self: VcgenContour): InnerJoin = self.mStroker.innerJoin()

proc width*(self: var VcgenContour, w: float64) =
  self.mWidth = w
  self.mStroker.width(w)

proc miterLimit*(self: var VcgenContour, ml: float64) = self.mStroker.miterLimit(ml)
proc miterLimitTheta*(self: var VcgenContour, t: float64) = self.mStroker.miterLimitTheta(t)
proc innerMiterLimit*(self: var VcgenContour, ml: float64) = self.mStroker.innerMiterLimit(ml)
proc approximationScale*(self: var VcgenContour, cas: float64) = self.mStroker.approximationScale(cas)

proc width*(self: VcgenContour): float64 = self.mWidth
proc miterLimit*(self: VcgenContour): float64 = self.mStroker.miterLimit()
proc innerMiterLimit*(self: VcgenContour): float64 = self.mStroker.innerMiterLimit()
proc approximationScale*(self: VcgenContour): float64 = self.mStroker.approximationScale()

proc autoDetectOrientation*(self: var VcgenContour, v: bool) = self.mAutoDetect = v
proc autoDetectOrientation*(self: VcgenContour): bool = self.mAutoDetect

# Generator interface
proc removeAll*(self: var VcgenContour) =
  self.mSrcVertices.removeAll()
  self.mClosed = 0
  self.mOrientation = 0
  self.mStatus = initial

proc addVertex*(self: var VcgenContour, x, y: float64, cmd: uint) =
  self.mStatus = initial
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(VertexDist(x: x, y: y))
  else:
    if isVertex(cmd):
       self.mSrcVertices.add(VertexDist(x: x, y: y))
    else:
      if isEndPoly(cmd):
        self.mClosed = getCloseFlag(cmd)
        if self.mOrientation == pathFlagsNone:
          self.mOrientation = getOrientation(cmd)

# Vertex Source Interface
proc rewind*(self: var VcgenContour, pathId: int) =
  if self.mStatus == initial:
    self.mSrcVertices.close(true)
    if self.mAutoDetect:
      if not isOriented(self.mOrientation):
        if calcPolygonArea(self.mSrcVertices) > 0.0:
          self.mOrientation = pathFlagsCcw
        else:
          self.mOrientation = pathFlagsCw

    if isOriented(self.mOrientation):
      self.mStroker.width(if isCcw(self.mOrientation): self.mWidth else: -self.mWidth)

  self.mStatus = ready
  self.mSrcVertex = 0

proc vertex*(self: var VcgenContour, x, y: var float64): uint =
  var cmd: uint = pathCmdLineTo
  while not isStop(cmd):
    case self.mStatus
    of initial:
      self.rewind(0)
      self.mStatus = ready
    of ready:
      if self.mSrcVertices.len() < 2 + int(self.mClosed != 0):
        cmd = pathCmdStop
        continue

      self.mStatus = outline
      cmd = pathCmdMoveTo
      self.mSrcVertex = 0
      self.mOutVertex = 0
    of outline:
      if self.mSrcVertex >= self.mSrcVertices.len():
        self.mStatus = endPoly
        continue

      self.mStroker.calcJoin(self.mOutVertices,
                          self.mSrcVertices.prev(self.mSrcVertex),
                          self.mSrcVertices.curr(self.mSrcVertex),
                          self.mSrcVertices.next(self.mSrcVertex),
                          self.mSrcVertices.prev(self.mSrcVertex).dist,
                          self.mSrcVertices.curr(self.mSrcVertex).dist)
      inc self.mSrcVertex
      self.mStatus = outVertices
      self.mOutVertex = 0
    of outVertices:
      if self.mOutVertex >= self.mOutVertices.len:
        self.mStatus = outline
      else:
        var c = self.mOutVertices[self.mOutVertex]
        inc self.mOutVertex
        x = c.x
        y = c.y
        return cmd
    of endPoly:
      if self.mClosed == 0: return pathCmdStop
      self.mStatus = stop
      return pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
    of stop:
      return pathCmdStop
    else:
      discard

  result = cmd
