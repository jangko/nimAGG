import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa
import agg_scanline_u, agg_renderer_scanline, agg_pixfmt_rgb
import agg_gamma_lut, agg_conv_dash, agg_conv_stroke, agg_span_gradient
import agg_span_interpolator_linear, agg_span_gouraud_rgba, agg_span_allocator
import agg_color_rgba, agg_renderer_base, nimBMP, math, agg_trans_affine, agg_ellipse
import strutils, random, times

{.passC: "-I./agg-2.5/include".}
{.compile: "aa_test.cpp".}
{.compile: "agg_trans_affine2.cpp".}
{.compile: "agg_vcgen_stroke2.cpp".}
{.compile: "agg_vcgen_dash2.cpp".}
{.passL: "-lstdc++".}

proc test_aa() {.importc.}

const
  frameWidth = 600
  frameHeight = 480
  pixWidth = 3

type
  ValueT = uint8

type
  SimpleVertexSource = object
    mNumVertices: int
    mCount: int
    mX, mY: array[8, float64]
    mCmd: array[8, uint]

  DashedLine[Ras, Ren, Scanline] = object
    mRas: ptr Ras
    mRen: ptr Ren
    mSl: ptr Scanline
    mSrc: SimpleVertexSource
    mDash: ConvDash[SimpleVertexSource, NullMarkers]
    mStroke: ConvStroke[SimpleVertexSource, NullMarkers]
    mDashStroke: ConvStroke[ConvDash[SimpleVertexSource, NullMarkers], NullMarkers]

proc initSimpleVertexSource(): SimpleVertexSource =
  result.mNumVertices = 0
  result.mCount = 0
  result.mCmd[0] = pathCmdStop

proc init(self: var SimpleVertexSource, x1, y1, x2, y2: float64) =
  self.mNumVertices = 2
  self.mCount = 0
  self.mX[0] = x1
  self.mY[0] = y1
  self.mX[1] = x2
  self.mY[1] = y2
  self.mCmd[0] = pathCmdMoveTo
  self.mCmd[1] = pathCmdLineTo
  self.mCmd[2] = pathCmdStop

proc init(self: var SimpleVertexSource, x1, y1, x2, y2, x3, y3: float64) =
  self.mNumVertices = 3
  self.mCount = 0
  self.mX[0] = x1
  self.mY[0] = y1
  self.mX[1] = x2
  self.mY[1] = y2
  self.mX[2] = x3
  self.mY[2] = y3
  self.mX[3] = 0.0
  self.mY[3] = 0.0
  self.mX[4] = 0.0
  self.mY[4] = 0.0
  self.mCmd[0] = pathCmdMoveTo
  self.mCmd[1] = pathCmdLineTo
  self.mCmd[2] = pathCmdLineTo
  self.mCmd[3] = pathCmdEndPoly or pathFlagsClose
  self.mCmd[4] = pathCmdStop

proc rewind*(self: var SimpleVertexSource, pathId: int) =
  self.mCount = 0

proc vertex*(self: var SimpleVertexSource, x, y: var float64): uint =
  x = self.mX[self.mCount]
  y = self.mY[self.mCount]
  result = self.mCmd[self.mCount]
  inc self.mCount

proc initDashedLine[Ras, Ren, Scanline](ras: var Ras, ren: var Ren, sl: var Scanline): DashedLine[Ras, Ren, Scanline] =
  result.mRas = ras.addr
  result.mRen = ren.addr
  result.mSl = sl.addr
  result.mSrc = initSimpleVertexSource()
  result.mDash = initConvDash(result.mSrc)
  result.mStroke = initConvStroke(result.mSrc)
  result.mDashStroke = initConvStroke(result.mDash)

proc draw*[Ras, Ren, Scanline](self: var DashedLine[Ras, Ren, Scanline], x1, y1, x2, y2, line_width, dash_length: float64) =
  self.mSrc.init(x1 + 0.5, y1 + 0.5, x2 + 0.5, y2 + 0.5)
  self.mRas[].reset()
  if dash_length > 0.0:
    self.mDash.removeAllDashes()
    self.mDash.addDash(dash_length, dash_length)
    self.mDashStroke.width(line_width)
    self.mDashStroke.lineCap(roundCap)
    self.mRas[].addPath(self.mDashStroke)
  else:
    self.mStroke.width(line_width)
    self.mStroke.lineCap(roundCap)
    self.mRas[].addPath(self.mStroke)

  renderScanlines(self.mRas[], self.mSl[], self.mRen[])

type
  PixFmt = PixfmtRgb24Gamma[GammaLut8] 
  ColorT = getColorT(PixFmt)

proc calc_linear_gradient_transform(x1, y1, x2, y2: float64, mtx: var TransAffine, gradient_d2 = 100.0) =
  let
    dx = x2 - x1
    dy = y2 - y1
  mtx.reset()
  mtx *= transAffineScaling(sqrt(dx * dx + dy * dy) / gradient_d2)
  mtx *= transAffineRotation(arctan2(dy, dx))
  mtx *= transAffineTranslation(x1 + 0.5, y1 + 0.5)
  mtx.invert()
  
  
# A simple function to form the gradient color array
# consisting of 3 colors, "begin", "middle", "end"
proc fillColorArray[CA,CB](arr: var openArray[CA], start, stop: CB) =
  var
    start = construct(ColorT, start)
    stop = construct(ColorT, stop)

  for i in 0.. <256:
    arr[i] = start.gradient(stop, i.float64 / 255.0)

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    gamma  = initGammaLut8(1.5)
    pixf   = initPixfmtRgb24Gamma(rbuf, gamma)
    renBase= initRendererBase(pixf)
    renSl  = initRendererScanlineAASolid(renBase)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

  renBase.clear(initRgba(0,0,0))
  var
    dash = initDashedLine(ras, renSl, sl)
    cx = frameWidth.float64 / 2.0
    cy = frameHeight.float64 / 2.0

  renSl.color(initRgba(1.0, 1.0, 1.0, 0.2))
  for i in countdown(180, 0):
    let n = 2.0 * pi * i.float64 / 180.0
    dash.draw(cx + min(cx, cy) * sin(n), cy + min(cx, cy) * cos(n),
     cx, cy, 1.0, if i < 90: i.float64 else: 0.0)

  var
    gradientF = initGradientX()
    gradientMtx = initTransAffine()
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanAllocator = initSpanAllocator[ColorT]()
    gradientColors: array[256, ColorT]
    spanGradient = initSpanGradient(spanInterpolator, gradientF, gradientColors, 0, 100)
    renGradient = initRendererScanlineAA(renBase, spanAllocator, spanGradient)
    dashGradient = initDashedLine(ras, renGradient, sl)

  var
    x1, y1, x2, y2: float64

  for ii in 1..20:
    let i = ii.float64
    renSl.color(initRgba(1,1,1))

    # integral point sizes 1..20
    var ell = initEllipse(20 + i * (i + 1) + 0.5,
                     20.5, i / 2.0, i / 2.0, 8 + ii)
    ras.reset()
    ras.addPath(ell)
    renderScanlines(ras, sl, renSl)

    # fractional point sizes 0..2
    ell.init(18 + i * 4 + 0.5, 33 + 0.5,
            i/20.0, i/20.0, 8)
    ras.reset()
    ras.addPath(ell)
    renderScanlines(ras, sl, renSl)


    # fractional point positioning
    ell.init(18 + i * 4 + (i-1) / 10.0 + 0.5,
            27 + (i - 1) / 10.0 + 0.5,
            0.5, 0.5, 8)
    ras.reset()
    ras.addPath(ell)
    renderScanlines(ras, sl, renSl)

    # integral line widths 1..20
    fillColorArray(gradientColors, initRgba(1,1,1), initRgba(i mod 2, (i mod 3) * 0.5, (i mod 5) * 0.25))
    #gradientColors.print_color()

    x1 = 20 + i* (i + 1)
    y1 = 40.5
    x2 = 20 + i * (i + 1) + (i - 1) * 4
    y2 = 100.5
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    #gradientMtx.print()
    dashGradient.draw(x1, y1, x2, y2, i, 0)

    fillColorArray(gradientColors, initRgba(1,0,0), initRgba(0,0,1))

    # fractional line lengths H (red/blue)
    x1 = 17.5 + i * 4
    y1 = 107
    x2 = 17.5 + i * 4 + i/6.66666667
    y2 = 107
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 1.0, 0)


    # fractional line lengths V (red/blue)
    x1 = 18 + i * 4
    y1 = 112.5
    x2 = 18 + i * 4
    y2 = 112.5 + i / 6.66666667
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 1.0, 0)

    # fractional line positioning (red)
    fillColorArray(gradientColors, initRgba(1,0,0), initRgba(1,1,1))
    x1 = 21.5
    y1 = 120 + (i - 1) * 3.1
    x2 = 52.5
    y2 = 120 + (i - 1) * 3.1
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 1.0, 0)


    # fractional line width 2..0 (green)
    fillColorArray(gradientColors, initRgba(0,1,0), initRgba(1,1,1))
    x1 = 52.5
    y1 = 118 + i * 3
    x2 = 83.5
    y2 = 118 + i * 3
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 2.0 - (i - 1) / 10.0, 0)

    # stippled fractional width 2..0 (blue)
    fillColorArray(gradientColors, initRgba(0,0,1), initRgba(1,1,1))
    x1 = 83.5
    y1 = 119 + i * 3
    x2 = 114.5
    y2 = 119 + i * 3
    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 2.0 - (i - 1) / 10.0, 3.0)

  #triangles
  let
    width = frameWidth.float64
    height = frameHeight.float64

  for ii in 1..13:
    let i = ii.float64
    fillColorArray(gradientColors, initRgba(1,1,1), initRgba(i mod 2, (i mod 3) * 0.5, (i mod 5) * 0.25))
    calc_linear_gradient_transform(width  - 150,
                                   height - 20 - i * (i + 1.5),
                                   width  - 20,
                                   height - 20 - i * (i + 1),
                                   gradientMtx)

    ras.reset()
    ras.moveToD(width - 150, height - 20 - i * (i + 1.5))
    ras.lineToD(width - 20,  height - 20 - i * (i + 1))
    ras.lineToD(width - 20,  height - 20 - i * (i + 2))
    renderScanlines(ras, sl, renGradient)

  saveBMP24("aa_test.bmp", buffer, frameWidth, frameHeight)

proc drawRandom() =
  randomize()
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    gamma  = initGammaLut8(1.5)
    pixf   = initPixfmtRgb24Gamma(rbuf, gamma)
    renBase= initRendererBase(pixf)
    renSl  = initRendererScanlineAASolid(renBase)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

  renBase.clear(initRgba(0,0,0))

  let
    w = frameWidth.float64
    h = frameHeight.float64

  var startTime = cpuTime()
  for i in 0..20000:
    let r = random(20.0) + 1.0
    var ell = initEllipse(random(w), random(h), r/2, r/2, int(r) + 10)
    ras.reset()
    ras.addPath(ell)
    renderScanlines(ras, sl, renSl)
    renSl.color(initRgba(random(1.0), random(1.0), random(1.0), 0.5+random(0.5)))

  let t1 = cpuTime() - startTime
  var
    gradientF = initGradientX()
    gradientMtx = initTransAffine()
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    spanAllocator = initSpanAllocator[ColorT]()
    gradientColors: array[256, ColorT]
    spanGradient = initSpanGradient(spanInterpolator, gradientF, gradientColors, 0, 100)
    renGradient = initRendererScanlineAA(renBase, spanAllocator, spanGradient)
    dashGradient = initDashedLine(ras, renGradient, sl)

  var
    x1, y1, x2, y2, x3, y3: float64

  startTime = cpuTime()
  for i in 0..2000:
    x1 = random(w)
    y1 = random(h)
    x2 = x1 + random(w * 0.5) - w * 0.25
    y2 = y1 + random(h * 0.5) - h * 0.25

    fillColorArray(gradientColors,
                     initRgba(random(1.0), random(1.0), random(1.0), 0.5+random(0.5)),
                     initRgba(random(1.0), random(1.0), random(1.0), random(1.0)))

    calc_linear_gradient_transform(x1, y1, x2, y2, gradientMtx)
    dashGradient.draw(x1, y1, x2, y2, 10.0, 0)

  let t2 = cpuTime() - startTime

  var
    spanGouraud = initSpanGouraudRgba[ColorT]()
    renGouraud  = initRendererScanlineAA(renBase, spanAllocator, spanGouraud)

  startTime = cpuTime()
  for i in 0..2000:
    x1 = random(w)
    y1 = random(h)
    x2 = x1 + random(w * 0.4) - w * 0.2
    y2 = y1 + random(h * 0.4) - h * 0.2
    x3 = x1 + random(w * 0.4) - w * 0.2
    y3 = y1 + random(h * 0.4) - h * 0.2

    spanGouraud.colors(initRgba(random(1.0), random(1.0), random(1.0), 0.5+random(0.5)),
                        initRgba(random(1.0), random(1.0), random(1.0), random(1.0)),
                        initRgba(random(1.0), random(1.0), random(1.0), random(1.0)))
    spanGouraud.triangle(x1, y1, x2, y2, x3, y3, 0.0)
    ras.addPath(spanGouraud)
    renderScanlines(ras, sl, renGouraud)

  let t3 = cpuTime() - startTime

  echo "Points=$1K/sec, Lines=$2K/sec, Triangles=$3K/sec" % [formatFloat(20000.0/t1/1000, ffDecimal, 3),
    formatFloat(2000.0/t2/1000, ffDecimal, 3), formatFloat(2000.0/t3/1000, ffDecimal, 3)]

  saveBMP24("aa_test2.bmp", buffer, frameWidth, frameHeight)

drawRandom()
onDraw()