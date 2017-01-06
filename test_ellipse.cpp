#include "agg_basics.h"
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_scanline_p.h"
#include "agg_renderer_scanline.h"
#include "agg_ellipse.h"
#include "agg_pixfmt_gray.h"
#include "agg_pixfmt_rgb.h"
#include <stdio.h>

typedef agg::pixfmt_alpha_blend_gray<agg::blender_gray8, agg::rendering_buffer, 3, 2> pixfmt_gray8_bgr24r;
//typedef agg::pixfmt_alpha_blend_gray<agg::blender_gray8, agg::rendering_buffer, 3, 1> pixfmt_gray8_bgr24g;
//typedef agg::pixfmt_alpha_blend_gray<agg::blender_gray8, agg::rendering_buffer, 3, 0> pixfmt_gray8_bgr24b;
        
extern "C" {
const int frameHeight = 320;
const int frameWidth = 320;

void test_ellipse() {
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               frameWidth * 3);
                               
  agg::rasterizer_scanline_aa<> ras;
  agg::scanline_p8 sl;
  
  pixfmt_gray8_bgr24r pfr(rbuf);
  //pixfmt_gray8_bgr24g pfg(rbuf_window());
  //pixfmt_gray8_bgr24b pfb(rbuf_window());

  //agg::renderer_base<agg::pixfmt_bgr24>   rbase(pf);
  agg::renderer_base<pixfmt_gray8_bgr24r> rbr(pfr);
  //agg::renderer_base<pixfmt_gray8_bgr24g> rbg(pfg);
  //agg::renderer_base<pixfmt_gray8_bgr24b> rbb(pfb);
        
  agg::ellipse er(frameWidth / 2 - 0.87*50, frameHeight / 2 - 0.5*50, 100, 100, 100);
  ras.add_path(er);
  ras.sort();
  
  //printf("%d %d %d %d\n", ras.min_x(), ras.min_y(), ras.max_x(), ras.max_y());
  //ras.inspect(sl);
  
  agg::render_scanlines_aa_solid(ras, sl, rbr, agg::gray8(0, 255));
}

}