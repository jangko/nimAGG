import agg_basics

type
  ConvConcat*[VS1, VS2] = object
    mSource1: ptr VS1
    mSource2: ptr VS2
    mStatus: int

proc initConvConcat*[VS1, VS2](source1: var VS1, source2: var VS2): ConvConcat[VS1, VS2] =
  result.mSource1 = source1.addr
  result.mSource2 = source2.addr
  result.mStatus = 2

proc attach1*[VS1, VS2](self: var ConvConcat[VS1, VS2], source: var VS1) = self.mSource1 = source.addr
proc attach2*[VS1, VS2](self: var ConvConcat[VS1, VS2], source: var VS2) = self.mSource2 = source.addr

proc rewind*[VS1, VS2](self: var ConvConcat[VS1, VS2], pathId: int) =
  self.mSource1[].rewind(pathId)
  self.mSource2[].rewind(0)
  self.mStatus = 0

proc vertex*[VS1, VS2](self: var ConvConcat[VS1, VS2], x, y: var float64): uint =
  var cmd: uint
  if self.mStatus == 0:
    cmd = self.mSource1[].vertex(x, y)
    if not isStop(cmd): return cmd
    self.mStatus = 1
  if self.mStatus == 1:
    cmd = self.mSource2[].vertex(x, y)
    if not isStop(cmd): return cmd
    self.mStatus = 2
  return pathCmdStop
