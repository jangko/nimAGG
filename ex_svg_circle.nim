import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_color_gray
import agg_span_gouraud_gray, agg_span_solid, agg_math, agg_dda_line, agg_pixfmt_gray
import agg_renderer_base, agg_gamma_functions, agg_span_gouraud_rgba
import agg_renderer_scanline, nimBMP, agg_color_rgba, agg_pixfmt_rgb
import agg_color_conv, agg_color_conv_rgb8, math, agg_conv_clip_polygon, make_arrows
import agg_path_storage, agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_bounding_rect, agg_conv_unclose_polygon, agg_conv_close_polygon
import agg_conv_shorten_path, agg_conv_clip_polyline, agg_conv_smooth_poly1
import agg_bezier_arc, colors

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3

type
  ValueT = uint8

proc circle(path: var PathStorage, cx, cy, radius: float64) =
  var arc = initBezierArc(cx, cy, radius, radius, 0, 2 * pi)
  path.joinPath(arc)

proc toRgba8(c: Color): Rgba8 =
  let c = extractRGB(c)
  result = initRgba8(c.r, c.g, c.b)

type
  Helmet* = object
    path*: PathStorage
    colors*: array[20, Rgba8]
    pathIdx*: array[20, int]
    numPaths*: int
    mtx*: TransAffine
    x1*, x2*, y1*, y2*: float64

proc createHelmet*(path: var PathStorage, colors: ptr Rgba8, pathIdx: ptr int): int =
  var npaths = 0

  # circle
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x221BE2).toRgba8
  path.circle(87, 87, 87)
  inc npaths

  # Half Circle
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x526EEB).toRgba8
  path.moveTo(17.34375, 89.375)
  path.arcTo(5.3368431, 5.3368431, 0, false, false, 12.03125, 94.71875)
  path.curve4(12.03125, 132.82644, 45.917638, 163.28125, 87, 163.28125)
  path.curve4(128.08238, 163.28125, 161.96875, 132.82644, 161.96875, 94.71875)
  path.arcTo(5.3368431, 5.3368431, 0, false, false, 156.65625, 89.375)
  path.lineTo(146.4375, 89.375)
  path.lineTo(136.25, 89.375)
  path.lineTo(38.21875, 89.375)
  path.lineTo(27.78125, 89.375)
  path.lineTo(17.34375, 89.375)
  inc npaths

  # Spike 1
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = colWhite.toRgba8
  path.moveTo(116.21875, 15.65625)
  path.lineTo(91.858265, 50.912099)
  path.lineTo(107.46875, 57.03125)
  path.lineTo(143.59375, 26.21875)
  path.closePolygon()

  # Spike 2
  path.moveTo(83.8125, 17.25)
  path.lineTo(72.640625, 53.09375)
  path.lineTo(89.78125, 50.4375)
  path.lineTo(109.60613, 17.253509)
  path.closePolygon()

  # Spike 3
  path.moveTo(76.9375, 21.6875)
  path.lineTo(54.8125, 30.28125)
  path.lineTo(57.617188, 62.710937)
  path.lineTo(71.273438, 53.492187)
  path.closePolygon()

  # Spike 4
  path.moveTo(50.5, 35.78125)
  path.lineTo(34.75, 50.6875)
  path.lineTo(48.705941, 77.449603)
  path.lineTo(56.539063, 63.875)
  path.closePolygon()

  # Spike 5
  path.moveTo(33.094512, 56.30183)
  path.lineTo(27.28125, 74.21875)
  path.lineTo(46.356044, 90.295439)
  path.lineTo(48.831075, 79.326634)
  path.closePolygon()

  # Spike 6
  path.moveTo(28.28125, 78.40625)
  path.lineTo(27.71875, 94.1875)
  path.lineTo(48.409391, 102.61742)
  path.lineTo(46.3125, 91.65625)
  path.closePolygon()

  # Spike 7
  path.moveTo(28.25, 96.625)
  path.lineTo(32.71875, 110.96875)
  path.lineTo(51.892818, 111.03275)
  path.lineTo(49.243337, 103.56573)
  path.closePolygon()

  # Spike 8
  path.moveTo(52.316561, 111.44508)
  path.lineTo(34.3125, 113.1562)
  path.lineTo(42.024318,123.57415)
  path.lineTo(56.931488,117.22633)
  path.closePolygon()
  inc npaths

  # Background Circle
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x526EEB).toRgba8
  path.moveTo(127.89327, 90.999997)
  path.arcTo(40.893275, 40.893275, 0, false, true, 46.106725, 90.999997)
  path.arcTo(40.893275, 40.893275, 0, true, true, 127.89327, 90.999997)
  inc npaths

  # Helmet Circle
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = colWhite.toRgba8
  path.moveTo(87.75, 55.4375)
  path.arcTo(35.571, 35.571007, 0, false, false, 65.125, 119.03125)
  path.lineTo(67.59375, 121.25)
  path.lineTo(86.5, 118.75)
  path.lineTo(80.90625, 103.59375)
  path.lineTo(115.5, 69.71875)
  path.arcTo(35.571, 35.571007, 0, false, false, 87.75, 55.4375)
  inc npaths

  # Helmet Part 0
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0xA1B5F3).toRgba8
  path.moveTo(124.78125, 58.4375)
  path.lineTo(72.25, 94.875)
  path.lineTo(75.84375, 107.625)
  path.curve4(94.606902, 103.41847, 132.125, 94.96875, 132.125, 94.96875)
  path.curve4(129.67728, 82.79162, 124.78125, 58.4375, 124.78125, 58.4375)
  inc npaths

  # Helmet Part 1
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = colWhite.toRgba8
  path.moveTo(121.375, 66.875)
  path.lineTo(126.28125, 91.15625)
  path.lineTo(79.375, 101.71875)
  path.lineTo(78.03125, 96.9375)
  path.lineTo(121.375, 66.875)
  inc npaths

  # Helmet Part 2
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = colWhite.toRgba8
  path.moveTo(87.28125, 107.3125)
  path.lineTo(88.03125, 108.96875)
  path.curve4(88.03125, 108.96875, 91.693696, 117.3024, 95.90625, 126.46875)
  path.curve4(100.1188, 135.6351, 104.82694, 145.59083, 106.96875, 149.03125)
  path.curve4(107.17503, 149.36261, 107.59478, 149.50994, 107.9375, 149.5)
  path.curve4(108.28022, 149.49, 108.62919, 149.38065, 109, 149.21875)
  path.curve4(109.74162, 148.89494, 110.5715, 148.32996, 111.4375, 147.625)
  path.curve4(113.16949, 146.21508, 114.95287, 144.27985, 115.5625, 142.5)
  path.curve4(116.13222, 140.83669, 115.539, 138.40147, 114.4375, 135.65625)
  path.curve4(113.33596, 132.91103, 111.6635, 129.87631, 109.78125, 127.21875)
  path.curve4(106.85741, 123.09056, 101.61579, 118.4075, 97.09375, 114.71875)
  path.curve4(92.57171, 111.03, 88.75, 108.34375, 88.75, 108.34375)
  path.lineTo(87.28125, 107.3125)
  inc npaths

  # Helmet Part 3
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x526EEB).toRgba8
  path.moveTo(79.679222, 60.619469)
  path.curve4(72.896972, 62.051929, 66.561832, 65.787739, 61.960472, 71.681969)
  path.curve4(52.761752, 83.465299, 53.568662, 99.889949, 63.147972, 110.68197)
  path.lineTo(69.241722, 109.30697)
  path.curve4(58.486892, 98.216539, 55.890172, 82.365299, 66.241722, 70.463219)
  path.curve4(70.026722, 66.111279, 74.778642, 63.085619, 79.897972, 61.431969)
  path.lineTo(79.679222, 60.619469)
  inc npaths

  # Helmet Part 4
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x241dE4).toRgba8
  path.moveTo(85.853952,116.52758)
  path.curve4(86.786482, 116.7176, 92.818232, 131.30436, 92.818232, 131.30436)
  path.curve4(92.818232, 131.30436, 88.928002, 137.98183, 88.621802, 137.86686)
  path.curve4(75.194472, 132.82537, 67.369672, 132.59698, 52.996802, 137.19722)
  path.curve4(50.899162, 137.8686, 59.435642, 121.75976, 61.345022, 118.98293)
  path.curve4(64.539192, 114.33764, 79.075592, 115.14633, 85.853952, 116.52758)
  inc npaths

  # Helmet Part 5
  pathIdx[npaths] = path.startNewPath()
  colors[npaths] = Color(0x5271EB).toRgba8
  path.moveTo(72.429222, 117.24447)
  path.curve4(69.191292, 117.38102, 66.238762, 118.01608, 65.179222, 119.55697)
  path.curve4(64.501612, 120.54242, 62.588842, 124.03634, 61.147972, 127.02572)
  path.curve4(63.045912, 124.35898, 65.323382, 121.63536, 66.554222, 121.02572)
  path.curve4(68.149632, 120.23551, 68.786982, 118.46824, 82.210472, 119.74447)
  path.curve4(82.320322, 119.75487, 82.463222, 119.81967, 82.585472, 119.90072)
  path.curve4(82.051152, 118.80698, 81.600772, 117.96692, 81.429222, 117.93197)
  path.curve4(79.180772, 117.4738, 75.667152, 117.10792, 72.429222, 117.24447)
  inc npaths

  result = npaths

proc createHelmet(width, height: int, scale = 1.0, angle = 0.0, skewX = 0.0, skewY = 0.0): Helmet =
  var x1, x2, y1, y2: float64
  result.path = initPathStorage()
  result.numPaths = createHelmet(result.path, result.colors[0].addr, result.pathIdx[0].addr)

  discard boundingRect(result.path, result.pathIdx, 0, result.numPaths, x1, y1, x2, y2)
  var
    baseDx = (x2 - x1) / 2.0
    baseDy = (y2 - y1) / 2.0

  result.mtx  = initTransAffine()
  result.mtx *= transAffineTranslation(-baseDx, -baseDy)
  result.mtx *= transAffineScaling(scale, scale)
  result.mtx *= transAffineRotation(angle + pi)
  result.mtx *= transAffineSkewing(skewX/1000.0, skewY/1000.0)
  result.mtx *= transAffineTranslation(width.float64/2, height.float64/2)
  result.x1 = x1
  result.x2 = x2
  result.y1 = y1
  result.y2 = y2

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtBgr24(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    ren    = initRendererScanlineAASolid(rb)
    helmet = createHelmet(frameWidth, frameHeight, 1.5)
    curve  = initConvCurve(helmet.path)
    trans  = initConvTransform(curve, helmet.mtx)

  rb.clear(initRgba(1,1,1))
  renderAllPaths(ras, sl, ren, trans, helmet.colors, helmet.pathIdx, helmet.numPaths)

  saveBMP24("svg_circle.bmp", buffer, frameWidth, frameHeight)

onDraw()
