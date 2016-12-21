import agg_basics, agg_rendering_buffer, agg_color_rgba

type
  blender_rgb*[ColorT, OrderT] = object

  pixfmt_alpha_blend_rgb*[Blender, RenBuf] = object
    blender: Blender
    rbuf: ptr RenBuf

template get_order_type*[C, O](x: typedesc[blender_rgb[C, O]]): typedesc = O
template get_value_type*[C, O](x: typedesc[blender_rgb[C, O]]): untyped = get_value_type(C.type)

proc copy_pixel*[Blender, RenBuf, ColorT](self: var pixfmt_alpha_blend_rgb[Blender, RenBuf],
  x, y: int, c: ColorT) =
  type
    order_type = get_order_type(Blender)
    value_type = get_value_type(Blender)

  var p = cast[ptr value_type](self.rbuf[].rowPtr(x, y, 1) + x + x + x)
  p[order_type.R.ord] = c.r
  p[order_type.G.ord] = c.g
  p[order_type.B.ord] = c.b

proc height*[Blender, RenBuf](self: pixfmt_alpha_blend_rgb[Blender, RenBuf]): int =
  result = self.rbuf[].height()

proc width*[Blender, RenBuf](self: pixfmt_alpha_blend_rgb[Blender, RenBuf]): int =
  result = self.rbuf[].width()

proc blend_pix*[C, O, T](self: blender_rgb[C, O],
  p: ptr T, cr, cg, cb, alpha: uint, cover=0.uint) {.inline.} =
  const
    base_shift = get_base_shift(C)

  p[O.R.ord] += T(((cr - p[O.R.ord].uint) * alpha) shr base_shift)
  p[O.G.ord] += T(((cg - p[O.G.ord].uint) * alpha) shr base_shift)
  p[O.B.ord] += T(((cb - p[O.B.ord].uint) * alpha) shr base_shift)

proc copy_or_blend_pix[Blender, RenBuf, C, T](self: pixfmt_alpha_blend_rgb[Blender, RenBuf],
  p: ptr T, c: C, cover: uint) {.inline.} =
  type
    calc_type = get_calc_type(C)
    order_type = get_order_type(Blender)
  const
    base_mask = get_base_mask(C)

  if c.a != 0:
    let alpha = (calc_type(c.a) * calc_type(cover + 1)) shr 8
    if alpha == base_mask:
      p[order_type.R.ord] = c.r
      p[order_type.G.ord] = c.g
      p[order_type.B.ord] = c.b
    else:
      self.blender.blend_pix(p, c.r.uint, c.g.uint, c.b.uint, alpha, cover)

proc copy_or_blend_pix[Blender, RenBuf, C, T](self: pixfmt_alpha_blend_rgb[Blender, RenBuf],
  p: ptr T, c: C) {.inline.} =

  type order_type = get_order_type(Blender)
  const base_mask = get_base_mask(C)

  if c.a != 0:
    if c.a == base_mask:
      p[order_type.R.ord] = c.r
      p[order_type.G.ord] = c.g
      p[order_type.B.ord] = c.b
  else:
    self.blender.blend_pix(p, c.r.uint, c.g.uint, c.b.uint, c.a.uint)

proc blend_color_hspan*[Blender, RenBuf, ColorT](self: pixfmt_alpha_blend_rgb[Blender, RenBuf],
  x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =

  type
    value_type = get_value_type(Blender)

  var
    p = cast[ptr value_type](self.rbuf[].rowPtr(x, y, length) + x + x + x)
    len = length
    co = colors
    cv = covers

  if covers != nil:
    doWhile len != 0:
      self.copy_or_blend_pix(p, co[], cv[])
      inc co
      inc cv
      inc(p, 3)
      dec len
    return

  if cover == 255:
    doWhile len != 0:
      self.copy_or_blend_pix(p, co[])
      inc co
      inc(p, 3)
      dec len
  else:
    doWhile len != 0:
      self.copy_or_blend_pix(p, co[], cover)
      inc co
      inc(p, 3)
      dec len

type
  pixfmt_rgb24* = pixfmt_alpha_blend_rgb[blender_rgb[rgba8, order_rgb], RenderingBuffer]

proc initPixFmtRgb24*(rbuf: var RenderingBuffer): pixfmt_rgb24 =
  result.rbuf = rbuf.addr

