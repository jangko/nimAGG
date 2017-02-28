import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_gsv_text, agg_conv_stroke, agg_path_storage
import ctrl_gamma, agg_renderer_base, agg_color_rgba, nimBMP, agg_ellipse
import agg_pixfmt_rgb, agg_trans_affine, agg_conv_transform, agg_basics

const
  frameWidth = 500
  frameHeight = 400
  flipY = true
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
    ctrl   = newGammaCtrl[Rgba8](10.0, 10.0, 300.0, 200.0, not flipY)
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixfmtRgb24(rbuf)
    rb     = initRendererBase(pixf)
    ewidth = frameWidth.float64 / 2.0 - 10.0
    ecenter= frameWidth / 2.0
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()

  rb.clear(initRgba(1, 1, 1))
  ctrl.textSize(10.0, 12.0)
  renderCtrl(ras, sl, rb, ctrl)
  ras.gamma(ctrl)

  var
    ellipse = initEllipse()
    poly    = initConvStroke(ellipse)
    aff     = initTransAffine()
    tpoly   = initConvTransform(poly, aff)
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
  #mtx *= trans_affine_resizing()
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

  for i in 0.. <35:
    mtx.reset()
    mtx *= transAffineRotation(float64(i) / 35.0 * pi * 2.0)
    mtx *= transAffineTranslation(400, 130)
    #mtx *= transAffine_resizing()
    ras.addPath(trans, 0)
    renderScanlinesAASolid(ras, sl, rb, color)

  saveBMP24("gamma_ctrl.bmp", buffer, frameWidth, frameHeight)

onDraw()