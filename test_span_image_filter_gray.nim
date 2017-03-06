import agg_basics, agg_pixfmt_gray, agg_color_gray, agg_renderer_base
import agg_rasterizer_scanline_aa, agg_rendering_buffer, agg_scanline_u
import agg_trans_affine, agg_span_interpolator_linear, agg_span_allocator
import agg_image_accessors, agg_span_image_filter_gray, agg_renderer_scanline
import agg_image_filters, agg_pixfmt_rgb, agg_color_rgba
import agg_color_conv, agg_color_conv_rgb8, ctrl_rbox, nimBMP

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
  image = [0'u8,50,0,70,
           90,0,110,0,
           0,150,0,170,
           200,0,V,0]

type
  App = object
    filters: RboxCtrl[Rgba8]

proc initApp(): App =
  result.filters = newRboxCtrl[Rgba8](1, 1, 170.0, 150.0, not flipY)

  result.filters.addItem("NN")
  result.filters.addItem("Bilinear")
  result.filters.addItem("Bilinear Clip")
  result.filters.addItem("Gaussian")
  result.filters.addItem("Gray2x2")
  result.filters.addItem("Gray")
  result.filters.addItem("Affine")
  result.filters.curItem(0)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth)
    pf     = initPixFmtGray8(rbuf)
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()


    img    = initRenderingBuffer(cast[ptr ValueT](image[0].unsafeAddr), 4, 4, -4)
    para   = [200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0]
    mtx    = initTransAffine(para, 0, 0, 4, 4)
    inter  = initSpanInterpolatorLinear(mtx)
    sa     = initSpanAllocator[Gray8]()
    pixf   = initPixFmtGray8(img)
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
    var sg = initSpanImageFilterGrayNN(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 1:
    var sg = initSpanImageFilterGrayBilinear(source, inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 2:
    var sg = initSpanImageFilterGrayBilinearClip(pixf, initRgba8(0,1,0), inter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 3:
    var sg = initSpanImageFilterGray2x2(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 4:
    var sg = initSpanImageFilterGray(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  of 5:
    var sg = initSpanImageResampleGrayAffine(source, inter, filter)
    renderScanlinesAA(ras, sl, rb, sa, sg)
  else:
    discard
  renderCtrl(ras, sl, rb, app.filters)

  var
    target = newString(frameWidth * frameHeight * pixWidth)
    rbuf2  = initRenderingBuffer(cast[ptr ValueT](target[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)

  colorConv(rbuf2, rbuf, color_conv_gray8_to_rgb24)
  saveBMP24("test_span_image_filter_gray.bmp", target, frameWidth, frameHeight)

onDraw()