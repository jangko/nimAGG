import math

type
  TransWarpMagnifier = object
    mXc, mYc, mMagn, mRadius: float64

proc initTransWarpMagnifier*(): TransWarpMagnifier =
  result.mXc = 0.0
  result.mYc = 0.0
  result.mMagn = 1.0
  result.mRadius = 1.0

proc center*(self: var TransWarpMagnifier, x, y: float64) =
  self.mXc = x
  self.mYc = y

proc magnification*(self: var TransWarpMagnifier, m: float64) =
  self.mMagn = m

proc radius*(self: var TransWarpMagnifier, r: float64) =
  self.mRadius = r

proc xc*(self: TransWarpMagnifier): float64 = self.mXc
proc yc*(self: TransWarpMagnifier): float64 = self.mYc
proc magnification*(self: TransWarpMagnifier): float64 = self.mMagn
proc radius*(self: TransWarpMagnifier): float64 = self.mRadius

proc transform*(self: TransWarpMagnifier, x, y: var float64) =
  var
    dx = x - self.mXc
    dy = y - self.mYc
    r = sqrt(dx * dx + dy * dy)
    
  if r < self.mRadius:
    x = self.mXc + dx * self.mMagn
    y = self.mYc + dy * self.mMagn
    return

  let m = (r + self.mRadius * (self.mMagn - 1.0)) / r
  x = self.mXc + dx * m
  y = self.mYc + dy * m

proc inverseTransform*(self: TransWarpMagnifier, x, y: var float64) =
  # New version by Andrew Skalkin
  var
    dx = x - self.mXc
    dy = y - self.mYc
    r = sqrt(dx * dx + dy * dy)

  if r < self.mRadius * self.mMagn:
    x = self.mXc + dx / self.mMagn
    y = self.mYc + dy / self.mMagn
  else:
    let rnew = r - self.mRadius * (self.mMagn - 1.0)
    x = self.mXc + rnew * dx / r
    y = self.mYc + rnew * dy / r
  
  # Old version
  #trans_warp_magnifier t(*this);
  #t.magnification(1.0 / self.mMagn);
  #t.radius(self.mRadius * self.mMagn);
  #t.transform(x, y);