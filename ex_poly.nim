import agg_basics, agg_path_storage, agg_renderer_base, agg_rendering_buffer
import agg_platform_support, agg_pixfmt_rgb, agg_scanline_p, streams
import agg_rasterizer_scanline_aa, agg_renderer_scanline, agg_conv_curve
import agg_color_rgba, agg_conv_stroke, os

const
  frameWidth = 640
  frameHeight = 480
  flipY = true

type
  PixFmt = PixFmtBgr24
  
  App = ref object of PlatformSupport
    path: PathStorage
    id: array[10, int]
    numId: int

proc loadBin(ps: var PathStorage, fn: string) =
  var s = newFileStream("resources" & DirSep & fn)
  let numPoly = s.readInt32()
  var v: PointF
  
  for i in 0.. <numPoly:
    let numPoints = s.readInt32()
    for j in 0.. <numPoints:
      discard s.readData(v.addr, sizeof(v))
      if j == 0:
        ps.moveTo(v.x, v.y)
      else:
        ps.lineTo(v.x, v.y)
    ps.closePolygon()
    
  s.close()
  
proc loadPoly(app: App) =
  app.numId = 0
  app.id[app.numId] = app.path.startNewPath()
  app.path.loadBin("AUSTRALIA.bin")
  inc app.numId
 
  app.numId = 0
  app.id[app.numId] = app.path.startNewPath()
  app.path.loadBin("CLIP.bin")
  inc app.numId

  app.numId = 0
  app.id[app.numId] = app.path.startNewPath()
  app.path.loadBin("POLYGON.bin")
  inc app.numId

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)
  
  result.path = initPathStorage()
  result.loadPoly()
  
method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    ren    = initRendererScanlineAASolid(rb)
    curve  = initConvStroke(app.path)
    
  rb.clear(initRgba(1,1,1))
  
  ras.addPath(curve)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Australia")

  if app.init(frameWidth, frameHeight, {}, "poly"):
    return app.run()

  result = 1

discard main()
