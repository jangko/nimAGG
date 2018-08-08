import agg/[rendering_buffer, rasterizer_scanline_aa, scanline_p, renderer_scanline,
  conv_bspline, conv_segmentator, font_win32_tt, font_cache_manager,
  font_types, trans_single_path, basics, color_rgba, pixfmt_rgb, renderer_base,
  conv_curve, conv_transform, conv_stroke, path_storage_integer]
import ctrl/[cbox, slider, polygon], platform/winapi, platform/support, random

proc makeText(): string {.compileTime.} =
   result = "Anti-Grain Geometry is designed as a set of loosely coupled"
   result.add " algorithms and class templates united with a common idea,"
   result.add " so that all the components can be easily combined. Also,"
   result.add " the template based design allows you to replace any part of"
   result.add " the library without the necessity to modify a single byte in"
   result.add " the existing code."

const text = makeText()

const
  frameWidth = 600
  frameHeight = 600
  flipY = true

type
  FontEngineType  = FontEngineWin32TTInt16
  FontManagerType = FontCacheManagerWin16

  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mFEng: FontEngineType
    mFMan: FontManagerType
    mPoly: PolygonCtrl[Rgba8]
    mNumPoints: SliderCtrl[Rgba8]
    mClose: CBoxCtrl[Rgba8]
    mPreserveXScale: CBoxCtrl[Rgba8]
    mFixedLen: CBoxCtrl[Rgba8]
    mAnimate: CBoxCtrl[Rgba8]
    mDx, mDy: array[6, float64]
    mPrevAnimate: bool

method onInit(app: App) =
  app.mPoly.xn(0) = 50
  app.mPoly.yn(0) = 50
  app.mPoly.xn(1) = 150 + 20
  app.mPoly.yn(1) = 150 - 20
  app.mPoly.xn(2) = 250 - 20
  app.mPoly.yn(2) = 250 + 20
  app.mPoly.xn(3) = 350 + 20
  app.mPoly.yn(3) = 350 - 20
  app.mPoly.xn(4) = 450 - 20
  app.mPoly.yn(4) = 450 + 20
  app.mPoly.xn(5) = 550
  app.mPoly.yn(5) = 550

proc newApp(format: PixFormat, flipY: bool, hdc: HDC): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mFEng = newFontEngineWin32TTInt16(hdc)
  result.mFMan = newFontCacheManagerWin16(result.mFEng)
  result.mPoly = newPolygonCtrl[Rgba8](6, 5.0)
  result.mNumPoints      = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mClose          = newCboxCtrl[Rgba8](350, 5.0,  "Close", not flipY)
  result.mPreserveXScale = newCboxCtrl[Rgba8](460, 5.0,  "Preserve X scale", not flipY)
  result.mFixedLen       = newCboxCtrl[Rgba8](350, 25.0, "Fixed Length", not flipY)
  result.mAnimate        = newCboxCtrl[Rgba8](460, 25.0, "Animate", not flipY)
  result.mPrevAnimate    = false

  result.addCtrl(result.mPoly)
  result.addCtrl(result.mNumPoints)
  result.addCtrl(result.mClose)
  result.addCtrl(result.mPreserveXScale)
  result.addCtrl(result.mFixedLen)
  result.addCtrl(result.mAnimate)

  result.mPreserveXScale.status(true)
  result.mFixedLen.status(true)
  result.mNumPoints.setRange(10.0, 400.0)
  result.mNumPoints.value(200.0)
  result.mNumPoints.label("Number of intermediate Points = $1")

method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()

  rb.clear(initRgba(1, 1, 1))
  app.mPoly.close(app.mClose.status())

  var
    path = initSimplePolygonVertexSource(app.mPoly.polygon(),
      app.mPoly.numPoints(), false, app.mClose.status())
    bspline = initConvBSpline(path)
    tcurve  = initTransSinglePath()

  bspline.interpolationStep(1.0 / app.mNumPoints.value())
  tcurve.addPath(bspline)
  tcurve.preserveXScale(app.mPreserveXScale.status())
  if app.mFixedLen.status(): tcurve.baseLength(1120)

  var
    fcurves = initConvCurve(app.mFMan.pathAdaptor())
    fsegm   = initConvSegmentator(fcurves)
    ftrans  = initConvTransform(fsegm, tcurve)

  fsegm.approximationScale(3.0)
  fcurves.approximationScale(2.0)

  app.mFEng.height(40.0)
  #app.mFEng.italic(true)

  if app.mFEng.createFont("Times New Roman", glyph_ren_outline):
    var
      x = 0.0
      y = 3.0

    for p in text:
      var glyph = app.mFMan.glyph(p.int)
      if glyph != nil:
        if x > tcurve.totalLength(): break

        discard app.mFMan.addKerning(x, y)
        app.mFMan.initEmbeddedAdaptors(glyph, x, y)

        if glyph.dataType == glyph_data_outline:
          ras.reset()
          ras.addPath(ftrans)
          ren.color(initRgba8(0, 0, 0))
          renderScanlines(ras, sl, ren)

        # increment pen position
        x += glyph.advanceX
        y += glyph.advanceY


  var stroke = initConvStroke(bspline)
  stroke.width(2.0)

  ren.color(initRgba8(170, 50, 20, 100))
  ras.addPath(stroke)
  renderScanlines(ras, sl, ren)

  # Render the "poly" tool and controls
  ren.color(initRgba(0, 0.3, 0.5, 0.3))
  ras.addPath(app.mPoly)
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.mClose)
  renderCtrl(ras, sl, rb, app.mPreserveXScale)
  renderCtrl(ras, sl, rb, app.mFixedLen)
  renderCtrl(ras, sl, rb, app.mAnimate)
  renderCtrl(ras, sl, rb, app.mNumPoints)

method onCtrlChange(app: App) =
  if app.mAnimate.status() != app.mPrevAnimate:
    if app.mAnimate.status():
      app.onInit()
      for i in 0..<6:
        app.mdx[i] = (rand(1000.0) - 500.0) * 0.01
        app.mdy[i] = (rand(1000.0) - 500.0) * 0.01
      app.waitMode(false)
    else:
      app.waitMode(true)
    app.mPrevAnimate = app.mAnimate.status()


proc movePoint(app: App, x, y, dx, dy: var float64) =
  if x < 0.0:
    x = 0.0
    dx = -dx

  if x > app.width():
    x = app.width()
    dx = -dx

  if y < 0.0:
    y = 0.0
    dy = -dy

  if y > app.height():
    y = app.height()
    dy = -dy

  x += dx
  y += dy

method onIdle(app: App) =
  for i in 0..<6:
    app.movePoint(app.mPoly.xn(i), app.mPoly.yn(i), app.mdx[i], app.mdy[i])
  app.forceRedraw()

proc main(): int =
  var dc = getDC(0)
  var app = newApp(pix_format_bgr24, flipY, dc)
  app.caption("AGG Example. Non-linear \"Along-A-Curve\" Transformer")

  if app.init(frameWidth, frameHeight, {}, "trans_curve1"):
    let ret = app.run()
    discard releaseDC(0, dc)
    return ret

  discard releaseDC(0, dc)
  result = 1

discard main()
