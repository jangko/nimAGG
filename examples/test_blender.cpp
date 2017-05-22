#include "agg_pixfmt_rgb.h"
#include "agg_pixfmt_rgba.h"
#include "agg_pixfmt_gray.h"
#include "agg_gamma_lut.h"

extern "C" {

void rgb24_blendpix1(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::blender_rgb_pre<agg::rgba8, agg::order_rgb> blender;
  blender.blend_pix(p, cr, cg, cb, alpha, cover);
}

void rgb24_blendpix2(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha) {
  agg::blender_rgb_pre<agg::rgba8, agg::order_rgb> blender;
  blender.blend_pix(p, cr, cg, cb, alpha);
}

void gray8_blendpix1(unsigned char* p, unsigned cv, unsigned alpha, unsigned cover) {
  agg::blender_gray_pre<agg::gray8> blender;
  blender.blend_pix(p, cv, alpha, cover);
}

void gray8_blendpix2(unsigned char* p, unsigned cv, unsigned alpha) {
  agg::blender_gray_pre<agg::gray8> blender;
  blender.blend_pix(p, cv, alpha);
}

void pre32_blendpix1(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::blender_rgba_pre<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(p, cr, cg, cb, alpha, cover);
}

void pre32_blendpix2(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha) {
  agg::blender_rgba_pre<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(p, cr, cg, cb, alpha);
}

void plain32_blendpix1(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::blender_rgba_plain<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(p, cr, cg, cb, alpha, cover);
}


void car_blendpix(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_adaptor_rgba<agg::blender_rgba_pre<agg::rgba8, agg::order_rgba> >blender;
  blender.blend_pix(0, p, cr, cg, cb, alpha, cover);
}

void carctd_blendpix(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_adaptor_clip_to_dst_rgba<agg::blender_rgba_pre<agg::rgba8, agg::order_rgba> >blender;
  blender.blend_pix(0, p, cr, cg, cb, alpha, cover);
}

void carctdpre_blendpix(unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_adaptor_clip_to_dst_rgba_pre<agg::blender_rgba_pre<agg::rgba8, agg::order_rgba> >blender;
  blender.blend_pix(0, p, cr, cg, cb, alpha, cover);
}

void t_blendpix(unsigned op, unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(op, p, cr, cg, cb, alpha, cover);
}

void u_blendpix(unsigned op, unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_op_adaptor_clip_to_dst_rgba<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(op, p, cr, cg, cb, alpha, cover);
}

void v_blendpix(unsigned op, unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_op_adaptor_rgba_pre<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(op, p, cr, cg, cb, alpha, cover);
}

void w_blendpix(unsigned op, unsigned char* p, unsigned cr, unsigned cg, unsigned cb,
                     unsigned alpha, unsigned cover) {
  agg::comp_op_adaptor_clip_to_dst_rgba_pre<agg::rgba8, agg::order_rgba> blender;
  blender.blend_pix(op, p, cr, cg, cb, alpha, cover);
}


agg::rendering_buffer* create_rbuf(unsigned char* buffer, int frame_width, int frame_height, int stride) {
  return new agg::rendering_buffer(buffer, frame_width, frame_height, stride);
}

typedef agg::comp_op_adaptor_rgba<agg::rgba8, agg::order_rgba> comp_op_adaptor;
typedef agg::pixfmt_custom_blend_rgba<comp_op_adaptor, agg::rendering_buffer> pixf_type;

pixf_type* create_pixf(agg::rendering_buffer* rbuf) {
  return new pixf_type(*rbuf);
}

void pixf_blend_pixel(pixf_type* pixf, int x, int y, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_pixel(x, y, c, cover);
}

void pixf_blend_color_hspan(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_hspan(x, y, len, colors, covers, cover);
}

void pixf_blend_color_vspan(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8* colors,
                               agg::int8u* covers, agg::int8u cover) {
  pixf->blend_color_vspan(x, y, len, colors, covers, cover);
}

void pixf_blend_hline(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_hline(x, y, len, c, cover);
}

void pixf_blend_vline(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u cover) {
  pixf->blend_vline(x, y, len, c, cover);
}

void pixf_blend_solid_hspan(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u* covers) {
  pixf->blend_solid_hspan(x, y, len, c, covers);
}

void pixf_blend_solid_vspan(pixf_type* pixf, int x, int y, unsigned len, agg::rgba8& c, agg::int8u* covers) {
  pixf->blend_solid_vspan(x, y, len, c, covers);
}

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8> GammaLUT8; 
void pixf_apply_gamma_inv(pixf_type* pixf, GammaLUT8* g) {
  pixf->apply_gamma_inv(*g);
}

void pixf_apply_gamma_dir(pixf_type* pixf, GammaLUT8* g) {
  pixf->apply_gamma_dir(*g);
}

void pixf_copy_pixel(pixf_type* pixf, int x, int y, const agg::rgba8& c) {
  pixf->copy_pixel(x, y, c);
}

agg::rgba8 pixf_pixel(pixf_type* pixf, int x, int y) {
  return pixf->pixel(x, y);
}

GammaLUT8* create_gamma_lut8() {
  return new GammaLUT8();
}

void pixf_copy_hline(pixf_type* pixf, int x, int y, unsigned len, const agg::rgba8& c) {
  pixf->copy_hline(x, y, len, c);
}

void pixf_copy_vline(pixf_type* pixf, int x, int y, unsigned len, const agg::rgba8& c) {
  pixf->copy_vline(x, y, len, c);
}

void pixf_copy_color_hspan(pixf_type* pixf, int x, int y, unsigned len, const agg::rgba8* colors) {
  pixf->copy_color_hspan(x, y, len, colors);
}

void pixf_copy_color_vspan(pixf_type* pixf, int x, int y, unsigned len, const agg::rgba8* colors) {
  pixf->copy_color_vspan(x, y, len, colors);
}

}