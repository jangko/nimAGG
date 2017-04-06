import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_scanline_p, agg_path_storage, agg_renderer_scanline, agg_pixfmt_rgb, agg_pixfmt_rgb_packed
import agg_pixfmt_rgba, agg_color_rgba, agg_color_conv_rgb8, agg_color_conv, blend_type
import nimBMP, agg_renderer_base, agg_pixfmt_gray, agg_color_gray, agg_gamma_lut

type
  ValueT = getValueT(Rgba8)

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
    pix_format_custom_a32
    pix_format_custom_b32
    pix_format_custom_c32
    pix_format_custom_d32
    pix_format_custom_e32
    pix_format_custom_f32
    pix_format_custom_g32
    pix_format_custom_h32
    pix_format_custom_i32
    pix_format_custom_j32
    pix_format_custom_k32
    pix_format_custom_l32
    pix_format_custom_m32

  PolymorphicBase = ref object of RootObj
    clear: proc(c: Rgba8)
    width: proc(): int
    height: proc(): int
    pixel: proc(x, y: int): Rgba8
    pixPtr: proc(x, y: int): ptr ValueT
    copyPixel: proc(x, y: int, c: Rgba8)
    blendPixel: proc(x, y: int, c: Rgba8, cover: uint8)
    copyHline: proc(x, y, len: int, c: Rgba8)
    copyVline: proc(x, y, len: int, c: Rgba8)
    blendHline: proc(x, y, len: int, c: Rgba8, cover: uint8)
    blendVline: proc(x, y, len: int, c: Rgba8, cover: uint8)
    blendSolidHspan: proc(x, y, len: int, c: Rgba8, covers: ptr uint8)
    blendSolidVspan: proc(x, y, len: int, c: Rgba8, covers: ptr uint8)
    copyColorHspan: proc(x, y, len: int, colors: ptr Rgba8)
    copyColorVspan: proc(x, y, len: int, colors: ptr Rgba8)
    blendColorHspan: proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8)
    blendColorVspan: proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8)

  PolymorphicAdaptor[PixFmt] = ref object of PolymorphicBase
    pixf: PixFmt
    rb: RendererBase[PixFmt]
    gamma: GammaLut8

proc init[PixFmt](ren: PolymorphicAdaptor[PixFmt]) =
  type ColorT = getColorT(PixFmt)

  ren.clear = proc(c: Rgba8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.rb.clear(c)

  ren.width = proc(): int =
    ren.pixf.width()

  ren.height = proc(): int =
    ren.pixf.height()

  ren.pixel = proc(x, y: int): Rgba8 =
    when ColorT is not Rgba8:
      construct(Rgba8, ren.pixf.pixel(x, y))
    else:
      ren.pixf.pixel(x, y)

  ren.pixPtr = proc(x, y: int): ptr ValueT =
    ren.pixf.pixPtr(x, y)

  ren.copyPixel = proc(x, y: int, c: Rgba8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.copyPixel(x, y, c)

  ren.blendPixel = proc(x, y: int, c: Rgba8, cover: uint8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.blendPixel(x, y, c, cover)

  ren.copyHline = proc(x, y, len: int, c: Rgba8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.copyHline(x, y, len, c)

  ren.copyVline = proc(x, y, len: int, c: Rgba8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.copyVline(x, y, len, c)

  ren.blendHline = proc(x, y, len: int, c: Rgba8, cover: uint8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.blendHline(x, y, len, c, cover)

  ren.blendVline = proc(x, y, len: int, c: Rgba8, cover: uint8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.blendVline(x, y, len, c, cover)

  ren.blendSolidHspan = proc(x, y, len: int, c: Rgba8, covers: ptr uint8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.blendSolidHspan(x, y, len, c, covers)

  ren.blendSolidVspan = proc(x, y, len: int, c: Rgba8, covers: ptr uint8) =
    when ColorT is not Rgba8:
      var c = construct(ColorT, c)
    ren.pixf.blendSolidVspan(x, y, len, c, covers)

  ren.copyColorHspan = proc(x, y, len: int, colors: ptr Rgba8) =
    when ColorT is not Rgba8:
      var c = allocU(ColorT, len)
      for i in 0.. <len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.copyColorHspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorHspan(x, y, len, colors)

  ren.copyColorVspan = proc(x, y, len: int, colors: ptr Rgba8) =
    when ColorT is not Rgba8:
      var c = allocU(ColorT, len)
      for i in 0.. <len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.copyColorVspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorVspan(x, y, len, colors)

  ren.blendColorHspan = proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
    when ColorT is not Rgba8:
      var c = allocU(ColorT, len)
      for i in 0.. <len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.blendColorHspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorHspan(x, y, len, colors, covers, cover)

  ren.blendColorVspan = proc(x, y, len: int, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) =
    when ColorT is not Rgba8:
      var c = allocU(ColorT, len)
      for i in 0.. <len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.blendColorVspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorVspan(x, y, len, colors, covers, cover)

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

proc getPixElem(x: PixFormat): int =
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
  of pix_format_custom_a32..pix_format_custom_m32: result = 4

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
  of pix_format_custom_a32: result = newPolymorphicAdaptor[CustomBlendA32](rbuf)
  of pix_format_custom_b32: result = newPolymorphicAdaptor[CustomBlendB32](rbuf)
  of pix_format_custom_c32: result = newPolymorphicAdaptor[CustomBlendC32](rbuf)
  of pix_format_custom_d32: result = newPolymorphicAdaptor[CustomBlendD32](rbuf)
  of pix_format_custom_e32: result = newPolymorphicAdaptor[CustomBlendE32](rbuf)
  of pix_format_custom_f32: result = newPolymorphicAdaptor[CustomBlendF32](rbuf)
  of pix_format_custom_g32: result = newPolymorphicAdaptor[CustomBlendG32](rbuf)
  of pix_format_custom_h32: result = newPolymorphicAdaptor[CustomBlendH32](rbuf)
  of pix_format_custom_i32: result = newPolymorphicAdaptor[CustomBlendI32](rbuf)
  of pix_format_custom_j32: result = newPolymorphicAdaptor[CustomBlendJ32](rbuf)
  of pix_format_custom_k32: result = newPolymorphicAdaptor[CustomBlendK32](rbuf)
  of pix_format_custom_l32: result = newPolymorphicAdaptor[CustomBlendL32](rbuf)
  of pix_format_custom_m32: result = newPolymorphicAdaptor[CustomBlendM32](rbuf)

const
  frameWidth = 400
  frameHeight = 400

proc onDraw(pixFormat: PixFormat) =
  var
    pixElem = getPixElem(pixFormat)
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixElem)
    rbuf   = initRenderingBuffer(buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixElem)
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

  let h = ren.height() div 2
  for i in 0.. <h:
    var p = ren.pixPtr(i, i)
    setMem(p, 0, pixElem * sizeof(ValueT))
    inc(p, pixElem)

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
  of pix_format_custom_a32..pix_format_custom_m32: colorConv(rbuf2, rbuf, color_conv_rgba32_to_rgb24)

  let name = $pixformat & ".bmp"
  echo name
  saveBMP24(name, target, frameWidth, frameHeight)

for i in PixFormat:
  onDraw(PixFormat(i))
