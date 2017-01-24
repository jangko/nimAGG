import agg_basics

type
  ConvClosePolygon*[VertexSource] = object
    mSource: ptr VertexSource
    mCmd: array[2, uint]
    mX: array[2, float64]
    mY: array[2, float64]
    mVertex: int
    mLineTo: bool

proc initConvClosePolygon*[VertexSource](vs: var VertexSource): ConvClosePolygon =
  result.mSource = vs.addr

proc attach*[VertexSource](self: var ConvClosePolygon, source: var VertexSource) =
  self.mSource = source.addr

proc rewind*[VertexSource](self: var ConvClosePolygon, pathId: int) =
  self.mSource[].rewind(pathId)
  self.mVertex = 2
  self.mLineTo = false

proc vertex*[VertexSource](self: var ConvClosePolygon, x, y: var float64): uint =
  var cmd: uint = pathCmdStop
  while true:
    if self.mVertex < 2:
      x = self.mX[self.mVertex]
      y = self.mY[self.mVertex]
      cmd = self.mCmd[self.mVertex]
      inc self.mVertex
      break

    cmd = self.mSource[].vertex(x, y)
    if isEndPoly(cmd):
      cmd = cmd or pathFlagsClose
      break

    if isStop(cmd):
      if self.mLineTo:
        self.mCmd[0]  = pathCmdEndPoly or pathFlagsClose
        self.mCmd[1]  = pathCmdStop
        self.mVertex  = 0
        self.mLineTo = false
        continue
      break

    if isMoveTo(cmd):
      if self.mLineTo:
        self.mX[0]    = 0.0
        self.mY[0]    = 0.0
        self.mCmd[0]  = pathCmdEndPoly or pathFlagsClose
        self.mX[1]    = x
        self.mY[1]    = y
        self.mCmd[1]  = cmd
        self.mVertex  = 0
        self.mLineTo = false
        continue

    if isVertex(cmd):
      self.mLineTo = true
      break

  result = cmd


