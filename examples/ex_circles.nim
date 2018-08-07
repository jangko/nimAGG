import agg/[ellipse, basics, bspline, calc, gsv_text, renderer_base, calc,
  rendering_buffer, scanline_p, pixfmt_rgb, rasterizer_scanline_aa,
  renderer_scanline, color_rgba, conv_transform, trans_affine, gsv_text]
import platform/support, ctrl/slider, ctrl/scale, random, math

const
  frameWidth = 400
  frameHeight = 400
  flipY = true

type
  ScatterPoint* = object
    x, y, z: float64
    color: Rgba

  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    points: seq[ScatterPoint]
    spline_r: BSpline
    spline_g: BSpline
    spline_b: BSpline
    mScale: ScaleCtrl[Rgba8]
    mSel: SliderCtrl[Rgba8]
    mSize: SliderCtrl[Rgba8]
    sl: ScanlineP8
    ras: RasterizerScanlineAA

const
  numPoints = 10000

var
  spline_r_x = [ 0.000000, 0.200000, 0.400000, 0.910484, 0.957258, 1.000000 ]
  spline_r_y = [ 1.000000, 0.800000, 0.600000, 0.066667, 0.169697, 0.600000 ]
  spline_g_x = [ 0.000000, 0.292244, 0.485655, 0.564859, 0.795607, 1.000000 ]
  spline_g_y = [ 0.000000, 0.607260, 0.964065, 0.892558, 0.435571, 0.000000 ]
  spline_b_x = [ 0.000000, 0.055045, 0.143034, 0.433082, 0.764859, 1.000000 ]
  spline_b_y = [ 0.385480, 0.128493, 0.021416, 0.271507, 0.713974, 1.000000 ]

proc randomDbl(start, stop: float64): float64 =
  let r = rand(0x7FFF)
  result = float64(r) * (stop - start) / 32768.0 + start

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.points = newSeq[ScatterPoint](numPoints)
  result.spline_r = initBSpline(6, spline_r_x[0].addr, spline_r_y[0].addr)
  result.spline_g = initBSpline(6, spline_g_x[0].addr, spline_g_y[0].addr)
  result.spline_b = initBSpline(6, spline_b_x[0].addr, spline_b_y[0].addr)

  result.sl     = initScanlineP8()
  result.ras    = initRasterizerScanlineAA()

  result.mScale = newScaleCtrl[Rgba8](5, 5,  framewidth-5, 12, not flipY)
  result.mSel   = newSliderCtrl[Rgba8](5, 20, framewidth-5, 27, not flipY)
  result.mSize  = newSliderCtrl[Rgba8](5, 35, framewidth-5, 42, not flipY)

  result.addCtrl(result.mScale)
  result.addCtrl(result.mSel)
  result.addCtrl(result.mSize)

  result.mSize.label("Size")
  result.mSel.label("Selectivity")

proc generate(app: App) =
  let
    rx = app.width()/3.5
    ry = app.height()/3.5

  for i in 0..<numPoints:
    let
      z = randomDbl(0.0, 1.0)
      x = cos(z * 2.0 * pi) * rx
      y = sin(z * 2.0 * pi) * ry

      dist  = randomDbl(0.0, rx/2.0)
      angle = randomDbl(0.0, pi * 2.0)

    app.points[i].z = z
    app.points[i].x = app.width()/2.0 + x + cos(angle) * dist
    app.points[i].y = app.height()/2.0 + y + sin(angle) * dist
    app.points[i].color = initRgba(app.spline_r.get(z)*0.8, app.spline_g.get(z)*0.8, app.spline_b.get(z)*0.8, 1.0)

method onInit(app: App) =
  app.generate()

method onDraw(app: App) =
  var
    pf   = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pf)

  rb.clear(initRgba(1,1,1))
  var
    e1: Ellipse
    mtx = transAffineResizing(app)
    t1 = initConvTransform(e1, mtx)
    nDrawn = 0
    scale1 = app.mScale.value1()
    scale2 = app.mScale.value2()
    sel = app.mSel.value()
    size = app.mSize.value()

  for i in 0..<numPoints:
    var
      z = app.points[i].z
      alpha = 1.0

    if z < scale1:
      alpha = 1.0 - (scale1 - z) * sel * 100.0

    if z > scale2:
      alpha = 1.0 - (z - scale2) * sel * 100.0

    if alpha > 1.0: alpha = 1.0
    if alpha < 0.0: alpha = 0.0

    if alpha > 0.0:
      e1.init(app.points[i].x, app.points[i].y,
              size * 5.0, size * 5.0, 8)
      app.ras.addPath(t1)

      renderScanlinesAASolid(app.ras, app.sl, rb,
            initRgba(app.points[i].color.r,
                     app.points[i].color.g,
                     app.points[i].color.b,
                     alpha))
      inc nDrawn

  renderCtrl(app.ras, app.sl, rb, app.mScale)
  renderCtrl(app.ras, app.sl, rb, app.mSel)
  renderCtrl(app.ras, app.sl, rb, app.mSize)

  var
    buf = $nDrawn
    txt = initGsvText()

  txt.size(15.0)
  txt.text(buf)
  txt.startPoint(10.0, frameHeight.float64 - 20.0)

  var txt_o = initGsvTextOutline(txt, mtx)
  app.ras.addPath(txt_o)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(0,0,0))

method onIdle(app: App) =
  for i in 0..<numPoints:
    app.points[i].x += randomDbl(0, app.mSel.value()) - app.mSel.value()*0.5
    app.points[i].y += randomDbl(0, app.mSel.value()) - app.mSel.value()*0.5
    app.points[i].z += randomDbl(0, app.mSel.value()*0.01) - app.mSel.value()*0.005
    if app.points[i].z < 0.0: app.points[i].z = 0.0
    if app.points[i].z > 1.0: app.points[i].z = 1.0
  app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    app.generate()
    app.forceRedraw()

  if mouseRight in flags:
    app.waitMode(not app.waitMode())

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Drawing random circles - A scatter plot prototype")

  if app.init(frameWidth, frameHeight, {window_resize, window_keep_aspect_ratio}, "circles"):
    return app.run()

  result = 1

discard main()

