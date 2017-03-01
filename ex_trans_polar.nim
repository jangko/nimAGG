import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_scanline_u, agg_renderer_scanline, agg_pixfmt_rgb, agg_trans_affine
import agg_conv_transform, agg_conv_segmentator, ctrl_slider, ctrl_cbox
import agg_renderer_base, agg_color_rgba, nimBMP, math

type
  TransformedControl[Ctrl, Pipeline] = object
    ctrl: Ctrl
    pipeline: ptr Pipeline
    
proc initTransformedControl[Ctrl, Pipeline](ctrl: Ctrl, 
  pl: var Pipeline): TransformedControl[Ctrl, Pipeline] =
  
  result.ctrl = ctrl
  result.pipeline = pl.addr
   
proc numPaths[C, P](self: TransformedControl[C, P]): int =
  self.ctrl.numPaths()
  
proc rewind[C, P](self: var TransformedControl[C, P], pathId: int) =
  self.pipeline[].rewind(pathId)
  
proc vertex[C, P](self: var TransformedControl[C, P], x, y: var float64): uint =
  self.pipeline[].vertex(x, y)
  
proc color[C, P](self: TransformedControl[C, P], i: int): auto =
  self.ctrl.color(i)

type
  TransPolar = object
    mBaseAngle: float64
    mBaseScale: float64
    mBaseX: float64
    mBaseY: float64
    mTranslationX: float64
    mTranslationY: float64
    mSpiral: float64

proc initTransPolar(): TransPolar =
  result.mBaseAngle = 1.0
  result.mBaseScale = 1.0
  result.mBaseX = 0.0
  result.mBaseY = 0.0
  result.mTranslationX = 0.0
  result.mTranslationY = 0.0
  result.mSpiral = 0.0

proc baseScale(self: var TransPolar, v: float64) =
  self.mBaseScale = v
  
proc fullCircle(self: var TransPolar, v: float64) =
  self.mBaseAngle = 2.0 * pi / v
  
proc baseOffset(self: var TransPolar, dx, dy: float64) =
  self.mBaseX = dx; self.mBaseY = dy
  
proc translation(self: var TransPolar, dx, dy: float64) =
  self.mTranslationX = dx
  self.mTranslationY = dy
  
proc spiral(self: var TransPolar, v: float64) =
  self.mSpiral = v

proc transform(self: TransPolar, x, y: var float64) =
  var 
    x1 = (x + self.mBaseX) * self.mBaseAngle
    y1 = (y + self.mBaseY) * self.mBaseScale + (x * self.mSpiral)
    
  x = cos(x1) * y1 + self.mTranslationX
  y = sin(x1) * y1 + self.mTranslationY
       
const
  frameWidth = 600
  frameHeight = 400
  flipY = true
  pixWidth = 3

type
  ValueT = uint8

type
  App = object
    slider1, spiral, baseY: SliderCtrl[Rgba8]
    
proc initApp(): App =
  result.slider1 = newSliderCtrl[Rgba8](10, 10,    600-10, 17, not flipY)
  result.spiral = newSliderCtrl[Rgba8](10, 10+20, 600-10, 17+20, not flipY)
  result.baseY = newSliderCtrl[Rgba8](10, 10+40, 600-10, 17+40, not flipY)
  result.slider1.setRange(0.0, 100.0)
  result.slider1.num_steps(5)
  result.slider1.value(32.0)
  result.slider1.label("Some Value=$1")
  result.spiral.label("Spiral=$1")
  result.spiral.setRange(-0.1, 0.1)
  result.spiral.value(0.0)
  result.baseY.label("Base Y=$1")
  result.baseY.setRange(50.0, 200.0)
  result.baseY.value(120.0)
  
proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixfmtRgb24(rbuf)
    rb     = initRendererBase(pixf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    width  = frameWidth.float64
    height = frameHeight.float64
  
  rb.clear(initRgba(1,1,1))
  renderCtrl(ras, sl, rb, app.slider1)
  renderCtrl(ras, sl, rb, app.spiral)
  renderCtrl(ras, sl, rb, app.baseY)
    
  var 
    trans = initTransPolar()
    
  trans.fullCircle(-600)
  trans.baseScale(-1.0)
  trans.baseOffset(0.0, app.baseY.value())
  trans.translation(width / 2.0, height / 2.0 + 30.0)
  trans.spiral(-app.spiral.value())

  var
    segm = initConvSegmentator(app.slider1)
    pipeline = initConvTransform(segm, trans)
    ctrl = initTransformedControl(app.slider1, pipeline)
  
  renderCtrl(ras, sl, rb, ctrl)
  saveBMP24("trans_polar.bmp", buffer, frameWidth, frameHeight)

onDraw()