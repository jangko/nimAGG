#include <math.h>
#include <stdio.h>
#include "agg_basics.h"
#include "agg_ellipse.h"
#include "agg_gamma_lut.h"
#include "agg_rendering_buffer.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_rasterizer_compound_aa.h"
#include "agg_conv_curve.h"
#include "agg_conv_stroke.h"
#include "agg_scanline_u.h"
#include "agg_renderer_scanline.h"
#include "agg_span_allocator.h"
#include "agg_pixfmt_rgba.h"
#include "agg_path_storage.h"

enum flip_y_e { flip_y = true };

//-------------------------------------------------
class style_handler
{
public:
    style_handler(const agg::rgba8* styles, unsigned count) : 
        m_transparent(0, 0, 0, 0),
        m_styles(styles),
        m_count(count)
    {}

    bool is_solid(unsigned style) const { return true; }

    const agg::rgba8& color(unsigned style) const 
    {
        if (style < m_count)
            return m_styles[style];

        return m_transparent;
    }

    void generate_span(agg::rgba8* span, int x, int y, unsigned len, unsigned style)
    {
    }

private:
    agg::rgba8          m_transparent;
    const agg::rgba8*   m_styles;
    unsigned            m_count;
};


void compose_path(agg::path_storage& path)
{
  path.remove_all();
  path.move_to(28.47, 6.45);
  path.curve3(21.58, 1.12, 19.82, 0.29);
  path.curve3(17.19, -0.93, 14.21, -0.93);
  path.curve3(9.57, -0.93, 6.57, 2.25);
  path.curve3(3.56, 5.42, 3.56, 10.60);
  path.curve3(3.56, 13.87, 5.03, 16.26);
  path.curve3(7.03, 19.58, 11.99, 22.51);
  path.curve3(16.94, 25.44, 28.47, 29.64);
  path.line_to(28.47, 31.40);
  path.curve3(28.47, 38.09, 26.34, 40.58);
  path.curve3(24.22, 43.07, 20.17, 43.07);
  path.curve3(17.09, 43.07, 15.28, 41.41);
  path.curve3(13.43, 39.75, 13.43, 37.60);
  path.line_to(13.53, 34.77);
  path.curve3(13.53, 32.52, 12.38, 31.30);
  path.curve3(11.23, 30.08, 9.38, 30.08);
  path.curve3(7.57, 30.08, 6.42, 31.35);
  path.curve3(5.27, 32.62, 5.27, 34.81);
  path.curve3(5.27, 39.01, 9.57, 42.53);
  path.curve3(13.87, 46.04, 21.63, 46.04);
  path.curve3(27.59, 46.04, 31.40, 44.04);
  path.curve3(34.28, 42.53, 35.64, 39.31);
  path.curve3(36.52, 37.21, 36.52, 30.71);
  path.line_to(36.52, 15.53);
  path.curve3(36.52, 9.13, 36.77, 7.69);
  path.curve3(37.01, 6.25, 37.57, 5.76);
  path.curve3(38.13, 5.27, 38.87, 5.27);
  path.curve3(39.65, 5.27, 40.23, 5.62);
  path.curve3(41.26, 6.25, 44.19, 9.18);
  path.line_to(44.19, 6.45);
  path.curve3(38.72, -0.88, 33.74, -0.88);
  path.curve3(31.35, -0.88, 29.93, 0.78);
  path.curve3(28.52, 2.44, 28.47, 6.45);
  path.close_polygon();
  
  path.move_to(28.47, 9.62);
  path.line_to(28.47, 26.66);
  path.curve3(21.09, 23.73, 18.95, 22.51);
  path.curve3(15.09, 20.36, 13.43, 18.02);
  path.curve3(11.77, 15.67, 11.77, 12.89);
  path.curve3(11.77, 9.38, 13.87, 7.06);
  path.curve3(15.97, 4.74, 18.70, 4.74);
  path.curve3(22.41, 4.74, 28.47, 9.62);
  path.close_polygon();
}

const int frameWidth = 440;
const int frameHeight = 330;
const int pixWidth = 4;

extern "C" {
unsigned char* test_compound()
{
    typedef agg::renderer_base<agg::pixfmt_rgba32>     ren_base;
    typedef agg::renderer_base<agg::pixfmt_rgba32_pre> ren_base_pre;
    
    unsigned char* buffer = new unsigned char[frameWidth * frameHeight * pixWidth];
    memset(buffer, 255, frameWidth * frameHeight * pixWidth);
    agg::rendering_buffer rbuf(buffer, frameWidth, frameHeight, -frameWidth * pixWidth);
  
    agg::gamma_lut<agg::int8u, agg::int8u> lut(2.0);

    agg::pixfmt_rgba32 pixf(rbuf);
    ren_base renb(pixf);

    agg::pixfmt_rgba32_pre pixf_pre(rbuf);
    ren_base_pre renb_pre(pixf_pre);

    // Clear the window with a gradient
    agg::pod_vector<agg::rgba8> gr(pixf_pre.width());
    unsigned i;
    for(i = 0; i < pixf.width(); i++)
    {
        gr.add(agg::rgba8(255, 255, 0).gradient(agg::rgba8(0, 255, 255), 
                                                double(i) / pixf.width()));
    }
    for(i = 0; i < pixf.height(); i++)
    {
        renb.copy_color_hspan(0, i, pixf.width(), &gr[0]);
    }
    pixf.apply_gamma_dir(lut);


    agg::rasterizer_scanline_aa<> ras;
    agg::rasterizer_compound_aa<agg::rasterizer_sl_clip_dbl> rasc;
    agg::scanline_u8 sl;
    agg::span_allocator<agg::rgba8> alloc;

    // Draw two triangles
    ras.move_to_d(0, 0);
    ras.line_to_d(frameWidth, 0);
    ras.line_to_d(frameWidth, frameHeight);
    agg::render_scanlines_aa_solid(ras, sl, renb, 
                                   agg::rgba8(lut.dir(0), 
                                              lut.dir(100), 
                                              lut.dir(0)));

    ras.move_to_d(0, 0);
    ras.line_to_d(0, frameHeight);
    ras.line_to_d(frameWidth, 0);
    agg::render_scanlines_aa_solid(ras, sl, renb, 
                                   agg::rgba8(lut.dir(0), 
                                              lut.dir(100), 
                                              lut.dir(100)));

    agg::trans_affine mtx;
    mtx *= agg::trans_affine_scaling(4.0);
    mtx *= agg::trans_affine_translation(150, 100);

    agg::path_storage path;
    compose_path(path);
    agg::conv_transform<agg::path_storage> trans(path, mtx);
    agg::conv_curve<agg::conv_transform<agg::path_storage> > curve(trans);

    agg::conv_stroke
        <agg::conv_curve
            <agg::conv_transform
                <agg::path_storage> > > stroke(curve);


    agg::rgba8 styles[4];

    //if(false)
    //{
    //    rasc.layer_order(agg::layer_inverse);
    //}
    //else
    //{
        rasc.layer_order(agg::layer_direct);
    //}

    styles[3] = agg::rgba8(lut.dir(255),
                           lut.dir(0),
                           lut.dir(108),
                           200).premultiply();

    styles[2] = agg::rgba8(lut.dir(51),
                           lut.dir(0),
                           lut.dir(151),
                           180).premultiply();

    styles[1] = agg::rgba8(lut.dir(143),
                           lut.dir(90),
                           lut.dir(6),
                           200).premultiply();

    styles[0] = agg::rgba8(lut.dir(0),
                           lut.dir(0),
                           lut.dir(255),
                           220).premultiply();

    style_handler sh(styles, 4);

    stroke.width(10.0);

    rasc.reset();
    rasc.master_alpha(3, 1.0);
    rasc.master_alpha(2, 1.0);
    rasc.master_alpha(1, 1.0);
    rasc.master_alpha(0, 1.0);

    agg::ellipse ell(220.0, 180.0, 120.0, 10.0, 128, false);
    agg::conv_stroke<agg::ellipse> str_ell(ell);
    str_ell.width(10.0 / 2);

    rasc.styles(3, -1);
    rasc.add_path(str_ell);

    rasc.styles(2, -1);
    rasc.add_path(ell);

    rasc.styles(1, -1);
    rasc.add_path(stroke);

    rasc.styles(0, -1);
    rasc.add_path(curve);

    agg::render_scanlines_compound_layered(rasc, sl, renb_pre, alloc, sh);
 
    pixf.apply_gamma_inv(lut);
    return buffer;
}

}