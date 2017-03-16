const subjects = [
  "ex_aa_demo.nim",
  "ex_aa_test.nim",
  "ex_alpha_gradient.nim",
  "ex_alpha_mask.nim",
  "ex_alpha_mask2.nim",
  "ex_alpha_mask3.nim",
  "ex_bezier_div.nim",
  "ex_blend_color.nim",
  "ex_blur.nim",
  "ex_bspline.nim",
  "ex_circles.nim",
  "ex_component_rendering.nim",
  "ex_compositing.nim",
  "ex_compositing2.nim",
  "ex_conv_contour.nim",
  "ex_conv_dash_marker.nim",
  "ex_conv_stroke.nim",
  "ex_distortions.nim",
  "ex_flash_rasterizer.nim",
  "ex_flash_rasterizer2.nim",
  "ex_gamma_correction.nim",
  "ex_gamma_ctrl.nim",
  "ex_gamma_tuner.nim",
  "ex_gouraud.nim",
  "ex_gouraud_mesh.nim",
  "ex_gradient_focal.nim",
  "ex_graph_test.nim",
  "ex_idea.nim",
  "ex_image1.nim",
  "ex_image_alpha.nim",
  "ex_image_filters.nim",
  "ex_image_filters2.nim",
  "ex_image_filter_graph.nim",
  "ex_image_perspective.nim",
  "ex_image_resample.nim",
  "ex_image_transform.nim",
  "ex_line_patterns.nim",
  "ex_line_patterns_clip.nim",
  "ex_lion.nim",
  "ex_lion_lens.nim",
  "ex_lion_outline.nim",
  "ex_logo.nim",
  "ex_mol_view.nim",
  "ex_multi_clip.nim",
  "ex_pattern_fill.nim",
  "ex_pattern_perspective.nim",
  "ex_pattern_resample.nim",
  "ex_perspective.nim",
  "ex_pixfmt.nim",
  "ex_pixfmt16.nim",
  "ex_polymorphic_renderer.nim",
  "ex_rasterizers.nim",
  "ex_rasterizers2.nim",
  "ex_rasterizer_compound.nim",
  "ex_raster_text.nim",
  "ex_rounded_rect.nim",
  "ex_scanline_boolean.nim",
  "ex_scanline_boolean2.nim",
  "ex_simple_blur.nim",
  "ex_trans_polar.nim",
  "test_blender_test.nim",
  "test_color_test.nim",
  "test_pixfmt_test.nim",
  "test_renderer_base.nim",
  "test_span_image_filter_gray.nim",
  "test_span_image_filter_rgb.nim",
  "test_span_image_filter_rgba.nim",
  "test_text.nim",
  "t01_rendering_buffer.nim",
  "t02_rendering_buffer.nim",
  "t03_rendering_buffer.nim",
  "t04_rendering_buffer.nim"]

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
  exec "nim c -d:release --verbosity:0 --hints:off $1 $2" % [switches, c]

exec "test_color_conv.bat"