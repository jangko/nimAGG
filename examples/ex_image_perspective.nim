import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  renderer_scanline, path_storage, conv_transform, trans_affine,
  trans_bilinear, trans_perspective, span_interpolator_linear,
  span_interpolator_trans, span_allocator, image_accessors,
  pixfmt_rgba, span_image_filter_rgba, renderer_base, color_rgba,
  image_filters, gsv_text]
import ctrl/[rbox, polygon], strutils, os, math, platform/support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre

  App = ref object of PlatformSupport
    quad: PolygonCtrl[Rgba8]
    transType: RboxCtrl[Rgba8]
    testFlag: bool
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    x1, y1, x2, y2: float64

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](460, 5.0, 420+170.0, 60.0, not flipY)

  result.addCtrl(result.quad)
  result.addCtrl(result.transType)

  result.testFlag = false
  result.transType.textSize(8)
  result.transType.textThickness(1)
  result.transType.addItem("Affine")
  result.transType.addItem("Bilinear")
  result.transType.addItem("Perspective")
  result.transType.curItem(2)

  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()

method onInit(app: App) =
  let
    d = 0.0
    width = app.width()
    height = app.height()

  app.x1 = d
  app.y1 = d
  app.x2 = app.rbufImg(0).width().float64 - d
  app.y2 = app.rbufImg(0).height().float64 - d

  app.quad.xn(0) = 100
  app.quad.yn(0) = 100
  app.quad.xn(1) = width - 100
  app.quad.yn(1) = 100
  app.quad.xn(2) = width - 100
  app.quad.yn(2) = height - 100
  app.quad.xn(3) = 100
  app.quad.yn(3) = height - 200

method onDraw(app: App) =
  var
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfPre = construct(PixFmtPre, app.rbufWindow())
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)
    sa      = initSpanAllocator[Rgba8]()
    filterKernel: ImageFilterBilinear
    filter  = initImageFilterLut(filterKernel, false)
    pixfImg = construct(PixFmt, app.rbufImg(0))
    imgSrc  = initImageAccessorClone(pixfImg)

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
  app.ras.clipBox(0, 0, app.width(), app.height())
  app.ras.reset()
  app.ras.moveToD(app.quad.xn(0), app.quad.yn(0))
  app.ras.lineToD(app.quad.xn(1), app.quad.yn(1))
  app.ras.lineToD(app.quad.xn(2), app.quad.yn(2))
  app.ras.lineToD(app.quad.xn(3), app.quad.yn(3))

  app.startTimer()
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
    var mtx = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
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
        inter = initSpanInterpolatorTrans(mtx)
        sg    = initSpanImageFilterRgba2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  else: discard

  let tm = app.elapsedTime()

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

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("AGG Example. Image Perspective Transformations")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  if app.init(frameWidth, frameHeight, {window_resize}, "image_perspective"):
    return app.run()

  result = 1

discard main()
