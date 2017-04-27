import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_color_gray, agg_renderer_mclip, agg_renderer_scanline, agg_path_storage
import agg_conv_transform, agg_bounding_rect, agg_renderer_outline_aa, agg_renderer_primitives
import agg_renderer_markers, agg_span_allocator, agg_span_gradient, agg_span_interpolator_linear
import agg_rasterizer_outline_aa, agg_ellipse, agg_pixfmt_rgb, agg_color_rgba
import parse_lion, agg_renderer_base, random, agg_renderer_markers, agg_trans_affine
import ctrl_slider, agg_platform_support, math

type
  GradientLinearColor[T] = object
    mC1, mC2: T

proc initGradientLinearColor[T](c1, c2: T): GradientLinearColor[T] =
  result.mC1 = c1
  result.mC2 = c2

proc len[T](self: GradientLinearColor[T]): int = 256

proc colors[T](self: var GradientLinearColor[T], c1, c2: T) =
  self.mC1 = c1
  self.mC2 = c2

proc `[]`(self: GradientLinearColor[Rgba8], v: int): Rgba8 =
  type
    ValueT = getValueT(Rgba8)
  const baseShift = getBaseShift(Rgba8)

  let v = v shl (baseShift - 8)
  result.r = ValueT((((self.mC2.r.int - self.mC1.r.int) * v) + (self.mC1.r.int shl baseShift)) shr baseShift)
  result.g = ValueT((((self.mC2.g.int - self.mC1.g.int) * v) + (self.mC1.g.int shl baseShift)) shr baseShift)
  result.b = ValueT((((self.mC2.b.int - self.mC1.b.int) * v) + (self.mC1.b.int shl baseShift)) shr baseShift)
  result.a = ValueT((((self.mC2.a.int - self.mC1.a.int) * v) + (self.mC1.a.int shl baseShift)) shr baseShift)

proc `[]`(self: GradientLinearColor[Gray8], v: int): Gray8 =
  type
    ValueT = getValueT(Gray8)
  const baseShift = getBaseShift(Gray8)

  result.v = ValueT((((self.mC2.v.int - self.mC1.v.int) * v) + (self.mC1.v.int shl baseShift)) shr baseShift)
  result.a = ValueT((((self.mC2.a.int - self.mC1.a.int) * v) + (self.mC1.a.int shl baseShift)) shr baseShift)

const
  frameWidth = 512
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mNumCb: SliderCtrl[Rgba8]
    lion: Lion

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mNumCb = newSliderCtrl[Rgba8](5, 5, 150, 12, not flipY)
  result.lion   = parseLion(frameWidth, frameHeight)
  result.addCtrl(result.mNumCb)
  result.mNumCb.setRange(2, 10)
  result.mNumCb.label("N=$1")
  result.mNumCb.noTransform()

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererMclip(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    width  = app.width()
    height = app.height()

  rb.clear(initRgba(1, 1, 1))
  rb.resetClipping(false)  # Visibility: "false" means "no visible regions"
  let n = app.mNumCb.value().int #number of block

  for x in 0.. <n:
    for y in 0.. <n:
      let
        xx  = x.float64
        yy  = y.float64
        nn  = n.float64
        x1 = int(width  * xx / nn)
        y1 = int(height * yy / nn)
        x2 = int(width  * (xx + 1) / nn)
        y2 = int(height * (yy + 1) / nn)
      rb.addClipBox(x1 + 5, y1 + 5, x2 - 5, y2 - 5)

  var mtx = initTransAffine()
  mtx *= transAffineTranslation(-app.lion.baseDx, -app.lion.baseDy)
  mtx *= transAffineScaling(app.lion.scale, app.lion.scale)
  mtx *= transAffineRotation(app.lion.angle + pi)
  mtx *= transAffineSkewing(app.lion.skewX/1000.0, app.lion.skewY/1000.0)
  mtx *= transAffineTranslation(width/2, height/2)

  # Render the lion
  var trans = initConvTransform(app.lion.path, mtx)
  renderAllPaths(ras, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  # The scanline rasterizer allows you to perform clipping to multiple
  # regions "manually", like in the following code, but the "embedded" method
  # shows much better performance.
  #for i in 0.. <lion.numPaths:
  #  ras.reset()
  #  ras.addPath(trans, lion.pathIdx[i])
  #  ren.color(lion.colors[i])
  #
  #  for x in 0.. <n:
  #    for y in 0.. <n:
  #      let
  #        xx  = x.float64
  #        yy  = y.float64
  #        nn    = n.float64
  #        x1 = int(width  * xx / nn)
  #        y1 = int(height * yy / nn)
  #        x2 = int(width  * (xx + 1) / nn)
  #        y2 = int(height * (yy + 1) / nn)
  #        # r should be of type renderer_base<>
  #      rb.clipBox(initRectI(x1 + 5, y1 + 5, x2 - 5, y2 - 5))
  #      renderScanlines(ras, sl, ren)

  # Render random Bresenham lines and markers
  #randomize()
  var m = initRendererMarkers(rb)
  for i in 0.. <50:
    m.lineColor(initRgba8(random(0x7F), random(0x7F), random(0x7F), random(0x7F) + 0x7F))
    m.fillColor(initRgba8(random(0x7F), random(0x7F), random(0x7F), random(0x7F) + 0x7F))
    m.line(m.coord(random(width)), m.coord(random(height)), m.coord(random(width)), m.coord(random(height)))
    m.marker(random(width).int, random(height).int, random(10) + 5, Marker(random(high(Marker).ord)))

  # Render random anti-aliased lines
  var
    w = 5.0
    profile = initLineProfileAA()
    renAA = initRendererOutlineAA(rb, profile)
    rasAA = initRasterizerOutlineAA(renAA)

  profile.width(w)
  rasAA.roundCap(true)
  for i in 0.. <50:
    renAA.color(initRgba8(random(0x7F), random(0x7F), random(0x7F), random(0x7F) + 0x7F))
    rasAA.moveToD(random(width), random(height))
    rasAA.lineToD(random(width), random(height))
    rasAA.render(false)

  # Render random circles with gradient
  var
    grm = initTransAffine()
    grf: GradientCircle
    grc = initGradientLinearColor(initRgba8(0,0,0), initRgba8(0,0,0))
    sa  = initSpanAllocator[Rgba8]()
    inter = initSpanInterpolatorLinear(grm)
    sg  = initSpanGradient(inter, grf, grc, 0, 10)
    ell: Ellipse

  for i in 0.. <50:
    let
      x = random(width)
      y = random(height)
      radius = random(10.0) + 5.0
    grm.reset()
    grm *= transAffineScaling(radius / 10.0)
    grm *= transAffineTranslation(x, y)
    grm.invert()
    grc.colors(initRgba8(255, 255, 255, 0),
               initRgba8(random(0x7F), random(0x7F), random(0x7F), 255))

    sg.colorFunction(grc)
    ell.init(x, y, radius, radius, 32)
    ras.addPath(ell)
    renderScanlinesAA(ras, sl, rb, sa, sg)

  rb.resetClipping(true) # "true" means "all rendering buffer is visible".
  renderCtrl(ras, sl, rb, app.mNumCb)

proc transform(app: App, width, height, x, y: float64) =
  var
    x = x - width / 2
    y = y - height / 2
  app.lion.angle = arctan2(y, x)
  app.lion.scale = sqrt(y * y + x * x) / 100.0

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    var
      width = app.rbufWindow().width().float64
      height = app.rbufWindow().height().float64
    app.transform(width, height, x.float64, y.float64)
    app.forceRedraw()

  if mouseRight in flags:
    app.lion.skewX = x.float64
    app.lion.skewY = y.float64
    app.forceRedraw()

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  app.onMouseButtonDown(x, y, flags)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Clipping to multiple rectangle regions")

  if app.init(frameWidth, frameHeight, {window_resize}, "multi_clip"):
    return app.run()

  result = 1

discard main()
