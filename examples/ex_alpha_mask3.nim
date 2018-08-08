import agg / [basics, rendering_buffer, rasterizer_scanline_aa, renderer_base,
  scanline_p, renderer_scanline, renderer_primitives, color_rgba,
  conv_stroke, gsv_text, pixfmt_rgb, pixfmt_gray, math_stroke,
  pixfmt_amask_adaptor, span_allocator, alpha_mask_u8, color_gray,
  path_storage, trans_affine, conv_transform, conv_curve]
import make_arrows, make_gb_poly, strutils, ctrl/rbox, platform/support

const
  frameWidth = 640
  frameHeight = 520
  flipY = true

type
  PixFmt = PixFmtBgr24
  ColorT = getColorT(PixFmt)
  ValueT = getValueT(ColorT)

  App = ref object of PlatformSupport
    polygons: RboxCtrl[Rgba8]
    operation: RBoxCtrl[Rgba8]
    alphaMask: AmaskNoClipGray8
    alphaBuf: seq[ValueT]
    alphaRbuf: RenderingBuffer
    ras: RasterizerScanlineAA
    sl: ScanlineP8
    mx, my: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.polygons  = newRboxCtrl[Rgba8](5.0,     5.0, 5.0+205.0,  110.0, not flipY)
  result.operation = newRboxCtrl[Rgba8](555.0,   5.0, 555.0+80.0, 55.0, not flipY)

  result.alphaBuf  = newSeq[ValueT](frameWidth * frameHeight)
  result.alphaRbuf = initRenderingBuffer(result.alphaBuf[0].addr, frameWidth, frameHeight, frameWidth)
  result.alphaMask = initAmaskNoClipGray8(result.alphaRbuf)

  result.mx = 0
  result.my = 0
  result.operation.addItem("AND")
  result.operation.addItem("SUB")
  result.operation.curItem(0)
  result.operation.noTransform()
  result.addCtrl(result.operation)

  result.polygons.addItem("Two Simple Paths")
  result.polygons.addItem("Closed Stroke")
  result.polygons.addItem("Great Britain and Arrows")
  result.polygons.addItem("Great Britain and Spiral")
  result.polygons.addItem("Spiral and Glyph")
  result.polygons.curItem(3)
  result.polygons.noTransform()
  result.addCtrl(result.polygons)

  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineP8()


proc drawText(app: App, x, y: float64, text: string) =
  var
    txt = initGsvText()
    stroke = initConvStroke(txt)
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)

  stroke.width(1.5)
  stroke.lineCap(roundCap)
  txt.size(10.0)
  txt.startPoint(x, y)
  txt.text(text)
  app.ras.addPath(stroke)
  ren.color(initRgba(0.0, 0.0, 0.0))
  renderScanlines(app.ras, app.sl, ren)

proc generateAlphaMask[VertexSource](app: App, vs: var VertexSource) =
  var
    cx = app.width().int
    cy = app.height().int

  if app.alphaBuf.len < cx * cy:
    app.alphaBuf = newSeq[ValueT](cx * cy)
    app.alphaRbuf.attach(app.alphaBuf[0].addr, cx, cy, cx)
    app.alphaMask = initAmaskNoClipGray8(app.alphaRbuf)

  var
    pixf = initPixFmtGray8(app.alphaRbuf)
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)

  app.startTimer()
  if app.operation.curItem() == 0:
    rb.clear(initGray8(0))
    ren.color(initGray8(255))
  else:
    rb.clear(initGray8(255))
    ren.color(initGray8(0))

  app.ras.addPath(vs)
  renderScanlines(app.ras, app.sl, ren)

  let t1 = app.elapsedTime()
  let renTime = formatFloat(t1, ffDecimal, 3)
  let text = "Generate AlphaMask: $1ms" % [renTime]
  app.drawText(250, 20, text)

proc performRendering[VertexSource](app: App, vs: var VertexSource) =
  var
    pf    = construct(PixFmt, app.rbufWindow())
    pixfa = initPixFmtAmaskAdaptor(pf, app.alphaMask)
    rbase = initRendererBase(pixfa)
    ren   = initRendererScanlineAASolid(rbase)

  ren.color(initRgba(0.5, 0.0, 0, 0.5))

  app.startTimer()
  app.ras.reset()
  app.ras.addPath(vs)
  renderScanlines(app.ras, app.sl, ren)

  let t1 = app.elapsedTime()
  let renTime = formatFloat(t1, ffDecimal, 3)
  let text = "Render with AlphaMask: $1ms" % [renTime]
  app.drawText(250, 5, text)

proc renderGBSpiral(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sp     = initSpiral(app.mx, app.my, 10, 150, 30, 0.0)
    stroke = initConvStroke(sp)
    gbPoly = initPathStorage()
    mtx    = initTransAffine()

  stroke.width(15.0)
  makeGBPoly(gbPoly)

  mtx *= transAffineTranslation(-1150, -1150)
  mtx *= transAffineScaling(2.0)

  var trans = initConvTransform(gbPoly, mtx)

  app.ras.addPath(trans)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  var strokegb = initConvStroke(trans)
  strokegb.width(0.1)

  app.ras.addPath(strokegb)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(app.ras, app.sl, ren)

  app.ras.addPath(stroke)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(app.ras, app.sl, ren)
  app.generateAlphaMask(trans)
  app.performRendering(stroke)

proc renderSimplePaths(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
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
  ps1.lineTo(x+268, y+309)
  ps1.lineTo(x+325, y+261)

  ps1.moveTo(x+259, y+259)
  ps1.lineTo(x+273, y+288)
  ps1.lineTo(x+298, y+266)

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)

  app.ras.reset()
  app.ras.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.ras.reset()
  app.ras.addPath(ps2)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.generateAlphaMask(ps1)
  app.performRendering(ps2)

proc renderClosedStroke(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    ps1 = initPathStorage()
    ps2 = initPathStorage()
    x = app.mx - app.width()/2 + 100
    y = app.my - app.height()/2 + 100
    stroke = initConvStroke(ps2)

  stroke.width(10.0)

  ps1.moveTo(x+140, y+145)
  ps1.lineTo(x+225, y+44)
  ps1.lineTo(x+296, y+219)
  ps1.closePolygon()

  ps1.lineTo(x+226, y+289)
  ps1.lineTo(x+82,  y+292)

  ps1.moveTo(x+220-50, y+222)
  ps1.lineTo(x+265-50, y+331)
  ps1.lineTo(x+363-50, y+249)
  ps1.closePolygon(pathFlagsCcw)

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)
  ps2.closePolygon()

  app.ras.reset()
  app.ras.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.ras.reset()
  app.ras.addPath(stroke)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.generateAlphaMask(ps1)
  app.performRendering(stroke)

proc renderGBArrow(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    gbPoly = initPathStorage()
    arrows = initPathStorage()
    mtx1 = initTransAffine()
    mtx2 = initTransAffine()

  makeGBPoly(gbPoly)
  makeArrows(arrows)

  mtx1 *= transAffineTranslation(-1150, -1150)
  mtx1 *= transAffineScaling(2.0)

  mtx2 = mtx1
  mtx2 *= transAffineTranslation(app.mx - app.width()/2, app.my - app.height()/2)

  var
    transGBPoly = initConvTransform(gbPoly, mtx1)
    transArrows = initConvTransform(arrows, mtx2)

  app.ras.addPath(transGBPoly)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  var stroke_gbPoly = initConvStroke(transGBPoly)
  stroke_gbPoly.width(0.1)
  app.ras.reset()
  app.ras.addPath(stroke_gbPoly)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(app.ras, app.sl, ren)

  app.ras.reset()
  app.ras.addPath(transArrows)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.generateAlphaMask(transGBPoly)
  app.performRendering(transArrows)

proc renderSpiralAndGlyph(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
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

  app.ras.reset()
  app.ras.addPath(stroke)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.ras.reset()
  app.ras.addPath(curve)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(app.ras, app.sl, ren)

  app.generateAlphaMask(stroke)
  app.performRendering(curve)

method onInit(app: App) =
  app.mx = app.width() / 2.0
  app.my = app.height() / 2.0

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)

  rb.clear(initRgba(1,1,1))

  case app.polygons.curItem()
  of 0: app.renderSimplePaths()
  of 1: app.renderClosedStroke()
  of 2: app.renderGBArrow()
  of 3: app.renderGBSpiral()
  of 4: app.renderSpiralAndGlyph()
  else: discard

  renderCtrl(app.ras, app.sl, rb, app.polygons)
  renderCtrl(app.ras, app.sl, rb, app.operation)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mx = x.float64
    app.my = y.float64
    app.forceRedraw()

  if mouseRight in flags:
    var buf = "$1 $2" % [$x, $y]
    app.message(buf)

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.mx = x.float64
    app.my = y.float64
    app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Alpha-Mask as a Polygon Clipper")

  if app.init(frameWidth, frameHeight, {window_resize}, "alpha_mask"):
    return app.run()

  result = 1

discard main()
