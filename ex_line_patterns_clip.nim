import agg_basics, agg_rendering_buffer, agg_conv_transform, agg_conv_stroke
import agg_scanline_p, agg_renderer_scanline
import agg_rasterizer_outline_aa, agg_rasterizer_scanline_aa, agg_pattern_filters_rgba
import agg_renderer_outline_aa, agg_renderer_outline_image, agg_pixfmt_rgb
import ctrl_slider, ctrl_polygon, nimBMP, agg_color_rgba, agg_renderer_base
import strutils, os, agg_trans_affine, agg_path_storage, agg_gsv_text, agg_math

const
  brightnessToAlpha = [
    255'u8, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 254, 254, 254,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 253, 253,
    253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 252,
    252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 251, 251, 251, 251, 251,
    251, 251, 251, 251, 250, 250, 250, 250, 250, 250, 250, 250, 249, 249, 249, 249,
    249, 249, 249, 248, 248, 248, 248, 248, 248, 248, 247, 247, 247, 247, 247, 246,
    246, 246, 246, 246, 246, 245, 245, 245, 245, 245, 244, 244, 244, 244, 243, 243,
    243, 243, 243, 242, 242, 242, 242, 241, 241, 241, 241, 240, 240, 240, 239, 239,
    239, 239, 238, 238, 238, 238, 237, 237, 237, 236, 236, 236, 235, 235, 235, 234,
    234, 234, 233, 233, 233, 232, 232, 232, 231, 231, 230, 230, 230, 229, 229, 229,
    228, 228, 227, 227, 227, 226, 226, 225, 225, 224, 224, 224, 223, 223, 222, 222,
    221, 221, 220, 220, 219, 219, 219, 218, 218, 217, 217, 216, 216, 215, 214, 214,
    213, 213, 212, 212, 211, 211, 210, 210, 209, 209, 208, 207, 207, 206, 206, 205,
    204, 204, 203, 203, 202, 201, 201, 200, 200, 199, 198, 198, 197, 196, 196, 195,
    194, 194, 193, 192, 192, 191, 190, 190, 189, 188, 188, 187, 186, 186, 185, 184,
    183, 183, 182, 181, 180, 180, 179, 178, 177, 177, 176, 175, 174, 174, 173, 172,
    171, 171, 170, 169, 168, 167, 166, 166, 165, 164, 163, 162, 162, 161, 160, 159,
    158, 157, 156, 156, 155, 154, 153, 152, 151, 150, 149, 148, 148, 147, 146, 145,
    144, 143, 142, 141, 140, 139, 138, 137, 136, 135, 134, 133, 132, 131, 130, 129,
    128, 128, 127, 125, 124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 114, 113,
    112, 111, 110, 109, 108, 107, 106, 105, 104, 102, 101, 100,  99,  98,  97,  96,
     95,  94,  93,  91,  90,  89,  88,  87,  86,  85,  84,  82,  81,  80,  79,  78,
     77,  75,  74,  73,  72,  71,  70,  69,  67,  66,  65,  64,  63,  61,  60,  59,
     58,  57,  56,  54,  53,  52,  51,  50,  48,  47,  46,  45,  44,  42,  41,  40,
     39,  37,  36,  35,  34,  33,  31,  30,  29,  28,  27,  25,  24,  23,  22,  20,
     19,  18,  17,  15,  14,  13,  12,  11,   9,   8,   7,   6,   4,   3,   2,   1]

type
  PatternSrcBrightnessToAlphaRgba8 = object
    mRb: ptr RenderingBuffer
    mPf: PixfmtRgb24

proc initPatternSrcBrightnessToAlphaRgba8(rb: var RenderingBuffer): PatternSrcBrightnessToAlphaRgba8 =
  result.mRb = rb.addr
  result.mPf = initPixFmtRgb24(result.mRb[])

proc width(self: PatternSrcBrightnessToAlphaRgba8): int =
  self.mPf.width()

proc height(self: PatternSrcBrightnessToAlphaRgba8): int =
  self.mPf.height()

proc pixel(self: PatternSrcBrightnessToAlphaRgba8, x, y: int): Rgba8 =
  result = self.mPf.pixel(x, y)
  result.a = brightnessToAlpha[result.r.int + result.g.int + result.b.int]

const
  frameWidth = 500
  frameHeight = 500
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    ctrlColor: Rgba8
    line1: PolygonCtrl[Rgba8]
    scaleX: SliderCtrl[Rgba8]
    startX: SliderCtrl[Rgba8]
    scale: TransAffine
    bmp: seq[BmpResult]
    rbuf: seq[RenderingBuffer]

proc initApp(): App =
  result.ctrlColor = construct(Rgba8, initRgba(0, 0.3, 0.5, 0.3))
  result.scaleX = newSliderCtrl[Rgba8](5.0,   5.0, 240.0, 12.0, not flipY)
  result.startX = newSliderCtrl[Rgba8](250.0, 5.0, 495.0, 12.0, not flipY)
  result.line1 = newPolygonCtrl[Rgba8](5)
  result.scale = initTransAffine()

  result.line1.lineColor(result.ctrlColor)
  result.line1.xn(0) = 20
  result.line1.yn(0) = 20
  result.line1.xn(1) = 500-20
  result.line1.yn(1) = 500-20
  result.line1.xn(2) = 500-60
  result.line1.yn(2) = 20
  result.line1.xn(3) = 40
  result.line1.yn(3) = 500-40
  result.line1.xn(4) = 100
  result.line1.yn(4) = 300
  result.line1.close(false)

  result.line1.transform(result.scale)

  result.scaleX.label("Scale X=$1")
  result.scaleX.setRange(0.2, 3.0)
  result.scaleX.value(1.0)
  result.scaleX.noTransform()

  result.startX.label("Start X=$1")
  result.startX.setRange(0.0, 10.0)
  result.startX.value(0.0)
  result.startX.noTransform()

  result.bmp = newSeq[BmpResult](10)
  result.rbuf = newSeq[RenderingBuffer](10)

proc loadImage(app: var App, idx: int, name: string) =
  app.bmp[idx] = loadBMP24("resources$1$2.bmp" % [$DirSep, name])
  if app.bmp[idx].width == 0 and app.bmp[idx].width == 0:
    echo "failed to load $1.bmp" % [name]
    quit(0)
  app.rbuf[idx] = initRenderingBuffer(cast[ptr ValueT](app.bmp[idx].data[0].addr),
    app.bmp[idx].width, app.bmp[idx].height, app.bmp[idx].width * pixWidth)

proc rbufImage(app: var App, idx: int): var RenderingBuffer =
  result = app.rbuf[idx]

proc drawPolyline[Rasterizer, Renderer](app: var App, ras: var Rasterizer, ren: var Renderer, polyline: ptr float64, numPoints: int) =
  var
    vs = initPolyPlainAdaptor(polyline, numPoints, app.line1.close())
    trans = initConvTransform(vs, app.scale);

  ras.addPath(trans)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()

  app.loadImage(0, "1")
  rb.clear(initRgba(0.5, 0.75, 0.85))
  ras.clipBox(0, 0, frameWidth, frameHeight)

  var
    p1 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(0))
    filter: PatternFilterBilinearRgba8
    patt   = initLineImagePattern(filter)
    renImg = initRendererOutlineImage(rb, patt)
    rasImg = initRasterizerOutlineAA(renImg)

  patt.create(p1)


  #-- create uninitialized and set parameters
  var
    profile = initLineProfileAA()

  profile.smootherWidth(10.0) #optional
  profile.width(8.0)          #mandatory!

  var
    renLine = initRendererOutlineAA(rb, profile)
    rasLine = initRasterizerOutlineAA(renLine)

  renLine.color(initRgba8(0,0,127)) #mandatory!
  rasLine.roundCap(true)            #optional

  # Calculate the dilation value so that, the line caps were
  # drawn correctly.
  var w2 = 9.0;#p1.height() / 2 + 2;

  # Set the clip box a bit bigger than you expect. You need it
  # to draw the clipped line caps correctly. The correct result
  # is achieved with raster clipping.
  renImg.scaleX(app.scaleX.value())
  renImg.startX(app.startX.value())
  renImg.clipBox(50-w2, 50-w2, frameWidth-50+w2, frameHeight-50+w2)
  renLine.clipBox(50-w2, 50-w2, frameWidth-50+w2, frameHeight-50+w2)

  # First, draw polyline without raster clipping just to show the idea
  app.drawPolyline(rasLine, renLine, app.line1.polygon(), app.line1.numPoints())
  app.drawPolyline(rasImg,  renImg,  app.line1.polygon(), app.line1.numPoints())

  # Clear the area, almost opaque, but not completely
  #------------------------
  rb.blendBar(0, 0, frameWidth, frameHeight, initRgba(1,1,1), 200)

  # Set the raster clip box and then, draw again.
  # In reality there shouldn't be two calls above.
  # It's done only for demonstration
  #------------------------
  rb.clipBox(50, 50, frameWidth-50, frameHeight-50)

  # This "copy_bar" is also for demonstration only
  rb.copyBar(0, 0, frameWidth, frameHeight, initRgba(1,1,1))

  # Finally draw polyline correctly clipped: We use double clipping,
  # first is vector clipping, with extended clip box, second is raster
  # clipping with normal clip box.
  #------------------------
  renImg.scaleX(app.scaleX.value())
  renImg.startX(app.startX.value())
  app.drawPolyline(rasLine, renLine, app.line1.polygon(), app.line1.numPoints())
  app.drawPolyline(rasImg, renImg,   app.line1.polygon(), app.line1.numPoints())


  # Reset clipping and draw the controls and stuff
  rb.resetClipping(true)

  app.line1.lineWidth(1/app.scale.scale())
  app.line1.pointRadius(5/app.scale.scale())

  renderCtrl(ras, sl, rb, app.line1)
  renderCtrl(ras, sl, rb, app.scaleX)
  renderCtrl(ras, sl, rb, app.startX)

  var
    t = initGsvText()
    pt = initConvStroke(t)
    p = app.line1.polygon()
    d = calcDistance(p[0], p[1], p[2], p[3]) * app.scale.scale()
    buf = "Len=$1" % [d.formatFloat(ffDecimal, 2)]

  t.size(10.0)
  pt.width(1.5)
  pt.lineCap(LineCap.roundCap)
  t.startPoint(10.0, 30.0)
  t.text(buf)

  ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  saveBMP24("line_patterns_clip.bmp", buffer, frameWidth, frameHeight)

onDraw()
