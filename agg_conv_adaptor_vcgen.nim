import agg_basics, agg_vcgen_stroke

type
  NullMarkers* = object

proc removeAll*(self: NullMarkers) = discard
proc addVertex*(self: NullMarkers, x, y: float64, cmd: uint) = discard
proc prepareSrc*(self: NullMarkers) = discard
proc rewind*(self: NullMarkers, pathId: int) = discard
proc vertex*(self: NullMarkers, x, y: var float64): uint = pathCmdStop

type
  Status = enum
    initial
    accumulate
    generate

  ConvAdaptorVcgen*[VertexSource, Generator, Markers] = ref object
    mSource: VertexSource
    mGenerator: Generator
    mMarkers: Markers
    mStatus: Status
    mLastCmd: uint
    mStartX, mStartY: float64

proc newConvAdaptorVcgen*[V,G,M](source: V): ConvAdaptorVcGen[V,G,M] =
  new(result)
  result.mSource = source
  result.mStatus = initial
  result.mGenerator = construct(G)

proc attach*[V,G,M](self: ConvAdaptorVcGen[V,G,M], source: V) =
  self.mSource = source

proc generator*[V,G,M](self: ConvAdaptorVcGen[V,G,M]): G =
  result = self.mGenerator

proc markers*[V,G,M](self: ConvAdaptorVcGen[V,G,M]): var M =
  result = self.mMarker

proc rewind*[V,G,M](self: ConvAdaptorVcGen[V,G,M], pathId: int)  =
  self.mSource.rewind(pathId)
  self.mStatus = initial

proc vertex*[V,G,M](self: ConvAdaptorVcGen[V,G,M], x, y: var float64): uint =
  var
    cmd: uint = pathCmdStop
    done = false

  while not done:
    case self.mStatus
    of initial:
      self.mMarkers.removeAll()
      self.mLastCmd = self.mSource.vertex(self.mStartX, self.mStartY)
      self.mStatus = accumulate
    of accumulate:
      if isStop(self.mLastCmd): return pathCmdStop
      self.mGenerator.removeAll()
      self.mGenerator.addVertex(self.mStartX, self.mStartY, pathCmdMoveTo)
      self.mMarkers.addVertex(self.mStartX, self.mStartY, pathCmdMoveTo)
      while true:
        cmd = self.mSource.vertex(x, y)
        if isVertex(cmd):
          self.mLastCmd = cmd
          if isMoveTo(cmd):
            self.mStartX = x
            self.mStartY = y
            break
          self.mGenerator.addVertex(x, y, cmd)
          self.mMarkers.addVertex(x, y, pathCmdLineTo)
        else:
          if isStop(cmd):
            self.mLastCmd = pathCmdStop
            break
          if isEndPoly(cmd):
            self.mGenerator.addVertex(x, y, cmd)
            break
      self.mGenerator.rewind(0)
      self.mStatus = generate
    of generate:
      cmd = self.mGenerator.vertex(x, y)
      if isStop(cmd):
        self.mStatus = accumulate
      else:
        done = true

  result = cmd
