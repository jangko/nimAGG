import basics

type
  ConvClosePolygon*[VertexSource] = object
    mSource: ptr VertexSource
    mCmd: array[2, uint]
    mX: array[2, float64]
    mY: array[2, float64]
    mVertex: int
    mLineTo: bool

proc initConvClosePolygon*[VS](vs: var VS): ConvClosePolygon[VS] =
  result.mSource = vs.addr

proc attach*[VS](self: var ConvClosePolygon[VS], source: var VS) =
  self.mSource = source.addr

proc rewind*[VS](self: var ConvClosePolygon[VS], pathId: int) =
  mixin rewind
  self.mSource[].rewind(pathId)
  self.mVertex = 2
  self.mLineTo = false

proc vertex*[VS](self: var ConvClosePolygon[VS], x, y: var float64): uint =
  mixin vertex
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


