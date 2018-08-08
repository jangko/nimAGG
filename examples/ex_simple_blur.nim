import agg/[basics, rendering_buffer, rasterizer_scanline_aa, rasterizer_outline,
  path_storage, conv_stroke, conv_transform, bounding_rect,
  scanline_u, scanline_p, pixfmt_rgb, renderer_base, renderer_outline_aa,
  rasterizer_outline_aa, renderer_scanline, span_allocator, ellipse,
  trans_affine, color_rgba]
import parse_lion, platform/support

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
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    cx, cy: float64
    lion: Lion

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.lion   = parseLion(frameWidth, frameHeight)
  result.cx     = 100.0
  result.cy     = 102.0

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    sl2    = initScanlineU8()
    ras2   = initRasterizerScanlineAA()
    mtx    = initTransAffine()
    trans  = initConvTransform(app.lion.path, mtx)

  rb.clear(initRgba(1, 1, 1))

  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineScaling(app.lion.scale, app.lion.scale)
  mtx *= transAffineRotation(app.lion.angle + pi)
  mtx *= transAffineSkewing(app.lion.skewX/1000.0, app.lion.skewY/1000.0)
  mtx *= transAffineTranslation(app.initialWidth()/4, app.initialHeight()/2)
  mtx *= transAffineResizing(app)

  renderAllPaths(ras2, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  mtx *= ~transAffineResizing(app)
  mtx *= transAffineTranslation(app.initialWidth()/2, 0)
  mtx *= transAffineResizing(app)

  var
    profile = initLineProfileAA()
    rp      = initRendererOutlineAA(rb, profile)
    ras     = initRasterizerOutlineAA(rp)

  profile.width(1.0)
  ras.roundCap(true)
  ras.renderAllPaths(trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  var
    ell = initEllipse(app.cx, app.cy, 100.0, 100.0, 100)
    ell_stroke1 = initConvStroke(ell)
    ell_stroke2 = initConvStroke(ell_stroke1)

  ell_stroke1.width(6.0)
  ell_stroke2.width(2.0)

  ren.color(initRgba(0,0.2,0))
  ras2.addPath(ell_stroke2)
  renderScanlines(ras2, sl, ren)

  var
    sg = initSpanSimpleBlurRgb24[OrderBgr](app.rbufImg(0))
    sa = initSpanAllocator[Rgba8]()

  ras2.addPath(ell)

  app.copyWindowToImg(0)
  renderScanlinesAA(ras2, sl2, rb, sa, sg)

  # More blur if desired :-)
  #rbuf2.copyFrom(rbuf)
  #renderScanlinesAA(ras2, sl2, rb, sa, sg)
  #rbuf2.copyFrom(rbuf)
  #renderScanlinesAA(ras2, sl2, rb, sa, sg)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Lion with blur")

  if app.init(frameWidth, frameHeight, {window_resize}, "simple_blur"):
    return app.run()

  result = 1

discard main()
