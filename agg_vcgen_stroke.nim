import agg_basics, agg_math_stroke, agg_array, agg_vertex_sequence, agg_shorten_path, strutils

type
  Status = enum
    initial
    ready
    cap1
    cap2
    outline1
    closeFirst
    outline2
    outVertices
    end_poly1
    end_poly2
    stop

  CoordStorage = PodBVector[PointD]
  VertexStorage = VertexSequence[VertexDist]

  VcgenStroke* = object
    mStroker: MathStroke
    mSrcVertices: VertexStorage
    mOutVertices: CoordStorage
    mShorten: float64
    mClosed: uint
    mStatus: Status
    mPrevStatus: Status
    mSrcVertex: int
    mOutVertex: int

proc initVcgenStroke*(): VcgenStroke =
  result.mStroker = initMathStroke()
  result.mSrcVertices = initVertexSequence[VertexDist]()
  result.mOutVertices = initPodBVector[PointD]()
  result.mShorten = 0.0
  result.mClosed = 0
  result.mStatus = initial
  result.mSrcVertex = 0
  result.mOutVertex = 0

template construct*(x: typedesc[VcgenStroke]): untyped = initVcgenStroke()

proc lineCap*(self: var VcgenStroke, lc: LineCap) = self.mStroker.lineCap(lc)
proc lineJoin*(self: var VcgenStroke, lj: LineJoin) = self.mStroker.lineJoin(lj)
proc innerJoin*(self: var VcgenStroke, ij: InnerJoin) = self.mStroker.innerJoin(ij)

proc lineCap*(self: VcgenStroke): LineCap = self.mStroker.lineCap
proc lineJoin*(self: VcgenStroke): LineJoin = self.mStroker.lineJoin
proc innerJoin*(self: VcgenStroke): InnerJoin = self.mStroker.innerJoin

proc width*(self: var VcgenStroke, w: float64) = self.mStroker.width(w)
proc miterLimit*(self: var VcgenStroke, ml: float64) = self.mStroker.miterLimit(ml)
proc miterLimitTheta*(self: var VcgenStroke, t: float64) = self.mStroker.miterLimitTheta(t)
proc innerMiterLimit*(self: var VcgenStroke, ml: float64) = self.mStroker.innerMiterLimit(ml)
proc approximationCcale*(self: var VcgenStroke, asc: float64) = self.mStroker.approximationScale(asc)

proc width*(self: VcgenStroke): float64 = self.mStroker.width()
proc miterLimit*(self: VcgenStroke): float64 = self.mStroker.miterLimit()
proc innerMiterLimit*(self: VcgenStroke): float64 = self.mStroker.innerMiterLimit()
proc approximationScale*(self: VcgenStroke): float64 = self.mStroker.approximationScale()

proc shorten*(self: var VcgenStroke, s: float64) = self.mShorten = s
proc shorten*(self: VcgenStroke): float64 = self.mShorten

proc removeAll*(self: var VcgenStroke) =
  self.mSrcVertices.removeAll()
  self.mClosed = 0
  self.mStatus = initial

proc addVertex*(self: var VcgenStroke, x, y: float64, cmd: uint) =
  self.mStatus = initial
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(initVertexDist(x, y))
  else:
   if isVertex(cmd):
     self.mSrcVertices.add(initVertexDist(x, y))
   else:
     self.mClosed = getCloseFlag(cmd)

proc rewind*(self: var VcgenStroke, pathId: int) =
  if self.mStatus == initial:
    self.mSrcVertices.close(self.mClosed != 0)
    shortenPath(self.mSrcVertices, self.mShorten, self.mClosed)
    if self.mSrcVertices.len() < 3: self.mClosed = 0

  self.mStatus = ready
  self.mSrcVertex = 0
  self.mOutVertex = 0

proc vertex*(self: var VcgenStroke, x, y: var float64): uint =
  var cmd: uint = pathCmdLineTo

  while not isStop(cmd):
    case self.mStatus
    of initial:
      self.rewind(0)
      self.mStatus = ready
    of ready:
      if self.mSrcVertices.len() < (2 + int(self.mClosed != 0)):
        cmd = pathCmdStop
      else:
        self.mStatus = if self.mClosed != 0: outline1 else: cap1
        cmd = pathCmdMoveTo
        self.mSrcVertex = 0
        self.mOutVertex = 0
    of cap1:
      self.mStroker.calcCap(self.mOutVertices,
                          self.mSrcVertices[0],
                          self.mSrcVertices[1],
                          self.mSrcVertices[0].dist)
      self.mSrcVertex = 1
      self.mPrevStatus = outline1
      self.mStatus = outVertices
      self.mOutVertex = 0
    of cap2:
      self.mStroker.calcCap(self.mOutVertices,
                          self.mSrcVertices[self.mSrcVertices.len() - 1],
                          self.mSrcVertices[self.mSrcVertices.len() - 2],
                          self.mSrcVertices[self.mSrcVertices.len() - 2].dist)
      self.mPrevStatus = outline2
      self.mStatus = outVertices
      self.mOutVertex = 0
    of outline1:
      if self.mClosed != 0:
        if self.mSrcVertex >= self.mSrcVertices.len():
          self.mPrevStatus = closeFirst
          self.mStatus = endPoly1
          continue
      else:
        if self.mSrcVertex >= self.mSrcVertices.len() - 1:
          self.mStatus = cap2
          continue

      self.mStroker.calcJoin(self.mOutVertices,
                          self.mSrcVertices.prev(self.mSrcVertex),
                          self.mSrcVertices.curr(self.mSrcVertex),
                          self.mSrcVertices.next(self.mSrcVertex),
                          self.mSrcVertices.prev(self.mSrcVertex).dist,
                          self.mSrcVertices.curr(self.mSrcVertex).dist)
      inc(self.mSrcVertex)
      self.mPrevStatus = self.mStatus
      self.mStatus = outVertices
      self.mOutVertex = 0

    of closeFirst:
      self.mStatus = outline2
      cmd = pathCmdMoveTo
    of outline2:
      if self.mSrcVertex <= int(self.mClosed == 0):
        self.mStatus = endPoly2
        self.mPrevStatus = stop
      else:
        dec(self.mSrcVertex)
        self.mStroker.calcJoin(self.mOutVertices,
                            self.mSrcVertices.next(self.mSrcVertex),
                            self.mSrcVertices.curr(self.mSrcVertex),
                            self.mSrcVertices.prev(self.mSrcVertex),
                            self.mSrcVertices.curr(self.mSrcVertex).dist,
                            self.mSrcVertices.prev(self.mSrcVertex).dist)
        self.mPrevStatus = self.mStatus
        self.mStatus = outVertices
        self.mOutVertex = 0
    of outVertices:
      if self.mOutVertex >= self.mOutVertices.len():
        self.mStatus = self.mPrevStatus
      else:
        var c = self.mOutVertices[self.mOutVertex]
        inc(self.mOutVertex)
        x = c.x
        y = c.y
        return cmd
    of endPoly1:
      self.mStatus = self.mPrevStatus
      return pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
    of endPoly2:
      self.mStatus = self.mPrevStatus
      return pathCmdEndPoly or pathFlagsClose or pathFlagsCw
    of stop:
      cmd = pathCmdStop

  result = cmd

