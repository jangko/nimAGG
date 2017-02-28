import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_conv_curve
import agg_conv_contour, agg_conv_stroke, agg_scanline_p, agg_renderer_scanline
import agg_pixfmt_rgb, agg_pixfmt_rgba, agg_pixfmt_gray, agg_bounding_rect
import agg_trans_perspective, agg_blur, agg_color_rgba, agg_path_storage
import ctrl_slider, ctrl_rbox, ctrl_cbox, ctrl_polygon, agg_trans_affine
import agg_renderer_base, nimBMP, agg_color_gray, agg_conv_transform

var
  gradient_colors = [
    255'u8, 255, 255, 255,
    255, 255, 254, 255,
    255, 255, 254, 255,
    255, 255, 254, 255,
    255, 255, 253, 255,
    255, 255, 253, 255,
    255, 255, 252, 255,
    255, 255, 251, 255,
    255, 255, 250, 255,
    255, 255, 248, 255,
    255, 255, 246, 255,
    255, 255, 244, 255,
    255, 255, 241, 255,
    255, 255, 238, 255,
    255, 255, 235, 255,
    255, 255, 231, 255,
    255, 255, 227, 255,
    255, 255, 222, 255,
    255, 255, 217, 255,
    255, 255, 211, 255,
    255, 255, 206, 255,
    255, 255, 200, 255,
    255, 254, 194, 255,
    255, 253, 188, 255,
    255, 252, 182, 255,
    255, 250, 176, 255,
    255, 249, 170, 255,
    255, 247, 164, 255,
    255, 246, 158, 255,
    255, 244, 152, 255,
    254, 242, 146, 255,
    254, 240, 141, 255,
    254, 238, 136, 255,
    254, 236, 131, 255,
    253, 234, 126, 255,
    253, 232, 121, 255,
    253, 229, 116, 255,
    252, 227, 112, 255,
    252, 224, 108, 255,
    251, 222, 104, 255,
    251, 219, 100, 255,
    251, 216,  96, 255,
    250, 214,  93, 255,
    250, 211,  89, 255,
    249, 208,  86, 255,
    249, 205,  83, 255,
    248, 202,  80, 255,
    247, 199,  77, 255,
    247, 196,  74, 255,
    246, 193,  72, 255,
    246, 190,  69, 255,
    245, 187,  67, 255,
    244, 183,  64, 255,
    244, 180,  62, 255,
    243, 177,  60, 255,
    242, 174,  58, 255,
    242, 170,  56, 255,
    241, 167,  54, 255,
    240, 164,  52, 255,
    239, 161,  51, 255,
    239, 157,  49, 255,
    238, 154,  47, 255,
    237, 151,  46, 255,
    236, 147,  44, 255,
    235, 144,  43, 255,
    235, 141,  41, 255,
    234, 138,  40, 255,
    233, 134,  39, 255,
    232, 131,  37, 255,
    231, 128,  36, 255,
    230, 125,  35, 255,
    229, 122,  34, 255,
    228, 119,  33, 255,
    227, 116,  31, 255,
    226, 113,  30, 255,
    225, 110,  29, 255,
    224, 107,  28, 255,
    223, 104,  27, 255,
    222, 101,  26, 255,
    221,  99,  25, 255,
    220,  96,  24, 255,
    219,  93,  23, 255,
    218,  91,  22, 255,
    217,  88,  21, 255,
    216,  86,  20, 255,
    215,  83,  19, 255,
    214,  81,  18, 255,
    213,  79,  17, 255,
    212,  77,  17, 255,
    211,  74,  16, 255,
    210,  72,  15, 255,
    209,  70,  14, 255,
    207,  68,  13, 255,
    206,  66,  13, 255,
    205,  64,  12, 255,
    204,  62,  11, 255,
    203,  60,  10, 255,
    202,  58,  10, 255,
    201,  56,   9, 255,
    199,  55,   9, 255,
    198,  53,   8, 255,
    197,  51,   7, 255,
    196,  50,   7, 255,
    195,  48,   6, 255,
    193,  46,   6, 255,
    192,  45,   5, 255,
    191,  43,   5, 255,
    190,  42,   4, 255,
    188,  41,   4, 255,
    187,  39,   3, 255,
    186,  38,   3, 255,
    185,  37,   2, 255,
    183,  35,   2, 255,
    182,  34,   1, 255,
    181,  33,   1, 255,
    179,  32,   1, 255,
    178,  30,   0, 255,
    177,  29,   0, 255,
    175,  28,   0, 255,
    174,  27,   0, 255,
    173,  26,   0, 255,
    171,  25,   0, 255,
    170,  24,   0, 255,
    168,  23,   0, 255,
    167,  22,   0, 255,
    165,  21,   0, 255,
    164,  21,   0, 255,
    163,  20,   0, 255,
    161,  19,   0, 255,
    160,  18,   0, 255,
    158,  17,   0, 255,
    156,  17,   0, 255,
    155,  16,   0, 255,
    153,  15,   0, 255,
    152,  14,   0, 255,
    150,  14,   0, 255,
    149,  13,   0, 255,
    147,  12,   0, 255,
    145,  12,   0, 255,
    144,  11,   0, 255,
    142,  11,   0, 255,
    140,  10,   0, 255,
    139,  10,   0, 255,
    137,   9,   0, 255,
    135,   9,   0, 255,
    134,   8,   0, 255,
    132,   8,   0, 255,
    130,   7,   0, 255,
    128,   7,   0, 255,
    126,   6,   0, 255,
    125,   6,   0, 255,
    123,   5,   0, 255,
    121,   5,   0, 255,
    119,   4,   0, 255,
    117,   4,   0, 255,
    115,   4,   0, 255,
    113,   3,   0, 255,
    111,   3,   0, 255,
    109,   2,   0, 255,
    107,   2,   0, 255,
    105,   2,   0, 255,
    103,   1,   0, 255,
    101,   1,   0, 255,
     99,   1,   0, 255,
     97,   0,   0, 255,
     95,   0,   0, 255,
     93,   0,   0, 255,
     91,   0,   0, 255,
     90,   0,   0, 255,
     88,   0,   0, 255,
     86,   0,   0, 255,
     84,   0,   0, 255,
     82,   0,   0, 255,
     80,   0,   0, 255,
     78,   0,   0, 255,
     77,   0,   0, 255,
     75,   0,   0, 255,
     73,   0,   0, 255,
     72,   0,   0, 255,
     70,   0,   0, 255,
     68,   0,   0, 255,
     67,   0,   0, 255,
     65,   0,   0, 255,
     64,   0,   0, 255,
     63,   0,   0, 255,
     61,   0,   0, 255,
     60,   0,   0, 255,
     59,   0,   0, 255,
     58,   0,   0, 255,
     57,   0,   0, 255,
     56,   0,   0, 255,
     55,   0,   0, 255,
     54,   0,   0, 255,
     53,   0,   0, 255,
     53,   0,   0, 255,
     52,   0,   0, 255,
     52,   0,   0, 255,
     51,   0,   0, 255,
     51,   0,   0, 255,
     51,   0,   0, 255,
     50,   0,   0, 255,
     50,   0,   0, 255,
     51,   0,   0, 255,
     51,   0,   0, 255,
     51,   0,   0, 255,
     51,   0,   0, 255,
     52,   0,   0, 255,
     52,   0,   0, 255,
     53,   0,   0, 255,
     54,   1,   0, 255,
     55,   2,   0, 255,
     56,   3,   0, 255,
     57,   4,   0, 255,
     58,   5,   0, 255,
     59,   6,   0, 255,
     60,   7,   0, 255,
     62,   8,   0, 255,
     63,   9,   0, 255,
     64,  11,   0, 255,
     66,  12,   0, 255,
     68,  13,   0, 255,
     69,  14,   0, 255,
     71,  16,   0, 255,
     73,  17,   0, 255,
     75,  18,   0, 255,
     77,  20,   0, 255,
     79,  21,   0, 255,
     81,  23,   0, 255,
     83,  24,   0, 255,
     85,  26,   0, 255,
     87,  28,   0, 255,
     90,  29,   0, 255,
     92,  31,   0, 255,
     94,  33,   0, 255,
     97,  34,   0, 255,
     99,  36,   0, 255,
    102,  38,   0, 255,
    104,  40,   0, 255,
    107,  41,   0, 255,
    109,  43,   0, 255,
    112,  45,   0, 255,
    115,  47,   0, 255,
    117,  49,   0, 255,
    120,  51,   0, 255,
    123,  52,   0, 255,
    126,  54,   0, 255,
    128,  56,   0, 255,
    131,  58,   0, 255,
    134,  60,   0, 255,
    137,  62,   0, 255,
    140,  64,   0, 255,
    143,  66,   0, 255,
    145,  68,   0, 255,
    148,  70,   0, 255,
    151,  72,   0, 255,
    154,  74,   0, 255]

const
  frameWidth = 440
  frameHeight = 330
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    how: RboxCtrl[Rgba8]
    radius: SliderCtrl[Rgba8]
    shadow: PolygonCtrl[Rgba8]
    path: PathStorage
    shape: ConvCurve[PathStorage]
    ras: RasterizerScanlineAA
    sl: ScanlineP8
    shapeBounds: RectD
    gray8Buf: seq[uint8]
    gray8Rbuf: RenderingBuffer
    gray8Rbuf2: RenderingBuffer
    colorLut: seq[Rgba8]

proc initApp(): App =
  result.how = newRboxCtrl[Rgba8](10.0, 10.0, 130.0, 55.0, not flipY)
  result.radius = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 130 + 300.0, 10.0 + 8.0 + 4.0, not flipY)
  result.shadow = newPolygonCtrl[Rgba8](4)
  result.path  = initPathStorage()
  result.shape = initConvCurve(result.path)
  result.ras = initRasterizerScanlineAA()
  result.sl = initScanlineP8()

  result.how.textSize(8)
  result.how.addItem("Single Color")
  result.how.addItem("Color LUT")
  result.how.curItem(1)

  result.radius.setRange(0.0, 40.0)
  result.radius.value(15.0)
  result.radius.label("Blur Radius=$1")

  result.path.removeAll()
  result.path.moveTo(28.47, 6.45)
  result.path.curve3(21.58, 1.12, 19.82, 0.29)
  result.path.curve3(17.19, -0.93, 14.21, -0.93)
  result.path.curve3(9.57, -0.93, 6.57, 2.25)
  result.path.curve3(3.56, 5.42, 3.56, 10.60)
  result.path.curve3(3.56, 13.87, 5.03, 16.26)
  result.path.curve3(7.03, 19.58, 11.99, 22.51)
  result.path.curve3(16.94, 25.44, 28.47, 29.64)
  result.path.lineTo(28.47, 31.40)
  result.path.curve3(28.47, 38.09, 26.34, 40.58)
  result.path.curve3(24.22, 43.07, 20.17, 43.07)
  result.path.curve3(17.09, 43.07, 15.28, 41.41)
  result.path.curve3(13.43, 39.75, 13.43, 37.60)
  result.path.lineTo(13.53, 34.77)
  result.path.curve3(13.53, 32.52, 12.38, 31.30)
  result.path.curve3(11.23, 30.08, 9.38, 30.08)
  result.path.curve3(7.57, 30.08, 6.42, 31.35)
  result.path.curve3(5.27, 32.62, 5.27, 34.81)
  result.path.curve3(5.27, 39.01, 9.57, 42.53)
  result.path.curve3(13.87, 46.04, 21.63, 46.04)
  result.path.curve3(27.59, 46.04, 31.40, 44.04)
  result.path.curve3(34.28, 42.53, 35.64, 39.31)
  result.path.curve3(36.52, 37.21, 36.52, 30.71)
  result.path.lineTo(36.52, 15.53)
  result.path.curve3(36.52, 9.13, 36.77, 7.69)
  result.path.curve3(37.01, 6.25, 37.57, 5.76)
  result.path.curve3(38.13, 5.27, 38.87, 5.27)
  result.path.curve3(39.65, 5.27, 40.23, 5.62)
  result.path.curve3(41.26, 6.25, 44.19, 9.18)
  result.path.lineTo(44.19, 6.45)
  result.path.curve3(38.72, -0.88, 33.74, -0.88)
  result.path.curve3(31.35, -0.88, 29.93, 0.78)
  result.path.curve3(28.52, 2.44, 28.47, 6.45)
  result.path.closePolygon()

  result.path.moveTo(28.47, 9.62)
  result.path.lineTo(28.47, 26.66)
  result.path.curve3(21.09, 23.73, 18.95, 22.51)
  result.path.curve3(15.09, 20.36, 13.43, 18.02)
  result.path.curve3(11.77, 15.67, 11.77, 12.89)
  result.path.curve3(11.77, 9.38, 13.87, 7.06)
  result.path.curve3(15.97, 4.74, 18.70, 4.74)
  result.path.curve3(22.41, 4.74, 28.47, 9.62)
  result.path.closePolygon()

  var shapeMtx = initTransAffine()
  shapeMtx *= transAffineScaling(4.0)
  shapeMtx *= transAffineTranslation(150, 100)
  result.path.transform(shapeMtx)

  discard boundingRectSingle(result.shape, 0,
                     result.shapeBounds.x1, result.shapeBounds.y1,
                     result.shapeBounds.x2, result.shapeBounds.y2)

  result.shadow.xn(0) = result.shapeBounds.x1
  result.shadow.yn(0) = result.shapeBounds.y1
  result.shadow.xn(1) = result.shapeBounds.x2
  result.shadow.yn(1) = result.shapeBounds.y1
  result.shadow.xn(2) = result.shapeBounds.x2
  result.shadow.yn(2) = result.shapeBounds.y2
  result.shadow.xn(3) = result.shapeBounds.x1
  result.shadow.yn(3) = result.shapeBounds.y2
  result.shadow.lineColor(initRgba(0, 0.3, 0.5, 0.3))

  result.colorLut = newSeq[Rgba8](256)
  var p = gradient_colors[0].addr
  for i in 0..255:
    result.colorLut[i] = initRgba8(p[0], p[1], p[2], if i > 63: 255 else: i * 4) #p[3])
    #result.colorLut[i].premultiply()
    inc(p, 4)

  result.gray8Buf = @[]
  result.gray8Rbuf = initRenderingBuffer()
  result.gray8Rbuf2 = initRenderingBuffer()

proc onResize(app: var App, sx, sy: int) =
  app.gray8Buf.setLen(sx * sy)
  app.gray8Rbuf.attach(app.gray8Buf[0].addr, sx, sy, sx)

{.passC: "-I./agg-2.5/include".}
{.compile: "test_blend.cpp".}
{.passL: "-lstdc++".}

proc test_blend(data: cstring, sx, sy: cint, x1,y1,x2,y2, radius:float64): cstring {.importc.}

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixfmtRgb24(rbuf)
    renb   = initRendererBase(pixf)
    shadowPersp = initTransPerspective(app.shapeBounds.x1, app.shapeBounds.y1,
                                       app.shapeBounds.x2, app.shapeBounds.y2,
                                       app.shadow.polygon())
    shadowTrans = initConvTransform(app.shape, shadowPersp)

  app.onResize(frameWidth, frameHeight)
  app.ras.clipBox(0, 0, frameWidth, frameHeight)

  var
    pixfGray8 = initPixfmtGray8(app.gray8Rbuf)
    renbGray8 = initRendererBase(pixfGray8)

  renbGray8.clear(initGray8(0))
  renb.clear(initRgba(1, 0.95, 0.95))

  # Render shadow
  app.ras.addPath(shadowTrans)
  renderScanlinesAAsolid(app.ras, app.sl, renbGray8, initGray8(255))
  #renderScanlinesAAsolid(app.ras, app.sl, renb, initRgba8(255,0,0,255))

  # Calculate the bounding box and extend it by the blur radius
  var bbox: RectD
  discard boundingRectSingle(shadowTrans, 0, bbox.x1, bbox.y1, bbox.x2, bbox.y2)

  bbox.x1 -= app.radius.value()
  bbox.y1 -= app.radius.value()
  bbox.x2 += app.radius.value()
  bbox.y2 += app.radius.value()

  #var buf = test_blend(cast[cstring](app.gray8buf[0].addr), frameWidth.cint, frameHeight.cint,
  #bbox.x1, bbox.y1, bbox.x2, bbox.y2, app.radius.value())

  #echo "---"
  if bbox.clip(initRectD(0.0, 0.0, frameWidth.float64, frameHeight.float64)):
    # Create a new pixel renderer and attach it to the main one as a child image.
    # It returns true if the attachment suceeded. It fails if the rectangle
    # (bbox) is fully clipped.
    var pixf2 = initPixfmtGray8(app.gray8Rbuf2)
    if pixf2.attach(pixfGray8, int(bbox.x1), int(bbox.y1), int(bbox.x2), int(bbox.y2)):
      # Blur it
      stackBlurGray8(pixf2, uround(app.radius.value()), uround(app.radius.value()))

    if app.how.curItem() == 0:
      renb.blendFromColor(pixf2, initRgba8(0, 100, 0), nil, int(bbox.x1), int(bbox.y1))
    else:
      renb.blendFromLut(pixf2, app.colorLut[0].addr, nil, int(bbox.x1), int(bbox.y1))

  renderCtrl(app.ras, app.sl, renb, app.how)
  renderCtrl(app.ras, app.sl, renb, app.radius)
  renderCtrl(app.ras, app.sl, renb, app.shadow)

  #copyMem(buffer.cstring, buf, buffer.len)
  saveBMP24("blend_color.bmp", buffer, frameWidth, frameHeight)

onDraw()