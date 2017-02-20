import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_conv_clip_polygon
import agg_bounding_rect, agg_ellipse, agg_trans_bilinear, agg_trans_perspective
import agg_color_rgba, agg_renderer_base, agg_pixfmt_rgb, agg_conv_stroke
import parse_lion, nimBMP

const
  frameWidth = 600
  frameHeight = 600
  pixWidth = 3

type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    lion   = parseLion(frameWidth, frameHeight)
        
  var 
    quad = [lion.x1, lion.y1, lion.x2, lion.y1, lion.x2, lion.y2, lion.x1, lion.y2]
    dx = frameWidth.float64  / 2.0 - (quad[1 * 2 + 0] - quad[0 * 2 + 0]) / 2.0
    dy = frameHeight.float64 / 2.0 - (quad[2 * 2 + 1] - quad[0 * 2 + 1]) / 2.0
    
  quad[0 * 2 + 0] += dx
  quad[0 * 2 + 1] += dy
  quad[1 * 2 + 0] += dx
  quad[1 * 2 + 1] += dy - 100
  quad[2 * 2 + 0] += dx
  quad[2 * 2 + 1] += dy
  quad[3 * 2 + 0] += dx
  quad[3 * 2 + 1] += dy
        
  block Bilinear:
    rb.clear(initrgba(1, 1, 1))
    var tr = initTransBilinear(lion.x1, lion.y1, lion.x2, lion.y2, quad)
      
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
                  
    saveBMP24("bilinear.bmp", buffer, frameWidth, frameHeight)

  block Perspective:
    rb.clear(initrgba(1, 1, 1))
    var tr = initTransPerspective(lion.x1, lion.y1, lion.x2, lion.y2, quad)
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
                  
    saveBMP24("perspective.bmp", buffer, frameWidth, frameHeight)
                
onDraw()