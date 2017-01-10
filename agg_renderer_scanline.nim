import agg_basics, agg_renderer_base, strutils

proc renderScanlineAASolid*[Scanline, BaseRenderer, ColorT](sl: Scanline,
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

proc renderScanlinesAASolid*[Rasterizer, Scanline, BaseRenderer, ColorT](ras: Rasterizer,
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

proc renderScanlines*[Rasterizer, Scanline, Renderer](ras: Rasterizer, sl: var Scanline, ren: var Renderer) =
  mixin reset
  if ras.rewindScanlines():
    sl.reset(ras.minX(), ras.maxX())
    ren.prepare()
    while ras.sweepScanline(sl):
      ren.render(sl)
