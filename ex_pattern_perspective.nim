import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_trans_affine
import agg_trans_bilinear, agg_trans_perspective, agg_span_interpolator_linear
import agg_span_interpolator_trans, agg_span_allocator, agg_image_accessors
import ctrl_rbox, ctrl_polygon, agg_pixfmt_rgb, agg_span_image_filter_rgb
import agg_renderer_base, agg_color_rgba, nimBMP, strutils, os, math
import agg_image_filters

const
  frameWidth = 600
  frameHeight = 600
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object 
    quad: PolygonCtrl[Rgba8]
    transType: RboxCtrl[Rgba8]
    testFlag: bool
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    x1, y1, x2, y2: float64
    bmp: seq[BmpResult]
    rbuf: seq[RenderingBuffer]
    
proc initApp(): App =
  result.quad = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](460, 5.0, 420+170.0, 60.0, not flipY)
  result.testFlag = false
  result.transType.textSize(8)
  result.transType.textThickness(1)
  result.transType.addItem("Affine")
  result.transType.addItem("Bilinear")
  result.transType.addItem("Perspective")
  result.transType.curItem(2)
  
  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()
  result.x1  = -150.0
  result.y1  = -150.0
  result.x2  = 150.0
  result.y2  = 150.0
  
  var
    trans_x1 = -200.0
    trans_y1 = -200.0
    trans_x2 =  200.0
    trans_y2 =  200.0
    dx = frameWidth.float64  / 2.0 - (trans_x2 + trans_x1) / 2.0
    dy = frameHeight.float64 / 2.0 - (trans_y2 + trans_y1) / 2.0
    
  result.quad.xn(0) = floor(trans_x1 + dx)
  result.quad.yn(0) = floor(trans_y1 + dy)
  result.quad.xn(1) = floor(trans_x2 + dx)
  result.quad.yn(1) = floor(trans_y1 + dy)
  result.quad.xn(2) = floor(trans_x2 + dx)
  result.quad.yn(2) = floor(trans_y2 + dy)
  result.quad.xn(3) = floor(trans_x1 + dx)
  result.quad.yn(3) = floor(trans_y2 + dy)
  result.bmp = newSeq[BmpResult](10)
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
  
proc getBmp(app: var App, idx: int): var BmpResult =
  app.bmp[idx]

spanInterpolatorLinear(SpanInterpolatorBilinear, TransBilinear, 8)
spanInterpolatorLinear(SpanInterpolatorPerspective, TransPerspective, 8)
  
proc onDraw() =
  var 
    app    = initApp()
    buffer  = newString(frameWidth * frameHeight * pixWidth)
    rbuf    = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    width   = frameWidth.float64
    height  = frameHeight.float64
    pixf    = initPixfmtRgb24(rbuf)
    pixfPre = initPixfmtRgb24Pre(rbuf)
    rb      = initRendererBase(pixf)
    rbPre   = initRendererBase(pixfPre)    
  
  app.loadImage(0, "agg")
   
  if not app.testFlag:
    rb.clear(initRgba(1, 1, 1))
  
  if app.transType.curItem() == 0:
    # For the affine parallelogram transformations we
    # calculate the 4-th (implicit) point of the parallelogram
    app.quad.xn(3) = app.quad.xn(0) + (app.quad.xn(2) - app.quad.xn(1))
    app.quad.yn(3) = app.quad.yn(0) + (app.quad.yn(2) - app.quad.yn(1))
  
  if not app.testFlag:
    # Render the "quad" tool and controls
    app.ras.addPath(app.quad)
    renderScanlinesAAsolid(app.ras, app.sl, rb, initRgba(0, 0.3, 0.5, 0.6))
    renderCtrl(app.ras, app.sl, rb, app.transType)
  
  # Prepare the polygon to rasterize. Here we need to fill
  # the destination (transformed) polygon.
  app.ras.clipBox(0, 0, width, height)
  app.ras.reset()
  app.ras.moveToD(app.quad.xn(0), app.quad.yn(0))
  app.ras.lineToD(app.quad.xn(1), app.quad.yn(1))
  app.ras.lineToD(app.quad.xn(2), app.quad.yn(2))
  app.ras.lineToD(app.quad.xn(3), app.quad.yn(3))
    
  type
    RemainderT = WrapModeReflectAutoPow2
    
  var
    sa = initSpanAllocator[Rgba8]()
    filter  = initImageFilter[ImageFilterHanning]()
    imgPixf = initPixfmtRgb24(app.rbufImage(0))
    imgSrc  = initImageAccessorWrap[PixFmtRgb24, RemainderT, RemainderT](imgPixf)
    
  const
    subdivShift = 2
  
  case app.transType.curItem()
  of 0:
    # Note that we consruct an affine matrix that transforms
    # a parallelogram to a rectangle, i.e., it's inverted.
    # It's actually the same as:
    # tr(app.x1, app.y1, app.x2, app.y2, m_triangle.polygon());
    # tr.invert();
    var
      mtx   = initTransAffine(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2)
      inter = initSpanInterpolatorLinear(mtx)
      sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
  
    # Also note that we can use the linear interpolator instead of 
    # arbitrary span_interpolator_trans. It works much faster, 
    # but the transformations must be linear and parellel.
    renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
    
  of 1:
    var mtx = initTransBilinear(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2);
    if mtx.isValid():
      var
        inter = initSpanInterpolatorBilinear(mtx)
        sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
      
  of 2:
    var mtx = initTransPerspective(app.quad.polygon(), app.x1, app.y1, app.x2, app.y2);
    if mtx.isValid():
      var
        inter = initSpanInterpolatorPerspective(mtx)
        sg    = initSpanImageFilterRgb2x2(imgSrc, inter, filter)
      renderScanlinesAA(app.ras, app.sl, rbPre, sa, sg)
  else:
    discard
        
  saveBMP24("pattern_perspective.bmp", buffer, frameWidth, frameHeight)

onDraw()