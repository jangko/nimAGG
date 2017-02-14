#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_scanline_u.h"
#include "agg_renderer_scanline.h"
#include "agg_span_allocator.h"
#include "agg_span_gradient.h"
#include "agg_gradient_lut.h"
#include "agg_gamma_lut.h"
#include "agg_span_interpolator_linear.h"
#include "agg_pixfmt_rgb.h"

typedef agg::pixfmt_rgb24 pixfmt;
typedef agg::rgba8 color_type;
typedef agg::order_rgb component_order;
typedef agg::renderer_base<pixfmt> renderer_base;
typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_solid;
typedef agg::gamma_lut<agg::int8u, agg::int8u> gamma_lut_type;
typedef agg::gradient_radial_focus gradient_func_type;
typedef agg::gradient_reflect_adaptor<gradient_func_type> gradient_adaptor_type;
typedef agg::gradient_lut<agg::color_interpolator<agg::rgba8>, 1024> color_func_type;
typedef agg::span_interpolator_linear<> interpolator_type;
typedef agg::span_allocator<color_type> span_allocator_type;
typedef agg::span_gradient<color_type, 
                           interpolator_type, 
                           gradient_adaptor_type, 
                           color_func_type> span_gradient_type;
                           
const int frameWidth = 600;
const int frameHeight = 400;     
                   
extern "C" {
    
color_func_type                 m_gradient_lut;
gamma_lut_type                  m_gamma_lut;

void test_gradient() {
  m_gamma_lut.gamma(1.8);
  
  m_gradient_lut.remove_all();
  m_gradient_lut.add_color(0.0, agg::rgba8_gamma_dir(agg::rgba8(0, 255, 0),   m_gamma_lut));
  m_gradient_lut.add_color(0.2, agg::rgba8_gamma_dir(agg::rgba8(120, 0, 0),   m_gamma_lut));
  m_gradient_lut.add_color(0.7, agg::rgba8_gamma_dir(agg::rgba8(120, 120, 0), m_gamma_lut));
  m_gradient_lut.add_color(1.0, agg::rgba8_gamma_dir(agg::rgba8(0, 0, 255),   m_gamma_lut));
  m_gradient_lut.build_lut();  
}

void get_gradient(int i, agg::rgba8& c) {
  c = m_gradient_lut[i];
}

void print_gradient() {
  for(int i = 0; i < m_gradient_lut.size(); i++) {
    agg::rgba8 c = m_gradient_lut[i];
    printf("(r: %d, g: %d, b: %d, a: %d)\n", c.r, c.g, c.b, c.a);
  }
}

unsigned char* main_gradient() {
  typedef agg::renderer_base<agg::pixfmt_rgb24> ren_base;
  typedef agg::span_allocator<agg::rgba8> span_allocator_type;
  typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_solid;
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, frameWidth, frameHeight, frameWidth * 3);
  agg::pixfmt_rgb24 pixf(rbuf);
  ren_base rb(pixf);
  agg::rasterizer_scanline_aa<> ras;
  agg::scanline_u8 sl;
  span_allocator_type alloc;
  renderer_solid rs(rb);
  rb.clear(agg::rgba(1, 1, 1));
  double mGamma = 1.8;
  double initialWidth = double(frameWidth);
  double initialHeight = double(frameHeight);
  double mouseX = initialWidth / 2.0;
  double mouseY = initialHeight / 2.0;
  double height = initialHeight;
  double width  = initialWidth;
  
  double cx = initialWidth  / 2.0;
  double cy = initialHeight / 2.0;
  double r = 100;

  double fx = mouseX - cx;
  double fy = mouseY - cy;
  
  gradient_func_type    gradient_func(r, fx, fy);
  gradient_adaptor_type gradient_adaptor(gradient_func);
  agg::trans_affine     gradient_mtx;
  
  gradient_mtx.translate(cx, cy);
  //gradient_mtx *= trans_affine_resizing();
  gradient_mtx.invert();

  interpolator_type     span_interpolator(gradient_mtx);
  span_gradient_type    span_gradient(span_interpolator, gradient_adaptor, m_gradient_lut, 0, r);
  ras.reset();
  ras.move_to_d(0,0);
  ras.line_to_d(width, 0);
  ras.line_to_d(width, height);
  ras.line_to_d(0, height);
  agg::render_scanlines_aa(ras, sl, rb, alloc, span_gradient);  
  return buffer;
}
}