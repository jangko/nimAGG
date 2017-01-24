import agg_basics, agg_vertex_sequence

type
  CoordType = object
    x, y: float64

  VcgenMarkersTerm* = object
    mMarkers: seq[CoordType]
    mCurrId: int
    mCurrIdx: int

proc initVcgenMarkersTerm*(): VcgenMarkersTerm =
  result.mCurrId = 0
  result.mCurrIdx = 0
  result.mMarkers = @[]

template construct*(x: typedesc[VcgenMarkersTerm]): untyped = initVcgenMarkersTerm()

proc removeAll*(self: var VcgenMarkersTerm) =
  self.mMarkers.setLen(0)

proc modifyLast(x: var seq[CoordType], val: CoordType) =
  x[x.len-1] = val

proc addVertex*(self: var VcgenMarkersTerm, x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    if (self.mMarkers.len and 1) != 0:
      # Initial state, the first coordinate was added.
      # If two of more calls of start_vertex() occures
      # we just modify the last one.
      self.mMarkers.modifyLast(CoordType(x: x, y: y))
    else:
      self.mMarkers.add(CoordType(x: x, y: y))
  else:
    if isVertex(cmd):
      if (self.mMarkers.len and 1) != 0:
        # Initial state, the first coordinate was added.
        # Add three more points, 0,1,1,0
        self.mMarkers.add(CoordType(x: x, y: y))
        self.mMarkers.add(self.mMarkers[self.mMarkers.len - 1])
        self.mMarkers.add(self.mMarkers[self.mMarkers.len - 3])
      else:
        if self.mMarkers.len != 0:
          # Replace two last points: 0,1,1,0 -> 0,1,2,1
          self.mMarkers[self.mMarkers.len - 1] = self.mMarkers[self.mMarkers.len - 2]
          self.mMarkers[self.mMarkers.len - 2] = CoordType(x: x, y: y)

proc rewind*(self: var VcgenMarkersTerm, pathId: int) =
  self.mCurrId = path_id * 2
  self.mCurrIdx = self.mCurrId

proc vertex*(self: var VcgenMarkersTerm, x, y: var float64): uint =
  if self.mCurrId > 2 or self.mCurrIdx >= self.mMarkers.len:
    return pathCmdStop

  let c = self.mMarkers[self.mCurrIdx].addr
  x = c.x
  y = c.y
  if (self.mCurrIdx and 1) != 0:
    self.mCurrIdx += 3
    return pathCmdLineto

  inc self.mCurrIdx
  result = pathCmdMoveTo
