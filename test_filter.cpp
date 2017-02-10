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

struct filter_base
{
    virtual double radius() const = 0;
    virtual void set_radius(double r) = 0;
    virtual double calc_weight(double x) const = 0;
};


template<class Filter> struct image_filter_const_radius_adaptor : filter_base
{
    virtual double radius() const { return m_filter.radius(); }
    virtual void set_radius(double r) {}
    virtual double calc_weight(double x) const { return m_filter.calc_weight(fabs(x)); }
    Filter m_filter;
};


template<class Filter> struct image_filter_variable_radius_adaptor : filter_base
{
    virtual double radius() const { return m_filter.radius(); }
    virtual double calc_weight(double x) const { return m_filter.calc_weight(fabs(x)); }
    virtual void set_radius(double r) { m_filter = Filter(r); }
    image_filter_variable_radius_adaptor() : m_filter(2.0) {}
    Filter m_filter;
};


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
  
  image_filter_const_radius_adaptor<agg::image_filter_bilinear>    m_filter_bilinear;
  image_filter_const_radius_adaptor<agg::image_filter_bicubic>     m_filter_bicubic;
  image_filter_const_radius_adaptor<agg::image_filter_spline16>    m_filter_spline16;
  image_filter_const_radius_adaptor<agg::image_filter_spline36>    m_filter_spline36;
  image_filter_const_radius_adaptor<agg::image_filter_hanning>     m_filter_hanning;
  image_filter_const_radius_adaptor<agg::image_filter_hamming>     m_filter_hamming;
  image_filter_const_radius_adaptor<agg::image_filter_hermite>     m_filter_hermite;
  image_filter_const_radius_adaptor<agg::image_filter_kaiser>      m_filter_kaiser;
  image_filter_const_radius_adaptor<agg::image_filter_quadric>     m_filter_quadric;
  image_filter_const_radius_adaptor<agg::image_filter_catrom>      m_filter_catrom;
  image_filter_const_radius_adaptor<agg::image_filter_gaussian>    m_filter_gaussian;
  image_filter_const_radius_adaptor<agg::image_filter_bessel>      m_filter_bessel;
  image_filter_const_radius_adaptor<agg::image_filter_mitchell>    m_filter_mitchell;
  image_filter_variable_radius_adaptor<agg::image_filter_sinc>     m_filter_sinc;
  image_filter_variable_radius_adaptor<agg::image_filter_lanczos>  m_filter_lanczos;
  image_filter_variable_radius_adaptor<agg::image_filter_blackman> m_filter_blackman;

  filter_base* m_filter_func[32];
  
  m_filter_func[0] = &m_filter_bilinear;
  m_filter_func[1] = &m_filter_bicubic;
  m_filter_func[2] = &m_filter_spline16;
  m_filter_func[3] = &m_filter_spline36;
  m_filter_func[4] = &m_filter_hanning;
  m_filter_func[5] = &m_filter_hamming;
  m_filter_func[6] = &m_filter_hermite;
  m_filter_func[7] = &m_filter_kaiser;
  m_filter_func[8] = &m_filter_quadric;
  m_filter_func[9] = &m_filter_catrom;
  m_filter_func[10] = &m_filter_gaussian;
  m_filter_func[11] = &m_filter_bessel;
  m_filter_func[12] = &m_filter_mitchell;
  m_filter_func[13] = &m_filter_sinc;
  m_filter_func[14] = &m_filter_lanczos;
  m_filter_func[15] = &m_filter_blackman;
        
  /*for(i = 0; i <= 16; i++)
  {
      double x = x_start + (x_end - x_start) * i / 16.0;
      p.remove_all();
      p.move_to(x+0.5, y_start);
      p.line_to(x+0.5, y_end);
      ras.add_path(tr);
      rs.color(agg::rgba8(0, 0, 0, i == 8 ? 255 : 100));
      agg::render_scanlines(ras, sl, rs);
  }*/
  double ys = y_start + (y_end - y_start) / 6.0;
  for(int i = 0; i < 16; i++)
  {
     m_filter_func[i]->set_radius(4.0);
     unsigned j;
     
     double radius = m_filter_func[i]->radius();
     unsigned n = unsigned(radius * 256 * 2);
     double dy = y_end - ys;
     
     double xs = (x_end + x_start)/2.0 - (radius * (x_end - x_start) / 16.0);
     double dx = (x_end - x_start) * radius / 8.0;
     
     //printf("radius: %3.3f n: %d dy: %3.3f xs: %3.3f dx: %3.3f\n", radius, n, dy, xs, dx);
     //double rd = m_filter_func[i]->calc_weight(-radius);
     //if(i == 7) { printf("radius: %3.3f cw: %3.3f\n", radius, rd); }
     
     p.remove_all();
     p.move_to(xs+0.5, ys + dy * m_filter_func[i]->calc_weight(-radius));
     for(j = 1; j < n; j++)
     {
         p.line_to(xs + dx * j / n + 0.5,
                   ys + dy * m_filter_func[i]->calc_weight(j / 256.0 - radius));
     }
     ras.add_path(tr);
     rs.color(agg::rgba8(100, 0, 0));
     agg::render_scanlines(ras, sl, rs);
     
     p.remove_all();
     unsigned xint;
     int ir = int(ceil(radius) + 0.1);
     //printf("%d\n", ir);
     for(xint = 0; xint < 256; xint++)
     {
         int xfract;
         double sum = 0;
         for(xfract = -ir; xfract < ir; xfract++) 
         {
             double xf = xint/256.0 + xfract;
             if(xf >= -radius || xf <= radius)
             {
                 sum += m_filter_func[i]->calc_weight(xf);
             }
         }
     
         double x = x_center + ((-128.0 + xint) / 128.0) * radius * (x_end - x_start) / 16.0;
         double y = ys + sum * 256 - 256;
     
         if(xint == 0) p.move_to(x, y);
         else          p.line_to(x, y);
     }
     ras.add_path(tr);
     rs.color(agg::rgba8(0, 100, 0));
     agg::render_scanlines(ras, sl, rs);
     
     /*agg::image_filter_lut normalized(*m_filter_func[i]);
     const agg::int16* weights = normalized.weight_array();
     
     xs = (x_end + x_start)/2.0 - (normalized.diameter() * (x_end - x_start) / 32.0);
     unsigned nn = normalized.diameter() * 256;
     p.remove_all();
     p.move_to(xs+0.5, ys + dy * weights[0] / agg::image_filter_scale);
     for(j = 1; j < nn; j++)
     {
         p.line_to(xs + dx * j / n + 0.5,
                   ys + dy * weights[j] / agg::image_filter_scale);
     }
     ras.add_path(tr);
     rs.color(agg::rgba8(0, 0, 100, 255));
     agg::render_scanlines(ras, sl, rs);*/
  }
}

}