import agg/[rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, gsv_text, conv_stroke, path_storage,
  pixfmt_rgb, trans_affine, conv_transform, basics,
  renderer_base, color_rgba, ellipse]
import ctrl/gamma, platform/support

const
  frameWidth = 500
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mGamma: GammaCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mGamma = newGammaCtrl[Rgba8](10.0, 10.0, 300.0, 200.0, not flipY)
  result.mGamma.textSize(10.0, 12.0)

  result.addCtrl(result.mGamma)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ewidth = app.initialWidth() / 2.0 - 10.0
    ecenter= app.initialWidth() / 2.0
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()

  rb.clear(initRgba(1, 1, 1))

  renderCtrl(ras, sl, rb, app.mGamma)
  ras.gamma(app.mGamma)

  var
    ellipse = initEllipse()
    poly    = initConvStroke(ellipse)
    tpoly   = initConvTransform(poly, transAffineResizing(app))
    color   = initRgba8(0, 0, 0)

  ellipse.init(ecenter, 220, ewidth, 15, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 220, 11, 11, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  color = initRgba8(127, 127, 127)

  ellipse.init(ecenter, 260, ewidth, 15, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 260, 11, 11, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  color = initRgba8(192, 192, 192)

  ellipse.init(ecenter, 300, ewidth, 15, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 300, 11, 11, 100)
  poly.width(2.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  color = initRgba8(initRgba(0.0, 0.0, 0.4))

  ellipse.init(ecenter, 340, ewidth, 15.5, 100)
  poly.width(1.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 340, 10.5, 10.5, 100)
  poly.width(1.0)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 380, ewidth, 15.5, 100)
  poly.width(0.4)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 380, 10.5, 10.5, 100)
  poly.width(0.4)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 420, ewidth, 15.5, 100)
  poly.width(0.1)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  ellipse.init(ecenter, 420, 10.5, 10.5, 100)
  poly.width(0.1)
  ras.addPath(tpoly, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  var mtx = initTransAffine()
  mtx *= transAffineSkewing(0.15, 0.0)
  mtx *= transAffineResizing(app)
  var
    text = initGsvText()
    text1 = initGsvTextOutline(text, mtx)

  text.text("Text 2345")
  text.size(50, 20)
  text1.width(2.0)
  text.startPoint(320, 10)

  color = initRgba8(initRgba(0.0, 0.5, 0.0))
  ras.addPath(text1, 0)
  renderScanlinesAASolid(ras, sl, rb, color)

  color = initRgba8(initRgba(0.5, 0.0, 0.0))
  var path = initPathStorage()
  path.moveTo(30, -1.0)
  path.lineTo(60, 0.0)
  path.lineTo(30, 1.0)

  path.moveTo(27, -1.0)
  path.lineTo(10, 0.0)
  path.lineTo(27, 1.0)

  var trans = initConvTransform(path, mtx)

  for i in 0..<35:
    mtx.reset()
    mtx *= transAffineRotation(float64(i) / 35.0 * pi * 2.0)
    mtx *= transAffineTranslation(400, 130)
    mtx *= transAffineResizing(app)
    ras.addPath(trans, 0)
    renderScanlinesAASolid(ras, sl, rb, color)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Anti-Aliasing Gamma Correction")

  if app.init(frameWidth, frameHeight, {window_resize}, "gamma_ctrl"):
    return app.run()

  result = 1

discard main()
