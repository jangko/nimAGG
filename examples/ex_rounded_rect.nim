import agg/[basics, rendering_buffer, scanline_p, renderer_base,
  pixfmt_rgb, gamma_lut, ellipse, rounded_rect, color_rgba,
  conv_stroke, rasterizer_scanline_aa, renderer_scanline]
import ctrl.slider, ctrl.cbox, platform.support, math

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24Gamma[GammaLut8]

  App = ref object of PlatformSupport
    mx, my: array[2, float64]
    mdx, mdy: float64
    midx: int
    mRadius: SliderCtrl[Rgba8]
    mGamma: SliderCtrl[Rgba8]
    mOffset: SliderCtrl[Rgba8]
    mWhiteOnBlack: CboxCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.midx = -1
  result.mRadius = newSliderCtrl[Rgba8](10, 10, 600-10,   19,     not flipY)
  result.mGamma  = newSliderCtrl[Rgba8](10, 10+20, 600-10, 19+20, not flipY)
  result.mOffset = newSliderCtrl[Rgba8](10, 10+40, 600-10, 19+40, not flipY)
  result.mWhiteOnBlack = newCboxCtrl[Rgba8](10, 10+60, "White on black")

  result.mx[0] = 100
  result.my[0] = 100
  result.mx[1] = 500
  result.my[1] = 350

  result.addCtrl(result.mRadius)
  result.addCtrl(result.mGamma)
  result.addCtrl(result.mOffset)
  result.addCtrl(result.mWhiteOnBlack)

  result.mGamma.label("gamma=$1")
  result.mGamma.setRange(0.0, 3.0)
  result.mGamma.value(1.8)

  result.mRadius.label("radius=$1")
  result.mRadius.setRange(0.0, 50.0)
  result.mRadius.value(25.0)

  result.mOffset.label("subpixel offset=$1")
  result.mOffset.setRange(-2.0, 3.0)

  result.mWhiteOnBlack.textColor(initRgba8(127, 127, 127))
  result.mWhiteOnBlack.inactiveColor(initRgba8(127, 127, 127))

method onDraw(app: App) =
  var
    gamma  = initGammaLut8(app.mGamma.value())
    pixf   = construct(PixFmt, app.rbufWindow(), gamma)
    rb     = initRendererBase(pixf)
    ren    = initRendererScanlineAASolid(rb)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    e: Ellipse

  rb.clear(if app.mWhiteOnBlack.status(): initRgba(0,0,0) else: initRgba(1,1,1))

  # Render two "control" circles
  ren.color(initRgba8(127,127,127))
  e.init(app.mx[0], app.my[0], 3, 3, 16)
  ras.addPath(e)
  renderScanlines(ras, sl, ren)

  e.init(app.mx[1], app.my[1], 3, 3, 16)
  ras.addPath(e)
  renderScanlines(ras, sl, ren)

  # Creating a rounded rectangle
  var d = app.mOffset.value()
  var r = initRoundedRect(app.mx[0]+d, app.my[0]+d, app.mx[1]+d, app.my[1]+d, app.mRadius.value())
  r.normalizeRadius()

  # Drawing as an outline
  var p = initConvStroke(r)
  p.width(1.0)
  ras.addPath(p)
  ren.color(if app.mWhiteOnBlack.status(): initRgba(1,1,1) else: initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  # Render the controls
  renderCtrl(ras, sl, rb, app.mRadius)
  renderCtrl(ras, sl, rb, app.mGamma)
  renderCtrl(ras, sl, rb, app.mOffset)
  renderCtrl(ras, sl, rb, app.mWhiteOnBlack)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    for i in 0.. <2:
      if sqrt((x-app.mX[i]) * (x-app.mX[i]) + (y-app.mY[i]) * (y-app.mY[i])) < 10.0:
        app.mDx = x - app.mX[i]
        app.mDy = y - app.mY[i]
        app.mIdx = i

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    if app.midx >= 0:
      app.mx[app.midx] = x - app.mdx
      app.my[app.midx] = y - app.mdy
      app.forceRedraw()
    else:
      app.onMouseButtonUp(x.int, y.int, flags)

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.mIdx = -1

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Rounded rectangle with gamma-correction & stuff")

  if app.init(frameWidth, frameHeight, {window_resize}, "rounded_rect"):
    return app.run()

  result = 1

discard main()
