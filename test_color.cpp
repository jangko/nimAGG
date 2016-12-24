#include <agg_basics.h>
#include <agg_color_rgba.h>
#include <agg_gamma_lut.h>

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8> GammaLUT8; 
typedef agg::gamma_lut<agg::int16u, agg::int16u, 16, 16> GammaLUT16; 

extern "C" {

void rgba_premultiply(agg::rgba& c) {
  c.premultiply();
}

void rgba_premultiply_a(agg::rgba& c, double a) {
  c.premultiply(a);
}

void rgba_demultiply(agg::rgba& c) {
  c.demultiply();
}

agg::rgba rgba_gradient(agg::rgba& s, agg::rgba c, double k) {
  return s.gradient(c, k);
}

void rgba8_opacity(agg::rgba8& s, double a) {
  s.opacity(a);
}

double rgba8_get_opacity(agg::rgba8& s) {
  return s.opacity();
}

void rgba8_premultiply(agg::rgba8& c) {
  c.premultiply();
}

void rgba8_premultiply_a(agg::rgba8& c, unsigned a) {
  c.premultiply(a);
}

void rgba8_demultiply(agg::rgba8& c) {
  c.demultiply();
}

agg::rgba8 rgba8_gradient(agg::rgba8& s, agg::rgba8 c, double k) {
  return s.gradient(c, k);
}

void rgba8_add(agg::rgba8& s, agg::rgba8 c, unsigned cover) {
  return s.add(c, cover);
}

void rgba8_apply_gamma_dir(agg::rgba8& s, GammaLUT8& gamma) {
  s.apply_gamma_dir(gamma);
}

void rgba8_apply_gamma_inv(agg::rgba8& s, GammaLUT8& gamma) {
  s.apply_gamma_inv(gamma);
}

void rgba16_opacity(agg::rgba16& s, double a) {
  s.opacity(a);
}

double rgba16_get_opacity(agg::rgba16& s) {
  return s.opacity();
}

void rgba16_premultiply(agg::rgba16& c) {
  c.premultiply();
}

void rgba16_premultiply_a(agg::rgba16& c, double a) {
  c.premultiply(a);
}

void rgba16_demultiply(agg::rgba16& c) {
  c.demultiply();
}

agg::rgba16 rgba16_gradient(agg::rgba16& s, agg::rgba16 c, double k) {
  return s.gradient(c, k);
}

void rgba16_add(agg::rgba16& s, agg::rgba16 c, unsigned cover) {
  return s.add(c, cover);
}

void rgba16_apply_gamma_dir(agg::rgba16& s, GammaLUT16& gamma) {
  s.apply_gamma_dir(gamma);
}

void rgba16_apply_gamma_inv(agg::rgba16& s, GammaLUT16& gamma) {
  s.apply_gamma_inv(gamma);
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

}