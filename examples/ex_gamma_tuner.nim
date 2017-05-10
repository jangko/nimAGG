import agg/[rendering_buffer, rasterizer_scanline_aa, scanline_p, gamma_lut,
  renderer_scanline, gsv_text, conv_stroke, path_storage, renderer_base, 
  color_rgba, ellipse, pixfmt_rgb, trans_affine, conv_transform, basics]
import ctrl.rbox, ctrl.slider, math, platform.support

const
  frameWidth = 500
  frameHeight = 500
  flipY = true

type
  PixFmt = PixFmtBgr24Gamma[GammaLut8]

  App = ref object of PlatformSupport
    pattern: RboxCtrl[Rgba8]
    gamma: SliderCtrl[Rgba8]
    r, g, b: SliderCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.gamma = newSliderCtrl[Rgba8](5, 5,    350-5, 11,    not flipY)
  result.r = newSliderCtrl[Rgba8](5, 5+15, 350-5, 11+15, not flipY)
  result.g = newSliderCtrl[Rgba8](5, 5+30, 350-5, 11+30, not flipY)
  result.b = newSliderCtrl[Rgba8](5, 5+45, 350-5, 11+45, not flipY)
  result.pattern = newRboxCtrl[Rgba8](355, 1,  495,   60, not flipY)

  result.addCtrl(result.gamma)
  result.addCtrl(result.r)
  result.addCtrl(result.g)
  result.addCtrl(result.b)
  result.addCtrl(result.pattern)

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

method onDraw(app: App) =
  var
    gamma = initGammaLut8(app.gamma.value())
    pf    = construct(PixFmt, app.rbufWindow(), gamma)
    rb    = initRendererBase(pf)
    ras   = initRasterizerScanlineAA()
    sl    = initScanlineP8()

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

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Gamma Tuner")

  if app.init(frameWidth, frameHeight, {}, "gamma_tuner"):
    return app.run()

  result = 1

discard main()
