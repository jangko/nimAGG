import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_renderer_base
import agg_scanline_p, agg_renderer_scanline, agg_renderer_primitives, agg_color_rgba
import agg_conv_stroke, agg_gsv_text, agg_pixfmt_rgb, agg_pixfmt_gray, agg_math_stroke
import agg_pixfmt_amask_adaptor, agg_span_allocator, agg_alpha_mask_u8, agg_color_gray
import make_arrows, make_gb_poly, nimBMP, agg_path_storage, agg_trans_affine
import agg_conv_transform, strutils, times, agg_conv_curve

const
  frameWidth = 640
  frameHeight = 520
  pixWidth = 3
  operationMode = 1

type
  ValueT = uint8

var
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
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
  alphaRbuf = initRenderingBuffer(cast[ptr ValueT](alphaBuf[0].addr), cx, cy, cx)
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

  var startTime = cpuTime()
  if operationMode == 0:
    rb.clear(initGray8(0))
    ren.color(initGray8(255))
  else:
    rb.clear(initGray8(255))
    ren.color(initGray8(0))

  ras.addPath(vs)
  renderScanlines(ras, sl, ren)

  let endTime = cpuTime()
  let renTime = formatFloat(endtime - startTime, ffDecimal, 3)
  let text = "Generate AlphaMask: $1ms" % [renTime]
  drawText(250, 20, text)


proc performRendering[VertexSource](vs: var VertexSource) =
  var
    pixfa = initPixFmtAmaskAdaptor(pf, alphaMask)
    rbase = initRendererBase(pixfa)
    ren   = initRendererScanlineAASolid(rbase)

  ren.color(initRgba(0.5, 0.0, 0, 0.5))

  var startTime = cpuTime()
  ras.reset()
  ras.addPath(vs)
  renderScanlines(ras, sl, ren)

  let endTime = cpuTime()
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

proc renderSpiralAndGlyph() =
  var
    sp = initSpiral(mx, my, 10, 150, 30, 0.0)
    stroke = initConvStroke(sp)
    glyph = initPathStorage()

  stroke.width(15.0)

  glyph.moveTo(28.47, 6.45)
  glyph.curve3(21.58, 1.12, 19.82, 0.29)
  glyph.curve3(17.19, -0.93, 14.21, -0.93)
  glyph.curve3(9.57, -0.93, 6.57, 2.25)
  glyph.curve3(3.56, 5.42, 3.56, 10.60)
  glyph.curve3(3.56, 13.87, 5.03, 16.26)
  glyph.curve3(7.03, 19.58, 11.99, 22.51)
  glyph.curve3(16.94, 25.44, 28.47, 29.64)
  glyph.lineTo(28.47, 31.40)
  glyph.curve3(28.47, 38.09, 26.34, 40.58)
  glyph.curve3(24.22, 43.07, 20.17, 43.07)
  glyph.curve3(17.09, 43.07, 15.28, 41.41)
  glyph.curve3(13.43, 39.75, 13.43, 37.60)
  glyph.lineTo(13.53, 34.77)
  glyph.curve3(13.53, 32.52, 12.38, 31.30)
  glyph.curve3(11.23, 30.08, 9.38, 30.08)
  glyph.curve3(7.57, 30.08, 6.42, 31.35)
  glyph.curve3(5.27, 32.62, 5.27, 34.81)
  glyph.curve3(5.27, 39.01, 9.57, 42.53)
  glyph.curve3(13.87, 46.04, 21.63, 46.04)
  glyph.curve3(27.59, 46.04, 31.40, 44.04)
  glyph.curve3(34.28, 42.53, 35.64, 39.31)
  glyph.curve3(36.52, 37.21, 36.52, 30.71)
  glyph.lineTo(36.52, 15.53)
  glyph.curve3(36.52, 9.13, 36.77, 7.69)
  glyph.curve3(37.01, 6.25, 37.57, 5.76)
  glyph.curve3(38.13, 5.27, 38.87, 5.27)
  glyph.curve3(39.65, 5.27, 40.23, 5.62)
  glyph.curve3(41.26, 6.25, 44.19, 9.18)
  glyph.lineTo(44.19, 6.45)
  glyph.curve3(38.72, -0.88, 33.74, -0.88)
  glyph.curve3(31.35, -0.88, 29.93, 0.78)
  glyph.curve3(28.52, 2.44, 28.47, 6.45)
  glyph.closePolygon()

  glyph.moveTo(28.47, 9.62)
  glyph.lineTo(28.47, 26.66)
  glyph.curve3(21.09, 23.73, 18.95, 22.51)
  glyph.curve3(15.09, 20.36, 13.43, 18.02)
  glyph.curve3(11.77, 15.67, 11.77, 12.89)
  glyph.curve3(11.77, 9.38, 13.87, 7.06)
  glyph.curve3(15.97, 4.74, 18.70, 4.74)
  glyph.curve3(22.41, 4.74, 28.47, 9.62)
  glyph.closePolygon()

  var
    mtx = initTransAffine()

  mtx *= transAffineScaling(4.0)
  mtx *= transAffineTranslation(220, 200)

  var
    trans = initConvTransform(glyph, mtx)
    curve = initConvCurve(trans)

  ras.reset()
  ras.addPath(stroke)
  ren.color(initRgba(0, 0, 0, 0.1))
  renderScanlines(ras, sl, ren)

  ras.reset()
  ras.addPath(curve)
  ren.color(initRgba(0, 0.6, 0, 0.1))
  renderScanlines(ras, sl, ren)

  generateAlphaMask(stroke)
  performRendering(curve)

rb.clear(initRgba(1,1,1))
#renderGBSpiral()
#renderSimplePaths()
#renderClosedStroke()
#renderGBArrow()
renderSpiralAndGlyph()

saveBMP24("alpha_mask3.bmp", buffer, frameWidth, frameHeight)
