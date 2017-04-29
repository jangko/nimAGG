import agg_basics, agg_bspline, agg_array

type
  Status = enum
    initial
    ready
    polygon
    endPoly
    stop

  VcgenBspline* = object
    mSrcVertices: PodBVector[PointD]
    mSplineX, mSplineY: BSpline
    mInterpolationStep: float64
    mClosed: uint
    mStatus: Status
    mSrcVertex: int
    mCurAbscissa, mMaxAbscissa: float64

proc initVcgenBspline*(): VcgenBspline =
  result.mSrcVertices = initPodBVector[PointD]()
  result.mSplineX = initBSpline()
  result.mSplineY = initBSpline()
  result.mInterpolationStep = 1.0/50.0
  result.mClosed = 0
  result.mStatus = initial
  result.mSrcVertex = 0

template construct*(x: typedesc[VcgenBspline]): untyped = initVcgenBspline()

proc interpolationStep*(self: var VcgenBspline, v: float64) =
  self.mInterpolationStep = v

proc interpolationStep*(self: VcgenBspline): float64 =
  self.mInterpolationStep

# Vertex Generator Interface
proc removeAll*(self: var VcgenBspline) =
  self.mSrcVertices.removeAll()
  self.mClosed = 0
  self.mStatus = initial
  self.mSrcVertex = 0

proc addVertex*(self: var VcgenBspline, x, y: float64, cmd: uint) =
  self.mStatus = initial
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(PointD(x: x, y: y))
  else:
    if isVertex(cmd):
      self.mSrcVertices.add(PointD(x: x, y: y))
    else:
      self.mClosed = getCloseFlag(cmd)

proc rewind*(self: var VcgenBspline, pathId: int) =
  self.mCurAbscissa = 0.0
  self.mMaxAbscissa = 0.0
  self.mSrcVertex = 0
  if self.mStatus == initial and self.mSrcVertices.len > 2:
    if self.mClosed != 0:
      self.mSplineX.init(self.mSrcVertices.len + 8)
      self.mSplineY.init(self.mSrcVertices.len + 8)
      self.mSplineX.addPoint(0.0, self.mSrcVertices.prev(self.mSrcVertices.len - 3).x)
      self.mSplineY.addPoint(0.0, self.mSrcVertices.prev(self.mSrcVertices.len - 3).y)
      self.mSplineX.addPoint(1.0, self.mSrcVertices[self.mSrcVertices.len - 3].x)
      self.mSplineY.addPoint(1.0, self.mSrcVertices[self.mSrcVertices.len - 3].y)
      self.mSplineX.addPoint(2.0, self.mSrcVertices[self.mSrcVertices.len - 2].x)
      self.mSplineY.addPoint(2.0, self.mSrcVertices[self.mSrcVertices.len - 2].y)
      self.mSplineX.addPoint(3.0, self.mSrcVertices[self.mSrcVertices.len - 1].x)
      self.mSplineY.addPoint(3.0, self.mSrcVertices[self.mSrcVertices.len - 1].y)
    else:
      self.mSplineX.init(self.mSrcVertices.len)
      self.mSplineY.init(self.mSrcVertices.len)


    for i in 0.. <self.mSrcVertices.len:
      let x = if self.mClosed != 0: i + 4 else: i
      self.mSplineX.addPoint(x.float64, self.mSrcVertices[i].x)
      self.mSplineY.addPoint(x.float64, self.mSrcVertices[i].y)

    self.mCurAbscissa = 0.0
    self.mMaxAbscissa = (self.mSrcVertices.len - 1).float64
    if self.mClosed != 0:
      self.mCurAbscissa = 4.0
      self.mMaxAbscissa += 5.0
      self.mSplineX.addPoint((self.mSrcVertices.len + 4).float64, self.mSrcVertices[0].x)
      self.mSplineY.addPoint((self.mSrcVertices.len + 4).float64, self.mSrcVertices[0].y)
      self.mSplineX.addPoint((self.mSrcVertices.len + 5).float64, self.mSrcVertices[1].x)
      self.mSplineY.addPoint((self.mSrcVertices.len + 5).float64, self.mSrcVertices[1].y)
      self.mSplineX.addPoint((self.mSrcVertices.len + 6).float64, self.mSrcVertices[2].x)
      self.mSplineY.addPoint((self.mSrcVertices.len + 6).float64, self.mSrcVertices[2].y)
      self.mSplineX.addPoint((self.mSrcVertices.len + 7).float64, self.mSrcVertices.next(2).x)
      self.mSplineY.addPoint((self.mSrcVertices.len + 7).float64, self.mSrcVertices.next(2).y)

    self.mSplineX.prepare()
    self.mSplineY.prepare()

  self.mStatus = ready

proc vertex*(self: var VcgenBspline, x, y: var float64): uint =
  var cmd: uint = pathCmdLineto
  while not isStop(cmd):
    case self.mStatus
    of initial:
      self.rewind(0)
      self.mStatus = ready
    of ready:
      if self.mSrcVertices.len < 2:
        cmd = pathCmdStop
        continue

      if self.mSrcVertices.len == 2:
        x = self.mSrcVertices[self.mSrcVertex].x
        y = self.mSrcVertices[self.mSrcVertex].y
        inc self.mSrcVertex
        if self.mSrcVertex == 1: return pathCmdMoveTo
        if self.mSrcVertex == 2: return pathCmdLineto
        cmd = pathCmdStop
        continue

      cmd = pathCmdMoveTo
      self.mStatus = polygon
      self.mSrcVertex = 0
    of polygon:
      if self.mCurAbscissa >= self.mMaxAbscissa:
        if self.mClosed != 0:
          self.mStatus = endPoly
          continue
        else:
          x = self.mSrcVertices[self.mSrcVertices.len - 1].x
          y = self.mSrcVertices[self.mSrcVertices.len - 1].y
          self.mStatus = endPoly
          return pathCmdLineto

      x = self.mSplineX.getStateful(self.mCurAbscissa)
      y = self.mSplineY.getStateful(self.mCurAbscissa)
      inc self.mSrcVertex
      self.mCurAbscissa += self.mInterpolationStep
      return if self.mSrcVertex == 1: pathCmdMoveTo else: pathCmdLineto
    of endPoly:
      self.mStatus = stop
      return pathCmdEndPoly or self.mClosed
    of stop:
      return pathCmdStop
    else:
      discard
  result = cmd
