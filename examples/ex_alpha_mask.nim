import agg / [basics, rendering_buffer, color_rgba, color_gray, path_storage,
  conv_transform, bounding_rect, renderer_scanline, pixfmt_rgb, pixfmt_gray,
  scanline_u, scanline_p, renderer_base, trans_affine, ellipse,
  rasterizer_scanline_aa, alpha_mask_u8]

import random, parse_lion, math, platform/support

const
  frameWidth = 512
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24
  ColorT = getColorT(PixFmt)
  ValueT = getValueT(ColorT)

  App = ref object of PlatformSupport

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
  for i in 0..<10:
    ell.init(rand(cx.float64), rand(cy.float64),
      rand(100.0) + 20.0, rand(100.0) + 20.0, 100)

    ras.addPath(ell)
    ren.color(initGray8(rand(0xFF).uint, rand(0xFF).uint))
    renderScanlines(ras, sl, ren)

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

method onResize*(app: App, sx, sy: int) =
  generateAlphaMask(sx, sy)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineU8Am(alphaMask)
    ren    = initRendererScanlineAASolid(rb)
    width  = app.width()
    height = app.height()

  rb.clear(initRgba(1,1,1))

  var mtx  = initTransAffine()
  mtx *= transAffineTranslation(-lion.baseDx, -lion.baseDy)
  mtx *= transAffineScaling(lion.scale, lion.scale)
  mtx *= transAffineRotation(lion.angle + pi)
  mtx *= transAffineSkewing(lion.skewX/1000.0, lion.skewY/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)
  var trans = initConvTransform(lion.path, mtx)

  renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)

proc transform(width, height, x, y: float64) =
  var
    x = x - (width / 2)
    y = y - (height / 2)

  lion.angle = arctan2(y, x)
  lion.scale = sqrt(y * y + x * x) / 100.0

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    var
      width = app.width()
      height = app.height()
    transform(width, height, x, y)
    app.forceRedraw()

  if mouseRight in flags:
    lion.skewX = x
    lion.skewY = y
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  app.onMouseButtonDown(x, y, flags)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Lion with Alpha-Masking")

  if app.init(frameWidth, frameHeight, {window_resize}, "alpha_mask"):
    return app.run()

  result = 1

discard main()
