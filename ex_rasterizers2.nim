import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_conv_transform, agg_conv_stroke, agg_scanline_p, agg_renderer_scanline
import agg_renderer_primitives, agg_rasterizer_outline, agg_rasterizer_outline_aa
import agg_pattern_filters_rgba, agg_renderer_outline_aa, agg_renderer_outline_image
import ctrl_slider, ctrl_cbox, agg_pixfmt_rgb, agg_color_rgba, agg_renderer_base
import nimBMP, make_arrows, math, agg_gsv_text

var
  pixmap_chain = [
    16'u32, 7,
    0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0xb4c29999'u32, 0xff9a5757'u32, 
    0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xb4c29999'u32, 
    0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 
    0x0cfbf9f9'u32, 0xff9a5757'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 
    0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xb4c29999'u32, 0x00ffffff'u32, 
    0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x5ae0cccc'u32, 0xffa46767'u32, 0xff660000'u32, 
    0xff975252'u32, 0x7ed4b8b8'u32, 0x5ae0cccc'u32, 0x5ae0cccc'u32, 0x5ae0cccc'u32, 0x5ae0cccc'u32, 
    0xa8c6a0a0'u32, 0xff7f2929'u32, 0xff670202'u32, 0x9ecaa6a6'u32, 0x5ae0cccc'u32, 0x00ffffff'u32, 
    0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 
    0xa4c7a2a2'u32, 0x3affff00'u32, 0x3affff00'u32, 0xff975151'u32, 0xff660000'u32, 0xff660000'u32, 
    0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0x00ffffff'u32, 0x5ae0cccc'u32, 
    0xffa46767'u32, 0xff660000'u32, 0xff954f4f'u32, 0x7ed4b8b8'u32, 0x5ae0cccc'u32, 0x5ae0cccc'u32, 
    0x5ae0cccc'u32, 0x5ae0cccc'u32, 0xa8c6a0a0'u32, 0xff7f2929'u32, 0xff670202'u32, 0x9ecaa6a6'u32, 
    0x5ae0cccc'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x0cfbf9f9'u32, 0xff9a5757'u32, 
    0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 0xff660000'u32, 
    0xff660000'u32, 0xff660000'u32, 0xb4c29999'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 
    0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0xb4c29999'u32, 0xff9a5757'u32, 
    0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xff9a5757'u32, 0xb4c29999'u32, 
    0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32, 0x00ffffff'u32]

type
  PatternPixmapArgb32 = object
    pixmap: ptr uint32
    
proc initPatternPixmapArgb32(pixmap: ptr uint32): PatternPixmapArgb32 =
  result.pixmap = pixmap

proc width(self: PatternPixmapArgb32): int = self.pixmap[0].int
proc height(self: PatternPixmapArgb32): int = self.pixmap[1].int

proc pixel(self: PatternPixmapArgb32, x, y: int): Rgba8 =
  let p = self.pixmap[y * self.width() + x + 2]
  result = initRgba8((p shr 16) and 0xFF, (p shr 8) and 0xFF, p and 0xFF, p shr 24)
    
template getColorT*(x: typedesc[PatternPixmapArgb32]): typedesc = Rgba8

type 
  Roundoff = object
  
proc transform(self: Roundoff, x, y: var float64) =
  x = math.floor(x)
  y = math.floor(y)


const
  frameWidth = 500
  frameHeight = 450
  pixWidth = 3
  flipY = true

type
  ValueT = uint8
  
type
  App = object
    step: SliderCtrl[Rgba8]
    width: SliderCtrl[Rgba8]
    test: CboxCtrl[Rgba8]
    rotate: CboxCtrl[Rgba8]
    accurateJoins: CboxCtrl[Rgba8]
    scalePattern: CboxCtrl[Rgba8]
    startAngle: float64
    
proc initApp(): App =
  result.step = newSliderCtrl[Rgba8](10.0, 10.0 + 4.0, 150.0, 10.0 + 8.0 + 4.0, not flipY)
  result.width = newSliderCtrl[Rgba8](150.0 + 10.0, 10.0 + 4.0, 400 - 10.0, 10.0 + 8.0 + 4.0, not flipY)
  result.test = newCboxCtrl[Rgba8](10.0, 10.0 + 4.0 + 16.0,    "Test Performance", not flipY)
  result.rotate = newCboxCtrl[Rgba8](130 + 10.0, 10.0 + 4.0 + 16.0,    "Rotate", not flipY)
  result.accurateJoins = newCboxCtrl[Rgba8](200 + 10.0, 10.0 + 4.0 + 16.0, "Accurate Joins", not flipY)
  result.scalePattern = newCboxCtrl[Rgba8](310 + 10.0, 10.0 + 4.0 + 16.0, "Scale Pattern", not flipY)
  result.startAngle = 0.0
  result.step.setRange(0.0, 2.0)
  result.step.value(0.1)
  result.step.label("Step=$1")
  result.step.noTransform()
  result.width.setRange(0.0, 7.0)
  result.width.value(3.0)
  result.width.label("Width=$1")
  result.width.noTransform()
  result.test.textSize(9.0, 7.0)
  result.test.noTransform()
  result.rotate.textSize(9.0, 7.0)
  result.rotate.noTransform()
  result.accurateJoins.textSize(9.0, 7.0)
  result.accurateJoins.noTransform()
  result.scalePattern.textSize(9.0, 7.0)
  result.scalePattern.noTransform()
  result.scalePattern.status(false)
  
proc draw_aliased_pix_accuracy[Rasterizer, Renderer](app: var App, ras: var Rasterizer, prim: var Renderer) =
  var 
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.startAngle
    s1 = initSpiral(w/5.0, h/4.0+50.0, 5, 70, 8, angle)
    rn: Roundoff
    trans = initConvTransform(s1, rn)
  prim.line_color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(trans)

proc draw_aliased_subpix_accuracy[Rasterizer, Renderer](app: var App, ras: var Rasterizer, prim: var Renderer) =
  var 
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.startAngle
    s2 = initSpiral(w/2.0, h/4.0+50.0, 5, 70, 8, angle)
  prim.lineColor(initRgba(0.4, 0.3, 0.1))
  ras.addPath(s2)

proc draw_anti_aliased_outline[Rasterizer, Renderer](app: var App, ras: var Rasterizer, ren: var Renderer) =
  var 
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.startAngle
    s3 = initSpiral(w/5.0, h - h/4.0 + 20.0, 5, 70, 8, angle)
  
  ren.color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(s3)

proc draw_anti_aliased_scanline[Rasterizer, Scanline, Renderer](app: var App, 
  ras: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var 
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.startAngle
    s4 = initSpiral(w/2.0, h - h/4.0 + 20.0, 5, 70, 8, angle)
    stroke = initConvStroke(s4)
  stroke.width(app.width.value())
  stroke.lineCap(LineCap.roundCap)
  ren.color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(stroke)
  renderScanlines(ras, sl, ren)

proc draw_anti_aliased_outline_img[Rasterizer, Renderer](app: var App, ras: var Rasterizer, ren: var Renderer) =
  var 
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.startAngle
    s5 = initSpiral(w - w/5.0, h - h/4.0 + 20.0, 5, 70, 8, angle)
  ras.addPath(s5)

proc text[Rasterizer, Scanline, Renderer](app: var App, ras: var Rasterizer, sl: var Scanline,
  ren: var Renderer, x, y: float64, txt: string) =
  var 
    t = initGsvText()
    stroke = initConvStroke(t)
    
  t.size(8)
  t.text(txt)
  t.startPoint(x, y)
  stroke.width(0.7)
  ras.addPath(stroke)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)
  
    #typedef agg::renderer_base<pixfmt> renderer_base;
    #typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_aa;
    #typedef agg::renderer_primitives<renderer_base> renderer_prim;
    #typedef agg::rasterizer_outline<renderer_prim> rasterizer_outline;
    #typedef agg::rasterizer_scanline_aa<> rasterizer_scanline;
    #typedef agg::scanline_p8 scanline;
    #typedef agg::renderer_outline_aa<renderer_base> renderer_oaa;
    #typedef agg::pattern_filter_bilinear_rgba8 pattern_filter;
    #typedef agg::line_image_pattern_pow2<pattern_filter> image_pattern;
    #typedef agg::renderer_outline_image<renderer_base, image_pattern> renderer_img;
    #typedef agg::rasterizer_outline_aa<renderer_oaa> rasterizer_outline_aa;
    #typedef agg::rasterizer_outline_aa<renderer_img> rasterizer_outline_img;
proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixfmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    renAA  = initRendererScanlineAASolid(rb)    
    renPrim= initRendererPrimitives(rb)
    rasAA  = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    rasAl  = initRasterizerOutline(renPrim)
    prof   = initLineProfileAA()    
    renOaa = initRendererOutlineAA(rb, prof)
    rasOaa = initRasterizerOutlineAA(renOaa)
    filter : PatternFilterBilinearRgba8
    src    = initPatternPixmapArgb32(pixmap_chain[0].addr)
    srcScaled = initLineImageScale(src, app.width.value())
    pattern = initLineImagePatternPow2(filter)
    
  prof.width(app.width.value())
  rasOaa.lineJoin(if app.accurateJoins.status(): outlineMiterAccurateJoin else: outlineRoundJoin)
  rasOaa.roundCap(true)

  if app.scalePattern.status():
    pattern.create(srcScaled)
  else:
    pattern.create(src)

  var 
    renImg = initRendererOutlineImage(rb, pattern)
    rasImg = initRasterizerOutlineAA(renImg)
    w = frameWidth.float64
    h = frameHeight.float64
    
  if app.scalePattern.status():
    renImg.scaleX(app.width.value() / src.height().float64)
  
  rb.clear(initRgba(1.0, 1.0, 0.95))
  
  app.draw_aliased_pix_accuracy(rasAl, renPrim)
  app.draw_aliased_subpix_accuracy(rasAl, renPrim)
  app.draw_anti_aliased_outline(rasOaa, renOaa)
  app.draw_anti_aliased_scanline(rasAA, sl, renAA)
  app.draw_anti_aliased_outline_img(rasImg, renImg)
  
  app.text(rasAA, sl, renAA, 50.0, 80.0, "Bresenham lines,\nregular accuracy")
  app.text(rasAA, sl, renAA, w/2.0-50.0, 80.0, "Bresenham lines,\nsubpixel accuracy")
  app.text(rasAA, sl, renAA, 50.0, h/2.0+50.0, "Anti-aliased lines")
  app.text(rasAA, sl, renAA, w/2.0-50.0, h/2.0+50.0, "Scanline rasterizer")
  app.text(rasAA, sl, renAA, w - w/5.0 - 50.0, h/2.0+50.0, "Arbitrary Image Pattern")
    
  renderCtrl(rasAA, sl, rb, app.step)
  renderCtrl(rasAA, sl, rb, app.width)
  renderCtrl(rasAA, sl, rb, app.test)
  renderCtrl(rasAA, sl, rb, app.rotate)
  renderCtrl(rasAA, sl, rb, app.accurateJoins)
  renderCtrl(rasAA, sl, rb, app.scalePattern)     
  
  saveBMP24("rasterizers2.bmp", buffer, frameWidth, frameHeight)

onDraw()