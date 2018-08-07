import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  scanline_p, renderer_scanline, span_allocator, color_rgba,
  span_gouraud_gray, span_solid, calc, dda_line, pixfmt_rgb,
  renderer_base, gamma_functions, span_gouraud_rgba, renderer_scanline]
import math, ctrl/slider, platform/support, strutils

const
  frameWidth = 400
  frameHeight = 320
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mx, my: array[3, float64]
    mdx, mdy: float64
    mIdx: int

    mDilation: SliderCtrl[Rgba8]
    mGamma: SliderCtrl[Rgba8]
    mAlpha: SliderCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mIdx = -1
  result.mDilation = newSliderCtrl[Rgba8](5, 5,    400-5, 11,    not flipY)
  result.mGamma    = newSliderCtrl[Rgba8](5, 5+15, 400-5, 11+15, not flipY)
  result.mAlpha    = newSliderCtrl[Rgba8](5, 5+30, 400-5, 11+30, not flipY)

  result.addCtrl(result.mDilation)
  result.addCtrl(result.mGamma)
  result.addCtrl(result.mAlpha)

  result.mDilation.label("Dilation=$1")
  result.mGamma.label("Linear gamma=$1")
  result.mAlpha.label("Opacity=$1")

  result.mDilation.value(0.175)
  result.mGamma.value(0.809)
  result.mAlpha.value(1.0)

  result.mx = [57.0, 369.0, 143.0]
  result.my = [60.0,170.0,310.0]

proc renderGouraud[Scanline, Rasterizer](app: App, sl: var Scanline, ras: var Rasterizer) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)
    alpha = app.mAlpha.value()
    brc = 1.0'f64
    d = app.mDilation.value()

  type ColorT = getColorT(PixFmt)

  var
    spanGen   = initSpanGouraudRgba[ColorT]()
    spanAlloc = initSpanAllocator[ColorT]()

  ras.gamma(initGammaLinear(0.0, app.mGamma.value()))

  # Single triangle
  #spanGen.colors(initRgba(1,   0,   0,  alpha),
  #                initRgba(0,   1,   0,  alpha),
  #                initRgba(0,   0,   1,  alpha))
  #spanGen.triangle(app.mx[0], app.my[0], app.mx[1], app.my[1], app.mx[2], app.my[2], d)
  #ras.addPath(spanGen)
  #renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)

  # Six triangles
  var
    xc = (app.mx[0] + app.mx[1] + app.mx[2]) / 3.0
    yc = (app.my[0] + app.my[1] + app.my[2]) / 3.0

    x1 = (app.mx[1] + app.mx[0]) / 2 - (xc - (app.mx[1] + app.mx[0]) / 2)
    y1 = (app.my[1] + app.my[0]) / 2 - (yc - (app.my[1] + app.my[0]) / 2)

    x2 = (app.mx[2] + app.mx[1]) / 2 - (xc - (app.mx[2] + app.mx[1]) / 2)
    y2 = (app.my[2] + app.my[1]) / 2 - (yc - (app.my[2] + app.my[1]) / 2)

    x3 = (app.mx[0] + app.mx[2]) / 2 - (xc - (app.mx[0] + app.mx[2]) / 2)
    y3 = (app.my[0] + app.my[2]) / 2 - (yc - (app.my[0] + app.my[2]) / 2)

  spanGen.colors(initRgba(1,   0,   0,    alpha),
                 initRgba(0,   1,   0,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(app.mx[0], app.my[0], app.mx[1], app.my[1], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   1,   0,    alpha),
                 initRgba(0,   0,   1,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(app.mx[1], app.my[1], app.mx[2], app.my[2], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   0,   1,   alpha),
                 initRgba(1,   0,   0,   alpha),
                 initRgba(brc, brc, brc, alpha))
  spanGen.triangle(app.mx[2], app.my[2], app.mx[0], app.my[0], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)


  brc = 1-brc
  spanGen.colors(initRgba(1,   0,   0,    alpha),
                  initRgba(0,   1,   0,    alpha),
                  initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(app.mx[0], app.my[0], app.mx[1], app.my[1], x1, y1, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   1,   0,    alpha),
                 initRgba(0,   0,   1,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(app.mx[1], app.my[1], app.mx[2], app.my[2], x2, y2, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   0,   1,    alpha),
                 initRgba(1,   0,   0,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(app.mx[2], app.my[2], app.mx[0], app.my[0], x3, y3, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)
    sl  = initScanlineU8()
    ras = initRasterizerScanlineAA()

  rb.clear(initRgba(1,1,1))

  app.renderGouraud(sl, ras)

  ras.gamma(initGammaNone())
  renderCtrl(ras, sl, rb, app.mDilation)
  renderCtrl(ras, sl, rb, app.mGamma)
  renderCtrl(ras, sl, rb, app.mAlpha)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseRight in flags:
    var
      sl  = initScanlineU8()
      ras = initRasterizerScanlineAA()

    app.startTimer()
    for i in 0..<100:
      app.renderGouraud(sl, ras)

    var
      t1 = app.elapsedTime()
      buf = "Time=$1 ms" % [t1.formatFloat(ffDecimal, 3)]
    app.message(buf)


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

method onKey(app: App, x, y, key: int, flags: InputFlags) =
  var
    dx = 0.0
    dy = 0.0

  case key.KeyCode
  of key_left:  dx = -0.1
  of key_right: dx =  0.1
  of key_up:    dy =  0.1
  of key_down:  dy = -0.1
  else: discard

  app.mx[0] += dx
  app.my[0] += dy
  app.mx[1] += dx
  app.my[1] += dy
  app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Gouraud Shading")

  if app.init(frameWidth, frameHeight, {window_resize}, "gouraud"):
    return app.run()

  result = 1

discard main()
