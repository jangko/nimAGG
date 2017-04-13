import agg_rendering_buffer, agg_renderer_base, agg_rasterizer_scanline_aa
import agg_scanline_u, agg_renderer_scanline, agg_rounded_rect
import agg_pixfmt_rgba, agg_span_allocator, agg_span_gradient
import agg_gsv_text, agg_span_interpolator_linear, agg_color_rgba
import nimBMP, math, agg_trans_affine, agg_math, agg_ellipse
import agg_comp_op, times, strutils, os, agg_pixfmt_rgb, agg_basics
import ctrl_rbox, ctrl_slider

type
  GradientLinearColor = object
    mC1, mC2: Rgba8

proc initGradientLinearColor(c1, c2: Rgba8): GradientLinearColor =
  result.mC1 = c1
  result.mC2 = c2

proc len*(self: GradientLinearColor): int = 256

proc `[]`(self: GradientLinearColor, v: int): Rgba8 =
  type
    ValueT = getValueT(Rgba8)
  const baseShift = getBaseShift(Rgba8)

  let v = v shl (baseShift - 8)
  result.r = ValueT((((self.mC2.r.int - self.mC1.r.int) * v) + (self.mC1.r.int shl baseShift)) shr baseShift)
  result.g = ValueT((((self.mC2.g.int - self.mC1.g.int) * v) + (self.mC1.g.int shl baseShift)) shr baseShift)
  result.b = ValueT((((self.mC2.b.int - self.mC1.b.int) * v) + (self.mC1.b.int shl baseShift)) shr baseShift)
  result.a = ValueT((((self.mC2.a.int - self.mC1.a.int) * v) + (self.mC1.a.int shl baseShift)) shr baseShift)

proc gradientAffine(x1, y1, x2, y2: float64, gradient_d2 = 100.0): TransAffine =
  let
    dx = x2 - x1
    dy = y2 - y1

  result.reset()
  result *= transAffineScaling(sqrt(dx * dx + dy * dy) / gradient_d2)
  result *= transAffineRotation(arctan2(dy, dx))
  result *= transAffineTranslation(x1, y1)
  result.invert()


proc circle[RenBase](rbase: var RenBase, c1, c2: Rgba8, x1, y1, x2, y2, shadow_alpha: float64) =
  var
    gradientFunc: GradientX
    gradientMtx      = gradientAffine(x1, y1, x2, y2, 100)
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanAllocator    = initSpanAllocator[Rgba8]()
    colorFunc        = initGradientLinearColor(c1, c2)
    spanGradient     = initSpanGradient(spanInterpolator, gradientFunc, colorFunc, 0, 100)
    ras              = initRasterizerScanlineAA()
    sl               = initScanlineU8()
    r                = calcDistance(x1, y1, x2, y2) / 2
    ell              = initEllipse((x1+x2)/2+5, (y1+y2)/2-3, r, r, 100)

  ras.addPath(ell)
  renderScanlinesAAsolid(ras, sl, rbase, initRgba(0.6, 0.6, 0.6, 0.7*shadow_alpha))

  ell.init((x1+x2)/2, (y1+y2)/2, r, r, 100)
  ras.addPath(ell)
  renderScanlinesAA(ras, sl, rbase, spanAllocator, spanGradient)

proc srcShape[RenBase, ColorT](rbase: var RenBase, c1, c2: ColorT, x1, y1, x2, y2: float64) =
  when ColorT isnot Rgba8:
    var
      c1 = construct(Rgba8, c1)
      c2 = construct(Rgba8, c2)
  var
    gradientFunc: GradientX
    gradientMtx      = gradientAffine(x1, y1, x2, y2, 100)
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanAllocator    = initSpanAllocator[Rgba8]()
    colorFunc        = initGradientLinearColor(c1, c2)
    spanGradient     = initSpanGradient(spanInterpolator, gradientFunc, colorFunc, 0, 100)
    ras              = initRasterizerScanlineAA()
    sl               = initScanlineU8()
    shape            = initRoundedRect(x1, y1, x2, y2, 40)
    #shape = initEllipse((x1+x2)/2, (y1+y2)/2, fabs(x2-x1)/2, fabs(y2-y1)/2, 100)
  ras.addPath(shape)
  renderScanlinesAA(ras, sl, rbase, spanAllocator, spanGradient)


const
  frameWidth = 600
  frameHeight = 400
  pixWidth = 4
  flipY = true

type
  ValueT = uint8

type
  App = object
    compOp: RboxCtrl[Rgba8]
    alphaDst, alphaSrc: SliderCtrl[Rgba8]

proc initApp(): App =
  result.alphaDst = newSliderCtrl[Rgba8](5, 5,    400, 11,    not flipY)
  result.alphaSrc = newSliderCtrl[Rgba8](5, 5+15, 400, 11+15, not flipY)
  result.compOp = newRboxCtrl[Rgba8](420, 5.0, 420+170.0, 395.0, not flipY)
  result.alphaDst.label("Dst Alpha=$1")
  result.alphaDst.value(1.0)
  result.alphaSrc.label("Src Alpha=$1")
  result.alphaSrc.value(0.75)
  result.compOp.textSize(6.8)

  for mode in CompOp:
    result.compOp.addItem($mode)

  result.compOp.curItem(3)

proc renderScene(app: var App, rbuf, rbuf1: var RenderingBuffer, pixf: var PixfmtRgba32, compOp: int) =
  type
    BlenderT = CompOpAdaptorRgba[Rgba8, OrderRgba]
  var
    renPixf  = initPixfmtCustomBlendRgba[BlenderT, RenderingBuffer](rbuf)
    renderer = initRendererBase(renPixf)
    rb       = initRendererBase(pixf)
    pf       = initPixfmtRgba32(rbuf1)
    a        = (app.alphaDst.value() * 255).uint8

  rb.blendFrom(pf, nil, 250, 180, a)

  circle(rb, initRgba8(0xFD, 0xF0, 0x6F, a),
             initRgba8(0xFE, 0x9F, 0x34, a),
             70*3, 100+24*3, 37*3, 100+79*3, app.alphaDst.value())

  renPixf.compOp(compOp)

  if compOp == 25: # Contrast
    let v = app.alphaSrc.value()
    srcShape(renderer,
      initRgba(v, v, v),
      initRgba(v, v, v),
      300.0+50.0, 100.0+24.0*3.0, 107.0+50.0, 100.0+79.0*3.0)
  else:
    let v = (app.alphaSrc.value() * 255).uint8
    srcShape(renderer,
      initRgba8(0x7F, 0xC1, 0xFF, v),
      initRgba8(0x05, 0x00, 0x5F, v),
      300.0+50.0, 100.0+24.0*3.0, 107.0+50.0, 100.0+79.0*3.0)

   #         src_shape(renderer,
   #                   agg::rgba8(0xFF, 0xFF, 0xFF, unsigned(m_alpha_src.value() * 255)),
   #                   agg::rgba8(0xFF, 0xFF, 0xFF, unsigned(m_alpha_src.value() * 255)),
   #                   300+50, 100+24*3, 107+50, 100+79*3);

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixfmtRgba32(rbuf)
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    ren    = initRendererScanlineAASolid(rb)

    buf0   = newString(frameWidth * frameHeight * pixWidth)
    rbuf0  = initRenderingBuffer(cast[ptr ValueT](buf0[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pixf2  = initPixfmtRgba32(rbuf0)
    rb2    = initRendererBase(pixf2)

    pixfPre = initPixfmtRgba32Pre(rbuf)
    rbPre   = initRendererBase(pixfPre)
    bmp    = loadBMP32("resources" & DirSep & "compositing.bmp")
    rbuf1  = initRenderingBuffer(cast[ptr ValueT](bmp.data[0].addr), bmp.width, bmp.height, -bmp.width * pixWidth)
    #mode   = app.compOp.curItem()

  # set alpha channel to full opaque
  let numPix = bmp.width*bmp.height
  for i in 0.. <numPix:
    bmp.data[i * 4 + 3] = 255.chr

  for modeOp in CompOp:
    app.compOp.curItem(modeOp.ord)
    # draw checker board
    rb.clear(initRgba8(255, 255, 255))
    for y in countup(0, rb.height() - 1, 8):
      for x in countup(((y shr 3) and 1) shl 3, rb.width() - 1, 16):
        rb.copyBar(x, y, x+7, y+7, initRgba8(0xdf, 0xdf, 0xAA))
  
    rb2.clear(initRgba8(0,0,0,0))
  
    let startTime = cpuTime()
    app.renderScene(rbuf0, rbuf1, pixf2, modeOp.ord)
    let t2 = cpuTime() - startTime
  
    rbPre.blendFrom(pixf2)
  
    var
      t = initGsvText()
      pt = initConvStroke(t)
  
    t.size(10.0)
    pt.width(1.5)
    t.startPoint(10.0, 50.0)
    t.text("$1 ms" % [formatFloat(t2, ffDecimal, 2)])
  
    ras.addPath(pt)
    ren.color(initRgba(0,0,0))
    renderScanlines(ras, sl, ren)
  
    let co = modeOp
    t.startPoint(10.0, 35.0)
    t.text($co)
  
    ras.addPath(pt)
    ren.color(initRgba(0,0,0))
    renderScanlines(ras, sl, ren)
  
    renderCtrlRs(ras, sl, ren, app.alphaDst)
    renderCtrlRs(ras, sl, ren, app.alphaSrc)
    renderCtrlRs(ras, sl, ren, app.compOp)
  
    let name = "compositing $1.bmp" % [$co]
    echo name
    saveBMP32(name, buffer, frameWidth, frameHeight)

onDraw()