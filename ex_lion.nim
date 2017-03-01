import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_scanline_p, agg_renderer_scanline, agg_path_storage
import agg_conv_transform, agg_bounding_rect, agg_pixfmt_rgb
import agg_color_rgba, agg_renderer_base, agg_trans_affine
import parse_lion, nimBMP, agg_path_length

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
    lion   = parseLion(frameWidth, frameHeight)

  let
    width  = frameWidth.float64
    height = frameHeight.float64
    alpha  = 0.7
 
  for i in 0.. <lion.numPaths:
    lion.colors[i].a = uint8(alpha * 255)

  # This code renders the lion:
  var trans = initConvTransform(lion.path, lion.mtx)
  rb.clear(initrgba(1, 1, 1))
  renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)
  
  var len = 0.0
  for i in 0.. <lion.numPaths:
    len += pathLength(lion.path, lion.pathIdx[i])
  echo len
  
  saveBMP24("lion.bmp", buffer, frameWidth, frameHeight)

onDraw()