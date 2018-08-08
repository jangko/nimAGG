import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, trans_affine, conv_stroke, conv_transform,
  path_storage, gamma_functions, pixfmt_rgb, color_rgba, renderer_base]
import ctrl/[cbox, slider], math, platform/support

const
  frameWidth = 250
  frameHeight = 280
  flipY = false

type
  ValueT = uint8

type
  PathAttributes = object
    index: int
    fillColor, strokeColor: Rgba8
    strokeWidth: float64

proc initPathAttributes(idx: int, fill, stroke: Rgba8, width: float64): PathAttributes =
  result.index = idx
  result.fillColor = fill
  result.strokeColor = stroke
  result.strokeWidth = width

let polyBulb = [
    -6.0,-67.0,    -6.0,-71.0,   -7.0,-74.0,    -8.0,-76.0,    -10.0,-79.0,
    -10.0,-82.0,   -9.0,-84.0,   -6.0,-86.0,    -4.0,-87.0,    -2.0,-86.0,
    -1.0,-86.0,     1.0,-84.0,    2.0,-82.0,     2.0,-79.0,     0.0,-77.0,
    -2.0,-73.0,    -2.0,-71.0,   -2.0,-69.0,    -3.0,-67.0,    -4.0,-65.0]

let polyBeam1 = [-14.0,-84.0,-22.0,-85.0,-23.0,-87.0,-22.0,-88.0,-21.0,-88.0]
let polyBeam2 = [-10.0,-92.0,   -14.0,-96.0,   -14.0,-98.0,   -12.0,-99.0,   -11.0,-97.0]
let polyBeam3 = [-1.0,-92.0,     -2.0,-98.0,    0.0,-100.0,    2.0,-100.0,    1.0,-98.0]
let polyBeam4 = [    5.0,-89.0,      11.0,-94.0,   13.0,-93.0,    13.0,-92.0,    12.0,-91.0]

let polyFig1 = [
  1.0,-48.0,-3.0,-54.0,-7.0,-58.0,-12.0,-58.0,-17.0,-55.0,-20.0,-52.0,-21.0,-47.0,
  -20.0,-40.0,-17.0,-33.0,-11.0,-28.0,-6.0,-26.0,-2.0,-25.0,2.0,-26.0,4.0,-28.0,5.0,
  -33.0,5.0,-39.0,3.0,-44.0,12.0,-48.0,12.0,-50.0,12.0,-51.0,3.0,-46.0]

let polyFig2 = [
    11.0,-27.0,6.0,-23.0,4.0,-22.0,3.0,-19.0,5.0,
    -16.0,6.0,-15.0,11.0,-17.0,19.0,-23.0,25.0,-30.0,32.0,-38.0,32.0,-41.0,32.0,-50.0,30.0,-64.0,32.0,-72.0,
    32.0,-75.0,31.0,-77.0,28.0,-78.0,26.0,-80.0,28.0,-87.0,27.0,-89.0,25.0,-88.0,24.0,-79.0,24.0,-76.0,23.0,
    -75.0,20.0,-76.0,17.0,-76.0,17.0,-74.0,19.0,-73.0,22.0,-73.0,24.0,-71.0,26.0,-69.0,27.0,-64.0,28.0,-55.0,
    28.0,-47.0,28.0,-40.0,26.0,-38.0,20.0,-33.0,14.0,-30.0]

let polyFig3 = [
    -6.0,-20.0,-9.0,-21.0,-15.0,-21.0,-20.0,-17.0,
    -28.0,-8.0,-32.0,-1.0,-32.0,1.0,-30.0,6.0,-26.0,8.0,-20.0,10.0,-16.0,12.0,-14.0,14.0,-15.0,16.0,-18.0,20.0,
    -22.0,20.0,-25.0,19.0,-27.0,20.0,-26.0,22.0,-23.0,23.0,-18.0,23.0,-14.0,22.0,-11.0,20.0,-10.0,17.0,-9.0,14.0,
    -11.0,11.0,-16.0,9.0,-22.0,8.0,-26.0,5.0,-28.0,2.0,-27.0,-2.0,-23.0,-8.0,-19.0,-11.0,-12.0,-14.0,-6.0,-15.0,
    -6.0,-18.0]

let polyFig4 = [
    11.0,-6.0,8.0,-16.0,5.0,-21.0,-1.0,-23.0,-7.0,
   -22.0,-10.0,-17.0,-9.0,-10.0,-8.0,0.0,-8.0,10.0,-10.0,18.0,-11.0,22.0,-10.0,26.0,-7.0,28.0,-3.0,30.0,0.0,31.0,
    5.0,31.0,10.0,27.0,14.0,18.0,14.0,11.0,11.0,2.0]


let polyFig5 = [
    0.0,22.0,-5.0,21.0,-8.0,22.0,-9.0,26.0,-8.0,49.0,
    -8.0,54.0,-10.0,64.0,-10.0,75.0,-9.0,81.0,-10.0,84.0,-16.0,89.0,-18.0,95.0,-18.0,97.0,-13.0,100.0,-12.0,99.0,
    -12.0,95.0,-10.0,90.0,-8.0,87.0,-6.0,86.0,-4.0,83.0,-3.0,82.0,-5.0,80.0,-6.0,79.0,-7.0,74.0,-6.0,63.0,-3.0,52.0,
    0.0,42.0,1.0,31.0]

let polyFig6 = [
    12.0,31.0,12.0,24.0,8.0,21.0,3.0,21.0,2.0,24.0,3.0,
    30.0,5.0,40.0,8.0,47.0,10.0,56.0,11.0,64.0,11.0,71.0,10.0,76.0,8.0,77.0,8.0,79.0,10.0,81.0,13.0,82.0,17.0,82.0,26.0,
    84.0,28.0,87.0,32.0,86.0,33.0,81.0,32.0,80.0,25.0,79.0,17.0,79.0,14.0,79.0,13.0,76.0,14.0,72.0,14.0,64.0,13.0,55.0,
    12.0,44.0,12.0,34.0]

type
  Roundoff = object

proc transform(self: Roundoff, x, y: var float64) =
  x = math.floor(x + 0.5)
  y = math.floor(y + 0.5)

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    attr: array[3, PathAttributes]
    path: PathStorage
    nPaths: int
    pFlag: FillingRule
    ras: RasterizerScanlineAA
    sl: ScanlineP8
    angle, dx, dy: float64
    rotate: CboxCtrl[Rgba8]
    evenOdd: CboxCtrl[Rgba8]
    draft: CboxCtrl[Rgba8]
    roundoff: CboxCtrl[Rgba8]
    angleDelta: SliderCtrl[Rgba8]
    redrawFlag: bool

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.path = initPathStorage()
  result.nPaths = 0
  result.pFlag = fillNonZero
  result.ras = initRasterizerScanlineAA()
  result.sl = initScanlineP8()
  result.angle = 0.0
  result.rotate = newCboxCtrl[Rgba8](10,  3, "Rotate", not flipY)
  result.evenOdd = newCboxCtrl[Rgba8](60, 3, "Even-Odd", not flipY)
  result.draft = newCboxCtrl[Rgba8](130, 3, "Draft", not flipY)
  result.roundoff = newCboxCtrl[Rgba8](175, 3, "Roundoff", not flipY)
  result.angleDelta = newSliderCtrl[Rgba8](10, 21, 250-10, 27, not flipY)

  result.addCtrl(result.rotate)
  result.addCtrl(result.evenOdd)
  result.addCtrl(result.draft)
  result.addCtrl(result.roundoff)
  result.addCtrl(result.angleDelta)

  result.redrawFlag = true

  result.angleDelta.label("Step=$1 degree")

  result.attr[result.nPaths] = initPathAttributes(result.path.startNewPath(),
    initRgba8(255, 255, 0), initRgba8(0, 0, 0), 1.0)
  inc result.nPaths

  result.path.concatPoly(polyBulb[0].unsafeAddr, polyBulb.len div 2, true)

  result.attr[result.nPaths] = initPathAttributes(result.path.startNewPath(),
    initRgba8(255,  255, 200), initRgba8(90, 0, 0), 0.7)
  inc result.nPaths

  result.path.concatPoly(polyBeam1[0].unsafeAddr, polyBeam1.len div 2, true)
  result.path.concatPoly(polyBeam2[0].unsafeAddr, polyBeam2.len div 2, true)
  result.path.concatPoly(polyBeam3[0].unsafeAddr, polyBeam3.len div 2, true)
  result.path.concatPoly(polyBeam4[0].unsafeAddr, polyBeam4.len div 2, true)

  result.attr[result.nPaths] = initPathAttributes(result.path.startNewPath(),
    initRgba8(0, 0, 0), initRgba8(0, 0, 0), 0.0)
  inc result.nPaths

  result.path.concatPoly(polyFig1[0].unsafeAddr, polyFig1.len div 2, true)
  result.path.concatPoly(polyFig2[0].unsafeAddr, polyFig2.len div 2, true)
  result.path.concatPoly(polyFig3[0].unsafeAddr, polyFig3.len div 2, true)
  result.path.concatPoly(polyFig4[0].unsafeAddr, polyFig4.len div 2, true)
  result.path.concatPoly(polyFig5[0].unsafeAddr, polyFig5.len div 2, true)
  result.path.concatPoly(polyFig6[0].unsafeAddr, polyFig6.len div 2, true)

  result.rotate.textSize(7)
  result.evenOdd.textSize(7)
  result.draft.textSize(7)
  result.roundoff.textSize(7)
  result.angleDelta.value(0.01)

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    roundOff: Roundoff
    width  = app.width()
    height = app.height()
    mtx    = initTransAffine()
    fill   = initConvTransform(app.path, mtx)

  if app.redrawFlag:
    app.ras.gamma(initGammaNone())
    rb.clear(initRgba8(255,255,255))
    app.ras.fillingRule(fillNonZero)
    renderCtrl(app.ras, app.sl, rb, app.rotate)
    renderCtrl(app.ras, app.sl, rb, app.evenOdd)
    renderCtrl(app.ras, app.sl, rb, app.draft)
    renderCtrl(app.ras, app.sl, rb, app.roundoff)
    renderCtrl(app.ras, app.sl, rb, app.angleDelta)
    app.redrawFlag = false
  else:
    rb.copyBar(0, int(32.0 * height / app.dy), width.int, height.int, initRgba8(255,255,255))

  if app.draft.status():
    app.ras.gamma(initGammaThreshold(0.4))

  mtx.reset()
  mtx *= transAffineRotation(app.angle * pi / 180.0)
  mtx *= transAffineTranslation(app.dx / 2, app.dy / 2 + 10)
  mtx *= transAffineScaling(width / app.dx, height / app.dy)

  var
    fillRoundOff = initConvTransform(fill, roundoff)
    stroke = initConvStroke(fill)
    strokeRoundOff = initConvStroke(fillRoundOff)

  app.pFlag = if app.evenOdd.status(): fillEvenOdd else: fillNonZero

  for i in 0..<app.nPaths:
    app.ras.fillingRule(app.pFlag)
    if app.roundoff.status(): app.ras.addPath(fillRoundOff, app.attr[i].index)
    else: app.ras.addPath(fill, app.attr[i].index)

    if app.draft.status():
      renderScanlinesBinSolid(app.ras, app.sl, rb, app.attr[i].fillColor)
    else:
      renderScanlinesAASolid(app.ras, app.sl, rb, app.attr[i].fillColor)

    if app.attr[i].strokeWidth > 0.001:
      stroke.width(app.attr[i].strokeWidth * mtx.scale())
      strokeRoundOff.width(app.attr[i].strokeWidth * mtx.scale())
      if app.roundoff.status(): app.ras.addPath(strokeRoundOff, app.attr[i].index)
      else: app.ras.addPath(stroke, app.attr[i].index)

      if app.draft.status():
        renderScanlinesBinSolid(app.ras, app.sl, rb, app.attr[i].strokeColor)
      else:
        renderScanlinesAASolid(app.ras, app.sl, rb, app.attr[i].strokeColor)

method onInit(app: App) =
  app.dx = app.rbufWindow().width().float64
  app.dy = app.rbufWindow().height().float64

method onResize(app: App, sx, sy: int) =
  app.redrawFlag = true

method onIdle(app: App) =
  app.angle += app.angleDelta.value()
  if app.angle > 360.0: app.angle -= 360.0
  app.forceRedraw()

method onCtrlChange(app: App) =
  app.waitMode(not app.rotate.status())
  app.redrawFlag = true

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Idea")

  if app.init(frameWidth, frameHeight, {window_resize}, "idea"):
    return app.run()

  result = 1

discard main()
