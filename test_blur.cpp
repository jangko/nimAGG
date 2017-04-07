#include "agg_basics.h"
#include "agg_pixfmt_rgb.h"
#include "agg_blur.h"
#include "agg_rendering_buffer.h"

extern "C" {

void test_blur(unsigned char* buf, int w, int h, int px, agg::rect_d& bb) {
  agg::rendering_buffer rbuf(buf, w, h, w * px);
  agg::pixfmt_rgb24 pixf(rbuf);

  agg::rendering_buffer rbuf2;
  agg::pixfmt_rgb24 pixf2(rbuf2);
  agg::recursive_blur<agg::rgba8, agg::recursive_blur_calc_rgb<> > recursive_blur;

  if(pixf2.attach(pixf, bb.x1, bb.y1, bb.x2, bb.y2)) {
    recursive_blur.blur(pixf2, 15.0);
  }
}

}
