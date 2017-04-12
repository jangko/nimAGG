import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_scanline_p, agg_renderer_scanline, agg_renderer_primitives, agg_conv_curve
import agg_conv_stroke, agg_conv_clip_polygon, agg_gsv_text, agg_pixfmt_rgb
import ctrl_slider, ctrl_cbox, ctrl_rbox, agg_conv_poly_bool, make_arrows, make_gb_poly
import nimBMP, agg_color_rgba, times, strutils, agg_renderer_base, agg_path_storage
import agg_trans_affine, agg_conv_transform

const
  frameWidth = 640
  frameHeight = 520
  flipY = true
  pixWidth = 3

type
  ValueT = uint8

# A simple counter of points and contours
type
  ConvPolyCounter[VS] = object
    mContours: int
    mPoints: int
    mSrc: ptr VS

proc initConvPolyCounter[VS](vs: var VS): ConvPolyCounter[VS] =
  result.mSrc = vs.addr
  result.mContours = 0
  result.mPoints = 0

proc rewind[VS](self: var ConvPolyCounter[VS], pathId: int) =
  self.mContours = 0
  self.mPoints = 0
  self.mSrc[].rewind(pathId)

proc vertex[VS](self: var ConvPolyCounter[VS], x, y: var float64): uint =
  let cmd = self.mSrc[].vertex(x, y)
  if isVertex(cmd): inc self.mPoints
  if isMoveTo(cmd): inc self.mContours
  result = cmd

type
  App = object
    mX, mY: float64
    mPolygons: RboxCtrl[Rgba8]
    mOperation: RboxCtrl[Rgba8]
    buffer: seq[ValueT]
    rbuf: RenderingBuffer

proc initApp(op = 2, shape = 3): App =
  result.mPolygons  = newRboxCtrl[Rgba8](5.0,     5.0, 5.0+205.0,  110.0, not flipY)
  result.mOperation = newRboxCtrl[Rgba8](555.0,   5.0, 555.0+80.0, 130.0, not flipY)

  result.mOperation.addItem("None")
  result.mOperation.addItem("OR")
  result.mOperation.addItem("AND")
  result.mOperation.addItem("XOR")
  result.mOperation.addItem("A-B")
  result.mOperation.addItem("B-A")
  result.mOperation.curItem(op)

  result.mPolygons.addItem("Two Simple Paths")
  result.mPolygons.addItem("Closed Stroke")
  result.mPolygons.addItem("Great Britain and Arrows")
  result.mPolygons.addItem("Great Britain and Spiral")
  result.mPolygons.addItem("Spiral and Glyph")
  result.mPolygons.curItem(shape)

  result.mX = frameWidth.float64 / 2.0
  result.mY = frameHeight.float64 / 2.0

  result.buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
  result.rbuf   = initRenderingBuffer(result.buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixWidth)

proc performRendering[Scanline, Ras, Ren, Clp](app: var App, sl: var Scanline,
  ras: var Ras, ren: var Ren, clp: var Clp) =

  if app.mOperation.curItem() == 0: return

  ras.reset()
  case app.mOperation.curItem()
  of 1: clp.operation(polyBoolUnion)
  of 2: clp.operation(polyBoolIntersect)
  of 3: clp.operation(polyBoolXor)
  of 4: clp.operation(polyBoolAMinusB)
  of 5: clp.operation(polyBoolBMinusA)
  else: discard

  var
    counter = initConvPolyCounter(clp)
    startTime = cpuTime()

  counter.rewind(0)
  let t1 = cpuTime() - startTime
  startTime = cpuTime()

  var 
    ps = initPathStorage()
    x, y: float64
    cmd = counter.vertex(x, y)
    
  while not isStop(cmd):
    if isMoveTo(cmd):
      ps.moveTo(x, y)
    elif isLineTo(cmd):
      ps.lineTo(x, y)
    elif isClose(cmd):
      ps.closePolygon()
      
    cmd = counter.vertex(x, y)
      
  ras.addPath(ps)
  ren.color(initRgba(0.25, 0.9, 0.25, 0.65))
  renderScanlines(ras, sl, ren)

  let t2 = cpuTime() - startTime

  var
    stroke = initConvStroke(ps)

  stroke.width(0.4)
  ras.addPath(stroke)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras, sl, ren)

  var
    buf = "Contours: $1  Points: $2" % [$counter.mContours, $counter.mPoints]
    txt = initGsvText()
    txtStroke = initConvStroke(txt)

  txtStroke.width(1.5)
  txtStroke.lineCap(LineCap.roundCap)
  txt.size(10.0)
  txt.startPoint(250, 5)
  txt.text(buf)

  ras.addPath(txtStroke)
  ren.color(initRgba(0.0, 0.0, 0.0))
  renderScanlines(ras, sl, ren)

  buf = "Clipper=$1ms Render=$2ms" % [t1.formatFloat(ffDecimal, 3), t2.formatFloat(ffDecimal, 3)]
  txt.startPoint(250, 20)
  txt.text(buf)
  ras.addPath(txtStroke)
  ren.color(initRgba(0.0, 0.0, 0.0))
  renderScanlines(ras, sl, ren)

proc initSimplePaths(ps1, ps2: var PathStorage, x, y: float64) =
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

  ps2.moveTo(100.0+32,  100.0+77)
  ps2.lineTo(100.0+473, 100.0+263)
  ps2.lineTo(100.0+351, 100.0+290)
  ps2.lineTo(100.0+354, 100.0+374)

proc initClosedStroke(ps1, ps2: var PathStorage, x, y: float64) =
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

proc initGlyph(ps: var PathStorage) =
  ps.moveTo(28.47, 6.45)
  ps.curve3(21.58, 1.12, 19.82, 0.29)
  ps.curve3(17.19, -0.93, 14.21, -0.93)
  ps.curve3(9.57, -0.93, 6.57, 2.25)
  ps.curve3(3.56, 5.42, 3.56, 10.60)
  ps.curve3(3.56, 13.87, 5.03, 16.26)
  ps.curve3(7.03, 19.58, 11.99, 22.51)
  ps.curve3(16.94, 25.44, 28.47, 29.64)
  ps.lineTo(28.47, 31.40)
  ps.curve3(28.47, 38.09, 26.34, 40.58)
  ps.curve3(24.22, 43.07, 20.17, 43.07)
  ps.curve3(17.09, 43.07, 15.28, 41.41)
  ps.curve3(13.43, 39.75, 13.43, 37.60)
  ps.lineTo(13.53, 34.77)
  ps.curve3(13.53, 32.52, 12.38, 31.30)
  ps.curve3(11.23, 30.08, 9.38, 30.08)
  ps.curve3(7.57, 30.08, 6.42, 31.35)
  ps.curve3(5.27, 32.62, 5.27, 34.81)
  ps.curve3(5.27, 39.01, 9.57, 42.53)
  ps.curve3(13.87, 46.04, 21.63, 46.04)
  ps.curve3(27.59, 46.04, 31.40, 44.04)
  ps.curve3(34.28, 42.53, 35.64, 39.31)
  ps.curve3(36.52, 37.21, 36.52, 30.71)
  ps.lineTo(36.52, 15.53)
  ps.curve3(36.52, 9.13, 36.77, 7.69)
  ps.curve3(37.01, 6.25, 37.57, 5.76)
  ps.curve3(38.13, 5.27, 38.87, 5.27)
  ps.curve3(39.65, 5.27, 40.23, 5.62)
  ps.curve3(41.26, 6.25, 44.19, 9.18)
  ps.lineTo(44.19, 6.45)
  ps.curve3(38.72, -0.88, 33.74, -0.88)
  ps.curve3(31.35, -0.88, 29.93, 0.78)
  ps.curve3(28.52, 2.44, 28.47, 6.45)
  ps.closePolygon()

  ps.moveTo(28.47, 9.62)
  ps.lineTo(28.47, 26.66)
  ps.curve3(21.09, 23.73, 18.95, 22.51)
  ps.curve3(15.09, 20.36, 13.43, 18.02)
  ps.curve3(11.77, 15.67, 11.77, 12.89)
  ps.curve3(11.77, 9.38, 13.87, 7.06)
  ps.curve3(15.97, 4.74, 18.70, 4.74)
  ps.curve3(22.41, 4.74, 28.47, 9.62)
  ps.closePolygon()

template renderAux(vs1, vs2, ras, sl, ren: typed) =
  ras.reset()
  ras.addPath(vs1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras, sl, ren)

  ras.reset()
  ras.addPath(vs2)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras, sl, ren)

template renderAux2(vs1, vs2, ras, sl, ren: typed) =
  ras.addPath(vs1)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(ras, sl, ren)

  var strokevs1 = initConvStroke(vs1)
  strokevs1.width(0.1)

  ras.addPath(strokevs1)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras, sl, ren)

  ras.addPath(vs2)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(ras, sl, ren)


proc renderClipper[Scanline, Ras](app: var App, sl: var Scanline, ras: var Ras) =
  var
    pf  = initPixFmtRgb24(app.rbuf)
    rb  = initRendererBase(pf)
    ren = initRendererScanlineAASolid(rb)

  case app.mPolygons.curItem()
  of 0:
    # Two simple paths
    var
      ps1 = initPathStorage()
      ps2 = initPathStorage()
      clp = initConvPolyBool(ps1, ps2)
      x   = app.mX - frameWidth.float64 / 2.0 + 100.0
      y   = app.mY - frameHeight.float64 / 2.0 + 100.0

    initSimplePaths(ps1, ps2, x, y)
    renderAux(ps1, ps2, ras, sl, ren)
    app.performRendering(sl, ras, ren, clp)
  of 1:
    # Closed stroke
    var
      ps1 = initPathStorage()
      ps2 = initPathStorage()
      stroke = initConvStroke(ps2)
      clp = initConvPolyBool(ps1, stroke)
      x   = app.mX - frameWidth.float64 / 2.0 + 100.0
      y   = app.mY - frameHeight.float64 / 2.0 + 100.0

    stroke.width(10.0)
    initClosedStroke(ps1, ps2, x, y)
    renderAux(ps1, stroke, ras, sl, ren)
    app.performRendering(sl, ras, ren, clp)
  of 2:
    # Great Britain and Arrows
    var
      gbPoly = initPathStorage()
      arrows = initPathStorage()
      mtx1   = initTransAffine()
      mtx2   = initTransAffine()
      transGBPoly = initConvTransform(gbPoly, mtx1)
      transArrows = initConvTransform(arrows, mtx2)
      clp = initConvPolyBool(transGBPoly, transArrows)

    mtx1 *= transAffineTranslation(-1150, -1150)
    mtx1 *= transAffineScaling(2.0)

    mtx2 = mtx1
    mtx2 *= transAffineTranslation(app.mX - frameWidth.float64/2.0, app.mY - frameHeight.float64/2.0)

    makeGBPoly(gbPoly)
    makeArrows(arrows)

    renderAux2(transGBPoly, transArrows, ras, sl, ren)
    app.performRendering(sl, ras, ren, clp)
  of 3:
    # Great Britain and a Spiral
    var
      sp = initSpiral(app.mX, app.mY, 10, 150, 30, 0.0)
      spiral = initConvStroke(sp)
      gbPoly = initPathStorage()
      mtx1   = initTransAffine()
      transGBPoly = initConvTransform(gbPoly, mtx1)
      clp = initConvPolyBool(transGBPoly, spiral)

    spiral.width(15.0)
    makeGBPoly(gbPoly)

    mtx1 *= transAffineTranslation(-1150, -1150)
    mtx1 *= transAffineScaling(2.0)

    renderAux2(transGBPoly, spiral, ras, sl, ren)
    app.performRendering(sl, ras, ren, clp)

  of 4:
    # Spiral and glyph
    var
      sp = initSpiral(app.mX, app.mY, 10, 150, 30, 0.0)
      spiral = initConvStroke(sp)
      glyph  = initPathStorage()
      mtx    = initTransAffine()
      trans  = initConvTransform(glyph, mtx)
      curve  = initConvCurve(trans)
      clp    = initConvPolyBool(spiral, curve)

    spiral.width(15.0)
    initGlyph(glyph)

    mtx *= transAffineScaling(4.0)
    mtx *= transAffineTranslation(220, 200)

    renderAux(spiral, curve, ras, sl, ren)
    app.performRendering(sl, ras, ren, clp)
  else: discard

proc onDraw(op = 2, shape = 3) =
  var
    app = initApp(op, shape)
    pf  = initPixFmtRgb24(app.rbuf)
    rb  = initRendererBase(pf)
    sl  = initScanlineU8()
    ras = initRasterizerScanlineAA()

  rb.clear(initRgba(1,1,1))
  
  ras.fillingRule(fillEvenOdd)
  app.renderClipper(sl, ras)

  renderCtrl(ras, sl, rb, app.mPolygons)
  renderCtrl(ras, sl, rb, app.mOperation)
  let name = "poly_bool_$1_$2.bmp" % [$op, $shape]
  echo name
  saveBMP24(name, app.buffer, frameWidth, frameHeight)

for op in 0..5:
  for shape in 0..4:
    onDraw(op, shape)