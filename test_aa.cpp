#include "agg_basics.h"
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_scanline_u.h"
#include "agg_renderer_scanline.h"
#include "agg_pixfmt_rgb.h"
#include "agg_color_rgba.h"
#include "agg_gamma_functions.h"
#include "agg_renderer_base.h"
#include "agg_path_storage.h"
#include "agg_conv_stroke.h"
#include <stdio.h>

extern "C" {
const int frameWidth = 600;
const int frameHeight = 400;

unsigned char* test_aa() {
  typedef agg::renderer_base<agg::pixfmt_bgr24> ren_base;
  
  double m_x[3];
  double m_y[3];
  double m_dx;
  double m_dy;
  int    m_idx;
    
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               frameWidth * 3);
                               
  m_idx = -1;
  m_x[0] = 57;    m_y[0] = 100;
  m_x[1] = 369;   m_y[1] = 170;
  m_x[2] = 143;   m_y[2] = 310;
  
  agg::pixfmt_bgr24 pixf(rbuf);
  ren_base ren(pixf);
  agg::scanline_u8 sl;
  ren.clear(agg::rgba(1,1,1));
  agg::rasterizer_scanline_aa<> ras;
  
  ras.reset();
  ras.gamma(agg::gamma_none());

  agg::path_storage ps;
  agg::conv_stroke<agg::path_storage> pg(ps);
  pg.width(5.0);

  ps.remove_all();
  ps.move_to(m_x[0], m_y[0]);
  ps.line_to(m_x[1], m_y[1]);
  ras.add_path(pg);
  agg::render_scanlines_aa_solid(ras, sl, ren, agg::rgba8(0,150,160, 200));
  return buffer;
}

}