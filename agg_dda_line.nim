import agg_basics

template ddaLineInterpolator*(name: untyped, FractionShift: int, Yshift: int = 0) =
  type
    name* = object
      mY, mInc, mDy: int
        
  proc `init name`*(y1, y2, count: int): name =
    result.mY = y1
    result.mInc = ((y2 - y1) shl FractionShift) div count
    result.mDy = 0

  proc inc*(self: var name) =
    self.mDy += self.mInc

  proc dec*(self: var name) =
    self.mDy -= self.mInc

  proc `+=`*(self: var name, n: int) =
    self.mDy += self.mInc * n

  proc `-=`*(self: var name, n: int) =
    self.mDy -= self.mInc * n

  proc getY*(self: name): int =  self.mY + sar(self.mDy, (FractionShift-YShift))
  proc getDy*(self: name): int = self.mDy

    
type
  Dda2LineInterpolator* = object
    mCnt, mLft, mRem, mMod, mY: int

  LineBresenhamInterpolator* = object
    x1Lr, y1Lr, x2Lr, y2Lr: int
    mVer: bool
    len: int
    mInc: int
    interpolator: Dda2LineInterpolator


# Forward-adjusted line
proc initDda2LineInterpolator*(y1, y2, count: int): Dda2LineInterpolator =
  result.mCnt = if count <= 0: 1 else: count
  result.mLft = (y2 - y1) div result.mCnt
  result.mRem = (y2 - y1) mod result.mCnt
  result.mMod = result.mRem
  result.mY = y1

  if result.mMod <= 0:
    result.mMod += count
    result.mRem += count
    dec result.mLft

  result.mMod -= count


# Backward-adjusted line
proc initDda2LineInterpolator*(y1, y2, count, z: int): Dda2LineInterpolator =
  result.mCnt = if count <= 0: 1 else: count
  result.mLft = (y2 - y1) div result.mCnt
  result.mRem = (y2 - y1) mod result.mCnt
  result.mMod = result.mRem
  result.mY = y1

  if result.mMod <= 0:
    result.mMod += count
    result.mRem += count
    dec result.mLft

# Backward-adjusted line
proc initDda2LineInterpolator*(y, count: int): Dda2LineInterpolator =
  result.mCnt = if count <= 0: 1 else: count
  result.mLft = y div result.mCnt
  result.mRem = y mod result.mCnt
  result.mMod = result.mRem
  result.mY = 0

  if result.mMod <= 0:
    result.mMod += count
    result.mRem += count
    dec result.mLft

proc save*(self: Dda2LineInterpolator, data: ptr int) =
  data[0] = self.mMod
  data[1] = self.mY

proc load*(self: var Dda2LineInterpolator, data: ptr int) =
  self.mMod = data[0]
  self.mY   = data[1]

proc inc*(self: var Dda2LineInterpolator) =
  self.mMod += self.mRem
  self.mY += self.mLft
  if self.mMod > 0:
    self.mMod -= self.mCnt
    inc self.mY

proc dec*(self: var Dda2LineInterpolator) =
  if self.mMod <= self.mRem:
    self.mMod += self.mCnt
    dec self.mY
  self.mMod -= self.mRem
  self.mY -= self.mLft

proc adjustForward*(self: var Dda2LineInterpolator) =
  self.mMod -= self.mCnt

proc adjustBackward*(self: var Dda2LineInterpolator) =
  self.mMod += self.mCnt

proc getMod*(self: Dda2LineInterpolator): int = self.mMod
proc getRem*(self: Dda2LineInterpolator): int = self.mRem
proc getLft*(self: Dda2LineInterpolator): int = self.mLft
proc y*(self: Dda2LineInterpolator): int = self.mY


const
  SubpixelShift* = 8
  SubpixelScale* = 1 shl SubpixelShift
  SubpixelMask*  = SubpixelScale - 1

proc lineLr*(x: typedesc[LineBresenhamInterpolator], v: int): int = sar(v, SubpixelShift)

proc initLineBresenhamInterpolator*(x1, y1, x2, y2: int): LineBresenhamInterpolator =
  result.x1Lr = LineBresenhamInterpolator.lineLr(x1)
  result.y1Lr = LineBresenhamInterpolator.lineLr(y1)
  result.x2Lr = LineBresenhamInterpolator.lineLr(x2)
  result.y2Lr = LineBresenhamInterpolator.lineLr(y2)

  result.mVer = abs(result.x2Lr - result.x1Lr) < abs(result.y2Lr - result.y1Lr)
  result.len  = if result.mVer: abs(result.y2Lr - result.y1Lr) else: abs(result.x2Lr - result.x1Lr)

  if result.mVer:
    result.mInc = if y2 > y1: 1 else: -1
  else:
    result.mInc = if x2 > x1: 1 else: -1

  result.interpolator = initDda2LineInterpolator(if result.mVer: x1 else: y1, if result.mVer: x2 else: y2, result.len)

proc isVer*(self: LineBresenhamInterpolator): bool = self.mVer
proc len*(self: LineBresenhamInterpolator): int = self.len
proc getInc*(self: LineBresenhamInterpolator): int = self.mInc

proc hstep*(self: var LineBresenhamInterpolator) =
  inc self.interpolator
  self.x1Lr += self.mInc

proc vstep*(self: var LineBresenhamInterpolator) =
  inc self.interpolator
  self.y1Lr += self.mInc

proc x1*(self: LineBresenhamInterpolator): int = self.x1Lr
proc y1*(self: LineBresenhamInterpolator): int = self.y1Lr
proc x2*(self: LineBresenhamInterpolator): int = LineBresenhamInterpolator.lineLr(self.interpolator.y())
proc y2*(self: LineBresenhamInterpolator): int = LineBresenhamInterpolator.lineLr(self.interpolator.y())
proc x2Hr*(self: LineBresenhamInterpolator): int = self.interpolator.y()
proc y2Hr*(self: LineBresenhamInterpolator): int = self.interpolator.y()
