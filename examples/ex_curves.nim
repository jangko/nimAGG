import agg/[basics, path_storage, renderer_base, rendering_buffer,
  pixfmt_rgb, scanline_p, rasterizer_scanline_aa, conv_transform,
  renderer_scanline, conv_curve, color_rgba, conv_stroke, trans_affine,
  bounding_rect]
import streams, os, platform/support, spline
import ctrl/[rbox, slider]

const
  frameWidth = 640
  frameHeight = 480
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    path: PathStorage
    curveType: RboxCtrl[Rgba8]
    segments: SliderCtrl[Rgba8]
    scale: SliderCtrl[Rgba8]
    stroke: SliderCtrl[Rgba8]
#[
  var sine = makeSine(20, 5, 3)
  path.cubicBezier(sine, 0, degree_to_radian(360), 50)
  cnv.drawFunction(sine, 70, 150, "SINE WAVE")
]#

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.segments  = newSliderCtrl[Rgba8](5, 5, frameWidth - 5, 11, not flipY)
  result.scale     = newSliderCtrl[Rgba8](5, 5+20, frameWidth div 2, 11+20, not flipY)
  result.stroke    = newSliderCtrl[Rgba8](frameWidth div 2 + 5, 5+20, frameWidth - 5, 11+20, not flipY)
  result.curveType = newRboxCtrl[Rgba8](frameWidth - 170, 45, frameWidth - 5, 45 + 140, not flipY)

  result.addCtrl(result.curveType)
  result.addCtrl(result.segments)
  result.addCtrl(result.scale)
  result.addCtrl(result.stroke)

  result.segments.setRange(30, 150)
  result.segments.label("Segments=$1")
  result.segments.value(80)
  result.segments.numSteps(150-30)

  result.scale.setRange(1, 15)
  result.scale.label("Scale=$1")
  result.scale.value(8.0)

  result.stroke.setRange(0.1, 5)
  result.stroke.label("Stroke=$1")
  result.stroke.value(0.2)

  result.curveType.addItem("Rose")
  result.curveType.addItem("Lissajouse")
  result.curveType.addItem("Epicycloid")
  result.curveType.addItem("Epitrochoid")
  result.curveType.addItem("FarrisWheel")
  result.curveType.addItem("Hipocycloid")
  result.curveType.addItem("Hipotrochoid")

  result.curveType.curItem(0)
  result.path = initPathStorage()

proc getCurve(app: App): CyclicCurve =
  case app.curveType.curItem()
  of 0: result = makeRose(20.0, 7, 1)
  of 1: result = makeLissaJous(20,20,1,4,0)
  of 2: result = makeEpicycloid(7,0,5,6)
  of 3: result = makeEpitrochoid(5,0,1,5,6)
  of 4: result = makeFarrisWheel(1,7,-17,1,1/2,1/3,0,0,0.5,30,-0.5)
  of 5: result = makeHipocycloid(20,0,5,7)
  of 6: result = makeHipotrochoid(30,0,-0.75,6,5)
  else: discard

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    ren    = initRendererScanlineAASolid(rb)
    curve  = initConvCurve(app.path)
    stroke = initConvStroke(curve)
    mtx    = initTransAffine()
    trans  = initConvTransform(stroke, mtx)
    segments = app.segments.value().int
    scale  = app.scale.value()
    angle  = 0.0
    skewX  = 0.0
    skewY  = 0.0

  rb.clear(initRgba(1,1,1))
  stroke.width(app.stroke.value())

  var geom = app.getCurve()
  app.path.removeAll()
  app.path.cubicBezier(geom, geom.CycleStart, geom.CycleEnd, segments)

  #var
    #bb = boundingRectD(app.path)
    #baseDx = (bb.x2 - bb.x1) / 2.0
    #baseDy = (bb.y2 - bb.y1) / 2.0

  #mtx *= transAffineTranslation(-baseDx, -baseDy)
  mtx *= transAffineScaling(scale, scale)
  mtx *= transAffineRotation(angle + pi)
  mtx *= transAffineSkewing(skewX/1000.0, skewY/1000.0)
  mtx *= transAffineTranslation(app.width()/2, app.height()/2)

  ras.addPath(trans)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.stroke)
  renderCtrl(ras, sl, rb, app.scale)
  renderCtrl(ras, sl, rb, app.segments)
  renderCtrl(ras, sl, rb, app.curveType)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Curves")

  if app.init(frameWidth, frameHeight, {window_resize}, "curves"):
    return app.run()

  result = 1

discard main()
