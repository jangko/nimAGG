#include <string.h>
#include "agg_basics.h"
#include "agg_pixfmt_rgb.h"
#include "agg_gamma_lut.h"
#include "agg_rounded_rect.h"
#include "agg_conv_stroke.h"
#include "agg_rasterizer_scanline_aa.h"

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8> gamma_lut_type;
typedef agg::blender_rgb_gamma<agg::rgba8, agg::order_rgb, gamma_lut_type> blender_type;


extern "C" {

void test_gamma() {
  double m_x[2];
  double m_y[2];
  
  m_x[0] = 100;   m_y[0] = 100;
  m_x[1] = 500;   m_y[1] = 350;
        
  agg::int8u buf[100];
  memset(buf, 255, 100);
  gamma_lut_type gamma(1.8);
  blender_type blend(gamma);
  
  double d = 1.25;
  double m_radius = 25.0;
  agg::rounded_rect r(m_x[0]+d, m_y[0]+d, m_x[1]+d, m_y[1]+d, m_radius);
  r.normalize_radius();
        
  agg::rasterizer_scanline_aa<> ras;
  agg::conv_stroke<agg::rounded_rect> p(r);
  p.width(1.0);
  ras.add_path(p);
}


}