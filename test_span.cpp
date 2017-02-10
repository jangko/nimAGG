#include "agg_basics.h"
#include "agg_pixfmt_rgb.h"
#include "agg_color_rgba.h"
#include "agg_renderer_base.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_rendering_buffer.h"
#include "agg_scanline_u.h"
#include "agg_trans_affine.h"
#include "agg_span_interpolator_linear.h"
#include "agg_span_allocator.h"
#include "agg_image_accessors.h"
#include "agg_span_image_filter_rgb.h"
#include "agg_renderer_scanline.h"

extern "C" {
  
const int frameWidth = 500;
const int frameHeight = 340;
const int pixWidth = 3;

enum { V = 255 };

static agg::int8u image[] = {
  0,V,0, 0,0,V, V,V,V, V,0,0,
  V,0,0, 0,0,0, V,V,V, V,V,V,
  V,V,V, V,V,V, 0,0,V, V,0,0,
  0,0,V, V,V,V, 0,0,0, 0,V,0};
           
unsigned char* test_span() {
  typedef agg::pixfmt_rgb24 pixfmt; 
  typedef agg::renderer_base<pixfmt> renderer_base;
  typedef agg::rendering_buffer rendering_buffer;
  
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               -frameWidth * 3);
  
  pixfmt pf(rbuf);
  renderer_base rb(pf);

  agg::rasterizer_scanline_aa<> ras;
  agg::scanline_u8 sl;
  
  agg::rendering_buffer img(image, 4, 4, 4*3);
  double para[] = {200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0};
  
  agg::trans_affine mtx(para, 0, 0, 4, 4);
  
  typedef agg::span_interpolator_linear<> interpolator_type;
  interpolator_type inter(mtx); 
  agg::span_allocator<agg::rgba8> sa;
        
  pixfmt pixf(img);
  typedef agg::image_accessor_clone<pixfmt> img_source_type;
  img_source_type source(pixf);
        
  typedef agg::span_image_filter_rgb_nn<img_source_type, interpolator_type> span_gen_nn;
  typedef agg::span_image_filter_rgb_bilinear<img_source_type, interpolator_type> span_gen_bilinear;
  typedef agg::span_image_filter_rgb_bilinear_clip<pixfmt, interpolator_type> span_gen_bilinear_clip;
  typedef agg::span_image_filter_rgb_2x2<img_source_type, interpolator_type> span_gen_2x2;
  typedef agg::span_image_filter_rgb<img_source_type, interpolator_type> span_gen_rgb;
  typedef agg::span_image_resample_rgb_affine<img_source_type> span_gen_resample_affine;
  
  agg::image_filter<agg::image_filter_kaiser> filter;
  
  //span_gen_nn sg(source, inter);
  //span_gen_bilinear sg(source, inter);
  //span_gen_bilinear_clip sg(pixf, agg::rgba8(1,1,1), inter);
  //span_gen_2x2 sg(source, inter, filter);
  //span_gen_rgb sg(source, inter, filter);
  span_gen_resample_affine sg(source, inter, filter);
  
  ras.reset();
  ras.move_to_d(para[0], para[1]);
  ras.line_to_d(para[2], para[3]);
  ras.line_to_d(para[4], para[5]);
  ras.line_to_d(para[6], para[7]);
  rb.clear(agg::rgba(1, 1, 1));
  
  agg::render_scanlines_aa(ras, sl, rb, sa, sg);
  return buffer;
}

void free_buffer(unsigned char* b) {
  delete [] b;
}

}