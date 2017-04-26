import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u, agg_scanline_p
import agg_conv_transform, agg_color_rgba, agg_color_gray, agg_span_allocator, agg_span_gradient
import agg_span_interpolator_linear, agg_renderer_scanline, ctrl_rbox, ctrl_spline
import ctrl_gamma, agg_renderer_base, agg_pixfmt_rgb, agg_basics, math
import agg_trans_affine, agg_ellipse, os, strutils, agg_platform_support

const
  frameWidth = 512
  frameHeight = 400
  flipY = true
  centerX = 350.0
  centerY = 280.0

type
  GradientPolymorphic = ref object of RootObj
    calculate: proc (x, y, d: int): int

  GradientWrapper[GradientF] = ref object of GradientPolymorphic
    mAdaptor: GradientReflectAdaptor[GradientF]
    mGradient: GradientF

proc newGradientWrapper[GradientF](): GradientPolymorphic =
  var res = GradientWrapper[GradientF]()
  res.mGradient = construct(GradientF)
  res.mAdaptor = initGradientReflectAdaptor(res.mGradient)
  res.calculate = proc (x, y, d: int): int =
    res.mAdaptor.calculate(x, y, d)
  result = res

type
  ColorFunctionProfile = object
    mColors: ptr Rgba8
    mProfile: ptr uint8

proc initColorFunctionProfile(colors: ptr Rgba8, profile: ptr uint8): ColorFunctionProfile =
  result.mColors = colors
  result.mProfile = profile

proc len(self: ColorFunctionProfile): int = 256
proc `[]`(self: ColorFunctionProfile, v: int): Rgba8 =
  self.mColors[self.mProfile[v].int]

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mProfile: GammaCtrl[Rgba8]
    mSplineR: SplineCtrl[Rgba8]
    mSplineG: SplineCtrl[Rgba8]
    mSplineB: SplineCtrl[Rgba8]
    mSplineA: SplineCtrl[Rgba8]
    mRbox: RboxCtrl[Rgba8]

    mPdx, mPdy: float64
    mCenterX, mCenterY: float64
    mScale, mPrevScale: float64
    mAngle, mPrevAngle: float64
    mScaleX, mPrevScaleX: float64
    mScaleY, mPrevScaleY: float64
    mMouseMove: bool

var
  gradients: array[6, GradientPolymorphic]

proc parseFloat(fd: File, v: var float64) =
  var buf: string
  if fd.readLine(buf):
    v = parseFloat(buf)

proc parseFloat(fd: File, x, y: var float64) =
  var buf: string
  if fd.readLine(buf):
    x = parseFloat(buf)

  if fd.readLine(buf):
    y = parseFloat(buf)

proc loadSettings(app: App) =
  var fd = open("resources" & DirSep & "settings.dat")
  if fd != nil:
    var x, y, x2, y2: float64
    fd.parseFloat(app.mCenterX)
    fd.parseFloat(app.mCenterY)
    fd.parseFloat(app.mScale)
    fd.parseFloat(app.mAngle)

    for i in 0..5:
      fd.parseFloat(x, y)
      app.mSplineR.point(i, x, y)
    app.mSplineR.updateSpline()

    for i in 0..5:
      fd.parseFloat(x, y)
      app.mSplineG.point(i, x, y)
    app.mSplineG.updateSpline()

    for i in 0..5:
      fd.parseFloat(x, y)
      app.mSplineB.point(i, x, y)
    app.mSplineB.updateSpline()

    for i in 0..5:
      fd.parseFloat(x, y)
      app.mSplineA.point(i, x, y)
    app.mSplineA.updateSpline()

    fd.parseFloat(x, y)
    fd.parseFloat(x2, y2)
    app.mProfile.values(x, y, x2, y2)

    fd.close()

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mProfile = newGammaCtrl[Rgba8](10.0, 10.0, 200.0, 170.0-5.0,    not flipY)
  result.mSplineR = newSplineCtrl[Rgba8](210, 10,     210+250, 5+40,  6, not flipY)
  result.mSplineG = newSplineCtrl[Rgba8](210, 10+40,  210+250, 5+80,  6, not flipY)
  result.mSplineB = newSplineCtrl[Rgba8](210, 10+80,  210+250, 5+120, 6, not flipY)
  result.mSplineA = newSplineCtrl[Rgba8](210, 10+120, 210+250, 5+160, 6, not flipY)
  result.mRbox    = newRboxCtrl[Rgba8](10.0, 180.0, 200.0, 300.0, not flipY)

  result.addCtrl(result.mProfile)
  result.addCtrl(result.mSplineR)
  result.addCtrl(result.mSplineG)
  result.addCtrl(result.mSplineB)
  result.addCtrl(result.mSplineA)
  result.addCtrl(result.mRbox)

  result.mPdx = 0.0
  result.mPdy = 0.0
  result.mCenterX = centerX
  result.mCenterY = centerY
  result.mScale = 1.0
  result.mPrevScale = 1.0
  result.mAngle = 0.0
  result.mPrevAngle = 0.0
  result.mScaleX = 1.0
  result.mPrevScaleX = 1.0
  result.mScaleY = 1.0
  result.mPrevScaleY = 1.0
  result.mMouseMove = false

  result.mProfile.borderWidth(2.0, 2.0)
  result.mSplineR.backgroundColor(initRgba(1.0, 0.8, 0.8))
  result.mSplineG.backgroundColor(initRgba(0.8, 1.0, 0.8))
  result.mSplineB.backgroundColor(initRgba(0.8, 0.8, 1.0))
  result.mSplineA.backgroundColor(initRgba(1.0, 1.0, 1.0))
  result.mSplineR.borderWidth(1.0, 2.0)
  result.mSplineG.borderWidth(1.0, 2.0)
  result.mSplineB.borderWidth(1.0, 2.0)
  result.mSplineA.borderWidth(1.0, 2.0)
  result.mRbox.borderWidth(2.0, 2.0)
  result.mSplineR.point(0, 0.0,     1.0)
  result.mSplineR.point(1, 1.0/5.0, 1.0 - 1.0/5.0)
  result.mSplineR.point(2, 2.0/5.0, 1.0 - 2.0/5.0)
  result.mSplineR.point(3, 3.0/5.0, 1.0 - 3.0/5.0)
  result.mSplineR.point(4, 4.0/5.0, 1.0 - 4.0/5.0)
  result.mSplineR.point(5, 1.0,     0.0)
  result.mSplineR.updateSpline()
  result.mSplineG.point(0, 0.0,     1.0)
  result.mSplineG.point(1, 1.0/5.0, 1.0 - 1.0/5.0)
  result.mSplineG.point(2, 2.0/5.0, 1.0 - 2.0/5.0)
  result.mSplineG.point(3, 3.0/5.0, 1.0 - 3.0/5.0)
  result.mSplineG.point(4, 4.0/5.0, 1.0 - 4.0/5.0)
  result.mSplineG.point(5, 1.0,     0.0)
  result.mSplineG.updateSpline()
  result.mSplineB.point(0, 0.0,     1.0)
  result.mSplineB.point(1, 1.0/5.0, 1.0 - 1.0/5.0)
  result.mSplineB.point(2, 2.0/5.0, 1.0 - 2.0/5.0)
  result.mSplineB.point(3, 3.0/5.0, 1.0 - 3.0/5.0)
  result.mSplineB.point(4, 4.0/5.0, 1.0 - 4.0/5.0)
  result.mSplineB.point(5, 1.0,     0.0)
  result.mSplineB.updateSpline()
  result.mSplineA.point(0, 0.0,     1.0)
  result.mSplineA.point(1, 1.0/5.0, 1.0)
  result.mSplineA.point(2, 2.0/5.0, 1.0)
  result.mSplineA.point(3, 3.0/5.0, 1.0)
  result.mSplineA.point(4, 4.0/5.0, 1.0)
  result.mSplineA.point(5, 1.0,     1.0)
  result.mSplineA.updateSpline()
  result.mRbox.addItem("Circular")
  result.mRbox.addItem("Diamond")
  result.mRbox.addItem("Linear")
  result.mRbox.addItem("XY")
  result.mRbox.addItem("sqrt(XY)")
  result.mRbox.addItem("Conic")
  result.mRbox.curItem(0)

  gradients[0] = newGradientWrapper[GradientRadial]()
  gradients[1] = newGradientWrapper[GradientDiamond]()
  gradients[2] = newGradientWrapper[GradientX]()
  gradients[3] = newGradientWrapper[GradientY]()
  gradients[4] = newGradientWrapper[GradientSqrtXY]()
  gradients[5] = newGradientWrapper[GradientConic]()
  result.loadSettings()

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    ras    = initRasterizerScanlineAA()
    sl     = initScanlineU8()
    iniScale = 1.0

  rb.clear(initRgba(0, 0, 0))
  app.mProfile.textSize(8.0)

  var mtx1 = initTransAffine()
  mtx1 *= transAffineScaling(iniScale, iniScale)
  mtx1 *= transAffineRotation(deg2rad(0.0))
  mtx1 *= transAffineTranslation(centerX, centerY)
  mtx1 *= transAffineresizing(app)

  var e1 = initEllipse(0.0, 0.0, 110.0, 110.0, 64)

  var mtxG1 = initTransAffine()
  mtxG1 *= transAffineScaling(iniScale, iniScale)
  mtxG1 *= transAffineScaling(app.mScale, app.mScale)
  mtxG1 *= transAffineScaling(app.mScaleX, app.mScaleY)
  mtxG1 *= transAffineRotation(app.mAngle)
  mtxG1 *= transAffineTranslation(app.mCenterX, app.mCenterY)
  mtxG1 *= transAffineresizing(app)
  mtxG1.invert()

  var colorProfile: array[256, Rgba8] # color_type is defined in pixel_formats.h
  for i in 0.. <256:
    colorProfile[i] = initRgba8(initRgba(app.mSplineR.spline()[i],
      app.mSplineG.spline()[i],
      app.mSplineB.spline()[i],
      app.mSplineA.spline()[i]))

  var
    t1 = initConvTransform(e1, mtx1)
    spanAlloc = initSpanAllocator[Rgba8]()
    colorF    = initColorFunctionProfile(colorProfile[0].addr, app.mProfile.gamma())
    inter     = initSpanInterpolatorLinear(mtxG1)

  var
    grad      = gradients[app.mRbox.curItem()]
    spanGen   = initSpanGradient(inter, grad, colorF, 0, 150)

  ras.addPath(t1)
  renderScanlinesAA(ras, sl, rb, spanAlloc, spanGen)

  renderCtrl(ras, sl, rb, app.mProfile)
  renderCtrl(ras, sl, rb, app.mSpliner)
  renderCtrl(ras, sl, rb, app.mSplineg)
  renderCtrl(ras, sl, rb, app.mSplineb)
  renderCtrl(ras, sl, rb, app.mSplinea)
  renderCtrl(ras, sl, rb, app.mRbox)

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if app.mMouseMove:
    var
      x2 = x
      y2 = y
    transAffineResizing(app).inverseTransform(x2, y2)

    if kbdCtrl in flags:
      var
        dx = x2 - app.mCenterX
        dy = y2 - app.mCenterY
      app.mScaleX = app.mPrevScaleX * dx / app.mPDx
      app.mScaleY = app.mPrevScaleY * dy / app.mPDy
      app.forceRedraw()
    else:
      if mouseLeft in flags:
        app.mCenterX = x2 + app.mPDx
        app.mCenterY = y2 + app.mPDy
        app.forceRedraw()

      if mouseRight in flags:
        var
          dx = x2 - app.mCenterX
          dy = y2 - app.mCenterY

        app.mScale = app.mPrevScale *
                    sqrt(dx * dx + dy * dy) /
                    sqrt(app.mPDx * app.mPDx + app.mPDy * app.mPDy)

        app.mAngle = app.mPrevAngle + arctan2(dy, dx) - arctan2(app.mPDy, app.mPDx)
        app.forceRedraw()

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)
    x2 = x
    y2 = y

  app.mMouseMove = true
  transAffineResizing(app).inverseTransform(x2, y2)

  app.mPDx = app.mCenterX - x2
  app.mPDy = app.mCenterY - y2
  app.mPrevScale = app.mScale
  app.mPrevAngle = app.mAngle + pi
  app.mPrevScaleX = app.mScaleX
  app.mPrevScaleY = app.mScaleY
  app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG gradients with Mach bands compensation")

  if app.init(frameWidth, frameHeight, {window_resize, window_hw_buffer}, "gradients"):
    return app.run()

  result = 1

discard main()
