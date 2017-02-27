import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_path_storage, agg_conv_transform
import agg_bounding_rect, agg_ellipse, agg_trans_bilinear, agg_trans_perspective
import agg_color_rgba, agg_renderer_base, agg_pixfmt_rgb, agg_conv_stroke
import parse_lion, nimBMP, ctrl_polygon, ctrl_rbox

const
  frameWidth = 600
  frameHeight = 600
  pixWidth = 3
  flipY = true
  
type
  ValueT = uint8
  
type
  App = object
    transType: RboxCtrl[Rgba8]
    quad: PolygonCtrl[Rgba8]
    
proc initApp(lion: Lion): App =    
  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](420, 5.0, 420+130.0, 55.0, not flipY)
  result.quad.xn(0) = lion.x1
  result.quad.yn(0) = lion.y1
  result.quad.xn(1) = lion.x2
  result.quad.yn(1) = lion.y1
  result.quad.xn(2) = lion.x2
  result.quad.yn(2) = lion.y2
  result.quad.xn(3) = lion.x1
  result.quad.yn(3) = lion.y2
  result.transType.addItem("Bilinear")
  result.transType.addItem("Perspective")
  result.transType.curItem(0)

proc onDraw() =
  var
    lion   = parseLion(frameWidth, frameHeight)
    app    = initApp(lion)
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    width  = frameWidth.float64
    height = frameHeight.float64
    dx = width / 2.0 - (app.quad.xn(1) - app.quad.xn(0)) / 2.0
    dy = height/ 2.0 - (app.quad.yn(2) - app.quad.yn(0)) / 2.0
    
  app.quad.xn(0) += dx
  app.quad.yn(0) += dy
  app.quad.xn(1) += dx
  app.quad.yn(1) += dy
  app.quad.xn(2) += dx
  app.quad.yn(2) += dy
  app.quad.xn(3) += dx
  app.quad.yn(3) += dy
  
  rb.clear(initrgba(1, 1, 1))
  ras.clipBox(0, 0, width, height)
  
  if app.transType.curItem() == 0:
    var tr = initTransBilinear(lion.x1, lion.y1, lion.x2, lion.y2, app.quad.polygon())
      
    if tr.isValid():
      # Render transformed lion
      var trans = initConvTransform(lion.path, tr)
      renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)
                  
      # Render transformed ellipse
      var 
        ell = initEllipse((lion.x1 + lion.x2) * 0.5, (lion.y1 + lion.y2) * 0.5, 
                          (lion.x2 - lion.x1) * 0.5, (lion.y2 - lion.y1) * 0.5, 200)
        ell_stroke = initConvStroke(ell)
        trans_ell = initConvTransform(ell, tr)
        trans_ell_stroke = initConvTransform(ell_stroke, tr)
      
      ell_stroke.width(3.0)
      ras.addPath(trans_ell)
      ren.color(initRgba(0.5, 0.3, 0.0, 0.3))
      renderScanlines(ras, sl, ren)
  
      ras.addPath(trans_ell_stroke)
      ren.color(initRgba(0.0, 0.3, 0.2, 1.0))
      renderScanlines(ras, sl, ren)

  else:
    var tr = initTransPerspective(lion.x1, lion.y1, lion.x2, lion.y2, app.quad.polygon())
    if tr.isValid():
      # Render transformed lion
      var trans = initConvTransform(lion.path, tr)
      renderAllPaths(ras, sl, ren, trans, lion.colors, lion.pathIdx, lion.numPaths)
    
      # Render transformed ellipse
      var 
        ell = initEllipse((lion.x1 + lion.x2) * 0.5, (lion.y1 + lion.y2) * 0.5, 
                          (lion.x2 - lion.x1) * 0.5, (lion.y2 - lion.y1) * 0.5, 200)
        ell_stroke = initConvStroke(ell)
        trans_ell = initConvTransform(ell, tr)
        trans_ell_stroke = initConvTransform(ell_stroke, tr)
      
      ell_stroke.width(3.0)
      ras.addPath(trans_ell)
      ren.color(initRgba(0.5, 0.3, 0.0, 0.3))
      renderScanlines(ras, sl, ren)
  
      ras.addPath(trans_ell_stroke)
      ren.color(initRgba(0.0, 0.3, 0.2, 1.0))
      renderScanlines(ras, sl, ren)
  
  # Render the "quad" tool and controls
  ras.addPath(app.quad)
  ren.color(initRgba(0, 0.3, 0.5, 0.6))
  renderScanlines(ras, sl, ren)
  renderCtrl(ras, sl, rb, app.transType)
        
  saveBMP24("perspective.bmp", buffer, frameWidth, frameHeight)
                
onDraw()