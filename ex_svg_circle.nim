import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_scanline_p, agg_renderer_scanline, agg_span_allocator, agg_color_gray
import agg_span_gouraud_gray, agg_span_solid, agg_math, agg_dda_line, agg_pixfmt_gray
import agg_renderer_base, agg_gamma_functions, agg_span_gouraud_rgba
import agg_renderer_scanline, nimBMP, agg_color_rgba, agg_pixfmt_rgb
import agg_color_conv, agg_color_conv_rgb8, math, agg_conv_clip_polygon, make_arrows
import agg_path_storage, agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_bounding_rect, agg_conv_unclose_polygon, agg_conv_close_polygon
import agg_conv_shorten_path, agg_conv_clip_polyline, agg_conv_smooth_poly1

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3

type
  ValueT = uint8
  
{.passC: "-I./agg-2.5/include".}
{.compile: "test_arc.cpp".}
{.compile: "agg_bezier_arc2.cpp".}
{.compile: "agg_vcgen_stroke2.cpp".}
{.compile: "agg_trans_affine2.cpp".}
{.passL: "-lstdc++".}
    
proc test_arc(buf: cstring, w, h, px: cint) {.importc.}

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    buf2   = newString(frameWidth * frameHeight * pixWidth)

  test_arc(buf2, frameWidth, frameHeight, pixWidth)
  
  rb.clear(initRgba(1,1,1))

  var
    ren   = initRendererScanlineAASolid(rb)
    mx = frameWidth.float64 / 2.0
    my = frameHeight.float64 / 2.0
    arc = initPathStorage()
    curve = initConvCurve(arc)
    arcs= initConvStroke(curve)

  arc.moveTo(127.89327, 90.999997)
  arc.arcTo(40.893275, 40.893275, 0, false, true, 46.106725, 90.999997)
  arc.arcTo(40.893275, 40.893275, 0, true, true, 127.89327, 90.999997)
    
  arcs.width(2)
  ras.reset()
  ras.addPath(arcs)
  ren.color(initRgba(0.9, 0.5, 0.5))
  renderScanlines(ras, sl, ren)
  
  saveBMP24("svg_circle.bmp", buffer, frameWidth, frameHeight)

onDraw()