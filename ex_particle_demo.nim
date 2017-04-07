import agg_basics, agg_pixfmt_rgba, agg_color_rgba, agg_rendering_buffer
import agg_renderer_base, ctrl_slider, ctrl_cbox, agg_span_allocator
import agg_span_gradient, agg_gsv_text, agg_renderer_scanline, agg_scanline_u
import agg_rasterizer_scanline_aa, agg_conv_stroke, agg_ellipse
import agg_trans_affine, agg_span_interpolator_linear, random, math
import nimBMP, times, strutils

const
  frameWidth = 600
  frameHeight = 500
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

type
  GradientTricolor = object
    mC1, mC2, mC3: Rgba8

proc initGradientTricolor(c1, c2, c3: Rgba8): GradientTricolor =
  result.mC1 = c1
  result.mC2 = c2
  result.mC3 = c3

proc `[]`(self: GradientTricolor, index: int): Rgba8 =
  type
    ColorT = Rgba8
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)

  const
    baseShift = getBaseShift(ColorT)

  if index <= 127:
    let index = index * 2
    result.r = ValueT((((self.mC2.r - self.mC1.r).int * index) + (self.mC1.r.int shl baseShift)) shr baseShift)
    result.g = ValueT((((self.mC2.g - self.mC1.g).int * index) + (self.mC1.g.int shl baseShift)) shr baseShift)
    result.b = ValueT((((self.mC2.b - self.mC1.b).int * index) + (self.mC1.b.int shl baseShift)) shr baseShift)
    result.a = ValueT((((self.mC2.a - self.mC1.a).int * index) + (self.mC1.a.int shl baseShift)) shr baseShift)
  else:
    let index = index - 127 * 2
    result.r = ValueT((((self.mC3.r - self.mC2.r).int * index) + (self.mC2.r.int shl baseshift)) shr baseShift)
    result.g = ValueT((((self.mC3.g - self.mC2.g).int * index) + (self.mC2.g.int shl baseshift)) shr baseShift)
    result.b = ValueT((((self.mC3.b - self.mC2.b).int * index) + (self.mC2.b.int shl baseshift)) shr baseShift)
    result.a = ValueT((((self.mC3.a - self.mC2.a).int * index) + (self.mC2.a.int shl baseshift)) shr baseShift)

type
  App = ref object
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

    mPixF: PixFmtRgba32
    mPixFPre: PixFmtRgba32Pre

    mRenb: RendererBase[PixFmtRgba32]
    mRenbPre: RendererBase[PixFmtRgba32Pre]

    mRen: RendererScanLineAASolid[RendererBase[PixFmtRgba32], Rgba8]
    mSl: ScanLineU8
    mRas: RasterizerScanLineAA
    buffer: seq[ValueT]
    rbuf: RenderingBuffer

proc newApp(): App =
  var app = new(App)
  app.mSl = initScanlineU8()
  app.mRas = initRasterizerScanLineAA()

  app.buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
  app.rbuf   = initRenderingBuffer(app.buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixWidth)

  app.mPixF = initPixFmtRgba32(app.rbuf)
  app.mPixFPre = initPixFmtRgba32Pre(app.rbuf)

  app.mRenb = initRendererBase(app.mPixF)
  app.mRenbPre = initRendererBase(app.mPixFPre)

  app.mRen = initRendererScanLineAASolid(app.mRenb)

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

  #for i in 0.. <1000:
  #  app.mGradients[i] = newSeq[Rgba8](256)

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

proc init(app: App) =
  var
    da: int
    divisor = if app.mUseCache.status: 250.0 else: 500.0
    angle, speed, K: float64
    N = iround(app.mParticles.value())
    disorder = true

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
    PixfmtRgba32Dyna = PixfmtAlphaBlendRgba[BlenderRgba32, DynaRow[ValueT], Pixel32Type]

  if app.mUseCache.status():
    for i in 0.. <N:
      let D = iround(app.mRadius[i]) * 2
      app.mCache[i] = initDynaRow[ValueT](D, D, D * pixWidth)
      var
        pixFmt = construct(PixfmtRgba32Dyna, app.mCache[i])
        rb = initRendererBase(pixFmt)
      app.renderParticle(rb, i, D.float64 * 0.5, D.float64 * 0.5)

proc onDraw(app: App) =
  type
    PixfmtRgba32Dyna = PixfmtAlphaBlendRgba[BlenderRgba32, DynaRow[ValueT], Pixel32Type]

  app.mRas.clipBox(0, 0, frameWidth, frameHeight)
  app.mRenb.clear(initRgba(0,0,0))

  if app.mRun.status():
    let startTime = cpuTime()

    let N = iround(app.mParticles.value())

    if app.mUseCache.status():
      for i in 0.. <N:
        var
          pixFmt = construct(PixfmtRgba32Dyna, app.mCache[i])
          x = iround(app.mCenter[i].x - app.mRadius[i]) + 1
          y = iround(app.mCenter[i].y - app.mRadius[i]) + 1
        app.mRenbPre.blendFrom(pixFmt, nil, x, y)
    else:
      for i in 0.. <N:
        app.renderParticle(app.mRenb, i, app.mCenter[i].x, app.mCenter[i].y)

    let endTime = cpuTime() - startTime

    let text = "$1 fps" % [(1000.0 / endTime).formatFloat(ffDecimal, 3)]
    app.mTxt.startPoint(10, 35)
    app.mTxt.text(text)
    app.mRas.addPath(app.mPt)
    app.mRen.color(initRgba(1,1,1))
    renderScanLines(app.mRas, app.mSl, app.mRen)

  # Render the controls
  renderCtrl(app.mRas, app.mSl, app.mRenb, app.mParticles)
  renderCtrl(app.mRas, app.mSl, app.mRenb, app.mSpeed)
  renderCtrl(app.mRas, app.mSl, app.mRenb, app.mUseCache)
  renderCtrl(app.mRas, app.mSl, app.mRenb, app.mRun)

  saveBMP32("particle_demo.bmp", app.buffer, frameWidth, frameHeight)

var app = newApp()
app.init()
app.onDraw()