import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_renderer_base
import agg_scanline_p, agg_renderer_scanline, agg_renderer_primitives, agg_color_rgba
import agg_conv_stroke, agg_gsv_text, agg_pixfmt_rgb, agg_pixfmt_gray, agg_math_stroke
import agg_pixfmt_amask_adaptor, agg_span_allocator, agg_alpha_mask_u8, agg_color_gray
import make_arrows, make_gb_poly, nimBMP, agg_path_storage, agg_trans_affine
import agg_conv_transform, strutils, times

const
  frameWidth = 640
  frameHeight = 520
  pixWidth = 3
  operationMode = 1

type
  ValueType = uint8

var
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
  pf     = initPixFmtRgb24(rbuf)
  rb     = initRendererBase(pf)
  sl     = initScanlineP8()
  ren    = initRendererScanlineAASolid(rb)
  ras    = initRasterizerScanlineAA()

  mx     = frameWidth.float64 / 2.0
  my     = frameHeight.float64 / 2.0
  cx     = frameWidth
  cy     = frameHeight
  alphaBuf  = newString(cx * cy)
  alphaRbuf = initRenderingBuffer(cast[ptr ValueType](alphaBuf[0].addr), cx, cy, cx)
  alphaMask = initAmaskNoClipGray8(alphaRbuf)

proc drawText(x, y: float64, text: string) =
  var
    txt = initGsvText()
    stroke = initConvStroke(txt)

  stroke.width(1.5)
  stroke.lineCap(roundCap)
  txt.size(10.0)
  txt.startPoint(x, y)
  txt.text(text)
  ras.addPath(stroke)
  ren.color(initRgba(0.0, 0.0, 0.0))
  renderScanlines(ras, sl, ren)

proc generateAlphaMask[VertexSource](vs: var VertexSource) =
  var
    pixf = initPixFmtGray8(alphaRbuf)
    rb   = initRendererBase(pixf)
    ren  = initRendererScanlineAASolid(rb)

  var startTime = epochTime()
  if operationMode == 0:
    rb.clear(initGray8(0))
    ren.color(initGray8(255))
  else:
    rb.clear(initGray8(255))
    ren.color(initGray8(0))

  ras.addPath(vs)
  renderScanlines(ras, sl, ren)

  let endTime = epochTime()
  let renTime = formatFloat(endtime - startTime, ffDecimal, 3)
  let text = "Generate AlphaMask: $1ms" % [renTime]
  drawText(250, 20, text)


proc performRendering[VertexSource](vs: var VertexSource) =
  var
    pixfa = initPixFmtAmaskAdaptor(pf, alphaMask)
    rbase = initRendererBase(pixfa)
    ren   = initRendererScanlineAASolid(rbase)

  ren.color(initRgba(0.5, 0.0, 0, 0.5))

  var startTime = epochTime()
  ras.reset()
  ras.addPath(vs)
  renderScanlines(ras, sl, ren)

  let endTime = epochTime()
  let renTime = formatFloat(endtime - startTime, ffDecimal, 3)
  let text = "Render with AlphaMask: $1ms" % [renTime]
  drawText(250, 5, text)

proc renderGBSpiral() =
  var
    mx = frameWidth.float64 / 2.0
    my = frameHeight.float64 / 2.0
    sp = initSpiral(mx, my, 10, 150, 30, 0.0)
    stroke = initConvStroke(sp)
    gbPoly = initPathStorage()
    mtx = initTransAffine()

  stroke.width(15.0)
  makeGBPoly(gbPoly)

  mtx *= transAffineTranslation(-1150, -1150)
  mtx *= transAffineScaling(2.0)

  var trans = initConvTransform(gbPoly, mtx)

  ras.addPath(trans)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(ras, sl, ren)

  var strokegb = initConvStroke(trans)
  strokegb.width(0.1)

  ras.addPath(strokegb)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras, sl, ren)

  ras.addPath(stroke)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(ras, sl, ren)
  generateAlphaMask(trans)
  performRendering(stroke)

proc renderSimplePaths() =
  var
    ps1 = initPathStorage()
    ps2 = initPathStorage()
    x = mx - frameWidth.float64/2 + 100
    y = my - frameHeight.float64/2 + 100

  ps1.moveTo(x+140, y+145)
  ps1.lineTo(x+225, y+44)
  ps1.lineTo(x+296, y+219)
  ps1.closePolygon()

  ps1.lineTo(x+226, y+289)
  ps1.lineTo(x+82,  y+292)

  ps1.moveTo(x+220, y+222)
  ps1.lineTo(x+363, y+249)
  ps1.lineTo(x+265, y+331)

  ps1.moveTo(x+242, y+243)
  ps1.lineTo(x+268, y+309)
  ps1.lineTo(x+325, y+261)

  ps1.moveTo(x+259, y+259)
  ps1.lineTo(x+273, y+288)
  ps1.lineTo(x+298, y+266)

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)

  ras.reset()
  ras.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras, sl, ren)

  ras.reset()
  ras.addPath(ps2)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras, sl, ren)

  generateAlphaMask(ps1)
  performRendering(ps2)

proc renderClosedStroke() =
  var
    ps1 = initPathStorage()
    ps2 = initPathStorage()
    x = mx - frameWidth.float64/2 + 100
    y = my - frameHeight.float64/2 + 100
    stroke = initConvStroke(ps2)

  stroke.width(10.0)

  ps1.moveTo(x+140, y+145)
  ps1.lineTo(x+225, y+44)
  ps1.lineTo(x+296, y+219)
  ps1.closePolygon()

  ps1.lineTo(x+226, y+289)
  ps1.lineTo(x+82,  y+292)

  ps1.moveTo(x+220-50, y+222)
  ps1.lineTo(x+265-50, y+331)
  ps1.lineTo(x+363-50, y+249)
  ps1.closePolygon(pathFlagsCcw)

  ps2.moveTo(100+32,  100+77)
  ps2.lineTo(100+473, 100+263)
  ps2.lineTo(100+351, 100+290)
  ps2.lineTo(100+354, 100+374)
  ps2.closePolygon()

  ras.reset()
  ras.addPath(ps1)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras, sl, ren)

  ras.reset()
  ras.addPath(stroke)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras, sl, ren)

  generateAlphaMask(ps1)
  performRendering(stroke)

proc renderGBArrow() =
  var
    gb_poly = initPathStorage()
    arrows = initPathStorage()
    mtx1 = initTransAffine()
    mtx2 = initTransAffine()

  makeGBPoly(gb_poly)
  makeArrows(arrows)

  mtx1 *= transAffineTranslation(-1150, -1150)
  mtx1 *= transAffineScaling(2.0)

  mtx2 = mtx1
  mtx2 *= transAffineTranslation(mx - frameHeight.float64/2, my - frameHeight.float64/2)

  var
    trans_gb_poly = initConvTransform(gb_poly, mtx1)
    trans_arrows = initConvTransform(arrows, mtx2)

  ras.addPath(trans_gb_poly)
  ren.color(initRgba(0.5, 0.5, 0, 0.1))
  renderScanlines(ras, sl, ren)

  var stroke_gb_poly = initConvStroke(trans_gb_poly)
  stroke_gb_poly.width(0.1)
  ras.addPath(stroke_gb_poly)
  ren.color(initRgba(0, 0, 0))
  renderScanlines(ras, sl, ren)

  ras.addPath(trans_arrows)
  ren.color(initRgba(0.0, 0.5, 0.5, 0.1))
  renderScanlines(ras, sl, ren)

  generateAlphaMask(trans_gb_poly)
  performRendering(trans_arrows)

rb.clear(initRgba(1,1,1))
renderGBSpiral()
renderSimplePaths()
renderClosedStroke()
renderGBArrow()

saveBMP24("alpha_mask3.bmp", buffer, frameWidth, frameHeight)
