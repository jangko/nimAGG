import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_scanline_p, agg_path_storage, agg_renderer_scanline, agg_pixfmt_rgb, agg_pixfmt_rgb_packed
import agg_pixfmt_rgba, agg_color_rgba, agg_color_conv_rgb16, agg_color_conv, blend_type
import nimBMP, agg_renderer_base, agg_pixfmt_gray, agg_color_gray, agg_gamma_lut

type
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
    clear_p: proc(c: Rgba16)
    width_p: proc(): int
    height_p: proc(): int
    pixel_p: proc(x, y: int): Rgba16
    copyPixel_p: proc(x, y: int, c: Rgba16)
    blendPixel_p: proc(x, y: int, c: Rgba16, cover: uint8)
    copyHline_p: proc(x, y, len: int, c: Rgba16)
    copyVline_p: proc(x, y, len: int, c: Rgba16)
    blendHline_p: proc(x, y, len: int, c: Rgba16, cover: uint8)
    blendVline_p: proc(x, y, len: int, c: Rgba16, cover: uint8)
    blendSolidHspan_p: proc(x, y, len: int, c: Rgba16, covers: ptr uint8)
    blendSolidVspan_p: proc(x, y, len: int, c: Rgba16, covers: ptr uint8)
    copyColorHspan_p: proc(x, y, len: int, colors: ptr Rgba16)
    copyColorVspan_p: proc(x, y, len: int, colors: ptr Rgba16)
    blendColorHspan_p: proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8)
    blendColorVspan_p: proc(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8)
      
  PolymorphicAdaptor[PixFmt] = ref object of PolymorphicBase
    pixf: PixFmt
    rb: RendererBase[PixFmt]
    gamma: GammaLut16
    
proc clear(self: PolymorphicBase, c: Rgba16) =
  self.clear_p(c)
  
proc width(self: PolymorphicBase): int =
  self.width_p()
  
proc height(self: PolymorphicBase): int =
  self.height_p()
  
proc pixel(self: PolymorphicBase, x, y: int): Rgba16 =
  self.pixel_p(x, y)
  
proc copyPixel(self: PolymorphicBase, x, y: int, c: Rgba16) =
  self.copyPixel_p(x, y, c)
  
proc blendPixel(self: PolymorphicBase, x, y: int, c: Rgba16, cover: uint8) =
  self.blendPixel_p(x, y, c, cover)
  
proc copyHline(self: PolymorphicBase, x, y, len: int, c: Rgba16) =
  self.copyHline_p(x, y, len, c)
  
proc copyVline(self: PolymorphicBase, x, y, len: int, c: Rgba16) =
  self.copyVline_p(x, y, len, c)
  
proc blendHline(self: PolymorphicBase, x, y, len: int, c: Rgba16, cover: uint8) =
  self.blendHline_p(x, y, len, c, cover)
  
proc blendVline(self: PolymorphicBase, x, y, len: int, c: Rgba16, cover: uint8) =
  self.blendVline_p(x, y, len, c, cover)
  
proc blendSolidHspan(self: PolymorphicBase, x, y, len: int, c: Rgba16, covers: ptr uint8) =
  self.blendSolidHspan_p(x, y, len, c, covers)

proc blendSolidVspan(self: PolymorphicBase, x, y, len: int, c: Rgba16, covers: ptr uint8) =
  self.blendSolidVspan_p(x, y, len, c, covers)
  
proc copyColorHspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba16) =
  self.copyColorHspan_p(x, y, len, colors)

proc copyColorVspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba16) =
  self.copyColorVspan_p(x, y, len, colors)
  
proc blendColorHspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
  self.blendColorHspan_p(x, y, len, colors, covers, cover)
  
proc blendColorVspan(self: PolymorphicBase, x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
  self.blendColorVspan_p(x, y, len, colors, covers, cover)
  
proc init[PixFmt](ren: PolymorphicAdaptor[PixFmt]) = 
  proc clear_i(c: Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.rb.clear(c)
    
  proc width_i(): int =
    ren.pixf.width()
    
  proc height_i(): int =
    ren.pixf.height()
    
  proc pixel_i(x, y: int): Rgba16 =
    when getColorT(PixFmt) is not Rgba16:
      construct(Rgba16, ren.pixf.pixel(x, y))
    else:
      ren.pixf.pixel(x, y)
    
  proc copyPixel_i(x, y: int, c: Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyPixel(x, y, c)
    
  proc blendPixel_i(x, y: int, c: Rgba16, cover: uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendPixel(x, y, c, cover)
    
  proc copyHline_i(x, y, len: int, c: Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyHline(x, y, len, c)
    
  proc copyVline_i(x, y, len: int, c: Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.copyVline(x, y, len, c)
    
  proc blendHline_i(x, y, len: int, c: Rgba16, cover: uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendHline(x, y, len, c, cover)
    
  proc blendVline_i(x, y, len: int, c: Rgba16, cover: uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendVline(x, y, len, c, cover)
    
  proc blendSolidHspan_i(x, y, len: int, c: Rgba16, covers: ptr uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendSolidHspan(x, y, len, c, covers)
    
  proc blendSolidVspan_i(x, y, len: int, c: Rgba16, covers: ptr uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = construct(getColorT(PixFmt), c)
    ren.pixf.blendSolidVspan(x, y, len, c, covers)
    
  proc copyColorHspan_i(x, y, len: int, colors: ptr Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])        
      ren.pixf.copyColorHspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorHspan(x, y, len, colors)
    
  proc copyColorVspan_i(x, y, len: int, colors: ptr Rgba16) =
    when getColorT(PixFmt) is not Rgba16:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])        
      ren.pixf.copyColorVspan(x, y, len, c)
      dealloc(c)
    else:
      ren.pixf.copyColorVspan(x, y, len, colors)
    
  proc blendColorHspan_i(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba16:
      var c = createU(getColorT(PixFmt), len)
      for i in 0.. <len:
        c[i] = construct(getColorT(PixFmt), colors[i])        
      ren.pixf.blendColorHspan(x, y, len, c, covers, cover)
      dealloc(c)
    else:
      ren.pixf.blendColorHspan(x, y, len, colors, covers, cover)
    
  proc blendColorVspan_i(x, y, len: int, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) =
    when getColorT(PixFmt) is not Rgba16:
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
  
proc getPixWidth(x: PixFormat): int =
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
  
type
  ValueT = uint16
  
proc onDraw(pixFormat: PixFormat) =
  var
    pixWidth = getPixWidth(pixFormat)
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
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
      
  for x in 0.. <ren.width():
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
    
  for i in 0.. <spanCover.len:
    let x = i.float64 / spanCover.len.float64
    let c = uround(x * 65535.0).uint
    spanCover[i] = uint8(i)
    spanColor[i] = initRgba16(c, c, c, c)
    
  for y in 250..300:
    ren.blendSolidHSpan(20, y, ren.width() - 20, initRgba16(initRgba(0.7, 0.4, 0.3, 0.8)), spanCover[0].addr)
    
  for x in 250..300:
    ren.blendSolidVSpan(x, 20, ren.height() - 20, initRgba16(initRgba(0.4, 0.7, 0.3, 0.8)), spanCover[0].addr)
  
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