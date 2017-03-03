import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_scanline_p, agg_path_storage, agg_renderer_scanline, agg_pixfmt_rgb, agg_pixfmt_rgb_packed
import agg_pixfmt_rgba, agg_color_rgba, agg_color_conv_rgb8, agg_color_conv
import nimBMP, agg_renderer_base, agg_pixfmt_gray, agg_color_gray, agg_gamma_lut

type
  PixFormat = enum
    pix_format_rgb555
    pix_format_rgb565
    pix_format_rgb555_pre
    pix_format_rgb565_pre
    pix_format_rgb24
    pix_format_bgr24
    pix_format_rgb24_pre
    pix_format_bgr24_pre
    pix_format_rgba32
    pix_format_argb32
    pix_format_abgr32
    pix_format_bgra32
    pix_format_rgba32_pre
    pix_format_argb32_pre
    pix_format_abgr32_pre
    pix_format_bgra32_pre
    pix_format_rgba32_plain
    pix_format_argb32_plain
    pix_format_abgr32_plain
    pix_format_bgra32_plain
    pix_format_gray8
    pix_format_gray8_pre
    pix_format_rgb24_gamma
    pix_format_bgr24_gamma
    pix_format_rgb555_gamma
    pix_format_rgb565_gamma

  PolymorphicBase = ref object of RootObj
    clear_p: proc(c: Rgba8)
    width_p: proc(): int
    height_p: proc(): int
    pixel_p: proc(x, y: int): Rgba8
    copyPixel_p: proc(x, y: int, c: Rgba8)
    blendPixel_p: proc(x, y: int, c: Rgba8, cover: uint8)
    copyHline_p: proc(x, y, len: int, c: Rgba8)
    copyVline_p: proc(x, y, len: int, c: Rgba8)
    blendHline_p: proc(x, y, len: int, c: Rgba8, cover: uint8)
    blendVline_p: proc(x, y, len: int, c: Rgba8, cover: uint8)
    blendSolidHspan_p: proc(x, y, len: int, c: Rgba8, covers: ptr uint8)
    blendSolidVspan_p: proc(x, y, len: int, c: Rgba8, covers: ptr uint8)
    copyColorHspan_p: proc(x, y, len: int, colors: ptr Rgba8)
    copyColorVspan_p: proc(x, y, len: int, colors: ptr Rgba8)
    blendColorHspan_p: proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8)
    blendColorVspan_p: proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8)

  PolymorphicAdaptor[PixFmt] = ref object of PolymorphicBase
    pixf: PixFmt
    rb: RendererBase[PixFmt]
    gamma: GammaLut8

proc clear(self: PolymorphicBase, c: Rgba8) =
  self.clear_p(c)

proc width(self: PolymorphicBase): int =
  self.width_p()

proc height(self: PolymorphicBase): int =
  self.height_p()

proc pixel(self: PolymorphicBase, x, y: int): Rgba8 =
  self.pixel_p(x, y)

proc copyPixel(self: PolymorphicBase, x, y: int, c: Rgba8) =
  self.copyPixel_p(x, y, c)

proc blendPixel(self: PolymorphicBase, x, y: int, c: Rgba8, cover: uint8) =
  self.blendPixel_p(x, y, c, cover)

proc copyHline(self: PolymorphicBase, x, y, len: int, c: Rgba8) =
  self.copyHline_p(x, y, len, c)

proc copyVline(self: PolymorphicBase, x, y, len: int, c: Rgba8) =
  self.copyVline_p(x, y, len, c)

proc blendHline(self: PolymorphicBase, x, y, len: int, c: Rgba8, cover: uint8) =
  self.blendHline_p(x, y, len, c, cover)

proc blendVline(self: PolymorphicBase, x, y, len: int, c: Rgba8, cover: uint8) =
  self.blendVline_p(x, y, len, c, cover)

proc blendSolidHspan(self: PolymorphicBase, x, y, len: int, c: Rgba8, covers: ptr uint8) =
  self.blendSolidHspan_p(x, y, len, c, covers)

proc blendSolidVspan(self: PolymorphicBase, x, y, len: int, c: Rgba8, covers: ptr uint8) =
  self.blendSolidVspan_p(x, y, len, c, covers)

proc copyColorHspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba8) =
  self.copyColorHspan_p(x, y, len, colors)

proc copyColorVspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba8) =
  self.copyColorVspan_p(x, y, len, colors)

proc blendColorHspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
  self.blendColorHspan_p(x, y, len, colors, covers, cover)

proc blendColorVspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
  self.blendColorVspan_p(x, y, len, colors, covers, cover)

proc init[PixFmt](ren: PolymorphicAdaptor[PixFmt]) =
  proc clear_i(c: Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.rb.clear(c)

  proc width_i(): int =
    ren.pixf.width()

  proc height_i(): int =
    ren.pixf.height()

  proc pixel_i(x, y: int): Rgba8 =
    when getColorT(PixFmt) is not Rgba8:
      construct(Rgba8, ren.pixf.pixel(x, y))
    else:
      ren.pixf.pixel(x, y)

  proc copyPixel_i(x, y: int, c: Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyPixel(x, y, c)

  proc blendPixel_i(x, y: int, c: Rgba8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendPixel(x, y, c, cover)

  proc copyHline_i(x, y, len: int, c: Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyHline(x, y, len, c)

  proc copyVline_i(x, y, len: int, c: Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyVline(x, y, len, c)

  proc blendHline_i(x, y, len: int, c: Rgba8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendHline(x, y, len, c, cover)

  proc blendVline_i(x, y, len: int, c: Rgba8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendVline(x, y, len, c, cover)

  proc blendSolidHspan_i(x, y, len: int, c: Rgba8, covers: ptr uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendSolidHspan(x, y, len, c, covers)

  proc blendSolidVspan_i(x, y, len: int, c: Rgba8, covers: ptr uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendSolidVspan(x, y, len, c, covers)

  proc copyColorHspan_i(x, y, len: int, colors: ptr Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])
      ren.pixf.copyColorHspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorHspan(x, y, len, colors)

  proc copyColorVspan_i(x, y, len: int, colors: ptr Rgba8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])
      ren.pixf.copyColorVspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorVspan(x, y, len, colors)

  proc blendColorHspan_i(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])
      ren.pixf.blendColorHspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorHspan(x, y, len, colors, covers, cover)

  proc blendColorVspan_i(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba8:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])
      ren.pixf.blendColorVspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorVspan(x, y, len, colors, covers, cover)

  ren.clear_p           = clear_i
  ren.width_p           = width_i
  ren.height_p          = height_i
  ren.pixel_p           = pixel_i
  ren.copyPixel_p       = copyPixel_i
  ren.blendPixel_p      = blendPixel_i
  ren.copyHline_p       = copyHline_i
  ren.copyVline_p       = copyVline_i
  ren.blendHline_p      = blendHline_i
  ren.blendVline_p      = blendVline_i
  ren.blendSolidHspan_p = blendSolidHspan_i
  ren.blendSolidVspan_p = blendSolidVspan_i
  ren.copyColorHspan_p  = copyColorHspan_i
  ren.copyColorVspan_p  = copyColorVspan_i
  ren.blendColorHspan_p = blendColorHspan_i
  ren.blendColorVspan_p = blendColorVspan_i

proc newPolymorphicAdaptorGamma[PixFmt](rbuf: var RenderingBuffer): PolymorphicBase =
  var ren   = new(PolymorphicAdaptor[PixFmt])
  ren.gamma = initGammaLut8(0.733)
  ren.pixf  = construct(PixFmt, rbuf, ren.gamma)
  ren.rb    = initRendererBase(ren.pixf)
  ren.init()
  result    = ren

proc newPolymorphicAdaptor[PixFmt](rbuf: var RenderingBuffer): PolymorphicBase =
  var ren  = new(PolymorphicAdaptor[PixFmt])
  ren.pixf = construct(PixFmt, rbuf)
  ren.rb   = initRendererBase(ren.pixf)
  ren.init()
  result   = ren

proc getPixWidth(x: PixFormat): int =
  case x
  of pix_format_rgb555: result = 2
  of pix_format_rgb565: result = 2
  of pix_format_rgb555_pre: result = 2
  of pix_format_rgb565_pre: result = 2
  of pix_format_rgb24 : result = 3
  of pix_format_bgr24 : result = 3
  of pix_format_rgb24_pre : result = 3
  of pix_format_bgr24_pre : result = 3
  of pix_format_rgba32: result = 4
  of pix_format_argb32: result = 4
  of pix_format_abgr32: result = 4
  of pix_format_bgra32: result = 4
  of pix_format_rgba32_pre: result = 4
  of pix_format_argb32_pre: result = 4
  of pix_format_abgr32_pre: result = 4
  of pix_format_bgra32_pre: result = 4
  of pix_format_rgba32_plain: result = 4
  of pix_format_argb32_plain: result = 4
  of pix_format_abgr32_plain: result = 4
  of pix_format_bgra32_plain: result = 4
  of pix_format_gray8 : result = 1
  of pix_format_gray8_pre: result = 1
  of pix_format_rgb24_gamma: result = 3
  of pix_format_bgr24_gamma: result = 3
  of pix_format_rgb555_gamma: result = 2
  of pix_format_rgb565_gamma: result = 2
  

proc pixfFactory(x: PixFormat, rbuf: var RenderingBuffer): PolymorphicBase =
  case x
  of pix_format_rgb555: result = newPolymorphicAdaptor[PixFmtRgb555](rbuf)
  of pix_format_rgb565: result = newPolymorphicAdaptor[PixFmtRgb565](rbuf)
  of pix_format_rgb555_pre: result = newPolymorphicAdaptor[PixFmtRgb555Pre](rbuf)
  of pix_format_rgb565_pre: result = newPolymorphicAdaptor[PixFmtRgb565Pre](rbuf)
  of pix_format_rgb24 : result = newPolymorphicAdaptor[PixFmtRgb24 ](rbuf)
  of pix_format_bgr24 : result = newPolymorphicAdaptor[PixFmtBgr24 ](rbuf)
  of pix_format_rgb24_pre: result = newPolymorphicAdaptor[PixFmtRgb24Pre](rbuf)
  of pix_format_bgr24_pre: result = newPolymorphicAdaptor[PixFmtBgr24Pre](rbuf)
  of pix_format_rgba32: result = newPolymorphicAdaptor[PixFmtRgba32](rbuf)
  of pix_format_argb32: result = newPolymorphicAdaptor[PixFmtArgb32](rbuf)
  of pix_format_abgr32: result = newPolymorphicAdaptor[PixFmtAbgr32](rbuf)
  of pix_format_bgra32: result = newPolymorphicAdaptor[PixFmtBgra32](rbuf)
  of pix_format_rgba32_pre: result = newPolymorphicAdaptor[PixFmtRgba32Pre](rbuf)
  of pix_format_argb32_pre: result = newPolymorphicAdaptor[PixFmtArgb32Pre](rbuf)
  of pix_format_abgr32_pre: result = newPolymorphicAdaptor[PixFmtAbgr32Pre](rbuf)
  of pix_format_bgra32_pre: result = newPolymorphicAdaptor[PixFmtBgra32Pre](rbuf)
  of pix_format_rgba32_plain: result = newPolymorphicAdaptor[PixFmtRgba32Plain](rbuf)
  of pix_format_argb32_plain: result = newPolymorphicAdaptor[PixFmtArgb32Plain](rbuf)
  of pix_format_abgr32_plain: result = newPolymorphicAdaptor[PixFmtAbgr32Plain](rbuf)
  of pix_format_bgra32_plain: result = newPolymorphicAdaptor[PixFmtBgra32Plain](rbuf)
  of pix_format_gray8 : result = newPolymorphicAdaptor[PixFmtGray8](rbuf)
  of pix_format_gray8_pre: result = newPolymorphicAdaptor[PixFmtGray8Pre](rbuf)
  of pix_format_rgb24_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgb24Gamma[GammaLut8]](rbuf)
  of pix_format_bgr24_gamma: result = newPolymorphicAdaptorGamma[PixFmtBgr24Gamma[GammaLut8]](rbuf)
  of pix_format_rgb555_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgb555Gamma[GammaLut8]](rbuf)
  of pix_format_rgb565_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgb565Gamma[GammaLut8]](rbuf)
  
  
const
  frameWidth = 400
  frameHeight = 400

type
  ValueT = uint8

proc onDraw(pixFormat: PixFormat) =
  var
    pixWidth = getPixWidth(pixFormat)
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    ren    = pixfFactory(pixFormat, rbuf)
    c      = initRgba8(initRgba(0.5, 0.7, 0.3, 0.5))

  ren.clear(initRgba8(255,255,255,255))

  for x in 0..50:
    for y in 0..50:
      ren.copyPixel(x, y, c)

  for x in 0..50:
    for y in 0..50:
      let a = ren.pixel(x, y)
      ren.copyPixel(x, y + 50, a)

  for x in 0.. <ren.width():
    for y in 100..150:
      ren.blendPixel(x, y, c, y.uint8)

  for y in 150..200:
    ren.copyHline(20, y, ren.width() - 20, initRgba8(80, 50, 70, 90))

  for x in 150..200:
    ren.copyVline(x, 20, ren.height() - 20, initRgba8(80, 50, 110, 90))

  for y in 200..250:
    ren.blendHline(20, y, ren.width() - 20, initRgba8(80, 50, 70, 90), uint8(y - 100))

  for x in 200..250:
    ren.blendVline(x, 20, ren.height() - 20, initRgba8(80, 50, 110, 90), uint8(x - 100))

  var
    spanCover: array[frameWidth - 20, uint8]
    spanColor: array[frameWidth - 20, Rgba8]

  for i in 0.. <spanCover.len:
    let x = i.float64 / spanCover.len.float64
    let c = uround(x * 255.0).uint
    spanCover[i] = uint8(c)
    spanColor[i] = initRgba8(c, c, c, c)

  for y in 250..300:
    ren.blendSolidHSpan(20, y, ren.width() - 20, initRgba8(120, 50, 150, 90), spanCover[0].addr)

  for x in 250..300:
    ren.blendSolidVSpan(x, 20, ren.height() - 20, initRgba8(80, 150, 110, 90), spanCover[0].addr)

  for y in 300..350:
    ren.copyColorHSpan(30, y, ren.width() - 30, spanColor[0].addr)

  for x in 300..350:
    ren.copyColorVSpan(x, 30, ren.height() - 30, spanColor[0].addr)

  for y in 350.. <400:
    ren.blendColorHSpan(40, y, ren.width() - 40, spanColor[0].addr, spanCover[0].addr, uint8(y - 350))

  for x in 350.. <400:
    ren.blendColorVSpan(x, 40, ren.height() - 40, spanColor[0].addr, spanCover[0].addr, uint8(x - 350))

  var
    target = newString(frameWidth * frameHeight * 3)
    rbuf2  = initRenderingBuffer(cast[ptr uint8](target[0].addr), frameWidth, frameHeight, -frameWidth * 3)

  case pixFormat
  of pix_format_rgb555: colorConv(rbuf2, rbuf, color_conv_rgb555_to_rgb24)
  of pix_format_rgb565: colorConv(rbuf2, rbuf, color_conv_rgb565_to_rgb24)
  of pix_format_rgb555_pre: colorConv(rbuf2, rbuf, color_conv_rgb555_to_rgb24)
  of pix_format_rgb565_pre: colorConv(rbuf2, rbuf, color_conv_rgb565_to_rgb24)
  of pix_format_rgb24 : colorConv(rbuf2, rbuf, color_conv_rgb24_to_rgb24)
  of pix_format_bgr24 : colorConv(rbuf2, rbuf, color_conv_bgr24_to_rgb24)
  of pix_format_rgb24_pre : colorConv(rbuf2, rbuf, color_conv_rgb24_to_rgb24)
  of pix_format_bgr24_pre : colorConv(rbuf2, rbuf, color_conv_bgr24_to_rgb24)
  of pix_format_rgba32: colorConv(rbuf2, rbuf, color_conv_rgba32_to_rgb24)
  of pix_format_argb32: colorConv(rbuf2, rbuf, color_conv_argb32_to_rgb24)
  of pix_format_abgr32: colorConv(rbuf2, rbuf, color_conv_abgr32_to_rgb24)
  of pix_format_bgra32: colorConv(rbuf2, rbuf, color_conv_bgra32_to_rgb24)
  of pix_format_rgba32_pre: colorConv(rbuf2, rbuf, color_conv_rgba32_to_rgb24)
  of pix_format_argb32_pre: colorConv(rbuf2, rbuf, color_conv_argb32_to_rgb24)
  of pix_format_abgr32_pre: colorConv(rbuf2, rbuf, color_conv_abgr32_to_rgb24)
  of pix_format_bgra32_pre: colorConv(rbuf2, rbuf, color_conv_bgra32_to_rgb24)
  of pix_format_rgba32_plain: colorConv(rbuf2, rbuf, color_conv_rgba32_to_rgb24)
  of pix_format_argb32_plain: colorConv(rbuf2, rbuf, color_conv_argb32_to_rgb24)
  of pix_format_abgr32_plain: colorConv(rbuf2, rbuf, color_conv_abgr32_to_rgb24)
  of pix_format_bgra32_plain: colorConv(rbuf2, rbuf, color_conv_bgra32_to_rgb24)
  of pix_format_gray8 : colorConv(rbuf2, rbuf, color_conv_gray8_to_rgb24)
  of pix_format_gray8_pre: colorConv(rbuf2, rbuf, color_conv_gray8_to_rgb24)
  of pix_format_rgb24_gamma: colorConv(rbuf2, rbuf, color_conv_rgb24_to_rgb24)
  of pix_format_bgr24_gamma: colorConv(rbuf2, rbuf, color_conv_bgr24_to_rgb24)
  of pix_format_rgb555_gamma: colorConv(rbuf2, rbuf, color_conv_rgb555_to_rgb24)
  of pix_format_rgb565_gamma: colorConv(rbuf2, rbuf, color_conv_rgb565_to_rgb24)
  
  let name = $pixformat & ".bmp"
  echo name
  saveBMP24(name, target, frameWidth, frameHeight)

for i in PixFormat:
  onDraw(PixFormat(i))