import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_scanline_p, agg_path_storage, agg_renderer_scanline, agg_pixfmt_rgb, agg_pixfmt_rgb_packed
import agg_pixfmt_rgba, agg_color_rgba, agg_color_conv_rgb8, agg_color_conv_rgb16, agg_color_conv
import nimBMP, agg_renderer_base

type
  PixFormat = enum
    pix_format_rgb555
    pix_format_rgb565
    pix_format_rgb24 
    pix_format_bgr24 
    pix_format_rgba32
    pix_format_argb32
    pix_format_abgr32
    pix_format_bgra32
    
proc getPixWidth(x: PixFormat): int =
  case x
  of pix_format_rgb555: result = 2
  of pix_format_rgb565: result = 2
  of pix_format_rgb24 : result = 3
  of pix_format_bgr24 : result = 3
  of pix_format_rgba32: result = 4
  of pix_format_argb32: result = 4
  of pix_format_abgr32: result = 4
  of pix_format_bgra32: result = 4

type
  PolymorphicBase = ref object of RootObj
    clear_p  : proc(c: Rgba8)
    color_set: proc(c: Rgba8)
    color_get: proc(): Rgba8
    prepare_p: proc()
    render_p : proc(sl: var ScanlineP8)
    
proc clear(self: PolymorphicBase, c: Rgba8) =
  self.clear_p(c)
  
proc color(self: PolymorphicBase, c: Rgba8) =
  self.color_set(c)
  
proc color(self: PolymorphicBase): Rgba8 =
  self.color_get()
  
proc prepare(self: PolymorphicBase) =
  self.prepare_p()
  
proc render(self: PolymorphicBase, sl: var ScanlineP8) =
  self.render_p(sl)
  
type
  PolymorphicAdaptor[PixFmt] = ref object of PolymorphicBase
    pixf: PixFmt
    rb  : RendererBase[PixFmt]
    ren : RendererScanlineAASolid[RendererBase[PixFmt], Rgba8]
        
proc newPolymorphicAdaptor[PixFmt](rbuf: var RenderingBuffer): PolymorphicBase =
  var ren = new(PolymorphicAdaptor[PixFmt])
  
  ren.pixf = construct(PixFmt, rbuf)
  ren.rb   = initRendererBase(ren.pixf)
  ren.ren  = initRendererScanlineAASolid(ren.rb)
            
  proc clear_i(c: Rgba8) =
    ren.rb.clear(c)
  
  proc color_set_i(c: Rgba8) =
    ren.ren.color(c)
  
  proc color_get_i(): Rgba8 =
    ren.ren.color()
  
  proc prepare_i() =
    ren.ren.prepare()
  
  proc render_i(sl: var ScanlineP8) =
    ren.ren.render(sl)
    
  ren.clear_p   = clear_i
  ren.color_set = color_set_i
  ren.color_get = color_get_i
  ren.prepare_p = prepare_i
  ren.render_p  = render_i
  result = ren

proc rendererFactory(x: PixFormat, rbuf: var RenderingBuffer): PolymorphicBase =
  case x
  of pix_format_rgb555: result = newPolymorphicAdaptor[PixFmtRgb555](rbuf)
  of pix_format_rgb565: result = newPolymorphicAdaptor[PixFmtRgb565](rbuf)
  of pix_format_rgb24 : result = newPolymorphicAdaptor[PixFmtRgb24 ](rbuf)
  of pix_format_bgr24 : result = newPolymorphicAdaptor[PixFmtBgr24 ](rbuf)
  of pix_format_rgba32: result = newPolymorphicAdaptor[PixFmtRgba32](rbuf)
  of pix_format_argb32: result = newPolymorphicAdaptor[PixFmtArgb32](rbuf)
  of pix_format_abgr32: result = newPolymorphicAdaptor[PixFmtAbgr32](rbuf)
  of pix_format_bgra32: result = newPolymorphicAdaptor[PixFmtBgra32](rbuf)
        
const
  pixFormat = pix_format_bgra32
  frameWidth = 400
  frameHeight = 330
  pixWidth = getPixWidth(pixFormat)

type
  ValueT = uint8
  
proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    mx     = [100.0, 369.0, 143.0]
    my     = [60.0, 170.0, 310.0]
    path   = initPathStorage()
    ren    = rendererFactory(pixFormat, rbuf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    
  path.moveTo(mx[0], my[0])
  path.lineTo(mx[1], my[1])
  path.lineTo(mx[2], my[2])
  path.closePolygon()
  
  ren.clear(initRgba8(255, 255, 255))
  ren.color(initRgba8(80, 30, 20, 255))
  ras.addPath(path)
  renderScanlines(ras, sl, ren)
  
  var
    target = newString(frameWidth * frameHeight * 3)
    rbuf2  = initRenderingBuffer(cast[ptr ValueT](target[0].addr), frameWidth, frameHeight, -frameWidth * 3)
  
  case pixFormat
  of pix_format_rgb555: colorConv(rbuf2, rbuf, color_conv_rgb555_to_rgb24)
  of pix_format_rgb565: colorConv(rbuf2, rbuf, color_conv_rgb565_to_rgb24)
  of pix_format_rgb24 : colorConv(rbuf2, rbuf, color_conv_rgb24_to_rgb24)
  of pix_format_bgr24 : colorConv(rbuf2, rbuf, color_conv_bgr24_to_rgb24)
  of pix_format_rgba32: colorConv(rbuf2, rbuf, color_conv_rgba32_to_rgb24)
  of pix_format_argb32: colorConv(rbuf2, rbuf, color_conv_argb32_to_rgb24)
  of pix_format_abgr32: colorConv(rbuf2, rbuf, color_conv_abgr32_to_rgb24)
  of pix_format_bgra32: colorConv(rbuf2, rbuf, color_conv_bgra32_to_rgb24)
  
  saveBMP24("polymorphic_renderer.bmp", target, frameWidth, frameHeight)
  
  #echo "---"
  #var buf = test_poly()
  #copyMem(buffer.cstring, buf, buffer.len)
  #saveBMP32("polymorphic_renderer.bmp", buffer, frameWidth, frameHeight)

onDraw()
