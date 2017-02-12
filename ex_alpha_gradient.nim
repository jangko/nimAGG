import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_span_gradient, agg_span_gradient_alpha
import agg_span_interpolator_linear, agg_span_allocator, agg_span_converter
import agg_ellipse, agg_pixfmt_rgb, agg_vcgen_stroke, agg_color_rgba
import nimBMP, random, agg_renderer_base, agg_trans_affine

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3

type
  ValueT = uint8
  ColorT = Rgba8

proc fillColorArray[CA,CB](arr: var openArray[CA], a, b, c: CB) =
  when CA is not CB:
    var
      a = construct(CA, a)
      b = construct(CA, b)
      c = construct(CA, c)

  for i in 0..127:
    arr[i] = a.gradient(b, i.float64 / 128.0)

  for i in 128..255:
    arr[i] = b.gradient(c, float64(i - 128) / 128.0)

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    w      = frameWidth.float64
    h      = frameHeight.float64
    mx     = [257.0, 369.0, 143.0]
    my     = [60.0, 170.0, 310.0]
    para   = [mx[0], my[0], mx[1], my[1], mx[2], my[2]]

  rb.clear(initRgba(1,1,1))
  # Draw some background
  randomize()
  for i in 0..99:
    var
      ell = initEllipse(random(w), random(h), random(60.0) + 5.0, random(60.0) + 5.0, 50)
      clr = initRgba(random(1.0), random(1.0), random(1.0), random(1.0) / 2.0)

    ras.addPath(ell)
    renderScanlinesAAsolid(ras, sl, rb, clr)

  var
    gradientFunc: GradientCircle
    alphaFunc: GradientXY
    gradientMtx =  initTransAffine()
    alphaMtx = initTransAffine()
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanInterpolatorAlpha = initSpanInterpolatorLinear(alphaMtx)
    spanAllocator = initSpanAllocator[ColorT]()
    colorArray: array[256, ColorT]
    alphaArray: array[256, ValueT]
    spanGradient = initSpanGradient(spanInterpolator, gradientFunc, colorArray, 0, 150)
    spanGradientAlpha = initSpanGradientAlpha(spanInterpolatorAlpha, alphaFunc, alphaArray, 0, 100)
    spanConv = initSpanConverter(spanGradient, spanGradientAlpha)

  gradientMtx *= transAffineScaling(0.75, 1.2)
  gradientMtx *= transAffineRotation(-pi/3.0)
  gradientMtx *= transAffineTranslation(w/2.0, h/2.0)
  gradientMtx.invert()

  alphaMtx = parlToRect(para, -100.0, -100.0, 100.0, 100.0)
  fillColorArray(colorArray,
    initRgba(0,    0.19, 0.19),
    initRgba(0.7,  0.7,  0.19),
    initRgba(0.31, 0.0,   0.0))

  const
    baseMask = getBaseMask(ColorT).float64

  for i in 0..255:
    alphaArray[i] = ValueT((i.float64 / 255.0) * baseMask)

  var ell = initEllipse(w/2.0, h/2.0, 150.0, 150.0, 100)
  ras.addPath(ell)

  # Render the circle with gradient plus alpha-gradient
  renderScanlinesAA(ras, sl, rb, spanAllocator, spanConv)

  # Draw the control points and the parallelogram
  var colorPnt = initRgba(0, 0.4, 0.4, 0.31)

  for i in 0..2:
    ell.init(mx[i], my[i], 5.0, 5.0, 20)
    ras.addPath(ell)
    renderScanlinesAASolid(ras, sl, rb, colorPnt)


  var stroke = initVcgenStroke()
  stroke.addVertex(mx[0], my[0], pathCmdMoveTo)
  stroke.addVertex(mx[1], my[1], pathCmdLineTo)
  stroke.addVertex(mx[2], my[2], pathCmdLineTo)
  stroke.addVertex(mx[0]+mx[2]-mx[1], my[0]+my[2]-my[1], pathCmdLineTo)
  stroke.addVertex(0, 0, pathCmdEndPoly or pathFlagsClose)
  ras.addPath(stroke)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0, 0, 0))

  saveBMP24("alpha_gradient.bmp", buffer, frameWidth, frameHeight)

onDraw()
