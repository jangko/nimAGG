import agg/[basics, rendering_buffer, rasterizer_scanline_aa, rasterizer_outline,
  conv_transform, conv_stroke, scanline_p, renderer_scanline,
  renderer_primitives, rasterizer_outline, rasterizer_outline_aa,
  pattern_filters_rgba, renderer_outline_aa, renderer_outline_image,
  pixfmt_rgb, color_rgba, renderer_base, gsv_text]
import ctrl.slider, ctrl.cbox, make_arrows, math, platform.support, strutils

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
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mStep: SliderCtrl[Rgba8]
    mWidth: SliderCtrl[Rgba8]
    mTest: CboxCtrl[Rgba8]
    mRotate: CboxCtrl[Rgba8]
    mAccurateJoins: CboxCtrl[Rgba8]
    mScalePattern: CboxCtrl[Rgba8]
    mStartAngle: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mStep = newSliderCtrl[Rgba8](10.0, 10.0 + 4.0, 150.0, 10.0 + 8.0 + 4.0, not flipY)
  result.mWidth = newSliderCtrl[Rgba8](150.0 + 10.0, 10.0 + 4.0, 400 - 10.0, 10.0 + 8.0 + 4.0, not flipY)
  result.mTest = newCboxCtrl[Rgba8](10.0, 10.0 + 4.0 + 16.0,    "Test Performance", not flipY)
  result.mRotate = newCboxCtrl[Rgba8](130 + 10.0, 10.0 + 4.0 + 16.0,    "Rotate", not flipY)
  result.mAccurateJoins = newCboxCtrl[Rgba8](200 + 10.0, 10.0 + 4.0 + 16.0, "Accurate Joins", not flipY)
  result.mScalePattern = newCboxCtrl[Rgba8](310 + 10.0, 10.0 + 4.0 + 16.0, "Scale Pattern", not flipY)

  result.addCtrl(result.mStep)
  result.addCtrl(result.mwidth)
  result.addCtrl(result.mTest)
  result.addCtrl(result.mRotate)
  result.addCtrl(result.mAccurateJoins)
  result.addCtrl(result.mScalePattern)

  result.mStartAngle = 0.0
  result.mStep.setRange(0.0, 2.0)
  result.mStep.value(0.1)
  result.mStep.label("Step=$1")
  result.mStep.noTransform()
  result.mWidth.setRange(0.0, 7.0)
  result.mWidth.value(3.0)
  result.mWidth.label("Width=$1")
  result.mWidth.noTransform()
  result.mTest.textSize(9.0, 7.0)
  result.mTest.noTransform()
  result.mRotate.textSize(9.0, 7.0)
  result.mRotate.noTransform()
  result.mAccurateJoins.textSize(9.0, 7.0)
  result.mAccurateJoins.noTransform()
  result.mScalePattern.textSize(9.0, 7.0)
  result.mScalePattern.noTransform()
  result.mScalePattern.status(false)

proc draw_aliased_pix_accuracy[Rasterizer, Renderer](app: App, ras: var Rasterizer, prim: var Renderer) =
  var
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.mStartAngle
    s1 = initSpiral(w/5.0, h/4.0+50.0, 5, 70, 8, angle)
    rn: Roundoff
    trans = initConvTransform(s1, rn)
  prim.line_color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(trans)

proc draw_aliased_subpix_accuracy[Rasterizer, Renderer](app: App, ras: var Rasterizer, prim: var Renderer) =
  var
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.mStartAngle
    s2 = initSpiral(w/2.0, h/4.0+50.0, 5, 70, 8, angle)
  prim.lineColor(initRgba(0.4, 0.3, 0.1))
  ras.addPath(s2)

proc draw_anti_aliased_outline[Rasterizer, Renderer](app: App, ras: var Rasterizer, ren: var Renderer) =
  var
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.mStartAngle
    s3 = initSpiral(w/5.0, h - h/4.0 + 20.0, 5, 70, 8, angle)

  ren.color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(s3)

proc draw_anti_aliased_scanline[Rasterizer, Scanline, Renderer](app: App,
  ras: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.mStartAngle
    s4 = initSpiral(w/2.0, h - h/4.0 + 20.0, 5, 70, 8, angle)
    stroke = initConvStroke(s4)
  stroke.width(app.mWidth.value())
  stroke.lineCap(LineCap.roundCap)
  ren.color(initRgba(0.4, 0.3, 0.1))
  ras.addPath(stroke)
  renderScanlines(ras, sl, ren)

proc draw_anti_aliased_outline_img[Rasterizer, Renderer](app: App, ras: var Rasterizer, ren: var Renderer) =
  var
    w = frameWidth.float64
    h = frameHeight.float64
    angle = app.mStartAngle
    s5 = initSpiral(w - w/5.0, h - h/4.0 + 20.0, 5, 70, 8, angle)
  ras.addPath(s5)

proc text[Rasterizer, Scanline, Renderer](app: App, ras: var Rasterizer, sl: var Scanline,
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

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
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
    srcScaled = initLineImageScale(src, app.mWidth.value())
    pattern = initLineImagePatternPow2(filter)

  prof.width(app.mWidth.value())
  rasOaa.lineJoin(if app.mAccurateJoins.status(): outlineMiterAccurateJoin else: outlineRoundJoin)
  rasOaa.roundCap(true)

  if app.mScalePattern.status():
    pattern.create(srcScaled)
  else:
    pattern.create(src)

  var
    renImg = initRendererOutlineImage(rb, pattern)
    rasImg = initRasterizerOutlineAA(renImg)
    w = frameWidth.float64
    h = frameHeight.float64

  if app.mScalePattern.status():
    renImg.scaleX(app.mWidth.value() / src.height().float64)

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

  renderCtrl(rasAA, sl, rb, app.mStep)
  renderCtrl(rasAA, sl, rb, app.mWidth)
  renderCtrl(rasAA, sl, rb, app.mTest)
  renderCtrl(rasAA, sl, rb, app.mRotate)
  renderCtrl(rasAA, sl, rb, app.mAccurateJoins)
  renderCtrl(rasAA, sl, rb, app.mScalePattern)

method onIdle(app: App) =
  app.mStartAngle += deg2rad(app.mStep.value())
  if app.mStartAngle > deg2rad(360.0):
    app.mStartAngle -= deg2rad(360.0)
  app.forceRedraw()

method onCtrlChange(app: App) =
  app.waitMode(not app.mRotate.status())

  if app.mTest.status():
    app.onDraw()
    app.updateWindow()

    var
      pf     = construct(Pixfmt, app.rbufWindow())
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
      srcScaled = initLineImageScale(src, app.mWidth.value())
      pattern = initLineImagePatternPow2(filter)

    prof.width(app.mWidth.value())

    if app.mAccurateJoins.status():
      rasOaa.lineJoin(outlineMiterAccurateJoin)
    else:
      rasOaa.lineJoin(outlineRoundJoin)

    rasOaa.roundCap(true)

    if app.mScalePattern.status():
      pattern.create(srcScaled)
    else:
      pattern.create(src)

    var
      renImg = initRendererOutlineImage(rb, pattern)
      rasImg = initRasterizerOutlineAA(renImg)

    if app.mScalePattern.status():
      renImg.scaleX(src.height().float64 / app.mWidth.value())

    app.startTimer()
    for i in 0.. <200:
      app.draw_aliased_subpix_accuracy(rasAl, renPrim)
      app.mStartAngle += deg2rad(app.mStep.value())

    let t2 = app.elapsedTime()

    app.startTimer()
    for i in 0.. <200:
      app.draw_anti_aliased_outline(rasOaa, renOaa)
      app.mStartAngle += deg2rad(app.mStep.value())

    let t3 = app.elapsedTime()

    app.startTimer()
    for i in 0.. <200:
      app.draw_anti_aliased_scanline(ras_aa, sl, ren_aa)
      app.mStartAngle += deg2rad(app.mStep.value())

    let t4 = app.elapsedTime()

    app.startTimer()
    for i in 0.. <200:
      app.draw_anti_aliased_outline_img(ras_img, ren_img)
      app.mStartAngle += deg2rad(app.mStep.value())

    let t5 = app.elapsedTime()

    app.mTest.status(false)
    app.forceRedraw()

    var buf = "Aliased=$1ms, Anti-Aliased=$2ms, Scanline=$3ms, Image-Pattern=$4ms" % [
      t2.formatFloat(ffDecimal, 3),
      t3.formatFloat(ffDecimal, 3),
      t4.formatFloat(ffDecimal, 3),
      t5.formatFloat(ffDecimal, 3)]

    app.message(buf)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Rasterizer")

  if app.init(frameWidth, frameHeight, {}, "rasterizer2"):
    return app.run()

  result = 1

discard main()
