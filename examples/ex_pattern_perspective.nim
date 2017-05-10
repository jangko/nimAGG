import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_u,
  renderer_scanline, path_storage, conv_transform, trans_affine,
  trans_bilinear, trans_perspective, span_interpolator_linear,
  span_interpolator_trans, span_allocator, image_accessors, image_filters,
  renderer_base, color_rgba, pixfmt_rgb, span_image_filter_rgb]
import ctrl.rbox, ctrl.polygon, strutils, os, math, platform.support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24
  PixFmtPre = PixFmtBgr24Pre

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
  result.transType.curItem(1)

  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()
  result.x1  = -150.0
  result.y1  = -150.0
  result.x2  = 150.0
  result.y2  = 150.0

  var
    trans_x1 = -200.0
    trans_y1 = -200.0
    trans_x2 =  200.0
    trans_y2 =  200.0
    dx = frameWidth.float64  / 2.0 - (trans_x2 + trans_x1) / 2.0
    dy = frameHeight.float64 / 2.0 - (trans_y2 + trans_y1) / 2.0

  result.quad.xn(0) = floor(trans_x1 + dx)
  result.quad.yn(0) = floor(trans_y1 + dy)
  result.quad.xn(1) = floor(trans_x2 + dx)
  result.quad.yn(1) = floor(trans_y1 + dy)
  result.quad.xn(2) = floor(trans_x2 + dx)
  result.quad.yn(2) = floor(trans_y2 + dy)
  result.quad.xn(3) = floor(trans_x1 + dx)
  result.quad.yn(3) = floor(trans_y2 + dy)

method onDraw(app: App) =
  var
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfPre = construct(PixFmt, app.rbufWindow())
    width   = app.width()
    height  = app.height()
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)

  if not app.testFlag:
    rb.clear(initRgba(1, 1, 1))

  if app.transType.curItem() == 0:
    # For the affine parallelogram transformations we
    # calculate the 4-th (implicit) point of the parallelogram
    app.quad.xn(3) = app.quad.xn(0) + (app.quad.xn(2) - app.quad.xn(1))
    app.quad.yn(3) = app.quad.yn(0) + (app.quad.yn(2) - app.quad.yn(1))

  if not app.testFlag:
    # Render the "quad" tool and controls
    app.ras.addPath(app.quad)
    renderScanlinesAAsolid(app.ras, app.sl, rb, initRgba(0, 0.3, 0.5, 0.6))
    renderCtrl(app.ras, app.sl, rb, app.transType)

  # Prepare the polygon to rasterize. Here we need to fill
  # the destination (transformed) polygon.
  app.ras.clipBox(0, 0, width, height)
  app.ras.reset()
  app.ras.moveToD(app.quad.xn(0), app.quad.yn(0))
  app.ras.lineToD(app.quad.xn(1), app.quad.yn(1))
  app.ras.lineToD(app.quad.xn(2), app.quad.yn(2))
  app.ras.lineToD(app.quad.xn(3), app.quad.yn(3))

  type
    RemainderT = WrapModeReflectAutoPow2

  var
    sa = initSpanAllocator[Rgba8]()
    filter  = initImageFilter[ImageFilterHanning]()
    imgPixf = construct(PixFmt, app.rbufImg(0))
    imgSrc  = initImageAccessorWrap[PixFmt, RemainderT, RemainderT](imgPixf)

  case app.transType.curItem()
  of 0:
    # Note that we consruct an affine matrix that transforms
    # a parallelogram to a rectangle, i.e., it's inverted.
    # It's actually the same as:
    # tr(app.x1, app.y1, app.x2, app.y2, m_triangle.polygon());
    # tr.invert();
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)

    # Also note that we can use the linear interpolator instead of
    # arbitrary span_interpolator_trans. It works much faster,
    # but the transformations must be linear and parellel.
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)

  of 1:
    var mtx = initTransBilinear(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2);
    if mtx.isValid():
      var
        inter = initSpanInterpolatorLinear(mtx)
        sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)

  of 2:
    var mtx = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2);
    if mtx.isValid():
      var
        inter = initSpanInterpolatorTrans(mtx)
        sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  else:
    discard

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Pattern Perspective Transformations")

  if not app.loadImg(0, "resources" & DirSep & "agg.bmp"):
    app.message("failed to load agg.bmp")
    return 1

  if app.init(frameWidth, frameHeight, {window_resize}, "pattern_perspective"):
    return app.run()

  result = 1

discard main()
