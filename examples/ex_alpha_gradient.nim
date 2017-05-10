import agg / [basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  renderer_scanline, span_gradient, span_gradient_alpha, span_interpolator_linear,
  span_allocator, span_converter, ellipse, pixfmt_rgb, vcgen_stroke, color_rgba,
  renderer_base, trans_affine, calc]
import random, ctrl.spline, platform.support, math

const
  frameWidth = 400
  frameHeight = 320
  flipY = true

type
  PixFmt = PixFmtBgr24
  ColorT = getColorT(PixFmt)
  ValueT = getValueT(ColorT)

  App = ref object of PlatformSupport
    mX, mY: array[3, float64]
    mDx, mDy: float64
    mIdx: int
    mAlpha: SplineCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mIdx = -1
  result.mAlpha = newSplineCtrl[Rgba8](2,  2,  200, 30,  6, not flipY)
  result.mX = [257.0, 369.0, 143.0]
  result.mY = [60.0, 170.0, 310.0]

  result.mAlpha.point(0, 0.0,     0.0)
  result.mAlpha.point(1, 1.0/5.0, 1.0 - 4.0/5.0)
  result.mAlpha.point(2, 2.0/5.0, 1.0 - 3.0/5.0)
  result.mAlpha.point(3, 3.0/5.0, 1.0 - 2.0/5.0)
  result.mAlpha.point(4, 4.0/5.0, 1.0 - 1.0/5.0)
  result.mAlpha.point(5, 1.0,     1.0)
  result.mAlpha.updateSpline()
  result.addCtrl(result.mAlpha)

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

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    w      = app.width()
    h      = app.height()
    para   = [app.mX[0], app.mY[0], app.mX[1], app.mY[1], app.mX[2], app.mY[2]]

  rb.clear(initRgba(1,1,1))
  # Draw some background
  #randomize()
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
    alphaArray[i] = ValueT(app.mAlpha.value(i.float64 / 255.0) * baseMask)

  var ell = initEllipse(w/2.0, h/2.0, 150.0, 150.0, 100)
  ras.addPath(ell)

  # Render the circle with gradient plus alpha-gradient
  renderScanlinesAA(ras, sl, rb, spanAllocator, spanConv)

  # Draw the control points and the parallelogram
  var colorPnt = initRgba(0, 0.4, 0.4, 0.31)

  for i in 0..2:
    ell.init(app.mX[i], app.mY[i], 5.0, 5.0, 20)
    ras.addPath(ell)
    renderScanlinesAASolid(ras, sl, rb, colorPnt)

  var stroke = initVcgenStroke()
  stroke.addVertex(app.mx[0], app.my[0], pathCmdMoveTo)
  stroke.addVertex(app.mx[1], app.my[1], pathCmdLineTo)
  stroke.addVertex(app.mx[2], app.my[2], pathCmdLineTo)
  stroke.addVertex(app.mx[0]+app.mx[2]-app.mx[1], app.my[0]+app.my[2]-app.my[1], pathCmdLineTo)
  stroke.addVertex(0, 0, pathCmdEndPoly or pathFlagsClose)
  ras.addPath(stroke)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0, 0, 0))

  renderCtrl(ras, sl, rb, app.mAlpha)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    var i = 0
    while i < 3:
      if sqrt((x-app.mX[i]) * (x-app.mX[i]) + (y-app.mY[i]) * (y-app.mY[i])) < 10.0:
        app.mDx = x - app.mX[i]
        app.mDy = y - app.mY[i]
        app.mIdx = i
        break
      inc i
    if i == 3:
      if pointInTriangle(app.mX[0], app.mY[0],
         app.mX[1], app.mY[1], app.mX[2], app.mY[2], x, y):
        app.mDx = x - app.mX[0]
        app.mDy = y - app.mY[0]
        app.mIdx = 3

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    if app.mIdx == 3:
      let dx = x - app.mDx
      let dy = y - app.mDy
      app.mX[1] -= app.mX[0] - dx
      app.mY[1] -= app.mY[0] - dy
      app.mX[2] -= app.mX[0] - dx
      app.mY[2] -= app.mY[0] - dy
      app.mX[0] = dx
      app.mY[0] = dy
      app.forceRedraw()
      return

    if app.mIdx >= 0:
      app.mX[app.mIdx] = x - app.mDx
      app.mY[app.mIdx] = y - app.mDy
      app.forceRedraw()
  else:
    app.onMouseButtonUp(x.int, y.int, flags)

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.mIdx = -1

method onKey*(app: App, x, y, key: int, flags: InputFlags) =
  var
    dx = 0.0
    dy = 0.0
  case KeyCode(key)
  of key_left:  dx = -0.1
  of key_right: dx =  0.1
  of key_up:    dy =  0.1
  of key_down:  dy = -0.1
  else: discard

  app.mX[0] += dx
  app.mY[0] += dy
  app.mX[1] += dx
  app.mY[1] += dy
  app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Alpha channel gradient")

  if app.init(frameWidth, frameHeight, {window_resize}, "alpha_gradient"):
    return app.run()

  result = 1

discard main()
