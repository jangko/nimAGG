import agg/[basics, rendering_buffer, rasterizer_scanline_aa, conv_stroke,
  renderer_base, path_storage, pixfmt_rgb, color_rgba, scanline_p, renderer_scanline]
import platform/support, polyBool/polyBool

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

proc polygonToPath(path: var PathStorage, poly: Polygon) =
  path.removeAll()
  for r in poly.regions:
    for i in 0..<r.len:
      if i == 0:
        path.moveTo(r[i].x, r[i].y)
      else:
        path.lineTo(r[i].x, r[i].y)
    path.closePolygon()

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()
    poly1  = initPolygon(false)
    poly2  = initPolygon(false)

  rb.clear(initRgba(1,1,1))

  poly1.addRegion()
  poly1.addVertex(500.0, 60.0)
  poly1.addVertex(500.0, 150.0)
  poly1.addVertex(200.0, 150.0)
  poly1.addVertex(200.0, 60.0)

  poly2.addRegion()
  poly2.addVertex(500.0, 60.0)
  poly2.addVertex(500.0, 150.0)
  poly2.addVertex(450.0, 230.0)
  poly2.addVertex(400.0, 180.0)
  poly2.addVertex(590.0, 60.0)

  #poly1.addRegion()
  #poly1.addVertex(50.0, 50.0)
  #poly1.addVertex(150.0, 150.0)
  #poly1.addVertex(190.0, 50.0)
  #
  #poly1.addRegion()
  #poly1.addVertex(130.0, 50.0)
  #poly1.addVertex(290.0, 150.0)
  #poly1.addVertex(290.0, 50.0)
  #
  #poly2.addRegion()
  #poly2.addVertex(110.0, 20.0)
  #poly2.addVertex(110.0, 110.0)
  #poly2.addVertex(20.0, 20.0)
  #
  #poly2.addRegion()
  #poly2.addVertex(130.0, 170.0)
  #poly2.addVertex(130.0, 20.0)
  #poly2.addVertex(260.0, 20.0)
  #poly2.addVertex(260.0, 170.0)

  var stroke = initConvStroke(path)
  stroke.width(3)

  #polygonToPath(path, poly1)
  #ras.addPath(stroke)
  #renderScanlinesAAsolid(ras, sl, rb, initRgba(1.0, 0.1, 0.1))
  #
  #polygonToPath(path, poly2)
  #ras.addPath(stroke)
  #renderScanlinesAAsolid(ras, sl, rb, initRgba(0.1, 0.1, 1.0))

  var
    pb = initPolyBool()
    isect = pb.clipXor(poly1, poly2)

  polygonToPath(path, isect)
  ras.addPath(path)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.1, 1.0, 0.1))

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. polyBool")

  if app.init(frameWidth, frameHeight, {}, "test_poly_bool"):
    return app.run()

  result = 1

discard main()
