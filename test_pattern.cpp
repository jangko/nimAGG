#include "agg_basics.h"
#include "agg_rendering_buffer.h"
#include "agg_conv_transform.h"
#include "agg_conv_stroke.h"
#include "agg_conv_clip_polyline.h"
#include "agg_scanline_p.h"
#include "agg_renderer_scanline.h"
#include "agg_rasterizer_outline_aa.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_pattern_filters_rgba.h"
#include "agg_renderer_outline_aa.h"
#include "agg_renderer_outline_image.h"
#include "agg_pixfmt_rgb.h"
#include "ctrl/agg_bezier_ctrl.h"

enum flip_y_e { flip_y = true };

typedef agg::pixfmt_rgb24 pixfmt;


static agg::int8u brightness_to_alpha[256 * 3] = 
{
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 254, 254, 254, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 
    254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 254, 253, 253, 
    253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 253, 252, 
    252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 251, 251, 251, 251, 251, 
    251, 251, 251, 251, 250, 250, 250, 250, 250, 250, 250, 250, 249, 249, 249, 249, 
    249, 249, 249, 248, 248, 248, 248, 248, 248, 248, 247, 247, 247, 247, 247, 246, 
    246, 246, 246, 246, 246, 245, 245, 245, 245, 245, 244, 244, 244, 244, 243, 243, 
    243, 243, 243, 242, 242, 242, 242, 241, 241, 241, 241, 240, 240, 240, 239, 239, 
    239, 239, 238, 238, 238, 238, 237, 237, 237, 236, 236, 236, 235, 235, 235, 234, 
    234, 234, 233, 233, 233, 232, 232, 232, 231, 231, 230, 230, 230, 229, 229, 229, 
    228, 228, 227, 227, 227, 226, 226, 225, 225, 224, 224, 224, 223, 223, 222, 222, 
    221, 221, 220, 220, 219, 219, 219, 218, 218, 217, 217, 216, 216, 215, 214, 214, 
    213, 213, 212, 212, 211, 211, 210, 210, 209, 209, 208, 207, 207, 206, 206, 205, 
    204, 204, 203, 203, 202, 201, 201, 200, 200, 199, 198, 198, 197, 196, 196, 195, 
    194, 194, 193, 192, 192, 191, 190, 190, 189, 188, 188, 187, 186, 186, 185, 184, 
    183, 183, 182, 181, 180, 180, 179, 178, 177, 177, 176, 175, 174, 174, 173, 172, 
    171, 171, 170, 169, 168, 167, 166, 166, 165, 164, 163, 162, 162, 161, 160, 159, 
    158, 157, 156, 156, 155, 154, 153, 152, 151, 150, 149, 148, 148, 147, 146, 145, 
    144, 143, 142, 141, 140, 139, 138, 137, 136, 135, 134, 133, 132, 131, 130, 129, 
    128, 128, 127, 125, 124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 114, 113, 
    112, 111, 110, 109, 108, 107, 106, 105, 104, 102, 101, 100,  99,  98,  97,  96,  
     95,  94,  93,  91,  90,  89,  88,  87,  86,  85,  84,  82,  81,  80,  79,  78, 
     77,  75,  74,  73,  72,  71,  70,  69,  67,  66,  65,  64,  63,  61,  60,  59, 
     58,  57,  56,  54,  53,  52,  51,  50,  48,  47,  46,  45,  44,  42,  41,  40, 
     39,  37,  36,  35,  34,  33,  31,  30,  29,  28,  27,  25,  24,  23,  22,  20, 
     19,  18,  17,  15,  14,  13,  12,  11,   9,   8,   7,   6,   4,   3,   2,   1
};


class pattern_src_brightness_to_alpha_rgba8
{
public:
    pattern_src_brightness_to_alpha_rgba8(agg::rendering_buffer& rb) : 
        m_rb(&rb), m_pf(*m_rb) {}

    unsigned width()  const { return m_pf.width();  }
    unsigned height() const { return m_pf.height(); }
    agg::rgba8 pixel(int x, int y) const
    {
        agg::rgba8 c = m_pf.pixel(x, y);
        c.a = brightness_to_alpha[c.r + c.g + c.b];
        return c;
    }

private:
    agg::rendering_buffer* m_rb;
    pixfmt m_pf;
};

extern "C" {
typedef agg::renderer_base<pixfmt> renderer_base;
typedef agg::renderer_scanline_aa_solid<renderer_base> renderer_scanline;
typedef agg::rasterizer_scanline_aa<> rasterizer_scanline;
typedef agg::scanline_p8 scanline;
 
const int frameWidth = 540;
const int frameHeight = 450;
const int pixWidth = 3;
  
unsigned char* test_pattern(unsigned char* image, int w, int h, agg::rgba8** data) {
  unsigned char* buffer = new unsigned char[frameWidth * frameHeight * 3];
  memset(buffer, 255, frameWidth * frameHeight * 3);
  agg::rendering_buffer rbuf(buffer, 
                               frameWidth, 
                               frameHeight, 
                               frameWidth * 3);
  
  agg::rendering_buffer rbuf_img(image, w, h, w * 3);
    
  agg::rgba8 m_ctrl_color(agg::rgba(0, 0.3, 0.5, 0.3));
  agg::bezier_ctrl<agg::rgba8> m_curve1;
  m_curve1.line_color(m_ctrl_color);
  m_curve1.curve(64, 19, 14, 126, 118, 266, 19, 265);
  m_curve1.no_transform();
  pixfmt pf(rbuf);
  renderer_base ren_base(pf);
  ren_base.clear(agg::rgba(1.0, 1.0, 0.95));
  renderer_scanline ren(ren_base);

  rasterizer_scanline ras;
  scanline sl; 
  pattern_src_brightness_to_alpha_rgba8 p1(rbuf_img);
  agg::pattern_filter_bilinear_rgba8 fltr;
  typedef agg::line_image_pattern<agg::pattern_filter_bilinear_rgba8> pattern_type;
  typedef agg::renderer_base<pixfmt> base_ren_type;
  typedef agg::renderer_outline_image<base_ren_type, pattern_type> renderer_type;
  typedef agg::rasterizer_outline_aa<renderer_type>                rasterizer_type;
  
  pattern_type patt(fltr);        
  renderer_type ren_img(ren_base, patt);
  rasterizer_type ras_img(ren_img);
  
  //for(int y = 0; y < p1.height(); y++) {
  //  for(int x = 0; x < p1.width(); x++) {
  //    agg::rgba8 c = p1.pixel(x, y);
  //    printf("%d %d %d %d\n", c.r, c.g, c.b, c.a);
  //  }
  //}
                    
  patt.create(p1);
  ren_img.scale_x(1.0);
  ren_img.start_x(0.0);
  ras_img.add_path(m_curve1.curve());
  
 /* printf("----\n");
  const agg::rgba8* const* rows = patt.data();
  for(int i = 0; i < patt.h(); i++) {
      printf("%d\n", memcmp(data[i], rows[i], patt.w()));
  }*/
  
  //return memcmp(data, patt.data(), patt.size());
  return buffer;
}

}