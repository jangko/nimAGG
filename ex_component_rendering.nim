import
  agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_cells_aa,
  agg_scanline_p, agg_ellipse, agg_pixfmt_gray, agg_pixfmt_rgb,
  agg_color_gray, agg_renderer_base, agg_color_rgba,
  agg_renderer_scanline, nimBMP

pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 2, PixfmtGray8bgr24r)
pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 1, PixfmtGray8bgr24g)
pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 0, PixfmtGray8bgr24b)

const
  frameWidth = 320
  frameHeight = 320
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pf  = initPixFmtBgr24(rbuf)
    pfr = initPixfmtGray8bgr24r(rbuf)
    pfg = initPixfmtGray8bgr24g(rbuf)
    pfb = initPixfmtgray8bgr24b(rbuf)
    rbase = initRendererBase(pf)
    rbr = initRendererBase(pfr)
    rbg = initRendererBase(pfg)
    rbb = initRendererBase(pfb)
    ras = initRasterizerScanlineAA()
    sl = initScanlineP8()

  var bkg = initRgba(1,1,1)
  rbase.clear(initRgba8(bkg))

  var er = initEllipse(frameWidth.float64 / 2 - 0.87*50, frameHeight.float64 / 2 - 0.5*50, 100.0, 100.0, 100)
  ras.addPath(er)

  var alpha = 255'u
  renderScanlinesAASolid(ras, sl, rbr, initGray8(0'u, alpha))

  var eg = initEllipse(frameWidth.float64 / 2 + 0.87*50, frameHeight.float64 / 2 - 0.5*50, 100, 100, 100)
  ras.addPath(eg)
  renderScanlinesAASolid(ras, sl, rbg, initGray8(0'u, alpha))

  var eb = initEllipse(frameWidth.float64 / 2, frameHeight.float64 / 2 + 50, 100, 100, 100)
  ras.addPath(eb)
  renderScanlinesAASolid(ras, sl, rbb, initGray8(0'u, alpha))

  saveBMP24("component_rendering.bmp", buffer, frameWidth, frameHeight)

onDraw()