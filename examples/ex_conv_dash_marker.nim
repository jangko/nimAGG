import agg/[basics, rendering_buffer, rasterizer_scanline_aa, conv_stroke,
  conv_dash, conv_curve, conv_contour, conv_smooth_poly1, conv_marker,
  arrowhead, vcgen_markers_term, scanline_u, renderer_scanline, pixfmt_rgb,
  color_rgba, renderer_base, vector, path_storage]
import ctrl/[slider, rbox, cbox], math, platform.support

const
  frameWidth = 500
  frameHeight = 330
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    cap: RboxCtrl[Rgba8]
    width: SliderCtrl[Rgba8]
    smooth: SliderCtrl[Rgba8]
    close: CboxCtrl[Rgba8]
    evenOdd: CboxCtrl[Rgba8]
    x, y: array[3, float64]
    dx, dy: float64
    idx: int

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.idx = -1
  result.cap = newRboxCtrl[Rgba8](10.0, 10.0, 130.0, 80.0, not flipY)
  result.width = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 130 + 150.0, 10.0 + 8.0 + 4.0, not flipY)
  result.smooth = newSliderCtrl[Rgba8](130 + 150.0 + 10.0, 10.0 + 4.0, 500 - 10.0, 10.0 + 8.0 + 4.0, not flipY)
  result.close = newCboxCtrl[Rgba8](130 + 10.0, 10.0 + 4.0 + 16.0,    "Close Polygons", not flipY)
  result.evenOdd = newCboxCtrl[Rgba8](130 + 150.0 + 10.0, 10.0 + 4.0 + 16.0, "Even-Odd Fill", not flipY)

  result.addCtrl(result.cap)
  result.addCtrl(result.width)
  result.addCtrl(result.smooth)
  result.addCtrl(result.close)
  result.addCtrl(result.evenOdd)

  result.x[0] = 57 + 100; result.y[0] = 60.0
  result.x[1] = 369 + 100; result.y[1] = 170.0
  result.x[2] = 143 + 100; result.y[2] = 310.0
  result.cap.addItem("Butt Cap")
  result.cap.addItem("Square Cap")
  result.cap.addItem("Round Cap")
  result.cap.curItem(0)
  result.cap.noTransform()
  result.width.setRange(0.0, 10.0)
  result.width.value(3.0)
  result.width.label("Width=$1")
  result.width.noTransform()
  result.smooth.setRange(0.0, 2.0)
  result.smooth.value(1.0)
  result.smooth.label("Smooth=$1")
  result.smooth.noTransform()
  result.close.noTransform()
  result.evenOdd.status(true)
  result.evenOdd.noTransform()

podAutoVector(AutoVec, VertexD, 20)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

  rb.clear(initRgba(1.0, 1.0, 1.0))
  var cap = LineCap.buttCap
  if app.cap.curItem() == 1: cap = LineCap.squareCap
  if app.cap.curItem() == 2: cap = LineCap.roundCap

  # Here we declare a very cheap-in-use path storage.
  # It allocates space for at most 20 vertices in stack and
  # never allocates memory. But be aware that adding more than
  # 20 vertices is fatal!
  var path = initPathBase[VertexStlStorage[AutoVec]]()

  path.moveTo(app.x[0], app.y[0])
  path.lineTo(app.x[1], app.y[1])
  path.lineTo((app.x[0]+app.x[1]+app.x[2]) / 3.0, (app.y[0]+app.y[1]+app.y[2]) / 3.0)
  path.lineTo(app.x[2], app.y[2])
  if app.close.status(): path.closePolygon()

  path.moveTo((app.x[0] + app.x[1]) / 2, (app.y[0] + app.y[1]) / 2)
  path.lineTo((app.x[1] + app.x[2]) / 2, (app.y[1] + app.y[2]) / 2)
  path.lineTo((app.x[2] + app.x[0]) / 2, (app.y[2] + app.y[0]) / 2)
  if app.close.status(): path.closePolygon()

  if app.evenOdd.status(): ras.fillingRule(fillEvenOdd)

  ras.addPath(path)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0.7, 0.5, 0.1, 0.5))

  var
    smooth = initConvSmoothPoly1(path)
    smoothOutline = initConvStroke(smooth)
    curve = initConvCurve(smooth)
    dash = initConvDash(curve, VCgenMarkersTerm)
    stroke = initConvStroke(dash)

  smooth.smoothValue(app.smooth.value())
  ras.addPath(smooth)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0.1, 0.5, 0.7, 0.1))

  ras.addPath(smoothOutline)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0.0, 0.6, 0.0, 0.8))

  stroke.lineCap(cap)
  stroke.width(app.width.value())

  var
    k = math.pow(app.width.value(), 0.7)
    ah = initArrowHead()

  ah.head(4 * k, 4 * k, 3 * k, 2 * k)
  if not app.close.status():
    ah.tail(1 * k, 1.5 * k, 3 * k, 5 * k)

  #agg::conv_marker<agg::vcgen_markers_term, agg::arrowhead>
  var arrow = initConvMarker(dash.markers(), ah)

  dash.addDash(20.0, 5.0)
  dash.addDash(5.0, 5.0)
  dash.addDash(5.0, 5.0)
  dash.dashStart(10)

  ras.addPath(stroke)
  ras.addPath(arrow)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.0, 0.0, 0.0))

  ras.fillingRule(fillNonZero)
  renderCtrl(ras, sl, rb, app.cap)
  renderCtrl(ras, sl, rb, app.width)
  renderCtrl(ras, sl, rb, app.smooth)
  renderCtrl(ras, sl, rb, app.close)
  renderCtrl(ras, sl, rb, app.evenOdd)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Line Join")

  if app.init(frameWidth, frameHeight, {}, "conv_dash_marker"):
    return app.run()

  result = 1

discard main()
