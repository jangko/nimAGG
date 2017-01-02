#include <agg_pixfmt_rgb.h>
#include <agg_color_rgba.h>
#include <agg_gamma_lut.h>
#include <agg_pixfmt_gray.h>
#include <agg_color_gray.h>

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8> GammaLUT8; 
typedef agg::gamma_lut<agg::int16u, agg::int16u, 16, 16> GammaLUT16; 

extern "C" {

agg::rendering_buffer* create_rbuf(unsigned char* buffer, int frame_width, int frame_height, int stride) {
  return new agg::rendering_buffer(buffer, frame_width, frame_height, stride);
}

agg::pixfmt_rgb24* create_pixf_rgb24(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb24(*rbuf);
}

agg::pixfmt_bgr24* create_pixf_bgr24(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr24(*rbuf);
}

agg::pixfmt_rgb48* create_pixf_rgb48(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb48(*rbuf);
}

agg::pixfmt_bgr48* create_pixf_bgr48(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr48(*rbuf);
}

agg::pixfmt_rgb24_pre* create_pixf_rgb24_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb24_pre(*rbuf);
}

agg::pixfmt_bgr24_pre* create_pixf_bgr24_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr24_pre(*rbuf);
}

agg::pixfmt_rgb48_pre* create_pixf_rgb48_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_rgb48_pre(*rbuf);
}

agg::pixfmt_bgr48_pre* create_pixf_bgr48_pre(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_bgr48_pre(*rbuf);
}

agg::pixfmt_gray8* create_pixf_gray8(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_gray8(*rbuf);
}

agg::pixfmt_gray16* create_pixf_gray16(agg::rendering_buffer* rbuf) {
  return new agg::pixfmt_gray16(*rbuf);
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


void pixf_rgb48_blend_pixel(agg::pixfmt_rgb48* pixf, int x, int y, agg::rgba16& c, agg::int8u cover) {
  pixf->blend_pixel(x, y, c, cover);
}

void pixf_rgb48_blend_color_hspan(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_hspan(x, y, len, colors, covers, cover);
}

void pixf_rgb48_blend_color_vspan(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_vspan(x, y, len, colors, covers, cover);
}

void pixf_rgb48_blend_hline(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16& c, agg::int8u cover) {
  pixf->blend_hline(x, y, len, c, cover);
}

void pixf_rgb48_blend_vline(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16& c, agg::int8u cover) {
  pixf->blend_vline(x, y, len, c, cover);
}

void pixf_rgb48_blend_solid_hspan(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16& c, agg::int8u* covers) {
  pixf->blend_solid_hspan(x, y, len, c, covers);
}

void pixf_rgb48_blend_solid_vspan(agg::pixfmt_rgb48* pixf, int x, int y, unsigned len, agg::rgba16& c, agg::int8u* covers) {
  pixf->blend_solid_vspan(x, y, len, c, covers);
}

void pixf_rgb48_apply_gamma_inv(agg::pixfmt_rgb48* pixf, GammaLUT16* g) {
  pixf->apply_gamma_inv(*g);
}

void pixf_rgb48_apply_gamma_dir(agg::pixfmt_rgb48* pixf, GammaLUT16* g) {
  pixf->apply_gamma_dir(*g);
}

void pixf_gray8_blend_pixel(agg::pixfmt_gray8* pixf, int x, int y, agg::gray8& c, agg::int8u cover) {
  pixf->blend_pixel(x, y, c, cover);
}

void pixf_gray8_blend_color_hspan(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_hspan(x, y, len, colors, covers, cover);
}

void pixf_gray8_blend_color_vspan(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_vspan(x, y, len, colors, covers, cover);
}

void pixf_gray8_blend_hline(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8& c, agg::int8u cover) {
  pixf->blend_hline(x, y, len, c, cover);
}

void pixf_gray8_blend_vline(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8& c, agg::int8u cover) {
  pixf->blend_vline(x, y, len, c, cover);
}

void pixf_gray8_blend_solid_hspan(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8& c, agg::int8u* covers) {
  pixf->blend_solid_hspan(x, y, len, c, covers);
}

void pixf_gray8_blend_solid_vspan(agg::pixfmt_gray8* pixf, int x, int y, unsigned len, agg::gray8& c, agg::int8u* covers) {
  pixf->blend_solid_vspan(x, y, len, c, covers);
}

void pixf_gray8_apply_gamma_inv(agg::pixfmt_gray8* pixf, GammaLUT8* g) {
  pixf->apply_gamma_inv(*g);
}

void pixf_gray8_apply_gamma_dir(agg::pixfmt_gray8* pixf, GammaLUT8* g) {
  pixf->apply_gamma_dir(*g);
}


void pixf_gray16_blend_pixel(agg::pixfmt_gray16* pixf, int x, int y, agg::gray16& c, agg::int8u cover) {
  pixf->blend_pixel(x, y, c, cover);
}

void pixf_gray16_blend_color_hspan(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_hspan(x, y, len, colors, covers, cover);
}

void pixf_gray16_blend_color_vspan(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_vspan(x, y, len, colors, covers, cover);
}

void pixf_gray16_blend_hline(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16& c, agg::int8u cover) {
  pixf->blend_hline(x, y, len, c, cover);
}

void pixf_gray16_blend_vline(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16& c, agg::int8u cover) {
  pixf->blend_vline(x, y, len, c, cover);
}

void pixf_gray16_blend_solid_hspan(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16& c, agg::int8u* covers) {
  pixf->blend_solid_hspan(x, y, len, c, covers);
}

void pixf_gray16_blend_solid_vspan(agg::pixfmt_gray16* pixf, int x, int y, unsigned len, agg::gray16& c, agg::int8u* covers) {
  pixf->blend_solid_vspan(x, y, len, c, covers);
}

void pixf_gray16_apply_gamma_inv(agg::pixfmt_gray16* pixf, GammaLUT16* g) {
  pixf->apply_gamma_inv(*g);
}

void pixf_gray16_apply_gamma_dir(agg::pixfmt_gray16* pixf, GammaLUT16* g) {
  pixf->apply_gamma_dir(*g);
}
}