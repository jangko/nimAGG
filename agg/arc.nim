import basics, math

type
  Arc* = object
    x, y, rx ,ry: float64
    angle, start, stop, scale, da: float64
    ccw, initialized: bool
    pathCmd: uint

proc normalize(self: var Arc, a1, a2: float64, ccw: bool) =
  let ra = (abs(self.rx) + abs(self.ry)) / 2
  self.da = arccos(ra / (ra + 0.125 / self.scale)) * 2

  var
    a1 = a1
    a2 = a2

  if ccw:
    while a2 < a1: a2 += pi * 2.0
  else:
    while a1 < a2: a1 += pi * 2.0
    self.da = -self.da

  self.ccw   = ccw
  self.start = a1
  self.stop  = a2
  self.initialized = true

proc initArc*(): Arc =
  result.scale = 1.0
  result.initialized = false

proc initArc*(x, y, rx, ry, a1, a2: float64, ccw: bool): Arc =
  result.x = x
  result.y = y
  result.rx = rx
  result.ry = ry
  result.scale = 1.0
  result.normalize(a1, a2, ccw)

proc init*(self: var Arc, x, y, rx, ry, a1, a2: float64, ccw: bool = true) =
  self.x  = x
  self.y  = y
  self.rx = rx
  self.ry = ry
  self.normalize(a1, a2, ccw)

proc approximationScale*(self: var Arc, s: float64) =
  self.scale = s
  if self.initialized:
    self.normalize(self.start, self.stop, self.ccw)

proc approximationScale*(self: Arc): float64 = self.scale

proc rewind*(self: var Arc, pathId: int) =
  self.pathCmd = pathCmdMoveTo
  self.angle = self.start

proc vertex*(self: var Arc, x, y: var float64): uint =
  if isStop(self.pathCmd): return pathCmdStop
  if (self.angle < (self.stop - (self.da/4))) != self.ccw:
    x = self.x + cos(self.stop) * self.rx
    y = self.y + sin(self.stop) * self.ry
    self.pathCmd = pathCmdStop
    return pathCmdLineTo

  x = self.x + cos(self.angle) * self.rx
  y = self.y + sin(self.angle) * self.ry
  self.angle += self.da

  result = self.pathCmd
  self.pathCmd = pathCmdLineTo
