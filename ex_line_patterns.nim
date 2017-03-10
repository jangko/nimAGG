import agg_basics, agg_rendering_buffer, agg_conv_transform, agg_conv_stroke
import agg_scanline_p, agg_renderer_scanline
import agg_rasterizer_outline_aa, agg_rasterizer_scanline_aa, agg_pattern_filters_rgba
import agg_renderer_outline_aa, agg_renderer_outline_image, agg_pixfmt_rgb
import ctrl_slider, ctrl_bezier, nimBMP, agg_color_rgba, agg_renderer_base
import strutils, os

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
  frameWidth = 540
  frameHeight = 450
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    ctrlColor: Rgba8
    curve1: BezierCtrl[Rgba8]
    curve2: BezierCtrl[Rgba8]
    curve3: BezierCtrl[Rgba8]
    curve4: BezierCtrl[Rgba8]
    curve5: BezierCtrl[Rgba8]
    curve6: BezierCtrl[Rgba8]
    curve7: BezierCtrl[Rgba8]
    curve8: BezierCtrl[Rgba8]
    curve9: BezierCtrl[Rgba8]
    scaleX: SliderCtrl[Rgba8]
    startX: SliderCtrl[Rgba8]
    bmp: seq[BmpResult]
    rbuf: seq[RenderingBuffer]

proc initApp(): App =
  result.ctrlColor = construct(Rgba8, initRgba(0, 0.3, 0.5, 0.3))
  result.scaleX = newSliderCtrl[Rgba8](5.0,   5.0, 240.0, 12.0, not flipY)
  result.startX = newSliderCtrl[Rgba8](250.0, 5.0, 495.0, 12.0, not flipY)

  result.curve1 = newBezierCtrl[Rgba8]()
  result.curve2 = newBezierCtrl[Rgba8]()
  result.curve3 = newBezierCtrl[Rgba8]()
  result.curve4 = newBezierCtrl[Rgba8]()
  result.curve5 = newBezierCtrl[Rgba8]()
  result.curve6 = newBezierCtrl[Rgba8]()
  result.curve7 = newBezierCtrl[Rgba8]()
  result.curve8 = newBezierCtrl[Rgba8]()
  result.curve9 = newBezierCtrl[Rgba8]()

  result.curve1.lineColor(result.ctrlColor)
  result.curve2.lineColor(result.ctrlColor)
  result.curve3.lineColor(result.ctrlColor)
  result.curve4.lineColor(result.ctrlColor)
  result.curve5.lineColor(result.ctrlColor)
  result.curve6.lineColor(result.ctrlColor)
  result.curve7.lineColor(result.ctrlColor)
  result.curve8.lineColor(result.ctrlColor)
  result.curve9.lineColor(result.ctrlColor)

  result.curve1.curve(64, 19, 14, 126, 118, 266, 19, 265)
  result.curve2.curve(112, 113, 178, 32, 200, 132, 125, 438)
  result.curve3.curve(401, 24, 326, 149, 285, 11, 177, 77)
  result.curve4.curve(188, 427, 129, 295, 19, 283, 25, 410)
  result.curve5.curve(451, 346, 302, 218, 265, 441, 459, 400)
  result.curve6.curve(454, 198, 14, 13, 220, 291, 483, 283)
  result.curve7.curve(301, 398, 355, 231, 209, 211, 170, 353)
  result.curve8.curve(484, 101, 222, 33, 486, 435, 487, 138)
  result.curve9.curve(143, 147, 11, 45, 83, 427, 132, 197)

  result.curve1.noTransform()
  result.curve2.noTransform()
  result.curve3.noTransform()
  result.curve4.noTransform()
  result.curve5.noTransform()
  result.curve6.noTransform()
  result.curve7.noTransform()
  result.curve8.noTransform()
  result.curve9.noTransform()

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

proc drawCurve[Pattern, Rasterizer, Renderer, PatternSource, VertexSource](app: var App,
  pat: var Pattern, ras: var Rasterizer, ren: var Renderer, src: var PatternSource, vs: var VertexSource) =

  pat.create(src)
  ren.scaleX(app.scaleX.value())
  ren.startX(app.startX.value())
  ras.addPath(vs)

#[
{.passC: "-I./agg-2.5/include".}
{.compile: "test_pattern.cpp".}
{.compile: "agg_bezier_ctrl2.cpp".}
{.compile: "agg_polygon_ctrl2.cpp".}
{.compile: "agg_curves2.cpp".}
{.compile: "agg_vcgen_stroke2.cpp".}
{.compile: "agg_line_aa_basics2.cpp".}
{.passL: "-lstdc++".}
]#
#proc test_pattern(image: cstring, w, h: cint, data: ptr ptr Rgba8): cstring {.importc.}

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    #ren    = initRendererScanlineAASolid(rb)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()

  app.loadImage(0, "1")
  app.loadImage(1, "2")
  app.loadImage(2, "3")
  app.loadImage(3, "4")
  app.loadImage(4, "5")
  app.loadImage(5, "6")
  app.loadImage(6, "7")
  app.loadImage(7, "8")
  app.loadImage(8, "9")

  rb.clear(initRgba(1.0, 1.0, 0.95))

  var
    p1 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(0))
    p2 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(1))
    p3 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(2))
    p4 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(3))
    p5 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(4))
    p6 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(5))
    p7 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(6))
    p8 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(7))
    p9 = initPatternSrcBrightnessToAlphaRgba8(app.rbufImage(8))
    filter: PatternFilterBilinearRgba8
    patt   = initLineImagePattern(filter)
    renImg = initRendererOutlineImage(rb, patt)
    rasImg = initRasterizerOutlineAA(renImg)

  #var
  #  w = app.bmp[0].width.cint
  #  h = app.bmp[0].height.cint
  #  data = app.bmp[0].data.cstring

  app.drawCurve(patt, rasImg, renImg, p1, app.curve1.curve())
  #for y in 0.. <p1.height():
  #  for x in 0.. <p1.width():
  #    let c = p1.pixel(x, y)
  #    echo "$1 $2 $3 $4" % [$c.r, $c.g, $c.b, $c.a]

  #echo "---"
  #var buf = test_pattern(data, w, h, patt.data())
  app.drawCurve(patt, rasImg, renImg, p2, app.curve2.curve())
  app.drawCurve(patt, rasImg, renImg, p3, app.curve3.curve())
  app.drawCurve(patt, rasImg, renImg, p4, app.curve4.curve())
  app.drawCurve(patt, rasImg, renImg, p5, app.curve5.curve())
  app.drawCurve(patt, rasImg, renImg, p6, app.curve6.curve())
  app.drawCurve(patt, rasImg, renImg, p7, app.curve7.curve())
  app.drawCurve(patt, rasImg, renImg, p8, app.curve8.curve())
  app.drawCurve(patt, rasImg, renImg, p9, app.curve9.curve())

  renderCtrl(ras, sl, rb, app.curve1)
  renderCtrl(ras, sl, rb, app.curve2)
  renderCtrl(ras, sl, rb, app.curve3)
  renderCtrl(ras, sl, rb, app.curve4)
  renderCtrl(ras, sl, rb, app.curve5)
  renderCtrl(ras, sl, rb, app.curve6)
  renderCtrl(ras, sl, rb, app.curve7)
  renderCtrl(ras, sl, rb, app.curve8)
  renderCtrl(ras, sl, rb, app.curve9)

  renderCtrl(ras, sl, rb, app.scaleX)
  renderCtrl(ras, sl, rb, app.startX)

  #copyMem(buffer.cstring, buf, buffer.len)
  saveBMP24("line_patterns.bmp", buffer, frameWidth, frameHeight)

onDraw()
