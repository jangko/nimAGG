var subjects = [
  "ex_aa_demo",
  "ex_aa_test",
  "ex_alpha_gradient",
  "ex_alpha_mask",
  "ex_alpha_mask2",
  "ex_alpha_mask3",
  "ex_bezier_div",
  "ex_blend_color",
  "ex_blur",
  "ex_bspline",
  "ex_circles",
  "ex_component_rendering",
  "ex_compositing",
  "ex_compositing2",
  "ex_conv_contour",
  "ex_conv_dash_marker",
  "ex_conv_stroke",
  "ex_distortions",
  "ex_flash_rasterizer",
  "ex_flash_rasterizer2",
  "ex_gamma_correction",
  "ex_gamma_ctrl",
  "ex_gamma_tuner",
  "ex_gouraud",
  "ex_gouraud_mesh",
  "ex_gradient_focal",
  "ex_graph_test",
  "ex_idea",
  "ex_image1",
  "ex_image_alpha",
  "ex_image_filters",
  "ex_image_filters2",
  "ex_image_filter_graph",
  "ex_image_perspective",
  "ex_image_resample",
  "ex_image_transform",
  "ex_line_patterns",
  "ex_line_patterns_clip",
  "ex_lion",
  "ex_lion_lens",
  "ex_lion_outline",
  "ex_logo",
  "ex_mol_view",
  "ex_multi_clip",
  "ex_pattern_fill",
  "ex_pattern_perspective",
  "ex_pattern_resample",
  "ex_perspective",
  "ex_pixfmt",
  "ex_pixfmt16",
  "ex_polymorphic_renderer",
  "ex_rasterizers",
  "ex_rasterizers2",
  "ex_rasterizer_compound",
  "ex_raster_text",
  "ex_rounded_rect",
  "ex_scanline_boolean",
  "ex_scanline_boolean2",
  "ex_simple_blur",
  "ex_trans_polar",
  "test_blender_test",
  "test_color_test",
  "test_pixfmt_test",
  "test_renderer_base",
  "test_span_image_filter_gray",
  "test_span_image_filter_rgb",
  "test_span_image_filter_rgba",
  "t01_rendering_buffer",
  "t02_rendering_buffer",
  "t03_rendering_buffer",
  "t04_rendering_buffer",
  "ex_svg_circle",
  "ex_gradients_contour",
  "ex_particle_demo",
  "ex_test_poly_bool",
  "ex_poly_bool",
  "ex_gradients"]

when defined(windows):
  subjects.add "ex_trans_curve1"
  subjects.add "ex_trans_curve2"
  subjects.add "ex_truetype_test"
  
mode = ScriptMode.Silent

import strutils

var switches = ""

proc addSwitch(sw: string) =
  switches.add " --"
  switches.add sw

when defined(release):
  addSwitch("define:release")

when not defined(cpu64):
  addSwitch("cpu:i386")

for c in subjects:
  echo c
  exec "nim c --verbosity:0 --hints:off $1 $2" % [switches, c]
  when defined(windows):
    exec c
  else:
    exec "./" & c
