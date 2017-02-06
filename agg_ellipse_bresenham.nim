import agg_basics

type
  EllipseBresenhamInterpolator* = object
    rx2, ry2, twoRx2, twoRy2: int
    mDx, mDy, incX, incY, curF: int

proc initEllipseBresenhamInterpolator*(rx, ry: int): EllipseBresenhamInterpolator =
  result.rx2 = rx * rx
  result.ry2 = ry * ry
  result.twoRx2 = result.rx2 shl 1
  result.twoRy2 = result.ry2 shl 1
  result.mDx = 0
  result.mDy = 0
  result.incX = 0
  result.incY = -ry * result.twoRx2
  result.curF = 0

proc getDx*(self: EllipseBresenhamInterpolator): int = self.mDx
proc getDy*(self: EllipseBresenhamInterpolator): int = self.mDy

proc inc*(self: var EllipseBresenhamInterpolator) =
  var
    mx, my, mxy, min_m: int
    fx, fy, fxy: int

  fx = self.curF + self.incX + self.ry2
  mx = fx
  if mx < 0: mx = -mx

  fy = self.curF + self.incY + self.rx2
  my = fy
  if my < 0: my = -my

  fxy = self.curF + self.incX + self.ry2 + self.incY + self.rx2
  mxy = fxy
  if mxy < 0: mxy = -mxy

  min_m = mx
  var flag = true

  if min_m > my:
    min_m = my
    flag = false

  self.mDx = 0
  self.mDy = 0

  if min_m > mxy:
    self.incX += self.twoRy2
    self.incY += self.twoRx2
    self.curF = fxy
    self.mDx = 1
    self.mDy = 1
    return

  if flag:
    self.incX += self.twoRy2
    self.curF = fx
    self.mDx = 1
    return

  self.incY += self.twoRx2
  self.curF = fy
  self.mDy = 1
