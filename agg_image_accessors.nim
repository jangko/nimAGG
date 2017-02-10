import agg_basics, agg_pixfmt_rgb

type
  ImageAccessorClip*[PixFmt] = object
    mPixF: ptr PixFmt
    mBkBuf: array[4, uint8]
    mX, mX0, mY: int
    mPixPtr: ptr uint8
    
template getOrderType*[PixFmt](x: typedesc[ImageAccessorClip[PixFmt]]): typedesc = getOrderType(PixFmt.type)

proc initImageAccessorClip*[PixFmt, ColorT](pixf: var PixFmt, bk: ColorT): ImageAccessorClip[PixFmt] =
  result.mPixF = pixf.addr
  makePix(PixFmt, result.mBkBuf[0].addr, bk)

proc attach*[PixFmt](self: var ImageAccessorClip[PixFmt], pixf: var PixFmt) =
   self.mPixF = pixf.addr

proc backgroundColor*[PixFmt, ColorT](self: var ImageAccessorClip[PixFmt], bk: ColorT) =
   makePix(PixFmt, self.mBkBuf[0].addr, bk)

proc pixel*[PixFmt](self: var ImageAccessorClip[PixFmt]): ptr uint8 {.inline.} =
  if self.mY >= 0 and self.mY < self.mPixF[].height() and
     self.mX >= 0 and self.mX < self.mPixF[].width():
     return self.mPixF[].pixPtr(self.mX, self.mY)
  result = self.mBkBuf[0].addr

proc span*[PixFmt](self: var ImageAccessorClip[PixFmt], x,y,len:int): ptr uint8 {.inline.} =
  self.mX  =  x
  self.mX0 = x
  self.mY  = y
  if y >= 0 and y < self.mPixF[].height() and
     x >= 0 and x+len <= self.mPixF[].width():
     self.mPixPtr = self.mPixF[].pixPtr(x, y)
     return self.mPixPtr

  self.mPixPtr = nil
  result = self.pixel()

proc nextX*[PixFmt](self: var ImageAccessorClip[PixFmt]): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  if self.mPixPtr != nil:
    inc(self.mPixPtr, pixWidth)
    return self.mPixPtr
  inc self.mX
  result = self.pixel()

proc nextY*[PixFmt](self: var ImageAccessorClip[PixFmt]): ptr uint8 {.inline.} =
  inc self.mY
  self.mX = self.mX0
  if self.mPixPtr != nil and self.mY >= 0 and self.mY < self.mPixF[].height():
    self.mPixPtr = self.mPixF[].pixPtr(self.mX, self.mY)
    return self.mPixPtr
  self.mPixPtr = nil
  result = self.pixel()


type
  ImageAccessorNoClip*[PixFmt] = object
    mPixF: ptr PixFmt
    mX, mY: int
    mPixPtr: ptr uint8
    
template getOrderType*[PixFmt](x: typedesc[ImageAccessorNoClip[PixFmt]]): typedesc = getOrderType(PixFmt.type)

proc initImageAccessorNoClip*[PixFmt](pixf: var PixFmt): ImageAccessorNoClip[PixFmt] =
  result.mPixF = pixf.addr

proc attach*[PixFmt](self: var ImageAccessorNoClip[PixFmt], pixf: var PixFmt) =
  self.mPixF = pixf.addr

proc span*[PixFmt](self: var ImageAccessorNoClip[PixFmt], x,y,z:int): ptr uint8 {.inline.} =
  self.mX = x
  self.mY = y
  self.mPixPtr = self.mPixF[].pixPtr(x, y)
  result = self.mPixPtr

proc nextX*[PixFmt](self: var ImageAccessorNoClip[PixFmt]): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  inc(self.mPixPtr, pixWidth)
  result = self.mPixPtr

proc nextY*[PixFmt](self: var ImageAccessorNoClip[PixFmt]): ptr uint8 {.inline.} =
  inc self.mY
  self.mPixPtr = self.mPixF[].pixPtr(self.mX, self.mY)
  result = self.mPixPtr

type
  ImageAccessorClone*[PixFmt] = object
    mPixF: ptr PixFmt
    mX, mX0, mY: int
    mPixPtr: ptr uint8

template getOrderType*[PixFmt](x: typedesc[ImageAccessorClone[PixFmt]]): typedesc = getOrderType(PixFmt.type)

proc initImageAccessorClone*[PixFmt](pixf: var PixFmt): ImageAccessorClone[PixFmt] =
  result.mPixF = pixf.addr

proc attach*[PixFmt](self: var ImageAccessorClone[PixFmt], pixf: var PixFmt) =
  self.mPixF = pixf.addr

proc pixel*[PixFmt](self: var ImageAccessorClone[PixFmt]): ptr uint8 {.inline.} =
  var
    x = self.mX
    y = self.mY

  if x < 0: x = 0
  if y < 0: y = 0
  if x >= self.mPixF[].width():  x = self.mPixF[].width() - 1
  if y >= self.mPixF[].height(): y = self.mPixF[].height() - 1
  result = self.mPixF[].pixPtr(x, y)

proc span*[PixFmt](self: var ImageAccessorClone[PixFmt], x,y,len:int): ptr uint8 {.inline.} =
  self.mX = x
  self.mX0 = x
  self.mY = y
  if y >= 0 and y < self.mPixF[].height() and
     x >= 0 and x+len <= self.mPixF[].width():
     self.mPixPtr = self.mPixF[].pixPtr(x, y)
     return self.mPixPtr
  self.mPixPtr = nil
  result = self.pixel()

proc nextX*[PixFmt](self: var ImageAccessorClone[PixFmt]): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  if self.mPixPtr != nil:
    inc(self.mPixPtr, pixWidth)
    return self.mPixPtr

  inc self.mX
  result = self.pixel()

proc nextY*[PixFmt](self: var ImageAccessorClone[PixFmt]): ptr uint8 {.inline.} =
  inc self.mY
  self.mX = self.mX0
  if self.mPixPtr != nil and self.mY >= 0 and self.mY < self.mPixF[].height():
    self.mPixPtr = self.mPixF[].pixPtr(self.mX, self.mY)
    return self.mPixPtr
  self.mPixPtr = nil
  result = self.pixel()

type
  ImageAccessorWrap*[PixFmt, WrapX, WrapY] = object
    mPixF: ptr PixFmt
    mRowPtr: ptr uint8
    mX: int
    mWrapX: WrapX
    mWrapY: WrapY

template getOrderType*[PixFmt, WrapX, WrapY](x: typedesc[ImageAccessorWrap[PixFmt, WrapX, WrapY]]): typedesc = getOrderType(PixFmt.type)

proc initImageAccessorWrap*[PixFmt, WrapX, WrapY](pixf: var PixFmt): ImageAccessorWrap[PixFmt, WrapX, WrapY] =
  result.mPixF = pixf.addr
  result.mWrapX = pixf.width()
  result.mWrapY = pixf.height()

proc attach*[PixFmt, WrapX, WrapY](self: var ImageAccessorWrap[PixFmt, WrapX, WrapY], pixf: var PixFmt) =
  self.mPixF = pixf.addr

proc span*[PixFmt, WrapX, WrapY](self: var ImageAccessorWrap[PixFmt, WrapX, WrapY], x,y,z:int): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  self.mX = x
  self.mRowPtr = self.mPixF[].rowPtr(self.mWrapY(y))
  result = self.mRowPtr + self.mWrapX(x) * pixWidth

proc nextX*[PixFmt, WrapX, WrapY](self: var ImageAccessorWrap[PixFmt, WrapX, WrapY]): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  inc self.mWrapX
  let x = self.mWrapX
  result = self.mRowPtr + x * pixWidth

proc nextY*[PixFmt, WrapX, WrapY](self: var ImageAccessorWrap[PixFmt, WrapX, WrapY]): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(PixFmt)
  inc self.mWrapY
  self.mRowPtr = self.mPixF[].rowPtr(self.mWrapY)
  result = self.mRowPtr + self.mWrapX(self.mX) * pixWidth


type
  WrapModeRepeat* = object
    mSize, mAdd, mValue: int

proc initWrapModeRepeat*(size: int): WrapModeRepeat =
  result.mSize = size
  result.mAdd = size * (0x3FFFFFFF div size)
  result.mValue = 0

proc getValue*(self: var WrapModeRepeat, v: int): int {.inline.} =
  self.mValue = (v + self.mAdd) mod self.mSize
  self.mValue

proc inc*(self: var WrapModeRepeat): int {.inline.} =
  inc self.mValue
  if self.mValue >= self.mSize: self.mValue = 0
  self.mValue

type
  WrapModeRepeatPow2* = object
    mMask, mValue: int

proc initWrapModeRepeatPow2*(size: int): WrapModeRepeatPow2 =
  result.mValue = 0
  result.mMask = 1
  while result.mMask < size:
    result.mMask = (result.mMask shl 1) or 1
  result.mMask = result.mMask shr 1

proc getValue*(self: var WrapModeRepeatPow2, v: int): int {.inline.} =
  self.mValue = v and self.mMask
  self.mValue

proc inc*(self: var WrapModeRepeatPow2): int {.inline.} =
  inc self.mValue
  if self.mValue > self.mMask: self.mValue = 0
  self.mValue

type
  WrapModeRepeatAutoPow2 = object
    mSize, mAdd, mMask, mValue: int

proc initWrapModeRepeatAutoPow2*(size: int): WrapModeRepeatAutoPow2 =
  result.mSize = size
  result.mAdd = size * (0x3FFFFFFF div size)
  result.mMask = if (result.mSize and (result.mSize-1)) != 0: 0 else: result.mSize-1
  result.mValue = 0

proc getValue*(self: var WrapModeRepeatAutoPow2, v: int): int {.inline.} =
  if self.mMask != 0:
    self.mValue = v and self.mMask
    return self.mValue
  self.mValue = (v + self.mAdd) mod self.mSize
  self.mValue

proc inc*(self: var WrapModeRepeatAutoPow2): int {.inline.} =
  inc self.mValue
  if self.mValue >= self.mSize: self.mValue = 0
  self.mValue

type
  WrapModeReflect* = object
    mSize, mSize2, mAdd, mValue: int

proc initWrapModeReflect*(size: int): WrapModeReflect =
  result.mSize = size
  result.mSize2 = size * 2
  result.mAdd = result.mSize2 * (0x3FFFFFFF div result.mSize2)
  result.mValue = 0

proc getValue*(self: var WrapModeReflect, v: int): int {.inline.} =
  self.mValue = (v + self.mAdd) mod self.mSize2
  if self.mValue >= self.mSize: return self.mSize2 - self.mValue - 1
  self.mValue

proc inc*(self: var WrapModeReflect): int {.inline.} =
  inc self.mValue
  if self.mValue >= self.mSize2: self.mValue = 0
  if self.mValue >= self.mSize:
    return self.mSize2 - self.mValue - 1
  self.mValue

type
  WrapModeReflectPow2* = object
    mSize, mMask, mValue: int

proc initWrapModeReflectPow2*(size: int): WrapModeReflectPow2 =
  result.mValue = 0
  result.mMask = 1
  result.mSize = 1
  while result.mMask < size:
    result.mMask = (result.mMask shl 1) or 1
    result.mSize = result.mSize shl 1

proc getValue*(self: var WrapModeReflectPow2, v: int): int {.inline.} =
  self.mValue = v and self.mMask
  if self.mValue >= self.mSize:
    return self.mMask - self.mValue
  self.mValue

proc inc*(self: var WrapModeReflectPow2): int {.inline.} =
  inc self.mValue
  self.mValue = self.mValue and self.mMask
  if self.mValue >= self.mSize:
    return self.mMask - self.mValue
  self.mValue

type
  WrapModeReflectAutoPow2 = object
    mSize, mSize2, mAdd, mMask, mValue: int

proc initWrapModeReflectAutoPow2*(size: int): WrapModeReflectAutoPow2 =
  result.mSize = size
  result.mSize2 = size * 2
  result.mAdd = result.mSize2 * (0x3FFFFFFF div result.mSize2)
  result.mMask = if (result.mSize2 and (result.mSize2-1)) != 0: 0 else: result.mSize2-1
  result.mValue = 0

proc getValue*(self: var WrapModeReflectAutoPow2, v: int): int {.inline.} =
  self.mValue = if self.mMask != 0: v and self.mMask else: (v + self.mAdd) mod self.mSize2
  if self.mValue >= self.mSize:
    return self.mSize2 - self.mValue - 1
  self.mValue

proc inc*(self: var WrapModeReflectAutoPow2): int {.inline.} =
  inc self.mValue
  if self.mValue >= self.mSize2: self.mValue = 0
  if self.mValue >= self.mSize:
    return self.mSize2 - self.mValue - 1
  self.mValue
