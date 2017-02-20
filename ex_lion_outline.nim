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
    lion   = parseLion(frameWidth, frameHeight)
    
  let
    width  = frameWidth.float64
    height = frameHeight.float64
    alpha  = 0.1
    mode   = false
    kWidth = 1.0

  rb.clear(initRgba(1,1,1))

  if mode:
    var stroke = initConvStroke(lion.path)
    stroke.width(kWidth)
    stroke.lineJoin(roundJoin)
    var trans = initConvTransform(stroke, lion.mtx)
    renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)
  else:
    var
      w       = kWidth * lion.mtx.scale()
      gammaF  = initGammaNone()
      profile = initLineProfileAA(w, gammaF)
      ren     = initRendererOutlineAA(rb, profile)
      ras     = initRasterizerOutlineAA(ren)
      trans   = initConvTransform(lion.path, lion.mtx)

    ras.renderAllPaths(trans, lion.colors, lion.pathIdx, lion.numPaths)

  saveBMP24("lion_outline.bmp", buffer, frameWidth, frameHeight)
onDraw()