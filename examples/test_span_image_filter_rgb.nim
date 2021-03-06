import agg/[basics, pixfmt_rgb, color_rgba, renderer_base,
  rasterizer_scanline_aa, rendering_buffer, scanline_u,
  trans_affine, span_interpolator_linear, span_allocator,
  image_accessors, span_image_filter_rgb, renderer_scanline,
  image_filters]
import ctrl/rbox, nimBMP

const
  frameWidth = 500
  frameHeight = 340
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

const
  V = 255

let
  image = [0'u8,V,0, 0,0,V, V,V,V, V,0,0,
           V,0,0,    0,0,0, V,V,V, V,V,V,
           V,V,V,    V,V,V, 0,0,V, V,0,0,
           0,0,V,    V,V,V, 0,0,0, 0,V,0,]

type
  App = object
    filters: RboxCtrl[Rgba8]

proc initApp(): App =
  result.filters = newRboxCtrl[Rgba8](1, 1, 170.0, 150.0, not flipY)

  result.filters.addItem("NN")
  result.filters.addItem("Bilinear")
  result.filters.addItem("Bilinear Clip")
  result.filters.addItem("Gaussian")
  result.filters.addItem("Rgb2x2")
  result.filters.addItem("Rgb")
  result.filters.addItem("Affine")
  result.filters.curItem(0)

proc onDraw() =
  var
    app    = initApp()
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
    filter  = initImageFilter[ImageFilterKaiser]()

  ras.reset()
  ras.moveToD(para[0], para[1])
  ras.lineToD(para[2], para[3])
  ras.lineToD(para[4], para[5])
  ras.lineToD(para[6], para[7])
  rb.clear(initRgba(1, 1, 1))

  case app.filters.curItem()
  of 0:
    var sg = initSpanImageFilterRgbNN(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 1:
    var sg = initSpanImageFilterRgbBilinear(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 2:
    var sg = initSpanImageFilterRgbBilinearClip(pixf, initRgba8(0,1,0), inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 3:
    var sg = initSpanImageFilterRgb2x2(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 4:
    var sg = initSpanImageFilterRgb(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 5:
    var sg = initSpanImageResampleRgbAffine(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  else:
    discard
  renderCtrl(ras, sl, rb, app.filters)

  saveBMP24("test_span_image_filter_rgb.bmp", buffer, frameWidth, frameHeight)

onDraw()