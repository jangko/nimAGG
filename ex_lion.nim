import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_scanline_p, agg_renderer_scanline, agg_path_storage
import agg_conv_transform, agg_bounding_rect, agg_pixfmt_rgb
import agg_color_rgba, agg_renderer_base, agg_trans_affine
import parse_lion, nimBMP

const
  frameWidth = 512
  frameHeight = 400
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()
    mtx    = initTransAffine()
    colors: array[100, Rgba8]
    pathIdx: array[100, int]
    numPaths = parseLion(path, colors[0].addr, pathIdx[0].addr)
    x1, x2, y1, y2, base_dx, base_dy: float64

  discard boundingRect(path, pathIdx, 0, numPaths, x1, y1, x2, y2)
  base_dx = (x2 - x1) / 2.0
  base_dy = (y2 - y1) / 2.0

  let
    width  = frameWidth.float64
    height = frameHeight.float64
    alpha  = 0.1
    angle  = 0.0
    scale  = 1.0
    skew_x = 0.0
    skew_y = 0.0

  for i in 0.. <numPaths:
    colors[i].a = uint8(alpha * 255)

  mtx *= transAffineTranslation(-base_dx, -base_dy)
  mtx *= transAffineScaling(scale, scale)
  mtx *= transAffineRotation(angle + pi)
  mtx *= transAffineSkewing(skew_x/1000.0, skew_y/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)

  # This code renders the lion:
  var trans = initConvTransform(path, mtx)
  rb.clear(initrgba(1, 1, 1))
  renderAllPaths(ras, sl, ren, trans, colors, pathIdx, numPaths)
  saveBMP24("lion.bmp", buffer, frameWidth, frameHeight)

onDraw()