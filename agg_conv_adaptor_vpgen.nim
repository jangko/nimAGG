import agg_basics, agg_vpgen_segmentator

type
  ConvAdaptorVpgen*[VertexSource, VPGen] = object of RootObj
    mSource: ptr VertexSource
    mVpgen: VPGen
    mStartX, mStartY: float64
    mPolyFlags: uint
    mVertices: int

proc init*[VS, VPG](self: var ConvAdaptorVpgen[VS, VPG], source: var VS) =
  self.mSource = source.addr
  self.mVpgen  = construct(VPG)

proc initConvAdaptorVpgen*[VS, VPG](source: var VS): ConvAdaptorVpgen[VS, VPG] =
  result.init(source)

proc attach*[VS, VPG](self: var ConvAdaptorVpgen[VS, VPG], source: var VS) =
  self.mSource = source.addr

proc vpgen*[VS, VPG](self: var ConvAdaptorVpgen[VS, VPG]): var VPG = self.mVpgen

proc rewind*[VS, VPG](self: var ConvAdaptorVpgen[VS, VPG], pathId: int)  =
  mixin rewind
  self.mSource[].rewind(pathId)
  self.mVpgen.reset()
  self.mStartX    = 0
  self.mStartY    = 0
  self.mPolyFlags = 0
  self.mVertices  = 0

proc vertex*[VS, VPG](self: var ConvAdaptorVpgen[VS, VPG], x, y: var float64): uint =
  var cmd: uint = pathCmdStop
  while true:
    cmd = self.mVpgen.vertex(x, y)
    if not isStop(cmd): break

    if self.mPolyFlags != 0 and not VPG.autoUnclose():
      x = 0.0
      y = 0.0
      cmd = self.mPolyFlags
      self.mPolyFlags = 0
      break

    if self.mVertices < 0:
      if self.mVertices < -1:
        self.mVertices = 0
        return pathCmdStop
      self.mVpgen.moveTo(self.mStartX, self.mStartY)
      self.mVertices = 1
      continue

    var tx, ty: float64
    cmd = self.mSource[].vertex(tx, ty)
    if isVertex(cmd):
      if isMoveTo(cmd):
        if VPG.autoClose() and self.mVertices > 2:
          self.mVpgen.lineTo(self.mStartX, self.mStartY)
          self.mPolyFlags = pathCmdEndPoly or pathFlagsClose
          self.mStartX    = tx
          self.mStartY    = ty
          self.mVertices  = -1
          continue

        self.mVpgen.moveTo(tx, ty)
        self.mStartX  = tx
        self.mStartY  = ty
        self.mVertices = 1
      else:
        self.mVpgen.lineTo(tx, ty)
        inc self.mVertices;
    else:
      if isEndPoly(cmd):
        self.mPolyFlags = cmd
        if isClosed(cmd) or VPG.autoClose():
          if VPG.autoClose(): self.mPolyFlags = self.mPolyFlags or pathFlagsClose
          if self.mVertices > 2:
            self.mVpgen.lineTo(self.mStartX, self.mStartY)
          self.mVertices = 0
      else:
        # pathCmdStop
        if VPG.autoClose() and self.mVertices > 2:
          self.mVpgen.lineTo(self.mStartX, self.mStartY)
          self.mPolyFlags = pathCmdEndPoly or pathFlagsClose
          self.mVertices  = -2
          continue
        break

  result = cmd
