import agg/[basics, rendering_buffer, rasterizer_scanline_aa, conv_curve,
  conv_contour, conv_stroke, scanline_p, renderer_scanline,
  pixfmt_rgb, pixfmt_rgba, pixfmt_gray, bounding_rect,
  trans_perspective, blur, renderer_base, color_rgba, color_gray, path_storage,
  trans_affine, conv_transform, gsv_text]
import ctrl/[slider, rbox, cbox, polygon]
import strutils, platform.support

const
  frameWidth = 440
  frameHeight = 330
  flipY = true
  pixWidth = 3

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    how: RboxCtrl[Rgba8]
    chr, chg, chb: CboxCtrl[Rgba8]
    radius: SliderCtrl[Rgba8]
    shadow: PolygonCtrl[Rgba8]
    path: PathStorage
    shape: ConvCurve[PathStorage]
    ras: RasterizerScanlineAA
    sl: ScanlineP8
    shapeBounds: RectD
    rbuf2: RenderingBuffer
    stackBlur: StackBlur[Rgba8, StackBlurCalcRgb]
    recursiveBlur: RecursiveBlur[Rgba8, RecursiveBlurCalcRgb]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.how = newRboxCtrl[Rgba8](10.0, 10.0, 130.0, 70.0, not flipY)
  result.radius = newSliderCtrl[Rgba8](130 + 10.0, 10.0 + 4.0, 130 + 300.0, 10.0 + 8.0 + 4.0, not flipY)
  result.shadow = newPolygonCtrl[Rgba8](4)
  result.chr = newCboxCtrl[Rgba8](10.0, 80.0,  "Red", not flipY)
  result.chg = newCboxCtrl[Rgba8](10.0, 95.0,  "Green", not flipY)
  result.chb = newCboxCtrl[Rgba8](10.0, 110.0, "Blue", not flipY)

  result.addCtrl(result.how)
  result.addCtrl(result.radius)
  result.addCtrl(result.shadow)
  result.addCtrl(result.chr)
  result.addCtrl(result.chg)
  result.addCtrl(result.chb)

  result.path = initPathStorage()
  result.shape = initConvCurve(result.path)
  result.ras = initRasterizerScanlineAA()
  result.sl = initScanlineP8()
  result.rbuf2 = initRenderingBuffer()

  result.how.textSize(8)
  result.how.addItem("Stack Blur")
  result.how.addItem("Recursive Blur")
  result.how.addItem("Channels")
  result.how.curItem(1)

  result.radius.setRange(0.0, 40.0)
  result.radius.value(15.0)
  result.radius.label("Blur Radius=$1")

  result.chg.status(true)

  result.path.removeAll()
  result.path.moveTo(28.47, 6.45)
  result.path.curve3(21.58, 1.12, 19.82, 0.29)
  result.path.curve3(17.19, -0.93, 14.21, -0.93)
  result.path.curve3(9.57, -0.93, 6.57, 2.25)
  result.path.curve3(3.56, 5.42, 3.56, 10.60)
  result.path.curve3(3.56, 13.87, 5.03, 16.26)
  result.path.curve3(7.03, 19.58, 11.99, 22.51)
  result.path.curve3(16.94, 25.44, 28.47, 29.64)
  result.path.lineTo(28.47, 31.40)
  result.path.curve3(28.47, 38.09, 26.34, 40.58)
  result.path.curve3(24.22, 43.07, 20.17, 43.07)
  result.path.curve3(17.09, 43.07, 15.28, 41.41)
  result.path.curve3(13.43, 39.75, 13.43, 37.60)
  result.path.lineTo(13.53, 34.77)
  result.path.curve3(13.53, 32.52, 12.38, 31.30)
  result.path.curve3(11.23, 30.08, 9.38, 30.08)
  result.path.curve3(7.57, 30.08, 6.42, 31.35)
  result.path.curve3(5.27, 32.62, 5.27, 34.81)
  result.path.curve3(5.27, 39.01, 9.57, 42.53)
  result.path.curve3(13.87, 46.04, 21.63, 46.04)
  result.path.curve3(27.59, 46.04, 31.40, 44.04)
  result.path.curve3(34.28, 42.53, 35.64, 39.31)
  result.path.curve3(36.52, 37.21, 36.52, 30.71)
  result.path.lineTo(36.52, 15.53)
  result.path.curve3(36.52, 9.13, 36.77, 7.69)
  result.path.curve3(37.01, 6.25, 37.57, 5.76)
  result.path.curve3(38.13, 5.27, 38.87, 5.27)
  result.path.curve3(39.65, 5.27, 40.23, 5.62)
  result.path.curve3(41.26, 6.25, 44.19, 9.18)
  result.path.lineTo(44.19, 6.45)
  result.path.curve3(38.72, -0.88, 33.74, -0.88)
  result.path.curve3(31.35, -0.88, 29.93, 0.78)
  result.path.curve3(28.52, 2.44, 28.47, 6.45)
  result.path.closePolygon()

  result.path.moveTo(28.47, 9.62)
  result.path.lineTo(28.47, 26.66)
  result.path.curve3(21.09, 23.73, 18.95, 22.51)
  result.path.curve3(15.09, 20.36, 13.43, 18.02)
  result.path.curve3(11.77, 15.67, 11.77, 12.89)
  result.path.curve3(11.77, 9.38, 13.87, 7.06)
  result.path.curve3(15.97, 4.74, 18.70, 4.74)
  result.path.curve3(22.41, 4.74, 28.47, 9.62)
  result.path.closePolygon()

  var shapeMtx = initTransAffine()
  shapeMtx *= transAffineScaling(4.0)
  shapeMtx *= transAffineTranslation(150, 100)
  result.path.transform(shapeMtx)

  discard boundingRectSingle(result.shape, 0,
                     result.shapeBounds.x1, result.shapeBounds.y1,
                     result.shapeBounds.x2, result.shapeBounds.y2)

  result.shadow.xn(0) = result.shapeBounds.x1
  result.shadow.yn(0) = result.shapeBounds.y1
  result.shadow.xn(1) = result.shapeBounds.x2
  result.shadow.yn(1) = result.shapeBounds.y1
  result.shadow.xn(2) = result.shapeBounds.x2
  result.shadow.yn(2) = result.shapeBounds.y2
  result.shadow.xn(3) = result.shapeBounds.x1
  result.shadow.yn(3) = result.shapeBounds.y2
  result.shadow.lineColor(initRgba(0, 0.3, 0.5, 0.3))

pixFmtAlphaBlendGray(BlenderGray8, RenderingBuffer, pixWidth, 2, PixFmtGray8R)
pixFmtAlphaBlendGray(BlenderGray8, RenderingBuffer, pixWidth, 1, PixFmtGray8G)
pixFmtAlphaBlendGray(BlenderGray8, RenderingBuffer, pixWidth, 0, PixFmtGray8B)

method onDraw(app: App) =
  var
    pf   = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pf)
    shadowPersp = initTransPerspective(app.shapeBounds.x1, app.shapeBounds.y1,
                                       app.shapeBounds.x2, app.shapeBounds.y2,
                                       app.shadow.polygon())
    shadowTrans = initConvTransform(app.shape, shadowPersp)

  rb.clear(initRgba(1.0, 1.0, 1.0))
  app.ras.clipBox(0, 0, frameWidth, frameHeight)

  # Render shadow
  app.ras.addPath(shadowTrans)
  renderScanlinesAAsolid(app.ras, app.sl, rb, initRgba(0.2,0.3,0.0))

  # Calculate the bounding box and extend it by the blur radius
  var bbox: RectD
  discard boundingRectSingle(shadowTrans, 0, bbox.x1, bbox.y1, bbox.x2, bbox.y2)

  bbox.x1 -= app.radius.value()
  bbox.y1 -= app.radius.value()
  bbox.x2 += app.radius.value()
  bbox.y2 += app.radius.value()


  if app.how.curItem() == 1:
    # The recursive blur method represents the true Gussian Blur,
    # with theoretically infinite kernel. The restricted window size
    # results in extra influence of edge pixels. It's impossible to
    # solve correctly, but extending the right and top areas to another
    # radius value produces fair result.
    #------------------
    bbox.x2 += app.radius.value()
    bbox.y2 += app.radius.value()

  app.startTimer()
  if app.how.curItem() != 2:
    # Create a new pixel renderer and attach it to the main one as a child image.
    # It returns true if the attachment suceeded. It fails if the rectangle
    # (bbox) is fully clipped.
    var pf2 = initPixFmtRgb24(app.rbuf2)
    if pf2.attach(pf, int(bbox.x1), int(bbox.y1), int(bbox.x2), int(bbox.y2)):
      # Blur it
      if app.how.curItem() == 0:
        # More general method, but 30-40% slower.
        #m_stack_blur.blur(pf2, agg::uround(m_radius.value()));

        # Faster, but bore specific.
        # Works only for 8 bits per channel and only with radii <= 254.
        stackBlurRgb24(pf2, uround(app.radius.value()), uround(app.radius.value()))
      else:
        # True Gaussian Blur, 3-5 times slower than Stack Blur,
        # but still constant time of radius. Very sensitive
        # to precision, doubles are must here.
        app.recursiveBlur.blur(pf2, app.radius.value())
  else:
    # Blur separate channels
    if app.chr.status():
      var pf2r = initPixFmtGray8R(app.rbuf2)
      if pf2r.attach(pf, int(bbox.x1), int(bbox.y1), int(bbox.x2), int(bbox.y2)):
        stackBlurGray8(pf2r, uround(app.radius.value()), uround(app.radius.value()))

    if app.chg.status():
      var pf2g = initPixFmtGray8G(app.rbuf2)
      if pf2g.attach(pf, int(bbox.x1), int(bbox.y1), int(bbox.x2), int(bbox.y2)):
        stackBlurGray8(pf2g, uround(app.radius.value()), uround(app.radius.value()))

    if app.chb.status():
      var pf2b = initPixFmtGray8B(app.rbuf2)
      if pf2b.attach(pf, int(bbox.x1), int(bbox.y1), int(bbox.x2), int(bbox.y2)):
        stackBlurGray8(pf2b, uround(app.radius.value()), uround(app.radius.value()))

  let t1 = app.elapsedTime()
  renderCtrl(app.ras, app.sl, rb, app.shadow)

  # Render the shape itself
  app.ras.addPath(app.shape)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba(0.6,0.9,0.7, 0.8))

  var
    t = initGsvText()
    st = initConvStroke(t)

  t.size(10.0)
  st.width(1.5)
  t.startPoint(140.0, 30.0)
  t.text(t1.formatFloat(ffDecimal, 2) & " ms")
  app.ras.addPath(st)
  renderScanlinesAAsolid(app.ras, app.sl, rb, initRgba(0,0,0))

  renderCtrl(app.ras, app.sl, rb, app.how)
  renderCtrl(app.ras, app.sl, rb, app.radius)
  renderCtrl(app.ras, app.sl, rb, app.chr)
  renderCtrl(app.ras, app.sl, rb, app.chg)
  renderCtrl(app.ras, app.sl, rb, app.chb)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Gaussian and Stack Blur")

  if app.init(frameWidth, frameHeight, {window_resize}, "blur"):
    return app.run()

  result = 1

discard main()
