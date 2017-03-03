import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_gsv_text, agg_conv_stroke, agg_path_storage
import agg_renderer_base, agg_color_rgba, nimBMP, agg_ellipse
import agg_pixfmt_rgb, agg_trans_affine, agg_conv_transform, agg_basics
import ctrl_rbox, ctrl_slider, agg_gamma_lut, math

const
  frameWidth = 500
  frameHeight = 500
  flipY = true
  pixWidth = 3

type
  ValueT = uint8

type
  App = object
    pattern: RboxCtrl[Rgba8]
    gamma: SliderCtrl[Rgba8]
    r, g, b: SliderCtrl[Rgba8]
    
proc initApp(): App =
  result.gamma = newSliderCtrl[Rgba8](5, 5,    350-5, 11,    not flipY)
  result.r = newSliderCtrl[Rgba8](5, 5+15, 350-5, 11+15, not flipY)
  result.g = newSliderCtrl[Rgba8](5, 5+30, 350-5, 11+30, not flipY)
  result.b = newSliderCtrl[Rgba8](5, 5+45, 350-5, 11+45, not flipY)
  result.pattern = newRboxCtrl[Rgba8](355, 1,  495,   60, not flipY)
  result.pattern.textSize(8)
  result.pattern.addItem("Horizontal")
  result.pattern.addItem("Vertical")
  result.pattern.addItem("Checkered")
  result.pattern.curItem(1)
  result.gamma.setRange(0.5, 4.0)
  result.gamma.value(2.2)
  result.gamma.label("Gamma=$1")
  result.r.value(1.0)
  result.g.value(1.0)
  result.b.value(1.0)
  result.r.label("R=$1")
  result.g.label("G=$1")
  result.b.label("B=$1")
  
#pixfmtRgb24Gamma(PixfmtRgb24Gamma, GammaLut8)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    gamma  = initGammaLut8(app.gamma.value())
    pixf   = initPixfmtRgb24Gamma(rbuf, gamma)
    rb     = initRendererBase(pixf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineP8()
    
  const 
    squareSize = 400
    verStrips  = 5
  
  var
    span1: array[squareSize, Rgba8]
    span2: array[squareSize, Rgba8]
    color = initRgba8(initRgba(app.r.value(), app.g.value(), app.b.value()))
    w = frameWidth
    h = frameHeight
  
  # Draw vertical gradient
  for i in 0.. <h:
    var k = float64(i - 80) / float64(squareSize - 1)
    if i < 80:             k = 0.0
    if i >= 80+squareSize: k = 1.0

    k = 1 - pow(k/2, 1/app.gamma.value())
    let c = color.gradient(initRgba8(0,0,0), k)
    rb.copyHline(0, i, w-1, c)

  const
    baseMask = getBaseMask(Rgba8)
    
  # Calculate spans
  case app.pattern.curItem()
  of 0:
    for i in 0.. <squareSize:
      span1[i] = color
      span2[i] = color
      span1[i].a = uint8(i * baseMask div squareSize)
      span2[i].a = uint8(baseMask - span1[i].a.int)
  of 1:
    for i in 0.. <squareSize:
      span1[i] = color
      span2[i] = color
      if (i and 1) != 0:
        span1[i].a = uint8(i * baseMask div squareSize)
        span2[i].a = span1[i].a
      else:
        span1[i].a = uint8(baseMask - i * baseMask div squareSize)
        span2[i].a = span1[i].a
  of 2:
    for i in 0.. <squareSize:
      span1[i] = color
      span2[i] = color
      if (i and 1) != 0:
        span1[i].a = uint8(i * baseMask div squareSize)
        span2[i].a = uint8(baseMask - span1[i].a.int)
      else:
        span2[i].a = uint8(i * baseMask div squareSize)
        span1[i].a = uint8(baseMask - span2[i].a.int)
  else:
    discard
         
  # Clear the area
  rb.copyBar(50, 80, 50+squareSize-1, 80+squareSize-1, initRgba(0,0,0))
  
  # Draw the patern
  for i in countup(0, squareSize - 1, 2):
    var k = i.float64 / float64(squareSize - 1)
    k = 1 - pow(k, 1/app.gamma.value())
    let c = color.gradient(initRgba8(0,0,0), k)
    for j in 0.. <squareSize:
      span1[j].r = c.r; span2[j].r = c.r
      span1[j].g = c.g; span2[j].g = c.g
      span1[j].b = c.b; span2[j].b = c.b
    rb.blendColorHspan(50, i + 80 + 0, squareSize, span1[0].addr, nil, 255)
    rb.blendColorHspan(50, i + 80 + 1, squareSize, span2[0].addr, nil, 255)
  
  # Draw vertical strips
  for i in 0.. <squareSize:
    var k = i.float64 / float64(squareSize - 1)
    k = 1 - pow(k/2, 1/app.gamma.value())
    let c = color.gradient(initRgba8(0,0,0), k)
    for j in 0.. <verStrips:
      let xc = squareSize * (j + 1) div (verStrips + 1)
      rb.copyHline(50+xc-10, i+80, 50+xc+10, c)
    
  renderCtrl(ras, sl, rb, app.gamma)
  renderCtrl(ras, sl, rb, app.r)
  renderCtrl(ras, sl, rb, app.g)
  renderCtrl(ras, sl, rb, app.b)
  renderCtrl(ras, sl, rb, app.pattern)
  saveBMP24("gamma_tuner.bmp", buffer, frameWidth, frameHeight)

onDraw()