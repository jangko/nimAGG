import agg_basics

type
  EllipseBresenhamInterpolator* = object
    rx2, ry2, two_rx2, two_ry2: int
    dx, dy, inc_x, inc_y, cur_f: int

proc initEllipseBresenhamInterpolator*(rx, ry: int): EllipseBresenhamInterpolator =
  result.rx2 = rx * rx
  result.ry2 = ry * ry
  result.two_rx2 = result.rx2 shl 1
  result.two_ry2 = result.ry2 shl 1
  result.dx = 0
  result.dy = 0
  result.inc_x = 0
  result.inc_y = -ry * result.two_rx2
  result.cur_f = 0

proc getDx*(self: EllipseBresenhamInterpolator): int = self.dx
proc getDy*(self: EllipseBresenhamInterpolator): int = self.dy

proc inc*(self: var EllipseBresenhamInterpolator) =
  var
    mx, my, mxy, min_m: int
    fx, fy, fxy: int

  fx = self.cur_f + self.inc_x + self.ry2
  mx = fx
  if mx < 0: mx = -mx

  fy = self.cur_f + self.inc_y + self.rx2
  my = fy
  if my < 0: my = -my

  fxy = self.cur_f + self.inc_x + self.ry2 + self.inc_y + self.rx2
  mxy = fxy
  if mxy < 0: mxy = -mxy

  min_m = mx
  var flag = true

  if min_m > my:
    min_m = my
    flag = false

  self.dx = 0
  self.dy = 0

  if min_m > mxy:
    self.inc_x += self.two_ry2
    self.inc_y += self.two_rx2
    self.cur_f = fxy
    self.dx = 1
    self.dy = 1
    return

  if flag:
    self.inc_x += self.two_ry2
    self.cur_f = fx
    self.dx = 1
    return

  self.inc_y += self.two_rx2
  self.cur_f = fy
  self.dy = 1
