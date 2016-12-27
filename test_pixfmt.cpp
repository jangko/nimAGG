#include <agg_pixfmt_rgb.h>
#include <agg_color_rgba.h>
#include <agg_gamma_lut.h>

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8> GammaLUT8; 
typedef agg::gamma_lut<agg::int16u, agg::int16u, 16, 16> GammaLUT16; 

extern "C" {

agg::rendering_buffer* create_rbuf(unsigned char* buffer, int frame_width, int frame_height) {
  return new agg::rendering_buffer(buffer, frame_width, frame_height, frame_width * 3);
}

agg::pixfmt_rgb24* create_pixfmt_rgb24(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb24(*rbuf);
}

agg::pixfmt_bgr24* create_pixfmt_bgr24(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr24(*rbuf);
}

agg::pixfmt_rgb48* create_pixfmt_rgb48(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb48(*rbuf);
}

agg::pixfmt_bgr48* create_pixfmt_bgr48(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr48(*rbuf);
}

agg::pixfmt_rgb24_pre* create_pixfmt_rgb24_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb24_pre(*rbuf);
}

agg::pixfmt_bgr24_pre* create_pixfmt_bgr24_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr24_pre(*rbuf);
}

agg::pixfmt_rgb48_pre* create_pixfmt_rgb48_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb48_pre(*rbuf);
}

agg::pixfmt_bgr48_pre* create_pixfmt_bgr48_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr48_pre(*rbuf);
}

GammaLUT8* create_gamma_lut8() {
  return new GammaLUT8();
}

GammaLUT8* create_gamma_lut8_a(double a) {
  return new GammaLUT8(a);
}

GammaLUT16* create_gamma_lut16() {
  return new GammaLUT16();
}

GammaLUT16* create_gamma_lut16_a(double a) {
  return new GammaLUT16(a);
}

void pixf_rgb24_blend_pixel(agg::pixfmt_rgb24* pixf, int x, int y, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_pixel(x, y, c, cover);
}

void pixf_rgb24_blend_color_hspan(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_hspan(x, y, len, colors, covers, cover);
}

void pixf_rgb24_blend_color_vspan(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_vspan(x, y, len, colors, covers, cover);
}

void pixf_rgb24_blend_hline(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_hline(x, y, len, c, cover);
}

void pixf_rgb24_blend_vline(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_vline(x, y, len, c, cover);
}

void pixf_rgb24_blend_solid_hspan(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u* covers) {
  pixf->blend_solid_hspan(x, y, len, c, covers);
}

void pixf_rgb24_blend_solid_vspan(agg::pixfmt_rgb24* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u* covers) {
  pixf->blend_solid_vspan(x, y, len, c, covers);
}

void pixf_rgb24_apply_gamma_inv(agg::pixfmt_rgb24* pixf, GammaLUT8* g) {
  pixf->apply_gamma_inv(*g);
}

void pixf_rgb24_apply_gamma_dir(agg::pixfmt_rgb24* pixf, GammaLUT8* g) {
  pixf->apply_gamma_dir(*g);
}

}