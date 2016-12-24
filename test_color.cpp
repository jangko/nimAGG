#include <agg_color_rgba.h>

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

}