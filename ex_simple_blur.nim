import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_rasterizer_outline
import agg_path_storage, agg_conv_stroke, agg_conv_transform, agg_bounding_rect
import agg_scanline_u, agg_scanline_p, agg_pixfmt_rgb, agg_renderer_base, agg_renderer_outline_aa
import agg_rasterizer_outline_aa, agg_renderer_scanline, agg_span_allocator, agg_ellipse
import agg_trans_affine, agg_color_rgba
import parse_lion, nimBMP

type
  SpanSimpleBlurRgb24[OrderT] = object
    mSourceImage: ptr RenderingBuffer

proc initSpanSimpleBlurRgb24*[OrderT](src: var RenderingBuffer): SpanSimpleBlurRgb24[OrderT] =
  result.mSourceImage = src.addr

proc sourceImage*[OrderT](self: var SpanSimpleBlurRgb24[OrderT], src: var RenderingBuffer) =
  self.mSourceImage = src.addr

proc sourceImage*[OrderT](self: SpanSimpleBlurRgb24[OrderT]): var RenderingBuffer =
  self.mSourceImage[]

proc prepare*[OrderT](self: SpanSimpleBlurRgb24[OrderT]) = discard

proc generate*[OrderT, ColorT](self: var SpanSimpleBlurRgb24[OrderT], span: ptr ColorT, x, y, len: int) =
  var
    len = len
    span = span
    x = x

  if y < 1 or y >= self.mSourceImage[].height() - 1:
    doWhile len != 0:
      span[] = initRgba8(0,0,0,0)
      inc span
      dec len
    return

  doWhile len != 0:
    var color = [0,0,0,0]
    if x > 0 and x < self.mSourceImage[].width()-1:
      var i = 3
      doWhile i != 0:
        var p = self.mSourceImage[].rowPtr(y - i + 2) + (x - 1) * 3

        color[0] += p[].int; inc p
        color[1] += p[].int; inc p
        color[2] += p[].int; inc p
        color[3] += 255

        color[0] += p[].int; inc p
        color[1] += p[].int; inc p
        color[2] += p[].int; inc p
        color[3] += 255

        color[0] += p[].int; inc p
        color[1] += p[].int; inc p
        color[2] += p[].int; inc p
        color[3] += 255
        dec i

      color[0] = color[0] div 9
      color[1] = color[1] div 9
      color[2] = color[2] div 9
      color[3] = color[3] div 9
    span[] = initRgba8(color[OrderT.R.ord].uint, color[OrderT.G.ord].uint, color[OrderT.B.ord].uint, color[3].uint)
    inc span
    inc x
    dec len

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
    sl2    = initScanlineU8()
    ras2   = initRasterizerScanlineAA()
    lion   = parseLion(frameWidth, frameHeight)
    trans  = initConvTransform(lion.path, lion.mtx)
    cx     = 100.0
    cy     = 102.0
  
  rb.clear(initRgba(1, 1, 1))

  lion.mtx *= transAffineTranslation(-frameWidth.float64/4, 0)
  #lion.mtx *= transAffineResizing()

  renderAllPaths(ras2, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)

  #mtx *= ~trans_affine_resizing();
  lion.mtx *= transAffineTranslation(frameWidth.float64/2, 0)
  #mtx *= trans_affine_resizing();

  var
    profile = initLineProfileAA()
    rp      = initRendererOutlineAA(rb, profile)
    ras     = initRasterizerOutlineAA(rp)

  profile.width(1.0)
  ras.roundCap(true)
  ras.renderAllPaths(trans, lion.colors, lion.pathIdx, lion.numPaths)

  var
    ell = initEllipse(cx, cy, 100.0, 100.0, 100)
    ell_stroke1 = initConvStroke(ell)
    ell_stroke2 = initConvStroke(ell_stroke1)

  ell_stroke1.width(6.0)
  ell_stroke2.width(2.0)

  ren.color(initRgba(0,0.2,0))
  ras2.addPath(ell_stroke2)
  renderScanlines(ras2, sl, ren)

  var
    buffer2 = newString(frameWidth * frameHeight * pixWidth)
    rbuf2   = initRenderingBuffer(cast[ptr ValueT](buffer2[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    sg = initSpanSimpleBlurRgb24[OrderRgb](rbuf2)
    sa = initSpanAllocator[Rgba8]()

  ras2.addPath(ell)

  rbuf2.copyFrom(rbuf)
  renderScanlinesAA(ras2, sl2, rb, sa, sg)

  # More blur if desired :-)
  #rbuf2.copyFrom(rbuf)
  #renderScanlinesAA(ras2, sl2, rb, sa, sg)
  #rbuf2.copyFrom(rbuf)
  #renderScanlinesAA(ras2, sl2, rb, sa, sg)

  saveBMP24("simple_blur.bmp", buffer, frameWidth, frameHeight)

onDraw()
