import agg / [basics, rendering_buffer, scanline_u, renderer_scanline,
  pixfmt_rgb, color_rgba, gamma_functions, renderer_base, calc,
  path_storage, conv_stroke, math_stroke, rasterizer_scanline_aa]
import platform.support, ctrl.slider, math

type
  Square = object
    size: float64

proc initSquare(size: float64): Square =
  result.size = size

proc setSize(self: var Square, size: float64) =
  self.size = size

proc draw[Rasterizer, Scanline, Renderer, ColorT](self: Square, ras : var Rasterizer,
  sl: var Scanline, ren: var Renderer, color: ColorT, x, y: float64) =
  ras.reset()
  let size = self.size
  ras.moveToD(x*size,      y*size)
  ras.lineToD(x*size+size, y*size)
  ras.lineToD(x*size+size, y*size+size)
  ras.lineToD(x*size,      y*size+size)
  renderScanlinesAAsolid(ras, sl, ren, color)

type
  RendererEnlarge[Renderer] = object
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    ren: ptr Renderer
    square: Square
    color: Rgba8
    size: float64

proc initRendererEnlarged[Renderer](ren: var Renderer, size: float64): RendererEnlarge[Renderer] =
  result.ren = ren.addr
  result.square = initSquare(size)
  result.size = size
  result.sl = initScanlineU8()
  result.ras = initRasterizerScanlineAA()

proc setSize[Renderer](self: var RendererEnlarge[Renderer], size: float64) =
  self.square.setSize(size)
  self.size = size

proc setColor[Renderer](self: var RendererEnlarge[Renderer], c: Rgba8) =
  self.color = c

proc setRenderer[Renderer](self: var RendererEnlarge[Renderer], ren: var Renderer) =
  self.ren = ren.addr

proc prepare[Renderer](self: RendererEnlarge[Renderer]) = discard

proc render[Renderer, Scanline](self: var RendererEnlarge[Renderer], sl: var Scanline) =
  let y = sl.getY()
  var
    numSpans = sl.numSpans()
    span = sl.begin()

  doWhile numSpans != 0:
    var
      x = span.x
      covers = span.covers
      numPix = span.len

    doWhile numPix != 0:
      let a = (covers[].uint32 * uint32(self.color.a)) shr 8
      inc covers
      self.square.draw(self.ras, self.sl, self.ren[],
        initRgba8(self.color.r, self.color.g, self.color.b, a), x.float64, y.float64)
      inc x
      dec numPix

    dec numSpans

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  RendererT = RendererBase[PixFmt]

  App = ref object of PlatformSupport
    mX: array[3, float64]
    mY: array[3, float64]
    mDx: float64
    mDy: float64
    mIdx: int
    mSlider1: SliderCtrl[Rgba8]
    mSlider2: SliderCtrl[Rgba8]
    mSlider3: SliderCtrl[Rgba8]
    sl: ScanlineU8
    rb: RendererT
    ras: RasterizerScanlineAA
    ren: RendererEnlarge[RendererT]

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mSlider1 = newSliderCtrl[Rgba8](80, 10,    600-10, 19,    not flipY)
  result.mSlider2 = newSliderCtrl[Rgba8](80, 10+20, 600-10, 19+20, not flipY)
  result.mSlider3 = newSliderCtrl[Rgba8](80, 10+40, 600-10, 19+40, not flipY)

  result.mIdx = -1
  result.mX = [57.0, 369.0, 143.0]
  result.mY = [100.0, 170.0, 310.0]

  result.addCtrl(result.mSlider1)
  result.addCtrl(result.mSlider2)
  result.addCtrl(result.mSlider3)

  result.mSlider1.setRange(8.0, 100.0)
  result.mSlider1.numSteps(23)
  result.mSlider1.value(32.0)

  result.mSlider2.setRange(0.1, 3.0)
  result.mSlider2.value(1.0)

  result.mSlider3.setRange(0.1, 10.0)
  result.mSlider3.value(1.5)

  result.mSlider1.label("Pixel size=$1")
  result.mSlider2.label("Gamma=$1")
  result.mSlider3.label("Stroke=$1")

  result.mSlider1.noTransform()
  result.mSlider2.noTransform()
  result.mSlider3.noTransform()

  result.sl  = initScanlineU8()
  result.ras = initRasterizerScanlineAA()

  let sizeMul = float64(result.mSlider1.value())
  result.ren  = initRendererEnlarged(result.rb, sizeMul)

method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    rb  = initRendererBase(pf)

  app.ren.setRenderer(rb)

  let sizeMul = float64(app.mSlider1.value())
  app.ras.gamma(initGammaPower(app.mSlider2.value()))

  app.ren.setSize(sizeMul)
  rb.clear(initRgba(1,1,1))

  app.ras.reset()
  app.ras.moveToD(app.mx[0]/sizeMul, app.my[0]/sizeMul)
  app.ras.lineToD(app.mx[1]/sizeMul, app.my[1]/sizeMul)
  app.ras.lineToD(app.mx[2]/sizeMul, app.my[2]/sizeMul)
  app.ren.setColor(initRgba8(0,0,0, 255))
  renderScanlines(app.ras, app.sl, app.ren)

  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba8(0,0,0))

  app.ras.gamma(initGammaNone())

  var ps = initPathStorage()
  var pg = initConvStroke(ps)
  pg.width(app.mSlider3.value())
  pg.lineCap(roundCap)

  ps.removeAll()
  ps.moveTo(app.mx[0], app.my[0])
  ps.lineTo(app.mx[1], app.my[1])
  app.ras.addPath(pg)

  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba8(0,150,160, 255))

  ps.removeAll()
  ps.moveTo(app.mx[1], app.my[1])
  ps.lineTo(app.mx[2], app.my[2])
  app.ras.addPath(pg)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba8(0,150,160, 255))

  ps.removeAll()
  ps.moveTo(app.mx[2], app.my[2])
  ps.lineTo(app.mx[0], app.my[0])
  app.ras.addPath(pg)
  renderScanlinesAASolid(app.ras, app.sl, rb, initRgba8(0,150,160, 255))

  # Render the controls
  renderCtrl(app.ras, app.sl, rb, app.mSlider1)
  renderCtrl(app.ras, app.sl, rb, app.mSlider2)
  renderCtrl(app.ras, app.sl, rb, app.mSlider3)

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    var i = 0
    while i < 3:
      if sqrt((x-app.mX[i]) * (x-app.mX[i]) + (y-app.mY[i]) * (y-app.mY[i])) < 10.0:
        app.mDx = x - app.mX[i]
        app.mDy = y - app.mY[i]
        app.mIdx = i
        break
      inc i

    if i == 3:
      if pointInTriangle(app.mX[0], app.mY[0],
         app.mX[1], app.mY[1], app.mX[2], app.mY[2], x, y):
        app.mDx = x - app.mX[0]
        app.mDy = y - app.mY[0]
        app.mIdx = 3

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  var
    x = float64(x)
    y = float64(y)

  if mouseLeft in flags:
    if app.mIdx == 3:
      let dx = x - app.mDx
      let dy = y - app.mDy
      app.mX[1] -= app.mX[0] - dx
      app.mY[1] -= app.mY[0] - dy
      app.mX[2] -= app.mX[0] - dx
      app.mY[2] -= app.mY[0] - dy
      app.mX[0] = dx
      app.mY[0] = dy
      app.forceRedraw()
      return

    if app.mIdx >= 0:
      app.mX[app.mIdx] = x - app.mDx
      app.mY[app.mIdx] = y - app.mDy
      app.forceRedraw()
  else:
    app.onMouseButtonUp(x.int, y.int, flags)

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  app.mIdx = -1

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Anti-Aliasing Demo")

  if app.init(frameWidth, frameHeight, {window_resize}, "aa_demo"):
    return app.run()

  result = 1

discard main()
