import agg / [basics, rendering_buffer, rasterizer_scanline_aa, scanline_u, scanline_p,
  color_gray, renderer_mclip, renderer_scanline, path_storage, conv_transform,
  bounding_rect, renderer_outline_aa, pixfmt_gray, pixfmt_amask_adaptor,
  renderer_primitives, renderer_markers, span_allocator, span_gradient,
  span_interpolator_linear, rasterizer_outline_aa, alpha_mask_u8, ellipse,
  trans_affine, color_rgba, renderer_base, pixfmt_rgb]
import parse_lion, random, ctrl.slider, platform.support, math

const
  frameWidth = 512
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24
  ColorT = getColorT(PixFmt)
  ValueT = getValueT(ColorT)

  App = ref object of PlatformSupport
    alphaBuf: seq[ValueT]
    alphaRbuf: RenderingBuffer
    alphaMask: AmaskNoclipGray8
    angle, scale, skewX, skewY: float64
    lion: Lion
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    mNumCb: SliderCtrl[Rgba8]
    mSliderValue: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mNumCb = newSliderCtrl[Rgba8](5, 5, 150, 12, not flipY)
  result.addCtrl(result.mNumCb)
  result.mNumCb.setRange(5, 100)
  result.mNumCb.value(10)
  result.mNumCb.label("N=$1")
  result.mNumCb.noTransform()

  result.mSliderValue = 0.0

  result.alphaBuf  = newSeq[ValueT](frameWidth * frameHeight)
  result.alphaRbuf = initRenderingBuffer(result.alphaBuf[0].addr, frameWidth, frameHeight, frameWidth)
  result.alphaMask = initAmaskNoClipGray8(result.alphaRbuf)

  result.angle = 0.0
  result.scale = 1.0
  result.skewX = 0.0
  result.skewY = 0.0

  result.ras  = initRasterizerScanlineAA()
  result.sl   = initScanlineU8()
  result.lion = parseLion(frameWidth, frameHeight, result.scale, result.angle, result.skewX, result.skewY)

proc generateAlphaMask(app: App, cx, cy: int) =
  if app.alphaBuf.len < cx * cy:
    app.alphaBuf = newSeq[ValueT](cx * cy)
    app.alphaRbuf.attach(app.alphaBuf[0].addr, cx, cy, cx)

  var
    pixf = initPixfmtGray8(app.alphaRbuf)
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)
    sl   = initScanlineP8()
    ell  = initEllipse()

  rb.clear(initGray8(0))
  randomize()
  for i in 0..<int(app.mNumCb.value()):
    ell.init(rand(cx.float64), rand(cy.float64),
      rand(100.0) + 20.0, rand(100.0) + 20.0, 100)

    app.ras.addPath(ell)
    ren.color(initGray8(rand(127).uint + 128'u, rand(127).uint + 128'u))
    renderScanlines(app.ras, sl, ren)

method onResize*(app: App, sx, sy: int) =
  app.generateAlphaMask(sx, sy)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    pfa    = initPixFmtAmaskAdaptor(pf, app.alphaMask)
    rba    = initRendererBase(pfa)
    rbase  = initRendererBase(pf)
    rs     = initRendererScanlineAASolid(rba)
    width  = app.width()
    height = app.height()


  if app.mNumCb.value() != app.mSliderValue:
    app.generateAlphaMask(width.int, height.int)
    app.mSliderValue = app.mNumCb.value()

  rbase.clear(initRgba(1, 1, 1))

  var mtx  = initTransAffine()
  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineScaling(app.scale, app.scale)
  mtx *= transAffineRotation(app.angle + pi)
  mtx *= transAffineSkewing(app.skewX/1000.0, app.skewY/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)

  # Render the lion
  var trans = initConvTransform(app.lion.path, mtx)
  renderAllPaths(app.ras, app.sl, rs, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  # Render random Bresenham lines and markers
  var markers = initRendererMarkers(rba)
  for i in 0..<50:
    markers.lineColor(initRgba8(rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint + 0x7F'u))
    markers.fillColor(initRgba8(rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint + 0x7F'u))
    markers.line(markers.coord(rand(width)),
                 markers.coord(rand(height)),
                 markers.coord(rand(width)),
                 markers.coord(rand(height)))
    markers.marker(rand(width).int, rand(height).int, rand(10) + 5,
      Marker(rand(high(Marker).ord)))

  # Render random anti-aliased lines
  var
    w = 5.0
    profile = initLineProfileAA()

  profile.width(w)
  var
    ren = initRendererOutlineAA(rba, profile)
    ras = initRasterizerOutlineAA(ren)

  ras.roundCap(true)
  for i in 0..<50:
    ren.color(initRgba8(rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint, rand(0x7F).uint + 0x7F'u))
    ras.moveToD(rand(width), rand(height))
    ras.lineToD(rand(width), rand(height))
    ras.render(false)

  # Render random circles with gradient
  var
    grm = initTransAffine()
    grf : GradientCircle
    grc = initGradientLinearColor(initRgba8(0,0,0), initRgba8(0,0,0))
    ell = initEllipse()
    sa  = initSpanAllocator[Rgba8]()
    inter = initSpanInterpolatorLinear(grm)
    sg  = initSpanGradient(inter, grf, grc, 0, 10)
    rg  = initRendererScanlineAA(rba, sa, sg)

  for i in 0..<50:
    var
      x = rand(width)
      y = rand(height)
      r = rand(10.0) + 5.0

    grm.reset()
    grm *= transAffineScaling(r / 10.0)
    grm *= transAffineTranslation(x, y)
    grm.invert()

    grc.colors(initRgba8(255, 255, 255, 0),
               initRgba8(rand(0x7F).uint,
                         rand(0x7F).uint,
                         rand(0x7F).uint,
                         255))
    sg.colorFunction(grc)
    ell.init(x, y, r, r, 32)
    app.ras.addPath(ell)
    renderScanlines(app.ras, app.sl, rg)

  renderCtrl(app.ras, app.sl, rbase, app.mNumCb)

proc transform(app: App, width, height, x, y: float64) =
  var
    x = x - (width / 2)
    y = y - (height / 2)

  app.angle = arctan2(y, x)
  app.scale = sqrt(y * y + x * x) / 100.0

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    var
      width = app.width()
      height = app.height()
    app.transform(width, height, x, y)
    app.forceRedraw()

  if mouseRight in flags:
    app.skewX = x
    app.skewY = y
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
