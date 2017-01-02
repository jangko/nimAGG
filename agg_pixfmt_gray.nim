import agg_basics, agg_rendering_buffer, agg_color_gray

type
  BlenderGray*[ColorT] = object
  BlenderGrayPre*[ColorT] = object

template getCalcType* [C](x: typedesc[BlenderGray[C]]): untyped = getCalcType(C.type)
template getValueType*[C](x: typedesc[BlenderGray[C]]): untyped = getValueType(C.type)
template getColorType*[C](x: typedesc[BlenderGray[C]]): typedesc = C
template getPixWidth* [C](x: typedesc[BlenderGray[C]]): int = sizeof(getValueType(C.type))

template getCalcType* [C](x: typedesc[BlenderGrayPre[C]]): untyped = getCalcType(C.type)
template getValueType*[C](x: typedesc[BlenderGrayPre[C]]): untyped = getValueType(C.type)
template getColorType*[C](x: typedesc[BlenderGrayPre[C]]): typedesc = C
template getPixWidth* [C](x: typedesc[BlenderGrayPre[C]]): int = sizeof(getValueType(C.type))

proc BlenderGrayBlendPix*[C,T](p: ptr T; cv, alpha: uint; cover = 0'u) {.inline.} =
  type
    ValueType = getValueType(C)
    CalcType = getCalcType(C)
  const baseShift = getBaseShift(C).CalcType
  p[] = ValueType((((CalcType(cv) - CalcType(p[])) * CalcType(alpha)) + (CalcType(p[]) shl baseShift)) shr baseShift)

proc BlenderGrayPreBlendPix*[C,T](p: ptr T; cv, alpha, cover: uint) {.inline.} =
  const
    baseMask = getBaseMask(C)
    baseShift = getBaseShift(C)
  type
    ValueType = getValueType(C)
  let alpha = baseMask - alpha
  let cover = (cover + 1) shl (baseShift - 8)
  p[] = ValueType((p[] * alpha + cv * cover) shr baseShift)

proc BlenderGrayPreBlendPix*[C,T](p: ptr T; cv, alpha: uint) {.inline.} =
  const
    baseMask = getBaseMask(C)
    baseShift = getBaseShift(C)
  type
    ValueType = getValueType(C)
  p[] = ValueType(((p[] * (baseMask - alpha)) shr baseShift) + cv)

template blendPix[C](x: typedesc[BlenderGray[C]], p: untyped, cv, alpha: uint) =
  BlenderGrayBlendPix[C.type, getValueType(C.type)](p, cv, alpha)

template blendPix[C](x: typedesc[BlenderGray[C]], p: untyped, cv, alpha, cover: uint) =
  BlenderGrayBlendPix[C.type, getValueType(C.type)](p, cv, alpha, cover)

template blendPix[C](x: typedesc[BlenderGrayPre[C]], p: untyped, cv, alpha: uint) =
  BlenderGrayPreBlendPix[C.type, getValueType(C.type)](p, cv, alpha)

template blendPix[C](x: typedesc[BlenderGrayPre[C]], p: untyped, cv, alpha, cover: uint) =
  BlenderGrayPreBlendPix[C.type, getValueType(C.type)](p, cv, alpha, cover)

template pixfmtAlphaBlendGray(Blender, RenBuf: typed, Step, Offset: int, name: untyped) =
  type
    name* = object
      rbuf: RenBuf

  proc copyOrBlendPix[ColorT, ValueT](x: typedesc[name], p: ptr ValueT, c: ColorT, cover: uint) {.inline.} =
    type CalcType = getCalcType(ColorT)
    const baseMask = getBaseMask(ColorT)

    if c.a != 0:
      let alpha = (CalcType(c.a) * CalcType(cover + 1)) shr 8
      if alpha == baseMask:
        p[] = c.v
      else:
        Blender.blendPix(p, c.v, alpha, cover)

  proc copyOrBlendPix[ColorT, ValueT](x: typedesc[name], p: ptr ValueT, c: ColorT) {.inline.} =
    const baseMask = getBaseMask(ColorT)
    if c.a != 0:
      if c.a == baseMask:
        p[] = c.v
      else:
        Blender.blendPix(p, c.v, c.a)

  proc `init name`*(rb: RenBuf): name =
    result.rbuf = rb

  proc attach*(self: var name, rb: RenBuf) =
    self.rbuf = rb

  proc attach*[PixFmt](self: name, pixf: PixFmt; x1, y1, x2, y2: int): bool =
    var r = initRectBase[int](x1, y1, x2, y2)
    let c = initRectBase[int](0, 0, pixf.width()-1, pixf.height()-1)

    if r.clip(c):
      let stride = pixf.stride()
      self.rbuf.attach(pixf.pixPtr(r.x1,
        if stride < 0: r.y2 else: r.y1),
        (r.x2 - r.x1) + 1, (r.y2 - r.y1) + 1, stride)
      return true
    result = false

  proc width*(self: name) : int {.inline.} = self.rbuf.width()
  proc height*(self: name): int {.inline.} = self.rbuf.height()
  proc stride*(self: name): int {.inline.} = self.rbuf.stride()
  proc rowPtr*(self: name, y: int): auto = self.rbuf.rowPtr(y)
  proc row*(self: name, y: int): auto = self.rbuf.row(y)
  proc pixPtr*(self: name; x, y: int): auto = self.rbuf.rowPtr(y) + x * Step + Offset

  proc makePix*[ColorT](x: typedesc[name], p: pointer, c: ColorT) {.inline.} =
    type ValueType = getValueType(ColorT)
    cast[ptr ValueType](p)[] = c.v

  proc pixel*(self: name, x, y: int): auto {.inline.} =
    let p = self.rbuf.rowPtr(y) + x * Step + Offset
    result = construct(getColorType(Blender), p[])

  proc copyPixel*[ColorT](self: name; x, y: int, c: ColorT) {.inline.} =
    var p = self.rbuf.rowPtr(x, y, 1) + x * Step + Offset
    p[] = c.v

  proc blendPixel*[ColorT](self: name; x, y: int, c: ColorT, cover: uint8) {.inline.} =
    let p = self.rbuf.rowPtr(x, y, 1) + x * Step + Offset
    name.copyOrBlendPix(p, c, cover)

  proc copyHline*[ColorT](self: name; x, y, length: int, c: ColorT) {.inline.} =
    type ValueType = getValueType(Blender)
    var
      len = length
      p = self.rbuf.rowPtr(x, y, len) + x * Step + Offset
    doWhile len != 0:
      p[] = c.v
      inc(p, Step)
      dec len

  proc copyVline*[ColorT](self: name; x, y, length: int, c: ColorT) {.inline.} =
    type ValueType = getValueType(Blender)
    var
      len = length
      line = y
    doWhile len != 0:
      var p = cast[ptr ValueType](self.rbuf.rowPtr(x, line, 1) + x * Step + Offset)
      inc line
      p[] = c.v
      dec len

  proc blendHline*[ColorT](self: name, x, y, length: int; c: ColorT, cover: uint8) =
    type
      ValueType = getValueType(ColorT)
      CalcType = getCalcType(ColorT)
    const
      baseMask = getBaseMask(ColorT)
    if c.a == 0: return
    var
      len = length
      p = self.rbuf.rowPtr(x, y, len) + x * Step + Offset

    let alpha = (CalcType(c.a) * (cover + 1)) shr 8
    if alpha == baseMask:
      doWhile len != 0:
        p[] = c.v
        inc(p, Step)
        dec len
    else:
      doWhile len != 0:
        Blender.blendPix(p, c.v, alpha, cover)
        inc(p, Step)
        dec len

  proc blendVline*[ColorT](self: name, x, y, length: int; c: ColorT, cover: uint8) =
    type
      ValueType = getValueType(ColorT)
      CalcType = getCalcType(ColorT)
    const
      baseMask = getBaseMask(ColorT)

    if c.a == 0: return
    let alpha = (CalcType(c.a) * (cover + 1)) shr 8
    var
      p: ptr ValueType
      line = y
      len = length

    if alpha == baseMask:
      doWhile len != 0:
        p = self.rbuf.rowPtr(x, line, 1) + x * Step + Offset
        inc line
        p[] = c.v
        dec len
    else:
      doWhile len != 0:
        p = self.rbuf.rowPtr(x, line, 1) + x * Step + Offset
        inc line
        Blender.blendPix(p, c.v, alpha, cover)
        dec len

  proc blendSolidHspan*[ColorT](self: name, x, y, length: int; c: ColorT, covers: ptr uint8) =
    type
      ValueType = getValueType(ColorT)
      CalcType = getCalcType(ColorT)
    const
      baseMask = getBaseMask(ColorT)
    if c.a == 0: return
    var
      len = length
      p = self.rbuf.rowPtr(x, y, len) + x * Step + Offset
      cv = covers

    doWhile len != 0:
      let alpha = (CalcType(c.a) * (CalcType(cv[]) + 1)) shr 8
      if alpha == baseMask:
        p[] = c.v
      else:
        Blender.blendPix(p, c.v, alpha, cv[])

      inc(p, Step)
      inc cv
      dec len

  proc blendSolidVspan*[ColorT](self: name, x, y, length: int; c: ColorT, covers: ptr uint8) =
    type
      ValueType = getValueType(ColorT)
      CalcType = getCalcType(ColorT)
    const
      baseMask = getBaseMask(ColorT)
    if c.a == 0: return
    var
      line = y
      len = length
      cv = covers

    doWhile len != 0:
      let alpha = (CalcType(c.a) * (CalcType(cv[]) + 1)) shr 8
      var p = cast[ptr ValueType](self.rbuf.rowPtr(x, line, 1) + x * Step + Offset)
      inc line
      if alpha == baseMask:
        p[] = c.v
      else:
        Blender.blendPix(p, c.v, alpha, cv[])
      inc cv
      dec len

  proc copyColorHspan*[ColorT](self: name, x, y, length: int; colors: ptr ColorT) =
    type ValueType = getValueType(Blender)
    var
      len = length
      p = self.rbuf.rowPtr(x, y, len) + x * Step + Offset
      co = colors

    doWhile len != 0:
      p[] = co.v
      inc(p, Step)
      inc co
      dec len

  proc copyColorVspan*[ColorT](self: name, x, y, length: int; colors: ptr ColorT) =
    type ValueType = getValueType(Blender)
    var
      len = length
      line = y
      co = colors

    doWhile len != 0:
      var p = cast[ptr ValueType](self.rbuf.rowPtr(x, line, 1) + x * Step + Offset)
      inc line
      p[] = co.v
      inc co
      dec len

  proc blendColorHspan*[ColorT](self: name, x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
    type ValueType = getValueType(ColorT)
    const baseMask = getBaseMask(ColorT)
    var
      len = length
      p = cast[ptr ValueType](self.rbuf.rowPtr(x, y, len) + x * Step + Offset)
      co = colors
      cv = covers

    if covers != nil:
      doWhile len != 0:
        name.copyOrBlendPix(p, co[], cv[])
        inc co
        inc cv
        inc(p, Step)
        dec len
      return

    if cover == 255:
      doWhile len != 0:
        if co.a == baseMask:
          p[] = co.v
        else:
          name.copyOrBlendPix(p, co[])
        inc(p, Step)
        inc co
        dec len
    else:
      doWhile len != 0:
        name.copyOrBlendPix(p, co[], cover)
        inc co
        inc(p, Step)
        dec len

  proc blendColorVspan*[ColorT](self: name, x, y, length: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
    type ValueType = getValueType(ColorT)
    const baseMask = getBaseMask(ColorT)
    var
      p: ptr ValueType
      len = length
      line = y
      co = colors
      cv = covers

    if covers != nil:
      doWhile len != 0:
        p = self.rbuf.rowPtr(x, line, 1) + x * Step + Offset
        inc line
        name.copyOrBlendPix(p, co[], cv[])
        inc co
        inc cv
        dec len
      return

    if cover == 255:
      doWhile len != 0:
        p = self.rbuf.rowPtr(x, line, 1) + x * Step + Offset
        inc line
        if co.a == baseMask:
          p[] = co.v
        else:
          name.copyOrBlendPix(p, co[])
          inc co
        dec len
    else:
      doWhile len != 0:
        p = self.rbuf.rowPtr(x, line, 1) + x * Step + Offset
        inc line
        name.copyOrBlendPix(p, co[], cover)
        inc co
        dec len

  proc forEachPixel[Func](self: name, f: Func) =
    type ValueType = getValueType(Blender)
    let h = self.height()
    for y in 0.. <h:
      let r = self.rbuf.row(y)
      if r.data != nil:
        var
          len = r.x2 - r.x1 + 1
          p = cast[ptr ValueType](self.rbuf.rowPtr(r.x1, y, len) + r.x1 * Step + Offset)
        doWhile len != 0:
          f(p)
          inc(p, Step)
          dec len

  proc applyGammaDir*[GammaLut](self: name, gamma: GammaLut) =
    type ValueType = getValueType(Blender)
    proc apply_gamma_dir_gray(p: ptr ValueType) =
      p[] = gamma.dir(p[])
    self.forEachPixel(apply_gamma_dir_gray)

  proc applyGammaInv*[GammaLut](self: name, gamma: GammaLut) =
    type ValueType = getValueType(Blender)
    proc apply_gamma_inv_gray(p: ptr ValueType) =
      p[] = gamma.inv(p[])
    self.forEachPixel(apply_gamma_inv_gray)

  proc copyFrom*[Renbuf2](self: name, src: RenBuf2, xdst, ydst, xsrc, ysrc, len: int) =
    const pixWidth = getPixWidth(Blender)
    let p = src.rowPtr(ysrc)
    if p == nil: return
    moveMem(self.rbuf.rowPtr(xdst, ydst, len) + xdst * pixWidth,
            p + xsrc * pixWidth, len * pixWidth)

  proc blendFromColor*[SrcPixelFormatRenderer, ColorT](self: name, src: SrcPixelFormatRenderer,
    color: ColorT; xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =
      type
        SrcValueType = getValueType(SrcPixelFormatRenderer)
        ValueType = getValueType(ColorT)
      var psrc = cast[ptr SrcValueType](src.rowPtr(ysrc))
      if psrc != nil:
        var pdst = cast[ptr ValueType](self.rbuf.rowPtr(xdst, ydst, len) + xdst)
        doWhile len != 0:
          name.copyOrBlendPix(pdst, color, (psrc[] * cover + baseMask) shr baseShift)
          inc psrc
          inc pdst
          dec len

  proc blendFromLut*[SrcPixelFormatRenderer, ColorT](self: name, src: SrcPixelFormatRenderer,
    colorLut: ptr ColorT; xdst, ydst, xsrc, ysrc, len: int; cover: uint8) =
      type
        SrcValueType = getValueType(SrcPixelFormatRenderer)
        ValueType = getValueType(ColorT)
      var psrc = cast[ptr SrcValueType](src.rowPtr(ysrc))
      if psrc != nil:
        var pdst = cast[ptr ValueType](self.rbuf.rowPtr(xdst, ydst, len) + xdst)
        doWhile len != 0:
          name.copyOrBlendPix(pdst, colorLut[psrc[]], cover)
          inc psrc
          inc pdst
          dec len

type
  BlenderGray8     = BlenderGray[Gray8]
  BlenderGray8Pre  = BlenderGrayPre[Gray8]
  BlenderGray16    = BlenderGray[Gray16]
  BlenderGray16Pre = BlenderGrayPre[Gray16]

pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 1, 0, PixfmtGray8)
pixfmtAlphaBlendGray(BlenderGray8Pre, RenderingBuffer, 1, 0, PixfmtGray8Pre)
pixfmtAlphaBlendGray(BlenderGray16, RenderingBuffer16, 1, 0, PixfmtGray16)
pixfmtAlphaBlendGray(BlenderGray16Pre, RenderingBuffer16, 1, 0, PixfmtGray16Pre)
