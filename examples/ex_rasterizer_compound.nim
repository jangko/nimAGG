import agg/[basics, ellipse, gamma_lut, rendering_buffer, rasterizer_scanline_aa,
  rasterizer_compound_aa, conv_curve, conv_stroke, scanline_u, renderer_scanline,
  span_allocator, pixfmt_rgba, pixfmt_rgba, renderer_base, color_rgba,
  path_storage, pixfmt_rgb, gamma_lut, rasterizer_sl_clip,
  trans_affine, conv_transform]
import ctrl.slider, ctrl.cbox, platform.support

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
  flipY = true

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre

  App = ref object of PlatformSupport
    mWidth : SliderCtrl[Rgba8]
    mAlpha1: SliderCtrl[Rgba8]
    mAlpha2: SliderCtrl[Rgba8]
    mAlpha3: SliderCtrl[Rgba8]
    mAlpha4: SliderCtrl[Rgba8]
    invertOrder: CboxCtrl[Rgba8]
    path: PathStorage
    rasc: RasterizerCompoundAA1[RasterizerSlClipDbl, getCoordT(RasterizerSlClipDbl)]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mWidth = newSliderCtrl[Rgba8](180 + 10.0, 5.0, 130 + 300.0, 12, not flipY)
  result.mAlpha1 = newSliderCtrl[Rgba8](5, 5,  180, 12, not flipY)
  result.mAlpha2 = newSliderCtrl[Rgba8](5, 25, 180, 32, not flipY)
  result.mAlpha3 = newSliderCtrl[Rgba8](5, 45, 180, 52, not flipY)
  result.mAlpha4 = newSliderCtrl[Rgba8](5, 65, 180, 72, not flipY)
  result.invertOrder = newCboxCtrl[Rgba8](190, 25, "Invert Z-Order")

  result.addCtrl(result.mWidth)
  result.addCtrl(result.mAlpha1)
  result.addCtrl(result.mAlpha2)
  result.addCtrl(result.mAlpha3)
  result.addCtrl(result.mAlpha4)
  result.addCtrl(result.invertOrder)

  result.invertOrder.status(false)
  result.mWidth.setRange(-20.0, 50.0)
  result.mWidth.value(20.0)
  result.mWidth.label("Width=$1")
  result.mAlpha1.setRange(0, 1)
  result.mAlpha1.value(1)
  result.mAlpha1.label("Alpha1=$1")
  result.mAlpha2.setRange(0, 1)
  result.mAlpha2.value(1)
  result.mAlpha2.label("Alpha2=$1")
  result.mAlpha3.setRange(0, 1)
  result.mAlpha3.value(1)
  result.mAlpha3.label("Alpha3=$1")
  result.mAlpha4.setRange(0, 1)
  result.mAlpha4.value(1)
  result.mAlpha4.label("Alpha4=$1")
  result.path  = initPathStorage()
  result.rasc  = initRasterizerCompoundAA(RasterizerSlClipDbl)

proc composePath(app: App) =
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

method onDraw(app: App) =
  var
    pixf   = construct(PixFmt, app.rbufWindow())
    renb   = initRendererBase(pixf)
    pfpre  = construct(PixFmtPre, app.rbufWindow())
    rbpre  = initRendererBase(pfpre)
    lut    = initGammaLut8(2.0)
    gr     = newSeq[Rgba8](pfpre.width())
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    sa     = initSpanAllocator[Rgba8]()    
    width  = app.width()
    height = app.height()

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
    app.rasc.layerOrder(layerInverse)
  else:
    app.rasc.layerOrder(layerDirect)

  styles[3] = initRgba8(lut.dir(255), lut.dir(0), lut.dir(108), 200)
  styles[2] = initRgba8(lut.dir(51), lut.dir(0), lut.dir(151), 180)
  styles[1] = initRgba8(lut.dir(143), lut.dir(90), lut.dir(6), 200)
  styles[0] = initRgba8(lut.dir(0), lut.dir(0), lut.dir(255), 220)

  styles[3].premultiply()
  styles[2].premultiply()
  styles[1].premultiply()
  styles[0].premultiply()

  stroke.width(app.mWidth.value())

  app.rasc.reset()
  app.rasc.masterAlpha(3, app.mAlpha1.value())
  app.rasc.masterAlpha(2, app.mAlpha2.value())
  app.rasc.masterAlpha(1, app.mAlpha3.value())
  app.rasc.masterAlpha(0, app.mAlpha4.value())

  var
    ell = initEllipse(220.0, 180.0, 120.0, 10.0, 128, false)
    strokeEll = initConvStroke(ell)

  strokeEll.width(app.mWidth.value() / 2)
  app.rasc.styles(3, -1)
  app.rasc.addPath(strokeEll)
  
  app.rasc.styles(2, -1)
  app.rasc.addPath(ell)
  
  app.rasc.styles(1, -1)
  app.rasc.addPath(stroke)
 
  app.rasc.styles(0, -1)
  app.rasc.addPath(curve)

  renderScanlinesCompoundLayered(app.rasc, sl, rbpre, sa, sh)
  renderCtrl(ras, sl, renb, app.mWidth)
  renderCtrl(ras, sl, renb, app.mAlpha1)
  renderCtrl(ras, sl, renb, app.mAlpha2)
  renderCtrl(ras, sl, renb, app.mAlpha3)
  renderCtrl(ras, sl, renb, app.mAlpha4)
  renderCtrl(ras, sl, renb, app.invertOrder)

  pixf.applyGammaInv(lut)

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("AGG Example. Compound Rasterizer -- Geometry Flattening")

  if app.init(frameWidth, frameHeight, {}, "rasterizer_compound"):
    return app.run()

  result = 1

discard main()
