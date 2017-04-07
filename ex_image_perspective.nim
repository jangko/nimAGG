import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_trans_affine
import agg_trans_bilinear, agg_trans_perspective, agg_span_interpolator_linear
import agg_span_interpolator_trans, agg_span_allocator, agg_image_accessors
import ctrl_rbox, ctrl_polygon, agg_pixfmt_rgba, agg_span_image_filter_rgba
import agg_renderer_base, agg_color_rgba, nimBMP, strutils, os, math
import agg_image_filters, agg_gsv_text, times

const
  frameWidth = 600
  frameHeight = 600
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

type
  App = object
    quad: PolygonCtrl[Rgba8]
    transType: RboxCtrl[Rgba8]
    testFlag: bool
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    x1, y1, x2, y2: float64
    bmp: seq[BmpResult[string]]
    rbuf: seq[RenderingBuffer]

proc initApp(): App =
  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](460, 5.0, 420+170.0, 60.0, not flipY)
  result.testFlag = false
  result.transType.textSize(8)
  result.transType.textThickness(1)
  result.transType.addItem("Affine")
  result.transType.addItem("Bilinear")
  result.transType.addItem("Perspective")
  result.transType.curItem(2)

  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()

  result.bmp = newSeq[BmpResult[string]](10)
  result.rbuf = newSeq[RenderingBuffer](10)

proc loadImage(app: var App, idx: int, name: string) =
  app.bmp[idx] = loadBMP32("resources$1$2.bmp" % [$DirSep, name])
  if app.bmp[idx].width == 0 and app.bmp[idx].width == 0:
    echo "failed to load $1.bmp" % [name]
    quit(0)

  let numPix = app.bmp[idx].width*app.bmp[idx].height
  for i in 0.. <numPix:
    app.bmp[idx].data[i * 4 + 3] = 255.chr

  app.rbuf[idx] = initRenderingBuffer(cast[ptr ValueT](app.bmp[idx].data[0].addr),
    app.bmp[idx].width, app.bmp[idx].height, -app.bmp[idx].width * pixWidth)

proc rbufImage(app: var App, idx: int): var RenderingBuffer =
  result = app.rbuf[idx]

proc getBmp(app: var App, idx: int): var BmpResult[string] =
  app.bmp[idx]

proc init(app: var App) =
  let
    d = 0.0
    width = frameWidth.float64
    height = frameHeight.float64

  app.x1 = d
  app.y1 = d
  app.x2 = app.rbufImage(0).width().float64 - d
  app.y2 = app.rbufImage(0).height().float64 - d

  app.quad.xn(0) = 100
  app.quad.yn(0) = 100
  app.quad.xn(1) = width  - 100
  app.quad.yn(1) = 100
  app.quad.xn(2) = width  - 100
  app.quad.yn(2) = height - 100
  app.quad.xn(3) = 100
  app.quad.yn(3) = height - 100

proc onDraw() =
  var app = initApp()
  app.loadImage(0, "spheres")

  var
    buffer  = newString(frameWidth * frameHeight * pixWidth)
    rbuf    = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    width   = frameWidth.float64
    height  = frameHeight.float64
    pixf    = initPixfmtRgba32(rbuf)
    pixfPre = initPixfmtRgba32Pre(rbuf)
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    sa      = initSpanAllocator[Rgba8]()
    filterKernel: ImageFilterBilinear
    filter  = initImageFilterLut(filterKernel, false)
    pixfImg = initPixfmtRgba32(app.rbufImage(0))
    imgSrc  = initImageAccessorClone(pixfImg)

  app.init()
  rb.clear(initRgba(1, 1, 1))

  if app.transType.curItem() == 0:
    # For the affine parallelogram transformations we
    # calculate the 4-th (implicit) point of the parallelogram
    app.quad.xn(3) = app.quad.xn(0) + (app.quad.xn(2) - app.quad.xn(1))
    app.quad.yn(3) = app.quad.yn(0) + (app.quad.yn(2) - app.quad.yn(1))

  #--------------------------
  # Render the "quad" tool and controls
  app.ras.addPath(app.quad);
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(0, 0.3, 0.5, 0.6))

  # Prepare the polygon to rasterize. Here we need to fill
  # the destination (transformed) polygon.
  app.ras.clipBox(0, 0, width, height)
  app.ras.reset()
  app.ras.moveToD(app.quad.xn(0), app.quad.yn(0))
  app.ras.lineToD(app.quad.xn(1), app.quad.yn(1))
  app.ras.lineToD(app.quad.xn(2), app.quad.yn(2))
  app.ras.lineToD(app.quad.xn(3), app.quad.yn(3))

  let startTime = cpuTime()
  case app.transType.curItem()
  of 0:
    # Note that we consruct an affine matrix that transforms
    # a parallelogram to a rectangle, i.e., it's inverted.
    # It's actually the same as:
    # tr(g_x1, g_y1, g_x2, g_y2, m_triangle.polygon());
    # tr.invert();
    var mtx = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)

    # Also note that we can use the linear interpolator instead of
    # arbitrary span_interpolator_trans. It works much faster,
    # but the transformations must be linear and parellel.
    var
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageFilterRgbaNN(imgSrc, inter)
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 1:
    var mtx = initTransBilinear(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
    if mtx.isValid():
      var
        inter = initSpanInterpolatorLinear(mtx)
        sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  of 2:
    var mtx = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2);
    if mtx.isValid():
      # Subdivision and linear interpolation (faster, but less accurate)
      #-----------------------
      #typedef agg::span_interpolator_linear<agg::trans_perspective> interpolator_type;
      #typedef agg::span_subdiv_adaptor<interpolator_type> subdiv_adaptor_type;
      #interpolator_type interpolator(tr);
      #subdiv_adaptor_type subdiv_adaptor(interpolator);
      #
      #typedef agg::span_image_filter_rgba_2x2<img_accessor_type,
      #                                        subdiv_adaptor_type> span_gen_type;
      #span_gen_type sg(ia, subdiv_adaptor, filter);

      # Direct calculations of the coordinates
      var
        inter = initSpanInterpolatorLinear(mtx)
        sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  else: discard

  let tm = cpuTime() - startTime

  var
    t = initGsvText()
    pt = initConvStroke(t)
    buf = "$1 ms" % [tm.formatFloat(ffDecimal, 2)]


  t.size(10.0)
  pt.width(1.5)
  t.startPoint(10.0, 10.0)
  t.text(buf)

  app.ras.addPath(pt)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(0,0,0))

  renderCtrl(app.ras, app.sl, rb, app.transType)

  saveBMP32("pattern_perspective.bmp", buffer, frameWidth, frameHeight)

onDraw()