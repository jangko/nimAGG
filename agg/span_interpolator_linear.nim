import basics, dda_line, trans_affine
export dda_line

template spanInterpolatorLinear*(name: untyped, SubpixelShift: int) =
  type
    name*[T] = object of RootObj
      mTrans: ptr T
      mLiX, mLiY: Dda2LineInterpolator

  template getSubPixelShift*[T](x: typedesc[name[T]]): int = SubpixelShift
  template getSubPixelScale*[T](x: typedesc[name[T]]): int = 1 shl SubPixelShift

  proc begin*[T](self: var name[T], xx, yy: float64, len: int) =
    mixin transform
    const subPixelScale = getSubPixelScale(name[T])
    var
      tx = xx
      ty = yy

    self.mTrans[].transform(tx, ty)
    var
      x1 = iround(tx * subPixelScale)
      y1 = iround(ty * subPixelScale)

    tx = xx + len.float64
    ty = yy
    self.mTrans[].transform(tx, ty)
    var
      x2 = iround(tx * subPixelScale)
      y2 = iround(ty * subPixelScale)

    self.mLiX = initDda2LineInterpolator(x1, x2, len)
    self.mLiY = initDda2LineInterpolator(y1, y2, len)

  proc `init name`*[T](trans: var T): name[T] =
    result.mTrans = trans.addr

  proc init*[T](self: var name[T], trans: var T) =
    self.mTrans = trans.addr

  proc `init name`*[T](trans: var T, x, y: float64, len: int): name[T] =
    result.mTrans = trans.addr
    result.begin(x, y, len)

  proc init*[T](self: var name[T], trans: var T, x, y: float64, len: int) =
    self.mTrans = trans.addr
    self.begin(x, y, len)

  proc transformer*[T](self: var name[T]): var T = self.mTrans[]
  proc transformer*[T](self: var name[T], trans: var T) = self.mTrans = trans.addr

  proc resynchronize*[T](self: var name[T], xe, ye: float64, len: int) =
    const subPixelScale = getSubPixelScale(name[T])
    var
      xe = xe
      ye = ye
    self.mTrans[].transform(xe, ye)
    self.mLiX = initDda2LineInterpolator(self.mLiX.y(), iround(xe * subPixelScale), len)
    self.mLiY = initDda2LineInterpolator(self.mLiY.y(), iround(ye * subPixelScale), len)

  proc inc*[T](self: var name[T]) =
    inc self.mLiX
    inc self.mLiY

  proc coordinates*[T](self: var name[T], xx, yy: var int) =
    xx = self.mLiX.y()
    yy = self.mLiY.y()

template spanInterpolatorLinearSubdiv*(name: untyped, SubpixelShift: int) =
  type
    name*[T] = object of RootObj
      mSubdivShift, mSubdivSize, mSubdivMask: int
      mTrans: ptr T
      mLiX, mLiY: Dda2LineInterpolator
      mSrcX: int
      mSrcY: float
      mPos, mLen: int

  template getSubPixelShift*[T](x: typedesc[name[T]]): int = SubpixelShift
  template getSubPixelScale*[T](x: typedesc[name[T]]): int = 1 shl SubPixelShift

  proc begin*[T](self: var name[T], x, y: float64, len: int) =
    mixin transform
    const subPixelScale = getSubPixelScale(name[T])
    var
      tx, ty: float64
      len = len

    self.mPos  = 1
    self.mSrcX = iround(x * subPixelScale) + subPixelScale
    self.mSrcY = y
    self.mLen  = len

    if len > self.mSubdivSize: len = self.mSubdivSize
    tx = x
    ty = y
    self.mTrans[].transform(tx, ty)
    var
      x1 = iround(tx * subPixelScale)
      y1 = iround(ty * subPixelScale)

    tx = x + len.float64
    ty = y
    self.mTrans[].transform(tx, ty)

    self.mLiX = initDda2LineInterpolator(x1, iround(tx * subPixelScale), len)
    self.mLiY = initDda2LineInterpolator(y1, iround(ty * subPixelScale), len)

  proc init*[T](self: var name[T]) =
    self.mSubdivShift = 4
    self.mSubdivSize  = 1 shl self.mSubdivShift
    self.mSubdivMask  = self.mSubdivSize - 1

  proc init*[T](self: var name[T], trans: var T, subdivShift = 4) =
    self.mSubdivShift = subdivShift
    self.mSubdivSize  = 1 shl self.mSubdivShift
    self.mSubdivMask  = self.mSubdivSize - 1
    self.mTrans = trans.addr

  proc init*[T](self: var name[T], trans: var T, x, y: float64, len: int, subdivShift = 4) =
    self.mSubdivShift = subdivShift
    self.mSubdivSize  = 1 shl self.mSubdivShift
    self.mSubdivMask  = self.mSubdivSize - 1
    self.mTrans = trans.addr
    self.begin(x, y, len)

  proc `init name`*[T](): name[T] =
    result.init()

  proc `init name`*[T](trans: var T, subdivShift = 4): name[T] =
    result.init(trans, subdivShift)

  proc `init name`*[T](trans: var T, x, y: float64, len: int, subdivShift = 4): name[T] =
    result.init(trans, x, y, len, subdivShift)

  proc transformer*[T](self: var name[T]): var T = self.mTrans[]
  proc transformer*[T](self: var name[T], trans: var T) = self.mTrans = trans.addr

  proc subdivShift*[T](self: name[T]): int = self.mSubdivShift

  proc subdivShift*[T](self: var name[T], shift: int) =
    self.mSubdivShift = shift
    self.mSubdivSize = 1 shl self.mSubdivShift
    self.mSubdivMask = self.mSubdivSize - 1

  proc inc*[T](self: var name[T]) =
    mixin transform
    const subPixelScale = getSubPixelScale(name[T])
    inc self.mLiX
    inc self.mLiY
    if self.mPos >= self.mSubdivSize:
      var len = self.mLen
      if len > self.mSubdivSize: len = self.mSubdivSize
      var
        tx = float64(self.mSrcX) / float64(subPixelScale) + len.float64
        ty = self.mSrcY
      self.mTrans[].transform(tx, ty)
      self.mLiX = initDda2LineInterpolator(self.mLiX.y(), iround(tx * subPixelScale), len)
      self.mLiY = initDda2LineInterpolator(self.mLiY.y(), iround(ty * subPixelScale), len)
      self.mPos = 0

    self.mSrcX += subPixelScale
    inc self.mPos
    dec self.mLen

  proc coordinates*[T](self: var name[T], xx, yy: var int) =
    xx = self.mLiX.y()
    yy = self.mLiY.y()

spanInterpolatorLinear(SpanInterpolatorLinear, 8)
spanInterpolatorLinearSubdiv(SpanInterpolatorLinearSubdiv, 8)

