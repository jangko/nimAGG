import trans_affine, basics, strutils

type
  AspectRatio* = enum
    aspectRatioStretch
    aspectRatioMeet
    aspectRatioSlice

  TransViewport* = object
    mWorld: RectD
    mDevice: RectD
    mAspect: AspectRatio
    mIsValid: bool
    mAlignX, mAlignY: float64
    mW: RectD
    mDx1, mDy1: float64
    mKx, mKy: float64

proc initTransViewport*(): TransViewport =
  result.mWorld   = initRectD(0.0, 0.0, 1.0, 1.0)
  result.mDevice  = initRectD(0.0, 0.0, 1.0, 1.0)
  result.mAspect  = aspectRatioStretch
  result.mIsValid = true
  result.mAlignX  = 0.5
  result.mAlignY  = 0.5
  result.mW       = initRectD(0.0, 0.0, 1.0, 1.0)
  result.mDx1 = 0.0
  result.mDy1 = 0.0
  result.mKx  = 1.0
  result.mKy  = 1.0

proc update*(self: var TransViewport)

proc preserveAspectRatio*(self: var TransViewport, alignx, aligny: float64, aspect: AspectRatio) =
  self.mAlignX = alignx
  self.mAlignY = aligny
  self.mAspect = aspect
  self.update()

proc setDeviceViewport*(self: var TransViewport, x1, y1, x2, y2: float64) =
  self.mDevice.x1 = x1
  self.mDevice.y1 = y1
  self.mDevice.x2 = x2
  self.mDevice.y2 = y2
  self.update()

proc deviceViewport*(self: var TransViewport, v: RectD) =
  self.mDevice = v
  self.update()

proc setWorldViewport*(self: var TransViewport, x1, y1, x2, y2: float64) =
  self.mWorld.x1 = x1
  self.mWorld.y1 = y1
  self.mWorld.x2 = x2
  self.mWorld.y2 = y2
  self.update()

proc worldViewport*(self: var TransViewport, v: RectD) =
  self.mWorld = v
  self.update()

proc getDeviceViewport*(self: TransViewport, x1, y1, x2, y2: var float64) =
  x1 = self.mDevice.x1
  y1 = self.mDevice.y1
  x2 = self.mDevice.x2
  y2 = self.mDevice.y2

proc deviceViewport*(self: TransViewport, v: var RectD) =
  v = self.mDevice

proc deviceViewport*(self: var TransViewport): RectD =
  self.mDevice

proc getWorldViewport*(self: var TransViewport, x1, y1, x2, y2: var float64) =
  x1 = self.mWorld.x1
  y1 = self.mWorld.y1
  x2 = self.mWorld.x2
  y2 = self.mWorld.y2

proc worldViewport*(self: TransViewport, v: var RectD) =
  v = self.mWorld

proc worldViewport*(self: var TransViewport): RectD =
  self.mWorld

proc worldViewportActual*(self: TransViewport, x1, y1, x2, y2: var float64) =
  x1 = self.mW.x1
  y1 = self.mW.y1
  x2 = self.mW.x2
  y2 = self.mW.y2

proc worldViewportActual*(self: TransViewport, v: var RectD) =
  v = self.mW

proc worldViewportActual*(self: TransViewport): RectD =
  self.mW

proc isValid*(self: TransViewport): bool =
  self.mIsValid

proc alignX*(self: TransViewport): float64 =
  self.mAlignX

proc alignY*(self: TransViewport): float64 =
  self.mAlignY

proc aspectRatio*(self: TransViewport): AspectRatio =
  self.mAspect

proc transform*(self: TransViewport, x, y: var float64) =
  x = (x - self.mW.x1) * self.mKx + self.mDx1
  y = (y - self.mW.y1) * self.mKy + self.mDy1

proc transformScaleOnly*(self: TransViewport, x, y: var float64) =
  x *= self.mKx
  y *= self.mKy

proc inverseTransform*(self: var TransViewport, x, y: var float64) =
  x = (x - self.mDx1) / self.mKx + self.mW.x1
  y = (y - self.mDy1) / self.mKy + self.mW.y1

proc inverseTransformScaleOnly*(self: var TransViewport, x, y: var float64) =
  x /= self.mKx
  y /= self.mKy

proc deviceDx*(self: TransViewport): float64 =
  self.mDx1 - self.mW.x1 * self.mKx

proc deviceDy*(self: TransViewport): float64 =
  self.mDy1 - self.mW.y1 * self.mKy

proc scaleX*(self: TransViewport): float64 =
  self.mKx

proc scaleY*(self: var TransViewport): float64 =
  self.mKy

proc scale*(self: var TransViewport): float64 =
  result = (self.mKx + self.mKy) * 0.5

proc toAffine*(self: TransViewport): TransAffine =
  var mtx = transAffineTranslation(-self.mW.x1, -self.mW.y1)
  mtx *= transAffineScaling(self.mKx, self.mKy)
  mtx *= transAffineTranslation(self.mDx1, self.mDy1)
  mtx

proc toAffineScaleOnly*(self: TransViewport): TransAffine =
  transAffineScaling(self.mKx, self.mKy)

proc byteSize*(self: TransViewport): int =
  sizeof(self)

proc serialize*(self: TransViewport, p: ptr uint8) =
  copyMem(p, self.unsafeAddr, sizeof(self))

proc deserialize*(self: var TransViewport, p: ptr uint8) =
  copyMem(self.addr, p, sizeof(self))

proc update*(self: var TransViewport) =
  const epsilon = 1e-30
  if abs(self.mWorld.x1  - self.mWorld.x2)  < epsilon or
     abs(self.mWorld.y1  - self.mWorld.y2)  < epsilon or
     abs(self.mDevice.x1 - self.mDevice.x2) < epsilon or
     abs(self.mDevice.y1 - self.mDevice.y2) < epsilon:
     self.mW.x1 = self.mWorld.x1
     self.mW.y1 = self.mWorld.y1
     self.mW.x2 = self.mWorld.x1 + 1.0
     self.mW.y2 = self.mWorld.y2 + 1.0
     self.mDx1 = self.mDevice.x1
     self.mDy1 = self.mDevice.y1
     self.mKx  = 1.0
     self.mKy  = 1.0
     self.mIsValid = false
     return

  var
    world_x1  = self.mWorld.x1
    world_y1  = self.mWorld.y1
    world_x2  = self.mWorld.x2
    world_y2  = self.mWorld.y2
    device_x1 = self.mDevice.x1
    device_y1 = self.mDevice.y1
    device_x2 = self.mDevice.x2
    device_y2 = self.mDevice.y2

  if self.mAspect != aspectRatioStretch:
    self.mKx = (device_x2 - device_x1) / (world_x2 - world_x1)
    self.mKy = (device_y2 - device_y1) / (world_y2 - world_y1)

    if (self.mAspect == aspectRatioMeet) == (self.mKx < self.mKy):
      let d     = (world_y2 - world_y1) * self.mKy / self.mKx
      world_y1 += (world_y2 - world_y1 - d) * self.mAlignY
      world_y2  =  world_y1 + d
    else:
      let d     = (world_x2 - world_x1) * self.mKx / self.mKy
      world_x1 += (world_x2 - world_x1 - d) * self.mAlignX
      world_x2  =  world_x1 + d

  self.mW.x1 = world_x1
  self.mW.y1 = world_y1
  self.mW.x2 = world_x2
  self.mW.y2 = world_y2
  self.mDx1  = device_x1
  self.mDy1  = device_y1
  self.mKx   = (device_x2 - device_x1) / (world_x2 - world_x1)
  self.mKy   = (device_y2 - device_y1) / (world_y2 - world_y1)
  self.mIsValid = true
