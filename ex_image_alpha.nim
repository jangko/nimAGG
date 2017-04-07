import agg_ellipse, agg_trans_affine, agg_conv_transform, agg_rendering_buffer
import agg_pixfmt_rgb, agg_span_allocator, agg_span_image_filter_rgb
import agg_image_accessors, agg_span_interpolator_linear, agg_span_converter
import agg_scanline_u, agg_renderer_scanline, agg_rasterizer_scanline_aa
import ctrl_spline, agg_pixfmt_rgb, agg_color_rgba, agg_renderer_base, agg_basics
import nimBMP, random, strutils, os

const
  arraySize = 256 * 3
  
type
  SpanConvBrightnessAlphaRgb8 = object
    alphaArray: ptr uint8
    
proc initSpanConvBrightnessAlphaRgb8(alphaArray: ptr uint8): SpanConvBrightnessAlphaRgb8 =
  result.alphaArray = alphaArray

proc prepare(self: SpanConvBrightnessAlphaRgb8) = discard

proc generate(self: SpanConvBrightnessAlphaRgb8, span: ptr Rgba8, x, y, len: int) =
  var 
    len = len
    span = span
    
  doWhile len != 0:
    span.a = self.alphaArray[(span.r + span.g + span.b).int]
    inc span
    dec len
    
const
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    bmp: seq[BmpResult[string]]
    rbuf: seq[RenderingBuffer]
    alpha: SplineCtrl[Rgba8]
    x, y, rx, ry: array[50, float64]
    colors: array[50, Rgba8]
    
proc initApp(): App = 
  result.alpha = newSplineCtrl[Rgba8](2,  2,  200, 30,  6, not flipY)
  result.alpha.value(0, 1.0)
  result.alpha.value(1, 1.0)
  result.alpha.value(2, 1.0)
  result.alpha.value(3, 0.5)
  result.alpha.value(4, 0.5)
  result.alpha.value(5, 1.0)
  result.alpha.updateSpline()
        
  result.bmp = newSeq[BmpResult[string]](10)
  result.rbuf = newSeq[RenderingBuffer](10)

proc loadImage(app: var App, idx: int, name: string) =
  app.bmp[idx] = loadBMP24("resources$1$2.bmp" % [$DirSep, name])
  if app.bmp[idx].width == 0 and app.bmp[idx].width == 0:
    echo "failed to load $1.bmp" % [name]
    quit(0)
  app.rbuf[idx] = initRenderingBuffer(cast[ptr ValueT](app.bmp[idx].data[0].addr),
    app.bmp[idx].width, app.bmp[idx].height, app.bmp[idx].width * pixWidth)

proc rbufImage(app: var App, idx: int): var RenderingBuffer =
  result = app.rbuf[idx]
  
proc getBmp(app: var App, idx: int): var BmpResult[string] =
  app.bmp[idx]
  
proc init(app: var App, width, height: int) =
  for i in 0.. <50:
    app.x[i]  = random(width.float64)
    app.y[i]  = random(height.float64)
    app.rx[i] = random(60.0) + 10.0
    app.ry[i] = random(60.0) + 10.0
    app.colors[i] = initRgba8(random(0xFF), random(0xFF), random(0xFF), random(0xFF))
 
proc onDraw() =
  var app    = initApp()
  app.loadImage(0, "spheres")

  var    
    bmp    = app.getBmp(0)
    frameWidth  = bmp.width
    frameHeight = bmp.height
    initialWidth = frameWidth.float64
    initialHeight = frameHeight.float64
    
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    mtx    = initTransAffine()
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    
  app.init(frameWidth, frameHeight)
  rb.clear(initRgba(1.0, 1.0, 1.0))
  
  mtx *= transAffineTranslation(-initialWidth/2.0, -initialHeight/2.0)
  mtx *= transAffineRotation(10.0 * pi / 180.0)
  mtx *= transAffineTranslation(initialWidth/2.0, initialHeight/2.0)
  #mtx *= transAffine_resizing();

  var 
    brightnessAlphaArray: array[arraySize, uint8]
    colorAlpha = initSpanConvBrightnessAlphaRgb8(brightnessAlphaArray[0].addr)
    imgMtx  = mtx
    sa      = initSpanAllocator[Rgba8]()
    inter   = initSpanInterpolatorLinear(imgMtx)
    imgPixf = initPixfmtRgb24(app.rbufImage(0))
    imgSrc  = initImageAccessorClip(imgPixf, initRgba(0,0,0,0))
    sg      = initSpanImageFilterRgbBilinear(imgSrc, inter)
    sc      = initSpanConverter(sg, colorAlpha)
    ell     = initEllipse()
    
  imgMtx.invert()
    
  for i in 0.. <arraySize:
    brightnessAlphaArray[i] = (app.alpha.value(float64(i) / float(arraySize)) * 255.0).uint8

  for i in 0.. <50:
    ell.init(app.x[i], app.y[i], app.rx[i], app.ry[i], 50)
    ras.addPath(ell)
    renderScanlinesAAsolid(ras, sl, rb, app.colors[i])

  ell.init(initialWidth  / 2.0, 
           initialHeight / 2.0, 
           initialWidth  / 1.9, 
           initialHeight / 1.9, 200)

  var tr = initConvTransform(ell, mtx)
  
  ras.addPath(tr)
  renderScanlinesAA(ras, sl, rb, sa, sc)

  renderCtrl(ras, sl, rb, app.alpha)
        
  saveBMP24("image_alpha.bmp", buffer, frameWidth, frameHeight)

onDraw()