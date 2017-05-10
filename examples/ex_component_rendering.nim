import agg/[basics, rendering_buffer, rasterizer_scanline_aa, rasterizer_cells_aa,
  scanline_p, ellipse, pixfmt_gray, pixfmt_rgb, color_gray, renderer_base,
  color_rgba, renderer_scanline]
import platform.support, ctrl.slider

pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 2, PixfmtGray8bgr24r)
pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 1, PixfmtGray8bgr24g)
pixfmtAlphaBlendGray(BlenderGray8, RenderingBuffer, 3, 0, PixfmtGray8bgr24b)

const
  frameWidth = 320
  frameHeight = 320
  flipY = true

type
  PixFmt = PixFmtBgr24
  ValueT = getValueT(PixFmt)

  App = ref object of PlatformSupport
    mAlpha: SliderCtrl[Rgba8]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mAlpha = newSliderCtrl[Rgba8](5, 5, 320-5, 10+5, not flipY)
  result.mAlpha.label("Alpha=$1")
  result.mAlpha.setRange(0, 255)
  result.mAlpha.value(255)
  result.addCtrl(result.mAlpha)

method onDraw(app: App) =
  var
    pf   = construct(PixFmt, app.rbufWindow())
    rb   = initRendererBase(pf)
    pfr = initPixfmtGray8bgr24r(app.rbufWindow())
    pfg = initPixfmtGray8bgr24g(app.rbufWindow())
    pfb = initPixfmtgray8bgr24b(app.rbufWindow())
    rbr = initRendererBase(pfr)
    rbg = initRendererBase(pfg)
    rbb = initRendererBase(pfb)
    ras = initRasterizerScanlineAA()
    sl = initScanlineP8()
    width = app.width()
    height = app.height()

  rb.clear(initRgba(1,1,1))

  var er = initEllipse(width / 2 - 0.87*50, height / 2 - 0.5*50, 100.0, 100.0, 100)
  ras.addPath(er)

  let alpha = uint(app.mAlpha.value())
  renderScanlinesAASolid(ras, sl, rbr, initGray8(0'u, alpha))

  var eg = initEllipse(width / 2 + 0.87*50, height / 2 - 0.5*50, 100, 100, 100)
  ras.addPath(eg)
  renderScanlinesAASolid(ras, sl, rbg, initGray8(0'u, alpha))

  var eb = initEllipse(width / 2, height / 2 + 50, 100, 100, 100)
  ras.addPath(eb)
  renderScanlinesAASolid(ras, sl, rbb, initGray8(0'u, alpha))

  renderCtrl(ras, sl, rb, app.mAlpha)

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Component Rendering")

  if app.init(frameWidth, frameHeight, {window_resize}, "component_rendering"):
    return app.run()

  result = 1

discard main()
