import agg_basics, agg_rendering_buffer, agg_color_rgba

type
  BlenderRgb*[ColorT, OrderT] = object
  BlenderRgbPre*[ColorT, OrderT] = object
  BlenderRgbGamma*[ColorT, OrderT, GammaT] = object
    gamma: GammaT

  PixfmtAlphaBlendRgb*[Blender, RenBuf] = object
    blender: Blender
    rbuf: ptr RenBuf

template getOrderType*[C,O](x: typedesc[BlenderRgb[C,O]]): typedesc = O
template getValueType*[C,O](x: typedesc[BlenderRgb[C,O]]): untyped = getValueType(C.type)
template getColorType*[C,O](x: typedesc[BlenderRgb[C,O]]): typedesc = C
template getPixWidth* [C,O](x: typedesc[BlenderRgb[C,O]]): int = sizeof(getValueType(C.type)) * 3

template getOrderType*[C,O](x: typedesc[BlenderRgbPre[C,O]]): typedesc = O
template getValueType*[C,O](x: typedesc[BlenderRgbPre[C,O]]): untyped = getValueType(C.type)
template getColorType*[C,O](x: typedesc[BlenderRgbPre[C,O]]): typedesc = C
template getPixWidth* [C,O](x: typedesc[BlenderRgbPre[C,O]]): int = sizeof(getValueType(C.type)) * 3

template getOrderType*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): typedesc = O
template getValueType*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): untyped = getValueType(C.type)
template getColorType*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): typedesc = C
template getPixWidth* [C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): int = sizeof(getValueType(C.type)) * 3

template getOrderType*[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): typedesc = getOrderType(B.type)
template getColorType*[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): typedesc = getColorType(B.type)

proc blendPix*[C,O,T](self: BlenderRgb[C,O], p: ptr T,
  cr, cg, cb, alpha: uint, cover=0.uint) {.inline.} =
  const
    baseShift = getBaseShift(C)

  p[O.R] = p[O.R] + T(((cr - p[O.R].uint) * alpha) shr baseShift)
  p[O.G] = p[O.G] + T(((cg - p[O.G].uint) * alpha) shr baseShift)
  p[O.B] = p[O.B] + T(((cb - p[O.B].uint) * alpha) shr baseShift)

proc blendPix*[C,O,T](self: BlenderRgbPre[C,O], p: ptr T,
  cr, cg, cb, alpha, cover: uint) {.inline.} =
  const
    baseShift = getBaseShift(C)
    baseMask  = getBaseMask(C)

  let al = baseMask - alpha
  let co = (cover + 1) shl (baseShift - 8)

  p[O.R] = T((p[O.R] * al + cr * co) shr baseShift)
  p[O.G] = T((p[O.G] * al + cg * co) shr baseShift)
  p[O.B] = T((p[O.B] * al + cb * co) shr baseShift)

proc blendPix*[C,O,T](self: BlenderRgbPre[C,O], p: ptr T,
  cr, cg, cb, alpha: uint) {.inline.} =
  const
    baseShift = getBaseShift(C)
    baseMask  = getBaseMask(C)

  let al = baseMask - alpha
  p[O.R] = T(((p[O.R] * al) shr baseShift) + cr)
  p[O.G] = T(((p[O.G] * al) shr baseShift) + cg)
  p[O.B] = T(((p[O.B] * al) shr baseShift) + cb)

proc setGamma*[C,O,G](self: var BlenderRgbGamma[C,O,G], gamma: G) =
  self.gamma = gamma

proc blendPix*[C,O,T,G](self: BlenderRgbGamma[C,O,G], p: ptr T,
  cr, cg, cb, alpha: uint, cover=0.uint) {.inline.} =
  type
    CalcType = getCalcType(C)
  const
    baseShift = getBaseShift(C)
    baseMask = getBaseMask(C)

  let r = self.gamma.dir(p[O.R]).int
  let g = self.gamma.dir(p[O.G]).int
  let b = self.gamma.dir(p[O.B]).int
  
  p[O.R] = self.gamma.inv(((((self.gamma.dir(cr).int - r) * alpha.int) shr baseShift) + r) and baseMask)
  p[O.G] = self.gamma.inv(((((self.gamma.dir(cg).int - g) * alpha.int) shr baseShift) + g) and baseMask)
  p[O.B] = self.gamma.inv(((((self.gamma.dir(cb).int - b) * alpha.int) shr baseShift) + b) and baseMask)

proc copyPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, c: ColorT) =
  type
    OrderType = getOrderType(Blender)
    ValueType = getValueType(Blender)

  var p = self.rbuf[].rowPtr(x, y, 1) + x + x + x
  p[OrderType.R] = c.r
  p[OrderType.G] = c.g
  p[OrderType.B] = c.b

proc makePix*[Blender, RenBuf, ColorT](x: typedesc[PixfmtAlphaBlendRgb[Blender, RenBuf]],
  p: pointer, c: ColorT) =

  type
    OrderType = getOrderType(Blender)
    ValueType = getValueType(Blender)

  cast[ptr ValueType](p)[OrderType.R] = c.r
  cast[ptr ValueType](p)[OrderType.G] = c.g
  cast[ptr ValueType](p)[OrderType.B] = c.b

proc pixel*[Blender, RenBuf](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int): auto =

  type
    OrderType = getOrderType(Blender)
    ValueType = getValueType(Blender)

  var p = self.rbuf[].rowPtr(y) + x + x + x
  result = construct(getColorType(Blender), p[OrderType.R], p[OrderType.G], p[OrderType.B])

proc height*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int =
  result = self.rbuf[].height()

proc width*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int =
  result = self.rbuf[].width()

proc stride*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int =
  result = self.rbuf[].stride()

proc rowPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], y: int): auto =
  result = self.rbuf[].rowPtr(y)

proc row*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], y: int): auto =
  result = self.rbuf[].row(y)

proc pixPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], x, y: int): auto =
  const pixWidth = getPixWidth(Blender)
  result = self.rbuf[].rowPtr(y) + x * pixWidth

proc copyOrBlendPix[Blender, RenBuf, C, T](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  p: ptr T, c: C, cover: uint) {.inline.} =
  type
    CalcType = getCalcType(C)
    OrderType = getOrderType(Blender)
  const
    baseMask = getBaseMask(C)

  if c.a != 0:
    let alpha = (CalcType(c.a) * CalcType(cover + 1)) shr 8
    if alpha == baseMask:
      p[OrderType.R] = c.r
      p[OrderType.G] = c.g
      p[OrderType.B] = c.b
    else:
      self.blender.blendPix(p, c.r.uint, c.g.uint, c.b.uint, alpha, cover)

proc copyOrBlendPix[Blender, RenBuf, C, T](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  p: ptr T, c: C) {.inline.} =

  type OrderType = getOrderType(Blender)
  const baseMask = getBaseMask(C)

  if c.a != 0:
    if c.a == baseMask:
      p[OrderType.R] = c.r
      p[OrderType.G] = c.g
      p[OrderType.B] = c.b
  else:
    self.blender.blendPix(p, c.r.uint, c.g.uint, c.b.uint, c.a.uint)

proc blendPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, c: ColorT, cover: uint8) =
  let p = self.rbuf[].rowPtr(x, y, 1) + x + x + x
  self.copyOrBlendPix(p, c, cover)

proc blendColorHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    ValueType = getValueType(Blender)

  var
    p = cast[ptr ValueType](self.rbuf[].rowPtr(x, y, length) + x + x + x)
    len = length
    co = colors
    cv = covers

  if covers != nil:
    doWhile len != 0:
      self.copyOrBlendPix(p, co[], cv[])
      inc co
      inc cv
      inc(p, 3)
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      self.copyOrBlendPix(p, co[])
      inc co
      inc(p, 3)
      dec len
  else:
    doWhile len != 0:
      self.copyOrBlendPix(p, co[], cover)
      inc co
      inc(p, 3)
      dec len

proc blendColorVspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    ValueType = getValueType(Blender)

  var
    len = length
    line = y
    cv = covers
    co = colors

  if covers != nil:
    doWhile len != 0:
      let p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[], cv[])
      inc cv
      inc co
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      let p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[])
      inc co
      dec len
  else:
    doWhile len != 0:
      let p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[], cover)
      inc co
      dec len

proc copyHline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT) =

  type
    OrderType = getOrderType(Blender)

  var
    len = length
    p = self.rbuf[].rowPtr(x, y, len) + x + x + x

  doWhile len != 0:
    p[OrderType.R] = c.r
    p[OrderType.G] = c.g
    p[OrderType.B] = c.b
    inc(p, 3)
    dec len

proc copyVline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT) =

  type
    OrderType = getOrderType(Blender)

  var
    len = length
    line = y

  doWhile len != 0:
    var p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
    p[OrderType.R] = c.r
    p[OrderType.G] = c.g
    p[OrderType.B] = c.b
    inc line
    dec len

proc blendHline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT, cover: uint8) =

  type
    CalcType = getCalcType(ColorT)
    OrderType = getOrderType(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    len = length
    p = self.rbuf[].rowPtr(x, y, len) + x + x + x

  let alpha = (CalcType(c.a) * (CalcType(cover) + 1)) shr 8
  if alpha == baseMask:
    doWhile len != 0:
      p[OrderType.R] = c.r
      p[OrderType.G] = c.g
      p[OrderType.B] = c.b
      inc(p, 3)
      dec len
  else:
    doWhile len != 0:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      inc(p, 3)
      dec len

proc blendVline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT, cover: uint8) =

  type
    CalcType = getCalcType(ColorT)
    OrderType = getOrderType(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  let alpha = (CalcType(c.a) * (CalcType(cover) + 1)) shr 8
  var
    len = length
    line = y

  if alpha == baseMask:
    doWhile len != 0:
      let p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
      inc line

      p[OrderType.R] = c.r
      p[OrderType.G] = c.g
      p[OrderType.B] = c.b
      dec len
  else:
    doWhile len != 0:
      let p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      dec len

proc blendSolidHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT, covers: ptr uint8) =

  type
    CalcType = getCalcType(ColorT)
    OrderType = getOrderType(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    len = length
    p = self.rbuf[].rowPtr(x, y, len) + x + x + x
    co = covers

  doWhile len != 0:
    let alpha = (CalcType(c.a) * (CalcType(co[]) + 1)) shr 8
    if alpha == baseMask:
      p[OrderType.R] = c.r
      p[OrderType.G] = c.g
      p[OrderType.B] = c.b
    else:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, co[])
    inc(p, 3)
    inc co
    dec len

proc blendSolidVspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, c: ColorT, covers: ptr uint8) =

  type
    CalcType = getCalcType(ColorT)
    OrderType = getOrderType(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    line = y
    len = length
    co = covers

  doWhile len != 0:
    var p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
    inc line

    let alpha = (CalcType(c.a) * (CalcType(co[]) + 1)) shr 8
    if alpha == baseMask:
        p[OrderType.R] = c.r
        p[OrderType.G] = c.g
        p[OrderType.B] = c.b
    else:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, co[])
    inc co
    dec len

proc copyColorHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, colors: ptr ColorT) =
  type
    OrderType = getOrderType(Blender)

  var
    len = length
    p = self.rbuf[].rowPtr(x, y, len) + x + x + x
    co = colors

  doWhile len != 0:
    p[OrderType.R] = co[].r
    p[OrderType.G] = co[].g
    p[OrderType.B] = co[].b
    inc co
    inc(p, 3)
    dec len

proc copyColorVspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, length: int, colors: ptr ColorT) =

  type
    OrderType = getOrderType(Blender)
  var
    co = colors
    line = y
    len = length

  doWhile len != 0:
    var p = self.rbuf[].rowPtr(x, line, 1) + x + x + x
    p[OrderType.R] = co[].r
    p[OrderType.G] = co[].g
    p[OrderType.B] = co[].b
    inc co
    inc line
    dec len

proc forEachPixel[PixFmt, Func](self: PixFmt, f: Func) =
  let h = self.height()
  for y in 0.. <h:
    let r = self.rbuf[].row(y)
    if r.data != nil:
      var
        len = r.x2 - r.x1 + 1
        p = self.rbuf[].rowPtr(r.x1, y, len) + r.x1 * 3
      doWhile len != 0:
        f(p)
        inc(p, 3)
        dec len

proc applyGammaDir*[Blender, RenBuf, GammaLut](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  gamma: GammaLut) =

  type
    ValueType = getValueType(Blender)
    OrderType = getOrderType(Blender)

  proc apply_gamma_dir_rgb(p: ptr ValueType) =
    p[OrderType.R] = gamma.dir(p[OrderType.R])
    p[OrderType.G] = gamma.dir(p[OrderType.G])
    p[OrderType.B] = gamma.dir(p[OrderType.B])

  self.forEachPixel(apply_gamma_dir_rgb)

proc applyGammaInv*[Blender, RenBuf, GammaLut](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  gamma: GammaLut) =

  type
    ValueType = getValueType(Blender)
    OrderType = getOrderType(Blender)

  proc apply_gamma_inv_rgb(p: ptr ValueType) =
    p[OrderType.R] = gamma.inv(p[OrderType.R])
    p[OrderType.G] = gamma.inv(p[OrderType.G])
    p[OrderType.B] = gamma.inv(p[OrderType.B])

  self.forEachPixel(apply_gamma_inv_rgb)

proc copyFrom*[Blender, RenBuf, RenBuf2](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: var RenBuf2, xdst, ydst, xsrc, ysrc: int, len: int) =

  const pixWidth = getPixWidth(Blender)
  let p = src.rowPtr(ysrc)
  if p == nil: return
  moveMem(self.rbuf[].rowPtr(xdst, ydst, len) + xdst * pixWidth,
    p + xsrc * pixWidth, len * pixWidth)

proc blendFrom*[Blender, RenBuf, SrcPixelFormatRenderer](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: SrcPixelFormatRenderer, xdst, ydst, xsrc, ysrc: int, length: uint, cover: uint8) =

  type
    SrcOrder  = getOrderType(SrcPixelFormatRenderer)
    OrderType = getOrderType(Blender)
    ColorType = getColorType(Blender)
  const
    baseMask = getBaseMask(getColorType(Blender))

  var
    psrc = src.rowPtr(ysrc)
    len = length
  if psrc == nil: return

  inc(psrc, xsrc * 4)
  var pdst = self.rbuf[].rowPtr(xdst, ydst, len) + xdst * 3
  if cover == 255:
    doWhile len != 0:
      let alpha = psrc[SrcOrder.A]
      if alpha != 0:
        if alpha == baseMask:
          pdst[OrderType.R] = psrc[SrcOrder.R]
          pdst[OrderType.G] = psrc[SrcOrder.G]
          pdst[OrderType.B] = psrc[SrcOrder.B]
        else:
          self.blender.blendPix(pdst,
            psrc[SrcOrder.R],
            psrc[SrcOrder.G],
            psrc[SrcOrder.B],
            alpha)
      inc(psrc, 4)
      inc(pdst, 3)
      dec len
  else:
    var color: ColorType
    doWhile len != 0:
      color.r = psrc[SrcOrder.R]
      color.g = psrc[SrcOrder.G]
      color.b = psrc[SrcOrder.B]
      color.a = psrc[SrcOrder.A]
      self.copyOrBlendPix(pdst, color, cover)
      inc(psrc, 4)
      inc(pdst, 3)
      dec len

proc blendFromColor*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: SrcPixelFormatRenderer, color: ColorT, xdst, ydst, xsrc, ysrc, length: uint, cover: uint8) =

  const
    baseShift = getBaseShift(ColorT)
    baseMask  = getBaseMask(ColorT)

  var
    len  = length
    psrc = src.rowPtr(ysrc)

  if psrc == nil: return
  var pdst = self.rbuf[].rowPtr(xdst, ydst, len) + xdst * 3
  doWhile len != 0:
    self.copyOrBlendPix(pdst, color, (psrc[] * cover + baseMask) shr baseShift)
    inc psrc
    inc(pdst, 3)
    dec len

proc blendFromLut*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: SrcPixelFormatRenderer, colorLut: ptr ColorT, xdst, ydst, xsrc, ysrc, length: uint, cover: uint8) =

  var
    psrc = src.rowPtr(ysrc)
    len = length

  if psrc == nil: return
  var pdst =  self.rbuf[].rowPtr(xdst, ydst, len) + xdst * 3

  if cover == 255:
    doWhile len != 0:
      let color = colorLut[psrc[]]
      self.blender.blendPix(pdst, color.r, color.g, color.b, color.a)
      inc psrc
      inc(pdst, 3)
      dec len
  else:
    doWhile len != 0:
      self.copyOrBlendPix(pdst, colorLut[psrc[]], cover)
      inc psrc
      inc(pdst, 3)
      dec len

proc attach*[Blender, RenBuf, PixFmt](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  pixf: PixFmt, x1, y1, x2, y2: int): bool =

  var r = initRectBase[int](x1, y1, x2, y2)
  let c = initRectBase[int](0, 0, pixf.width()-1, pixf.height()-1)

  if r.clip(c):
    let stride = pixf.stride()
    self.rbuf[].attach(pixf.pixPtr(r.x1,
      if stride < 0: r.y2 else: r.y1),
      (r.x2 - r.x1) + 1, (r.y2 - r.y1) + 1, stride)
    return true
  result = false

type
  PixfmtRgb24* = PixfmtAlphaBlendRgb[BlenderRgb[Rgba8, OrderRgb], RenderingBuffer]
  PixfmtBgr24* = PixfmtAlphaBlendRgb[BlenderRgb[Rgba8, OrderBgr], RenderingBuffer]
  PixfmtRgb48* = PixfmtAlphaBlendRgb[BlenderRgb[Rgba16, OrderRgb], RenderingBuffer16]
  PixfmtBgr48* = PixfmtAlphaBlendRgb[BlenderRgb[Rgba16, OrderBgr], RenderingBuffer16]

  PixfmtRgb24Pre* = PixfmtAlphaBlendRgb[BlenderRgbPre[Rgba8, OrderRgb], RenderingBuffer]
  PixfmtBgr24Pre* = PixfmtAlphaBlendRgb[BlenderRgbPre[Rgba8, OrderBgr], RenderingBuffer]
  PixfmtRgb48Pre* = PixfmtAlphaBlendRgb[BlenderRgbPre[Rgba16, OrderRgb], RenderingBuffer16]
  PixfmtBgr48Pre* = PixfmtAlphaBlendRgb[BlenderRgbPre[Rgba16, OrderBgr], RenderingBuffer16]

proc initPixFmtRgb24*(rbuf: var RenderingBuffer): PixfmtRgb24 =
  result.rbuf = rbuf.addr

proc initPixFmtBgr24*(rbuf: var RenderingBuffer): PixfmtBgr24 =
  result.rbuf = rbuf.addr

proc initPixFmtRgb48*(rbuf: var RenderingBuffer16): PixfmtRgb48 =
  result.rbuf = rbuf.addr

proc initPixFmtBgr48*(rbuf: var RenderingBuffer16): PixfmtBgr48 =
  result.rbuf = rbuf.addr

proc initPixFmtRgb24Pre*(rbuf: var RenderingBuffer): PixfmtRgb24Pre =
  result.rbuf = rbuf.addr

proc initPixFmtBgr24Pre*(rbuf: var RenderingBuffer): PixfmtBgr24Pre =
  result.rbuf = rbuf.addr

proc initPixFmtRgb48Pre*(rbuf: var RenderingBuffer16): PixfmtRgb48Pre =
  result.rbuf = rbuf.addr

proc initPixFmtBgr48Pre*(rbuf: var RenderingBuffer16): PixfmtBgr48Pre =
  result.rbuf = rbuf.addr

template pixfmtRgb24Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba8, OrderRgb, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: Gamma): name =
    result.rbuf = rbuf.addr
    result.blender.setGamma(gamma)

template pixfmtBgr24Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba8, OrderBgr, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: Gamma): name =
    result.rbuf = rbuf.addr
    result.blender.setGamma(gamma)

template pixfmtRgb48Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba16, OrderRgb, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer16]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: Gamma): name =
    result.rbuf = rbuf.addr
    result.blender.setGamma(gamma)

template pixfmtBgr48Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba16, OrderBgr, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer16]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: Gamma): name =
    result.rbuf = rbuf.addr
    result.blender.setGamma(gamma)