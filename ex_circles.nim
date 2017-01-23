import agg_ellipse, agg_basics, random, agg_bspline, math
import agg_gsv_text, agg_renderer_base, agg_rendering_buffer
import agg_scanline_p, agg_pixfmt_rgb, agg_rasterizer_scanline_aa
import agg_renderer_scanline, agg_color_rgba, nimBMP, agg_conv_transform
import agg_trans_affine, agg_gsv_text

const
  frameWidth = 400
  frameHeight = 400
  pixWidth = 3
  
type
  ValueType = uint8
  
const
  num_points = 10000
  
var
  spline_r_x = [ 0.000000, 0.200000, 0.400000, 0.910484, 0.957258, 1.000000 ]
  spline_r_y = [ 1.000000, 0.800000, 0.600000, 0.066667, 0.169697, 0.600000 ]
  spline_g_x = [ 0.000000, 0.292244, 0.485655, 0.564859, 0.795607, 1.000000 ]
  spline_g_y = [ 0.000000, 0.607260, 0.964065, 0.892558, 0.435571, 0.000000 ]
  spline_b_x = [ 0.000000, 0.055045, 0.143034, 0.433082, 0.764859, 1.000000 ]
  spline_b_y = [ 0.385480, 0.128493, 0.021416, 0.271507, 0.713974, 1.000000 ]
  
type
  ScatterPoint* = object
    x, y, z: float64
    color: Rgba

proc random_dbl(start, stop: float64): float64 =
  let r = random(0x7FFF)
  result = float64(r) * (stop - start) / 32768.0 + start

var
  points = newSeq[ScatterPoint](num_points)
  spline_r = initBSpline(6, spline_r_x[0].addr, spline_r_y[0].addr)
  spline_g = initBSpline(6, spline_g_x[0].addr, spline_g_y[0].addr)
  spline_b = initBSpline(6, spline_b_x[0].addr, spline_b_y[0].addr)
  
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
  pf     = initPixFmtRgb24(rbuf)
  rb     = initRendererBase(pf)
  sl     = initScanlineP8()  
  ras    = initRasterizerScanlineAA()
 
proc generate() =
  let 
    rx = frameWidth.float64/3.5
    ry = frameHeight.float64/3.5

  for i in 0.. <num_points:
    let
      z = random_dbl(0.0, 1.0)
      x = cos(z * 2.0 * pi) * rx
      y = sin(z * 2.0 * pi) * ry

      dist  = random_dbl(0.0, rx/2.0)
      angle = random_dbl(0.0, pi * 2.0)

    points[i].z = z
    points[i].x = frameWidth.float64/2.0  + x + cos(angle) * dist
    points[i].y = frameWidth.float64/2.0 + y + sin(angle) * dist
    points[i].color = initRgba(spline_r.get(z)*0.8, spline_g.get(z)*0.8, spline_b.get(z)*0.8, 1.0)

proc onDraw() =
  rb.clear(initRgba(1,1,1))
  var 
    e1: Ellipse
    mtx = transAffineScaling(1.0,1.0)
    t1 = initConvTransform(e1, mtx)
    nDrawn = 0
    scale1 = 0.3
    scale2 = 0.7
    sel = 0.5
    size = 0.5
    
  for i in 0.. <num_points:
    var 
      z = points[i].z
      alpha = 1.0
      
    if z < scale1:
      alpha = 1.0 - (scale1 - z) *  sel * 100.0
  
    if z > scale2:
      alpha = 1.0 - (z - scale2) * sel * 100.0
  
    if alpha > 1.0: alpha = 1.0
    if alpha < 0.0: alpha = 0.0
  
    if alpha > 0.0:
      e1.init(points[i].x, points[i].y, 
              size * 5.0, size * 5.0, 8)
      ras.addPath(t1)
  
      renderScanlinesAASolid(ras, sl, rb,
            initRgba(points[i].color.r, 
                     points[i].color.g,
                     points[i].color.b,
                     alpha))
      inc nDrawn
  
  var 
    buf = $nDrawn
    txt = initGsvText()
  
  txt.size(15.0)
  txt.text(buf)
  txt.startPoint(10.0, frameHeight.float64 - 20.0)
  
  var txt_o = initGsvTextOutline(txt, mtx)
  ras.addPath(txt_o)
  renderScanlinesAASolid(ras, sl, rb, initRgba(0,0,0))
        
  saveBMP24("circles.bmp", buffer, frameWidth, frameHeight)

generate()
onDraw()
  
  