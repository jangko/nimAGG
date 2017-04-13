import agg_basics, agg_rendering_buffer, agg_color_rgba, agg_color_gray
import agg_path_storage, agg_conv_transform, agg_bounding_rect, agg_renderer_scanline
import agg_pixfmt_rgb, agg_pixfmt_gray, agg_scanline_u, agg_scanline_p, agg_renderer_base, agg_trans_affine
import parse_lion, nimBMP, agg_rasterizer_scanline_aa, agg_alpha_mask_u8, agg_ellipse, random

const
  frameWidth = 512
  frameHeight = 400
  pixWidth = 3

type
  ValueT = uint8

var
  alphaBuf  = newString(frameWidth * frameHeight)
  alphaRbuf = initRenderingBuffer(cast[ptr ValueT](alphaBuf[0].addr), frameWidth, frameHeight, frameWidth)
  alphaMask = initAlphaMaskGray8(alphaRbuf)
  ras       = initRasterizerScanlineAA()
  lion      = parseLion(frameWidth, frameHeight)

proc generateAlphaMask(cx, cy: int) =
  var
    pixf = initPixfmtGray8(alphaRbuf)
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)
    sl   = initScanlineP8()
    ell  = initEllipse()

  rb.clear(initGray8(0))
  randomize()
  for i in 0.. <10:
    ell.init(random(cx.float64), random(cy.float64),
      random(100.0) + 20.0, random(100.0) + 20.0, 100)

    ras.addPath(ell)
    ren.color(initGray8(random(0xFF).uint, random(0xFF).uint))
    renderScanlines(ras, sl, ren)

generateAlphaMask(frameWidth, frameHeight)

var
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
  pf     = initPixFmtRgb24(rbuf)
  rb     = initRendererBase(pf)
  sl     = initScanlineU8Am(alphaMask)
  ren    = initRendererScanlineAASolid(rb)

rb.clear(initRgba(1,1,1))

var trans = initConvTransform(lion.path, lion.mtx)

renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)

saveBMP24("alpha_mask.bmp", buffer, frameWidth, frameHeight)