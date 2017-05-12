import basics, clip_liang_barsky, strutils

const
  polyMaxCoord = (1 shl 30) - 1

type
  RasConvInt* = object

proc mulDiv*(x: typedesc[RasConvInt], a, b, c: float64): int = iround((a) * (b) / (c))
proc xi*(x: typedesc[RasConvInt], v: int): int = (v)
proc yi*(x: typedesc[RasConvInt], v: int): int = (v)
proc upscale*(x: typedesc[RasConvInt], v: float64): int = iround((v) * polySubpixelScale)
proc downscale*(x: typedesc[RasConvInt], v: int): int = (v)

type
  RasConvIntSat* = object

proc mulDiv*(x: typedesc[RasConvIntSat], a, b, c: float64): int = iround((a) * (b) / (c), polyMaxCoord)
proc xi*(x: typedesc[RasConvIntSat], v: int): int = (v)
proc yi*(x: typedesc[RasConvIntSat], v: int): int = (v)
proc upscale*(x: typedesc[RasConvIntSat], v: float64): int = iround((v) * polySubpixelScale, polyMaxCoord)
proc downscale*(x: typedesc[RasConvIntSat], v: int): int = (v)

type
  RasConvInt3x* = object

proc mulDiv*(x: typedesc[RasConvInt3x], a, b, c: float64): int = iround((a) * (b) / (c))
proc xi*(x: typedesc[RasConvInt3x], v: int): int = ((v) * 3)
proc yi*(x: typedesc[RasConvInt3x], v: int): int = (v)
proc upscale*(x: typedesc[RasConvInt3x], v: float64): int = iround((v) * polySubpixelScale)
proc downscale*(x: typedesc[RasConvInt3x], v: int): int = (v)

type
  RasConvDbl* = object

proc mulDiv*(x: typedesc[RasConvDbl], a, b, c: float64): float64 = ((a) * (b) / (c))
proc xi*(x: typedesc[RasConvDbl], v: float64): int = iround((v) * polySubPixelScale)
proc yi*(x: typedesc[RasConvDbl], v: float64): int = iround((v) * polySubPixelScale)
proc upscale*(x: typedesc[RasConvDbl], v: float64): float64 = (v)
proc downscale*(x: typedesc[RasConvDbl], v: int): float64 = ((v)float64 / polySubPixelScale.float64)

type
  RasConvDbl3x* = object

proc mulDiv*(x: typedesc[RasConvDbl3x], a, b, c: float64): float64 = ((a) * (b) / (c))
proc xi*(x: typedesc[RasConvDbl3x], v: float64): int = iround((v) * polySubPixelScale * 3)
proc yi*(x: typedesc[RasConvDbl3x], v: float64): int = iround((v) * polySubPixelScale)
proc upscale*(x: typedesc[RasConvDbl3x], v: float64): float64 = (v)
proc downscale*(x: typedesc[RasConvDbl3x], v: int): float64 = ((v)float64 / polySubPixelScale.float64)

template rasterizerSlClip(Conv, name: untyped, CoordType: typed) =
  type
    name* = object
      clipBox: RectBase[CoordType]
      x1, y1: CoordType
      f1: uint
      clipping: bool

  proc `init name`*(): name =
    result.clipBox = initRectBase[CoordType](0,0,0,0)
    result.x1 = 0
    result.y1 = 0
    result.f1 = 0
    result.clipping = false

  template construct*(x: typedesc[name]): untyped = `init name`()
  template getCoordT*(x: typedesc[name]): typedesc = CoordType
  template getConvT*(x: typedesc[name]): typedesc = Conv

  proc resetClipping*(self: var name) =
    self.clipping = false

  proc clipBox*(self: var name, x1, y1, x2, y2: CoordType) =
    self.clipBox = initRectBase[CoordType](x1, y1, x2, y2)
    self.clipBox.normalize()
    self.clipping = true

  proc moveTo*(self: var name, x1, y1: CoordType) =
    self.x1 = x1
    self.y1 = y1
    if self.clipping: self.f1 = clippingFlags(x1, y1, self.clipBox)

  proc lineClipY*[Rasterizer](self: var name, ras: var Rasterizer,
    x1, y1, x2, y2: CoordType, cf1, cf2: uint) {.inline.} =

    let
      f1 = cf1 and 10
      f2 = cf2 and 10

    if (f1 or f2) == 0:
      # Fully visible
      ras.line(Conv.xi(x1), Conv.yi(y1), Conv.xi(x2), Conv.yi(y2))
    else:
      if f1 == f2:
        # Invisible by Y
        return

      var
        tx1 = x1
        ty1 = y1
        tx2 = x2
        ty2 = y2

      if (f1 and 8) != 0: # y1 < clip.y1
        tx1 = x1 + Conv.mulDiv((self.clipBox.y1-y1).float64, (x2-x1).float64, (y2-y1).float64)
        ty1 = self.clipBox.y1

      if (f1 and 2) != 0: # y1 > clip.y2
        tx1 = x1 + Conv.mulDiv((self.clipBox.y2-y1).float64, (x2-x1).float64, (y2-y1).float64)
        ty1 = self.clipBox.y2

      if (f2 and 8) != 0: # y2 < clip.y1
        tx2 = x1 + Conv.mulDiv((self.clipBox.y1-y1).float64, (x2-x1).float64, (y2-y1).float64)
        ty2 = self.clipBox.y1

      if (f2 and 2) != 0: # y2 > clip.y2
        tx2 = x1 + Conv.mulDiv((self.clipBox.y2-y1).float64, (x2-x1).float64, (y2-y1).float64)
        ty2 = self.clipBox.y2

      ras.line(Conv.xi(tx1), Conv.yi(ty1), Conv.xi(tx2), Conv.yi(ty2))

  proc lineTo*[Rasterizer](self: var name, ras: var Rasterizer, x2, y2: CoordType) =
    if self.clipping:
      let f2 = clippingFlags(x2, y2, self.clipBox)
      if ((self.f1 and 10) == (f2 and 10)) and ((self.f1 and 10) != 0):
        # Invisible by Y
          self.x1 = x2
          self.y1 = y2
          self.f1 = f2
          return

      var
        x1 = self.x1
        y1 = self.y1
        f1 = self.f1
        y3, y4: CoordType
        f3, f4: uint

      case (((f1 and 5) shl 1) or (f2 and 5))
      of 0: # Visible by X
        self.lineClipY(ras, x1, y1, x2, y2, f1, f2)
      of 1: # x2 > clip.x2
        y3 = y1 + Conv.mulDiv((self.clipBox.x2-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        self.lineClipY(ras, x1, y1, self.clipBox.x2, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x2, y3, self.clipBox.x2, y2, f3, f2)
      of 2: # x1 > clip.x2
        y3 = y1 + Conv.mulDiv((self.clipBox.x2-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        self.lineClipY(ras, self.clipBox.x2, y1, self.clipBox.x2, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x2, y3, x2, y2, f3, f2)
      of 3: # x1 > clip.x2 && x2 > clip.x2
         self.lineClipY(ras, self.clipBox.x2, y1, self.clipBox.x2, y2, f1, f2)
      of 4: # x2 < clip.x1
        y3 = y1 + Conv.mulDiv((self.clipBox.x1-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        self.lineClipY(ras, x1, y1, self.clipBox.x1, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x1, y3, self.clipBox.x1, y2, f3, f2)
      of 6: # x1 > clip.x2 && x2 < clip.x1
        y3 = y1 + Conv.mulDiv((self.clipBox.x2-x1).float64, (y2-y1).float64, (x2-x1).float64)
        y4 = y1 + Conv.mulDiv((self.clipBox.x1-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        f4 = clippingFlagsY(y4, self.clipBox)
        self.lineClipY(ras, self.clipBox.x2, y1, self.clipBox.x2, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x2, y3, self.clipBox.x1, y4, f3, f4)
        self.lineClipY(ras, self.clipBox.x1, y4, self.clipBox.x1, y2, f4, f2)
      of 8: # x1 < clip.x1
        y3 = y1 + Conv.mulDiv((self.clipBox.x1-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        self.lineClipY(ras, self.clipBox.x1, y1, self.clipBox.x1, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x1, y3, x2, y2, f3, f2)
      of 9:  # x1 < clip.x1 && x2 > clip.x2
        y3 = y1 + Conv.mulDiv((self.clipBox.x1-x1).float64, (y2-y1).float64, (x2-x1).float64)
        y4 = y1 + Conv.mulDiv((self.clipBox.x2-x1).float64, (y2-y1).float64, (x2-x1).float64)
        f3 = clippingFlagsY(y3, self.clipBox)
        f4 = clippingFlagsY(y4, self.clipBox)
        self.lineClipY(ras, self.clipBox.x1, y1, self.clipBox.x1, y3, f1, f3)
        self.lineClipY(ras, self.clipBox.x1, y3, self.clipBox.x2, y4, f3, f4)
        self.lineClipY(ras, self.clipBox.x2, y4, self.clipBox.x2, y2, f4, f2)
      of 12: # x1 < clip.x1 && x2 < clip.x1
        self.lineClipY(ras, self.clipBox.x1, y1, self.clipBox.x1, y2, f1, f2)
      else:
        doAssert(false, "clipping error")

      self.f1 = f2
    else:
      ras.line(Conv.xi(self.x1), Conv.yi(self.y1), Conv.xi(x2), Conv.yi(y2))
    self.x1 = x2
    self.y1 = y2

rasterizerSlClip(RasConvInt, RasterizerSlClipInt, int)
rasterizerSlClip(RasConvIntSat, RasterizerSlClipIntSat, int)
rasterizerSlClip(RasConvInt3x, RasterizerSlClipInt3x, int)
rasterizerSlClip(RasConvDbl, RasterizerSlClipDbl, float64)
rasterizerSlClip(RasConvDbl3x, RasterizerSlClipDbl3x, float64)

type
  RasterizerSlNoClip* = object
    x1, y1: int

proc initRasterizerSlNoClip*(): RasterizerSlNoClip =
  result.x1 = 0
  result.y1 = 0

proc resetClipping*(self: RasterizerSlNoClip) = discard
proc clipBox*(self: var RasterizerSlNoClip, x1, y1, x2, y2: int) = discard
proc moveTo*(self: var RasterizerSlNoClip, x1, y1: int) =
  self.x1 = x1
  self.y1 = y1

proc lineTo*[Rasterizer](self: var RasterizerSlNoClip, ras: Rasterizer, x2, y2: int) =
  ras.line(self.x1, self.y1, x2, y2)
  self.x1 = x2
  self.y1 = y2
