import agg_basics

template spanInterpolatorTrans*(name: untyped, SubpixelShift: int) =
  type
    name*[Transformer] = object
      mTrans: ptr Transformer
      mX, mY: float64
      mIx, mIy: int

  template getSubPixelShift*[T](x: typedesc[name[T]]): int = SubpixelShift
  template getSubPixelScale*[T](x: typedesc[name[T]]): int = 1 shl getSubPixelShift(x)

  proc begin*[T](self: var name[T], x, y: float64, z: int) =
    mixin transform
    var
      x = x
      y = y
    const subPixelScale = getSubPixelScale(self.type)
    self.mX = x
    self.mY = y
    self.mTrans[].transform(x, y)
    self.mIx = iround(x * subPixelScale)
    self.mIy = iround(y * subPixelScale)

  proc `init name`*[T](trans: var T): name[T] =
    result.mTrans = trans.addr

  proc `init name`*[T](trans: var T, x, y: float64, z: int): name[T] =
    result.mTrans = trans.addr
    result.begin(x, y, 0)

  proc transformer*[T](self: var name[T]): var T = self.mTrans[]
  proc transformer*[T](self: var name[T], trans: var T) =
    self.mTrans = trans.addr

  proc inc*[T](self: var name[T]) =
    mixin transform
    const subPixelScale = getSubPixelScale(self.type)
    self.mX += 1.0
    var
      x = self.mX
      y = self.mY
    self.mTrans[].transform(x, y)
    self.mIx = iround(x * subPixelScale)
    self.mIy = iround(y * subPixelScale)

  proc coordinates*[T](self: name[T], x, y: var int) =
    x = self.mIx
    y = self.mIy

spanInterpolatorTrans(SpanInterpolatorTrans, 8)