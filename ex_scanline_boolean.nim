import agg_basics, agg_array, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_scanline_p, agg_scanline_u, agg_scanline_bin, agg_scanline_boolean_algebra
import agg_scanline_storage_aa, agg_scanline_storage_bin, agg_renderer_scanline
import agg_path_storage, agg_conv_transform, agg_ellipse, agg_gamma_functions
import ctrl_rbox, ctrl_cbox, ctrl_slider, ctrl_polygon, agg_scanline_u
import agg_renderer_base, agg_color_rgba, agg_pixfmt_rgb
import nimBMP

const
  frameWidth = 800
  frameHeight = 600
  flipY = true
  pixWidth = 3

type
  ValueT = uint8

proc generateCircles(ps: var PathStorage, quad: openArray[float64], numCircles: int, radius: float64) =
  ps.removeAll()
  for i in 0.. <4:
    let
      n1 = i * 2
      n2 = if i < 3: i * 2 + 2 else: 0

    for j in 0.. <numCircles:
      var ell = initEllipse(quad[n1]+ (quad[n2] - quad[n1]) * j.float64 / numCircles.float64, 
                            quad[n1 + 1] + (quad[n2 + 1] - quad[n1 + 1]) * j.float64 / numCircles.float64, 
                            radius, radius, 100)
      ps.concatPath(ell)

type
  App = object
    quad1: PolygonCtrl[Rgba8]
    quad2: PolygonCtrl[Rgba8]
    transType: RboxCtrl[Rgba8]
    reset: CboxCtrl[Rgba8]
    mul1: SliderCtrl[Rgba8]
    mul2: SliderCtrl[Rgba8]
    
proc initApp(): App =
  result.quad1 = newPolygonCtrl[Rgba8](4, 5.0)
  result.quad2 = newPolygonCtrl[Rgba8](4, 5.0)
  result.transType = newRboxCtrl[Rgba8](420, 5.0, 420+130.0, 145.0, not flipY)
  result.reset = newCboxCtrl[Rgba8](350, 5.0,  "Reset", not flipY)
  result.mul1 = newSliderCtrl[Rgba8](5.0,  5.0, 340.0, 12.0, not flipY)
  result.mul2 = newSliderCtrl[Rgba8](5.0, 20.0, 340.0, 27.0, not flipY)
  result.trans_type.addItem("Union")
  result.trans_type.addItem("Intersection")
  result.trans_type.addItem("Linear XOR")
  result.trans_type.addItem("Saddle XOR")
  result.trans_type.addItem("Abs Diff XOR")
  result.trans_type.addItem("A-B")
  result.trans_type.addItem("B-A")
  result.trans_type.curItem(0)
  result.mul1.value(1.0)
  result.mul2.value(1.0)
  result.mul1.label("Opacity1=$1")
  result.mul2.label("Opacity2=$1")
  
  var
    width  = frameWidth.float64
    height = frameHeight.float64
    
  result.quad1.xn(0) = 50.0
  result.quad1.yn(0) = 200.0 - 20.0
  result.quad1.xn(1) = width / 2.0 - 25.0
  result.quad1.yn(1) = 200;
  result.quad1.xn(2) = width / 2.0 - 25.0
  result.quad1.yn(2) = height - 50.0 - 20.0
  result.quad1.xn(3) = 50.0
  result.quad1.yn(3) = height - 50.0

  result.quad2.xn(0) = width / 2.0 + 25.0
  result.quad2.yn(0) = 200.0 - 20.0
  result.quad2.xn(1) = width - 50.0
  result.quad2.yn(1) = 200.0
  result.quad2.xn(2) = width - 50.0
  result.quad2.yn(2) = height - 50.0 - 20.0
  result.quad2.xn(3) = width / 2.0 + 25.0
  result.quad2.yn(3) = height - 50.0
        
proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf   = initPixfmtRgb24(rbuf)
    rb     = initRendererBase(pixf)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    ras1   = initRasterizerScanlineAA()
    ras2   = initRasterizerScanlineAA()
    ren    = initRendererScanlineAAsolid(rb)
    width  = frameWidth.float64
    height = frameHeight.float64
    op     = SboolOp(app.transType.curItem())
    gm1    = initGammaMultiply(app.mul1.value())
    gm2    = initGammaMultiply(app.mul2.value())
    path1  = initPathStorage()
    path2  = initPathStorage()
    
  rb.clear(initRgba(1, 1, 1))
  ras1.gamma(gm1)
  ras2.gamma(gm2)
  ras.clipBox(0, 0, width, height)
  
  generateCircles(path1, app.quad1.polygon(), 5, 20.0)
  generateCircles(path2, app.quad2.polygon(), 5, 20.0)

  ras1.fillingRule(fillEvenOdd)

  ren.color(initRgba8(240, 255, 200, 100))
  ras1.addPath(path1)
  renderScanlines(ras1, sl, ren)

  ren.color(initRgba8(255, 240, 240, 100))
  ras2.addPath(path2)
  renderScanlines(ras2, sl, ren)

  var
    slResult = initScanlineU8()
    sl1      = initScanlineU8()
    sl2      = initScanlineU8()
    sren     = initRendererScanlineAASolid(rb)
        
  sren.color(initRgba8(0, 0, 0))
  sboolCombineShapesAA(op, ras1, ras2, sl1, sl2, slResult, sren)
        
  # Render the "quad" tools and controls
  ren.color(initRgba(0, 0.3, 0.5, 0.6))
  ras.addPath(app.quad1)
  renderScanlines(ras, sl, ren)
  ras.addPath(app.quad2)
  renderScanlines(ras, sl, ren)
  renderCtrl(ras, sl, rb, app.transType)
  renderCtrl(ras, sl, rb, app.reset)
  renderCtrl(ras, sl, rb, app.mul1)
  renderCtrl(ras, sl, rb, app.mul2)
  
  saveBMP24("scanline_boolean.bmp", buffer, frameWidth, frameHeight)

onDraw()