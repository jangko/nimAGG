#include <math.h>
#include <stdio.h>
#include "agg_basics.h"
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_scanline_p.h"
#include "agg_renderer_scanline.h"
#include "agg_pixfmt_rgba.h"
#include "agg_path_storage.h"

const int frameWidth = 400;
const int frameHeight = 330;
const int pixWidth = 4;

typedef agg::pixfmt_rgba32 pixfmt;
typedef agg::renderer_base<pixfmt> renderer_base;
typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_scanline;
typedef agg::rasterizer_scanline_aa<> rasterizer_scanline;
typedef agg::scanline_p8 scanline;

extern "C" {

unsigned char* test_poly() {
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * pixWidth];
  memset(buffer, 255, frameWidth * frameHeight * pixWidth);
  agg::rendering_buffer rbuf(buffer, frameWidth, frameHeight, -frameWidth * pixWidth);
  double mx[] = {100.0, 369.0, 143.0};
  double my[] = {60.0, 170.0, 310.0};
  agg::path_storage path;
  path.move_to(mx[0], my[0]);
  path.line_to(mx[1], my[1]);
  path.line_to(mx[2], my[2]);
  path.close_polygon();
  
  pixfmt pixf(rbuf);
  renderer_base rb(pixf);
  renderer_scanline ren(rb);
  rasterizer_scanline ras;
  scanline sl;
    
  rb.clear(agg::rgba8(255, 255, 255));
  ren.color(agg::rgba8(80, 30, 20, 255));
  ras.add_path(path);
  agg::render_scanlines(ras, sl, ren);
            
  return buffer;
}

}