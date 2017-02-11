import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_rasterizer_outline, agg_scanline_p, agg_scanline_bin
import agg_renderer_scanline, agg_renderer_primitives
import agg_pixfmt_rgb, agg_renderer_base, agg_path_storage
import agg_color_rgba, agg_gamma_functions, nimBMP

const
  frameWidth = 500
  frameHeight = 330
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  const
    mx = [100.0+120.0, 369.0+120.0, 143.0+120.0]
    my = [60.0, 170.0, 310.0]
    mGamma = 0.5
    mAlpha = 1.0

  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren_aa = initRendererScanlineAASolid(rb)
    ren_bin= initRendererScanlineBinSolid(rb)
    ren_pr = initRendererPrimitives(rb)
    ras_ln = initRasterizerOutline(ren_pr)
    ras    = initRasterizerScanlineAA()
    slp8   = initScanlineP8()
    slbin  = initScanlineBin()
    path   = initPathStorage()

  rb.clear(initRgba(1, 1, 1))

  # draw anti aliased
  path.moveTo(mx[0], my[0])
  path.lineTo(mx[1], my[1])
  path.lineTo(mx[2], my[2])
  path.closePolygon()

  ren_aa.color(initRgba(0.7, 0.5, 0.1, mAlpha))
  ras.gamma(initGammaPower(mGamma * 2.0))
  ras.addPath(path)
  renderScanlines(ras, slp8, ren_aa)

  # draw aliased
  path.removeAll()
  path.moveTo(mx[0] - 200, my[0])
  path.lineTo(mx[1] - 200, my[1])
  path.lineTo(mx[2] - 200, my[2])
  path.closePolygon()

  ren_bin.color(initRgba(0.1, 0.5, 0.7, mAlpha))
  ras.gamma(initGammaThreshold(mGamma))
  ras.addPath(path)
  renderScanlines(ras, slbin, ren_bin)

  # Drawing an outline with subpixel accuracy (aliased)
  ren_pr.lineColor(initRgba(0.0, 0.0, 0.0))
  ras_ln.addPath(path)

  saveBMP24("rasterizers.bmp", buffer, frameWidth, frameHeight)

onDraw()