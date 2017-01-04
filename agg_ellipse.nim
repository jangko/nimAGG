import agg_basics, math

type
  Ellipse* = object
    x: float64
    y: float64
    rx: float64
    ry: float64
    scale: float64
    num: int
    step: int
    cw: bool
    
proc calcNumSteps(self: var Ellipse) {.inline.} =
  var
    ra = (abs(self.rx) + abs(self.ry)) / 2
    da = arccos(ra / (ra + 0.125 / self.scale)) * 2
    
  self.num = uround(2*pi / da)
   
proc initEllipse*(): Ellipse =
  result.x = 0.0
  result.y = 0.0
  result.rx = 1.0
  result.ry = 1.0
  result.scale = 1.0
  result.num = 4 
  result.step = 0
  result.cw = false

proc initEllipse*(x, y, rx, ry: float64, numSteps = 0, cw = false): Ellipse =
  result.x = x
  result.y = y
  result.rx = rx
  result.ry = ry
  result.scale = 1.0
  result.num = numSteps
  result.step = 0
  result.cw = cw 
  if result.num == 0: result.calcNumSteps()
  
proc init*(self: var Ellipse, x, y, rx, ry: float64, numSteps = 0, cw = false) {.inline.} =
  self.x = x
  self.y = y
  self.rx = rx
  self.ry = ry
  self.num = numSteps
  self.step = 0
  self.cw = cw
  if self.num == 0: self.calcNumSteps()
        
proc approximationScale*(self: var Ellipse, scale: float64) {.inline.} =
  self.scale = scale
  self.calcNumSteps()
        
proc rewind*(self: var Ellipse, pathId: uint) {.inline.} =
  self.step = 0
 
proc vertex*(self: var Ellipse, x, y: var float64): uint {.inline.} =
  if self.step == self.num:
    inc self.step
    return pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
    
  if self.step > self.num: 
    return pathCmdStop
    
  var angle = float64(self.step) / float64(self.num) * 2.0 * pi
  if self.cw: angle = 2.0 * pi - angle
  
  x = self.x + cos(angle) * self.rx
  y = self.y + sin(angle) * self.ry
  
  inc self.step
  result = if self.step == 1: pathCmdMoveTo else: pathCmdLineTo
