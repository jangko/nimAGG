import agg/[basics, rendering_buffer, rasterizer_scanline_aa,
  scanline_u, renderer_scanline, pixfmt_rgb, trans_affine,
  conv_transform, conv_segmentator, renderer_base, color_rgba]
import ctrl.slider, ctrl.cbox, math, platform.support

type
  TransformedControl[Ctrl, Pipeline] = object
    ctrl: Ctrl
    pipeline: ptr Pipeline

proc initTransformedControl[Ctrl, Pipeline](ctrl: Ctrl,
  pl: var Pipeline): TransformedControl[Ctrl, Pipeline] =

  result.ctrl = ctrl
  result.pipeline = pl.addr

proc numPaths[C, P](self: TransformedControl[C, P]): int =
  self.ctrl.numPaths()

proc rewind[C, P](self: var TransformedControl[C, P], pathId: int) =
  self.pipeline[].rewind(pathId)

proc vertex[C, P](self: var TransformedControl[C, P], x, y: var float64): uint =
  self.pipeline[].vertex(x, y)

proc color[C, P](self: TransformedControl[C, P], i: int): auto =
  self.ctrl.color(i)

type
  TransPolar = object
    mBaseAngle: float64
    mBaseScale: float64
    mBaseX: float64
    mBaseY: float64
    mTranslationX: float64
    mTranslationY: float64
    mSpiral: float64

proc initTransPolar(): TransPolar =
  result.mBaseAngle = 1.0
  result.mBaseScale = 1.0
  result.mBaseX = 0.0
  result.mBaseY = 0.0
  result.mTranslationX = 0.0
  result.mTranslationY = 0.0
  result.mSpiral = 0.0

proc baseScale(self: var TransPolar, v: float64) =
  self.mBaseScale = v

proc fullCircle(self: var TransPolar, v: float64) =
  self.mBaseAngle = 2.0 * pi / v

proc baseOffset(self: var TransPolar, dx, dy: float64) =
  self.mBaseX = dx; self.mBaseY = dy

proc translation(self: var TransPolar, dx, dy: float64) =
  self.mTranslationX = dx
  self.mTranslationY = dy

proc spiral(self: var TransPolar, v: float64) =
  self.mSpiral = v

proc transform(self: TransPolar, x, y: var float64) =
  var
    x1 = (x + self.mBaseX) * self.mBaseAngle
    y1 = (y + self.mBaseY) * self.mBaseScale + (x * self.mSpiral)

  x = cos(x1) * y1 + self.mTranslationX
  y = sin(x1) * y1 + self.mTranslationY

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    slider1, spiral, baseY: SliderCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.slider1 = newSliderCtrl[Rgba8](10, 10,    600-10, 17, not flipY)
  result.spiral = newSliderCtrl[Rgba8](10, 10+20, 600-10, 17+20, not flipY)
  result.baseY = newSliderCtrl[Rgba8](10, 10+40, 600-10, 17+40, not flipY)

  result.addCtrl(result.slider1)
  result.addCtrl(result.spiral)
  result.addCtrl(result.baseY)

  result.slider1.setRange(0.0, 100.0)
  result.slider1.num_steps(5)
  result.slider1.value(32.0)
  result.slider1.label("Some Value=$1")
  result.spiral.label("Spiral=$1")
  result.spiral.setRange(-0.1, 0.1)
  result.spiral.value(0.0)
  result.baseY.label("Base Y=$1")
  result.baseY.setRange(50.0, 200.0)
  result.baseY.value(120.0)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    width  = app.width()
    height = app.height()

  rb.clear(initRgba(1,1,1))
  renderCtrl(ras, sl, rb, app.slider1)
  renderCtrl(ras, sl, rb, app.spiral)
  renderCtrl(ras, sl, rb, app.baseY)

  var
    trans = initTransPolar()

  trans.fullCircle(-600)
  trans.baseScale(-1.0)
  trans.baseOffset(0.0, app.baseY.value())
  trans.translation(width / 2.0, height / 2.0 + 30.0)
  trans.spiral(-app.spiral.value())

  var
    segm = initConvSegmentator(app.slider1)
    pipeline = initConvTransform(segm, trans)
    ctrl = initTransformedControl(app.slider1, pipeline)

  renderCtrl(ras, sl, rb, ctrl)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Polar Transformer")

  if app.init(frameWidth, frameHeight, {window_resize}, "trans_polar"):
    return app.run()

  result = 1

discard main()
