import agg_rendering_buffer, agg_conv_transform, agg_conv_stroke, agg_conv_dash
import agg_scanline_u, agg_renderer_scanline, agg_rasterizer_outline_aa, agg_rasterizer_scanline_aa
import agg_pattern_filters_rgba, agg_renderer_outline_aa, agg_renderer_outline_image, agg_arc
import agg_bezier_arc, agg_pixfmt_rgb, ctrl_slider, ctrl_bezier, ctrl_rbox, ctrl_cbox
import agg_renderer_base, agg_color_rgba, times, agg_basics, agg_math, agg_vertex_sequence
import math, agg_path_storage, nimBMP, agg_ellipse, agg_gsv_text, strutils, random

proc bezier4Point(x1, y1, x2, y2, x3, y3, x4, y4, mu: float64; x, y: var float64) =
   var mum1, mum13, mu3: float64

   mum1 = 1 - mu
   mum13 = mum1 * mum1 * mum1
   mu3 = mu * mu * mu

   x = mum13*x1 + 3*mu*mum1*mum1*x2 + 3*mu*mu*mum1*x3 + mu3*x4
   y = mum13*y1 + 3*mu*mum1*mum1*y2 + 3*mu*mu*mum1*y3 + mu3*y4

const
  frameWidth = 655
  frameHeight = 520
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    ctrlColor: Rgba8
    curve1: BezierCtrl[Rgba8]
    angleTolerance: SliderCtrl[Rgba8]
    approximationScale: SliderCtrl[Rgba8]
    cuspLimit: SliderCtrl[Rgba8]
    width: SliderCtrl[Rgba8]
    showPoints: CboxCtrl[Rgba8]
    showOutline: CboxCtrl[Rgba8]
    curveType: RboxCtrl[Rgba8]
    caseType: RboxCtrl[Rgba8]
    innerJoin: RboxCtrl[Rgba8]
    lineJoin: RboxCtrl[Rgba8]
    lineCap: RboxCtrl[Rgba8]
    curCaseType: int

proc initApp(): App =
  result.ctrlColor = construct(Rgba8, initRgba(0, 0.3, 0.5, 0.8))
  result.curve1 = newBezierCtrl[Rgba8]()
  result.angleTolerance     = newSliderCtrl[Rgba8](5.0, 5.0, 240.0, 12.0            , not flipY)
  result.approximationScale = newSliderCtrl[Rgba8](5.0, 17+5.0, 240.0, 17+12.0      , not flipY)
  result.cuspLimit          = newSliderCtrl[Rgba8](5.0, 17+17+5.0, 240.0, 17+17+12.0, not flipY)
  result.width              = newSliderCtrl[Rgba8](245.0, 5.0,           495.0, 12.0, not flipY)
  result.showPoints         = newCboxCtrl[Rgba8](250.0,  15+5, "Show Points"        , not flipY)
  result.showOutline        = newCboxCtrl[Rgba8](250.0,  30+5, "Show Stroke Outline", not flipY)
  result.curveType          = newRboxCtrl[Rgba8](535.0,   5.0, 535.0+115.0,   55.0  , not flipY)
  result.caseType           = newRboxCtrl[Rgba8](535.0,  60.0, 535.0+115.0,   195.0 , not flipY)
  result.innerJoin          = newRboxCtrl[Rgba8](535.0, 200.0, 535.0+115.0,   290.0 , not flipY)
  result.lineJoin           = newRboxCtrl[Rgba8](535.0, 295.0, 535.0+115.0,   385.0 , not flipY)
  result.lineCap            = newRboxCtrl[Rgba8](535.0, 395.0, 535.0+115.0,   455.0 , not flipY)
  result.curCaseType = -1

  result.curve1.lineColor(result.ctrlColor)
  result.curve1.curve(170.0, 424.0, 13.0, 87.0, 488.0, 423.0, 26.0, 333.0)
  result.curve1.noTransform()

  result.angleTolerance.label("Angle Tolerance=$1 deg")
  result.angleTolerance.setRange(0, 90)
  result.angleTolerance.value(15)
  result.angleTolerance.noTransform()

  result.approximationScale.label("Approximation Scale=$1")
  result.approximationScale.setRange(0.1, 5)
  result.approximationScale.value(1.0)
  result.approximationScale.noTransform()

  result.cusp_limit.label("Cusp Limit=$1 deg")
  result.cusp_limit.setRange(0, 90)
  result.cusp_limit.value(0)
  result.cusp_limit.noTransform()

  result.width.label("Width=$1")
  result.width.setRange(-50, 100)
  result.width.value(50.0)
  result.width.noTransform()

  result.showPoints.noTransform()
  result.showPoints.status(true)

  result.showOutline.noTransform()
  result.showOutline.status(true)

  result.curveType.addItem("Incremental")
  result.curveType.addItem("Subdiv")
  result.curveType.curItem(1)
  result.curveType.noTransform()

  result.caseType.textSize(7)
  result.caseType.textThickness(1.0)
  result.caseType.addItem("Random")
  result.caseType.addItem("13---24")
  result.caseType.addItem("Smooth Cusp 1")
  result.caseType.addItem("Smooth Cusp 2")
  result.caseType.addItem("Real Cusp 1")
  result.caseType.addItem("Real Cusp 2")
  result.caseType.addItem("Fancy Stroke")
  result.caseType.addItem("Jaw")
  result.caseType.addItem("Ugly Jaw")
  result.caseType.noTransform()

  result.innerJoin.textSize(8)
  result.innerJoin.addItem("Inner Bevel")
  result.innerJoin.addItem("Inner Miter")
  result.innerJoin.addItem("Inner Jag")
  result.innerJoin.addItem("Inner Round")
  result.innerJoin.curItem(3)
  result.innerJoin.noTransform()

  result.lineJoin.textSize(8)
  result.lineJoin.addItem("Miter Join")
  result.lineJoin.addItem("Miter Revert")
  result.lineJoin.addItem("Round Join")
  result.lineJoin.addItem("Bevel Join")
  result.lineJoin.addItem("Miter Round")
  result.lineJoin.curItem(1)
  result.lineJoin.noTransform()

  result.lineCap.textSize(8)
  result.lineCap.addItem("Butt Cap")
  result.lineCap.addItem("Square Cap")
  result.lineCap.addItem("Round Cap")
  result.lineCap.curItem(0)
  result.lineCap.noTransform()

proc measureTime[Curve](app: App, curve: var Curve): float64 =
  let startTime = cpuTime()
  for i in 0.. <100:
    var x, y: float64
    curve.init(app.curve1.x1(), app.curve1.y1(),
               app.curve1.x2(), app.curve1.y2(),
               app.curve1.x3(), app.curve1.y3(),
               app.curve1.x4(), app.curve1.y4())
    curve.rewind(0)
    var cmd = curve.vertex(x, y)
    while not isStop(cmd):
      cmd = curve.vertex(x, y)
  result = cpuTime() - startTime

proc findPoint[Path](path: var Path, dist: float64, i, j: var int): bool =
  j = path.len - 1
  i = 0

  while (j - i) > 1:
    let k = (i + j) shr 1
    if dist < path[k].dist: j = k
    else:                   i = k
  result = true

type
  CurvePoint = object
    x, y, dist, mu: float64

proc initCurvePoint(x1, y1, mu1: float64): CurvePoint =
  result.x = x1
  result.y = y1
  result.mu = mu1

proc calcMaxError[Curve](app: var App, curve: var Curve, scale: float64,  maxAngleError: var float64): float64 =
  curve.approximationScale(app.approximationScale.value() * scale)
  curve.init(app.curve1.x1(), app.curve1.y1(),
             app.curve1.x2(), app.curve1.y2(),
             app.curve1.x3(), app.curve1.y3(),
             app.curve1.x4(), app.curve1.y4())

  var
    cmd: uint
    x, y: float64
    curvePoints = newSeq[VertexDist]()
    curveDist = 0.0
    referencePoints = newSeq[CurvePoint]()
    referenceDist = 0.0

  curve.rewind(0)
  cmd = curve.vertex(x, y)
  while not isStop(cmd):
    if isVertex(cmd):
      curvePoints.add(initVertexDist(x, y))
    cmd = curve.vertex(x, y)

  for i in 1.. <curvePoints.len:
    curvePoints[i - 1].dist = curveDist
    curveDist += calcDistance(curvePoints[i-1].x,
                              curvePoints[i-1].y,
                              curvePoints[i].x,
                              curvePoints[i].y)

  curvePoints[curvePoints.len - 1].dist = curveDist

  for i in 0.. <4096:
    let mu = i.float64 / 4095.0
    bezier4Point(app.curve1.x1(), app.curve1.y1(),
                 app.curve1.x2(), app.curve1.y2(),
                 app.curve1.x3(), app.curve1.y3(),
                 app.curve1.x4(), app.curve1.y4(),
                 mu, x, y)
    referencePoints.add(initCurvePoint(x, y, mu))

  for i in 1.. <referencePoints.len:
    referencePoints[i - 1].dist = referenceDist
    referenceDist += calcDistance(referencePoints[i-1].x,
                                  referencePoints[i-1].y,
                                  referencePoints[i].x,
                                  referencePoints[i].y)

  referencePoints[referencePoints.len - 1].dist = referenceDist

  var
    idx1 = 0
    idx2 = 1
    maxError = 0.0
    aerr = 0.0

  for i in 0.. <referencePoints.len:
    if findPoint(curvePoints, referencePoints[i].dist, idx1, idx2):
      let err = abs(calcLinePointDistance(curvePoints[idx1].x,  curvePoints[idx1].y,
                                          curvePoints[idx2].x,  curvePoints[idx2].y,
                                          referencePoints[i].x, referencePoints[i].y))
      if err > maxError: maxError = err

  for i in 2.. <curvePoints.len:
    let a1 = arctan2(curvePoints[i-1].y - curvePoints[i-2].y,
                     curvePoints[i-1].x - curvePoints[i-2].x)
    let a2 = arctan2(curvePoints[i].y - curvePoints[i-1].y,
                     curvePoints[i].x - curvePoints[i-1].x)

    var da = abs(a1 - a2)
    if da >= pi: da = 2 * pi - da
    if da > aerr: aerr = da

  maxAngleError = aerr * 180.0 / pi
  result = maxError * scale

proc on_ctrl_change(app: var App) =
  if app.caseType.curItem() != app.curCaseType:
    case app.caseType.curItem()
    of 0: #m_of_type.add_item("Random");
      let
        w = float64(frameWidth - 120)
        h = float64(frameHeight - 80)
      app.curve1.curve(random(w), random(h)+ 80.0, random(w), random(h) + 80.0,
                       random(w), random(h)+ 80.0, random(w), random(h) + 80.0)
    of 1: #m_of_type.add_item("13---24");
      app.curve1.curve(150, 150, 350, 150, 150, 150, 350, 150)
        #app.curve1.curve(252, 227, 16, 227, 506, 227, 285, 227);
        #app.curve1.curve(252, 227, 16, 227, 387, 227, 285, 227);
    of 2: #m_of_type.add_item("Smooth Cusp 1");
      app.curve1.curve(50, 142, 483, 251, 496, 62, 26, 333)
    of 3: #m_of_type.add_item("Smooth Cusp 2");
      app.curve1.curve(50, 142, 484, 251, 496, 62, 26, 333)
    of 4: #m_of_type.add_item("Real Cusp 1");
      app.curve1.curve(100, 100, 300, 200, 200, 200, 200, 100)
    of 5: #m_of_type.add_item("Real Cusp 2");
      app.curve1.curve(475, 157, 200, 100, 453, 100, 222, 157)
    of 6: #m_of_type.add_item("Fancy Stroke");
      app.curve1.curve(129, 233, 32, 283, 258, 285, 159, 232)
      app.width.value(100)
    of 7: #m_of_type.add_item("Jaw");
      app.curve1.curve(100, 100, 300, 200, 264, 286, 264, 284)
    of 8: #m_of_type.add_item("Ugly Jaw");
      app.curve1.curve(100, 100, 413, 304, 264, 286, 264, 284)
    else:
      discard
    app.curCaseType = app.caseType.curItem()

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    path   = initPathStorage()
    x, y: float64
    curveTime = 0.0
    curve  = initCurve4()

  rb.clear(initRgba(1.0, 1.0, 0.95))
  path.removeAll()
  curve.approximationMethod(CurveApproximationMethod(app.curveType.curItem()))
  curve.approximationScale(app.approximationScale.value())
  curve.angleTolerance(deg2rad(app.angleTolerance.value()))
  curve.cuspLimit(deg2rad(app.cuspLimit.value()))
  curveTime = app.measureTime(curve)

  var
    max_angle_error_001 = 0.0
    max_angle_error_01 = 0.0
    max_angle_error1 = 0.0
    max_angle_error_10 = 0.0
    max_angle_error_100 = 0.0
    max_error_001 = 0.0
    max_error_01 = 0.0
    max_error1 = 0.0
    max_error_10 = 0.0
    max_error_100 = 0.0

  max_error_001   = app.calcMaxError(curve, 0.01, max_angle_error_001)
  max_error_01    = app.calcMaxError(curve, 0.1,  max_angle_error_01)
  max_error1     = app.calcMaxError(curve, 1,    max_angle_error1)
  max_error_10   = app.calcMaxError(curve, 10,   max_angle_error_10)
  max_error_100  = app.calcMaxError(curve, 100,  max_angle_error_100)

  curve.approximationScale(app.approximationScale.value())
  curve.angleTolerance(deg2rad(app.angleTolerance.value()))
  curve.cuspLimit(deg2rad(app.cuspLimit.value()))
  curve.init(app.curve1.x1(), app.curve1.y1(),
             app.curve1.x2(), app.curve1.y2(),
             app.curve1.x3(), app.curve1.y3(),
             app.curve1.x4(), app.curve1.y4())

  path.concatPath(curve)

  var stroke = initConvStroke(path)

  stroke.width(app.width.value())
  stroke.lineJoin(LineJoin(app.lineJoin.curItem()))
  stroke.lineCap(LineCap(app.lineCap.curItem()))
  stroke.innerJoin(InnerJoin(app.innerJoin.curItem()))
  stroke.innerMiterLimit(1.01)

  ras.addPath(stroke)
  ren.color(initRgba(0, 0.5, 0, 0.5))
  renderScanlines(ras, sl, ren)

  var
    cmd: uint
    numPoints1 = 0

  path.rewind(0)
  cmd = path.vertex(x, y)
  while not isStop(cmd):
    if app.showPoints.status():
      var ell = initEllipse(x.float64, y.float64, 1.5, 1.5, 8)
      ras.addPath(ell)
      ren.color(initRgba(0,0,0, 0.5))
      renderScanlines(ras, sl, ren)
    inc numPoints1
    cmd = path.vertex(x, y)

  if app.showOutline.status():
    # Draw a stroke of the stroke to see the internals
    var stroke2 = initConvStroke(stroke)
    ras.addPath(stroke2)
    ren.color(initRgba(0,0,0, 0.5))
    renderScanlines(ras, sl, ren)

  var
    t = initGsvText()
    pt = initconvStroke(t)

  t.size(8.0)
  pt.lineCap(LineCap.roundCap)
  pt.lineJoin(LineJoin.roundJoin)
  pt.width(1.5)

  var buf = "Num Points=$1 Time=$2mks\n"
  buf.add "Dist Error: x0.01=$3 x0.1=$4 x1=$5 x10=$6 x100=$7\n"
  buf.add "Angle Error: x0.01=$8 x0.1=$9 x1=$10 x10=$11 x100=$12"

  buf = buf % [$numPoints1, curveTime.formatFloat(ffDecimal, 2),
    max_error_01.formatFloat(ffDecimal, 5),
    max_error_1.formatFloat(ffDecimal, 5),
    max_error1.formatFloat(ffDecimal, 5),
    max_error_10.formatFloat(ffDecimal, 5),
    max_error_100.formatFloat(ffDecimal, 5),
    max_angle_error_01.formatFloat(ffDecimal, 1),
    max_angle_error_1.formatFloat(ffDecimal, 1),
    max_angle_error1.formatFloat(ffDecimal, 1),
    max_angle_error_10.formatFloat(ffDecimal, 1),
    max_angle_error_100.formatFloat(ffDecimal, 1)]

  t.startPoint(10.0, 85.0)
  t.text(buf)

  ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.curve1)
  renderCtrl(ras, sl, rb, app.angleTolerance)
  renderCtrl(ras, sl, rb, app.approximationScale)
  renderCtrl(ras, sl, rb, app.cuspLimit)
  renderCtrl(ras, sl, rb, app.width)
  renderCtrl(ras, sl, rb, app.showPoints)
  renderCtrl(ras, sl, rb, app.showOutline)
  renderCtrl(ras, sl, rb, app.curveType)
  renderCtrl(ras, sl, rb, app.caseType)
  renderCtrl(ras, sl, rb, app.innerJoin)
  renderCtrl(ras, sl, rb, app.lineJoin)
  renderCtrl(ras, sl, rb, app.lineCap)

  saveBMP24("bezier_div.bmp", buffer, frameWidth, frameHeight)

onDraw()
