import agg_basics, agg_renderer_base, strutils

proc renderScanlineAASolid*[Scanline, BaseRenderer, ColorT](sl: var Scanline,
  ren: BaseRenderer, color: ColorT) =

  let y = sl.getY()
  var
    numSpans = sl.numSpans()
    span = sl.begin()

  while true:
    let x = span.x
    if span.len > 0:
      ren.blendSolidHspan(x, y, span.len, color, span.covers)
    else:
      ren.blendHline(x, y, (x - span.len - 1), color, span.covers[])

    dec numSpans
    if numSpans == 0: break
    inc span

proc renderScanlinesAASolid*[Rasterizer, Scanline, BaseRenderer, ColorT](ras: var Rasterizer,
  sl: var Scanline, ren: BaseRenderer, color: ColorT) =
  mixin reset

  if ras.rewindScanlines():
    let renColor = getColorT(BaseRenderer).construct(color)

    sl.reset(ras.minX(), ras.maxX())
    while ras.sweepScanline(sl):
      let y = sl.getY()
      var
        numSpans = sl.numSpans()
        span = sl.begin()

      while true:
        let x = span.x
        if span.len > 0:
          ren.blendSolidHspan(x, y, span.len, renColor, span.covers)
        else:
          ren.blendHline(x, y, (x - span.len - 1), renColor, span.covers[])

        dec numSpans
        if numSpans == 0: break
        inc span

proc renderScanlines*[Rasterizer, Scanline, Renderer](ras: var Rasterizer, sl: var Scanline, ren: var Renderer) =
  mixin reset
  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    ren.prepare()
    while ras.sweepScanline(sl):
      ren.render(sl)

proc renderAllPaths*[Rasterizer, Scanline, Renderer, VertexSource, ColorT](ras: var Rasterizer, sl: var Scanline,
  ren: var Renderer, vs: var VertexSource, col: openArray[ColorT], pathId: openArray[int], numPaths: int) =

  mixin reset, addPath

  for i in 0.. <numPaths:
    ras.reset()
    ras.addPath(vs, pathId[i])
    ren.color(col[i])
    renderScanlines(ras, sl, ren)

type
  RendererScanlineAASolid*[BaseRenderer, ColorT] = object
    mRen: ptr BaseRenderer
    mColor: ColorT

proc initRendererSAAS[B,C](ren: var B): RendererScanlineAASolid[B, C] =
  result.mRen = ren.addr

proc initRendererScanlineAASolid*[BaseRenderer](ren: var BaseRenderer): auto =
  result = initRendererSAAS[BaseRenderer, getColorT(BaseRenderer)](ren)

proc attach*[B, C](self: var RendererScanlineAASolid[B, C], ren: var B) =
  self.mRen = ren.addr

proc color*[B,C,CT](self: var RendererScanlineAASolid[B, C], c: CT) =
  when C isnot CT:
    self.mColor = construct(C, c)
  else:
    self.mColor = c

proc color*[B,C](self: RendererScanlineAASolid[B, C]): C =
  result = self.mColor

proc prepare*[B,C](self: RendererScanlineAASolid[B, C]) = discard

proc render*[B,C, Scanline](self: RendererScanlineAASolid[B, C], sl: var Scanline) =
  renderScanlineAASolid(sl, self.mRen[], self.color)

proc renderScanlineAA*[Scanline, BaseRenderer, SpanAllocator, SpanGenerator](sl: var Scanline,
  ren: var BaseRenderer, alloc: var SpanAllocator, spanGen: var SpanGenerator) =

  let y = sl.getY()
  var
    numSpans = sl.numSpans()
    span = sl.begin()

  while true:
    var
      x = span.x
      len = span.len
      covers = span.covers

    if len < 0: len = -len
    var colors = alloc.allocate(len)
    spanGen.generate(colors, x, y, len)
    ren.blendColorHspan(x, y, len, colors, if span.len < 0: nil else: covers, covers[])

    dec numSpans
    if numSpans == 0: break
    inc span

type
  RendererScanlineAA*[BaseRenderer, SpanAllocator, SpanGenerator] = object
    mRen: ptr BaseRenderer
    mAlloc: ptr SpanAllocator
    mSpanGen: ptr SpanGenerator

proc initRendererScanlineAA*[BR,SA,SG](ren: var BR, alloc: var SA, spanGen: var SG): RendererScanlineAA[BR,SA,SG] =
  result.mRen = ren.addr
  result.mAlloc = alloc.addr
  result.mSpanGen = spanGen.addr

proc attach*[BR,SA,SG](self: var RendererScanlineAA[BR,SA,SG], ren: var BR, alloc: var SA, spanGen: var SG) =
  self.mRen = ren.addr
  self.mAlloc = alloc.addr
  self.mSpanGen = spanGen.addr

proc prepare*[BR,SA,SG](self: var RendererScanlineAA[BR,SA,SG]) =
  self.mSpanGen[].prepare()

proc render*[BR,SA,SG,Scanline](self: var RendererScanlineAA[BR,SA,SG], sl: var Scanline) =
  renderScanlineAA(sl, self.mRen[], self.mAlloc[], self.mSpanGen[])

proc renderScanlinesAA*[Rasterizer, Scanline, BaseRenderer, SpanAllocator, SpanGenerator](ras: var Rasterizer,
  sl: var Scanline, ren: var BaseRenderer, alloc: var SpanAllocator, spanGen: var SpanGenerator) =
  mixin reset, prepare
  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    spanGen.prepare()
    while ras.sweepScanline(sl):
      renderScanlineAA(sl, ren, alloc, spanGen)

proc renderScanlineBinSolid*[Scanline, BaseRenderer, ColorT](sl: var Scanline,
  ren: var BaseRenderer, color: ColorT) =
  var
    numSpans = sl.numSpans()
    span = sl.begin()

  while true:
    let len = if span.len < 0: -span.len else: span.len
    ren.blendHline(span.x,
                   sl.getY(),
                   span.x - 1 + len,
                   color,
                   coverFull)
    dec numSpans
    if numSpans == 0: break
    inc span

proc renderScanlinesBinSolid*[Rasterizer, Scanline, BaseRenderer, ColorT](ras: var Rasterizer,
  sl: var Scanline, ren: var BaseRenderer, color: ColorT) =

  if ras.rewindScanlines():
    # Explicitly convert "color" to the BaseRenderer color type.
    # For example, it can be called with color type "rgba", while
    # "rgba8" is needed. Otherwise it will be implicitly
    # converted in the loop many times.
    let renColor = getColorT(BaseRenderer).construct(color)

    sl.reset(ras.minX(), ras.maxX())
    while ras.sweepScanline(sl):
      #render_scanline_bin_solid(sl, ren, ren_color);
      # This code is equivalent to the above call (copy/paste).
      # It's just a "manual" optimization for old compilers,
      # like Microsoft Visual C++ v6.0

      var
        numSpans = sl.numSpans()
        span = sl.begin()

      while true:
        let len = if span.len < 0: -span.len else: span.len
        ren.blendHline(span.x,
                       sl.y(),
                       span.x - 1 + len,
                       renColor,
                       coverFull)
        dec numSpans
        if numSpans == 0: break
        inc span

type
  RendererScanlineBinSolid[BaseRenderer, ColorT] = object
    mRen: ptr BaseRenderer
    mColor: ColorT

proc initRendererSBS[B,C](ren: var B): RendererScanlineBinSolid[B, C] =
  result.mRen = ren.addr

proc initRendererScanlineBinSolid*[BaseRenderer](ren: var BaseRenderer): auto =
  result = initRendererSBS[BaseRenderer, getColorT(BaseRenderer)](ren)

proc attach*[B,C](self: var RendererScanlineBinSolid[B,C], ren: var B) =
  self.mRen = ren.addr

proc color*[B,C,CT](self: var RendererScanlineBinSolid[B, C], c: CT) =
  when C isnot CT:
    self.mColor = construct(C, c)
  else:
    self.mColor = c

proc color*[B,C](self: RendererScanlineBinSolid[B, C]): C =
  result = self.mColor

proc prepare*[B,C](self: RendererScanlineBinSolid[B, C]) = discard

proc render*[B,C, Scanline](self: RendererScanlineBinSolid[B, C], sl: var Scanline) =
  renderScanlineBinSolid(sl, self.mRen[], self.mColor)

proc renderScanlineBin*[Scanline, BaseRenderer, SpanAllocator, SpanGenerator](sl: var Scanline,
  ren: var BaseRenderer, alloc: var SpanAllocator, spanGen: var SpanGenerator) =
  var
    y = sl.getY()
    numSpans = sl.numSpans()
    span = sl.begin()

  while true:
    var
      x = span.x
      len = if span.len < 0: -span.len else: span.len
      colors = alloc.allocate(len)

    spanGen.generate(colors, x, y, len)
    ren.blendColorHspan(x, y, len, colors, 0, coverFull)
    dec numSpans
    if numSpans == 0: break
    inc span

proc renderScanlinesBin*[Rasterizer, Scanline, BaseRenderer, SpanAllocator, SpanGenerator](ras: var Rasterizer,
  sl: var Scanline, ren: var BaseRenderer, alloc: var SpanAllocator, spanGen: SpanGenerator) =

  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    spanGen.prepare()
    while ras.sweepScanline(sl):
      renderScanlineBin(sl, ren, alloc, spanGen)

type
  RendererScanlineBin*[BaseRenderer, SpanAllocator, SpanGenerator] = object
    mRen: ptr BaseRenderer
    mAlloc: ptr SpanAllocator
    mSpanGen: ptr SpanGenerator

proc initRendererScanlineBin*[BR,SA,SG](ren: var BR, alloc: var SA, spanGen: var SG): RendererScanlineBin[BR,SA,SG] =
  result.mRen = ren.addr
  result.mAlloc = alloc.addr
  result.mSpanGen = spanGen.addr

proc attach*[BR,SA,SG](self: var RendererScanlineBin[BR,SA,SG], ren: var BR, alloc: var SA, spanGen: var SG) =
  self.mRen = ren.addr
  self.mAlloc = alloc.addr
  self.mSpanGen = spanGen.addr

proc prepare*[BR,SA,SG](self: var RendererScanlineBin[BR,SA,SG]) =
  self.mSpanGen[].prepare()

proc render*[BR,SA,SG,Scanline](self: var RendererScanlineBin[BR,SA,SG], sl: var Scanline) =
  renderScanlineBin(sl, self.mRen[], self.mAlloc[], self.mSpanGen[])
