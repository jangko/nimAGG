import agg/[basics, rendering_buffer, rasterizer_scanline_aa,
  rasterizer_outline, scanline_p, scanline_bin, renderer_scanline,
  renderer_primitives, pixfmt_rgb, renderer_base, path_storage,
  color_rgba, gamma_functions, calc]
import platform/support, ctrl/slider, ctrl/cbox, strutils, math

const
  frameWidth = 500
  frameHeight = 330
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mx, my: array[3, float64]
    mdx, mdy: float64
    midx: int
    mGamma: SliderCtrl[Rgba8]
    mAlpha: SliderCtrl[Rgba8]
    mTest: CboxCtrl[Rgba8]
    ras: RasterizerScanlineAA
    slp8: ScanlineP8
    slbin: ScanlineBin

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.midx = -1
  result.mGamma = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 130 + 150.0, 10.0 + 8.0 + 4.0, not flipY)
  result.mAlpha = newSliderCtrl[Rgba8](130 + 150.0 + 10.0, 10.0 + 4.0, 500 - 10.0, 10.0 + 8.0 + 4.0, not flipY)
  result.mTest  = newCboxCtrl[Rgba8](130 + 10.0, 10.0 + 4.0 + 16.0,    "Test Performance", not flipY)

  result.mx = [100.0+120.0, 369.0+120.0, 143.0+120.0]
  result.my = [60.0, 170.0, 310.0]

  result.addCtrl(result.mGamma)
  result.addCtrl(result.mAlpha)
  result.addCtrl(result.mTest)

  result.mGamma.setRange(0.0, 1.0)
  result.mGamma.value(0.5)
  result.mGamma.label("Gamma=$1")
  result.mGamma.noTransform()

  result.mAlpha.setRange(0.0, 1.0)
  result.mAlpha.value(1.0)
  result.mAlpha.label("Alpha=$1")
  result.mAlpha.noTransform()

  result.mTest.noTransform()

  result.ras    = initRasterizerScanlineAA()
  result.slp8   = initScanlineP8()
  result.slbin  = initScanlineBin()

proc drawAliased(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren_bin= initRendererScanlineBinSolid(rb)
    ren_pr = initRendererPrimitives(rb)
    ras_ln = initRasterizerOutline(ren_pr)
    path   = initPathStorage()

  # draw aliased
  path.removeAll()
  path.moveTo(app.mx[0] - 200, app.my[0])
  path.lineTo(app.mx[1] - 200, app.my[1])
  path.lineTo(app.mx[2] - 200, app.my[2])
  path.closePolygon()

  ren_bin.color(initRgba(0.1, 0.5, 0.7, app.mAlpha.value()))
  app.ras.gamma(initGammaThreshold(app.mGamma.value()))
  app.ras.addPath(path)
  renderScanlines(app.ras, app.slbin, ren_bin)

  # Drawing an outline with subpixel accuracy (aliased)
  ren_pr.lineColor(initRgba(0.0, 0.0, 0.0, app.mAlpha.value()))
  ras_ln.addPath(path)

proc drawAntiAliased(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren_aa = initRendererScanlineAASolid(rb)
    path   = initPathStorage()

  # draw anti aliased
  path.moveTo(app.mx[0], app.my[0])
  path.lineTo(app.mx[1], app.my[1])
  path.lineTo(app.mx[2], app.my[2])
  path.closePolygon()

  ren_aa.color(initRgba(0.7, 0.5, 0.1, app.mAlpha.value()))
  app.ras.gamma(initGammaPower(app.mGamma.value() * 2.0))
  app.ras.addPath(path)
  renderScanlines(app.ras, app.slp8, ren_aa)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)

  rb.clear(initRgba(1, 1, 1))

  app.drawAntiAliased()
  app.drawAliased()

  var ras_aa = initRasterizerScanlineAA()
  renderCtrl(ras_aa, app.slp8, rb, app.mGamma)
  renderCtrl(ras_aa, app.slp8, rb, app.mAlpha)
  renderCtrl(ras_aa, app.slp8, rb, app.mTest)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    var i = 0
    while i < 3:
      if sqrt((x-app.mX[i]) * (x-app.mX[i]) + (y-app.mY[i]) * (y-app.mY[i])) < 20.0 or
         sqrt((x-app.mx[i]+200) * (x-app.mx[i]+200) + (y-app.my[i]) * (y-app.my[i]) ) < 20.0:
        app.mDx = x - app.mX[i]
        app.mDy = y - app.mY[i]
        app.mIdx = i
        break
      inc i

    if i == 3:
      if pointInTriangle(app.mX[0], app.mY[0],
         app.mX[1], app.mY[1], app.mX[2], app.mY[2], x, y) or
         pointInTriangle(app.mx[0] - 200, app.my[0],
         app.mx[1] - 200, app.my[1], app.mx[2] - 200, app.my[2], x, y):

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

method onCtrlChange(app: App) =
  if app.mTest.status():
    app.onDraw()
    app.updateWindow()
    app.mTest.status(false)

    app.startTimer()
    for i in 0..<1000:
      app.drawAliased()
    let t1 = app.elapsedTime()

    app.startTimer()
    for i in 0..<1000:
      app.drawAntiAliased()
    let t2 = app.elapsedTime()

    app.updateWindow()
    var buf = "Time Aliased=$1ms Time Anti-Aliased=$1ms" % [t1.formatFloat(ffDecimal, 3),
    t2.formatFloat(ffDecimal, 3)]

    app.message(buf)

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
  app.caption("AGG Example. Rasterizer")

  if app.init(frameWidth, frameHeight, {}, "rasterizer"):
    return app.run()

  result = 1

discard main()
