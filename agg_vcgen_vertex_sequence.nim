import agg_basics, agg_vertex_sequence, agg_shorten_path

type
  VcgenVertexSequence* = object
    mSrcVertices: VertexSequence[VertexDistCmd]
    mFlags: uint
    mCurVertex: int
    mShorten: float64
    mReady: bool

proc initVcgenVertexSequence*(): VcgenVertexSequence =
  result.mFlags = 0
  result.mCurVertex = 0
  result.mShorten = 0.0
  result.mReady = false
  result.mSrcVertices = initVertexSequence[VertexDistCmd]()

template construct*(x: typedesc[VcgenVertexSequence]): untyped = initVcgenVertexSequence()

proc shorten*(self: var VcgenVertexSequence, s: float64) = self.mShorten = s
proc shorten*(self: var VcgenVertexSequence): float64 = self.mShorten

proc removeAll*(self: var VcgenVertexSequence) {.inline.} =
  self.mReady = false;
  self.mSrcVertices.removeAll()
  self.mCurVertex = 0;
  self.mFlags = 0;

proc addVertex*(self: var VcgenVertexSequence, x, y: float64, cmd: uint) {.inline.} =
  self.mReady = false
  if isMoveTo(cmd):
    self.mSrcVertices.modifyLast(VertexDistCmd(x: x, y: y, cmd: cmd))
  else:
    if isVertex(cmd):
      self.mSrcVertices.add(VertexDistCmd(x: x, y: y, cmd: cmd))
    else:
      self.mFlags = cmd and pathFlagsMask

proc rewind*(self: var VcgenVertexSequence, pathId: int) {.inline.} =
  if not self.mReady:
    self.mSrcVertices.close(isClosed(self.mFlags))
    shortenPath(self.mSrcVertices, self.mShorten, getCloseFlag(self.mFlags))
  self.mReady = true
  self.mCurVertex = 0;

proc vertex*(self: var VcgenVertexSequence, x, y: var float64): uint {.inline.} =
  if not self.mReady:
    self.rewind(0)

  if self.mCurVertex == self.mSrcVertices.size:
    inc self.mCurVertex
    return pathCmdEndPoly or self.mFlags

  if self.mCurVertex > self.mSrcVertices.size:
    return pathCmdStop

  let v = self.mSrcVertices[self.mCurVertex].addr
  inc self.mCurVertex
  x = v.x
  y = v.y
  result = v.cmd