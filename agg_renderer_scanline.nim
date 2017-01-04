import agg_basics, agg_renderer_base

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
    # Explicitly convert "color" to the BaseRenderer color type.
    # For example, it can be called with color type "rgba", while
    # "rgba8" is needed. Otherwise it will be implicitly 
    # converted in the loop many times.

    let renColor = getColorType(BaseRenderer).construct(color)
    
    sl.reset(ras.minX(), ras.maxX())
    while ras.sweepScanline(sl):
      # render_scanline_aa_solid(sl, ren, ren_color);
      #
      # This code is equivalent to the above call (copy/paste). 
      # It's just a "manual" optimization for old compilers,
      # like Microsoft Visual C++ v6.0
      #-------------------------------
      let y = sl.getY()
      var
        numSpans = sl.numSpans()
        span = sl.begin()
              
      while true:
        echo numSpans
        let x = span.x
        echo x
        if span.len > 0:
          ren.blendSolidHspan(x, y, span.len, renColor, span.covers)
        else:
          echo (x - span.len - 1)
          #ren.blendHline(x, y, (x - span.len - 1), renColor, span.covers[])
        
        dec numSpans
        if numSpans == 0: break
        inc span
    
