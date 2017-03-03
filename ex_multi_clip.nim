import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_color_gray, agg_renderer_mclip, agg_renderer_scanline, agg_path_storage
import agg_conv_transform, agg_bounding_rect, agg_renderer_outline_aa, agg_renderer_primitives
import agg_renderer_markers, agg_span_allocator, agg_span_gradient, agg_span_interpolator_linear
import agg_rasterizer_outline_aa, agg_ellipse, agg_pixfmt_rgb, agg_color_rgba
import nimBMP, parse_lion, agg_renderer_base, random, agg_renderer_markers, agg_trans_affine

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
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererMclip(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    lion   = parseLion(frameWidth, frameHeight)
    width  = frameWidth.float64
    height = frameWidth.float64

  rb.clear(initRgba(1, 1, 1))
  rb.resetClipping(false)  # Visibility: "false" means "no visible regions"
  let n = 6 #number of block

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


  # Render the lion
  var trans = initConvTransform(lion.path, lion.mtx)
  renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)

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
  randomize()
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

  saveBMP24("multi_clip.bmp", buffer, frameWidth, frameHeight)

onDraw()