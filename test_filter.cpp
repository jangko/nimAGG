#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_ellipse.h"
#include "agg_trans_affine.h"
#include "agg_conv_transform.h"
#include "agg_conv_stroke.h"
#include "agg_pixfmt_rgb.h"
#include "agg_scanline_p.h"
#include "agg_renderer_scanline.h"
#include "agg_image_filters.h"
#include "agg_path_storage.h"

extern "C" {
  
const int frameWidth = 780;
const int frameHeight = 300;
const int pixWidth = 3;

void test_filter() {
  typedef agg::pixfmt_bgr24 pixfmt; 
  typedef agg::renderer_base<pixfmt> renderer_base;
  typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_solid;
  typedef agg::rendering_buffer rendering_buffer;
  
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               frameWidth * 3);
  
  pixfmt pixf(rbuf);
  renderer_base rb(pixf);
  renderer_solid rs(rb);
  
  rb.clear(agg::rgba(1.0, 1.0, 1.0));
  agg::rasterizer_scanline_aa<> ras;
  agg::scanline_p8 sl;
  
  double initial_width = double(frameWidth);
  double initial_height = double(frameHeight);
  
  double x_start = 125.0;
  double x_end   = initial_width - 15.0;
  double y_start = 10.0;
  double y_end   = initial_height - 10.0;
  double x_center = (x_start + x_end) / 2;
  
  unsigned i;
  
  agg::path_storage p;
  agg::conv_stroke<agg::path_storage> pl(p);
  agg::conv_transform<agg::conv_stroke<agg::path_storage> > tr(pl, agg::trans_affine());
  
  for(i = 0; i <= 16; i++)
  {
      double x = x_start + (x_end - x_start) * i / 16.0;
      p.remove_all();
      p.move_to(x+0.5, y_start);
      p.line_to(x+0.5, y_end);
      ras.add_path(tr);
      rs.color(agg::rgba8(0, 0, 0, i == 8 ? 255 : 100));
      agg::render_scanlines(ras, sl, rs);
  }
}

}