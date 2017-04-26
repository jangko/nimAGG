import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_path_storage, agg_trans_affine
import agg_conv_transform, agg_pixfmt_rgba, agg_span_image_filter_rgba, agg_span_interpolator_linear
import agg_scanline_u, agg_renderer_scanline, agg_span_allocator, ctrl_slider, ctrl_rbox, ctrl_cbox
import agg_color_rgba, strutils, os, agg_basics, math, agg_renderer_base, agg_ellipse
import agg_conv_stroke, agg_platform_support

const
  flipY = true

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre

  App = ref object of PlatformSupport
    polygonAngle: SliderCtrl[Rgba8]
    polygonScale: SliderCtrl[Rgba8]
    imageAngle: SliderCtrl[Rgba8]
    imageScale: SliderCtrl[Rgba8]
    rotatePolygon: CboxCtrl[Rgba8]
    rotateImage: CboxCtrl[Rgba8]
    example: RboxCtrl[Rgba8]
    imageCx, imageCy: float64
    imageCcx, imageCcy: float64
    polygonCx, polygonCy: float64
    dx, dy: float64
    flag: int
    ps : PathStorage

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.polygonAngle = newSliderCtrl[Rgba8](5,  5,      145, 11,    not flipY)
  result.polygonScale = newSliderCtrl[Rgba8](5,  5+14,   145, 12+14, not flipY)
  result.imageAngle   = newSliderCtrl[Rgba8](155,  5,    300, 12,    not flipY)
  result.imageScale   = newSliderCtrl[Rgba8](155,  5+14, 300, 12+14, not flipY)
  result.rotatePolygon = newCboxCtrl[Rgba8](5, 5+14+14,    "Rotate Polygon", not flipY)
  result.rotateImage   = newCboxCtrl[Rgba8](5, 5+14+14+14, "Rotate Image", not flipY)
  result.example = newRboxCtrl[Rgba8](-3.0, 14+14+14+14, -3.0, 14+14+14+14, not flipY)

  result.addCtrl(result.polygonAngle)
  result.addCtrl(result.polygonScale)
  result.addCtrl(result.imageAngle)
  result.addCtrl(result.imageScale)
  result.addCtrl(result.rotatePolygon)
  result.addCtrl(result.rotateImage)
  result.addCtrl(result.example)

  result.flag = 0
  result.polygonAngle.label("Polygon Angle=$1")
  result.polygonScale.label("Polygon Scale=$1")
  result.polygonAngle.setRange(-180.0, 180.0)
  result.polygonScale.setRange(0.1, 5.0)
  result.polygonScale.value(1.0)
  result.imageAngle.label("Image Angle=$1")
  result.imageScale.label("Image Scale=$1")
  result.imageAngle.setRange(-180.0, 180.0)
  result.imageScale.setRange(0.1, 5.0)
  result.imageScale.value(1.0)
  result.example.addItem("0")
  result.example.addItem("1")
  result.example.addItem("2")
  result.example.addItem("3")
  result.example.addItem("4")
  result.example.addItem("5")
  result.example.addItem("6")
  result.example.curItem(0)
  result.ps = initPathStorage()

proc createStar(app: App, w, h: float64) =
  app.ps.removeAll()
  var r = w
  if h < r: r = h

  var
    r1 = r / 3.0 - 8.0
    r2 = r1 / 1.45
    nr = 14

  for i in 0.. <nr:
    var
      a = pi * 2.0 * i.float64 / nr.float64 - pi / 2.0
      dx = cos(a)
      dy = sin(a)

    if(i and 1) != 0:
      app.ps.lineTo(app.polygonCx + dx * r1, app.polygonCy + dy * r1)
    else:
      if i != 0: app.ps.lineTo(app.polygonCx + dx * r2, app.polygonCy + dy * r2)
      else: app.ps.moveTo(app.polygonCx + dx * r2, app.polygonCy + dy * r2)

method onInit(app: App) =
  let w = app.width() / 2.0
  let h = app.height() / 2.0
  app.imageCcx = w
  app.imageCcy = h
  app.polygonCx = w
  app.polygonCy = h
  app.imageCx = w
  app.imageCy = h

method onDraw(app: App) =
  var
    width   = app.width()
    height  = app.height()
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfImg = construct(PixFmtPre, app.rbufImg(0))
    rb      = initRendererBase(pixf)
    ren     = initRendererScanlineAASolid(rb)
    imgMtx  = initTransAffine()
    polyMtx = initTransAffine()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  polyMtx *= transAffineTranslation(-app.polygonCx, -app.polygonCy)
  polyMtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
  polyMtx *= transAffineScaling(app.polygonScale.value())
  polyMtx *= transAffineTranslation(app.polygonCx, app.polygonCy)

  case app.example.curItem()
  of 0:
  # (Example 0, Identity matrix)
    discard
  of 1:
    imgMtx *= transAffineTranslation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.polygonScale.value())
    imgMtx *= transAffineTranslation(app.polygonCx, app.polygonCy)
    imgMtx.invert()
  of 2:
    imgMtx *= transAffineTranslation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffineRotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.imageScale.value())
    imgMtx *= transAffineTranslation(app.imageCx, app.imageCy)
    imgMtx.invert()
  of 3:
    imgMtx *= transAffineTranslation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffineRotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.imageScale.value())
    imgMtx *= transAffineTranslation(app.polygonCx, app.polygonCy)
    imgMtx.invert()
  of 4:
    imgMtx *= transAffineTranslation(-app.imageCx, -app.imageCy)
    imgMtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.polygonScale.value())
    imgMtx *= transAffineTranslation(app.polygonCx, app.polygonCy)
    imgMtx.invert()
  of 5:
    imgMtx *= transAffineTranslation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffineRotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.imageScale.value())
    imgMtx *= transAffineScaling(app.polygonScale.value())
    imgMtx *= transAffineTranslation(app.imageCx, app.imageCy)
    imgMtx.invert()
  of 6:
    imgMtx *= transAffineTranslation(-app.imageCx, -app.imageCy)
    imgMtx *= transAffineRotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffineScaling(app.imageScale.value())
    imgMtx *= transAffineTranslation(app.imageCx, app.imageCy)
    imgMtx.invert()
  else:
    discard

  var
    inter = initSpanInterpolatorLinear(imgMtx)
    sa    = initSpanAllocator[Rgba8]()
    sg    = initSpanImagefilterRgbaBilinearClip(pixfImg, initRgba(1,1,1), inter)
    ras   = initRasterizerScanlineAA()
    sl    = initScanlineU8()

  app.createStar(width, height)
  var
    tr = initConvTransform(app.ps, polyMtx)

  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rb, sa, sg)

  var
    e1 = initEllipse(app.imageCx, app.imageCy, 5, 5, 20)
    e2 = initEllipse(app.imageCx, app.imageCy, 2, 2, 20)
    c1 = initConvStroke(e1)

  ren.color(initRgba(0.7,0.8,0))
  ras.addPath(e1)
  renderScanlines(ras, sl, ren)

  ren.color(initRgba(0,0,0))
  ras.addPath(c1)
  renderScanlines(ras, sl, ren)

  ras.addPath(e2)
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.polygonAngle)
  renderCtrl(ras, sl, rb, app.polygonScale)
  renderCtrl(ras, sl, rb, app.imageAngle)
  renderCtrl(ras, sl, rb, app.imageScale)
  renderCtrl(ras, sl, rb, app.rotatePolygon)
  renderCtrl(ras, sl, rb, app.rotateImage)
  renderCtrl(ras, sl, rb, app.example)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    if sqrt((x - app.imageCx) * (x - app.imageCx) +
            (y - app.imageCy) * (y - app.imageCy) ) < 5.0:

      app.dx = x - app.imageCx
      app.dy = y - app.imageCy
      app.flag = 1
    else:
      var
        ras = initRasterizerScanlineAA()
        polygonMtx = initTransAffine()

      polygonMtx *= transAffineTranslation(-app.polygonCx, -app.polygonCy)
      polygonMtx *= transAffineRotation(app.polygonAngle.value() * pi / 180.0)
      polygonMtx *= transAffineScaling(app.polygonScale.value(), app.polygonScale.value())
      polygonMtx *= transAffineTranslation(app.polygonCx, app.polygonCy)

      app.createStar(app.width(), app.height())

      var tr = initConvTransform(app.ps, polygonMtx)
      ras.addPath(tr)
      if ras.hitTest(x.int, y.int):
        app.dx = x - app.polygonCx
        app.dy = y - app.polygonCy
        app.flag = 2

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.flag = 0

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    if app.flag == 1:
      app.imageCx = x - app.dx
      app.imageCy = y - app.dy
      app.forceRedraw()

    if app.flag == 2:
      app.polygonCx = x - app.dx
      app.polygonCy = y - app.dy
      app.forceRedraw()
  else:
    app.onMouseButtonUp(x.int, y.int, flags)

method onCtrlChange(app: App) =
  if app.rotatePolygon.status() or app.rotateImage.status():
    app.waitMode(false)
  else:
    app.waitMode(true)
  app.forceRedraw()

method onIdle(app: App) =
  var redraw = false
  if app.rotatePolygon.status():
    app.polygonAngle.value(app.polygonAngle.value() + 0.5)
    if app.polygonAngle.value() >= 180.0:
      app.polygonAngle.value(app.polygonAngle.value() - 360.0)
    redraw = true

  if app.rotateImage.status():
    app.imageAngle.value(app.imageAngle.value() + 0.5)
    if app.imageAngle.value() >= 180.0:
      app.imageAngle.value(app.imageAngle.value() - 360.0)
    redraw = true

  if redraw: app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("Image Affine Transformations with filtering")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  let
    frameWidth = app.rbufImg(0).width()
    frameHeight = app.rbufImg(0).height()

  if app.init(frameWidth, frameHeight, {window_resize}, "image_alpha"):
    return app.run()

  result = 1

discard main()
