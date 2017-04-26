import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_ellipse
import agg_trans_affine, agg_conv_transform, agg_span_image_filter_rgb
import agg_span_image_filter_rgba, agg_span_image_filter_gray, agg_pixfmt_rgb
import agg_scanline_u, agg_renderer_scanline, agg_span_allocator, agg_span_interpolator_linear
import agg_image_accessors, agg_basics, agg_renderer_base, agg_platform_support
import agg_trans_affine, os, agg_color_rgba, agg_image_filters, ctrl_slider

const
  flipY = true

type
  PixFmt = PixFmtBgr24
  PixFmtPre = PixFmtBgr24Pre

  App = ref object of PlatformSupport
    mAngle: SliderCtrl[Rgba8]
    mScale: SliderCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mAngle = newSliderCtrl[Rgba8](5,  5,    300, 12,    not flipY)
  result.mScale = newSliderCtrl[Rgba8](5,  5+15, 300, 12+15, not flipY)

  result.addCtrl(result.mAngle)
  result.addCtrl(result.mScale)
  result.mAngle.label("Angle=$1")
  result.mScale.label("Scale=$1")
  result.mAngle.setRange(-180.0, 180.0)
  result.mAngle.value(0.0)
  result.mScale.setRange(0.1, 5.0)
  result.mScale.value(1.0)

method onDraw(app: App) =
  var
    pixf    = construct(PixFmt, app.rbufWindow())
    pixfPre = construct(PixFmtPre, app.rbufWindow())

    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)

    srcMtx  = initTransAffine()
    imgMtx  = initTransAffine()

    width   = app.initialWidth()
    height  = app.initialHeight()

    sa      = initSpanAllocator[Rgba8]()
    inter   = initSpanInterpolatorLinear(imgMtx)

    imgPixf = initPixfmtRgb24(app.rbufImg(0))
    imgSrc  = initImageAccessorClip(imgPixf, rgbaPre(0, 0.4, 0, 0.5))

    filter  = initImageFilter[ImageFilterSpline36]()
    sg      = initSpanImageFilterRgb(imgSrc, inter, filter)

    ras     = initRasterizerScanlineAA()
    sl      = initScanlineU8()
    r       = width
    mAngle  = app.mAngle.value()
    mScale  = app.mScale.value()

  rb.clear(initRgba(1.0, 1.0, 1.0))

  srcMtx *= transAffineTranslation(-width/2.0 - 10.0, -height/2.0 - 20.0 - 10.0)
  srcMtx *= transAffineRotation(mAngle * pi / 180.0)
  srcMtx *= transAffineScaling(mScale)
  srcMtx *= transAffineTranslation(width/2.0, height/2.0 + 20.0)
  srcMtx *= transAffineResizing(app)

  imgMtx *= transAffineTranslation(-width/2.0 + 10.0, -height/2.0 + 20.0 + 10.0)
  imgMtx *= transAffineRotation(mAngle * pi / 180.0)
  imgMtx *= transAffineScaling(mScale)
  imgMtx *= transAffineTranslation(width/2.0, height/2.0 + 20.0)
  imgMtx *= transAffineResizing(app)
  imgMtx.invert()

  ras.clipBox(0, 0, app.width(), app.height())
  if height - 60 < r:
    r = height - 60

  var
    ell = initEllipse(width  / 2.0 + 10,
                       height / 2.0 + 20 + 10,
                       r / 2.0 + 16.0,
                       r / 2.0 + 16.0, 200)
    tr  = initConvTransform(ell, srcMtx)

  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rbPre, sa, sg)
  renderCtrl(ras, sl, rb, app.mAngle)
  renderCtrl(ras, sl, rb, app.mScale)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Image Affine Transformations with filtering")

  if not app.loadImg(0, "resources" & DirSep & "spheres.bmp"):
    app.message("failed to load spheres.bmp")
    return 1

  let
    frameWidth = app.rbufImg(0).width()
    frameHeight = app.rbufImg(0).height()

  if app.init(frameWidth, frameHeight, {window_resize}, "image1"):
    return app.run()

  result = 1

discard main()
