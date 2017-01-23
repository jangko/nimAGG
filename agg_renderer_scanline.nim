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
    let renColor = getColorType(BaseRenderer).construct(color)

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
    ren: BaseRenderer
    mColor: ColorT

proc initRendererSAAS[B,C](ren: var B): RendererScanlineAASolid[B, C] =
  result.ren = ren

proc initRendererScanlineAASolid*[BaseRenderer](ren: var BaseRenderer): auto =
  result = initRendererSAAS[BaseRenderer, getColorType(BaseRenderer)](ren)

proc attach*[B, C](self: var RendererScanlineAASolid[B, C], ren: var B) =
  self.ren = ren

proc color*[B,C,CT](self: var RendererScanlineAASolid[B, C], c: CT) =
  when C isnot CT:
    self.mColor = construct(C, c)
  else:
    self.mColor = c

proc color*[B,C](self: RendererScanlineAASolid[B, C]): C =
  result = self.mColor

proc prepare*[B,C](self: RendererScanlineAASolid[B, C]) = discard

proc render*[B,C, Scanline](self: RendererScanlineAASolid[B, C], sl: var Scanline) =
  renderScanlineAASolid(sl, self.ren, self.color)

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
  mixin reset
  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    spanGen.prepare()
    while ras.sweepScanline(sl):
      renderScanlineAA(sl, ren, alloc, spanGen)
            