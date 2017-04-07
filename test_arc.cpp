#include "agg_basics.h"
#include "agg_pixfmt_rgb.h"
#include "agg_rendering_buffer.h"
#include "agg_scanline_p.h"
#include "agg_renderer_base.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_renderer_scanline.h"
#include "agg_path_storage.h"
#include "agg_conv_stroke.h"

extern "C" {

typedef agg::renderer_base<agg::pixfmt_rgb24> ren_base;

void test_arc(unsigned char* buf, int w, int h, int px) {
  agg::rendering_buffer rbuf(buf, w, h, w * px);
  agg::pixfmt_rgb24 pixf(rbuf);
  ren_base rb(pixf);
  agg::scanline_p8 sl;
  agg::rasterizer_scanline_aa<> ras;
  agg::renderer_scanline_aa_solid<ren_base> ren(rb);
  
  rb.clear(agg::rgba(1,1,1));
  double mx = w / 2.0;
  double my = w / 2.0;
  
  agg::path_storage arc;
  agg::conv_stroke<agg::path_storage> arcs(arc);

  arc.move_to(127.89327, 90.999997);
  arc.arc_to(40.893275, 40.893275, 0, false, true, 46.106725, 90.999997);
  arc.arc_to(40.893275, 40.893275, 0, true, true, 127.89327, 90.999997);
  
  arcs.width(2);
  ras.reset();
  ras.add_path(arcs);
  ren.color(agg::rgba(0.9, 0.5, 0.5));
  render_scanlines(ras, sl, ren);
}

}
