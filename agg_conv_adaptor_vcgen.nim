import agg_basics, agg_vcgen_stroke

type
  NullMarkers* = object

proc removeAll*(self: NullMarkers) = discard
proc addVertex*(self: NullMarkers, x, y: float64, cmd: uint) = discard
proc prepareSrc*(self: NullMarkers) = discard
proc rewind*(self: NullMarkers, pathId: int) = discard
proc vertex*(self: NullMarkers, x, y: var float64): uint = pathCmdStop

template construct*(x: typedesc[NullMarkers]): untyped = NullMarkers()

type
  Status = enum
    initial
    accumulate
    generate

  ConvAdaptorVcgen*[VertexSource, Generator, Markers] = object of RootObj
    mSource: ptr VertexSource
    mGenerator: Generator
    mMarkers: Markers
    mStatus: Status
    mLastCmd: uint
    mStartX, mStartY: float64

proc init*[V,G,M](self: var ConvAdaptorVcGen[V,G,M], source: var V) =
  mixin construct
  self.mSource = source.addr
  self.mStatus = initial
  self.mGenerator = construct(G)
  self.mMarkers = construct(M)

proc initConvAdaptorVcgen*[V,G,M](source: var V): ConvAdaptorVcGen[V,G,M] =
  result.init(source)

proc attach*[V,G,M](self: var ConvAdaptorVcGen[V,G,M], source: var V) =
  self.mSource = source.addr

proc generator*[V,G,M](self: var ConvAdaptorVcGen[V,G,M]): var G =
  result = self.mGenerator

proc markers*[V,G,M](self: var ConvAdaptorVcGen[V,G,M]): var M =
  result = self.mMarkers

proc rewind*[V,G,M](self: var ConvAdaptorVcGen[V,G,M], pathId: int)  =
  mixin rewind
  self.mSource[].rewind(pathId)
  self.mStatus = initial

proc vertex*[V,G,M](self: var ConvAdaptorVcGen[V,G,M], x, y: var float64): uint =
  mixin removeAll
  var
    cmd: uint = pathCmdStop
    done = false

  while not done:
    case self.mStatus
    of initial:
      self.mMarkers.removeAll()
      self.mLastCmd = self.mSource[].vertex(self.mStartX, self.mStartY)
      self.mStatus = accumulate
    of accumulate:
      if isStop(self.mLastCmd): return pathCmdStop
      self.mGenerator.removeAll()
      self.mGenerator.addVertex(self.mStartX, self.mStartY, pathCmdMoveTo)
      self.mMarkers.addVertex(self.mStartX, self.mStartY, pathCmdMoveTo)
      while true:
        cmd = self.mSource[].vertex(x, y)
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
