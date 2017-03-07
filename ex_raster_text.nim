import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_pixfmt_rgb, agg_span_allocator, agg_span_gradient
import agg_span_interpolator_linear, agg_glyph_raster_bin, agg_renderer_raster_text
import agg_embedded_raster_fonts, ctrl_slider, ctrl_cbox, nimBMP, math
import agg_renderer_base, agg_color_rgba, agg_trans_affine

const
  frameWidth = 640
  frameHeight = 480
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  GradientSineRepeatAdaptor[GradientF] = object
    mgradient: GradientF
    mPeriods: float64

proc initGradientSineRepeatAdaptor[G](): GradientSineRepeatAdaptor[G] =
  result.mPeriods = pi * 2.0

proc periods[G](self: var GradientSineRepeatAdaptor[G], p: float64) =
  self.mPeriods = p * pi * 2.0

proc calculate[G](self: var GradientSineRepeatAdaptor[G], x, y, d: int): int =
  result = int((1.0 + sin(self.mGradient.calculate(x, y, d).float64 * self.mPeriods / d.float64)) * d.float64/2)

let
  fonts = [
    (font: gse4x6[0].unsafeAddr,               name: "gse4x6"               ),
    (font: gse4x8[0].unsafeAddr,               name: "gse4x8"               ),
    (font: gse5x7[0].unsafeAddr,               name: "gse5x7"               ),
    (font: gse5x9[0].unsafeAddr,               name: "gse5x9"               ),
    (font: gse6x9[0].unsafeAddr,               name: "gse6x9"               ),
    (font: gse6x12[0].unsafeAddr,              name: "gse6x12"              ),
    (font: gse7x11[0].unsafeAddr,              name: "gse7x11"              ),
    (font: gse7x11_bold[0].unsafeAddr,         name: "gse7x11_bold"         ),
    (font: gse7x15[0].unsafeAddr,              name: "gse7x15"              ),
    (font: gse7x15_bold[0].unsafeAddr,         name: "gse7x15_bold"         ),
    (font: gse8x16[0].unsafeAddr,              name: "gse8x16"              ),
    (font: gse8x16_bold[0].unsafeAddr,         name: "gse8x16_bold"         ),
    (font: mcs11_prop[0].unsafeAddr,           name: "mcs11_prop"           ),
    (font: mcs11_prop_condensed[0].unsafeAddr, name: "mcs11_prop_condensed" ),
    (font: mcs12_prop[0].unsafeAddr,           name: "mcs12_prop"           ),
    (font: mcs13_prop[0].unsafeAddr,           name: "mcs13_prop"           ),
    (font: mcs5x10_mono[0].unsafeAddr,         name: "mcs5x10_mono"         ),
    (font: mcs5x11_mono[0].unsafeAddr,         name: "mcs5x11_mono"         ),
    (font: mcs6x10_mono[0].unsafeAddr,         name: "mcs6x10_mono"         ),
    (font: mcs6x11_mono[0].unsafeAddr,         name: "mcs6x11_mono"         ),
    (font: mcs7x12_mono_high[0].unsafeAddr,    name: "mcs7x12_mono_high"    ),
    (font: mcs7x12_mono_low[0].unsafeAddr,     name: "mcs7x12_mono_low"     ),
    (font: verdana12[0].unsafeAddr,            name: "verdana12"            ),
    (font: verdana12_bold[0].unsafeAddr,       name: "verdana12_bold"       ),
    (font: verdana13[0].unsafeAddr,            name: "verdana13"            ),
    (font: verdana13_bold[0].unsafeAddr,       name: "verdana13_bold"       ),
    (font: verdana14[0].unsafeAddr,            name: "verdana14"            ),
    (font: verdana14_bold[0].unsafeAddr,       name: "verdana14_bold"       ),
    (font: verdana16[0].unsafeAddr,            name: "verdana16"            ),
    (font: verdana16_bold[0].unsafeAddr,       name: "verdana16_bold"       ),
    (font: verdana17[0].unsafeAddr,            name: "verdana17"            ),
    (font: verdana17_bold[0].unsafeAddr,       name: "verdana17_bold"       ),
    (font: verdana18[0].unsafeAddr,            name: "verdana18"            ),
    (font: verdana18_bold[0].unsafeAddr,       name: "verdana18_bold"       )]

proc onDraw() =
  var
    glyph  = initGlyphRasterBin(nil)
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixfmtRgb24(rbuf)
    rb     = initRendererBase(pixf)
    rt     = initRendererRasterHtextSolid(rb, glyph)

  rb.clear(initRgba(1,1,1))

  var
    y = 5.0

  rt.color(initRgba(0,0,0))
  for font in fonts:
    let buf = "A quick brown fox jumps over the lazy dog 0123456789: " & font.name

    glyph.font(font.font)
    rt.renderText(5, y, buf, not flipY)
    y += glyph.height() + 1

  # Rendering raster text with a custom span generator, gradient
  var
    mtx = initTransAffine()
    gradFunc = initGradientSineRepeatAdaptor[GradientCircle]()
    colorFunc = initGradientLinearColor[Rgba8]()
    inter = initSpanInterpolatorLinear(mtx)
    sa = initSpanAllocator[Rgba8]()
    sg = initSpanGradient(inter, gradFunc, colorFunc, 0, 150.0)
    ren = initRendererScanlineAA(rb, sa, sg)
    rt2 = initRendererRasterHtext(ren, glyph)

  gradFunc.periods(5.0)
  colorFunc.colors(initRgba(1.0,0,0), initRgba(0,0.5,0))

  var buf = "RADIAL REPEATING GRADIENT: A quick brown fox jumps over the lazy dog"
  rt2.renderText(5, 465, buf, not flipY)

  saveBMP24("raster_text.bmp", buffer, frameWidth, frameHeight)

onDraw()