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
        