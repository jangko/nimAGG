import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_conv_stroke
import agg_conv_dash, agg_conv_curve, agg_conv_contour, agg_conv_smooth_poly1
import agg_conv_marker, agg_arrowhead, agg_vcgen_markers_term, agg_scanline_p
import agg_renderer_scanline, agg_pixfmt_rgb, ctrl_slider, ctrl_rbox, agg_color_rgba
import agg_renderer_base, agg_path_storage, agg_platform_support

const
  frameWidth = 500
  frameHeight = 330
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)
  
  App = ref object of PlatformSupport
    join: RboxCtrl[Rgba8]
    cap: RboxCtrl[Rgba8]
    width: SliderCtrl[Rgba8]
    miterLimit: SliderCtrl[Rgba8]
    x, y: array[3, float64]
    dx, dy: float64
    idx: int

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)
  
  result.idx = -1
  result.join = newRboxCtrl[Rgba8](10.0, 10.0, 133.0, 80.0, not flipY)
  result.cap  = newRboxCtrl[Rgba8](10.0, 80.0 + 10.0, 133.0, 80.0 + 80.0, not flipY)
  result.width = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 500.0 - 10.0, 10.0 + 8.0 + 4.0, not flipY)
  result.miterLimit= newSliderCtrl[Rgba8](130 + 10.0, 20.0 + 10.0 + 4.0, 500.0 - 10.0, 20.0 + 10.0 + 8.0 + 4.0, not flipY)

  result.addCtrl(result.join)
  result.addCtrl(result.cap)
  result.addCtrl(result.width)
  result.addCtrl(result.miterLimit)

  result.x[0] = 57  + 100; result.y[0] = 60
  result.x[1] = 369 + 100; result.y[1] = 170
  result.x[2] = 143 + 100; result.y[2] = 310

  result.join.textSize(7.5)
  result.join.textThickness(1.0)
  result.join.addItem("Miter Join")
  result.join.addItem("Miter Join Revert")
  result.join.addItem("Round Join")
  result.join.addItem("Bevel Join")
  result.join.curItem(2)
  result.cap.addItem("Butt Cap")
  result.cap.addItem("Square Cap")
  result.cap.addItem("Round Cap")
  result.cap.curItem(2)
  result.width.setRange(3.0, 40.0)
  result.width.value(20.0)
  result.width.label("Width=$1")
  result.miterLimit.setRange(1.0, 10.0)
  result.miterLimit.value(4.0)
  result.miterLimit.label("Miter Limit=$1")
  result.join.noTransform()
  result.cap.noTransform()
  result.width.noTransform()
  result.miterLimit.noTransform()

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()

  rb.clear(initRgba(1.0, 1.0, 1.0))
  path.moveTo(app.x[0], app.y[0])
  # This point is added only to check for numerical stability
  path.lineTo((app.x[0] + app.x[1]) / 2, (app.y[0] + app.y[1]) / 2)
  path.lineTo(app.x[1], app.y[1])
  path.lineTo(app.x[2], app.y[2])
  # This point is added only to check for numerical stability
  path.lineTo(app.x[2], app.y[2])

  path.moveTo((app.x[0] + app.x[1]) / 2, (app.y[0] + app.y[1]) / 2)
  path.lineTo((app.x[1] + app.x[2]) / 2, (app.y[1] + app.y[2]) / 2)
  path.lineTo((app.x[2] + app.x[0]) / 2, (app.y[2] + app.y[0]) / 2)
  path.closePolygon()

  var cap = LineCap.buttCap
  if app.cap.curItem() == 1: cap = LineCap.squareCap
  if app.cap.curItem() == 2: cap = LineCap.roundCap

  var join = LineJoin.miterJoin
  if app.join.curItem() == 1: join = LineJoin.miterJoinRevert
  if app.join.curItem() == 2: join = LineJoin.roundJoin
  if app.join.curItem() == 3: join = LineJoin.bevelJoin

  var
    stroke = initConvStroke(path)
    poly1  = initConvStroke(path)
    poly2Dash = initConvDash(stroke)
    poly2 = initConvStroke(poly2Dash)

  stroke.lineJoin(join)
  stroke.lineCap(cap)
  stroke.miterLimit(app.miterLimit.value())
  stroke.width(app.width.value())
  ras.addPath(stroke)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.8, 0.7, 0.6))

  poly1.width(1.5)
  ras.addPath(poly1)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0,0,0))

  poly2.miterLimit(4.0)
  poly2.width(app.width.value() / 5.0)
  poly2.lineCap(cap)
  poly2.lineJoin(join)
  poly2_dash.addDash(20.0, app.width.value() / 2.5)
  ras.addPath(poly2)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0,0,0.3))

  ras.addPath(path)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.0, 0.0, 0.0, 0.2))

  renderCtrl(ras, sl, rb, app.join)
  renderCtrl(ras, sl, rb, app.cap)
  renderCtrl(ras, sl, rb, app.width)
  renderCtrl(ras, sl, rb, app.miterLimit)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Line Join")

  if app.init(frameWidth, frameHeight, {}, "conv_stroke"):
    return app.run()

  result = 1

discard main()
