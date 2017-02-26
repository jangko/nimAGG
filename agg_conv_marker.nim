import agg_basics, agg_trans_affine, math

type
  Status = enum
    initial
    markers
    polygon
    stop

  ConvMarker*[MarkerLocator, MarkerShapes] = object
    mMarkerLocator: ptr MarkerLocator
    mMarkerShapes: ptr MarkerShapes
    mTransform, mMtx: TransAffine
    mStatus: Status
    mMarker, mNumMarkers: int

proc initConvMarker*[ML,MS](ml: var ML, ms: var MS): ConvMarker[ML, MS] =
  result.mMarkerLocator = ml.addr
  result.mMarkerShapes = ms.addr
  result.mStatus = initial
  result.mMarker = 0
  result.mNumMarkers = 1
  result.mTransform = initTransAffine()
  result.mMtx = initTransAffine()

proc transform*[ML,MS](self: var ConvMarker[ML, MS]): var TransAffine = self.mTransform

proc rewind*[ML,MS](self: var ConvMarker[ML, MS], pathId: int) =
  self.mStatus = initial
  self.mMarker = 0
  self.mNumMarkers = 1

proc vertex*[ML,MS](self: var ConvMarker[ML, MS], x, y: var float64): uint =
  mixin rewind, vertex
  var
    cmd: uint = pathCmdMoveTo
    x1, y1, x2, y2: float64

  while not isStop(cmd):
    case self.mStatus
    of initial:
      if self.mNumMarkers == 0:
        cmd = pathCmdStop
        break

      self.mMarkerLocator[].rewind(self.mMarker)
      inc self.mMarker
      self.mNumMarkers = 0
      self.mStatus = markers
    of markers:
      if isStop(self.mMarkerLocator[].vertex(x1, y1)):
        self.mStatus = initial
        continue

      if isStop(self.mMarkerLocator[].vertex(x2, y2)):
        self.mStatus = initial
        continue

      inc self.mNumMarkers
      self.mMtx = self.mTransform
      self.mMtx *= transAffineRotation(arctan2(y2 - y1, x2 - x1))
      self.mMtx *= transAffineTranslation(x1, y1)
      self.mMarkerShapes[].rewind(self.mMarker - 1)
      self.mStatus = polygon
    of polygon:
      cmd = self.mMarkerShapes[].vertex(x, y)
      if isStop(cmd):
        cmd = pathCmdMoveTo
        self.mStatus = markers
        continue
      self.mMtx.transform(x, y)
      return cmd
    of stop:
      cmd = pathCmdStop
      break

  result = cmd




