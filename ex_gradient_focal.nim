import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_span_allocator, agg_span_gradient
import agg_gradient_lut, agg_gamma_lut, agg_span_interpolator_linear
import agg_basics, agg_color_rgba, agg_pixfmt_rgb, agg_renderer_base
import nimBMP, agg_trans_affine, agg_ellipse, agg_conv_stroke
import agg_conv_transform, times, agg_gsv_text, strutils

{.passC: "-I./agg-2.5/include".}
{.compile: "test_gradient.cpp".}
{.compile: "agg_trans_affine2.cpp".}
{.passL: "-lstdc++".}

proc test_gradient() {.importc.}
proc get_gradient(i: cint, c: var Rgba8) {.importc.}
proc main_gradient(): cstring {.importc.}
proc print_gradient() {.importc.}
const
  frameWidth = 600
  frameHeight = 400
  pixWidth = 3

type
  ValueT = uint8

gradientLut(ColorFunc, ColorInterpolatorRgba8, 1024)

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


proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    alloc  = initSpanAllocator[Rgba8]()
    mGamma = 1.8
    oldGamma = mGamma
    gammaLut = initGammaLut8(mGamma)
    gradientLut = initColorFunc()
    initialWidth = frameWidth.float64
    initialHeight = frameHeight.float64
    mouseX = initialWidth / 2.0
    mouseY = initialHeight / 2.0
    height = initialHeight
    width  = initialWidth

  buildGradientLut(gradientLut, gammaLut)
  rb.clear(initRgba(1, 1, 1))

  # When Gamma changes rebuild the gamma and gradient LUTs
  if oldGamma != mGamma:
    gammaLut.gamma(mGamma)
    buildGradientLut(gradientLut, gammaLut)
    oldGamma = mGamma

  # Gradient center. All gradient functions assume the
  # center being in the origin (0,0) and you can't
  # change it. But you can apply arbitrary transformations
  # to the gradient (see below).
  var
    cx = initialWidth / 2.0
    cy = initialHeight / 2.0
    r = 100.0

  # Focal center. Defined in the gradient coordinates,
  # that is, with respect to the origin (0,0)
  var
    fx = mouseX - cx
    fy = mouseY - cy
    gradientFunc = initGradientRadialFocus(r, fx, fy)
    gradientAdaptor = initGradientReflectAdaptor(gradientFunc)
    gradientMtx = initTransAffine()
    #transAffineResizing = initTransAffine()

  # Making the affine matrix. Move to (cx,cy),
  # apply the resizing transformations and invert
  # the matrix. Gradients and images always assume the
  # inverse transformations.
  gradientMtx.translate(cx, cy)
  #gradientMtx *= transAffineResizing
  gradientMtx.invert()

  var
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanGradient = initSpanGradient(spanInterpolator, gradientAdaptor, gradientLut, 0, r)

  # Form the simple rectangle
  ras.reset()
  ras.moveToD(0,0)
  ras.lineToD(width, 0)
  ras.lineToD(width, height)
  ras.lineToD(0, height)

  # Render the gradient to the whole screen and measure the time
  let startTime = cpuTime()
  renderScanlinesAA(ras, sl, rb, alloc, spanGradient)

  let t3 = cpuTime() - startTime

  # Draw the transformed circle that shows the gradient boundary
  var
    e = initEllipse(cx, cy, r, r)
    estr = initConvStroke(e)
    #etrans = initConvTransform(estr, transAffineResizing)

  ras.addPath(estr)
  renderScanlinesAASolid(ras, sl, rb, initRgba(1,1,1))

  var t = initGsvText()
  t.size(10.0)
  var pt = initConvStroke(t)
  pt.width(1.5)

  var buf = "$1 ms" % [$(t3 * 1000)]

  t.startPoint(10.0, 35.0)
  t.text(buf)
  ras.addPath(pt)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0,0,0))

  # Apply the inverse gamma to the whole buffer
  # (transform the colors to the perceptually uniform space)
  pf.applyGammaInv(gammaLut)
  saveBMP24("gradient_focal.bmp", buffer, frameWidth, frameHeight)

onDraw()
