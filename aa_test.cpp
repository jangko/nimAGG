#include "agg_basics.h"
#include "agg_color_rgba.h"
#include "agg_array.h"
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_scanline_u.h"
#include "agg_renderer_scanline.h"
#include "agg_pixfmt_rgb.h"
#include "agg_gamma_lut.h"
#include "agg_conv_dash.h"
#include "agg_conv_stroke.h"
#include "agg_span_gradient.h"
#include "agg_span_interpolator_linear.h"
#include "agg_span_gouraud_rgba.h"
#include "agg_span_allocator.h"

typedef agg::gamma_lut<agg::int8u, agg::int8u, 8, 8>        gamma_lut_type;
typedef agg::pixfmt_bgr24_gamma<gamma_lut_type>             pixfmt_type;
typedef pixfmt_type::color_type                             color_type;
typedef agg::renderer_base<pixfmt_type>                     renderer_base_type;
typedef agg::renderer_scanline_aa_solid<renderer_base_type> renderer_scanline_type;
typedef agg::scanline_u8                                    scanline_type;
typedef agg::rasterizer_scanline_aa<>                       rasterizer_type;

class simple_vertex_source
{
public:
    simple_vertex_source() : m_num_vertices(0), m_count(0) 
    { 
        m_cmd[0] = agg::path_cmd_stop;
    }


    simple_vertex_source(double x1, double y1, double x2, double y2)
    {
        init(x1, y1, x2, y2);
    }


    simple_vertex_source(double x1, double y1, 
                         double x2, double y2,
                         double x3, double y3)
    {
        init(x1, y1, x2, y2, x3, y3);
    }

    void init(double x1, double y1, double x2, double y2)
    {
        m_num_vertices = 2;
        m_count = 0;
        m_x[0] = x1;
        m_y[0] = y1;
        m_x[1] = x2;
        m_y[1] = y2;
        m_cmd[0] = agg::path_cmd_move_to;
        m_cmd[1] = agg::path_cmd_line_to;
        m_cmd[2] = agg::path_cmd_stop;
    }



    void init(double x1, double y1, 
              double x2, double y2,
              double x3, double y3)
    {
        m_num_vertices = 3;
        m_count = 0;
        m_x[0] = x1;
        m_y[0] = y1;
        m_x[1] = x2;
        m_y[1] = y2;
        m_x[2] = x3;
        m_y[2] = y3;
        m_x[3] = m_y[3] = m_x[4] = m_y[4] = 0.0;
        m_cmd[0] = agg::path_cmd_move_to;
        m_cmd[1] = agg::path_cmd_line_to;
        m_cmd[2] = agg::path_cmd_line_to;
        m_cmd[3] = agg::path_cmd_end_poly | agg::path_flags_close;
        m_cmd[4] = agg::path_cmd_stop;
    }


    void rewind(unsigned)
    {
        m_count = 0;
    }

    unsigned vertex(double* x, double* y)
    {
        *x = m_x[m_count];
        *y = m_y[m_count];
        return m_cmd[m_count++];
    }

private:
    unsigned m_num_vertices;
    unsigned m_count;
    double   m_x[8];
    double   m_y[8];
    unsigned m_cmd[8];
};





template<class Ras, class Ren, class Scanline> class dashed_line
{
public:
    dashed_line(Ras& ras, Ren& ren, Scanline& sl) : 
        m_ras(ras), m_ren(ren), m_sl(sl),
        m_src(),
        m_dash(m_src),
        m_stroke(m_src),
        m_dash_stroke(m_dash)
    {}

    void draw(double x1, double y1, double x2, double y2, 
              double line_width, double dash_length)
    {
        m_src.init(x1 + 0.5, y1 + 0.5, x2 + 0.5, y2 + 0.5);
        m_ras.reset();
        if(dash_length > 0.0)
        {
            m_dash.remove_all_dashes();
            m_dash.add_dash(dash_length, dash_length);
            m_dash_stroke.width(line_width);
            m_dash_stroke.line_cap(agg::round_cap);
            m_ras.add_path(m_dash_stroke);
        }
        else
        {
            m_stroke.width(line_width);
            m_stroke.line_cap(agg::round_cap);
            m_ras.add_path(m_stroke);
        }
        agg::render_scanlines(m_ras, m_sl, m_ren);
    }

private:
    Ras&      m_ras;
    Ren&      m_ren;
    Scanline& m_sl;
    simple_vertex_source m_src;
    agg::conv_dash<simple_vertex_source> m_dash;
    agg::conv_stroke<simple_vertex_source> m_stroke;
    agg::conv_stroke<agg::conv_dash<simple_vertex_source> > m_dash_stroke;
};

template<class ColorArrayT>
void print_color(ColorArrayT& array) {
  for(int i = 0; i < 256; ++i) {
    const agg::rgba8& x = array[i];
    printf("%d %d %d %d\n", x.r, x.g, x.b, x.a);
  }
}

template<class ColorArrayT>
void fill_color_array(ColorArrayT& array, 
                      color_type begin, 
                      color_type end)
{
    unsigned i;
    for(i = 0; i < 256; ++i)
    {
        array[i] = begin.gradient(end, i / 255.0);        
    }
}

void calc_linear_gradient_transform(double x1, double y1, double x2, double y2, 
                                    agg::trans_affine& mtx,
                                    double gradient_d2 = 100.0)
{
    double dx = x2 - x1;
    double dy = y2 - y1;
    mtx.reset();
    mtx *= agg::trans_affine_scaling(sqrt(dx * dx + dy * dy) / gradient_d2);
    mtx *= agg::trans_affine_rotation(atan2(dy, dx));
    mtx *= agg::trans_affine_translation(x1 + 0.5, y1 + 0.5);
    mtx.invert();
}

void print_mtx(agg::trans_affine& mtx) {
  printf("%3.3f %3.3f %3.3f %3.3f %3.3f %3.3f\n", mtx.sx, mtx.shy, mtx.shx, mtx.sy, mtx.tx, mtx.ty);
}

const int frameWidth = 600;
const int frameHeight = 480;
const int pixWidth = 3;

extern "C" {
  
void test_aa() {
  
  
  typedef agg::gradient_x gradient_func_type;
  typedef agg::span_interpolator_linear<> interpolator_type;
  typedef agg::span_allocator<color_type> span_allocator_type;
  typedef agg::pod_auto_array<color_type, 256> color_array_type;
  typedef agg::span_gradient<color_type, 
                                   interpolator_type, 
                                   gradient_func_type, 
                                   color_array_type> span_gradient_type;

  typedef agg::renderer_scanline_aa<renderer_base_type, 
                                          span_allocator_type,
                                          span_gradient_type> renderer_gradient_type;

  
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               frameWidth * 3);
  scanline_type sl;
  rasterizer_type ras;
  gamma_lut_type gamma(1.5);
  pixfmt_type pixf(rbuf, gamma);
  renderer_base_type ren_base(pixf);
  ren_base.clear(agg::rgba(0,0,0));
  
  gradient_func_type  gradient_func;                   // The gradient function
  agg::trans_affine   gradient_mtx;                    // Affine transformer
  interpolator_type   span_interpolator(gradient_mtx); // Span interpolator
  span_allocator_type span_allocator;                  // Span Allocator
  color_array_type    gradient_colors;                 // The gradient colors
  span_gradient_type  span_gradient(span_interpolator, 
                                          gradient_func, 
                                          gradient_colors, 
                                          0, 100);

  renderer_gradient_type ren_gradient(ren_base, span_allocator, span_gradient);
  
  dashed_line<rasterizer_type, 
                    renderer_gradient_type, 
                    scanline_type> dash_gradient(ras, ren_gradient, sl);
                    
  double x1, y1, x2, y2;                  
  
  for(int i = 1; i <= 20; i++) {
    fill_color_array(gradient_colors, 
                             agg::rgba(1,1,1), 
                             agg::rgba(i % 2, (i % 3) * 0.5, (i % 5) * 0.25));
    //print_color(gradient_colors);
    
    x1 = 20 + i* (i + 1);
    y1 = 40.5;
    x2 = 20 + i * (i + 1) + (i - 1) * 4;
    y2 = 100.5;
    calc_linear_gradient_transform(x1, y1, x2, y2, gradient_mtx);
    //print_mtx(gradient_mtx);
    dash_gradient.draw(x1, y1, x2, y2, i, 0);
  }
}

}