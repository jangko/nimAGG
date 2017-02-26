import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_conv_bspline, ctrl_cbox, ctrl_slider
import agg_basics, nimBMP, agg_color_rgba, agg_pixfmt_rgb, ctrl_polygon
import agg_renderer_base, agg_conv_stroke

const
  frameWidth = 600
  frameHeight = 600
  pixWidth = 3
  flipY = true

type
  ValueT = uint8

type
  App = object
    mPoly: PolygonCtrl[Rgba8]
    mNumPoints: SliderCtrl[Rgba8]
    mClose: CboxCtrl[Rgba8]
    mFlip: int

proc initApp(): App =
  result.mPoly = newPolygonCtrl[Rgba8](6, 5.0)
  result.mNumPoints = newSliderCtrl[Rgba8](5.0, 5.0, 340.0, 12.0, not flipY)
  result.mclose = newCboxCtrl[Rgba8](350, 5.0,  "Close", not flipY)
  result.mflip = 0

  result.mNumPoints.setRange(1.0, 40.0)
  result.mNumPoints.value(20.0)
  result.mNumPoints.label("Number of intermediate Points = $1")


  if result.mflip != 0:
    result.mPoly.xn(0) = 100
    result.mPoly.yn(0) = frameHeight - 100
    result.mPoly.xn(1) = frameWidth - 100
    result.mPoly.yn(1) = frameHeight - 100
    result.mPoly.xn(2) = frameWidth - 100
    result.mPoly.yn(2) = 100
    result.mPoly.xn(3) = 100
    result.mPoly.yn(3) = 100
  else:
    result.mpoly.xn(0) = 100
    result.mpoly.yn(0) = 100
    result.mpoly.xn(1) = frameWidth - 100
    result.mpoly.yn(1) = 100
    result.mpoly.xn(2) = frameWidth - 100
    result.mpoly.yn(2) = frameHeight - 100
    result.mpoly.xn(3) = 100
    result.mpoly.yn(3) = frameHeight - 100

  result.mpoly.xn(4) = frameWidth.float64 / 2.0
  result.mpoly.yn(4) = frameHeight.float64 / 2.0
  result.mpoly.xn(5) = frameWidth.float64 / 2.0
  result.mpoly.yn(5) = frameHeight.float64 / 3.0

proc onDraw() =
  var
    app    = initApp()
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    #ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()

  rb.clear(initRgba(1.0, 1.0, 0.95))

  var
    path    = initSimplePolygonVertexSource(app.mPoly.polygon(), app.mPoly.numPoints(), false, app.mClose.status())
    bspline = initConvBspline(path)
    stroke  = initConvStroke(bspline)

  bspline.interpolationStep(1.0 / app.mNumPoints.value())
  stroke.width(2.0)
  ras.addPath(stroke)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0, 0, 0))

  # Render the "poly" tool and controls
  ras.addPath(app.mPoly)
  renderScanlinesAAsolid(ras, sl, rb, initRgba(0, 0.3, 0.5, 0.6))

  renderCtrl(ras, sl, rb, app.mClose)
  renderCtrl(ras, sl, rb, app.mNumPoints)

  saveBMP24("bspline.bmp", buffer, frameWidth, frameHeight)

onDraw()