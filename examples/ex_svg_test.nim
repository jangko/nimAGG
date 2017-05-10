import agg/[basics, rendering_buffer, rasterizer_scanline_aa, scanline_p,
  renderer_scanline, pixfmt_rgb, color_rgba, conv_transform,
  renderer_base, gamma_functions, gsv_text, conv_stroke, trans_affine,
  path_storage, conv_contour]
import os, strutils, platform.support, ctrl.slider

import svg_parser, svg_path_renderer

const
  frameWidth = 512
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mPath: PathRenderer

    mExpand: SliderCtrl[Rgba8]
    mGamma: SliderCtrl[Rgba8]
    mScale: SliderCtrl[Rgba8]
    mRotate: SliderCtrl[Rgba8]

    mMinX, mMinY, mMaxX, mMaxY: float64
    mX, mY, mDx, mDy: float64
    mCurSvg: int

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mPath = initPathRenderer()
  result.mExpand = newSliderCtrl[Rgba8](5,     5,    256-5, 11,    not flipY)
  result.mGamma  = newSliderCtrl[Rgba8](5,     5+15, 256-5, 11+15, not flipY)
  result.mScale  = newSliderCtrl[Rgba8](256+5, 5,    512-5, 11,    not flipY)
  result.mRotate = newSliderCtrl[Rgba8](256+5, 5+15, 512-5, 11+15, not flipY)

  result.addCtrl(result.mExpand)
  result.addCtrl(result.mGamma )
  result.addCtrl(result.mScale )
  result.addCtrl(result.mRotate)

  result.mMinX = 0.0
  result.mMinY = 0.0
  result.mMaxX = 0.0
  result.mMaxY = 0.0
  result.mX = 0.0
  result.mY = 0.0
  result.mDx = 0.0
  result.mDy = 0.0

  result.mExpand.label("Expand=$1")
  result.mExpand.setRange(-1, 1.2)
  result.mExpand.value(0.0)

  result.mGamma.label("Gamma=$1")
  result.mGamma.setRange(0.0, 3.0)
  result.mGamma.value(1.0)

  result.mScale.label("Scale=$1")
  result.mScale.setRange(0.2, 10.0)
  result.mScale.value(1.0)

  result.mRotate.label("Rotate=$1")
  result.mRotate.setRange(-180.0, 180.0)
  result.mRotate.value(180.0)
  result.mCurSvg = 0

const
  svg = ["b8","clinton","cowboy","lion","longhorn","mcseem2","picasso","tiger","xenia4"]

proc parseSvg(app: App, fname: string) =
  var p = initParser(app.mPath)
  p.parse("resources" & DirSep & fname & ".svg")
  app.mPath.arrangeOrientations()
  app.mPath.boundingRect(app.mMinX, app.mMinY, app.mMaxX, app.mMaxY)
  app.caption(p.title())

method onInit(app: App) =
  app.parseSvg(svg[app.mCurSvg])

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    mtx    = initTransAffine()
    gamma  = initGammaPower(app.mGamma.value())

  rb.clear(initRgba(1, 1, 1))

  var
    width  = app.width()
    height = app.height()
    w = app.mMaxX - app.mMinX
    h = app.mMaxY - app.mMinY
    scaleX = app.mScale.value()
    scaleY = app.mScale.value()

  if w > width:
    scaleX = width / w
    scaleX *= app.mScale.value()

  if h > height:
    scaleY = height / h
    scaleY *= app.mScale.value()

  ras.gamma(gamma)
  mtx *= transAffineTranslation((app.mMinX + app.mMaxX) * -0.5, (app.mMinY + app.mMaxY) * -0.5 + 50)
  mtx.flipX()
  mtx *= transAffineScaling(scaleX, scaleY)
  mtx *= transAffineRotation(deg2rad(app.mRotate.value()))
  mtx *= transAffineTranslation((app.mMinX + app.mMaxX) * 0.5 + app.mX, (app.mMinY + app.mMaxY) * 0.5 + app.mY + 50)

  app.mPath.expand(app.mExpand.value())

  app.startTimer()
  app.mPath.render(ras, sl, ren, mtx, rb.clipBox(), 1.0)

  var
    tm = app.elapsedTime()
    vertexCount = app.mPath.vertexCount()
    gammaNone = initGammaNone()
    t = initGsvText()
    pt = initConvStroke(t)
    buf = "Vertices= $1 Time=$2 ms" % [$vertexCount, tm.formatFloat(ffDecimal, 3)]

  ras.gamma(gammaNone)
  renderCtrl(ras, sl, rb, app.mExpand)
  renderCtrl(ras, sl, rb, app.mGamma)
  renderCtrl(ras, sl, rb, app.mScale)
  renderCtrl(ras, sl, rb, app.mRotate)

  t.size(10.0)
  t.flip(false)
  pt.width(1.5)
  t.startPoint(10.0, 40.0)
  t.text(buf)

  ras.addPath(pt)
  ren.color(initRgba(0,0,0))
  renderScanlines(ras, sl, ren)

  #agg::gamma_lut<> gl(app.mGamma.value())
  #unsigned x, y;
  #unsigned w = unsigned(width())
  #unsigned h = unsigned(height())
  #for(y = 0; y < h; y++)
  #{
  #    for(x = 0; x < w; x++)
  #    {
  #        agg::rgba8 c = rb.pixel(x, y)
  #        c.r = gl.inv(c.r)
  #        c.g = gl.inv(c.g)
  #        c.b = gl.inv(c.b)
  #        rb.copy_pixel(x, y, c)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseRight in flags:
    app.mCurSvg = (app.mCurSvg + 1) mod svg.len
    app.mPath.removeAll()
    app.parseSvg(svg[app.mCurSvg])
    app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. SVG Viewer")

  if app.init(frameWidth, frameHeight, {}, "svg_test"):
    return app.run()

  result = 1

discard main()
