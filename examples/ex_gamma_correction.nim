import agg/[trans_affine, conv_stroke, rasterizer_scanline_aa,
  rendering_buffer, scanline_u, renderer_scanline, gamma_lut, 
  basics, gamma_lut, pixfmt_rgb, renderer_base, color_rgba, path_storage,
  gamma_functions, ellipse], ctrl.slider, platform.support

const
  frameWidth = 400
  frameHeight = 320
  flipY = true

type
  PixFmt = PixFmtBgr24Gamma[GammaLut8]

  App = ref object of PlatformSupport
    mThickness: SliderCtrl[Rgba8]
    mGamma: SliderCtrl[Rgba8]
    mContrast: SliderCtrl[Rgba8]
    mRx, mRy: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mThickness = newSliderCtrl[Rgba8](5, 5,    400-5, 11,    not flipY)
  result.mGamma     = newSliderCtrl[Rgba8](5, 5+15, 400-5, 11+15, not flipY)
  result.mContrast  = newSliderCtrl[Rgba8](5, 5+30, 400-5, 11+30, not flipY)

  result.addCtrl(result.mThickness)
  result.addCtrl(result.mGamma)
  result.addCtrl(result.mContrast)

  result.mThickness.label("Thickness=$1")
  result.mGamma.label("Gamma=$1")
  result.mContrast.label("Contrast")

  result.mThickness.setRange(0.0, 3.0)
  result.mGamma.setRange(0.5, 3.0)
  result.mContrast.setRange(0.0, 1.0)

  result.mThickness.value(1.0)
  result.mGamma.value(1.0)
  result.mContrast.value(1.0)

method onInit(app: App) =
  app.mRx = app.width() / 3.0
  app.mRy = app.height() / 3.0

method onDraw(app: App) =
  var
    g      = app.mGamma.value()
    gamma  = initGammaLut8(g)
    pf     = construct(PixFmt, app.rbufWindow(), gamma)
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()
    w      = app.width().int
    h      = app.height().int

  rb.clear(initRgba(1, 1, 1))

  var
    dark = 1.0 - app.mContrast.value()
    light = app.mContrast.value()

  rb.copyBar(0,0,w div 2, h, initRgba(dark,dark,dark))
  rb.copyBar(w div 2+1,0, w, h,  initRgba(light,light,light))
  rb.copyBar(0,h div 2+1, w, h, initRgba(1.0,dark,dark))

  var
    x = (app.width() - 256.0) / 2.0
    y = 50.0
    gp = initGammaPower(g)

  path.removeAll()
  for i in 0..255:
    var
      v = float64(i) / 255.0
      gval = gp.getGammaValue(v)
      dy = gval * 255.0

    if i == 0: path.moveTo(x + i.float64, y + dy)
    else:      path.lineTo(x + i.float64, y + dy)


  var gpoly = initConvStroke(path)
  gpoly.width(2.0)
  ras.reset()
  ras.addPath(gpoly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(80,127,80))

  var
    width2  = app.width() / 2
    height2 = app.height() / 2
    ell     = initEllipse(width2, height2, app.mRx, app.mRy, 150)
    poly    = initconvStroke(ell)

  poly.width(app.mThickness.value())
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(255,0,0))

  ell.init(width2, height2, app.mRx-5.0, app.mRy-5.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,255,0))

  ell.init(width2, height2, app.mRx-10.0, app.mRy-10.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,0,255))

  ell.init(width2, height2, app.mRx-15.0, app.mRy-15.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,0,0))

  ell.init(width2, height2, app.mRx-20.0, app.mRy-20.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(255,255,255))

  renderCtrl(ras, sl, rb, app.mThickness)
  renderCtrl(ras, sl, rb, app.mGamma)
  renderCtrl(ras, sl, rb, app.mContrast)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    app.mRx = abs(app.width()/2 - x)
    app.mRy = abs(app.height()/2 - y)
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  app.onMouseButtonDown(x, y, flags)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Thin red ellipse")

  if app.init(frameWidth, frameHeight, {}, "gamma_correction"):
    return app.run()

  result = 1

discard main()
