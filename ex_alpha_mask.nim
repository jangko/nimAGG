import agg_basics, agg_rendering_buffer, agg_color_rgba
import agg_path_storage, agg_conv_transform, agg_bounding_rect, agg_renderer_scanline
import agg_pixfmt_rgb, agg_pixfmt_gray, agg_scanline_u, agg_renderer_base, agg_trans_affine
import parse_lion, nimBMP, agg_rasterizer_scanline_aa

{.passC: "-I./agg-2.5/include".}
{.compile: "parse_lion2.cpp".}
{.passL: "-lstdc++".}

proc parse_lion() {.importc.}

const
  frameWidth = 512
  frameHeight = 400
  pixWidth = 3

type
  ValueType = uint8
  
var 
  colors: array[100, Rgba8]
  pathIdx: array[100, int]
  path = initPathStorage()
  numPaths = parseLion(path, colors[0].addr, pathIdx[0].addr)
  x1, x2, y1, y2, base_dx, base_dy: float64

discard boundingRect(path, pathIdx, 0, numPaths, x1, y1, x2, y2)
base_dx = (x2 - x1) / 2.0
base_dy = (y2 - y1) / 2.0

var
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
  pf     = initPixFmtRgb24(rbuf)
  rb     = initRendererBase(pf)
  sl     = initScanlineU8()
  ras    = initRasterizerScanlineAA()
  ren    = initRendererScanlineAASolid(rb)
  mtx    = initTransAffine()
  
#var bkg = initRgba(1,1,1)
rb.clear(initRgba(1,1,1))
  
mtx *= transAffineTranslation(-base_dx, -base_dy)
mtx *= transAffineTranslation(frameWidth.float64/2, frameHeight.float64/2)
var trans = initConvTransform(path, mtx)

renderAllPaths(ras, sl, ren, trans, colors, pathIdx, numPaths)

saveBMP24("alpha_mask.bmp", buffer, frameWidth, frameHeight)