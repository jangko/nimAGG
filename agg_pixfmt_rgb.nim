import agg_basics, agg_rendering_buffer, agg_color_rgba, strutils

type
  BlenderRgb*[ColorT, OrderT] = object
  BlenderRgbPre*[ColorT, OrderT] = object
  BlenderRgbGamma*[ColorT, OrderT, GammaT] = object
    mGamma: ptr GammaT

  PixfmtAlphaBlendRgb*[Blender, RenBuf] = object
    blender: Blender
    mRbuf: ptr RenBuf

template getOrderT*[C,O](x: typedesc[BlenderRgb[C,O]]): typedesc = O
template getValueT*[C,O](x: typedesc[BlenderRgb[C,O]]): untyped = getValueT(C.type)
template getColorT*[C,O](x: typedesc[BlenderRgb[C,O]]): typedesc = C
template getPixWidth* [C,O](x: typedesc[BlenderRgb[C,O]]): int = sizeof(getValueT(C.type)) * 3

template getOrderT*[C,O](x: typedesc[BlenderRgbPre[C,O]]): typedesc = O
template getValueT*[C,O](x: typedesc[BlenderRgbPre[C,O]]): untyped = getValueT(C.type)
template getColorT*[C,O](x: typedesc[BlenderRgbPre[C,O]]): typedesc = C
template getPixWidth* [C,O](x: typedesc[BlenderRgbPre[C,O]]): int = sizeof(getValueT(C.type)) * 3

template getOrderT*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): typedesc = O
template getValueT*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): untyped = getValueT(C.type)
template getColorT*[C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): typedesc = C
template getPixWidth* [C,O,G](x: typedesc[BlenderRgbGamma[C,O,G]]): int = sizeof(getValueT(C.type)) * 3

template getOrderT*[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): typedesc = getOrderT(B.type)
template getColorT*[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): typedesc = getColorT(B.type)
template getValueT*[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): typedesc = getValueT(B.type)
template getPixWidth *[B,R](x: typedesc[PixfmtAlphaBlendRgb[B,R]]): int = getPixWidth(B.type)

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
    baseShift = getBaseShift(C).uint
    baseMask  = getBaseMask(C).uint

  let al = baseMask - alpha
  let co = (cover + 1) shl (baseShift - 8)

  p[O.R] = T((p[O.R].uint * al + cr * co) shr baseShift)
  p[O.G] = T((p[O.G].uint * al + cg * co) shr baseShift)
  p[O.B] = T((p[O.B].uint * al + cb * co) shr baseShift)

proc blendPix*[C,O,T](self: BlenderRgbPre[C,O], p: ptr T,
  cr, cg, cb, alpha: uint) {.inline.} =
  const
    baseShift = getBaseShift(C).uint
    baseMask  = getBaseMask(C).uint

  let al = baseMask - alpha
  p[O.R] = T(((p[O.R].uint * al) shr baseShift) + cr)
  p[O.G] = T(((p[O.G].uint * al) shr baseShift) + cg)
  p[O.B] = T(((p[O.B].uint * al) shr baseShift) + cb)

proc gamma*[C,O,G](self: var BlenderRgbGamma[C,O,G], gamma: var G) =
  self.mGamma = gamma.addr

proc blendPix*[C,O,T,G](self: BlenderRgbGamma[C,O,G], p: ptr T,
  cr, cg, cb, alpha: uint, cover=0.uint) {.inline.} =
  type
    CalcT = getCalcT(C)
  const
    baseShift = getBaseShift(C)
    baseMask = getBaseMask(C)

  let r = self.mGamma[].dir(p[O.R]).int
  let g = self.mGamma[].dir(p[O.G]).int
  let b = self.mGamma[].dir(p[O.B]).int

  p[O.R] = self.mGamma[].inv(((((self.mGamma[].dir(cr).int - r) * alpha.int) shr baseShift) + r) and baseMask)
  p[O.G] = self.mGamma[].inv(((((self.mGamma[].dir(cg).int - g) * alpha.int) shr baseShift) + g) and baseMask)
  p[O.B] = self.mGamma[].inv(((((self.mGamma[].dir(cb).int - b) * alpha.int) shr baseShift) + b) and baseMask)

proc copyPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, c: ColorT) =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  var p = self.mRbuf[].rowPtr(x, y, 1) + x + x + x
  p[OrderT.R] = c.r
  p[OrderT.G] = c.g
  p[OrderT.B] = c.b

proc makePix*[Blender, RenBuf, ColorT](x: typedesc[PixfmtAlphaBlendRgb[Blender, RenBuf]],
  p: pointer, c: ColorT) =

  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  cast[ptr ValueT](p)[OrderT.R] = c.r
  cast[ptr ValueT](p)[OrderT.G] = c.g
  cast[ptr ValueT](p)[OrderT.B] = c.b

proc pixel*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int): auto =

  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  var p = self.mRbuf[].rowPtr(y) + x + x + x
  result = construct(getColorT(Blender), p[OrderT.R], p[OrderT.G], p[OrderT.B])

proc height*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int {.inline.} =
  result = self.mRbuf[].height()

proc width*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int {.inline.} =
  result = self.mRbuf[].width()

proc stride*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int {.inline.} =
  result = self.mRbuf[].stride()

proc rowPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], y: int): auto {.inline.} =
  result = self.mRbuf[].rowPtr(y)

proc row*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], y: int): auto {.inline.} =
  result = self.mRbuf[].row(y)

proc pixPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf], x, y: int): auto {.inline.} =
  const pixWidth = getPixWidth(Blender)
  result = self.mRbuf[].rowPtr(y) + x * pixWidth

proc rbuf*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): var RenBuf {.inline.} =
  result = self.mRbuf[]

proc copyOrBlendPix[Blender, RenBuf, C, T](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  p: ptr T, c: C, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(C)
    OrderT = getOrderT(Blender)
  const
    baseMask = getBaseMask(C)

  if c.a != 0:
    let alpha = (CalcT(c.a) * CalcT(cover + 1)) shr 8
    if alpha == baseMask:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
    else:
      self.blender.blendPix(p, c.r.uint, c.g.uint, c.b.uint, alpha, cover)

proc copyOrBlendPix[Blender, RenBuf, C, T](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  p: ptr T, c: C) {.inline.} =

  type OrderT = getOrderT(Blender)
  const baseMask = getBaseMask(C)

  if c.a != 0:
    if c.a == baseMask:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
    else:
      self.blender.blendPix(p, c.r.uint, c.g.uint, c.b.uint, c.a.uint)

proc blendPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, c: ColorT, cover: uint8) =
  let p = self.mRbuf[].rowPtr(x, y, 1) + x + x + x
  self.copyOrBlendPix(p, c, cover)

proc blendColorHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    ValueT = getValueT(Blender)

  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len) + x + x + x)
    len = len
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
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    ValueT = getValueT(Blender)

  var
    len = len
    line = y
    cv = covers
    co = colors

  if covers != nil:
    doWhile len != 0:
      let p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[], cv[])
      inc cv
      inc co
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      let p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[])
      inc co
      dec len
  else:
    doWhile len != 0:
      let p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.copyOrBlendPix(p, co[], cover)
      inc co
      dec len

proc copyHline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT) =

  type
    OrderT = getOrderT(Blender)

  var
    len = len
    p = self.mRbuf[].rowPtr(x, y, len) + x + x + x

  doWhile len != 0:
    p[OrderT.R] = c.r
    p[OrderT.G] = c.g
    p[OrderT.B] = c.b
    inc(p, 3)
    dec len

proc copyVline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT) =

  type
    OrderT = getOrderT(Blender)

  var
    len = len
    line = y

  doWhile len != 0:
    var p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
    p[OrderT.R] = c.r
    p[OrderT.G] = c.g
    p[OrderT.B] = c.b
    inc line
    dec len

proc blendHline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =

  type
    CalcT = getCalcT(ColorT)
    OrderT = getOrderT(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    len = len
    p = self.mRbuf[].rowPtr(x, y, len) + x + x + x

  let alpha = (CalcT(c.a) * (CalcT(cover) + 1)) shr 8
  if alpha == baseMask:
    doWhile len != 0:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
      inc(p, 3)
      dec len
  else:
    doWhile len != 0:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      inc(p, 3)
      dec len

proc blendVline*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =

  type
    CalcT = getCalcT(ColorT)
    OrderT = getOrderT(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  let alpha = (CalcT(c.a) * (CalcT(cover) + 1)) shr 8
  var
    len = len
    line = y

  if alpha == baseMask:
    doWhile len != 0:
      let p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
      inc line

      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
      dec len
  else:
    doWhile len != 0:
      let p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
      inc line
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      dec len

proc blendSolidHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =

  type
    CalcT = getCalcT(ColorT)
    OrderT = getOrderT(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    len = len
    p = self.mRbuf[].rowPtr(x, y, len) + x + x + x
    co = covers

  doWhile len != 0:
    let alpha = (CalcT(c.a) * (CalcT(co[]) + 1)) shr 8
    if alpha == baseMask:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
    else:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, co[])
    inc(p, 3)
    inc co
    dec len

proc blendSolidVspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =

  type
    CalcT = getCalcT(ColorT)
    OrderT = getOrderT(Blender)

  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return

  var
    line = y
    len = len
    co = covers

  doWhile len != 0:
    var p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
    inc line

    let alpha = (CalcT(c.a) * (CalcT(co[]) + 1)) shr 8
    if alpha == baseMask:
        p[OrderT.R] = c.r
        p[OrderT.G] = c.g
        p[OrderT.B] = c.b
    else:
      self.blender.blendPix(p, c.r, c.g, c.b, alpha, co[])
    inc co
    dec len

proc copyColorHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT) =
  type
    OrderT = getOrderT(Blender)

  var
    len = len
    p = self.mRbuf[].rowPtr(x, y, len) + x + x + x
    co = colors

  doWhile len != 0:
    p[OrderT.R] = co[].r
    p[OrderT.G] = co[].g
    p[OrderT.B] = co[].b
    inc co
    inc(p, 3)
    dec len

proc copyColorVspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT) =

  type
    OrderT = getOrderT(Blender)
  var
    co = colors
    line = y
    len = len

  doWhile len != 0:
    var p = self.mRbuf[].rowPtr(x, line, 1) + x + x + x
    p[OrderT.R] = co[].r
    p[OrderT.G] = co[].g
    p[OrderT.B] = co[].b
    inc co
    inc line
    dec len

proc forEachPixel[PixFmt, Func](self: PixFmt, f: Func) =
  let h = self.height()
  for y in 0.. <h:
    let r = self.mRbuf[].row(y)
    if r.data != nil:
      var
        len = r.x2 - r.x1 + 1
        p = self.mRbuf[].rowPtr(r.x1, y, len) + r.x1 * 3
      doWhile len != 0:
        f(p)
        inc(p, 3)
        dec len

proc applyGammaDir*[Blender, RenBuf, GammaLut](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  gamma: GammaLut) =

  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)

  proc apply_gamma_dir_rgb(p: ptr ValueT) =
    p[OrderT.R] = gamma.dir(p[OrderT.R])
    p[OrderT.G] = gamma.dir(p[OrderT.G])
    p[OrderT.B] = gamma.dir(p[OrderT.B])

  self.forEachPixel(apply_gamma_dir_rgb)

proc applyGammaInv*[Blender, RenBuf, GammaLut](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  gamma: GammaLut) =

  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)

  proc apply_gamma_inv_rgb(p: ptr ValueT) =
    p[OrderT.R] = gamma.inv(p[OrderT.R])
    p[OrderT.G] = gamma.inv(p[OrderT.G])
    p[OrderT.B] = gamma.inv(p[OrderT.B])

  self.forEachPixel(apply_gamma_inv_rgb)

proc copyFrom*[Blender, RenBuf, RenBuf2](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: var RenBuf2, xdst, ydst, xsrc, ysrc: int, len: int) =

  const pixWidth = getPixWidth(Blender)
  let p = src.rowPtr(ysrc)
  if p == nil: return
  moveMem(self.mRbuf[].rowPtr(xdst, ydst, len) + xdst * pixWidth,
    p + xsrc * pixWidth, len * pixWidth)

proc blendFrom*[Blender, RenBuf, SrcPixelFormatRenderer](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: SrcPixelFormatRenderer, xdst, ydst, xsrc, ysrc, length: int, cover: uint8) =

  type
    SrcOrder  = getOrderT(SrcPixelFormatRenderer)
    OrderT = getOrderT(Blender)
    ColorType = getColorT(Blender)
  const
    baseMask = getBaseMask(getColorT(Blender))

  var
    psrc = src.rowPtr(ysrc)
    len = len
  if psrc == nil: return

  inc(psrc, xsrc * 4)
  var pdst = self.mRbuf[].rowPtr(xdst, ydst, len) + xdst * 3
  if cover == 255:
    doWhile len != 0:
      let alpha = psrc[SrcOrder.A]
      if alpha != 0:
        if alpha == baseMask:
          pdst[OrderT.R] = psrc[SrcOrder.R]
          pdst[OrderT.G] = psrc[SrcOrder.G]
          pdst[OrderT.B] = psrc[SrcOrder.B]
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
  src: SrcPixelFormatRenderer, color: ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(ColorT)
    CalcT = getCalcT(ColorT)

  const
    baseShift = getBaseShift(ColorT).CalcT
    baseMask  = getBaseMask(ColorT).CalcT

  var
    len  = len
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))

  if psrc == nil: return
  var pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + xdst * 3
  doWhile len != 0:
    self.copyOrBlendPix(pdst, color, (psrc[].CalcT * cover.CalcT + baseMask) shr baseShift)
    inc psrc
    inc(pdst, 3)
    dec len

proc blendFromLut*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  src: SrcPixelFormatRenderer, colorLut: ptr ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =
  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(ColorT)

  var
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))
    len = len

  if psrc == nil: return
  var pdst =  cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + xdst * 3

  if cover == 255:
    doWhile len != 0:
      let color = colorLut[psrc[].int]
      self.blender.blendPix(pdst, color.r, color.g, color.b, color.a)
      inc psrc
      inc(pdst, 3)
      dec len
  else:
    doWhile len != 0:
      self.copyOrBlendPix(pdst, colorLut[psrc[].int], cover)
      inc psrc
      inc(pdst, 3)
      dec len

proc attach*[Blender, RenBuf, PixFmt](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  pixf: PixFmt, x1, y1, x2, y2: int): bool =

  var r = initRectI(x1, y1, x2, y2)
  let c = initRectI(0, 0, pixf.width()-1, pixf.height()-1)

  if r.clip(c):
    let stride = pixf.stride()
    self.mRbuf[].attach(pixf.pixPtr(r.x1,
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
  result.mRbuf = rbuf.addr

proc initPixFmtBgr24*(rbuf: var RenderingBuffer): PixfmtBgr24 =
  result.mRbuf = rbuf.addr

proc initPixFmtRgb48*(rbuf: var RenderingBuffer16): PixfmtRgb48 =
  result.mRbuf = rbuf.addr

proc initPixFmtBgr48*(rbuf: var RenderingBuffer16): PixfmtBgr48 =
  result.mRbuf = rbuf.addr

proc initPixFmtRgb24Pre*(rbuf: var RenderingBuffer): PixfmtRgb24Pre =
  result.mRbuf = rbuf.addr

proc initPixFmtBgr24Pre*(rbuf: var RenderingBuffer): PixfmtBgr24Pre =
  result.mRbuf = rbuf.addr

proc initPixFmtRgb48Pre*(rbuf: var RenderingBuffer16): PixfmtRgb48Pre =
  result.mRbuf = rbuf.addr

proc initPixFmtBgr48Pre*(rbuf: var RenderingBuffer16): PixfmtBgr48Pre =
  result.mRbuf = rbuf.addr

template pixfmtRgb24Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba8, OrderRgb, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: var Gamma): name =
    result.mRbuf = rbuf.addr
    result.blender.gamma(gamma)

template pixfmtBgr24Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba8, OrderBgr, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: var Gamma): name =
    result.mRbuf = rbuf.addr
    result.blender.gamma(gamma)

template pixfmtRgb48Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba16, OrderRgb, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer16]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: var Gamma): name =
    result.mRbuf = rbuf.addr
    result.blender.gamma(gamma)

template pixfmtBgr48Gamma*(name: untyped, Gamma: typedesc) =
  type
    `name blender`* = BlenderRgbGamma[Rgba16, OrderBgr, Gamma]
    name* = PixfmtAlphaBlendRgb[`name blender`, RenderingBuffer16]

  proc `init name`*(rbuf: var RenderingBuffer, gamma: var Gamma): name =
    result.mRbuf = rbuf.addr
    result.blender.gamma(gamma)