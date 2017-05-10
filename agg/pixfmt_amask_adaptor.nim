import basics, rendering_buffer, alpha_mask_u8

type
  PixfmtAmaskAdaptor*[PixFmt, Amask] = object
    pixf: ptr PixFmt
    mask: ptr Amask
    span: seq[CoverType]

template getOrderT*[P,A](x: typedesc[PixfmtAmaskAdaptor[P,A]]): typedesc = getOrderT(P.type)
template getColorT*[P,A](x: typedesc[PixfmtAmaskAdaptor[P,A]]): typedesc = getColorT(P.type)
template getValueT*[P,A](x: typedesc[PixfmtAmaskAdaptor[P,A]]): typedesc = getValueT(P.type)
template getPixWidth*[P,A](x: typedesc[PixfmtAmaskAdaptor[P,A]]): int = getPixWidth(P.type)

const
  spanExtraTail = 256

proc reallocSpan[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask], len: int) =
  if len > self.span.len:
    self.span.setLen(len + spanExtraTail)

proc initSpan[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask], len: int) =
  self.reallocSpan(len)
  setMem(self.span[0].addr, Amask.coverFull, len * sizeof(CoverType))

proc initSpan[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask], len: int, covers: ptr CoverType) =
  self.reallocSpan(len)
  copyMem(self.span[0].addr, covers, len * sizeof(CoverType))

proc initPixfmtAmaskAdaptor*[PixFmt, Amask](pixf: var PixFmt, mask: var Amask): PixfmtAmaskAdaptor[PixFmt, Amask] =
  result.pixf = pixf.addr
  result.mask = mask.addr
  result.span = @[]

proc attachPixfmt*[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask], pixf: var PixFmt) =
  self.pixf = pixf.addr

proc attachAlphaMask*[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask], mask: var Amask) =
  self.mask = mask.addr

proc attachPixfmt*[PixFmt, Amask, PixFmt2](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  pixf: var PixFmt2, x1, y1, x2, y2: int): bool =
  mixin attach
  result = self.pixf[].attach(pixf, x1, y1, x2, y2)

proc width*[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask]): int =
  mixin width
  self.pixf[].width()

proc height*[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask]): int =
  mixin height
  self.pixf[].height()

proc pixel*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask], x, y: int): ColorT =
  mixin pixel
  result = self.pixf[].pixel(x, y)

proc copyPixel*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask], x, y: int, c: ColorT) =
  mixin blendPixel
  self.pixf[].blendPixel(x, y, c, self.mask[].pixel(x, y))

proc blendPixel*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask], x, y: int, c: ColorT, cover: CoverType) =
  mixin blendPixel
  self.pixf[].blendPixel(x, y, c, self.mask[].combine_pixel(x, y, cover))

proc copyHline*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask], x, y, len: int, c: ColorT) =
  mixin blendSolidHspan
  self.reallocSpan(len)
  self.mask[].fillHspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidHspan(x, y, len, c, self.span[0].addr)

proc blendHline*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, c: ColorT, cover: CoverType) =
  mixin blendSolidHspan
  self.initSpan(len)
  self.mask[].combineHspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidHspan(x, y, len, c, self.span[0].addr)

proc copyVline*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, c: ColorT) =
  mixin blendSolidVspan
  self.reallocSpan(len)
  self.mask[].fillVspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidVspan(x, y, len, c, self.span[0].addr)

proc blendVline*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, c: ColorT, cover: CoverType) =
  mixin blendSolidVspan
  self.initSpan(len)
  self.mask[].combineVspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidVspan(x, y, len, c, self.span[0].addr)

proc copyFrom*[PixFmt, Amask](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  src: RenderingBuffer, xdst, ydst, xsrc, ysrc: int, len: int) =
  mixin copyFrom
  self.pixf[].copyFrom(src, xdst, ydst, xsrc, ysrc, len)

proc blendSolidHspan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, c: ColorT, covers: ptr CoverType) =
  mixin blendSolidHspan
  self.initSpan(len, covers)
  self.mask[].combineHspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidHspan(x, y, len, c, self.span[0].addr)

proc blendSolidVspan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, c: ColorT, covers: ptr CoverType) =
  mixin blendSolidVspan
  self.initSpan(len, covers)
  self.mask[].combineVspan(x, y, self.span[0].addr, len)
  self.pixf[].blendSolidVspan(x, y, len, c, self.span[0].addr)

proc copyColorHspan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT) =
  mixin blendColorHspan
  self.reallocSpan(len)
  self.mask[].fillHspan(x, y, self.span[0].addr, len)
  self.pixf[].blendColorHSpan(x, y, len, colors, self.span[0].addr, Amask.coverFull)

proc copyColorVspan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT) =
  mixin blendColorVspan
  self.reallocSpan(len)
  self.mask[].fillVspan(x, y, self.span[0].addr, len)
  self.pixf[].blendColorVSpan(x, y, len, colors, self.span[0].addr, Amask.coverFull)

proc blendColorHSpan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT, covers: ptr CoverType, cover: CoverType) =
  mixin blendColorHspan
  if covers != nil:
    self.initSpan(len, covers)
    self.mask[].combineHspan(x, y, self.span[0].addr, len)
  else:
    self.reallocSpan(len)
    self.mask[].fillHspan(x, y, self.span[0].addr, len)

  self.pixf[].blendColorHSpan(x, y, len, colors, self.span[0].addr, cover)

proc blendColorHSpan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT, covers: ptr CoverType) {.inline.} =
  self.blendColorHSpan(x, y, len, colors, covers, Amask.coverFull)

proc blendColorVSpan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT, covers: ptr CoverType, cover: CoverType) =
  mixin blendColorVspan
  if covers != nil:
    self.initSpan(len, covers)
    self.mask[].combineVspan(x, y, self.span[0].addr, len)
  else:
    self.reallocSpan(len)
    self.mask[].fillVspan(x, y, self.span[0].addr, len)
  self.pixf[].blendColorVSpan(x, y, len, colors, self.span[0].addr, cover)

proc blendColorVSpan*[PixFmt, Amask, ColorT](self: var PixfmtAmaskAdaptor[PixFmt, Amask],
  x, y: int, len: int, colors: ptr ColorT, covers: ptr CoverType) {.inline.} =
  self.blendColorVSpan(x, y, len, colors, covers, Amask.coverFull)