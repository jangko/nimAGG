import agg/[rendering_buffer, renderer_base, rasterizer_scanline_aa, scanline_u, 
  renderer_scanline, rounded_rect, pixfmt_rgba, span_allocator, span_gradient,
  gsv_text, span_interpolator_linear, color_rgba, trans_affine, calc, ellipse,
  comp_op, pixfmt_rgb, basics]
import strutils, os, math
import ctrl.rbox, ctrl.slider, platform.support

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
  flipY = true

type
  PixFmt = PixFmtBgra32
  PixFmtPre = PixFmtBgra32Pre
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    compOp: RboxCtrl[Rgba8]
    alphaDst, alphaSrc: SliderCtrl[Rgba8]
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    ramp1, ramp2: array[256, Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.alphaDst = newSliderCtrl[Rgba8](5, 5,    400, 11,    not flipY)
  result.alphaSrc = newSliderCtrl[Rgba8](5, 5+15, 400, 11+15, not flipY)
  result.compOp = newRboxCtrl[Rgba8](420, 5.0, 420+170.0, 395.0, not flipY)

  result.addCtrl(result.alphaDst)
  result.addCtrl(result.alphaSrc)
  result.addCtrl(result.compOp)

  result.alphaDst.label("Dst Alpha=$1")
  result.alphaDst.value(1.0)
  result.alphaSrc.label("Src Alpha=$1")
  result.alphaSrc.value(0.75)
  result.compOp.textSize(6.8)

  for mode in CompOp:
    result.compOp.addItem($mode)

  result.compOp.curItem(3)
  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()

proc renderScene[RenBase](app: App, rb: var RenBase, compOp: int) =
  type
    OrderT   = getOrderT(Pixfmt)
    BlenderT = CompOpAdaptorRgba[Rgba8, OrderT]

  var
    pixf = initPixfmtCustomBlendRgba[BlenderT, RenderingBuffer](app.rbufWindow())
    ren  = initRendererBase(pixf)

  pixf.compOp(CompOpDifference)
  radialShape(ren, app.ramp1, 50.0, 50.0, 50.0+320.0, 50.0+320.0, app.ras, app.sl)

  pixf.compOp(compOp)
  let
    cx = 50.0
    cy = 50.0

  radialShape(ren, app.ramp2, cx+120.0-70.0, cy+120.0-70.0, cx+120.0+70.0, cy+120.0+70.0, app.ras, app.sl)
  radialShape(ren, app.ramp2, cx+200.0-70.0, cy+120.0-70.0, cx+200.0+70.0, cy+120.0+70.0, app.ras, app.sl)
  radialShape(ren, app.ramp2, cx+120.0-70.0, cy+200.0-70.0, cx+120.0+70.0, cy+200.0+70.0, app.ras, app.sl)
  radialShape(ren, app.ramp2, cx+200.0-70.0, cy+200.0-70.0, cx+200.0+70.0, cy+200.0+70.0, app.ras, app.sl)

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)

  generateColorRamp(app.ramp1,
    initRgba(0, 0, 0, app.alphaDst.value()),
    initRgba(0, 0, 1, app.alphaDst.value()),
    initRgba(0, 1, 0, app.alphaDst.value()),
    initRgba(1, 0, 0, 0))

  generateColorRamp(app.ramp2,
    initRgba(0, 0, 0, app.alphaSrc.value()),
    initRgba(0, 0, 1, app.alphaSrc.value()),
    initRgba(0, 1, 0, app.alphaSrc.value()),
    initRgba(1, 0, 0, 0))

  rb.clear(initRgba8(255, 255, 255))
  app.startTimer()
  app.renderScene(rb, app.compOp.curItem())
  let t2 = app.elapsedTime()

  var
    t = initGsvText()
    pt = initConvStroke(t)

  t.size(10.0)
  pt.width(1.5)
  t.startPoint(10.0, 50.0)
  t.text("$1 ms" % [formatFloat(t2, ffDecimal, 2)])

  app.ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(app.ras, app.sl, ren)

  let co = CompOp(app.compOp.curItem())
  t.startPoint(10.0, 35.0)
  t.text($co)

  app.ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(app.ras, app.sl, ren)

  renderCtrlRs(app.ras, app.sl, ren, app.alphaDst)
  renderCtrlRs(app.ras, app.sl, ren, app.alphaSrc)
  renderCtrlRs(app.ras, app.sl, ren, app.compOp)

proc main(): int =
  var app = newApp(pix_format_bgra32, flipY)
  app.caption("AGG Example. Compositing Modes")

  if app.init(frameWidth, frameHeight, {window_resize, window_keep_aspect_ratio}, "compositing2"):
    return app.run()

  result = 1

discard main()
