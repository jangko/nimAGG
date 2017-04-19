import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p, agg_renderer_scanline
import agg_conv_bspline, agg_conv_segmentator, agg_font_win32_tt, agg_font_cache_manager
import agg_font_types, agg_trans_double_path, ctrl_cbox, ctrl_slider, ctrl_polygon
import winapi, agg_basics, agg_color_rgba, agg_pixfmt_rgb, agg_renderer_base
import agg_conv_curve, agg_conv_transform, agg_conv_stroke, agg_path_storage_integer
import nimBMP

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
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

  FontEngineType  = FontEngineWin32TTInt16
  FontManagerType = FontCacheManagerWin16

  App = object
    mFEng: FontEngineType
    mFMan: FontManagerType
    mPoly1: PolygonCtrl[Rgba8]
    mPoly2: PolygonCtrl[Rgba8]
    mNumPoints: SliderCtrl[Rgba8]
    mPreserveXScale: CBoxCtrl[Rgba8]
    mFixedLen: CBoxCtrl[Rgba8]
    mAnimate: CBoxCtrl[Rgba8]
    mDx1, mDy1: array[6, float64]
    mDx2, mDy2: array[6, float64]
    mPrevAnimate: bool

proc init(app: var App) =
  app.mPoly1.xn(0) =  10 + 50
  app.mPoly1.yn(0) = -10 + 50
  app.mPoly1.xn(1) =  10 + 150 + 20
  app.mPoly1.yn(1) = -10 + 150 - 20
  app.mPoly1.xn(2) =  10 + 250 - 20
  app.mPoly1.yn(2) = -10 + 250 + 20
  app.mPoly1.xn(3) =  10 + 350 + 20
  app.mPoly1.yn(3) = -10 + 350 - 20
  app.mPoly1.xn(4) =  10 + 450 - 20
  app.mPoly1.yn(4) = -10 + 450 + 20
  app.mPoly1.xn(5) =  10 + 550
  app.mPoly1.yn(5) = -10 + 550

  app.mPoly2.xn(0) = -10 + 50
  app.mPoly2.yn(0) =  10 + 50
  app.mPoly2.xn(1) = -10 + 150 + 20
  app.mPoly2.yn(1) =  10 + 150 - 20
  app.mPoly2.xn(2) = -10 + 250 - 20
  app.mPoly2.yn(2) =  10 + 250 + 20
  app.mPoly2.xn(3) = -10 + 350 + 20
  app.mPoly2.yn(3) =  10 + 350 - 20
  app.mPoly2.xn(4) = -10 + 450 - 20
  app.mPoly2.yn(4) =  10 + 450 + 20
  app.mPoly2.xn(5) = -10 + 550
  app.mPoly2.yn(5) =  10 + 550

proc initApp(hdc: HDC): App =
  result.mFEng = newFontEngineWin32TTInt16(hdc)
  result.mFMan = newFontCacheManagerWin16(result.mFEng)
  result.mPoly1 = newPolygonCtrl[Rgba8](6, 5.0)
  result.mPoly2 = newPolygonCtrl[Rgba8](6, 5.0)
  result.mNumPoints      = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mPreserveXScale = newCboxCtrl[Rgba8](465, 5.0,  "Preserve X scale", not flipY)
  result.mFixedLen       = newCboxCtrl[Rgba8](350, 5.0, "Fixed Length", not flipY)
  result.mAnimate        = newCboxCtrl[Rgba8](350, 25.0, "Animate", not flipY)
  result.mPrevAnimate    = false

  result.mPreserveXScale.status(true)
  result.mFixedLen.status(true)
  result.mNumPoints.setRange(10.0, 400.0)
  result.mNumPoints.value(200.0)
  result.mNumPoints.label("Number of intermediate Points = $1")

  result.mPoly1.close(false)
  result.mPoly2.close(false)

  result.init()

proc onDraw(hdc: HDC) =
  var
    app = initApp(hdc)
    buffer = newSeq[ValueT](frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(buffer[0].addr, frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()

  rb.clear(initRgba(1, 1, 1))

  var
    path1 = initSimplePolygonVertexSource(app.mPoly1.polygon(),
      app.mPoly1.numPoints(), false, false)

    path2 = initSimplePolygonVertexSource(app.mPoly2.polygon(),
      app.mPoly2.numPoints(), false, false)

    bspline1 = initConvBSpline(path1)
    bspline2 = initConvBSpline(path2)

  bspline1.interpolationStep(1.0 / app.mNumPoints.value())
  bspline2.interpolationStep(1.0 / app.mNumPoints.value())

  var
    tcurve  = initTransDoublePath()
    fcurves = initConvCurve(app.mFMan.pathAdaptor())
    fsegm   = initConvSegmentator(fcurves)
    ftrans  = initConvTransform(fsegm, tcurve)

  tcurve.preserveXScale(app.mPreserveXScale.status())
  if app.mFixedLen.status(): tcurve.baseLength(1140.0)
  tcurve.baseHeight(30.0)

  tcurve.addPaths(bspline1, bspline2)
  fsegm.approximationScale(3.0)
  fcurves.approximationScale(5.0)

  app.mFeng.height(40.0)
  app.mFeng.hinting(false)
  app.mFeng.italic(true)

  if app.mFeng.createFont("Times New Roman", glyph_ren_outline):
    var
      x = 0.0
      y = 3.0

    for p in text:
      var glyph = app.mFMan.glyph(p.int)
      if glyph != nil:
        if x > tcurve.totalLength1(): break

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

  var
    stroke1 = initConvStroke(bspline1)
    stroke2 = initConvStroke(bspline2)

  stroke1.width(2.0)
  stroke2.width(2.0)

  ren.color(initRgba8(170, 50, 20, 100))
  ras.addPath(stroke1)
  renderScanlines(ras, sl, ren)

  ras.addPath(stroke2)
  renderScanlines(ras, sl, ren)

  # Render the "poly" tool and controls
  ren.color(initRgba(0, 0.3, 0.5, 0.2))
  ras.addPath(app.mPoly1)
  renderScanlines(ras, sl, ren)

  ras.addPath(app.mPoly2)
  renderScanlines(ras, sl, ren)

  renderCtrl(ras, sl, rb, app.mFixedLen)
  renderCtrl(ras, sl, rb, app.mPreserveXScale)
  renderCtrl(ras, sl, rb, app.mAnimate)
  renderCtrl(ras, sl, rb, app.mNumPoints)
  saveBMP24("trans_curve2.bmp", buffer, frameWidth, frameHeight)

proc main() =
  var dc = getDC(0)
  onDraw(dc)
  discard releaseDC(0, dc)

main()