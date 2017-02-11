import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_color_rgba
import agg_span_gouraud_gray, agg_span_solid, agg_math, agg_dda_line, agg_pixfmt_rgb
import agg_renderer_base, agg_gamma_functions, agg_span_gouraud_rgba
import agg_renderer_scanline, nimBMP

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3
  mDilation = 0.175
  mGamma = 0.809
  mAlpha = 1.0

type
  ValueT = uint8

var
  m_x, m_y: array[3, float64]
  m_dx, m_dy: float64
  m_idx: int

m_x[0] = 57;    m_y[0] = 60
m_x[1] = 369;   m_y[1] = 170
m_x[2] = 143;   m_y[2] = 310

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    renBase= initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

  var
    alpha = mAlpha
    brc = 1.0'f64
    d = mDilation

  type
    ColorType = Rgba8#getColorT(PixFmtRgb24)

  var spanGen = initSpanGouraudRgba[ColorType]()

  var spanAlloc = initSpanAllocator[ColorType]()

  renBase.clear(initRgba(1,1,1))
  ras.gamma(initGammaLinear(0.0, mGamma))



  # Single triangle
  #spanGen.colors(initRgba(1,   0,   0,  alpha),
  #                initRgba(0,   1,   0,  alpha),
  #                initRgba(0,   0,   1,  alpha));
  #spanGen.triangle(m_x[0], m_y[0], m_x[1], m_y[1], m_x[2], m_y[2], d);
  #ras.addPath(spanGen);
  #renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen);


  # Six triangles
  var
    xc = (m_x[0] + m_x[1] + m_x[2]) / 3.0
    yc = (m_y[0] + m_y[1] + m_y[2]) / 3.0

    x1 = (m_x[1] + m_x[0]) / 2 - (xc - (m_x[1] + m_x[0]) / 2)
    y1 = (m_y[1] + m_y[0]) / 2 - (yc - (m_y[1] + m_y[0]) / 2)

    x2 = (m_x[2] + m_x[1]) / 2 - (xc - (m_x[2] + m_x[1]) / 2)
    y2 = (m_y[2] + m_y[1]) / 2 - (yc - (m_y[2] + m_y[1]) / 2)

    x3 = (m_x[0] + m_x[2]) / 2 - (xc - (m_x[0] + m_x[2]) / 2)
    y3 = (m_y[0] + m_y[2]) / 2 - (yc - (m_y[0] + m_y[2]) / 2)

  spanGen.colors(initRgba(1,   0,   0,    alpha),
                 initRgba(0,   1,   0,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(m_x[0], m_y[0], m_x[1], m_y[1], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   1,   0,    alpha),
                 initRgba(0,   0,   1,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(m_x[1], m_y[1], m_x[2], m_y[2], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   0,   1,   alpha),
                 initRgba(1,   0,   0,   alpha),
                 initRgba(brc, brc, brc, alpha))
  spanGen.triangle(m_x[2], m_y[2], m_x[0], m_y[0], xc, yc, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)


  brc = 1-brc
  spanGen.colors(initRgba(1,   0,   0,    alpha),
                  initRgba(0,   1,   0,    alpha),
                  initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(m_x[0], m_y[0], m_x[1], m_y[1], x1, y1, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   1,   0,    alpha),
                 initRgba(0,   0,   1,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(m_x[1], m_y[1], m_x[2], m_y[2], x2, y2, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)


  spanGen.colors(initRgba(0,   0,   1,    alpha),
                 initRgba(1,   0,   0,    alpha),
                 initRgba(brc, brc, brc,  alpha))
  spanGen.triangle(m_x[2], m_y[2], m_x[0], m_y[0], x3, y3, d)
  ras.addPath(spanGen)
  renderScanlinesAA(ras, sl, renBase, spanAlloc, spanGen)
  saveBMP24("gouraud.bmp", buffer, frameWidth, frameHeight)

onDraw()