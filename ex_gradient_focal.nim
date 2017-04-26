import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_span_allocator, agg_span_gradient
import agg_gradient_lut, agg_gamma_lut, agg_span_interpolator_linear
import agg_basics, agg_color_rgba, agg_pixfmt_rgb, agg_renderer_base
import agg_trans_affine, agg_ellipse, agg_conv_stroke, agg_platform_support
import agg_conv_transform, times, agg_gsv_text, strutils, ctrl_slider

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

gradientLut(ColorFunc, ColorInterpolatorRgba8, 1024)

type
  PixFmt = PixFmtBgr24
  ColorT = getColorT(PixFmt)

  App = ref object of PlatformSupport
    mGamma: SliderCtrl[Rgba8]
    sl: ScanlineU8
    ras: RasterizerScanlineAA
    alloc: SpanAllocator[ColorT]
    mGradientLut: ColorFunc
    mGammaLut: GammaLut8
    mouseX, mouseY: float64
    mOldGamma: float64

proc buildGradientLut(gradientLut: var ColorFunc, gammaLut: GammaLut8) =

  gradientLut.removeAll()

  gradientLut.addColor(0.0, rgba8GammaDir(initRgba8(0, 255, 0),   gammaLut))
  gradientLut.addColor(0.2, rgba8GammaDir(initRgba8(120, 0, 0),   gammaLut))
  gradientLut.addColor(0.7, rgba8GammaDir(initRgba8(120, 120, 0), gammaLut))
  gradientLut.addColor(1.0, rgba8GammaDir(initRgba8(0, 0, 255),   gammaLut))

  #gradientLut.addColor(0.0, rgba8fromWavelength(380, mGamma))
  #gradientLut.addColor(0.1, rgba8fromWavelength(420, mGamma))
  #gradientLut.addColor(0.2, rgba8fromWavelength(460, mGamma))
  #gradientLut.addColor(0.3, rgba8fromWavelength(500, mGamma))
  #gradientLut.addColor(0.4, rgba8fromWavelength(540, mGamma))
  #gradientLut.addColor(0.5, rgba8fromWavelength(580, mGamma))
  #gradientLut.addColor(0.6, rgba8fromWavelength(620, mGamma))
  #gradientLut.addColor(0.7, rgba8fromWavelength(660, mGamma))
  #gradientLut.addColor(0.8, rgba8fromWavelength(700, mGamma))
  #gradientLut.addColor(0.9, rgba8fromWavelength(740, mGamma))
  #gradientLut.addColor(1.0, rgba8fromWavelength(780, mGamma))

  gradientLut.buildLut()

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mGamma = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mouseX = 200
  result.mouseY = 200

  result.mGamma.setRange(0.5, 2.5)
  result.mGamma.value(1.8)
  result.mGamma.label("Gamma = $1")
  result.addCtrl(result.mGamma)
  result.mGamma.noTransform()

  result.ras   = initRasterizerScanlineAA()
  result.sl    = initScanlineU8()
  result.alloc = initSpanAllocator[Rgba8]()

  result.mGradientLut = initColorFunc()
  result.mGammaLut = initGammaLut8(result.mGamma.value())
  result.mOldGamma = result.mGamma.value()

  buildGradientLut(result.mGradientLut, result.mGammaLut)

method onInit(app: App) =
  app.mouseX = app.initialWidth() / 2.0
  app.mouseY = app.initialHeight() / 2.0

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)

  rb.clear(initRgba(1, 1, 1))

  # When Gamma changes rebuild the gamma and gradient LUTs
  if app.mOldGamma != app.mGamma.value():
    app.mGammaLut.gamma(app.mGamma.value())
    buildGradientLut(app.mGradientLut, app.mGammaLut)
    app.mOldGamma = app.mGamma.value()

  # Gradient center. All gradient functions assume the
  # center being in the origin (0,0) and you can't
  # change it. But you can apply arbitrary transformations
  # to the gradient (see below).
  var
    cx = app.initialWidth() / 2.0
    cy = app.initialHeight() / 2.0
    r = 100.0

  # Focal center. Defined in the gradient coordinates,
  # that is, with respect to the origin (0,0)
  var
    fx = app.mouseX - cx
    fy = app.mouseY - cy
    gradientFunc = initGradientRadialFocus(r, fx, fy)
    gradientAdaptor = initGradientReflectAdaptor(gradientFunc)
    gradientMtx = initTransAffine()

  # Making the affine matrix. Move to (cx,cy),
  # apply the resizing transformations and invert
  # the matrix. Gradients and images always assume the
  # inverse transformations.
  gradientMtx.translate(cx, cy)
  gradientMtx *= transAffineResizing(app)
  gradientMtx.invert()

  var
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanGradient = initSpanGradient(spanInterpolator, gradientAdaptor, app.mGradientLut, 0, r)

  # Form the simple rectangle
  app.ras.reset()
  app.ras.moveToD(0,0)
  app.ras.lineToD(app.width(), 0)
  app.ras.lineToD(app.width(), app.height())
  app.ras.lineToD(0, app.height())

  # Render the gradient to the whole screen and measure the time
  app.startTimer()
  renderScanlinesAA(app.ras, app.sl, rb, app.alloc, spanGradient)

  let t3 = app.elapsedTime()

  # Draw the transformed circle that shows the gradient boundary
  var
    e = initEllipse(cx, cy, r, r)
    estr = initConvStroke(e)
    etrans = initConvTransform(estr, transAffineResizing(app))

  app.ras.addPath(etrans)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(1,1,1))

  var t = initGsvText()
  t.size(10.0)
  var pt = initConvStroke(t)
  pt.width(1.5)

  var buf = "$1 ms" % [$t3]

  t.startPoint(10.0, 35.0)
  t.text(buf)
  app.ras.addPath(pt)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(0,0,0))
  
  renderCtrl(app.ras, app.sl, rb, app.mGamma)
  
  # Apply the inverse gamma to the whole buffer
  # (transform the colors to the perceptually uniform space)
  pf.applyGammaInv(app.mGammaLut)

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mouseX = x.float64
    app.mouseY = y.float64
    transAffineResizing(app).inverseTransform(app.mouseX, app.mouseY)
    app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mouseX = x.float64
    app.mouseY = y.float64
    transAffineResizing(app).inverseTransform(app.mouseX, app.mouseY)
    app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. PDF linear and radial gradients")

  if app.init(frameWidth, frameHeight, {window_resize}, "gradient_focal"):
    return app.run()

  result = 1

discard main()
