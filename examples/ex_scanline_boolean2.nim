import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  scanline_p, scanline_bin, renderer_scanline, renderer_primitives,
  span_solid, conv_curve, conv_stroke, gsv_text, pixfmt_rgb,
  scanline_boolean_algebra, scanline_storage_aa, scanline_storage_bin,
  path_storage, trans_affine, conv_transform, color_rgba, renderer_base]
import ctrl/[slider, cbox, rbox], make_arrows, make_gb_poly, strutils, platform.support

const
  frameWidth = 655
  frameHeight = 520
  flipY = true

proc countSpans[Rasterizer, Scanline](ras: var Rasterizer, sl: var Scanline): int =
  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    while ras.sweepScanline(sl):
      result += sl.numSpans()

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    polygons: RboxCtrl[Rgba8]
    operation: RBoxCtrl[Rgba8]
    fillRule: RboxCtrl[Rgba8]
    scanlineType: RBoxCtrl[Rgba8]
    mx, my: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.polygons     = newRboxCtrl[Rgba8](5.0,     5.0, 5.0+205.0,   110.0,  not flipY)
  result.fillRule     = newRboxCtrl[Rgba8](200,     5.0, 200+105.0,    50.0,  not flipY)
  result.scanlineType = newRboxCtrl[Rgba8](300,     5.0, 300+115.0,    70.0,  not flipY)
  result.operation    = newRboxCtrl[Rgba8](535.0,   5.0, 535.0+115.0, 145.0,  not flipY)

  result.addCtrl(result.polygons)
  result.addCtrl(result.fillRule)
  result.addCtrl(result.scanlineType)
  result.addCtrl(result.operation)

  result.polygons.addItem("Two Simple Paths")
  result.polygons.addItem("Closed Stroke")
  result.polygons.addItem("Great Britain and Arrows")
  result.polygons.addItem("Great Britain and Spiral")
  result.polygons.addItem("Spiral and Glyph")
  result.polygons.curItem(0)
  result.polygons.noTransform()

  result.operation.addItem("None")
  result.operation.addItem("OR")
  result.operation.addItem("AND")
  result.operation.addItem("XOR Linear")
  result.operation.addItem("XOR Saddle")
  result.operation.addItem("A-B")
  result.operation.addItem("B-A")
  result.operation.curItem(2)
  result.operation.noTransform()

  result.fillRule.addItem("Even-Odd")
  result.fillRule.addItem("Non Zero")
  result.fillRule.curItem(0)
  result.fillRule.noTransform()

  result.scanlineType.addItem("scanline_p")
  result.scanlineType.addItem("scanline_u")
  result.scanlineType.addItem("scanline_bin")
  result.scanlineType.curItem(1)
  result.scanlineType.noTransform()

method onInit(app: App) =
  app.mx = app.width() / 2.0
  app.my = app.height() / 2.0

proc getOperation(app: App): SboolOp =
  case app.operation.curItem()
  of 1: result = sbool_or
  of 2: result = sbool_and
  of 3: result = sbool_xor
  of 4: result = sbool_xor_saddle
  of 5: result = sbool_a_minus_b
  of 6: result = sbool_b_minus_a
  else: discard

proc scanlineP[RendererBase, Rasterizer](app: App, rb: var RendererBase,
  ras1, ras2: var Rasterizer, op: SBoolOp, t1, t2: var float64, numSpans: var int) =

  var
    ren = initRendererScanlineAASolid(rb)
    sl  = initScanlineP8()
    sl1 = initScanlineP8()
    sl2 = initScanlineP8()
    storage  = initScanlineStorageAA8()
    storage1 = initScanlineStorageAA8()
    storage2 = initScanlineStorageAA8()

  # The intermediate storage is used only to test the perfoprmance,
  # the short variant can be as follows:
  # ------------------------
  # ren.color(initRgba(0.5, 0.0, 0, 0.5))
  # agg::sbool_combine_shapes_aa(op, ras1, ras2, sl1, sl2, sl, ren)

  renderScanlines(ras1, sl, storage1)
  renderScanlines(ras2, sl, storage2)

  app.startTimer()
  for i in 0.. <10:
    sboolCombineShapesAA(op, storage1, storage2, sl1, sl2, sl, storage)

  t1 = app.elapsedTime() / 10.0

  app.startTimer()
  ren.color(initRgba(0.5, 0.0, 0, 0.5))
  renderScanlines(storage, sl, ren)
  t2 = app.elapsedTime()
  numSpans = countSpans(storage, sl)

proc scanlineU[RendererBase, Rasterizer](app: App, rb: var RendererBase,
  ras1, ras2: var Rasterizer, op: SBoolOp, t1, t2: var float64, numSpans: var int) =

  var
    ren = initRendererScanlineAASolid(rb)
    sl  = initScanlineU8()
    sl1 = initScanlineU8()
    sl2 = initScanlineU8()
    storage  = initScanlineStorageAA8()
    storage1 = initScanlineStorageAA8()
    storage2 = initScanlineStorageAA8()

  renderScanlines(ras1, sl, storage1)
  renderScanlines(ras2, sl, storage2)

  app.startTimer()
  for i in 0.. <10:
    sboolCombineShapesAA(op, storage1, storage2, sl1, sl2, sl, storage)

  t1 = app.elapsedTime() / 10.0

  app.startTimer()
  ren.color(initRgba(0.5, 0.0, 0, 0.5))
  renderScanlines(storage, sl, ren)
  t2 = app.elapsedTime()
  numSpans = countSpans(storage, sl)

proc scanlineBin[RendererBase, Rasterizer](app: App, rb: var RendererBase,
  ras1, ras2: var Rasterizer, op: SBoolOp, t1, t2: var float64, numSpans: var int) =
  var
    ren = initRendererScanlineBinSolid(rb)
    sl  = initScanlineBin()
    sl1 = initScanlineBin()
    sl2 = initScanlineBin()
    storage  = initScanlineStorageBin()
    storage1 = initScanlineStorageBin()
    storage2 = initScanlineStorageBin()

  renderScanlines(ras1, sl, storage1)
  renderScanlines(ras2, sl, storage2)

  app.startTimer()
  for i in 0.. <10:
    sboolCombineShapesBin(op, storage1, storage2, sl1, sl2, sl, storage)

  t1 = app.elapsedTime() / 10.0

  app.startTimer()
  ren.color(initRgba(0.5, 0.0, 0, 0.5))
  renderScanlines(storage, sl, ren)
  t2 = app.elapsedTime()
  numSpans = countSpans(storage, sl)

proc renderScanlineBoolean[Rasterizer](app: App, ras1, ras2: var Rasterizer) =
  if app.operation.curItem() == 0: return
  let op = app.getOperation()

  var
    pixf = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pixf)
    t1   = 0.0
    t2   = 0.0
    numSpans = 0

  case app.scanlineType.curItem()
  of 0: app.scanlineP(rb, ras1, ras2, op, t1, t2, numSpans)
  of 1: app.scanlineU(rb, ras1, ras2, op, t1, t2, numSpans)
  of 2: app.scanlineBin(rb, ras1, ras2, op, t1, t2, numSpans)
  else: discard

  var
    buf  = "Combine=$1ms\nRender=$2ms\nnumSpans=$3" %
           [t1.formatFloat(ffDecimal, 3),
            t2.formatFloat(ffDecimal, 3), $numSpans]
    ren  = initRendererScanlineAASolid(rb)
    sl   = initScanlineP8()
    txt  = initGsvText()
    stroke = initConvStroke(txt)

  stroke.width(1.0)
  stroke.lineCap(LineCap.roundCap)
  txt.size(8.0)
  txt.startPoint(420, 40)
  txt.text(buf)
  ras1.addPath(stroke)
  ren.color(initRgba(0.0, 0.0, 0.0))
  renderScanlines(ras1, sl, ren)

proc renderSimplePaths[Rasterizer, Scanline, Renderer](app: App,
  ras1, ras2: var Rasterizer, sl: var Scanline, ren: var Renderer) =

  var
    ps1 = initPathStorage()
    ps2 = initPathStorage()
    x = app.mx - app.width()/2 + 100
    y = app.my - app.height()/2 + 100

  ps1.moveTo(x+140, y+145)
  ps1.lineTo(x+225, y+44)
  ps1.lineTo(x+296, y+219)
  ps1.closePolygon()

  ps1.lineTo(x+226, y+289)
  ps1.lineTo(x+82,  y+292)

  ps1.moveTo(x+220, y+222)
  ps1.lineTo(x+363, y+249)
  ps1.lineTo(x+265, y+331)

  ps1.moveTo(x+242, y+243)
  ps1.lineTo(x+325, y+261)
  ps1.lineTo(x+268, y+309)

  ps1.moveTo(x+259, y+259)
  ps1.lineTo(x+273, y+288)
  ps1.lineTo(x+298, y+266)

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)

  ras1.reset()
  ras1.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras1, sl, ren)

  ras2.reset()
  ras2.addPath(ps2)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras2, sl, ren)
  app.renderScanlineBoolean(ras1, ras2)

proc renderClosedStroke[Rasterizer, Scanline, Renderer](app: App,
  ras1, ras2: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var
    ps1 = initPathStorage()
    ps2 = initPathStorage()
    x = app.mx - app.width()/2 + 100
    y = app.my - app.height()/2 + 100
    stroke = initConvStroke(ps2)

  stroke.width(15.0)

  ps1.moveTo(x+140, y+145)
  ps1.lineTo(x+225, y+44)
  ps1.lineTo(x+296, y+219)
  ps1.closePolygon()

  ps1.lineTo(x+226, y+289)
  ps1.lineTo(x+82,  y+292)

  ps1.moveTo(x+220-50, y+222)
  ps1.lineTo(x+363-50, y+249)
  ps1.lineTo(x+265-50, y+331)
  ps1.closePolygon()

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)
  ps2.closePolygon()

  ras1.reset()
  ras1.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras1, sl, ren)

  ras2.reset()
  ras2.addPath(stroke)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras2, sl, ren)
  app.renderScanlineBoolean(ras1, ras2)

proc renderGBArrow[Rasterizer, Scanline, Renderer](app: App,
  ras1, ras2: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var
    gbPoly = initPathStorage()
    arrows = initPathStorage()
    mtx1 = initTransAffine()
    mtx2 = initTransAffine()

  makeGBPoly(gbPoly)
  makeArrows(arrows)

  mtx1 *= transAffineTranslation(-1150, -1150)
  mtx1 *= transAffineScaling(2.0)

  mtx2 = mtx1
  mtx2 *= transAffineTranslation(app.mx - app.height()/2, app.my - app.height()/2)

  var
    transGBPoly = initConvTransform(gbPoly, mtx1)
    transArrows = initConvTransform(arrows, mtx2)

  ras2.addPath(transGBPoly)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(ras2, sl, ren)

  var stroke_gbPoly = initConvStroke(transGBPoly)
  stroke_gbPoly.width(0.1)
  ras1.addPath(stroke_gbPoly)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras1, sl, ren)

  ras2.addPath(transArrows)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(ras2, sl, ren)

  ras1.reset()
  ras1.addPath(transGBPoly)

  app.renderScanlineBoolean(ras1, ras2)

proc renderGBSpiral[Rasterizer, Scanline, Renderer](app: App,
  ras1, ras2: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var
    sp = initSpiral(app.mx, app.my, 10, 150, 30, 0.0)
    stroke = initConvStroke(sp)
    gbPoly = initPathStorage()
    mtx = initTransAffine()

  stroke.width(15.0)
  makeGBPoly(gbPoly)

  mtx *= transAffineTranslation(-1150, -1150)
  mtx *= transAffineScaling(2.0)

  var trans = initConvTransform(gbPoly, mtx)

  ras1.addPath(trans)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(ras1, sl, ren)

  var strokegb = initConvStroke(trans)
  strokegb.width(0.1)
  ras1.addPath(strokegb)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras1, sl, ren)

  ras2.reset()
  ras2.addPath(stroke)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(ras2, sl, ren)

  ras1.reset()
  ras1.addPath(trans)
  app.renderScanlineBoolean(ras1, ras2)

proc renderSpiralAndGlyph[Rasterizer, Scanline, Renderer](app: App,
  ras1, ras2: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  var
    sp     = initSpiral(app.mx, app.my, 10, 150, 30, 0.0)
    stroke = initConvStroke(sp)
    glyph  = initPathStorage()

  stroke.width(15.0)

  glyph.moveTo(28.47, 6.45)
  glyph.curve3(21.58, 1.12, 19.82, 0.29)
  glyph.curve3(17.19, -0.93, 14.21, -0.93)
  glyph.curve3(9.57, -0.93, 6.57, 2.25)
  glyph.curve3(3.56, 5.42, 3.56, 10.60)
  glyph.curve3(3.56, 13.87, 5.03, 16.26)
  glyph.curve3(7.03, 19.58, 11.99, 22.51)
  glyph.curve3(16.94, 25.44, 28.47, 29.64)
  glyph.lineTo(28.47, 31.40)
  glyph.curve3(28.47, 38.09, 26.34, 40.58)
  glyph.curve3(24.22, 43.07, 20.17, 43.07)
  glyph.curve3(17.09, 43.07, 15.28, 41.41)
  glyph.curve3(13.43, 39.75, 13.43, 37.60)
  glyph.lineTo(13.53, 34.77)
  glyph.curve3(13.53, 32.52, 12.38, 31.30)
  glyph.curve3(11.23, 30.08, 9.38, 30.08)
  glyph.curve3(7.57, 30.08, 6.42, 31.35)
  glyph.curve3(5.27, 32.62, 5.27, 34.81)
  glyph.curve3(5.27, 39.01, 9.57, 42.53)
  glyph.curve3(13.87, 46.04, 21.63, 46.04)
  glyph.curve3(27.59, 46.04, 31.40, 44.04)
  glyph.curve3(34.28, 42.53, 35.64, 39.31)
  glyph.curve3(36.52, 37.21, 36.52, 30.71)
  glyph.lineTo(36.52, 15.53)
  glyph.curve3(36.52, 9.13, 36.77, 7.69)
  glyph.curve3(37.01, 6.25, 37.57, 5.76)
  glyph.curve3(38.13, 5.27, 38.87, 5.27)
  glyph.curve3(39.65, 5.27, 40.23, 5.62)
  glyph.curve3(41.26, 6.25, 44.19, 9.18)
  glyph.lineTo(44.19, 6.45)
  glyph.curve3(38.72, -0.88, 33.74, -0.88)
  glyph.curve3(31.35, -0.88, 29.93, 0.78)
  glyph.curve3(28.52, 2.44, 28.47, 6.45)
  glyph.closePolygon()

  glyph.moveTo(28.47, 9.62)
  glyph.lineTo(28.47, 26.66)
  glyph.curve3(21.09, 23.73, 18.95, 22.51)
  glyph.curve3(15.09, 20.36, 13.43, 18.02)
  glyph.curve3(11.77, 15.67, 11.77, 12.89)
  glyph.curve3(11.77, 9.38, 13.87, 7.06)
  glyph.curve3(15.97, 4.74, 18.70, 4.74)
  glyph.curve3(22.41, 4.74, 28.47, 9.62)
  glyph.closePolygon()

  var
    mtx = initTransAffine()

  mtx *= transAffineScaling(4.0)
  mtx *= transAffineTranslation(220, 200)

  var
    trans = initConvTransform(glyph, mtx)
    curve = initConvCurve(trans)

  ras1.reset()
  ras1.addPath(stroke)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras1, sl, ren)

  ras2.reset()
  ras2.addPath(curve)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras2, sl, ren)

  app.renderScanlineBoolean(ras1, ras2)

proc renderSbool[Rasterizer](app: App, ras1, ras2: var Rasterizer) =
  var
    pixf = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)
    sl   = initScanlineP8()

  let fr = if app.fillRule.curItem() != 0: fillNonZero else: fillEvenOdd

  ras1.fillingRule(fr)
  ras2.fillingRule(fr)

  case app.polygons.curItem()
  of 0: app.renderSimplePaths(ras1, ras2, sl, ren)
  of 1: app.renderClosedStroke(ras1, ras2, sl, ren)
  of 2: app.renderGBArrow(ras1, ras2, sl, ren)
  of 3: app.renderGBSpiral(ras1, ras2, sl, ren)
  of 4: app.renderSpiralAndGlyph(ras1, ras2, sl, ren)
  else: discard

method onDraw(app: App) =
  var
    pf   = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pf)
    sl   = initScanlineU8()
    ras  = initRasterizerScanlineAA()
    ras2 = initRasterizerScanlineAA()

  rb.clear(initRgba(1,1,1))

  renderCtrl(ras, sl, rb, app.polygons)
  renderCtrl(ras, sl, rb, app.fillRule)
  renderCtrl(ras, sl, rb, app.scanlineType)
  renderCtrl(ras, sl, rb, app.operation)

  app.renderSbool(ras, ras2)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mx = x.float64
    app.my = y.float64
    app.forceRedraw()

  if mouseRight in flags:
    let buf = "$1 $2" % [$x, $y]
    app.message(buf)

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mx = x.float64
    app.my = y.float64
    app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Scanline Boolean")

  if app.init(frameWidth, frameHeight, {}, "scanline_boolean2"):
    return app.run()

  result = 1

discard main()
