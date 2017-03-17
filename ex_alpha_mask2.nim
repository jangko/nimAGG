import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u, agg_scanline_p
import agg_color_gray, agg_renderer_mclip, agg_renderer_scanline, agg_path_storage, agg_conv_transform
import agg_bounding_rect, agg_renderer_outline_aa, agg_pixfmt_gray, agg_pixfmt_amask_adaptor
import agg_renderer_primitives, agg_renderer_markers, agg_span_allocator, agg_span_gradient
import agg_span_interpolator_linear, agg_rasterizer_outline_aa, agg_alpha_mask_u8, agg_ellipse
import agg_trans_affine, agg_color_rgba, agg_renderer_base, agg_pixfmt_rgb
import parse_lion, nimBMP, random

const
  frameWidth = 512
  frameHeight = 400
  pixWidth = 3

type
  ValueT = uint8

type
  App = object
    alphaBuf: seq[ValueT]
    alphaRbuf: RenderingBuffer
    alphaMask: AmaskNoclipGray8
    angle, scale, skewX, skewY: float64
    lion: Lion
    ras: RasterizerScanlineAA
    sl: ScanlineU8

proc initApp(): App =
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

proc generateAlphaMask(app: var App, cx, cy: int) =
  var
    pixf = initPixfmtGray8(app.alphaRbuf)
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)
    sl   = initScanlineP8()
    ell  = initEllipse()

  rb.clear(initGray8(0))
  randomize()
  for i in 0.. <10:
    ell.init(random(cx.float64), random(cy.float64),
      random(100.0) + 20.0, random(100.0) + 20.0, 100)

    app.ras.addPath(ell)
    ren.color(initGray8(random(127).uint + 128'u, random(127).uint + 128'u))
    renderScanlines(app.ras, sl, ren)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    pfa    = initPixFmtAmaskAdaptor(pf, app.alphaMask)
    rba    = initRendererBase(pfa)
    rbase  = initRendererBase(pf)
    rs     = initRendererScanlineAASolid(rba)
    width  = frameWidth.float64
    height = frameHeight.float64


  app.generateAlphaMask(frameWidth, frameHeight)
  rbase.clear(initRgba(1, 1, 1))

  # Render the lion
  var trans = initConvTransform(app.lion.path, app.lion.mtx)
  renderAllPaths(app.ras, app.sl, rs, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

  # Render random Bresenham lines and markers
  var markers = initRendererMarkers(rba)
  for i in 0.. <50:
    markers.lineColor(initRgba8(random(0x7F).uint, random(0x7F).uint, random(0x7F).uint, random(0x7F).uint + 0x7F'u))
    markers.fillColor(initRgba8(random(0x7F).uint, random(0x7F).uint, random(0x7F).uint, random(0x7F).uint + 0x7F'u))
    markers.line(markers.coord(random(width)),
                 markers.coord(random(height)),
                 markers.coord(random(width)),
                 markers.coord(random(height)))
    markers.marker(random(width).int, random(height).int, random(10) + 5,
      Marker(random(high(Marker).ord)))

  # Render random anti-aliased lines
  var
    w = 5.0
    profile = initLineProfileAA()

  profile.width(w)
  var
    ren = initRendererOutlineAA(rba, profile)
    ras = initRasterizerOutlineAA(ren)

  ras.roundCap(true)
  for i in 0.. <50:
    ren.color(initRgba8(random(0x7F).uint, random(0x7F).uint, random(0x7F).uint, random(0x7F).uint + 0x7F'u))
    ras.moveToD(random(width), random(height))
    ras.lineToD(random(width), random(height))
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

  for i in 0.. <50:
    var
      x = random(width)
      y = random(height)
      r = random(10.0) + 5.0

    grm.reset()
    grm *= transAffineScaling(r / 10.0)
    grm *= transAffineTranslation(x, y)
    grm.invert()

    grc.colors(initRgba8(255, 255, 255, 0),
               initRgba8(random(0x7F).uint,
                         random(0x7F).uint,
                         random(0x7F).uint,
                         255))
    sg.colorFunction(grc)
    ell.init(x, y, r, r, 32)
    app.ras.addPath(ell)
    renderScanlines(app.ras, app.sl, rg)

  saveBMP24("alpha_mask2.bmp", buffer, frameWidth, frameHeight)

onDraw()