import agg/[basics, rendering_buffer, rasterizer_scanline_aa, rasterizer_outline,
  scanline_p, path_storage, renderer_scanline, pixfmt_rgb, pixfmt_rgb_packed,
  pixfmt_rgba, color_rgba, color_conv_rgb16, color_conv, renderer_base, pixfmt_gray,
  color_gray, gamma_lut]

import nimBMP, blend_type

type
  ValueT = getValueT(Rgba16)

  PixFormat = enum
    pix_format_rgbAAA
    pix_format_bgrAAA
    pix_format_rgbBBA
    pix_format_bgrABB
    pix_format_rgbAAA_pre
    pix_format_bgrAAA_pre
    pix_format_rgbBBA_pre
    pix_format_bgrABB_pre
    pix_format_gray16
    pix_format_gray16_pre
    pix_format_rgb48
    pix_format_bgr48
    pix_format_rgb48_pre
    pix_format_bgr48_pre
    pix_format_rgba64
    pix_format_argb64
    pix_format_abgr64
    pix_format_bgra64
    pix_format_rgba64_pre
    pix_format_argb64_pre
    pix_format_abgr64_pre
    pix_format_bgra64_pre
    pix_format_rgb48_gamma
    pix_format_bgr48_gamma
    pix_format_rgbAAA_gamma
    pix_format_bgrAAA_gamma
    pix_format_rgbBBA_gamma
    pix_format_bgrABB_gamma
    pix_format_custom_a64
    pix_format_custom_b64
    pix_format_custom_c64
    pix_format_custom_d64
    pix_format_custom_e64
    pix_format_custom_f64
    pix_format_custom_g64
    pix_format_custom_h64
    pix_format_custom_i64
    pix_format_custom_j64

  PolymorphicBase = ref object of RootObj
    clear: proc(c: Rgba16)
    width: proc(): int
    height: proc(): int
    pixel: proc(x, y: int): Rgba16
    pixPtr: proc(x, y: int): ptr ValueT
    copyPixel: proc(x, y: int, c: Rgba16)
    blendPixel: proc(x, y: int, c: Rgba16, cover: uint8)
    copyHline: proc(x, y, len: int, c: Rgba16)
    copyVline: proc(x, y, len: int, c: Rgba16)
    blendHline: proc(x, y, len: int, c: Rgba16, cover: uint8)
    blendVline: proc(x, y, len: int, c: Rgba16, cover: uint8)
    blendSolidHspan: proc(x, y, len: int, c: Rgba16, covers: ptr uint8)
    blendSolidVspan: proc(x, y, len: int, c: Rgba16, covers: ptr uint8)
    copyColorHspan: proc(x, y, len: int, colors: ptr Rgba16)
    copyColorVspan: proc(x, y, len: int, colors: ptr Rgba16)
    blendColorHspan: proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8)
    blendColorVspan: proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8)

  PolymorphicAdaptor[PixFmt] = ref object of PolymorphicBase
    pixf: PixFmt
    rb: RendererBase[PixFmt]
    gamma: GammaLut16

proc init[PixFmt](ren: PolymorphicAdaptor[PixFmt]) =
  type ColorT = getColorT(PixFmt)

  ren.clear = proc(c: Rgba16) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.rb.clear(c)

  ren.width = proc(): int =
    ren.pixf.width()

  ren.height = proc(): int =
    ren.pixf.height()

  ren.pixel = proc(x, y: int): Rgba16 =
    when ColorT is not Rgba16:
      construct(Rgba16, ren.pixf.pixel(x, y))
    else:
      ren.pixf.pixel(x, y)

  ren.pixPtr = proc(x, y: int): ptr ValueT =
    ren.pixf.pixPtr(x, y)

  ren.copyPixel = proc(x, y: int, c: Rgba16) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.copyPixel(x, y, c)

  ren.blendPixel = proc(x, y: int, c: Rgba16, cover: uint8) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.blendPixel(x, y, c, cover)

  ren.copyHline = proc(x, y, len: int, c: Rgba16) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.copyHline(x, y, len, c)

  ren.copyVline = proc(x, y, len: int, c: Rgba16) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.copyVline(x, y, len, c)

  ren.blendHline = proc(x, y, len: int, c: Rgba16, cover: uint8) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.blendHline(x, y, len, c, cover)

  ren.blendVline = proc(x, y, len: int, c: Rgba16, cover: uint8) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.blendVline(x, y, len, c, cover)

  ren.blendSolidHspan = proc(x, y, len: int, c: Rgba16, covers: ptr uint8) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.blendSolidHspan(x, y, len, c, covers)

  ren.blendSolidVspan = proc(x, y, len: int, c: Rgba16, covers: ptr uint8) =
    when ColorT is not Rgba16:
      var c = construct(ColorT, c)
    ren.pixf.blendSolidVspan(x, y, len, c, covers)

  ren.copyColorHspan = proc(x, y, len: int, colors: ptr Rgba16) =
    when ColorT is not Rgba16:
      var c = createU(ColorT, len)
      for i in 0..<len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.copyColorHspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorHspan(x, y, len, colors)

  ren.copyColorVspan = proc(x, y, len: int, colors: ptr Rgba16) =
    when ColorT is not Rgba16:
      var c = createU(ColorT, len)
      for i in 0..<len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.copyColorVspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorVspan(x, y, len, colors)

  ren.blendColorHspan = proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
    when ColorT is not Rgba16:
      var c = createU(ColorT, len)
      for i in 0..<len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.blendColorHspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorHspan(x, y, len, colors, covers, cover)

  ren.blendColorVspan = proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
    when ColorT is not Rgba16:
      var c = createU(ColorT, len)
      for i in 0..<len:
        c[i] = construct(ColorT, colors[i])
      ren.pixf.blendColorVspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorVspan(x, y, len, colors, covers, cover)

proc newPolymorphicAdaptorGamma[PixFmt](rbuf: var RenderingBuffer16): PolymorphicBase =
  var ren   = new(PolymorphicAdaptor[PixFmt])
  ren.gamma = initGammaLut16(0.733)
  ren.pixf  = construct(PixFmt, rbuf, ren.gamma)
  ren.rb    = initRendererBase(ren.pixf)
  ren.init()
  result    = ren

proc newPolymorphicAdaptor[PixFmt](rbuf: var RenderingBuffer16): PolymorphicBase =
  var ren  = new(PolymorphicAdaptor[PixFmt])
  ren.pixf = construct(PixFmt, rbuf)
  ren.rb   = initRendererBase(ren.pixf)
  ren.init()
  result   = ren

proc getPixElem(x: PixFormat): int =
  case x
  of pix_format_rgbAAA: result = 2
  of pix_format_bgrAAA: result = 2
  of pix_format_rgbBBA: result = 2
  of pix_format_bgrABB: result = 2
  of pix_format_rgbAAA_pre: result = 2
  of pix_format_bgrAAA_pre: result = 2
  of pix_format_rgbBBA_pre: result = 2
  of pix_format_bgrABB_pre: result = 2
  of pix_format_gray16 : result = 1
  of pix_format_gray16_pre: result = 1
  of pix_format_rgb48: result = 3
  of pix_format_bgr48: result = 3
  of pix_format_rgb48_pre: result = 3
  of pix_format_bgr48_pre: result = 3
  of pix_format_rgba64: result = 4
  of pix_format_argb64: result = 4
  of pix_format_abgr64: result = 4
  of pix_format_bgra64: result = 4
  of pix_format_rgba64_pre: result = 4
  of pix_format_argb64_pre: result = 4
  of pix_format_abgr64_pre: result = 4
  of pix_format_bgra64_pre: result = 4
  of pix_format_rgb48_gamma: result = 3
  of pix_format_bgr48_gamma: result = 3
  of pix_format_rgbAAA_gamma: result = 2
  of pix_format_bgrAAA_gamma: result = 2
  of pix_format_rgbBBA_gamma: result = 2
  of pix_format_bgrABB_gamma: result = 2
  of pix_format_custom_a64..pix_format_custom_j64: result = 4

proc pixfFactory(x: PixFormat, rbuf: var RenderingBuffer16): PolymorphicBase =
  case x
  of pix_format_rgbAAA: result = newPolymorphicAdaptor[PixFmtRgbAAA](rbuf)
  of pix_format_bgrAAA: result = newPolymorphicAdaptor[PixFmtBgrAAA](rbuf)
  of pix_format_rgbBBA: result = newPolymorphicAdaptor[PixFmtRgbBBA](rbuf)
  of pix_format_bgrABB: result = newPolymorphicAdaptor[PixFmtBgrABB](rbuf)
  of pix_format_rgbAAA_pre: result = newPolymorphicAdaptor[PixFmtRgbAAA](rbuf)
  of pix_format_bgrAAA_pre: result = newPolymorphicAdaptor[PixFmtBgrAAA](rbuf)
  of pix_format_rgbBBA_pre: result = newPolymorphicAdaptor[PixFmtRgbBBA](rbuf)
  of pix_format_bgrABB_pre: result = newPolymorphicAdaptor[PixFmtBgrABB](rbuf)
  of pix_format_gray16 : result = newPolymorphicAdaptor[PixFmtGray16](rbuf)
  of pix_format_gray16_pre: result = newPolymorphicAdaptor[PixFmtGray16Pre](rbuf)
  of pix_format_rgb48: result = newPolymorphicAdaptor[PixFmtRgb48](rbuf)
  of pix_format_bgr48: result = newPolymorphicAdaptor[PixFmtBgr48](rbuf)
  of pix_format_rgb48_pre: result = newPolymorphicAdaptor[PixFmtRgb48Pre](rbuf)
  of pix_format_bgr48_pre: result = newPolymorphicAdaptor[PixFmtBgr48Pre](rbuf)
  of pix_format_rgba64: result = newPolymorphicAdaptor[PixFmtRgba64](rbuf)
  of pix_format_argb64: result = newPolymorphicAdaptor[PixFmtArgb64](rbuf)
  of pix_format_abgr64: result = newPolymorphicAdaptor[PixFmtAbgr64](rbuf)
  of pix_format_bgra64: result = newPolymorphicAdaptor[PixFmtBgra64](rbuf)
  of pix_format_rgba64_pre: result = newPolymorphicAdaptor[PixFmtRgba64Pre](rbuf)
  of pix_format_argb64_pre: result = newPolymorphicAdaptor[PixFmtArgb64Pre](rbuf)
  of pix_format_abgr64_pre: result = newPolymorphicAdaptor[PixFmtAbgr64Pre](rbuf)
  of pix_format_bgra64_pre: result = newPolymorphicAdaptor[PixFmtBgra64Pre](rbuf)
  of pix_format_rgb48_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgb48Gamma[GammaLut16]](rbuf)
  of pix_format_bgr48_gamma: result = newPolymorphicAdaptorGamma[PixFmtBgr48Gamma[GammaLut16]](rbuf)
  of pix_format_rgbAAA_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgbAAAGamma[GammaLut16]](rbuf)
  of pix_format_bgrAAA_gamma: result = newPolymorphicAdaptorGamma[PixFmtBgrAAAGamma[GammaLut16]](rbuf)
  of pix_format_rgbBBA_gamma: result = newPolymorphicAdaptorGamma[PixFmtRgbBBAGamma[GammaLut16]](rbuf)
  of pix_format_bgrABB_gamma: result = newPolymorphicAdaptorGamma[PixFmtBgrABBGamma[GammaLut16]](rbuf)
  of pix_format_custom_a64: result = newPolymorphicAdaptor[CustomBlendA64](rbuf)
  of pix_format_custom_b64: result = newPolymorphicAdaptor[CustomBlendB64](rbuf)
  of pix_format_custom_c64: result = newPolymorphicAdaptor[CustomBlendC64](rbuf)
  of pix_format_custom_d64: result = newPolymorphicAdaptor[CustomBlendD64](rbuf)
  of pix_format_custom_e64: result = newPolymorphicAdaptor[CustomBlendE64](rbuf)
  of pix_format_custom_f64: result = newPolymorphicAdaptor[CustomBlendF64](rbuf)
  of pix_format_custom_g64: result = newPolymorphicAdaptor[CustomBlendG64](rbuf)
  of pix_format_custom_h64: result = newPolymorphicAdaptor[CustomBlendH64](rbuf)
  of pix_format_custom_i64: result = newPolymorphicAdaptor[CustomBlendI64](rbuf)
  of pix_format_custom_j64: result = newPolymorphicAdaptor[CustomBlendJ64](rbuf)


const
  frameWidth = 400
  frameHeight = 400

proc onDraw(pixFormat: PixFormat) =
  var
    pixElem = getPixElem(pixFormat)
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixElem)
    rbuf   = initRenderingBuffer(buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixElem)
    ren    = pixfFactory(pixFormat, rbuf)
    c      = initRgba16(initRgba(0.5, 0.7, 0.3, 0.5))

  let cc = initRgba16(initRgba(1,1,1))
  ren.clear(cc)

  for x in 0..50:
    for y in 0..50:
      ren.copyPixel(x, y, c)

  for x in 0..50:
    for y in 0..50:
      let a = ren.pixel(x, y)
      ren.copyPixel(x, y + 50, a)

  for x in 0..<ren.width():
    for y in 100..150:
      ren.blendPixel(x, y, c, y.uint8)

  for y in 150..200:
    ren.copyHline(20, y, ren.width() - 20, initRgba16(initRgba(0.3, 0.4, 0.7, 0.8)))

  for x in 150..200:
    ren.copyVline(x, 20, ren.height() - 20, initRgba16(initRgba(0.7, 0.4, 0.3, 0.8)))

  for y in 200..250:
    ren.blendHline(20, y, ren.width() - 20, initRgba16(initRgba(0.3, 0.8, 0.7, 0.4)), uint8(y - 100))

  for x in 200..250:
    ren.blendVline(x, 20, ren.height() - 20, initRgba16(initRgba(0.4, 0.7, 0.3, 0.8)), uint8(x - 100))

  var
    spanCover: array[frameWidth - 20, uint8]
    spanColor: array[frameWidth - 20, Rgba16]

  for i in 0..<spanCover.len:
    let x = i.float64 / spanCover.len.float64
    let c = uround(x * 65535.0).uint
    spanCover[i] = uint8(i and 0xFF)
    spanColor[i] = initRgba16(c, c, c, c)

  for y in 250..300:
    ren.blendSolidHSpan(20, y, ren.width() - 20, initRgba16(initRgba(0.7, 0.4, 0.3, 0.8)), spanCover[0].addr)

  for x in 250..300:
    ren.blendSolidVSpan(x, 20, ren.height() - 20, initRgba16(initRgba(0.4, 0.7, 0.3, 0.8)), spanCover[0].addr)

  for y in 300..350:
    ren.copyColorHSpan(30, y, ren.width() - 30, spanColor[0].addr)

  for x in 300..350:
    ren.copyColorVSpan(x, 30, ren.height() - 30, spanColor[0].addr)

  for y in 350..<400:
    ren.blendColorHSpan(40, y, ren.width() - 40, spanColor[0].addr, spanCover[0].addr, uint8(y - 350))

  for x in 350..<400:
    ren.blendColorVSpan(x, 40, ren.height() - 40, spanColor[0].addr, spanCover[0].addr, uint8(x - 350))

  let h = ren.height() div 2
  for i in 0..<h:
    var p = ren.pixPtr(i, i)
    zeroMem(p, pixElem * sizeof(ValueT))
    inc(p, pixElem)

  var
    target = newString(frameWidth * frameHeight * 3)
    rbuf2  = initRenderingBuffer(cast[ptr uint8](target[0].addr), frameWidth, frameHeight, -frameWidth * 3)

  case pixFormat
  of pix_format_rgbAAA: colorConv(rbuf2, rbuf, color_conv_rgbAAA_to_rgb24)
  of pix_format_bgrAAA: colorConv(rbuf2, rbuf, color_conv_bgrAAA_to_rgb24)
  of pix_format_rgbBBA: colorConv(rbuf2, rbuf, color_conv_rgbBBA_to_rgb24)
  of pix_format_bgrABB: colorConv(rbuf2, rbuf, color_conv_bgrABB_to_rgb24)
  of pix_format_rgbAAA_pre: colorConv(rbuf2, rbuf, color_conv_rgbAAA_to_rgb24)
  of pix_format_bgrAAA_pre: colorConv(rbuf2, rbuf, color_conv_bgrAAA_to_rgb24)
  of pix_format_rgbBBA_pre: colorConv(rbuf2, rbuf, color_conv_rgbBBA_to_rgb24)
  of pix_format_bgrABB_pre: colorConv(rbuf2, rbuf, color_conv_bgrABB_to_rgb24)
  of pix_format_gray16 : colorConv(rbuf2, rbuf, color_conv_gray16_to_rgb24)
  of pix_format_gray16_pre: colorConv(rbuf2, rbuf, color_conv_gray16_to_rgb24)
  of pix_format_rgb48: colorConv(rbuf2, rbuf, color_conv_rgb48_to_rgb24)
  of pix_format_bgr48: colorConv(rbuf2, rbuf, color_conv_bgr48_to_rgb24)
  of pix_format_rgb48_pre: colorConv(rbuf2, rbuf, color_conv_rgb48_to_rgb24)
  of pix_format_bgr48_pre: colorConv(rbuf2, rbuf, color_conv_bgr48_to_rgb24)
  of pix_format_rgba64: colorConv(rbuf2, rbuf, color_conv_rgba64_to_rgb24)
  of pix_format_argb64: colorConv(rbuf2, rbuf, color_conv_argb64_to_rgb24)
  of pix_format_abgr64: colorConv(rbuf2, rbuf, color_conv_abgr64_to_rgb24)
  of pix_format_bgra64: colorConv(rbuf2, rbuf, color_conv_bgra64_to_rgb24)
  of pix_format_rgba64_pre: colorConv(rbuf2, rbuf, color_conv_rgba64_to_rgb24)
  of pix_format_argb64_pre: colorConv(rbuf2, rbuf, color_conv_argb64_to_rgb24)
  of pix_format_abgr64_pre: colorConv(rbuf2, rbuf, color_conv_abgr64_to_rgb24)
  of pix_format_bgra64_pre: colorConv(rbuf2, rbuf, color_conv_bgra64_to_rgb24)
  of pix_format_rgb48_gamma: colorConv(rbuf2, rbuf, color_conv_rgb48_to_rgb24)
  of pix_format_bgr48_gamma: colorConv(rbuf2, rbuf, color_conv_bgr48_to_rgb24)
  of pix_format_rgbAAA_gamma: colorConv(rbuf2, rbuf, color_conv_rgbAAA_to_rgb24)
  of pix_format_bgrAAA_gamma: colorConv(rbuf2, rbuf, color_conv_bgrAAA_to_rgb24)
  of pix_format_rgbBBA_gamma: colorConv(rbuf2, rbuf, color_conv_rgbBBA_to_rgb24)
  of pix_format_bgrABB_gamma: colorConv(rbuf2, rbuf, color_conv_bgrABB_to_rgb24)
  of pix_format_custom_a64..pix_format_custom_j64: colorConv(rbuf2, rbuf, color_conv_rgba64_to_rgb24)

  let name = $pixformat & ".bmp"
  echo name
  saveBMP24(name, target, frameWidth, frameHeight)

for i in PixFormat:
  onDraw(PixFormat(i))