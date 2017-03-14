import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_color_gray
import agg_span_gouraud_gray, agg_span_solid, agg_math, agg_dda_line, agg_pixfmt_gray
import agg_renderer_base, agg_gamma_functions, agg_span_gouraud_rgba
import agg_renderer_scanline, nimBMP, agg_color_rgba, agg_pixfmt_rgb
import agg_color_conv, agg_color_conv_rgb8, math, agg_conv_clip_polygon, make_arrows
import agg_path_storage, agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_bounding_rect, agg_conv_unclose_polygon, agg_conv_close_polygon
import agg_conv_shorten_path, agg_conv_clip_polyline

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3
  mGamma = 0.809
  mDilation = 0.175
  mAlpha = 1.0

type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()

  var
    alpha = mAlpha
    d = mDilation

  type ColorT = Rgba8
  var spanGen = initSpanGouraudRgba[ColorT]()
  var spanAlloc = initSpanAllocator[ColorT]()

  rb.clear(initRgba(1,1,1))
  ras.gamma(initGammaLinear(0.0, mGamma))

  const
    side = 20.0
    gap = 3.0
    sin60 = sin(deg_to_rad(60.0))
    cos60 = cos(deg_to_rad(60.0))

  var
    startX = 10.0
    startY = 15.0
    x = startX
    y = startY

  # Single triangle
  spanGen.colors(initRgba(1, 0, 0, alpha), initRgba(0, 1, 0, alpha), initRgba(0, 0, 1, alpha))

  var
    pola = [
      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      1,1,1,1,0,1,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,
      1,1,1,0,0,0,1,1,1,0,0,1,1,0,0,0,1,0,0,1,1,0,0,0,1,1,
      1,1,0,1,1,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,0,1,1,
      1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,1,1,1,
      1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    ]

  let w = 26
  for k in 0.. <6:
    if k mod 2 == 0:
      for i in 0.. <w:
        let up = if i mod 2 == 0: 1.0 else: -1.0
        if pola[(5 - k) * w + i] != 0:
          spanGen.triangle(x, y, x + side, y, x + cos60 * side, y + sin60 * side * up, d)
          ras.addPath(spanGen)
          renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)
        x = x + cos60 * side + gap
        y = y + side * up
    else:
      y = y + side
      for i in 0.. <w:
        let up = if i mod 2 == 0: -1.0 else: 1.0
        if pola[(5 - k) * w + i] != 0:
          spanGen.triangle(x, y, x + side, y, x + cos60 * side, y + sin60 * side * up, d)
          ras.addPath(spanGen)
          renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)
        x = x + cos60 * side + gap
        y = y + side * up
      y = y - side
    y = y + side + gap
    x = startX

  var
    ren   = initRendererScanlineAASolid(rb)
    arrow = initPathStorage()
    mtx   = initTransAffine()
    mx = frameWidth.float64 / 2.0
    my = frameHeight.float64 / 2.0

  makeSingleArrow(arrow)
  var
    rc     = boundingRectD(arrow, 0)
    baseDx = rc.x1 + (rc.x2 - rc.x1) / 2.0
    baseDy = rc.y1 + (rc.y2 - rc.y1) / 2.0

  mtx *= transAffineTranslation(-baseDx, -baseDy)
  #mtx *= transAffineScaling(0.5)
  mtx *= transAffineTranslation(frameHeight.float64/2.0, frameHeight.float64/2.0)
  mtx *= transAffineTranslation(10.0, 20.0)

  var
    transArrow = initConvTransform(arrow, mtx)
    stroke     = initConvStroke(transArrow)
    #path     = initConvUnclosePolygon(stroke)
    #path      = initConvShortenPath(stroke)
    clip      = initConvClipPolyline(stroke)
    path     = initConvClosePolygon(clip)
  #path.shorten(0.5)

  clip.clipBox(mx-40, my-40, mx+40, my+40)
  stroke.width(2)
  ras.reset()
  ras.addPath(path)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.5))
  renderScanlines(ras, sl, ren)

  #var
  #  target = newString(frameWidth * frameHeight * 3)
  #  rbuf2  = initRenderingBuffer(cast[ptr ValueT](target[0].addr), frameWidth, frameHeight, -frameWidth * 3)
  #
  #colorConv(rbuf2, rbuf, color_conv_gray8_to_rgb24)
  saveBMP24("logo.bmp", buffer, frameWidth, frameHeight)

onDraw()