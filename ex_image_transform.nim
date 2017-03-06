import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_path_storage, agg_trans_affine
import agg_conv_transform, agg_pixfmt_rgba, agg_span_image_filter_rgba, agg_span_interpolator_linear
import agg_scanline_u, agg_renderer_scanline, agg_span_allocator, ctrl_slider, ctrl_rbox, ctrl_cbox
import nimBMP, agg_color_rgba, strutils, os, times, agg_basics, math, agg_renderer_base, agg_ellipse
import agg_conv_stroke

const
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

type
  App = object
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
    bmp: seq[BmpResult]
    rbuf: seq[RenderingBuffer]
    ps : PathStorage

proc initApp(): App =
  result.polygonAngle = newSliderCtrl[Rgba8](5,  5,      145, 11,    not flipY)
  result.polygonScale = newSliderCtrl[Rgba8](5,  5+14,   145, 12+14, not flipY)
  result.imageAngle   = newSliderCtrl[Rgba8](155,  5,    300, 12,    not flipY)
  result.imageScale   = newSliderCtrl[Rgba8](155,  5+14, 300, 12+14, not flipY)
  result.rotatePolygon = newCboxCtrl[Rgba8](5, 5+14+14,    "Rotate Polygon", not flipY)
  result.rotateImage   = newCboxCtrl[Rgba8](5, 5+14+14+14, "Rotate Image", not flipY)
  result.example = newRboxCtrl[Rgba8](-3.0, 14+14+14+14, -3.0, 14+14+14+14, not flipY)
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
  result.bmp = newSeq[BmpResult](10)
  result.rbuf = newSeq[RenderingBuffer](10)
  result.ps = initPathStorage()

proc loadImage(app: var App, idx: int, name: string) =
  app.bmp[idx] = loadBMP32("resources$1$2.bmp" % [$DirSep, name])
  if app.bmp[idx].width == 0 and app.bmp[idx].width == 0:
    echo "failed to load $1.bmp" % [name]
    quit(0)

  let numPix = app.bmp[idx].width*app.bmp[idx].height
  for i in 0.. <numPix:
    app.bmp[idx].data[i * 4 + 3] = 255.chr

  app.rbuf[idx] = initRenderingBuffer(cast[ptr ValueT](app.bmp[idx].data[0].addr),
    app.bmp[idx].width, app.bmp[idx].height, -app.bmp[idx].width * pixWidth)

proc rbufImage(app: var App, idx: int): var RenderingBuffer =
  result = app.rbuf[idx]

proc getBmp(app: var App, idx: int): var BmpResult =
  app.bmp[idx]

proc createStar(app: var App, w, h: int) =
  var r = w.float64
  if h.float64 < r: r = h.float64

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

proc init(app: var App, width, height: int) =
  let w = width.float64 / 2.0
  let h = height.float64 / 2.0
  app.imageCcx = w
  app.imageCcy = h
  app.polygonCx = w
  app.polygonCy = h
  app.imageCx = w
  app.imageCy = h

proc onDraw() =
  var app = initApp()
  app.loadImage(0, "spheres")

  let
    w = app.rbufImage(0).width()
    h = app.rbufImage(0).height()

  app.init(w, h)

  var
    buffer  = newString(w * h * pixWidth)
    rbuf    = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), w, h, -w * pixWidth)
    width   = w.float64
    height  = h.float64
    pixf    = initPixfmtRgba32(rbuf)
    pixfImg = initPixfmtRgba32Pre(app.rbufImage(0))
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
    imgMtx *= transAffine_translation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffine_rotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffine_scaling(app.imageScale.value())
    imgMtx *= transAffine_translation(app.imageCx, app.imageCy)
    imgMtx.invert()
  of 3:
    imgMtx *= transAffine_translation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffine_rotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffine_scaling(app.imageScale.value())
    imgMtx *= transAffine_translation(app.polygonCx, app.polygonCy)
    imgMtx.invert()
  of 4:
    imgMtx *= transAffine_translation(-app.imageCx, -app.imageCy)
    imgMtx *= transAffine_rotation(app.polygonAngle.value() * pi / 180.0)
    imgMtx *= transAffine_scaling(app.polygonScale.value())
    imgMtx *= transAffine_translation(app.polygonCx, app.polygonCy)
    imgMtx.invert()
  of 5:
    imgMtx *= transAffine_translation(-app.imageCcx, -app.imageCcy)
    imgMtx *= transAffine_rotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffine_rotation(app.polygonAngle.value() * pi / 180.0)
    imgMtx *= transAffine_scaling(app.imageScale.value())
    imgMtx *= transAffine_scaling(app.polygonScale.value())
    imgMtx *= transAffine_translation(app.imageCx, app.imageCy)
    imgMtx.invert()
  of 6:
    imgMtx *= transAffine_translation(-app.imageCx, -app.imageCy)
    imgMtx *= transAffine_rotation(app.imageAngle.value() * pi / 180.0)
    imgMtx *= transAffine_scaling(app.imageScale.value())
    imgMtx *= transAffine_translation(app.imageCx, app.imageCy)
    imgMtx.invert()
  else:
    discard

  var
    inter = initSpanInterpolatorLinear(imgMtx)
    sa    = initSpanAllocator[Rgba8]()
    sg    = initSpanImagefilterRgbaBilinearClip(pixfImg, initRgba(1,1,1), inter)
    ras   = initRasterizerScanlineAA()
    sl    = initScanlineU8()

  app.createStar(w, h)
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

  saveBMP32("image_transform.bmp", buffer, w, h)

onDraw()