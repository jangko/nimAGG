import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p, agg_renderer_scanline
import agg_conv_bspline, agg_conv_segmentator, agg_font_win32_tt, agg_font_cache_manager
import agg_font_types, agg_trans_single_path, ctrl_cbox, ctrl_slider, ctrl_polygon
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
    mPoly: PolygonCtrl[Rgba8]
    mNumPoints: SliderCtrl[Rgba8]
    mClose: CBoxCtrl[Rgba8]
    mPreserveXScale: CBoxCtrl[Rgba8]
    mFixedLen: CBoxCtrl[Rgba8]
    mAnimate: CBoxCtrl[Rgba8]
    mDx, mDy: array[6, float64]
    mPrevAnimate: bool

proc init(app: var App) =
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

proc initApp(hdc: HDC): App =
  result.mFEng = newFontEngineWin32TTInt16(hdc)
  result.mFMan = newFontCacheManagerWin16(result.mFEng)
  result.mPoly = newPolygonCtrl[Rgba8](6, 5.0)
  result.mNumPoints      = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mClose          = newCboxCtrl[Rgba8](350, 5.0,  "Close", not flipY)
  result.mPreserveXScale = newCboxCtrl[Rgba8](460, 5.0,  "Preserve X scale", not flipY)
  result.mFixedLen       = newCboxCtrl[Rgba8](350, 25.0, "Fixed Length", not flipY)
  result.mAnimate        = newCboxCtrl[Rgba8](460, 25.0, "Animate", not flipY)
  result.mPrevAnimate    = false

  result.mPreserveXScale.status(true)
  result.mFixedLen.status(true)
  result.mNumPoints.setRange(10.0, 400.0)
  result.mNumPoints.value(200.0)
  result.mNumPoints.label("Number of intermediate Points = $1")

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
  saveBMP24("trans_curve1.bmp", buffer, frameWidth, frameHeight)

proc main() =
  var dc = getDC(0)
  onDraw(dc)
  discard releaseDC(0, dc)

main()