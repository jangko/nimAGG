import agg_basics, agg_ellipse, agg_gamma_lut, agg_rendering_buffer
import agg_rasterizer_scanline_aa, agg_rasterizer_compound_aa
import agg_conv_curve, agg_conv_stroke, agg_scanline_u, agg_renderer_scanline
import agg_span_allocator, agg_pixfmt_rgba, ctrl_slider, ctrl_cbox
import agg_pixfmt_rgba, agg_renderer_base, agg_color_rgba, nimBMP
import agg_path_storage, agg_pixfmt_rgb, agg_gamma_lut, agg_rasterizer_sl_clip
import agg_trans_affine, agg_conv_transform

type
  StyleHandler = object
    transparent: Rgba8
    styles: ptr Rgba8
    count: int

proc initStyleHandler(styles: ptr Rgba8, count: int): StyleHandler =
  result.transparent = initRgba8(0, 0, 0, 0)
  result.styles = styles
  result.count = count

proc isSolid(self: StyleHandler, style: int): bool = true

proc color(self: StyleHandler, style: int): Rgba8 =
  if style < self.count:
    return self.styles[style]

  result = self.transparent

proc generateSpan(self: StyleHandler, span: ptr Rgba8, x, y, len, style: int) =
  discard

const
  frameWidth = 440
  frameHeight = 330
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

type
  App = object
    width : SliderCtrl[Rgba8]
    alpha1: SliderCtrl[Rgba8]
    alpha2: SliderCtrl[Rgba8]
    alpha3: SliderCtrl[Rgba8]
    alpha4: SliderCtrl[Rgba8]
    invertOrder: CboxCtrl[Rgba8]
    path: PathStorage

proc initApp(): App =
  result.width = newSliderCtrl[Rgba8](180 + 10.0, 5.0, 130 + 300.0, 12, not flipY)
  result.alpha1 = newSliderCtrl[Rgba8](5, 5,  180, 12, not flipY)
  result.alpha2 = newSliderCtrl[Rgba8](5, 25, 180, 32, not flipY)
  result.alpha3 = newSliderCtrl[Rgba8](5, 45, 180, 52, not flipY)
  result.alpha4 = newSliderCtrl[Rgba8](5, 65, 180, 72, not flipY)
  result.invertOrder = newCboxCtrl[Rgba8](190, 25, "Invert Z-Order")
  result.invertOrder.status(false)
  result.width.setRange(-20.0, 50.0)
  result.width.value(10.0)
  result.width.label("Width=$1")
  result.alpha1.setRange(0, 1)
  result.alpha1.value(1)
  result.alpha1.label("Alpha1=$1")
  result.alpha2.setRange(0, 1)
  result.alpha2.value(1)
  result.alpha2.label("Alpha2=$1")
  result.alpha3.setRange(0, 1)
  result.alpha3.value(1)
  result.alpha3.label("Alpha3=$1")
  result.alpha4.setRange(0, 1)
  result.alpha4.value(1)
  result.alpha4.label("Alpha4=$1")
  result.path = initPathStorage()

proc composePath(app: var App) =
  app.path.removeAll()
  app.path.moveTo(28.47, 6.45)
  app.path.curve3(21.58, 1.12, 19.82, 0.29)
  app.path.curve3(17.19, -0.93, 14.21, -0.93)
  app.path.curve3(9.57, -0.93, 6.57, 2.25)
  app.path.curve3(3.56, 5.42, 3.56, 10.60)
  app.path.curve3(3.56, 13.87, 5.03, 16.26)
  app.path.curve3(7.03, 19.58, 11.99, 22.51)
  app.path.curve3(16.94, 25.44, 28.47, 29.64)
  app.path.lineTo(28.47, 31.40)
  app.path.curve3(28.47, 38.09, 26.34, 40.58)
  app.path.curve3(24.22, 43.07, 20.17, 43.07)
  app.path.curve3(17.09, 43.07, 15.28, 41.41)
  app.path.curve3(13.43, 39.75, 13.43, 37.60)
  app.path.lineTo(13.53, 34.77)
  app.path.curve3(13.53, 32.52, 12.38, 31.30)
  app.path.curve3(11.23, 30.08, 9.38, 30.08)
  app.path.curve3(7.57, 30.08, 6.42, 31.35)
  app.path.curve3(5.27, 32.62, 5.27, 34.81)
  app.path.curve3(5.27, 39.01, 9.57, 42.53)
  app.path.curve3(13.87, 46.04, 21.63, 46.04)
  app.path.curve3(27.59, 46.04, 31.40, 44.04)
  app.path.curve3(34.28, 42.53, 35.64, 39.31)
  app.path.curve3(36.52, 37.21, 36.52, 30.71)
  app.path.lineTo(36.52, 15.53)
  app.path.curve3(36.52, 9.13, 36.77, 7.69)
  app.path.curve3(37.01, 6.25, 37.57, 5.76)
  app.path.curve3(38.13, 5.27, 38.87, 5.27)
  app.path.curve3(39.65, 5.27, 40.23, 5.62)
  app.path.curve3(41.26, 6.25, 44.19, 9.18)
  app.path.lineTo(44.19, 6.45)
  app.path.curve3(38.72, -0.88, 33.74, -0.88)
  app.path.curve3(31.35, -0.88, 29.93, 0.78)
  app.path.curve3(28.52, 2.44, 28.47, 6.45)
  app.path.closePolygon()

  app.path.moveTo(28.47, 9.62)
  app.path.lineTo(28.47, 26.66)
  app.path.curve3(21.09, 23.73, 18.95, 22.51)
  app.path.curve3(15.09, 20.36, 13.43, 18.02)
  app.path.curve3(11.77, 15.67, 11.77, 12.89)
  app.path.curve3(11.77, 9.38, 13.87, 7.06)
  app.path.curve3(15.97, 4.74, 18.70, 4.74)
  app.path.curve3(22.41, 4.74, 28.47, 9.62)
  app.path.closePolygon()

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixFmtRgba32(rbuf)
    renb   = initRendererBase(pixf)
    pfpre  = initPixFmtRgba32Pre(rbuf)
    rbpre  = initRendererBase(pfpre)
    lut    = initGammaLut8(2.0)
    gr     = newSeq[Rgba8](pfpre.width())
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    sa     = initSpanAllocator[Rgba8]()
    rasc   = initRasterizerCompoundAA(RasterizerSlClipDbl)
    width  = frameWidth.float64
    height = frameHeight.float64

  # Clear the window with a gradient
  for i in 0.. <pixf.width():
    var c = initRgba8(255, 255, 0)
    gr[i] = c.gradient(initRgba8(0, 255, 255), float64(i) / float64(pixf.width()))

  for i in 0.. <pixf.height():
    renb.copyColorHspan(0, i, pixf.width(), gr[0].addr)

  pixf.applyGammaDir(lut)

  # Draw two triangles
  ras.moveToD(0, 0)
  ras.lineToD(width, 0)
  ras.lineToD(width, height)
  renderScanlinesAASolid(ras, sl, renb, initRgba8(lut.dir(0), lut.dir(100), lut.dir(0)))

  ras.moveToD(0, 0)
  ras.lineToD(0, height)
  ras.lineToD(width, 0)
  renderScanlinesAASolid(ras, sl, renb, initRgba8(lut.dir(0), lut.dir(100), lut.dir(100)))

  var
    mtx    = initTransAffine()
    trans  = initConvTransform(app.path, mtx)
    curve  = initConvCurve(trans)
    stroke = initConvStroke(curve)
    styles: array[4, Rgba8]
    sh     = initStyleHandler(styles[0].addr, 4)

  mtx *= transAffineScaling(4.0)
  mtx *= transAffineTranslation(150, 100)

  app.composePath()

  if app.invertOrder.status():
    rasc.layerOrder(layerInverse)
  else:
    rasc.layerOrder(layerDirect)

  styles[3] = initRgba8(lut.dir(255), lut.dir(0), lut.dir(108), 200)
  styles[2] = initRgba8(lut.dir(51), lut.dir(0), lut.dir(151), 180)
  styles[1] = initRgba8(lut.dir(143), lut.dir(90), lut.dir(6), 200)
  styles[0] = initRgba8(lut.dir(0), lut.dir(0), lut.dir(255), 220)

  styles[3].premultiply()
  styles[2].premultiply()
  styles[1].premultiply()
  styles[0].premultiply()

  stroke.width(app.width.value())

  rasc.reset()
  rasc.masterAlpha(3, app.alpha1.value())
  rasc.masterAlpha(2, app.alpha2.value())
  rasc.masterAlpha(1, app.alpha3.value())
  rasc.masterAlpha(0, app.alpha4.value())

  var
    ell = initEllipse(220.0, 180.0, 120.0, 10.0, 128, false)
    strokeEll = initConvStroke(ell)

  strokeEll.width(app.width.value() / 2)
  rasc.styles(3, -1)
  rasc.addPath(strokeEll)

  rasc.styles(2, -1)
  rasc.addPath(ell)

  rasc.styles(1, -1)
  rasc.addPath(stroke)

  rasc.styles(0, -1)
  rasc.addPath(curve)

  renderScanlinesCompoundLayered(rasc, sl, rbpre, sa, sh)
  renderCtrl(ras, sl, renb, app.width)
  renderCtrl(ras, sl, renb, app.alpha1)
  renderCtrl(ras, sl, renb, app.alpha2)
  renderCtrl(ras, sl, renb, app.alpha3)
  renderCtrl(ras, sl, renb, app.alpha4)
  renderCtrl(ras, sl, renb, app.invertOrder)

  pixf.applyGammaInv(lut)

  saveBMP32("rasterizer_compound.bmp", buffer, frameWidth, frameHeight)

onDraw()

