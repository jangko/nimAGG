import agg/[ellipse, trans_affine, conv_transform, rendering_buffer,
  pixfmt_rgb, span_allocator, span_image_filter_rgb, image_accessors,
  span_interpolator_linear, span_converter, scanline_u, renderer_scanline,
  rasterizer_scanline_aa, pixfmt_rgb, color_rgba, renderer_base, basics]
import ctrl/spline, random, strutils, os, platform/support

const
  arraySize = 256 * 3

type
  SpanConvBrightnessAlphaRgb8 = object
    alphaArray: ptr uint8

proc initSpanConvBrightnessAlphaRgb8(alphaArray: ptr uint8): SpanConvBrightnessAlphaRgb8 =
  result.alphaArray = alphaArray

proc prepare(self: SpanConvBrightnessAlphaRgb8) = discard

proc generate(self: SpanConvBrightnessAlphaRgb8, span: ptr Rgba8, x, y, len: int) =
  var
    len = len
    span = span

  doWhile len != 0:
    span.a = self.alphaArray[(span.r + span.g + span.b).int]
    inc span
    dec len

const
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    alpha: SplineCtrl[Rgba8]
    x, y, rx, ry: array[50, float64]
    colors: array[50, Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.alpha = newSplineCtrl[Rgba8](2,  2,  200, 30,  6, not flipY)
  result.addCtrl(result.alpha)
  result.alpha.value(0, 1.0)
  result.alpha.value(1, 1.0)
  result.alpha.value(2, 1.0)
  result.alpha.value(3, 0.5)
  result.alpha.value(4, 0.5)
  result.alpha.value(5, 1.0)
  result.alpha.updateSpline()

method onInit(app: App) =
  for i in 0..<50:
    app.x[i] = rand(app.width())
    app.y[i] = rand(app.height())
    app.rx[i] = rand(60.0) + 10.0
    app.ry[i] = rand(60.0) + 10.0
    app.colors[i] = initRgba8(rand(0xFF), rand(0xFF), rand(0xFF), rand(0xFF))

method onDraw(app: App) =
  var
    pf = construct(PixFmt, app.rbufWindow())
    rb = initRendererBase(pf)
    mtx = initTransAffine()
    ras = initRasterizerScanlineAA()
    sl = initScanlineU8()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  mtx *= transAffineTranslation(-app.initialWidth()/2.0, -app.initialHeight()/2.0)
  mtx *= transAffineRotation(10.0 * pi / 180.0)
  mtx *= transAffineTranslation(app.initialWidth()/2.0, app.initialHeight()/2.0)
  mtx *= transAffineResizing(app)

  var
    brightnessAlphaArray: array[arraySize, uint8]
    colorAlpha = initSpanConvBrightnessAlphaRgb8(brightnessAlphaArray[0].addr)
    imgMtx  = mtx
    sa      = initSpanAllocator[Rgba8]()
    inter   = initSpanInterpolatorLinear(imgMtx)
    imgPixf = initPixfmtRgb24(app.rbufImg(0))
    imgSrc  = initImageAccessorClip(imgPixf, initRgba(0,0,0,0))
    sg      = initSpanImageFilterRgbBilinear(imgSrc, inter)
    sc      = initSpanConverter(sg, colorAlpha)
    ell     = initEllipse()

  imgMtx.invert()

  for i in 0..<arraySize:
    brightnessAlphaArray[i] = (app.alpha.value(float64(i) / float(arraySize)) * 255.0).uint8

  for i in 0..<50:
    ell.init(app.x[i], app.y[i], app.rx[i], app.ry[i], 50)
    ras.addPath(ell)
    renderScanlinesAAsolid(ras, sl, rb, app.colors[i])

  ell.init(app.initialWidth() / 2.0,
           app.initialHeight() / 2.0,
           app.initialWidth() / 1.9,
           app.initialHeight() / 1.9, 200)

  var tr = initConvTransform(ell, mtx)

  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rb, sa, sc)

  renderCtrl(ras, sl, rb, app.alpha)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Image Affine Transformations with Alpha-function")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  let
    frameWidth = app.rbufImg(0).width()
    frameHeight = app.rbufImg(0).height()

  if app.init(frameWidth, frameHeight, {window_resize}, "image_alpha"):
    return app.run()

  result = 1

discard main()
