import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_conv_stroke
import agg_renderer_base, nimBMP, agg_path_storage, agg_pixfmt_rgb, agg_color_rgba
import agg_scanline_p, agg_renderer_scanline

import polyBool/polyBool

const
  frameWidth = 600
  frameHeight = 400
  pixWidth = 3
  flipY = true

type
  ValueT = uint8
  
proc polygonToPath(path: var PathStorage, poly: Polygon) =
  path.removeAll()
  for r in poly.regions:
    for i in 0.. <r.len:
      if i == 0: 
        path.moveTo(r[i].x, r[i].y)
      else:
        path.lineTo(r[i].x, r[i].y)
    path.closePolygon()
    
proc onDraw() =
  var
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    #ren   = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()
    poly1  = initPolygon(false)
    poly2  = initPolygon(false)
    
  rb.clear(initRgba(1,1,1))
  
  poly1.addRegion()  
  poly1.addVertex(50.0, 50.0)
  poly1.addVertex(150.0, 150.0)
  poly1.addVertex(190.0, 50.0)
  
  poly1.addRegion()  
  poly1.addVertex(130.0, 50.0)
  poly1.addVertex(290.0, 150.0)
  poly1.addVertex(290.0, 50.0)
  
  poly2.addRegion()  
  poly2.addVertex(110.0, 20.0)
  poly2.addVertex(110.0, 110.0)
  poly2.addVertex(20.0, 20.0)
  
  poly2.addRegion()  
  poly2.addVertex(130.0, 170.0)
  poly2.addVertex(130.0, 20.0)
  poly2.addVertex(260.0, 20.0) 
  poly2.addVertex(260.0, 170.0) 
  
  var stroke = initConvStroke(path)
  stroke.width(1.5)
  
  polygonToPath(path, poly1)
  ras.addPath(stroke)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(1.0, 0.1, 0.1))
  
  polygonToPath(path, poly2)
  ras.addPath(stroke)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.1, 0.1, 1.0))
  
  var 
    pb = initPolyBool()
    isect = pb.clipIntersect(poly1, poly2)
  
  polygonToPath(path, isect)
  ras.addPath(path)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0.1, 1.0, 0.1))
  
  saveBMP24("test_poly_bool.bmp", buffer, frameWidth, frameHeight)

onDraw()