import agg_basics, agg_color_rgba, agg_rendering_buffer, agg_comp_op, strutils

proc multiplierRgbaPremultiply[ColorT, OrderT, ValueT](p: ptr ValueT) =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))

  let a = CalcT(p[OrderT.A])
  if a < baseMask:
    if a == 0:
      p[OrderT.R] = 0
      p[OrderT.G] = 0
      p[OrderT.B] = 0
      return

    p[OrderT.R] = ValueT((p[OrderT.R].CalcT * a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((p[OrderT.G].CalcT * a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((p[OrderT.B].CalcT * a + baseMask) shr baseShift)

proc multiplierRgbaDemultiply[ColorT, OrderT, ValueT](p: ptr ValueT) =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = getBaseShift(ColorT)

  let a = CalcT(p[OrderT.A])
  if a < baseMask:
    if a == 0:
      p[OrderT.R] = 0
      p[OrderT.G] = 0
      p[OrderT.B] = 0
      return

    let r = (CalcT(p[OrderT.R]) * baseMask) div a
    let g = (CalcT(p[OrderT.G]) * baseMask) div a
    let b = (CalcT(p[OrderT.B]) * baseMask) div a
    p[OrderT.R] = ValueT(if r > baseMask: baseMask else: r)
    p[OrderT.G] = ValueT(if g > baseMask: baseMask else: g)
    p[OrderT.B] = ValueT(if b > baseMask: baseMask else: b)

type
  BlenderRgba*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[BlenderRgba[C,O]]): typedesc = O
template getValueT*[C,O](x: typedesc[BlenderRgba[C,O]]): untyped = getValueT(C.type)
template getColorT*[C,O](x: typedesc[BlenderRgba[C,O]]): typedesc = C

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[BlenderRgba[ColorT, OrderT]], p: ptr ValueT,
  cr, cg, cb, alpha: uint, cover: uint = 0) {.inline.} =
  type CalcT = getCalcT(ColorT)
  const
    baseShift = getBaseShift(ColorT)
    baseMask  = getBaseMask(ColorT)
  let
    r = CalcT(p[OrderT.R])
    g = CalcT(p[OrderT.G])
    b = CalcT(p[OrderT.B])
    a = CalcT(p[OrderT.A])
  p[OrderT.R] = ValueT(((cr - r) * alpha + (r shl baseShift)) shr baseShift)
  p[OrderT.G] = ValueT(((cg - g) * alpha + (g shl baseShift)) shr baseShift)
  p[OrderT.B] = ValueT(((cb - b) * alpha + (b shl baseShift)) shr baseShift)
  p[OrderT.A] = ValueT((alpha + a) - ((alpha * a + baseMask) shr baseShift))

type
  BlenderRgbaPre*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[BlenderRgbaPre[C,O]]): typedesc = O
template getValueT*[C,O](x: typedesc[BlenderRgbaPre[C,O]]): untyped = getValueT(C.type)
template getColorT*[C,O](x: typedesc[BlenderRgbaPre[C,O]]): typedesc = C

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[BlenderRgbaPre[ColorT, OrderT]], p: ptr ValueT,
  cr, cg, cb, alpha: uint, cover: uint) {.inline.} =
  const
    baseShift = getBaseShift(ColorT).uint
    baseMask  = getBaseMask(ColorT).uint
  let
    alpha = baseMask - alpha
    cover = (cover + 1) shl (baseShift - 8)

  p[OrderT.R] = ValueT((p[OrderT.R].uint * alpha + cr * cover) shr baseShift)
  p[OrderT.G] = ValueT((p[OrderT.G].uint * alpha + cg * cover) shr baseShift)
  p[OrderT.B] = ValueT((p[OrderT.B].uint * alpha + cb * cover) shr baseShift)
  p[OrderT.A] = ValueT(baseMask - ((alpha * (baseMask - p[OrderT.A])) shr baseShift))

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[BlenderRgbaPre[ColorT, OrderT]], p: ptr ValueT,
  cr, cg, cb, alpha: uint) {.inline.} =
  const
    baseShift = getBaseShift(ColorT).uint
    baseMask  = getBaseMask(ColorT).uint
  let alpha = baseMask - alpha
  p[OrderT.R] = ValueT(((p[OrderT.R].uint * alpha) shr baseShift) + cr)
  p[OrderT.G] = ValueT(((p[OrderT.G].uint * alpha) shr baseShift) + cg)
  p[OrderT.B] = ValueT(((p[OrderT.B].uint * alpha) shr baseShift) + cb)
  p[OrderT.A] = ValueT(baseMask - ((alpha * (baseMask - p[OrderT.A])) shr baseShift))

type
  BlenderRgbaPlain*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[BlenderRgbaPlain[C,O]]): typedesc = O
template getValueT*[C,O](x: typedesc[BlenderRgbaPlain[C,O]]): untyped = getValueT(C.type)
template getColorT*[C,O](x: typedesc[BlenderRgbaPlain[C,O]]): typedesc = C

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[BlenderRgbaPlain[ColorT, OrderT]], p: ptr ValueT,
  cr, cg, cb, alpha: uint, cover: uint = 0) {.inline.} =
  type CalcT = getCalcT(ColorT)
  const baseShift = CalcT(getBaseShift(ColorT))

  if alpha == 0: return
  var
    a = CalcT(p[OrderT.A])
    r = CalcT(p[OrderT.R]) * a
    g = CalcT(p[OrderT.G]) * a
    b = CalcT(p[OrderT.B]) * a

  a = ((CalcT(alpha) + a) shl baseShift) - CalcT(alpha) * a
  p[OrderT.A] = ValueT(a shr baseShift)
  p[OrderT.R] = ValueT((((cr shl baseShift) - r) * alpha + (r shl baseShift)) div a)
  p[OrderT.G] = ValueT((((cg shl baseShift) - g) * alpha + (g shl baseShift)) div a)
  p[OrderT.B] = ValueT((((cb shl baseShift) - b) * alpha + (b shl baseShift)) div a)

proc rgbaWrapperCopyOrBlendPix[Blender, ValueT](p: ptr ValueT,
  cr, cg, cb, alpha: uint) =
  type OrderT = getOrderT(Blender)
  const baseMask = getBaseMask(getColorT(Blender))
  if alpha != 0:
    if alpha == baseMask:
      p[OrderT.R] = ValueT(cr)
      p[OrderT.G] = ValueT(cg)
      p[OrderT.B] = ValueT(cb)
      p[OrderT.A] = ValueT(baseMask)
    else:
      Blender.blendPix(p, cr, cg, cb, alpha)

proc rgbaWrapperCopyOrBlendPix[Blender, ValueT](p: ptr ValueT,
  cr, cg, cb, alpha, cover: uint) =
  type OrderT = getOrderT(Blender)
  const baseMask = getBaseMask(getColorT(Blender))
  if cover == 255:
    rgbaWrapperCopyOrBlendPix[Blender, ValueT](p, cr, cg, cb, alpha)
  else:
    if alpha != 0:
      var alpha = (alpha * (cover + 1)) shr 8
      if alpha == baseMask:
        p[OrderT.R] = ValueT(cr)
        p[OrderT.G] = ValueT(cg)
        p[OrderT.B] = ValueT(cb)
        p[OrderT.A] = ValueT(baseMask)
      else:
        Blender.blendPix(p, cr, cg, cb, alpha, cover)

type
  PixfmtAlphaBlendRgba*[Blender, RenBuf, PixelT] = object
    mRbuf: ptr RenBuf

template getOrderT*[B,R,P](x: typedesc[PixfmtAlphaBlendRgba[B,R,P]]): typedesc = getOrderT(B.type)
template getColorT*[B,R,P](x: typedesc[PixfmtAlphaBlendRgba[B,R,P]]): typedesc = getColorT(B.type)
template getValueT*[B,R,P](x: typedesc[PixfmtAlphaBlendRgba[B,R,P]]): typedesc = getValueT(B.type)
template getPixWidth*[B,R,P](x: typedesc[PixfmtAlphaBlendRgba[B,R,P]]): int = sizeof(P.type)

proc initPixfmtAlphaBlendRgba*[Blender, RenBuf, PixelT](rbuf: var RenBuf):
  PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT] =
  result.mRbuf = rbuf.addr

template construct*[B,R,P](x: typedesc[PixfmtAlphaBlendRgba[B,R,P]], rbuf: typed): untyped =
  initPixfmtAlphaBlendRgba[B,R,P](rbuf)

proc attach*[Blender, RenBuf, PixelT](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  rbuf: var RenBuf) =
  self.mRbuf = rbuf.addr

proc attach*[Blender, RenBuf, PixelT, PixFmt](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  pixf: PixFmt, x1, y1, x2, y2: int): bool =
  var r = initRectI(x1, y1, x2, y2)
  if r.clip(initRectI(0, 0, pixf.width()-1, pixf.height()-1)):
    let stride = pixf.stride()
    self.mRbuf[].attach(pixf.pixPtr(r.x1, if stride < 0: r.y2 else: r.y1),
       (r.x2 - r.x1) + 1,
       (r.y2 - r.y1) + 1,
       stride)
    return true
  result = false

proc width*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]): int {.inline.} =
  self.mRbuf[].width()

proc height*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]): int {.inline.} =
  self.mRbuf[].height()

proc stride*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]): int {.inline.} =
  self.mRbuf[].stride()

proc rowPtr*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT], y: int): ptr uint8 {.inline.} =
  self.mRbuf[].rowPtr(y)

proc row*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT], y: int): auto {.inline.} =
  self.mRbuf[].row(y)

proc pixPtr*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT], x, y: int): auto {.inline.} =
  const pixWidth = getPixWidth(self.type)
  self.mRbuf[].rowPtr(y) + x * pixWidth

proc rbuf*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]): var Renbuf {.inline.} =
  self.mRbuf[]

proc makePix*[Blender, RenBuf, PixelT, ColorT](x: typedesc[PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]],
  p: pointer, c: ColorT) {.inline.} =

  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  cast[ptr ValueT](p)[OrderT.R] = c.r
  cast[ptr ValueT](p)[OrderT.G] = c.g
  cast[ptr ValueT](p)[OrderT.B] = c.b
  cast[ptr ValueT](p)[OrderT.A] = c.a

proc pixel*[Blender, RenBuf, PixelT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y: int): auto {.inline.} =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
    ColorT = getColorT(Blender)
  var p = cast[ptr ValueT](self.mRbuf[].rowPtr(y))
  if p != nil:
    p += x shl 2
    return construct(ColorT,
        p[OrderT.R],
        p[OrderT.G],
        p[OrderT.B],
        p[OrderT.A])
  result = noColor(ColorT)

proc copyPixel*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y: int, c: ColorT) {.inline.} =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)

  var p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
  p[OrderT.R] = c.r
  p[OrderT.G] = c.g
  p[OrderT.B] = c.b
  p[OrderT.A] = c.a

proc blendPixel*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y: int, c: ColorT, cover: uint8) {.inline.} =
  type ValueT = getValueT(Blender)

  rgbaWrapperCopyOrBlendPix[Blender, ValueT](
    cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
    c.r, c.g, c.b, c.a, cover)

proc copyHline*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT) {.inline.} =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)

  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    v: PixelT
    len = len

  cast[ptr ValueT](v.addr)[OrderT.R] = c.r
  cast[ptr ValueT](v.addr)[OrderT.G] = c.g
  cast[ptr ValueT](v.addr)[OrderT.B] = c.b
  cast[ptr ValueT](v.addr)[OrderT.A] = c.a
  doWhile len != 0:
    cast[ptr PixelT](p)[] = v
    inc(p, 4)
    dec len

proc copyVline*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT) {.inline.} =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)

  var
    v: PixelT
    len = len
    y = y

  cast[ptr ValueT](v.addr)[OrderT.R] = c.r
  cast[ptr ValueT](v.addr)[OrderT.G] = c.g
  cast[ptr ValueT](v.addr)[OrderT.B] = c.b
  cast[ptr ValueT](v.addr)[OrderT.A] = c.a
  doWhile len != 0:
    var p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
    inc y
    cast[ptr PixelT](p)[] = v
    dec len

proc blendHline*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT, cover: uint8) =

  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
    CalcT  = getCalcT(ColorT)
  const baseMask = getBaseMask(getColorT(Blender))
  if c.a == 0: return

  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    alpha = CalcT((CalcT(c.a) * (cover.CalcT + 1)) shr 8)
    len = len

  if alpha == baseMask:
    var v: PixelT
    cast[ptr ValueT](v.addr)[OrderT.R] = c.r
    cast[ptr ValueT](v.addr)[OrderT.G] = c.g
    cast[ptr ValueT](v.addr)[OrderT.B] = c.b
    cast[ptr ValueT](v.addr)[OrderT.A] = c.a
    doWhile len != 0:
      cast[ptr PixelT](p)[] = v
      inc(p, 4)
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      Blender.blendPix(p, c.r, c.g, c.b, alpha)
      inc(p, 4)
      dec len
  else:
    doWhile len != 0:
      Blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      inc(p, 4)
      dec len

proc blendVline*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT, cover: uint8) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
    CalcT  = getCalcT(ColorT)
  const baseMask = getBaseMask(getColorT(Blender))
  if c.a == 0: return
  var
    p: ptr ValueT
    alpha = CalcT((CalcT(c.a) * (cover + 1)) shr 8)
    y = y
    len = len
  if alpha == baseMask:
    var v: PixelT
    cast[ptr ValueT](v.addr)[OrderT.R] = c.r
    cast[ptr ValueT](v.addr)[OrderT.G] = c.g
    cast[ptr ValueT](v.addr)[OrderT.B] = c.b
    cast[ptr ValueT](v.addr)[OrderT.A] = c.a
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      cast[ptr PixelT](p)[] = v
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      Blender.blendPix(p, c.r, c.g, c.b, alpha)
      dec len
  else:
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      Blender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      dec len

proc blendSolidHspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
    CalcT  = getCalcT(ColorT)
  const baseMask = getBaseMask(getColorT(Blender))
  if c.a == 0: return
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    covers = covers
  doWhile len != 0:
    let alpha = CalcT((CalcT(c.a) * (CalcT(covers[]) + 1)) shr 8)
    if alpha == baseMask:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
      p[OrderT.A] = baseMask
    else:
      Blender.blendPix(p, c.r, c.g, c.b, alpha, covers[])
    inc(p, 4)
    inc covers
    dec len

proc blendSolidVspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
    CalcT  = getCalcT(ColorT)
  const baseMask = getBaseMask(getColorT(Blender))
  if c.a == 0: return
  var
    len = len
    y = y
    covers = covers
  doWhile len != 0:
    var
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      alpha = CalcT((CalcT(c.a) * (CalcT(covers[]) + 1)) shr 8)
    inc y
    if alpha == baseMask:
      p[OrderT.R] = c.r
      p[OrderT.G] = c.g
      p[OrderT.B] = c.b
      p[OrderT.A] = baseMask
    else:
      Blender.blendPix(p, c.r, c.g, c.b, alpha, covers[])
    inc covers
    dec len

proc copyColorHspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, colors: ptr ColorT) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    colors = colors
  doWhile len != 0:
    p[OrderT.R] = colors.r
    p[OrderT.G] = colors.g
    p[OrderT.B] = colors.b
    p[OrderT.A] = colors.a
    inc colors
    inc(p, 4)
    dec len

proc copyColorVspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, colors: ptr ColorT) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
  var
    len = len
    y = y
    colors = colors
  doWhile len != 0:
    var p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
    inc y
    p[OrderT.R] = colors.r
    p[OrderT.G] = colors.g
    p[OrderT.B] = colors.b
    p[OrderT.A] = colors.a
    inc colors
    dec len

proc blendColorHspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type
    ValueT = getValueT(Blender)

  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    covers = covers
    colors = colors

  if covers != nil:
    doWhile len != 0:
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a, covers[])
      inc covers
      inc(p, 4)
      inc colors
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a)
      inc(p, 4)
      inc colors
      dec len
  else:
    doWhile len != 0:
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a, cover)
      inc(p, 4)
      inc colors
      dec len

proc blendColorVspan*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type
    ValueT = getValueT(Blender)
  var
    p: ptr ValueT
    y = y
    len = len
    covers = covers
    colors = colors

  if covers != nil:
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a, covers[])
      inc covers
      inc colors
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a)
      inc colors
      dec len
  else:
    doWhile len != 0:
      p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
      inc y
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](p,
        colors.r, colors.g, colors.b, colors.a, cover)
      inc colors
      dec len

proc forEachPixel[PixFmt, Func](self: PixFmt, f: Func) =
  type
    ValueT = getValueT(PixFmt)
  let h = self.height()
  for y in 0.. <h:
    let r = self.mRbuf[].row(y)
    if r.data != nil:
      var
        len = r.x2 - r.x1 + 1
        p = cast[ptr ValueT](self.mRbuf[].rowPtr(r.x1, y, len)) + (r.x1 shl 2)
      doWhile len != 0:
        f(p)
        inc(p, 4)
        dec len

proc premultiply*[Blender, RenBuf, PixelT](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]) =
  type
    ColorT = getColorT(Blender)
    OrderT = getOrderT(ColorT)
    ValueT = getValueT(ColorT)
  self.forEachPixel(multiplierRgbaPremultiply[ColorT, OrderT, ValueT])

proc demultiply*[Blender, RenBuf, PixelT](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT]) =
  type
    ColorT = getColorT(Blender)
    OrderT = getOrderT(ColorT)
    ValueT = getValueT(ColorT)
  self.forEachPixel(multiplierRgbaDemultiply[ColorT, OrderT, ValueT])

proc applyGammaDir*[Blender, RenBuf, PixelT, GammaLut](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  gamma: GammaLut) =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  proc apply_gamma_dir_rgba(p: ptr ValueT) =
    p[OrderT.R] = gamma.dir(p[OrderT.R])
    p[OrderT.G] = gamma.dir(p[OrderT.G])
    p[OrderT.B] = gamma.dir(p[OrderT.B])

  self.forEachPixel(apply_gamma_dir_rgba)

proc applyGammaInv*[Blender, RenBuf, PixelT, GammaLut](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  gamma: GammaLut) =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  proc apply_gamma_inv_rgba(p: ptr ValueT) =
    p[OrderT.R] = gamma.inv(p[OrderT.R])
    p[OrderT.G] = gamma.inv(p[OrderT.G])
    p[OrderT.B] = gamma.inv(p[OrderT.B])

  self.forEachPixel(apply_gamma_inv_rgba)

proc copyFrom*[Blender, RenBuf, PixelT, RenBuf2](self: var PixfmtAlphaBlendRgba[Blender, RenBuf, PixelT],
  src: RenBuf2, xdst, ydst, xsrc, ysrc, len: int) =
  const pixWidth = getPixWidth(self.type)
  var p = src.rowPtr(ysrc)
  if p != nil:
    moveMem(self.mRbuf[].rowPtr(xdst, ydst, len) + xdst * pixWidth,
      p + xsrc * pixWidth, len * pixWidth)

proc blendFrom*[Blender, RenBuf, PixelT, SrcPixelFormatRenderer](self: var PixfmtAlphaBlendRgba[Blender,
  RenBuf, PixelT], src: SrcPixelFormatRenderer, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcOrderT = getOrderT(SrcPixelFormatRenderer)
    ValueT = getValueT(Blender)

  var
    psrc = cast[ptr ValueT](src.rowPtr(ysrc))
    len = len

  if psrc == nil: return
  psrc += xsrc shl 2

  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    incp = 4

  if xdst > xsrc:
    psrc += (len-1) shl 2
    pdst += (len-1) shl 2
    incp = -4

  if cover == 255:
    doWhile len != 0:
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](pdst,
        psrc[SrcOrderT.R], psrc[SrcOrderT.G],
        psrc[SrcOrderT.B], psrc[SrcOrderT.A])
      psrc += incp
      pdst += incp
      dec len
  else:
    doWhile len != 0:
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](pdst,
        psrc[SrcOrderT.R], psrc[SrcOrderT.G],
        psrc[SrcOrderT.B], psrc[SrcOrderT.A], cover)
      psrc += incp
      pdst += incp
      dec len

proc blendFromColor*[Blender, RenBuf, PixelT, SrcPixelFormatRenderer, ColorT](self: var PixfmtAlphaBlendRgba[Blender,
  RenBuf, PixelT], src: SrcPixelFormatRenderer, color: ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(self.type)

  var
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))

  if psrc == nil: return
  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    len = len

  doWhile len != 0:
    rgbaWrapperCopyOrBlendPix[Blender, ValueT](pdst,
      color.r, color.g, color.b, color.a,
      (psrc[] * cover + baseMask) shr baseShift)
    inc psrc
    inc(pdst, 4)
    dec len

proc blendFromLut*[Blender, RenBuf, PixelT, SrcPixelFormatRenderer, ColorT](self: var PixfmtAlphaBlendRgba[Blender,
  RenBuf, PixelT], src: SrcPixelFormatRenderer, colorLut: ptr ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =
  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(self.type)

  var
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))

  if psrc == nil: return

  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    len = len

  if cover == 255:
    doWhile len != 0:
      let color = colorLut[psrc[]]
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](pdst,
        color.r, color.g, color.b, color.a)
      inc psrc
      inc(pdst, 4)
      dec len
  else:
    doWhile len != 0:
      let color = colorLut[psrc[]]
      rgbaWrapperCopyOrBlendPix[Blender, ValueT](pdst,
        color.r, color.g, color.b, color.a, cover)
      inc psrc
      inc(pdst, 4)
      dec len

type
  CustomBlendTable* = array[28, pointer]
  PixfmtCustomBlendRgba*[Blender, RenBuf] = object
    mRbuf: ptr RenBuf
    mCompOp: int
    mTable: CustomBlendTable

template getOrderT*[B,R](x: typedesc[PixfmtCustomBlendRgba[B,R]]): typedesc = getOrderT(B.type)
template getColorT*[B,R](x: typedesc[PixfmtCustomBlendRgba[B,R]]): typedesc = getColorT(B.type)
template getValueT*[B,R](x: typedesc[PixfmtCustomBlendRgba[B,R]]): typedesc = getValueT(B.type)
template getPixWidth *[B,R](x: typedesc[PixfmtCustomBlendRgba[B,R]]): int = (sizeof(getValueT(B.type)) * 4)

proc initPixfmtCustomBlendRgba*[Blender, RenBuf](rbuf: var Renbuf, compOp = 3): PixfmtCustomBlendRgba[Blender, RenBuf] =
  result.mRbuf = rbuf.addr
  result.mCompOp = compOp
  result.mTable = cast[CustomBlendTable](compOpTable[getColorT(Blender), getOrderT(Blender), getValueT(Blender)]())

proc initPixfmtCustomBlendRgba*[Blender, RenBuf](rbuf: var Renbuf, compOp: CompOp): PixfmtCustomBlendRgba[Blender, RenBuf] =
  result = initPixfmtCustomBlendRgba[Blender, RenBuf](rbuf, compOp.ord)

template construct*[B,R](x: typedesc[PixfmtCustomBlendRgba[B,R]], rbuf: typed): untyped =
  initPixfmtCustomBlendRgba[B,R](rbuf)

proc attach*[Blender, RenBuf](self: var PixfmtCustomBlendRgba[Blender, RenBuf], rbuf: var Renbuf) =
  self.mRbuf = rbuf.addr

proc attach*[Blender, RenBuf, PixFmt](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  pixf: PixFmt, x1, y1, x2, y2: int): bool =

  var r = initRectI(x1, y1, x2, y2)
  if r.clip(initRectI(0, 0, pixf.width()-1, pixf.height()-1)):
    let stride = pixf.stride()
    self.mRbuf[].attach(pixf.pixPtr(r.x1, if stride < 0: r.y2 else: r.y1),
      (r.x2 - r.x1) + 1, (r.y2 - r.y1) + 1, stride)
    return true
  result = false

proc width*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].width()

proc height*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].height()

proc stride*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].stride()

proc rowPtr*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf], y: int): ptr uint8 {.inline.} =
  self.mRbuf[].rowPtr(y)

proc row*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf], y: int): auto {.inline.} =
  self.mRbuf[].row(y)

proc pixPtr*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf], x, y: int): ptr uint8 {.inline.} =
  const pixWidth = getPixWidth(self.type)
  self.mRbuf[].rowPtr(y) + x * pixWidth

proc compOp*[Blender, RenBuf](self: var PixfmtCustomBlendRgba[Blender, RenBuf], op: int) {.inline.} =
  self.mCompOp = op

proc compOp*[Blender, RenBuf](self: var PixfmtCustomBlendRgba[Blender, RenBuf], op: CompOp) {.inline.} =
  self.mCompOp = op.ord

proc compOp*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf]): int {.inline.} =
  self.mCompOp

proc rbuf*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf]): var RenBuf {.inline.} =
  self.mRBuf[]

proc makePix*[Blender, RenBuf, ColorT](x: typedesc[PixfmtCustomBlendRgba[Blender, RenBuf]],
  p: pointer, c: ColorT) {.inline.} =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(ColorT)

  cast[ptr ValueT](p)[OrderT.R] = c.r
  cast[ptr ValueT](p)[OrderT.G] = c.g
  cast[ptr ValueT](p)[OrderT.B] = c.b
  cast[ptr ValueT](p)[OrderT.A] = c.a

proc pixel*[Blender, RenBuf](self: PixfmtCustomBlendRgba[Blender, RenBuf], x, y: int): auto {.inline.} =
  type
    ColorT = getColorT(Blender)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(Blender)
  var p = cast[ptr ValueT](self.mRbuf[].rowPtr(y)) + (x shl 2)
  result = construct(ColorT, p[OrderT.R].uint, p[OrderT.G].uint, p[OrderT.B].uint, p[OrderT.A].uint)

proc copyPixel*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y: int, c: ColorT) =
  type ValueT = getValueT(Blender)
  Blender.blendPix(self.mTable[self.mCompOp],
    cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
    c.r, c.g, c.b, c.a, 255)

proc blendPixel*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y: int, c: ColorT, cover: uint8) =
  type ValueT = getValueT(Blender)
  Blender.blendPix(self.mTable[self.mCompOp],
    cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
    c.r, c.g, c.b, c.a, cover)

proc copyHline*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT) =
  type ValueT = getValueT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp], p, c.r, c.g, c.b, c.a, 255)
    inc(p, 4)
    dec len

proc copyVline*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT) =
  type ValueT = getValueT(Blender)
  var
    len = len
    y = y
  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp],
      cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
      c.r, c.g, c.b, c.a, 255)
    inc y
    dec len

proc blendHline*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =
  type ValueT = getValueT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp], p, c.r, c.g, c.b, c.a, cover)
    inc(p, 4)
    dec len

proc blendVline*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =
  type ValueT = getValueT(Blender)
  var
    len = len
    y = y
  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp],
      cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
      c.r, c.g, c.b, c.a, cover)
    inc y
    dec len

proc blendSolidHspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type ValueT = getValueT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    covers = covers

  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp],
      p, c.r, c.g, c.b, c.a, covers[])
    inc(p, 4)
    dec len
    inc covers

proc blendSolidVspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type ValueT = getValueT(Blender)
  var
    len = len
    y = y
    covers = covers

  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp],
      cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
      c.r, c.g, c.b, c.a, covers[])
    inc y
    inc covers
    dec len

proc copyColorHspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y: int, len: int, colors: ptr ColorT) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    colors = colors
  doWhile len != 0:
    p[OrderT.R] = colors.r
    p[OrderT.G] = colors.g
    p[OrderT.B] = colors.b
    p[OrderT.A] = colors.a
    inc colors
    inc(p, 4)
    dec len

proc copyColorVspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y: int, len: int, colors: ptr ColorT) =
  type
    ValueT = getValueT(Blender)
    OrderT = getOrderT(Blender)
  var
    len = len
    y = y
    colors = colors
  doWhile len != 0:
    var p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2)
    inc y
    p[OrderT.R] = colors.r
    p[OrderT.G] = colors.g
    p[OrderT.B] = colors.b
    p[OrderT.A] = colors.a
    inc colors
    dec len

proc blendColorHspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type ValueT = getValueT(Blender)
  var
    p = cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, len)) + (x shl 2)
    len = len
    colors = colors
    covers = covers
  doWhile len != 0:
    if covers != nil:
      Blender.blendPix(self.mTable[self.mCompOp], p,
        colors.r, colors.g, colors.b, colors.a, covers[])
      inc covers
    else:
      Blender.blendPix(self.mTable[self.mCompOp], p,
      colors.r, colors.g, colors.b, colors.a, cover)
    inc(p, 4)
    inc colors
    dec len

proc blendColorVspan*[Blender, RenBuf, ColorT](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type ValueT = getValueT(Blender)
  var
    len = len
    y = y
    colors = colors
    covers = covers
  doWhile len != 0:
    if covers != nil:
      Blender.blendPix(self.mTable[self.mCompOp],
        cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
        colors.r, colors.g, colors.b, colors.a, covers[])
      inc covers
    else:
      Blender.blendPix(self.mTable[self.mCompOp],
        cast[ptr ValueT](self.mRbuf[].rowPtr(x, y, 1)) + (x shl 2),
        colors.r, colors.g, colors.b, colors.a, cover)
    inc y
    inc colors
    dec len

proc premultiply*[Blender, RenBuf](self: var PixfmtCustomBlendRgba[Blender, RenBuf]) =
  type
    ColorT = getColorT(Blender)
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)
  self.forEachPixel(multiplierRgbaPremultiply[ColorT, OrderT, ValueT])

proc demultiply*[Blender, RenBuf](self: var PixfmtCustomBlendRgba[Blender, RenBuf]) =
  type
    ColorT = getColorT(Blender)
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)
  self.forEachPixel(multiplierRgbaDemultiply[ColorT, OrderT, ValueT])

proc applyGammaDir*[Blender, RenBuf, GammaLut](self: var PixfmtCustomBlendRgba[Blender, RenBuf], gamma: GammaLut) =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  proc apply_gamma_dir_rgba(p: ptr ValueT) =
    p[OrderT.R] = gamma.dir(p[OrderT.R])
    p[OrderT.G] = gamma.dir(p[OrderT.G])
    p[OrderT.B] = gamma.dir(p[OrderT.B])

  self.forEachPixel(apply_gamma_dir_rgba)

proc applyGammaInv*[Blender, RenBuf, GammaLut](self: var PixfmtCustomBlendRgba[Blender, RenBuf], gamma: GammaLut) =
  type
    OrderT = getOrderT(Blender)
    ValueT = getValueT(Blender)

  proc apply_gamma_inv_rgba(p: ptr ValueT) =
    p[OrderT.R] = gamma.inv(p[OrderT.R])
    p[OrderT.G] = gamma.inv(p[OrderT.G])
    p[OrderT.B] = gamma.inv(p[OrderT.B])

  self.forEachPixel(apply_gamma_inv_rgba)

proc copyFrom*[Blender, RenBuf, RenBuf2](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  src: RenBuf2, xdst, ydst, xsrc, ysrc, len: int) =
  const pixWidth = getPixWidth(self.type)
  var p = src.rowPtr(ysrc)
  if p != nil:
    moveMem(self.mRbuf[].rowPtr(xdst, ydst, len) + xdst * pixWidth,
      p + xsrc * pixWidth, len * pixWidth)

proc blendFrom*[Blender, RenBuf, SrcPixelFormatRenderer](self: var PixfmtCustomBlendRgba[Blender, RenBuf],
  src: SrcPixelFormatRenderer, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcOrderT = getOrderT(SrcPixelFormatRenderer)
    ValueT = getValueT(Blender)

  var
    psrc = cast[ptr ValueT](src.rowPtr(ysrc))
    len = len

  if psrc == nil: return
  psrc += xsrc shl 2

  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    incp = 4

  if xdst > xsrc:
    psrc += (len-1) shl 2
    pdst += (len-1) shl 2
    incp = -4

  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp], pdst,
      psrc[SrcOrderT.R], psrc[SrcOrderT.G],
      psrc[SrcOrderT.B], psrc[SrcOrderT.A], cover)
    psrc += incp
    pdst += incp
    dec len

proc blendFromColor*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: var PixfmtCustomBlendRgba[Blender,
  RenBuf], src: SrcPixelFormatRenderer, color: ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =
  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(self.type)

  var
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))

  if psrc == nil: return
  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    len = len

  doWhile len != 0:
    Blender.blendPix(self.mTable[self.mCompOp], pdst,
      color.r, color.g, color.b, color.a,
      (psrc[] * cover + baseMask) shr baseShift)
    inc psrc
    inc(pdst, 4)
    dec len

proc blendFromLut*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: var PixfmtCustomBlendRgba[Blender,
  RenBuf], src: SrcPixelFormatRenderer, colorLut: ptr ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =
  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    ValueT = getValueT(self.type)

  var
    psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))

  if psrc == nil: return

  var
    pdst = cast[ptr ValueT](self.mRbuf[].rowPtr(xdst, ydst, len)) + (xdst shl 2)
    len = len

  doWhile len != 0:
    let color = colorLut[psrc[]]
    Blender.blendPix(self.mTable[self.mCompOp], pdst,
      color.r, color.g, color.b, color.a, cover)
    inc psrc
    inc(pdst, 4)
    dec len

type
  BlenderRgba32* = BlenderRgba[Rgba8, OrderRgba]
  BlenderArgb32* = BlenderRgba[Rgba8, OrderArgb]
  BlenderAbgr32* = BlenderRgba[Rgba8, OrderAbgr]
  BlenderBgra32* = BlenderRgba[Rgba8, OrderBgra]

  BlenderRgba32Pre* = BlenderRgbaPre[Rgba8, OrderRgba]
  BlenderArgb32Pre* = BlenderRgbaPre[Rgba8, OrderArgb]
  BlenderAbgr32Pre* = BlenderRgbaPre[Rgba8, OrderAbgr]
  BlenderBgra32Pre* = BlenderRgbaPre[Rgba8, OrderBgra]

  BlenderRgba32Plain* = BlenderRgbaPlain[Rgba8, OrderRgba]
  BlenderArgb32Plain* = BlenderRgbaPlain[Rgba8, OrderArgb]
  BlenderAbgr32Plain* = BlenderRgbaPlain[Rgba8, OrderAbgr]
  BlenderBgra32Plain* = BlenderRgbaPlain[Rgba8, OrderBgra]

  BlenderRgba64* = BlenderRgba[Rgba16, OrderRgba]
  BlenderArgb64* = BlenderRgba[Rgba16, OrderArgb]
  BlenderAbgr64* = BlenderRgba[Rgba16, OrderAbgr]
  BlenderBgra64* = BlenderRgba[Rgba16, OrderBgra]

  BlenderRgba64Pre* = BlenderRgbaPre[Rgba16, OrderRgba]
  BlenderArgb64Pre* = BlenderRgbaPre[Rgba16, OrderArgb]
  BlenderAbgr64Pre* = BlenderRgbaPre[Rgba16, OrderAbgr]
  BlenderBgra64Pre* = BlenderRgbaPre[Rgba16, OrderBgra]

  Pixel32Type* = uint32
  PixfmtRgba32* = PixfmtAlphaBlendRgba[BlenderRgba32, RenderingBuffer, Pixel32Type]
  PixfmtArgb32* = PixfmtAlphaBlendRgba[BlenderArgb32, RenderingBuffer, Pixel32Type]
  PixfmtAbgr32* = PixfmtAlphaBlendRgba[BlenderAbgr32, RenderingBuffer, Pixel32Type]
  PixfmtBgra32* = PixfmtAlphaBlendRgba[BlenderBgra32, RenderingBuffer, Pixel32Type]

  PixfmtRgba32Pre* = PixfmtAlphaBlendRgba[BlenderRgba32Pre, RenderingBuffer, Pixel32Type]
  PixfmtArgb32Pre* = PixfmtAlphaBlendRgba[BlenderArgb32Pre, RenderingBuffer, Pixel32Type]
  PixfmtAbgr32Pre* = PixfmtAlphaBlendRgba[BlenderAbgr32Pre, RenderingBuffer, Pixel32Type]
  PixfmtBgra32Pre* = PixfmtAlphaBlendRgba[BlenderBgra32Pre, RenderingBuffer, Pixel32Type]

  PixfmtRgba32Plain* = PixfmtAlphaBlendRgba[BlenderRgba32Plain, RenderingBuffer, Pixel32Type]
  PixfmtArgb32Plain* = PixfmtAlphaBlendRgba[BlenderArgb32Plain, RenderingBuffer, Pixel32Type]
  PixfmtAbgr32Plain* = PixfmtAlphaBlendRgba[BlenderAbgr32Plain, RenderingBuffer, Pixel32Type]
  PixfmtBgra32Plain* = PixfmtAlphaBlendRgba[BlenderBgra32Plain, RenderingBuffer, Pixel32Type]

  Pixel64Type* = uint64

  PixfmtRgba64* = PixfmtAlphaBlendRgba[BlenderRgba64, RenderingBuffer16, Pixel64Type]
  PixfmtArgb64* = PixfmtAlphaBlendRgba[BlenderArgb64, RenderingBuffer16, Pixel64Type]
  PixfmtAbgr64* = PixfmtAlphaBlendRgba[BlenderAbgr64, RenderingBuffer16, Pixel64Type]
  PixfmtBgra64* = PixfmtAlphaBlendRgba[BlenderBgra64, RenderingBuffer16, Pixel64Type]

  PixfmtRgba64Pre* = PixfmtAlphaBlendRgba[BlenderRgba64Pre, RenderingBuffer16, Pixel64Type]
  PixfmtArgb64Pre* = PixfmtAlphaBlendRgba[BlenderArgb64Pre, RenderingBuffer16, Pixel64Type]
  PixfmtAbgr64Pre* = PixfmtAlphaBlendRgba[BlenderAbgr64Pre, RenderingBuffer16, Pixel64Type]
  PixfmtBgra64Pre* = PixfmtAlphaBlendRgba[BlenderBgra64Pre, RenderingBuffer16, Pixel64Type]

proc initPixFmtRgba32*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderRgba32, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtArgb32*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderArgb32, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtAbgr32*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderAbgr32, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtBgra32*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderBgra32, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtRgba32Pre*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderRgba32Pre, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtArgb32Pre*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderArgb32Pre, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtAbgr32Pre*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderAbgr32Pre, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtBgra32Pre*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderBgra32Pre, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtRgba32Plain*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderRgba32Plain, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtArgb32Plain*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderArgb32Plain, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtAbgr32Plain*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderAbgr32Plain, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtBgra32Plain*(rbuf: var RenderingBuffer): auto =
  initPixfmtAlphaBlendRgba[BlenderBgra32Plain, RenderingBuffer, Pixel32Type](rbuf)

proc initPixfmtRgba64*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderRgba64, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtArgb64*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderArgb64, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtAbgr64*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderAbgr64, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtBgra64*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderBgra64, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtRgba64Pre*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderRgba64Pre, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtArgb64Pre*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderArgb64Pre, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtAbgr64Pre*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderAbgr64Pre, RenderingBuffer16, Pixel64Type](rbuf)

proc initPixfmtBgra64Pre*(rbuf: var RenderingBuffer16): auto =
  initPixfmtAlphaBlendRgba[BlenderBgra64Pre, RenderingBuffer16, Pixel64Type](rbuf)