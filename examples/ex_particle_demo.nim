import agg/[basics, pixfmt_rgba, color_rgba, rendering_buffer,
  renderer_base, span_allocator, span_gradient, gsv_text,
  renderer_scanline, scanline_u, rasterizer_scanline_aa,
  conv_stroke, ellipse, trans_affine, span_interpolator_linear, calc]
import random, math, platform.support, strutils, ctrl.slider, ctrl.cbox

const
  frameWidth = 600
  frameHeight = 500
  flipY = true

type
  GradientTricolor = object
    mC1, mC2, mC3: Rgba8

proc initGradientTricolor(c1, c2, c3: Rgba8): GradientTricolor =
  result.mC1 = c1
  result.mC2 = c2
  result.mC3 = c3

proc `[]`(self: GradientTricolor, idx: int): Rgba8 =
  type
    ColorT = Rgba8
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)

  const
    baseShift = getBaseShift(ColorT)

  if idx <= 127:
    let idx = idx * 2
    result.r = ValueT((((self.mC2.r.CalcT - self.mC1.r.CalcT) * idx.CalcT) + (self.mC1.r.CalcT shl baseShift)) shr baseShift)
    result.g = ValueT((((self.mC2.g.CalcT - self.mC1.g.CalcT) * idx.CalcT) + (self.mC1.g.CalcT shl baseShift)) shr baseShift)
    result.b = ValueT((((self.mC2.b.CalcT - self.mC1.b.CalcT) * idx.CalcT) + (self.mC1.b.CalcT shl baseShift)) shr baseShift)
    result.a = ValueT((((self.mC2.a.CalcT - self.mC1.a.CalcT) * idx.CalcT) + (self.mC1.a.CalcT shl baseShift)) shr baseShift)
  else:
    let idx = (idx - 127) * 2
    result.r = ValueT((((self.mC3.r.CalcT - self.mC2.r.CalcT) * idx.CalcT) + (self.mC2.r.CalcT shl baseshift)) shr baseShift)
    result.g = ValueT((((self.mC3.g.CalcT - self.mC2.g.CalcT) * idx.CalcT) + (self.mC2.g.CalcT shl baseshift)) shr baseShift)
    result.b = ValueT((((self.mC3.b.CalcT - self.mC2.b.CalcT) * idx.CalcT) + (self.mC2.b.CalcT shl baseshift)) shr baseShift)
    result.a = ValueT((((self.mC3.a.CalcT - self.mC2.a.CalcT) * idx.CalcT) + (self.mC2.a.CalcT shl baseshift)) shr baseShift)

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    mAngle, mCenterScale: float64
    mParticlesValue: float64
    mSpeedValue: float64
    mDeltaCenter: float64

    mCenter, mDelta: array[1000, PointD]
    mRadius: array[1000, float64]
    mColor1: array[1000, Rgba8]
    mColor2: array[1000, Rgba8]
    mColor3: array[1000, Rgba8]

    mGradients: array[1000, seq[Rgba8]]
    mCache: array[1000, DynaRow[uint8]]

    mParticles, mSpeed: SliderCtrl[Rgba8]
    mUseCache, mRun: CboxCtrl[Rgba8]

    mGradientCircle: GradientCircle
    mSpanAllocator: SpanAllocator[Rgba8]
    mTxt: GsvText
    mPt: ConvStroke[GsvText, NullMarkers]

    mRunFlag, mUseCacheFlag, mFirstTime: bool

    mSl: ScanLineU8
    mRas: RasterizerScanLineAA

proc newApp(format: PixFormat, flipY: bool): App =
  var app = new(App)
  PlatformSupport(app).init(format, flipY)

  app.mSl = initScanlineU8()
  app.mRas = initRasterizerScanLineAA()

  #app.mGradientCircle = initGradientCircle()
  app.mSpanAllocator = initSpanAllocator[Rgba8]()

  app.mParticles = newSliderCtrl[Rgba8](5, 5, 300, 12, not flipY)
  app.mParticles.setRange(10, 1000)
  app.mParticles.value(200)
  app.mParticles.label("Number of Particles=$1")
  app.mParticles.noTransform()
  app.mParticlesValue = app.mParticles.value()

  app.mSpeed = newSliderCtrl[Rgba8](5, 20, 300, 12 + 15, not flipY)
  app.mSpeed.setRange(0.025, 2.0)
  app.mSpeed.value(1.0)
  app.mSpeed.label("Dark Energy=$1")
  app.mSpeed.noTransform()

  var
    white = initRgba(1,1,1)
    active = initRgba(0.8,0,0)

  app.mUseCache = newCboxCtrl[Rgba8](320, 5, "Use Bitmap Cache", not flipY)
  app.mUseCache.textColor(white)
  app.mUseCache.inactiveColor(white)
  app.mUseCache.activeColor(active)
  app.mUseCache.status(true)
  app.mUseCache.noTransform()

  app.mRun = newCboxCtrl[Rgba8](320, 20, "Start the Universe!", not flipY)
  app.mRun.textColor(white)
  app.mRun.inactiveColor(white)
  app.mRun.activeColor(active)
  app.mRun.status(true)
  app.mRun.noTransform()

  app.mRunFlag = app.mRun.status()
  app.mUseCacheFlag = app.mUseCache.status()
  app.mSpeedValue = app.mSpeed.value()
  app.mFirstTime = true

  app.mAngle = 0
  app.mCenterScale = 0
  app.mDeltaCenter = 0.5

  app.mTxt = initGsvText()
  app.mTxt.size(10)
  app.mPt = initConvStroke(app.mTxt)
  app.mPt.width(1.5)

  app.addCtrl(app.mParticles)
  app.addCtrl(app.mSpeed)
  app.addCtrl(app.mUseCache)
  app.addCtrl(app.mRun)

  result = app

proc renderParticle[RendererBase](app: App, ren: var RendererBase; idx: int; x, y: float64) =
  var
    grm = initTransAffine()
    radius = app.mRadius[idx]

  grm.reset()
  grm.scale(radius * 0.1)
  grm.translate(x, y)
  grm.invert()

  var
    circle = initEllipse(x, y, radius, radius, 32)
    spanInterpolator = initSpanInterpolatorLinear(grm)
    sg = initSpanGradient(spanInterpolator, app.mGradientCircle, app.mGradients[idx], 0, 10)
    rg = initRendererScanLineAA(ren, app.mSpanAllocator, sg)

  app.mRas.addPath(circle)
  renderScanLines(app.mRas, app.mSl, rg)

method onInit(app: App) =
  var
    da: int
    divisor = if app.mUseCache.status: 250.0 else: 500.0
    angle, speed, K: float64
    N = iround(app.mParticles.value())
    disorder = false

  randomize()

  if app.mFirstTime:
    for i in 0.. <N:
      app.mCenter[i].x = 0.5 * frameWidth
      app.mCenter[i].y = 0.5 * frameHeight
      if disorder:
        app.mCenter[i].x = random(frameWidth.float64) - 5.0
        app.mCenter[i].y = random(frameHeight.float64) - 5.0

        if random(1) != 0:
          app.mDelta[i].x = (random(5000.0) + 1000.0) / divisor
        else:
          app.mDelta[i].x = -(random(5000.0) + 1000.0) / divisor

        app.mDelta[i].y = app.mDelta[i].x

        if random(1) != 0:
          app.mDelta[i].y = -app.mDelta[i].y

        angle = random(0.25 * pi)
        da = random(4)
        angle = angle + pi * 0.1 * (5 * da.float64 + 1)
      else:
        angle = random(2 * pi)

      speed = (random(5000.0) + 1000.0) / divisor

      app.mDelta[i].y = sin(angle) * speed
      app.mDelta[i].x = cos(angle) * speed

      K = 1.0 - N.float64 / 2000.0

      app.mRadius[i] = (random(30.0) + 15.0) * K

      app.mColor1[i]= initRgba8(random(0xFF), random(0xFF), random(0xFF), 0)
      app.mColor2[i]= initRgba8(random(0xFF), random(0xFF), random(0xFF), 255)

      let component = random(4)

      if component == 0: app.mColor2[i].r = 255
      if component == 1: app.mColor2[i].g = 255
      if component == 2: app.mColor2[i].b = 255

      if disorder:
        app.mColor1[i] = app.mColor2[i]
        app.mColor1[i].a = 0

      app.mColor3[i] = initRgba8(random(0xFF), random(0xFF), random(0xFF), 0)

      var grc = initGradientTricolor(app.mColor1[i], app.mColor2[i], app.mColor3[i])
      var grad = newSeq[Rgba8](256)
      for j in 0.. <256:
        grad[j] = grc[j]
      app.mGradients[i] = grad

    app.mFirstTime = false

  type
    PixFmtDyna = PixfmtAlphaBlendRgba[BlenderBgra32, DynaRow[ValueT], Pixel32Type]

  if app.mUseCache.status():
    for i in 0.. <N:
      let D = iround(app.mRadius[i]) * 2
      app.mCache[i] = initDynaRow[ValueT](D, D, D * getPixelem(PixFmt))
      var
        pixFmt = construct(PixFmtDyna, app.mCache[i])
        rb = initRendererBase(pixFmt)
      app.renderParticle(rb, i, D.float64 * 0.5, D.float64 * 0.5)

method onDraw(app: App) =
  type
    PixFmtDyna = PixfmtAlphaBlendRgba[BlenderBgra32, DynaRow[ValueT], Pixel32Type]

  var
    pixF = construct(PixFmt, app.rbufWindow())
    pixFPre = construct(PixFmtPre, app.rbufWindow())

    renb = initRendererBase(pixF)
    renbPre = initRendererBase(pixFPre)
    ren = initRendererScanLineAASolid(renb)

  app.mRas.clipBox(0, 0, app.width(), app.height())
  renb.clear(initRgba(0,0,0))

  if app.mRun.status():
    app.startTimer()

    let N = iround(app.mParticles.value())

    if app.mUseCache.status():
      for i in 0.. <N:
        var
          pixFmt = construct(PixFmtDyna, app.mCache[i])
          x = iround(app.mCenter[i].x - app.mRadius[i]) + 1
          y = iround(app.mCenter[i].y - app.mRadius[i]) + 1
        renbPre.blendFrom(pixFmt, nil, x, y)
    else:
      for i in 0.. <N:
        app.renderParticle(renb, i, app.mCenter[i].x, app.mCenter[i].y)

    let endTime = app.elapsedTime()

    let text = "$1 fps" % [(1000.0 / endTime).formatFloat(ffDecimal, 3)]
    app.mTxt.startPoint(10, app.height() - 35)
    app.mTxt.text(text)
    app.mRas.addPath(app.mPt)
    ren.color(initRgba(1,1,1))
    renderScanLines(app.mRas, app.mSl, ren)

  # Render the controls
  renderCtrl(app.mRas, app.mSl, renb, app.mParticles)
  renderCtrl(app.mRas, app.mSl, renb, app.mSpeed)
  renderCtrl(app.mRas, app.mSl, renb, app.mUseCache)
  renderCtrl(app.mRas, app.mSl, renb, app.mRun)

var mCenter = 0.0
var mDC = 0.5

method onIdle(app: App) =
  let n = app.mParticles.value().int

  var
    dx = cos(app.mAngle) * mCenter
    dy = sin(app.mAngle) * mCenter
    cx = dx + app.width() / 2
    cy = dy + app.height() / 2
    max_dist = sqrt(app.width() * app.width() / 2 + app.height() * app.height() / 2)

  app.mAngle += 5.0 * pi / 180.0
  mCenter += mDC
  if mCenter > max_dist/2:
    mCenter = max_dist/2
    mDC = -mDC

  if mCenter < 10.0:
    mCenter = 10.0
    mDC = -mDC

  for i in 0.. <n:
    app.mCenter[i].x += app.mDelta[i].x * app.mSpeed.value()
    app.mCenter[i].y += app.mDelta[i].y * app.mSpeed.value()

    var d = calcDistance(app.mCenter[i].x, app.mCenter[i].y, cx, cy)
    if d > max_dist:
      app.mCenter[i].x = cx
      app.mCenter[i].y = cy

  app.forceRedraw()

method onCtrlChange(app: App) =
  if app.mRunFlag != app.mRun.status():
    app.waitMode(not app.mRun.status())
    app.mRunFlag = app.mRun.status()
    if app.mRunFlag:
      app.onInit()
  else:
    var stop = false
    if app.mUseCache.status() != app.mUseCacheFlag:
      app.mUseCacheFlag = app.mUseCache.status()
      stop = true

    if app.mParticles.value() != app.mParticlesValue:
      app.mParticlesValue = app.mParticles.value()
      stop = true

    if app.mSpeed.value() != app.mSpeedValue:
      app.mSpeedValue = app.mSpeed.value()
      stop = true

    if stop:
      app.waitMode(true)
      app.mRun.status(false)

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("Renesis project -- Particles demo.")

  if app.init(frameWidth, frameHeight, {window_resize}, "particle_demo"):
    app.waitMode(false)
    return app.run()

  result = 1

discard main()
