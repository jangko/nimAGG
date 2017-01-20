import agg_basics, agg_dda_line, agg_trans_affine

template spanInterpolatorLinear(name: untyped, Transformer: typed, SubpixelShift: int) =
  type
    name* = object
      mTrans: ptr Transformer
      mLiX, mLiY: Dda2LineInterpolator

  template getSubPixelShift*(x: typedesc[name]): int = SubpixelShift
  template getSubPixelScale*(x: typedesc[name]): int = 1 shl SubPixelShift

  proc begin*(self: var name, x, y: float64, len: int)

  proc `init name`*(trans: var Transformer): name =
    result.mTrans = trans.addr

  proc `init name`*(trans: var Transformer, x, y: float64, len: int): name =
    result.mTrans = trans.addr
    result.begin(x, y, len)

  proc transformer*(self: var name): var Transformer = self.mTrans[]
  proc transformer*(self: var name, trans: var Transformer) = self.mTrans = trans.addr

  proc begin(self: var name, x, y: float64, len: int) =
    const subPixelScale = getSubPixelScale(name)
    var
      tx = x
      ty = y

    self.mTrans[].transform(tx, ty)
    var
      x1 = iround(tx * subPixelScale)
      y1 = iround(ty * subPixelScale)

    tx = x + len.float64
    ty = y
    self.mTrans[].transform(tx, ty)
    var
      x2 = iround(tx * subPixelScale)
      y2 = iround(ty * subPixelScale)

    self.mLiX = initDda2LineInterpolator(x1, x2, len)
    self.mLiY = initDda2LineInterpolator(y1, y2, len)

  proc resynchronize*(self: var name, xee, yee: float64, len: int) =
    const subPixelScale = getSubPixelScale(name)
    var
      xe = xee
      ye = yee
    self.mTrans[].transform(xe, ye)
    self.mLiX = initDda2LineInterpolator(self.mLiX.y(), iround(xe * subPixelScale), len)
    self.mLiY = initDda2LineInterpolator(self.mLiY.y(), iround(ye * subPixelScale), len)

  proc inc*(self: var name) =
    inc self.mLiX
    inc self.mLiY

  proc coordinates*(self: var name, x, y: var int) =
    x = self.mLiX.y()
    y = self.mLiY.y()



template spanInterpolatorLinearSubdiv(name: untyped, Transformer: typed, SubpixelShift: int) =
  type
    name* = object
      mSubdivShift, mSubdivSize, mSubdivMask: int
      mTrans: ptr Transformer
      mLiX, mLiY: Dda2LineInterpolator
      mSrcX: int
      mSrcY: float
      mPos, mLen: int

  template getSubPixelShift*(x: typedesc[name]): int = SubpixelShift
  template getSubPixelScale*(x: typedesc[name]): int = 1 shl SubPixelShift

  proc begin*(self: var name, x, y: float64, lenx: int)

  proc `init name`*(): name =
    result.mSubdivShift = 4
    result.mSubdivSize  = 1 shl result.mSubdivShift
    result.mSubdivMask  = result.mSubdivSize - 1

  proc `init name`*(trans: var Transformer, subdivShift = 4): name =
    result.mSubdivShift = subdivShift
    result.mSubdivSize  = 1 shl result.mSubdivShift
    result.mSubdivMask  = result.mSubdivSize - 1
    result.mTrans = trans.addr

  proc `init name`*(trans: var Transformer,
    x, y: float64, len: int, subdivShift = 4): name =
    result.mSubdivShift = subdivShift
    result.mSubdivSize  = 1 shl result.mSubdivShift
    result.mSubdivMask  = result.mSubdivSize - 1
    result.mTrans = trans.addr
    result.begin(x, y, len)

  proc transformer*(self: var name): var Transformer = self.mTrans[]
  proc transformer*(self: var name, trans: var Transformer) = self.mTrans = trans.addr

  proc subdivShift*(self: name): int = self.mSubdivShift

  proc subdivShift*(self: var name, shift: int) =
    self.mSubdivShift = shift
    self.mSubdivSize = 1 shl self.mSubdivShift
    self.mSubdivMask = self.mSubdivSize - 1

  proc begin(self: var name, x, y: float64, lenx: int) =
    const subPixelScale = getSubPixelScale(name)
    var
      tx, ty: float64
      len = lenx

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

  proc inc*(self: var name) =
    const subPixelScale = getSubPixelScale(name)
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

  proc coordinates*(self: var name, x, y: var int) =
    x = self.mLiX.y()
    y = self.mLiY.y()

spanInterpolatorLinear(SpanInterpolatorLinear, TransAffine, 8)
spanInterpolatorLinearSubdiv(SpanInterpolatorLinearSubdiv, TransAffine, 8)

