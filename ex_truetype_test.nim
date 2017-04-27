import agg_basics, agg_rendering_buffer, agg_scanline_u, agg_scanline_bin, agg_renderer_scanline
import agg_renderer_primitives, agg_rasterizer_scanline_aa, agg_conv_curve, agg_conv_contour
import agg_pixfmt_rgb, agg_gamma_lut, agg_font_win32_tt, agg_font_types, agg_font_cache_manager
import ctrl_slider, ctrl_cbox, ctrl_rbox, agg_color_rgba, agg_renderer_base
import os, strutils, winapi, agg_trans_affine, agg_gamma_functions, agg_platform_support
import agg_scanline_storage_bin, agg_scanline_storage_aa, agg_path_storage_integer

const
  frameWidth = 640
  frameHeight = 520
  flipY = true

gammaLut(GammaLut86, uint8, uint16, 8, 16)

type
  FontEngineType  = FontEngineWin32TTInt16
  FontManagerType = FontCacheManagerWin16
  ConvCurveType = ConvCurve[pathAdaptorT(FontManagerType)]
  ConvContourType = ConvContour[ConvCurveType]
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mRenType: RBoxCtrl[Rgba8]
    mHeight: SliderCtrl[Rgba8]
    mWidth: SliderCtrl[Rgba8]
    mWeight: SliderCtrl[Rgba8]
    mGamma: SliderCtrl[Rgba8]
    mHinting: CBoxCtrl[Rgba8]
    mKerning: CBoxCtrl[Rgba8]
    mPerformance: CBoxCtrl[Rgba8]
    mFEng: FontEngineType
    mFMan: FontManagerType
    mOldHeight: float64
    mGammaLut: GammaLut86

    # Pipeline to process the vectors glyph paths (curves + contour)
    mCurves: ConvCurveType
    mContour: ConvContourType
    mText: string

proc loadText(): string =
  var f = open("resources" & DirSep & "text.txt")
  result = ""
  var line: string
  while f.readLine(line):
    result.add line
  f.close()

proc newApp(format: PixFormat, flipY: bool, hdc: HDC): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mRenType     = newRboxCtrl[Rgba8](5.0, 5.0, 5.0+150.0,   110.0,  not flipY)
  result.mHeight      = newSliderCtrl[Rgba8](160, 10.0, 640-5.0,    18.0,   not flipY)
  result.mWidth       = newSliderCtrl[Rgba8](160, 30.0, 640-5.0,    38.0,   not flipY)
  result.mWeight      = newSliderCtrl[Rgba8](160, 50.0, 640-5.0,    58.0,   not flipY)
  result.mGamma       = newSliderCtrl[Rgba8](260, 70.0, 640-5.0,    78.0,   not flipY)
  result.mHinting     = newCboxCtrl[Rgba8](160, 65.0, "Hinting", not flipY)
  result.mKerning     = newCboxCtrl[Rgba8](160, 80.0, "Kerning", not flipY)
  result.mPerformance = newCboxCtrl[Rgba8](160, 95.0, "Test Performance", not flipY)

  result.addCtrl(result.mRenType)
  result.addCtrl(result.mHeight)
  result.addCtrl(result.mWidth)
  result.addCtrl(result.mWeight)
  result.addCtrl(result.mGamma)
  result.addCtrl(result.mHinting)
  result.addCtrl(result.mKerning)
  result.addCtrl(result.mPerformance)

  result.mFEng = newFontEngineWin32TTInt16(hdc)
  result.mFMan = newFontCacheManagerWin16(result.mFEng)
  result.mOldHeight = 0.0
  result.mCurves = initConvCurve(result.mFMan.pathAdaptor())
  result.mContour = initConvContour(result.mCurves)
  result.mGammaLut = initGammaLut86()

  result.mRenType.addItem("Native Mono")
  result.mRenType.addItem("Native Gray 8")
  result.mRenType.addItem("Outline")
  result.mRenType.addItem("AGG Mono")
  result.mRenType.addItem("AGG Gray 8")
  result.mRenType.curItem(1)
  result.mRenType.noTransform()

  result.mHeight.label("Font Height=$1")
  result.mHeight.setRange(8, 32)
  result.mHeight.numSteps(32-8)
  result.mHeight.value(18)
  result.mHeight.textThickness(1.5)
  result.mHeight.noTransform()

  result.mWidth.label("Font Width=$1")
  result.mWidth.setRange(8, 32)
  result.mWidth.numSteps(32-8)
  result.mWidth.textThickness(1.5)
  result.mWidth.value(18)
  result.mWidth.noTransform()

  result.mWeight.label("Font Weight=$1")
  result.mWeight.setRange(-2, 2)
  result.mWeight.textThickness(1.5)
  result.mWeight.noTransform()

  result.mGamma.label("Gamma=$1")
  result.mGamma.setRange(0.1, 2.0)
  result.mGamma.value(1.0)
  result.mGamma.textThickness(1.5)
  result.mGamma.noTransform()

  result.mHinting.status(true)
  result.mHinting.noTransform()

  result.mKerning.status(true)
  result.mKerning.noTransform()

  result.mPerformance.noTransform()

  # result.mCurves.approximation_method(agg::curve_div)
  # result.mCurves.approximation_scale(0.5)
  # result.mCurves.angle_tolerance(0.3)
  result.mContour.autoDetectOrientation(false)
  result.mText = loadText()


proc getRenType(app: App): GlyphRendering =
  var gren = glyph_ren_native_mono

  case app.mRenType.curItem()
  of 0: gren = glyph_ren_native_mono
  of 1: gren = glyph_ren_native_gray8
  of 2: gren = glyph_ren_outline
  of 3: gren = glyph_ren_agg_mono
  of 4: gren = glyph_ren_agg_gray8
  else: discard
  result = gren

const
  textFlip = false

proc drawText[Rasterizer, Scanline, RenSolid, RenBin](app: App, ras: var Rasterizer,
  sl: var Scanline, renSolid: var RenSolid, renBin: var RenBin): int =

  var
    gren = app.getRenType()
    numGlyphs = 0

  app.mContour.width(-app.mWeight.value() * app.mHeight.value() * 0.05)
  app.mFEng.hinting(app.mHinting.status())
  app.mFEng.height(app.mHeight.value())

  # Font width in Windows is strange. MSDN says,
  # "specifies the average width", but there's no clue what
  # this "average width" means. It'd be logical to specify
  # the width with regard to the font height, like it's done in
  # FreeType. That is, width == height should mean the "natural",
  # not distorted glyphs. In Windows you have to specify
  # the absolute width, which is very stupid and hard to use
  # in practice.
  #-------------------------
  app.mFEng.width(if app.mWidth.value() == app.mHeight.value(): 0.0 else: app.mWidth.value() / 2.4)
  app.mFEng.italic(true)
  app.mFEng.flipY(textFlip)

  var mtx = initTransAffine()
  #mtx *= agg::trans_affine_skewing(-0.3, 0)
  mtx *= transAffineRotation(deg2rad(-4.0))
  app.mFEng.transform(mtx)

  if app.mFEng.createFont("Arial", gren):
    app.mFMan.precache(' '.ord, 127)

    var
      x  = 10.0
      y0 = frameHeight.float64 - app.mHeight.value() - 10.0
      y = y0

    for p in app.mText:
      var glyph = app.mFMan.glyph(p.ord)
      if glyph != nil:
        if app.mKerning.status():
          discard app.mFMan.addKerning(x, y)

        if x >= frameWidth.float64 - app.mHeight.value():
          x = 10.0
          y0 -= app.mHeight.value()
          if y0 <= 120.0: break
          y = y0

        app.mFMan.initEmbeddedAdaptors(glyph, x, y)

        case glyph.dataType
        of glyph_data_mono:
          renBin.color(initRgba8(0, 0, 0))
          renderScanlines(app.mFMan.monoAdaptor(), app.mFMan.monoScanline(), renBin)
        of glyph_data_gray8:
          renSolid.color(initRgba8(0, 0, 0))
          renderScanlines(app.mFMan.gray8Adaptor(), app.mFMan.gray8Scanline(), renSolid)
        of glyph_data_outline:
          ras.reset()
          if abs(app.mWeight.value()) <= 0.01:
            # For the sake of efficiency skip the
            # contour converter if the weight is about zero.
            ras.addPath(app.mCurves)
          else:
            ras.addPath(app.mContour)
          renSolid.color(initRgba8(0, 0, 0))
          renderScanlines(ras, sl, renSolid)
        else: discard

      # increment pen position
      x += glyph.advanceX
      y += glyph.advanceY
      inc numGlyphs
  result = numGlyphs


method onDraw(app: App) =
  var
    pf     = construct(PixFmt, app.rbufWindow())
    rb     = initRendererBase(pf)
    renSolid = initRendererScanlineAASolid(rb)
    renbin   = initRendererScanlineBinSolid(rb)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()

  rb.clear(initRgba(1,1,1))

  if app.mHeight.value() != app.mOldHeight:
    app.mOldHeight = app.mHeight.value()
    app.mWidth.value(app.mOldHeight)

  if app.mRenType.curItem() == 3:
    # When rendering in mono format,
    # Set threshold gamma = 0.5
    var gamma = initGammaThreshold(app.mGamma.value() / 2.0)
    app.mFEng.gamma(gamma)
  else:
    var gamma = initGammaNone()
    app.mFEng.gamma(gamma)
    app.mGammaLut.gamma(app.mGamma.value())


  discard app.drawText(ras, sl, renSolid, renBin)

  ras.gamma(initGammaPower(1.0))

  renderCtrl(ras, sl, rb, app.mRenType)
  renderCtrl(ras, sl, rb, app.mHeight)
  renderCtrl(ras, sl, rb, app.mWidth)
  renderCtrl(ras, sl, rb, app.mWeight)
  renderCtrl(ras, sl, rb, app.mGamma)
  renderCtrl(ras, sl, rb, app.mHinting)
  renderCtrl(ras, sl, rb, app.mKerning)
  renderCtrl(ras, sl, rb, app.mPerformance)

proc main(): int =
  var dc = getDC(0)
  var app = newApp(pix_format_bgr24, flipY, dc)
  app.caption("AGG Example. Rendering TrueType Fonts with WinAPI")

  if app.init(frameWidth, frameHeight, {}, "truetype_test"):
    let ret = app.run()
    discard releaseDC(0, dc)
    return ret

  discard releaseDC(0, dc)
  result = 1

discard main()
