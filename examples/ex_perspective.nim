import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, path_storage, conv_transform,
  bounding_rect, ellipse, trans_bilinear, trans_perspective,
  color_rgba, renderer_base, pixfmt_rgb, conv_stroke]
import parse_lion, ctrl.polygon, ctrl.rbox, platform.support

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    transType: RboxCtrl[Rgba8]
    quad: PolygonCtrl[Rgba8]
    lion: Lion

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](420, 5.0, 420+130.0, 55.0, not flipY)

  result.addCtrl(result.quad)
  result.addCtrl(result.transType)

  result.lion   = parseLion(frameWidth, frameHeight)
  result.quad.xn(0) = result.lion.x1
  result.quad.yn(0) = result.lion.y1
  result.quad.xn(1) = result.lion.x2
  result.quad.yn(1) = result.lion.y1
  result.quad.xn(2) = result.lion.x2
  result.quad.yn(2) = result.lion.y2
  result.quad.xn(3) = result.lion.x1
  result.quad.yn(3) = result.lion.y2
  result.transType.addItem("Bilinear")
  result.transType.addItem("Perspective")
  result.transType.curItem(0)

method onInit(app: App) =
  var
    dx = app.width() / 2.0 - (app.quad.xn(1) - app.quad.xn(0)) / 2.0
    dy = app.height()/ 2.0 - (app.quad.yn(2) - app.quad.yn(0)) / 2.0

  app.quad.xn(0) += dx
  app.quad.yn(0) += dy
  app.quad.xn(1) += dx
  app.quad.yn(1) += dy
  app.quad.xn(2) += dx
  app.quad.yn(2) += dy
  app.quad.xn(3) += dx
  app.quad.yn(3) += dy

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    width  = app.width()
    height = app.height()

  rb.clear(initrgba(1, 1, 1))
  ras.clipBox(0, 0, width, height)

  if app.transType.curItem() == 0:
    var tr = initTransBilinear(app.lion.x1, app.lion.y1, app.lion.x2, app.lion.y2, app.quad.polygon())

    if tr.isValid():
      # Render transformed lion
      var trans = initConvTransform(app.lion.path, tr)
      renderAllPaths(ras, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

      # Render transformed ellipse
      var
        ell = initEllipse((app.lion.x1 + app.lion.x2) * 0.5, (app.lion.y1 + app.lion.y2) * 0.5,
                          (app.lion.x2 - app.lion.x1) * 0.5, (app.lion.y2 - app.lion.y1) * 0.5, 200)
        ellStroke = initConvStroke(ell)
        transEll = initConvTransform(ell, tr)
        transEllStroke = initConvTransform(ellStroke, tr)

      ellStroke.width(3.0)
      ras.addPath(transEll)
      ren.color(initRgba(0.5, 0.3, 0.0, 0.3))
      renderScanlines(ras, sl, ren)

      ras.addPath(transEllStroke)
      ren.color(initRgba(0.0, 0.3, 0.2, 1.0))
      renderScanlines(ras, sl, ren)

  else:
    var tr = initTransPerspective(app.lion.x1, app.lion.y1, app.lion.x2, app.lion.y2, app.quad.polygon())
    if tr.isValid():
      # Render transformed lion
      var trans = initConvTransform(app.lion.path, tr)
      renderAllPaths(ras, sl, ren, trans, app.lion.colors, app.lion.pathIdx, app.lion.numPaths)

      # Render transformed ellipse
      var
        ell = initEllipse((app.lion.x1 + app.lion.x2) * 0.5, (app.lion.y1 + app.lion.y2) * 0.5,
                          (app.lion.x2 - app.lion.x1) * 0.5, (app.lion.y2 - app.lion.y1) * 0.5, 200)
        ellStroke = initConvStroke(ell)
        transEll  = initConvTransform(ell, tr)
        transEllStroke = initConvTransform(ellStroke, tr)

      ellStroke.width(3.0)
      ras.addPath(transEll)
      ren.color(initRgba(0.5, 0.3, 0.0, 0.3))
      renderScanlines(ras, sl, ren)

      ras.addPath(transEllStroke)
      ren.color(initRgba(0.0, 0.3, 0.2, 1.0))
      renderScanlines(ras, sl, ren)

  # Render the "quad" tool and controls
  ras.addPath(app.quad)
  ren.color(initRgba(0, 0.3, 0.5, 0.6))
  renderScanlines(ras, sl, ren)
  renderCtrl(ras, sl, rb, app.transType)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Perspective Transformations")

  if app.init(frameWidth, frameHeight, {window_resize}, "perspective"):
    return app.run()

  result = 1

discard main()
