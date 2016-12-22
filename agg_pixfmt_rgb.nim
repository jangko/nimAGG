import agg_basics, agg_rendering_buffer, agg_color_rgba

type
  BlenderRgb*[ColorT, OrderT] = object

  PixfmtAlphaBlendRgb*[Blender, RenBuf] = object
    blender: Blender
    rbuf: RenBuf

template getOrderType*[C, O](x: typedesc[BlenderRgb[C, O]]): typedesc = O
template getValueType*[C, O](x: typedesc[BlenderRgb[C, O]]): untyped = getValueType(C.type)

proc copyPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y: int, c: ColorT) =
  type
    OrderType = getOrderType(Blender)
    ValueType = getValueType(Blender)

  var p = cast[ptr ValueType](self.rbuf.rowPtr(x, y, 1) + x + x + x)
  p[OrderType.R] = c.r
  p[OrderType.G] = c.g
  p[OrderType.B] = c.b

proc height*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int =
  result = self.rbuf.height()

proc width*[Blender, RenBuf](self: PixfmtAlphaBlendRgb[Blender, RenBuf]): int =
  result = self.rbuf.width()

proc blendPix*[C, O, T](self: BlenderRgb[C, O],
  p: ptr T, cr, cg, cb, alpha: uint, cover=0.uint) {.inline.} =
  const
    baseShift = getBaseShift(C)

  p[O.R] += T(((cr - p[O.R].uint) * alpha) shr baseShift)
  p[O.G] += T(((cg - p[O.G].uint) * alpha) shr baseShift)
  p[O.B] += T(((cb - p[O.B].uint) * alpha) shr baseShift)

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

proc blendColorHspan*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgb[Blender, RenBuf],
  x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    ValueType = getValueType(Blender)

  var
    p = cast[ptr ValueType](self.rbuf.rowPtr(x, y, length) + x + x + x)
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

type
  PixfmtRgb24* = PixfmtAlphaBlendRgb[BlenderRgb[Rgba8, OrderRgb], RenderingBuffer]

proc initPixFmtRgb24*(rbuf: RenderingBuffer): PixfmtRgb24 =
  result.rbuf = rbuf

