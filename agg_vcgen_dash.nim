import agg_basics, agg_vertex_sequence, agg_shorten_path

const
  maxDashes = 32

type
  Status = enum
    initial
    ready
    polyline
    stop

  VcgenDash* = object
    mDashes: array[maxDashes, float64]
    mTotalDashLen: float64
    mNumDashes: int
    mDashStart, mShorten, mCurrDashStart: float64
    mCurrDash: int
    mCurrRest: float64
    mV1, mV2: ptr VertexDist
    mSrcVertices: VertexSequence[VertexDist]
    mClosed: uint
    mStatus: Status
    mSrcVertex: int

proc initVcgenDash*(): VcgenDash =
  result.mTotalDashLen = 0.0
  result.mNumDashes = 0
  result.mDashStart = 0.0
  result.mShorten = 0.0
  result.mCurrDashStart = 0.0
  result.mCurrDash = 0
  result.mSrcVertices = initVertexSequence[VertexDist]()
  result.mClosed = 0
  result.mStatus = initial
  result.mSrcVertex = 0

template construct*(x: typedesc[VcgenDash]): untyped = initVcgenDash()

proc calcDashStart(self: var VcgenDash, ds: float64) =
  var ds = ds
  self.mCurrDash = 0
  self.mCurrDashStart = 0.0
  while ds > 0.0:
    if ds > self.mDashes[self.mCurrDash]:
      ds -= self.mDashes[self.mCurrDash]
      inc self.mCurrDash
      self.mCurrDashStart = 0.0
      if self.mCurrDash >= self.mNumDashes: self.mCurrDash = 0
    else:
      self.mCurrDashStart = ds
      ds = 0.0

proc removeAllDashes*(self: var VcgenDash) =
  self.mTotalDashLen = 0.0
  self.mNumDashes = 0
  self.mCurrDashStart = 0.0
  self.mCurrDash = 0

proc addDash*(self: var VcgenDash, dashLen, gapLen: float64) =
  if self.mNumDashes < maxDashes:
    self.mTotalDashLen += dashLen + gapLen
    self.mDashes[self.mNumDashes] = dashLen
    inc self.mNumDashes
    self.mDashes[self.mNumDashes] = gapLen
    inc self.mNumDashes

proc dashStart*(self: var VcgenDash, ds: float64) =
  self.mDashStart = ds
  self.calcDashStart(abs(ds))

proc shorten*(self: var VcgenDash, s: float64)= self.mShorten = s
proc shorten*(self: VcgenDash): float64 = self.mShorten

# Vertex Generator Interface
proc removeAll*(self: var VcgenDash) =
  self.mStatus = initial
  self.mSrcVertices.removeAll()
  self.mClosed = 0

proc addVertex*(self: var VcgenDash, x, y: float64, cmd: uint) =
  self.mStatus = initial
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(VertexDist(x: x, y: y))
  else:
    if isVertex(cmd):
      self.mSrcVertices.add(VertexDist(x: x, y: y))
    else:
      self.mClosed = getCloseFlag(cmd)

# Vertex Source Interface
proc rewind*(self: var VcgenDash, pathId: int) =
  if self.mStatus == initial:
    self.mSrcVertices.close(self.mClosed != 0)
    shortenPath(self.mSrcVertices, self.mShorten, self.mClosed)
  self.mStatus = ready
  self.mSrcVertex = 0

proc vertex*(self: var VcgenDash, x, y: var float64): uint =
  var cmd: uint = pathCmdMoveTo
  while not isStop(cmd):
    case self.mStatus
    of initial:
      self.rewind(0)
      self.mStatus = ready
    of ready:
        if self.mNumDashes < 2 or self.mSrcVertices.len() < 2:
          cmd = pathCmdStop
          continue

        self.mStatus = polyline
        self.mSrcVertex = 1
        self.mV1 = self.mSrcVertices[0].addr
        self.mV2 = self.mSrcVertices[1].addr
        self.mCurrRest = self.mV1.dist
        x = self.mV1.x
        y = self.mV1.y
        if self.mDashStart >= 0.0: self.calcDashStart(self.mDashStart)
        return pathCmdMoveTo
    of polyline:
      let dashRest = self.mDashes[self.mCurrDash] - self.mCurrDashStart
      var cmd: uint = if (self.mCurrDash and 1) != 0: pathCmdMoveTo else: pathCmdLineTo

      if self.mCurrRest > dashRest:
        self.mCurrRest -= dashRest
        inc self.mCurrDash
        if self.mCurrDash >= self.mNumDashes: self.mCurrDash = 0
        self.mCurrDashStart = 0.0
        x = self.mV2.x - (self.mV2.x - self.mV1.x) * self.mCurrRest / self.mV1.dist
        y = self.mV2.y - (self.mV2.y - self.mV1.y) * self.mCurrRest / self.mV1.dist
      else:
        self.mCurrDashStart += self.mCurrRest
        x = self.mV2.x
        y = self.mV2.y
        inc self.mSrcVertex
        self.mV1 = self.mV2
        self.mCurrRest = self.mV1.dist
        if self.mClosed != 0:
          if self.mSrcVertex > self.mSrcVertices.len():
            self.mStatus = stop
          else:
            let idx = if self.mSrcVertex >= self.mSrcVertices.len(): 0 else: self.mSrcVertex
            self.mV2 = self.mSrcVertices[idx].addr
        else:
          if self.mSrcVertex >= self.mSrcVertices.len():
            self.mStatus = stop
          else:
            self.mV2 = self.mSrcVertices[self.mSrcVertex].addr
      return cmd
    of stop:
      cmd = pathCmdStop
    else:
      discard

  result = pathCmdStop







