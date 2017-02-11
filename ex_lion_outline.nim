import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_renderer_outline_aa, agg_rasterizer_outline_aa, agg_scanline_p
import agg_renderer_scanline, agg_path_storage, agg_conv_transform
import agg_bounding_rect, agg_pixfmt_rgb, agg_renderer_base
import agg_color_rgba, nimBMP, agg_trans_affine, parse_lion
import agg_conv_stroke, agg_gamma_functions

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
    mode   = false
    kWidth = 1.0

  rb.clear(initRgba(1,1,1))

  mtx *= transAffineTranslation(-base_dx, -base_dy)
  mtx *= transAffineScaling(scale, scale)
  mtx *= transAffineRotation(angle + pi)
  mtx *= transAffineSkewing(skew_x/1000.0, skew_y/1000.0)
  mtx *= transAffineTranslation(width / 2, height / 2)

  if mode:
    var stroke = initConvStroke(path)
    stroke.width(kWidth)
    stroke.lineJoin(roundJoin)
    var trans = initConvTransform(stroke, mtx)
    renderAllPaths(ras, sl, ren, trans, colors, pathIdx, numPaths)
  else:
    var
      w       = kWidth * mtx.scale()
      gammaF  = initGammaNone()
      profile = initLineProfileAA(w, gammaF)
      ren     = initRendererOutlineAA(rb, profile)
      ras     = initRasterizerOutlineAA(ren)
      trans   = initConvTransform(path, mtx)

    ras.renderAllPaths(trans, colors, pathIdx, numPaths)

  saveBMP24("lion_outline.bmp", buffer, frameWidth, frameHeight)
onDraw()