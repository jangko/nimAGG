import agg_basics, math, agg_arc

type
  RoundedRect* = object
   x1, y1, x2, y2: float64
   rx1, ry1, rx2, ry2: float64
   rx3, ry3, rx4, ry4: float64
   status: int
   arc: Arc

proc initRoundedRect*(x1, y1, x2, y2, r: float64): RoundedRect =
  result.arc = initArc()
  result.x1 = x1; result.y1 = y1; result.x2 = x2; result.y2 = y2
  result.rx1 = r; result.ry1 = r; result.rx2 = r; result.ry2 = r
  result.rx3 = r; result.ry3 = r; result.rx4 = r; result.ry4 = r
  if x1 > x2:
    result.x1 = x2; result.x2 = x1
  if y1 > y2:
    result.y1 = y2; result.y2 = y1

proc rect*(self: var RoundedRect, x1, y1, x2, y2: float64) =
  self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2;
  if x1 > x2:
    self.x1 = x2; self.x2 = x1
  if y1 > y2:
    self.y1 = y2; self.y2 = y1

proc radius*(self: var RoundedRect, r: float64) =
  self.rx1 = r; self.ry1 = r; self.rx2 = r; self.ry2 = r
  self.rx3 = r; self.ry3 = r; self.rx4 = r; self.ry4 = r

proc radius*(self: var RoundedRect, rx, ry: float64) =
  self.rx1 = rx; self.rx2 = rx; self.rx3 = rx; self.rx4 = rx
  self.ry1 = ry; self.ry2 = ry; self.ry3 = ry; self.ry4 = ry

proc radius*(self: var RoundedRect, rx_bottom, ry_bottom, rx_top, ry_top: float64) =
  self.rx1 = rx_bottom; self.rx2 = rx_bottom; self.rx3 = rx_top; self.rx4 = rx_top
  self.ry1 = ry_bottom; self.ry2 = ry_bottom; self.ry3 = ry_top; self.ry4 = ry_top

proc radius*(self: var RoundedRect, rx1, ry1, rx2, ry2, rx3, ry3, rx4, ry4: float64) =
  self.rx1 = rx1; self.ry1 = ry1; self.rx2 = rx2; self.ry2 = ry2
  self.rx3 = rx3; self.ry3 = ry3; self.rx4 = rx4; self.ry4 = ry4

proc normalizeRadius*(self: var RoundedRect) =
  let
    dx = abs(self.x2 - self.x1)
    dy = abs(self.y2 - self.y1)

  var
    k = 1.0
    t: float64

  t = dx / (self.rx1 + self.rx2); if t < k: k = t
  t = dx / (self.rx3 + self.rx4); if t < k: k = t
  t = dy / (self.ry1 + self.ry2); if t < k: k = t
  t = dy / (self.ry3 + self.ry4); if t < k: k = t

  if k < 1.0:
    self.rx1 *= k; self.ry1 *= k; self.rx2 *= k; self.ry2 *= k
    self.rx3 *= k; self.ry3 *= k; self.rx4 *= k; self.ry4 *= k

proc approximationScale*(self: var RoundedRect, s: float64) = 
  self.arc.approximationScale(s)
  
proc approximationScale*(self: RoundedRect): float64 = 
  result = self.arc.approximationScale()
        
proc rewind*(self: var RoundedRect, pathId: int) =
  self.status = 0

proc vertex*(self: var RoundedRect, x, y: var float64): uint =
  var cmd: uint = pathCmdStop
  
  while true:
    case self.status
    of 0:
      self.arc.init(self.x1 + self.rx1, self.y1 + self.ry1, self.rx1, self.ry1, pi, pi+pi*0.5)
      self.arc.rewind(0)
      inc self.status
    of 1:
      cmd = self.arc.vertex(x, y)
      if isStop(cmd): 
        inc self.status
      else: return cmd
    of 2:
      self.arc.init(self.x2 - self.rx2, self.y1 + self.ry2, self.rx2, self.ry2, pi+pi*0.5, 0.0)
      self.arc.rewind(0)
      inc self.status
    of 3:
      cmd = self.arc.vertex(x, y)
      if isStop(cmd): 
        inc self.status
      else: return pathCmdLineTo
    of 4:
      self.arc.init(self.x2 - self.rx3, self.y2 - self.ry3, self.rx3, self.ry3, 0.0, pi*0.5)
      self.arc.rewind(0)
      inc self.status
    of 5:
      cmd = self.arc.vertex(x, y)
      if isStop(cmd): 
        inc self.status
      else: return pathCmdLineTo
    of 6:
      self.arc.init(self.x1 + self.rx4, self.y2 - self.ry4, self.rx4, self.ry4, pi*0.5, pi)
      self.arc.rewind(0)
      inc self.status
    of 7:
      cmd = self.arc.vertex(x, y);
      if isStop(cmd): 
        inc self.status
      else: return pathCmdLineTo
    of 8:
      cmd = pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
      inc self.status
      break
    else:
      break

  result = cmd
