import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_ellipse
import agg_trans_affine, agg_conv_transform, agg_span_image_filter_rgb
import agg_span_image_filter_rgba, agg_span_image_filter_gray, agg_pixfmt_rgb
import agg_scanline_u, agg_renderer_scanline, agg_span_allocator, agg_span_interpolator_linear
import agg_image_accessors, agg_basics, agg_renderer_base, nimBMP
import agg_trans_affine, os, agg_color_rgba, agg_image_filters

const
  pixWidth = 3
  mAngle = 35.0
  mScale = 1.0

type
  ValueT = uint8

proc onDraw() =
  var
    bmp         = loadBMP24("resources" & DirSep & "spheres.bmp")
    rbuf1       = initRenderingBuffer(cast[ptr ValueT](bmp.data[0].addr), bmp.width, bmp.height, -bmp.width * pixWidth)
    frameWidth  = bmp.width + 20
    frameHeight = bmp.height + 20
    buffer      = newString(frameWidth * frameHeight * pixWidth)
    rbuf        = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)

    pixf        = initPixfmtRgb24(rbuf)
    pixfPre     = initPixfmtRgb24Pre(rbuf)

    rb          = initRendererBase(pixf)
    rbPre       = initRendererBase(pixfPre)

    srcMtx      = initTransAffine()
    imgMtx      = initTransAffine()

    width       = frameWidth.float64
    height      = frameHeight.float64

    sa          = initSpanAllocator[Rgba8]()
    inter       = initSpanInterpolatorLinear(imgMtx)

    imgPixf     = initPixfmtRgb24(rbuf1)
    imgSrc      = initImageAccessorClip(imgPixf, rgbaPre(0, 0.4, 0, 0.5))

    filter      = initImageFilter[ImageFilterSpline36]()
    sg          = initSpanImageFilterRgb(imgSrc, inter, filter)

    ras         = initRasterizerScanlineAA()
    sl          = initScanlineU8()
    r           = width

  rb.clear(initRgba(1.0, 1.0, 1.0))

  srcMtx *= transAffineTranslation(-width/2.0 - 10.0, -height/2.0 - 20.0 - 10.0)
  srcMtx *= transAffineRotation(mAngle * pi / 180.0)
  srcMtx *= transAffineScaling(mScale)
  srcMtx *= transAffineTranslation(width/2.0, height/2.0 + 20.0)
  #srcMtx *= trans_affine_resizing()

  imgMtx *= transAffineTranslation(-width/2.0 + 10.0, -height/2.0 + 20.0 + 10.0)
  imgMtx *= transAffineRotation(mAngle * pi / 180.0)
  imgMtx *= transAffineScaling(mScale)
  imgMtx *= transAffineTranslation(width/2.0, height/2.0 + 20.0)
  #imgMtx *= trans_affine_resizing();
  imgMtx.invert()

  ras.clipBox(0, 0, width, height)
  if height - 60 < r:
    r = height - 60

  var
    ell = initEllipse(width  / 2.0 + 10,
                       height / 2.0 + 20 + 10,
                       r / 2.0 + 16.0,
                       r / 2.0 + 16.0, 200)
    tr  = initConvTransform(ell, srcMtx)

  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rbPre, sa, sg)
  saveBMP24("image1.bmp", buffer, frameWidth, frameHeight)

onDraw()