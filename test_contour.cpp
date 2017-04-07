#include "agg_basics.h"
#include "agg_path_storage.h"
#include "agg_trans_perspective.h"
#include "agg_pixfmt_rgb.h"
#include "agg_rendering_buffer.h"
#include "agg_span_gradient_contour.h"
#include "agg_bounding_rect.h"

template<class VertexSource>
unsigned char* perform_rendering(VertexSource& vs) {
  double x1,y1,x2,y2;

  if(!agg::bounding_rect_single(vs ,0 ,&x1 ,&y1 ,&x2 ,&y2 )) return NULL;

  // Init Basic Transformations
  double scale = (520 - 120 ) / (x2 - x1 );
  if (scale > (520 - 120 ) / (y2 - y1 ) ) {
    scale = (520 - 120 ) / (y2 - y1 );
  }

  agg::trans_affine mtx;
  mtx *= agg::trans_affine_translation(-x1, -y1);
  mtx *= agg::trans_affine_scaling(scale, scale);
  agg::conv_transform<VertexSource> t1(vs, mtx);
  agg::trans_affine_translation tat(100, 105);

  // Create Path
  agg::path_storage path;
  path.concat_path(t1 );

  agg::gradient_contour gradient_func;

  gradient_func.frame(0 );
  gradient_func.d1(0);
  gradient_func.d2(512);
  return gradient_func.contour_create(&path );  
}
 
extern "C" {

    
unsigned char* test_contour() {
  agg::path_storage star;
  star.move_to(12.0 ,40.0 );
  star.line_to(52.0 ,40.0 );
  star.line_to(72.0 ,6.0 );
  star.line_to(92.0 ,40.0 );
  star.line_to(132.0 ,40.0 );
  star.line_to(112.0 ,76.0 );
  star.line_to(132.0 ,112.0 );
  star.line_to(92.0 ,112.0 );
  star.line_to(72.0 ,148.0 );
  star.line_to(52.0 ,112.0 );
  star.line_to(12.0 ,112.0 );
  star.line_to(32.0 ,76.0 );
  star.close_polygon();
  
  return perform_rendering(star);
}

}