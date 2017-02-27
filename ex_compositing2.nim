import agg_rendering_buffer, agg_renderer_base, agg_rasterizer_scanline_aa
import agg_scanline_u, agg_renderer_scanline, agg_rounded_rect
import agg_pixfmt_rgba, agg_span_allocator, agg_span_gradient
import agg_gsv_text, agg_span_interpolator_linear, agg_color_rgba
import nimBMP, math, agg_trans_affine, agg_math, agg_ellipse
import agg_comp_op, times, strutils, os, agg_pixfmt_rgb, agg_basics
import ctrl_rbox, ctrl_slider

proc generateColorRamp[CA,CB](c: var openArray[CA], c1, c2, c3, c4: CB) =
  when CA is not CB:
    for i in 0.. <85:
      c[i] = construct(CA, c1.gradient(c2, i.float64/85.0))

    for i in 85.. <170:
      c[i] = construct(CA, c2.gradient(c3, (i.float64 - 85.0)/85.0))

    for i in 170.. <256:
      c[i] = construct(CA, c3.gradient(c4, (i.float64 - 170.0)/85.0))
  else:
    for i in 0.. <85:
      c[i] = c1.gradient(c2, i.float64/85.0)

    for i in 85.. <170:
      c[i] = c2.gradient(c3, (i.float64 - 85.0)/85.0)

    for i in 170.. <256:
      c[i] = c3.gradient(c4, (i.float64 - 170.0)/85.0)

proc radialShape[RenBase, ColorT](rbase: var RenBase, colors: var array[256, ColorT],
  x1, y1, x2, y2: float64, ras: var RasterizerScanlineAA, sl: var ScanlineU8) =

  var
    gradientF        : GradientRadial
    gradientMtx      = initTransAffine()
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanAllocator    = initSpanAllocator[Rgba8]()
    spanGradient     = initSpanGradient(spanInterpolator, gradientF, colors, 0, 100)
    cx = (x1 + x2) / 2.0
    cy = (y1 + y2) / 2.0
    r  = 0.5 * (if((x2 - x1) < (y2 - y1)): (x2 - x1) else: (y2 - y1))

  gradientMtx *= transAffineScaling(r / 100.0)
  gradientMtx *= transAffineTranslation(cx, cy)
  #gradientMtx *= trans_affine_resizing();
  gradientMtx.invert()

  var
    ell   = initEllipse(cx, cy, r, r, 100)
    #trans = initConvTransform(ell, trans_affine_resizing())

  #ras.addPath(trans)
  ras.addPath(ell)
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
  
  for mode in 0.. <EndOfCompOp.ord:
    result.compOp.addItem($CompOp(mode))
    
  result.compOp.curItem(3)
        
proc renderScene[RenBase, ColorT](rb: var RenBase, rbuf: var RenderingBuffer,
  ramp1, ramp2: var array[256, ColorT], compOp: int, ras: var RasterizerScanlineAA, sl: var ScanlineU8) =
  type
    BlenderT = CompOpAdaptorRgba[Rgba8, OrderRgba]

  var
    pixf = initPixfmtCustomBlendRgba[BlenderT, RenderingBuffer](rbuf)
    ren  = initRendererBase(pixf)

  pixf.compOp(CompOpDifference)
  radialShape(ren, ramp1, 50.0, 50.0, 50.0+320.0, 50.0+320.0, ras, sl)

  pixf.compOp(compOp)
  let
    cx = 50.0
    cy = 50.0

  radialShape(ren, ramp2, cx+120.0-70.0, cy+120.0-70.0, cx+120.0+70.0, cy+120.0+70.0, ras, sl)
  radialShape(ren, ramp2, cx+200.0-70.0, cy+120.0-70.0, cx+200.0+70.0, cy+120.0+70.0, ras, sl)
  radialShape(ren, ramp2, cx+120.0-70.0, cy+200.0-70.0, cx+120.0+70.0, cy+200.0+70.0, ras, sl)
  radialShape(ren, ramp2, cx+200.0-70.0, cy+200.0-70.0, cx+200.0+70.0, cy+200.0+70.0, ras, sl)

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixfmtRgba32(rbuf)
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    ramp1, ramp2: array[256, Rgba8]
    ren    = initRendererScanlineAASolid(rb)
    mode   = app.compOp.curItem()
    
  rb.clear(initRgba8(255, 255, 255))
  
  generateColorRamp(ramp1,
    initRgba(0, 0, 0, app.alphaDst.value()),
    initRgba(0, 0, 1, app.alphaDst.value()),
    initRgba(0, 1, 0, app.alphaDst.value()),
    initRgba(1, 0, 0, 0))
  
  generateColorRamp(ramp2,
    initRgba(0, 0, 0, app.alphaSrc.value()),
    initRgba(0, 0, 1, app.alphaSrc.value()),
    initRgba(0, 1, 0, app.alphaSrc.value()),
    initRgba(1, 0, 0, 0))
  
  let startTime = cpuTime()
  renderScene(rb, rbuf, ramp1, ramp2, mode, ras, sl)
  let t2 = cpuTime() - startTime
  
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
  
  let co = CompOp(mode)
  t.startPoint(10.0, 35.0)
  t.text($co)
  
  ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  renderCtrlRs(ras, sl, ren, app.alphaDst)
  renderCtrlRs(ras, sl, ren, app.alphaSrc)
  renderCtrlRs(ras, sl, ren, app.compOp)
        
  saveBMP32("compositing2 $1.bmp" % [$co], buffer, frameWidth, frameHeight)

onDraw()