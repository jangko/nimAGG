import agg/[basics, pixfmt_rgb, color_rgba, renderer_base,
  rasterizer_scanline_aa, rendering_buffer, scanline_u,
  trans_affine, span_interpolator_linear, span_allocator,
  image_accessors, span_image_filter_rgba, renderer_scanline,
  image_filters, pixfmt_rgba, color_conv_rgb8]
import nimBMP, ctrl/rbox

const
  frameWidth = 500
  frameHeight = 340
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

const
  V = 255

let
  image = [0'u8,V,0,V,  0,0,V,V,  V,V,V,V,  V,0,0,V,
           V,0,0,V,  0,0,0,V,  V,V,V,V,  V,V,V,V,
           V,V,V,V,  V,V,V,V,  0,0,V,V,  V,0,0,V,
           0,0,V,V,  V,V,V,V,  0,0,0,V,  0,V,0,V]

type
  App = object
    filters: RboxCtrl[Rgba8]

proc initApp(): App =
  result.filters = newRboxCtrl[Rgba8](1, 1, 170.0, 150.0, not flipY)

  result.filters.addItem("NN")
  result.filters.addItem("Bilinear")
  result.filters.addItem("Bilinear Clip")
  result.filters.addItem("Gaussian")
  result.filters.addItem("Rgba2x2")
  result.filters.addItem("Rgba")
  result.filters.addItem("Affine")
  result.filters.curItem(0)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgba32(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

    img    = initRenderingBuffer(cast[ptr ValueT](image[0].unsafeAddr), 4, 4, 4*4)
    para   = [200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0]
    mtx    = initTransAffine(para, 0, 0, 4, 4)
    inter  = initSpanInterpolatorLinear(mtx)
    sa     = initSpanAllocator[Rgba8]()
    pixf   = initPixFmtRgba32(img)
    source = initImageAccessorClone(pixf)
    filter  = initImageFilter[ImageFilterGaussian]()

  ras.reset()
  ras.moveToD(para[0], para[1])
  ras.lineToD(para[2], para[3])
  ras.lineToD(para[4], para[5])
  ras.lineToD(para[6], para[7])
  rb.clear(initRgba(1, 1, 1))

  case app.filters.curItem()
  of 0:
    var sg = initSpanImageFilterRgbaNN(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 1:
    var sg = initSpanImageFilterRgbaBilinear(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 2:
    var sg = initSpanImageFilterRgbaBilinearClip(pixf, initRgba8(0,255,0), inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 3:
    var sg = initSpanImageFilterRgba2x2(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 4:
    var sg = initSpanImageFilterRgba(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 5:
    var sg = initSpanImageResampleRgbaAffine(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  else:
    discard

  renderCtrl(ras, sl, rb, app.filters)
  saveBMP32("test_span_image_filter_rgba.bmp", buffer, frameWidth, frameHeight)

onDraw()