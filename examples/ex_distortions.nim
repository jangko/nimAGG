import agg/[rendering_buffer, rasterizer_scanline_aa, ellipse, trans_affine,
  conv_transform, pixfmt_rgb, span_allocator, span_image_filter_rgb,
  scanline_u, renderer_scanline, span_interpolator_linear, image_filters,
  span_interpolator_adaptor, span_gradient, image_accessors,
  color_rgba, renderer_base, basics]
import ctrl.slider, ctrl.rbox, math, os, strutils, platform.support

const gradientColors = [
  255'u8, 255, 255, 255,
  255, 255, 254, 255,
  255, 255, 254, 255,
  255, 255, 254, 255,
  255, 255, 253, 255,
  255, 255, 253, 255,
  255, 255, 252, 255,
  255, 255, 251, 255,
  255, 255, 250, 255,
  255, 255, 248, 255,
  255, 255, 246, 255,
  255, 255, 244, 255,
  255, 255, 241, 255,
  255, 255, 238, 255,
  255, 255, 235, 255,
  255, 255, 231, 255,
  255, 255, 227, 255,
  255, 255, 222, 255,
  255, 255, 217, 255,
  255, 255, 211, 255,
  255, 255, 206, 255,
  255, 255, 200, 255,
  255, 254, 194, 255,
  255, 253, 188, 255,
  255, 252, 182, 255,
  255, 250, 176, 255,
  255, 249, 170, 255,
  255, 247, 164, 255,
  255, 246, 158, 255,
  255, 244, 152, 255,
  254, 242, 146, 255,
  254, 240, 141, 255,
  254, 238, 136, 255,
  254, 236, 131, 255,
  253, 234, 126, 255,
  253, 232, 121, 255,
  253, 229, 116, 255,
  252, 227, 112, 255,
  252, 224, 108, 255,
  251, 222, 104, 255,
  251, 219, 100, 255,
  251, 216,  96, 255,
  250, 214,  93, 255,
  250, 211,  89, 255,
  249, 208,  86, 255,
  249, 205,  83, 255,
  248, 202,  80, 255,
  247, 199,  77, 255,
  247, 196,  74, 255,
  246, 193,  72, 255,
  246, 190,  69, 255,
  245, 187,  67, 255,
  244, 183,  64, 255,
  244, 180,  62, 255,
  243, 177,  60, 255,
  242, 174,  58, 255,
  242, 170,  56, 255,
  241, 167,  54, 255,
  240, 164,  52, 255,
  239, 161,  51, 255,
  239, 157,  49, 255,
  238, 154,  47, 255,
  237, 151,  46, 255,
  236, 147,  44, 255,
  235, 144,  43, 255,
  235, 141,  41, 255,
  234, 138,  40, 255,
  233, 134,  39, 255,
  232, 131,  37, 255,
  231, 128,  36, 255,
  230, 125,  35, 255,
  229, 122,  34, 255,
  228, 119,  33, 255,
  227, 116,  31, 255,
  226, 113,  30, 255,
  225, 110,  29, 255,
  224, 107,  28, 255,
  223, 104,  27, 255,
  222, 101,  26, 255,
  221,  99,  25, 255,
  220,  96,  24, 255,
  219,  93,  23, 255,
  218,  91,  22, 255,
  217,  88,  21, 255,
  216,  86,  20, 255,
  215,  83,  19, 255,
  214,  81,  18, 255,
  213,  79,  17, 255,
  212,  77,  17, 255,
  211,  74,  16, 255,
  210,  72,  15, 255,
  209,  70,  14, 255,
  207,  68,  13, 255,
  206,  66,  13, 255,
  205,  64,  12, 255,
  204,  62,  11, 255,
  203,  60,  10, 255,
  202,  58,  10, 255,
  201,  56,   9, 255,
  199,  55,   9, 255,
  198,  53,   8, 255,
  197,  51,   7, 255,
  196,  50,   7, 255,
  195,  48,   6, 255,
  193,  46,   6, 255,
  192,  45,   5, 255,
  191,  43,   5, 255,
  190,  42,   4, 255,
  188,  41,   4, 255,
  187,  39,   3, 255,
  186,  38,   3, 255,
  185,  37,   2, 255,
  183,  35,   2, 255,
  182,  34,   1, 255,
  181,  33,   1, 255,
  179,  32,   1, 255,
  178,  30,   0, 255,
  177,  29,   0, 255,
  175,  28,   0, 255,
  174,  27,   0, 255,
  173,  26,   0, 255,
  171,  25,   0, 255,
  170,  24,   0, 255,
  168,  23,   0, 255,
  167,  22,   0, 255,
  165,  21,   0, 255,
  164,  21,   0, 255,
  163,  20,   0, 255,
  161,  19,   0, 255,
  160,  18,   0, 255,
  158,  17,   0, 255,
  156,  17,   0, 255,
  155,  16,   0, 255,
  153,  15,   0, 255,
  152,  14,   0, 255,
  150,  14,   0, 255,
  149,  13,   0, 255,
  147,  12,   0, 255,
  145,  12,   0, 255,
  144,  11,   0, 255,
  142,  11,   0, 255,
  140,  10,   0, 255,
  139,  10,   0, 255,
  137,   9,   0, 255,
  135,   9,   0, 255,
  134,   8,   0, 255,
  132,   8,   0, 255,
  130,   7,   0, 255,
  128,   7,   0, 255,
  126,   6,   0, 255,
  125,   6,   0, 255,
  123,   5,   0, 255,
  121,   5,   0, 255,
  119,   4,   0, 255,
  117,   4,   0, 255,
  115,   4,   0, 255,
  113,   3,   0, 255,
  111,   3,   0, 255,
  109,   2,   0, 255,
  107,   2,   0, 255,
  105,   2,   0, 255,
  103,   1,   0, 255,
  101,   1,   0, 255,
  99,   1,   0, 255,
  97,   0,   0, 255,
  95,   0,   0, 255,
  93,   0,   0, 255,
  91,   0,   0, 255,
  90,   0,   0, 255,
  88,   0,   0, 255,
  86,   0,   0, 255,
  84,   0,   0, 255,
  82,   0,   0, 255,
  80,   0,   0, 255,
  78,   0,   0, 255,
  77,   0,   0, 255,
  75,   0,   0, 255,
  73,   0,   0, 255,
  72,   0,   0, 255,
  70,   0,   0, 255,
  68,   0,   0, 255,
  67,   0,   0, 255,
  65,   0,   0, 255,
  64,   0,   0, 255,
  63,   0,   0, 255,
  61,   0,   0, 255,
  60,   0,   0, 255,
  59,   0,   0, 255,
  58,   0,   0, 255,
  57,   0,   0, 255,
  56,   0,   0, 255,
  55,   0,   0, 255,
  54,   0,   0, 255,
  53,   0,   0, 255,
  53,   0,   0, 255,
  52,   0,   0, 255,
  52,   0,   0, 255,
  51,   0,   0, 255,
  51,   0,   0, 255,
  51,   0,   0, 255,
  50,   0,   0, 255,
  50,   0,   0, 255,
  51,   0,   0, 255,
  51,   0,   0, 255,
  51,   0,   0, 255,
  51,   0,   0, 255,
  52,   0,   0, 255,
  52,   0,   0, 255,
  53,   0,   0, 255,
  54,   1,   0, 255,
  55,   2,   0, 255,
  56,   3,   0, 255,
  57,   4,   0, 255,
  58,   5,   0, 255,
  59,   6,   0, 255,
  60,   7,   0, 255,
  62,   8,   0, 255,
  63,   9,   0, 255,
  64,  11,   0, 255,
  66,  12,   0, 255,
  68,  13,   0, 255,
  69,  14,   0, 255,
  71,  16,   0, 255,
  73,  17,   0, 255,
  75,  18,   0, 255,
  77,  20,   0, 255,
  79,  21,   0, 255,
  81,  23,   0, 255,
  83,  24,   0, 255,
  85,  26,   0, 255,
  87,  28,   0, 255,
  90,  29,   0, 255,
  92,  31,   0, 255,
  94,  33,   0, 255,
  97,  34,   0, 255,
  99,  36,   0, 255,
  102,  38,   0, 255,
  104,  40,   0, 255,
  107,  41,   0, 255,
  109,  43,   0, 255,
  112,  45,   0, 255,
  115,  47,   0, 255,
  117,  49,   0, 255,
  120,  51,   0, 255,
  123,  52,   0, 255,
  126,  54,   0, 255,
  128,  56,   0, 255,
  131,  58,   0, 255,
  134,  60,   0, 255,
  137,  62,   0, 255,
  140,  64,   0, 255,
  143,  66,   0, 255,
  145,  68,   0, 255,
  148,  70,   0, 255,
  151,  72,   0, 255,
  154,  74,   0, 255]

type
  PeriodicDistortion = ref object of RootObj
    mCx, mCy: float64
    mPeriod: float64
    mAmplitude: float64
    mPhase: float64

proc init(self: PeriodicDistortion) =
  self.mCx = 0.0
  self.mcy = 0.0
  self.mPeriod = 0.5
  self.mAmplitude = 0.5
  self.mPhase = 0.0

proc center(self: PeriodicDistortion, x, y: float64) =
  self.mCx = x
  self.mCy = y

proc period(self: PeriodicDistortion, v: float64) =
  self.mPeriod = v

proc amplitude(self: PeriodicDistortion, v: float64) =
  self.mAmplitude = 1.0 / v

proc phase(self: PeriodicDistortion, v: float64) =
  self.mPhase = v

method calculate(self: PeriodicDistortion, x, y: var int) {.base.} =
  discard

proc calculateWave(x,y: var int, cx, cy: float64, period, amplitude, phase: float64) =
  let
    xd = float64(x) / imageSubpixelScale - cx
    yd = float64(y) / imageSubpixelScale - cy
    d = sqrt(xd*xd + yd*yd)
  if d > 1:
    let a = cos(d / (16.0 * period) - phase) * (1.0 / (amplitude * d)) + 1.0;
    x = int((xd * a + cx) * imageSubpixelScale)
    y = int((yd * a + cy) * imageSubpixelScale)

proc calculateSwirl(x,y: var int, cx, cy: float64, amplitude, phase: float64) =
  let
    xd = float64(x) / imageSubpixelScale - cx
    yd = float64(y) / imageSubpixelScale - cy
    a = float64(100.0 - sqrt(xd * xd + yd * yd)) / 100.0 * (0.1 / -amplitude)
    sa = sin(a - phase/25.0)
    ca = cos(a - phase/25.0)
  x = int((xd * ca - yd * sa + cx) * imageSubpixelScale)
  y = int((xd * sa + yd * ca + cy) * imageSubpixelScale)

type
  DistortionWave = ref object of PeriodicDistortion

proc newDistortionWave(): DistortionWave =
  new(result)
  PeriodicDistortion(result).init()

method calculate(self: DistortionWave, x, y: var int) =
  calculateWave(x, y, self.mCx, self.mCy, self.mPeriod, self.mAmplitude, self.mPhase)

type
  DistortionSwirl = ref object of PeriodicDistortion

proc newDistortionSwirl(): DistortionSwirl =
  new(result)
  PeriodicDistortion(result).init()

method calculate(self: DistortionSwirl, x, y: var int) =
  calculateSwirl(x, y, self.mCx, self.mCy, self.mAmplitude, self.mPhase)

type
  DistortionSwirlWave = ref object of PeriodicDistortion

proc newDistortionSwirlWave(): DistortionSwirlWave =
  new(result)
  PeriodicDistortion(result).init()

method calculate(self: DistortionSwirlWave, x, y: var int) =
  calculateSwirl(x, y, self.mCx, self.mCy, self.mAmplitude, self.mPhase)
  calculateWave(x, y, self.mCx, self.mCy, self.mPeriod, self.mAmplitude, self.mPhase)

type
  DistortionWaveSwirl = ref object of PeriodicDistortion

proc newDistortionWaveSwirl(): DistortionWaveSwirl =
  new(result)
  PeriodicDistortion(result).init()

method calculate(self: DistortionWaveSwirl, x, y: var int) =
  calculateWave(x, y, self.mCx, self.mCy, self.mPeriod, self.mAmplitude, self.mPhase)
  calculateSwirl(x, y, self.mCx, self.mCy, self.mAmplitude, self.mPhase)

const
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    angle: SliderCtrl[Rgba8]
    scale: SliderCtrl[Rgba8]
    amplitude: SliderCtrl[Rgba8]
    period: SliderCtrl[Rgba8]
    distortion: RboxCtrl[Rgba8]
    centerX, centerY, phase: float64
    gradientColors: array[256, Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.angle      = newSliderCtrl[Rgba8](5,      5,    150,     12,    not flipY)
  result.scale      = newSliderCtrl[Rgba8](5,      5+15, 150,     12+15, not flipY)
  result.period     = newSliderCtrl[Rgba8](5+170,  5,    150+170, 12,    not flipY)
  result.amplitude  = newSliderCtrl[Rgba8](5+170,  5+15, 150+170, 12+15, not flipY)
  result.distortion = newRboxCtrl[Rgba8](480,    5,    600,     90,    not flipY)

  result.addCtrl(result.angle)
  result.addCtrl(result.scale)
  result.addCtrl(result.period)
  result.addCtrl(result.amplitude)
  result.addCtrl(result.distortion)

  result.centerX = 0.0
  result.centerY = 0.0
  result.phase = 0.0
  result.angle.label("Angle=$1")
  result.scale.label("Scale=$1")
  result.angle.setRange(-180.0, 180.0)
  result.angle.value(20.0)
  result.scale.setRange(0.1, 5.0)
  result.scale.value(1.0)
  result.amplitude.label("Amplitude=$1")
  result.period.label("Period=$1")
  result.amplitude.setRange(0.1, 40.0)
  result.period.setRange(0.1, 2.0)
  result.amplitude.value(10.0)
  result.period.value(1.0)
  result.distortion.addItem("Wave")
  result.distortion.addItem("Swirl")
  result.distortion.addItem("Wave-Swirl")
  result.distortion.addItem("Swirl-Wave")
  result.distortion.curItem(0)

  for i in 0.. <256:
    result.gradientColors[i] = initRgba8(
      gradientColors[i * 4 + 0],
      gradientColors[i * 4 + 1],
      gradientColors[i * 4 + 2],
      gradientColors[i * 4 + 3])

var
  dist: PeriodicDistortion
  distWave = newDistortionWave()
  distSwirl = newDistortionSwirl()
  distWaveSwirl = newDistortionWaveSwirl()
  distSwirlWave = newDistortionSwirlWave()

method onInit(app: App) =
  app.centerX = app.rbufImg(0).width().float64 / 2.0 + 10.0
  app.centerY = app.rbufImg(0).height().float64 / 2.0 + 10.0 + 40.0

method onDraw(app: App) =

  var
    imgWidth = app.rbufImg(0).width().float64
    imgHeight = app.rbufImg(0).height().float64

    pf      = construct(PixFmt, app.rbufWindow())
    imgPixf = construct(PixFmt, app.rbufImg(0))
    rb      = initRendererBase(pf)
    srcMtx  = initTransAffine()
    imgMtx  = initTransAffine()
    sa      = initSpanAllocator[Rgba8]()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  srcMtx *= transAffineTranslation(-imgWidth/2, -imgHeight/2)
  srcMtx *= transAffineRotation(app.angle.value() * pi / 180.0)
  srcMtx *= transAffineTranslation(imgWidth/2 + 10, imgHeight/2 + 10 + 40)
  srcMtx *= transAffineResizing(app)

  imgMtx *= transAffineTranslation(-imgWidth/2, -imgHeight/2)
  imgMtx *= transAffineRotation(app.angle.value() * pi / 180.0)
  imgMtx *= transAffineScaling(app.scale.value())
  imgMtx *= transAffineTranslation(imgWidth/2 + 10, imgHeight/2 + 10 + 40)
  imgMtx *= transAffineResizing(app)
  imgMtx.invert()

  case app.distortion.curItem()
  of 0: dist = distWave
  of 1: dist = distSwirl
  of 2: dist = distWaveSwirl
  of 3: dist = distSwirlWave
  else: discard

  dist.period(app.period.value())
  dist.amplitude(app.amplitude.value())
  dist.phase(app.phase)
  var
    cx = app.centerX
    cy = app.centerY

  imgMtx.transform(cx, cy)
  dist.center(cx, cy)

  var
    inter = initSpanInterpolatorAdaptor[SpanInterpolatorLinear[TransAffine]](imgMtx, dist)
    imgSrc = initImageAccessorClip(imgPixf, initRgba(1,1,1))

    # Version without filtering (nearest neighbor)
    #sga = initSpanImageFilterRgbNN(imgSrc, inter)

    #filter = initImageFilter[ImageFilterKaiser]()
    #sga = initSpanImageFilterRgb2x2(imgSrc, inter, filter)

    #filter = initImageFilter[ImageFilterSpline36]()
    #sga = initSpanImageFilterRgb(imgSrc, inter, filter)

  # Version with "hardcoded" bilinear filter and without
  # image_accessor (direct filter, the old variant)
  var
    sg = initSpanImageFilterRgbBilinearClip(imgPixf, initRgba(1,1,1), inter)
    ras = initRasterizerScanlineAA()
    sl  = initScanlineU8()
    r   = imgWidth

  if imgHeight < r: r = imgHeight
  var
    ell = initEllipse(imgWidth  / 2.0, imgHeight / 2.0, r / 2.0 - 20.0, r / 2.0 - 20.0, 200)
    tr  = initConvTransform(ell, srcMtx)

  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rb, sa, sg)

  srcMtx *= ~transAffineResizing(app)
  srcMtx *= transAffineTranslation(imgWidth - imgWidth/10, 0.0)
  srcMtx *= transAffineResizing(app)

  ras.addPath(tr)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,0,0))

  var
    gradF: GradientCircle
    gradColors = app.gradientColors
    spanGrad = initSpanGradient(inter, gradF, gradColors, 0, 180)
    gr1Mtx = initTransAffine()
    gr2Mtx = initTransAffine()

  gr1Mtx *= transAffineTranslation(-imgWidth/2, -imgHeight/2)
  gr1Mtx *= transAffineScaling(0.8)
  gr1Mtx *= transAffineRotation(app.angle.value() * pi / 180.0)
  gr1Mtx *= transAffineTranslation(imgWidth - imgWidth/10 + imgWidth/2 + 10, imgHeight/2 + 10 + 40)
  gr1Mtx *= transAffineResizing(app)

  gr2Mtx *= transAffineRotation(app.angle.value() * pi / 180.0)
  gr2Mtx *= transAffineScaling(app.scale.value())
  gr2Mtx *= transAffineTranslation(imgWidth - imgWidth/10 + imgWidth/2 + 10 + 50, imgHeight/2 + 10 + 40 + 50)
  gr2Mtx *= transAffineResizing(app)
  gr2Mtx.invert()

  cx = app.centerX + imgWidth - imgWidth/10
  cy = app.centerY
  gr2Mtx.transform(cx, cy)
  dist.center(cx, cy)

  inter.transformer(gr2Mtx)

  var tr2 = initConvTransform(ell, gr1Mtx)

  ras.addPath(tr2)
  renderScanlinesAA(ras, sl, rb, sa, spanGrad)

  renderCtrl(ras, sl, rb, app.angle)
  renderCtrl(ras, sl, rb, app.scale)
  renderCtrl(ras, sl, rb, app.amplitude)
  renderCtrl(ras, sl, rb, app.period)
  renderCtrl(ras, sl, rb, app.distortion)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.centerX = x.float64
    app.centerY = y.float64
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.centerX = x.float64
    app.centerY = y.float64
    app.forceRedraw()

method onIdle(app: App) =
  app.phase += 15.0 * pi / 180.0
  if app.phase > pi * 200.0: app.phase -= pi * 200.0
  app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Image and Gradient Distortions")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  let
    frameWidth  = app.rbufImg(0).width() + 300
    frameHeight = app.rbufImg(0).height() + 40 + 20

  if app.init(frameWidth, frameHeight, {window_resize}, "distortions"):
    app.waitMode(false)
    return app.run()

  result = 1

discard main()
