#include <math.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "agg_rendering_buffer.h"
#include "agg_trans_viewport.h"
#include "agg_path_storage.h"
#include "agg_conv_transform.h"
#include "agg_conv_curve.h"
#include "agg_conv_stroke.h"
#include "agg_scanline_u.h"
#include "agg_scanline_bin.h"
#include "agg_renderer_scanline.h"
#include "agg_rasterizer_scanline_aa.h"
#include "agg_rasterizer_compound_aa.h"
#include "agg_span_allocator.h"
#include "agg_gamma_lut.h"
#include "agg_bounding_rect.h"
#include "agg_color_rgba.h"

enum { flip_y = false };

namespace agg
{
    struct path_style
    {
        unsigned path_id;
        int left_fill;
        int right_fill;
        int line;
    };

    class compound_shape
    {
    public:
        ~compound_shape() 
        { 
            if(m_fd)
            {
                fclose(m_fd);
            }
        }

        compound_shape() :
            m_path(),
            m_affine(),
            m_curve(m_path),
            m_trans(m_curve, m_affine),
            m_styles()
        {}

        bool open(const char* fname)
        {
            m_fd = fopen(fname, "r");
            return m_fd != 0;
        }

        bool read_next()
        {
            m_path.remove_all();
            m_styles.remove_all();
            const char space[] = " \t\n\r";
            double ax, ay, cx, cy;
            if(m_fd)
            {
                char buf[1024];
                char* ts;

                for(;;)
                {
                    if(fgets(buf, 1022, m_fd) == 0) return false;
                    if(buf[0] == '=') break;
                }

                while(fgets(buf, 1022, m_fd))
                {
                    if(buf[0] == '!') break;
                    if(buf[0] == 'P')
                    {
                        // BeginPath
                        path_style style;
                        style.path_id = m_path.start_new_path();
                        ts = strtok(buf, space); // Path;
                        ts = strtok(0, space);  // left_style
                        style.left_fill = atoi(ts);
                        ts = strtok(0, space);  // right_style
                        style.right_fill = atoi(ts);
                        ts = strtok(0, space);  // line_style
                        style.line = atoi(ts);
                        ts = strtok(0, space);  // ax
                        ax = atof(ts);
                        ts = strtok(0, space);  // ay
                        ay = atof(ts);
                        m_path.move_to(ax, ay);
                        m_styles.add(style);
                    }


                    if(buf[0] == 'C')
                    {
                        ts = strtok(buf, space); // Curve;
                        ts = strtok(0, space);  // cx
                        cx = atof(ts);
                        ts = strtok(0, space);  // cy
                        cy = atof(ts);
                        ts = strtok(0, space);  // ax
                        ax = atof(ts);
                        ts = strtok(0, space);  // ay
                        ay = atof(ts);
                        m_path.curve3(cx, cy, ax, ay);
                    }

                    if(buf[0] == 'L')
                    {
                        ts = strtok(buf, space); // Line;
                        ts = strtok(0, space);  // ax
                        ax = atof(ts);
                        ts = strtok(0, space);  // ay
                        ay = atof(ts);
                        m_path.line_to(ax, ay);
                    }


                    if(buf[0] == '<')
                    {
                        // EndPath
                    }
                }
                return true;
            }
            return false;
        }


        unsigned operator [] (unsigned i) const 
        {
            return m_styles[i].path_id;
        }

        unsigned paths() const { return m_styles.size(); }
        const path_style& style(unsigned i) const
        {
            return m_styles[i];
        }

        void rewind(unsigned path_id)
        {
            m_trans.rewind(path_id);
        }

        unsigned vertex(double* x, double* y)
        {
            return m_trans.vertex(x, y);
        }

        double scale() const
        {
            return m_affine.scale();
        }

        void scale(double w, double h)
        {
            m_affine.reset();
            double x1, y1, x2, y2;
            bounding_rect(m_path, *this, 0, m_styles.size(), 
                          &x1, &y1, &x2, &y2);
            printf("%.3f %.3f %.3f %.3f\n", x1, y1, x2, y2);
            if(x1 < x2 && y1 < y2)
            {
                trans_viewport vp;                
                vp.preserve_aspect_ratio(0.5, 0.5, aspect_ratio_meet);                
                vp.world_viewport(x1, y1, x2, y2);
                vp.print();
                vp.device_viewport(0, 0, w, h);
                m_affine = vp.to_affine();
            }
            printf("%.3f\n", m_affine.scale());
            m_curve.approximation_scale(m_affine.scale());
        }

        void approximation_scale(double s)
        {
            m_curve.approximation_scale(m_affine.scale() * s);
        }

        int hit_test(double x, double y, double r)
        {
            m_affine.inverse_transform(&x, &y);
            r /= m_affine.scale();
            unsigned i;
            for(i = 0; i < m_path.total_vertices(); i++)
            {
                double vx, vy;
                unsigned cmd = m_path.vertex(i, &vx, &vy);
                if(is_vertex(cmd))
                {
                    if(calc_distance(x, y, vx, vy) <= r)
                    {
                        return i;
                    }
                }
            }
            return -1;
        }

        void modify_vertex(unsigned i, double x, double y)
        {
            m_affine.inverse_transform(&x, &y);
            m_path.modify_vertex(i, x, y);
        }

    private:
        path_storage                              m_path;
        trans_affine                              m_affine;
        conv_curve<path_storage>                  m_curve;
        conv_transform<conv_curve<path_storage> > m_trans;
        pod_bvector<path_style>                   m_styles;
        double                                    m_x1, m_y1, m_x2, m_y2;

        FILE* m_fd;
    };



    // Testing class, color provider and span generator
    //-------------------------------------------------
    class test_styles
    {
    public:
        test_styles(const rgba8* solid_colors, 
                    const rgba8* gradient) : 
            m_solid_colors(solid_colors),
            m_gradient(gradient)
        {}

        // Suppose that style=1 is a gradient
        //---------------------------------------------
        bool is_solid(unsigned style) const 
        { 
            return true;//style != 1; 
        }

        // Just returns a color
        //---------------------------------------------
        const rgba8& color(unsigned style) const 
        { 
            return m_solid_colors[style]; 
        }

        // Generate span. In our test case only one style (style=1)
        // can be a span generator, so that, parameter "style"
        // isn't used here.
        //---------------------------------------------
        void generate_span(rgba8* span, int x, int y, unsigned len, unsigned style)
        {
            memcpy(span, m_gradient + x, sizeof(rgba8) * len);
        }

    private:
        const rgba8* m_solid_colors;
        const rgba8* m_gradient;
    };

}

const int frameWidth = 655;
const int frameHeight = 520;
const int pixWidth = 3;
  
extern "C" {
  
void test_flash() {
  //agg::compound_shape cs;
  //cs.open("resources//shapes.txt");
  //cs.read_next();
  //cs.scale(frameWidth, frameHeight);
  
  agg::rgba8                 m_colors[100];
  agg::trans_affine          m_scale;
  agg::gamma_lut<>           m_gamma;
  
  m_gamma.gamma(2.0);

  unsigned i;
  
  //for(i = 0; i < 256; i++) {
  //  printf("%d\n", m_gamma.dir(i));
  //}
  
  for(i = 0; i < 100; i++)
  {
      m_colors[i] = agg::rgba8(
          (rand() & 0xFF), 
          (rand() & 0xFF), 
          (rand() & 0xFF), 
          230);

      //m_colors[i].apply_gamma_dir(m_gamma);
      //m_colors[i].premultiply();
      
      agg::rgba8 c = m_colors[i];
      printf("%d %d %d %d\n", c.r, c.g, c.b, c.a);
  }
    
}

}