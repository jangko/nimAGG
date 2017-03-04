import agg_basics, agg_pixfmt_rgb, agg_color_rgba, agg_renderer_base
import agg_rasterizer_scanline_aa, agg_rendering_buffer, agg_scanline_u
import agg_trans_affine, agg_span_interpolator_linear, agg_span_allocator
import agg_image_accessors, agg_span_image_filter_rgb, agg_renderer_scanline
import agg_image_filters
import nimBMP

const
  frameWidth = 500
  frameHeight = 340
  pixWidth = 3

type
  ValueT = uint8

const
  V = 255

#let
#  image = [0'u8,V,0,V,  0,0,V,V,  V,V,V,V,  V,0,0,V,
#           V,0,0,V,  0,0,0,V,  V,V,V,V,  V,V,V,V,
#           V,V,V,V,  V,V,V,V,  0,0,V,V,  V,0,0,V,
#           0,0,V,V,  V,V,V,V,  0,0,0,V,  0,V,0,V]

let
  image = [0'u8,V,0, 0,0,V, V,V,V, V,0,0,
           V,0,0,    0,0,0, V,V,V, V,V,V,
           V,V,V,    V,V,V, 0,0,V, V,0,0,
           0,0,V,    V,V,V, 0,0,0, 0,V,0,]

{.passC: "-I./agg-2.5/include".}
{.compile: "test_span.cpp".}
{.compile: "agg_trans_affine2.cpp".}
{.compile: "agg_image_filters2.cpp".}
{.passL: "-lstdc++".}

proc test_span(): cstring {.importc.}
proc free_buffer(b: cstring) {.importc.}

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)    
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    
    
    img    = initRenderingBuffer(cast[ptr ValueT](image[0].unsafeAddr), 4, 4, 4*3)
    para   = [200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0]
    mtx    = initTransAffine(para, 0, 0, 4, 4)
    inter  = initSpanInterpolatorLinear(mtx)
    sa     = initSpanAllocator[Rgba8]()
    pixf   = initPixFmtRgb24(img)
    source = initImageAccessorClone(pixf)
    #sg     = initSpanImageFilterRgbNN(source, inter)
    #sg     = initSpanImageFilterRgbBilinear(source, inter)
    #sg     = initSpanImageFilterRgbBilinearClip(pixf, initRgba8(0,1,0), inter)
    filter  = initImageFilter[ImageFilterKaiser]()
    #sg      = initSpanImageFilterRgb2x2(source, inter, filter)
    #sg      = initSpanImageFilterRgb(source, inter, filter)
    sg      = initSpanImageResampleRgbAffine(source, inter, filter)
    
  ras.reset()
  ras.moveToD(para[0], para[1])
  ras.lineToD(para[2], para[3])
  ras.lineToD(para[4], para[5])
  ras.lineToD(para[6], para[7])
  rb.clear(initRgba(1, 1, 1))
  
  renderScanlinesAA(ras, sl, rb, sa, sg)

  #echo "----"
  #var buf = test_span();
  #copyMem(buffer.cstring, buf, buffer.len)
  saveBMP24("test_span_image.bmp", buffer, frameWidth, frameHeight)
  #free_buffer(buf)

onDraw()