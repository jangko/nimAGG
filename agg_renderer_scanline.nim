import agg_basics, agg_renderer_base, strutils

proc renderScanlineAASolid*[Scanline, BaseRenderer, ColorT](sl: var Scanline,
  ren: var BaseRenderer, color: ColorT) =
  mixin blendSolidHspan, blendHline
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
  sl: var Scanline, ren: var BaseRenderer, color: ColorT) =
  mixin reset, blendSolidHspan, blendHline

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

  mixin reset, addPath, color

  for i in 0.. <numPaths:
    ras.reset()
    ras.addPath(vs, pathId[i])
    ren.color(col[i])
    renderScanlines(ras, sl, ren)

type
  RendererScanlineAASolid*[BaseRenderer, ColorT] = object
    mRen: ptr BaseRenderer
    mColor: ColorT

proc initRendererScanlineAASolidAux[B,C](ren: var B): RendererScanlineAASolid[B, C] =
  result.mRen = ren.addr

proc initRendererScanlineAASolid*[BaseRenderer](ren: var BaseRenderer): auto =
  mixin getColorT
  result = initRendererScanlineAASolidAux[BaseRenderer, getColorT(BaseRenderer)](ren)

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
  mixin blendColorHSpan

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
  mixin reset
  
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
                       sl.getY(),
                       span.x - 1 + len,
                       renColor,
                       coverFull)
        dec numSpans
        if numSpans == 0: break
        inc span

type
  RendererScanlineBinSolid*[BaseRenderer, ColorT] = object
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

proc renderScanlinesCompound*[Rasterizer, ScanlineAA, ScanlineBin,
  BaseRenderer, SpanAllocator, StyleHandler](ras: var Rasterizer, slAA: var ScanlineAA,
  slBin: var ScanlineBin, ren: var BaseRenderer, alloc: var SpanAllocator, sh: var StyleHandler) =
  mixin isSolid, reset
  if ras.rewindScanlines():
    var
      minX = ras.minX()
      len = ras.maxX() - minX + 2

    slAA.reset(minX, ras.maxX())
    slBin.reset(minX, ras.maxX())

    var
      colorSpan = alloc.allocate(len * 2)
      mixBufer = colorSpan + len
      numSpans: int
      numStyles: int
      style: int
      solid: bool

    numStyles = ras.sweepStyles()
    while numStyles > 0:
      if numStyles == 1:
          # Optimization for a single style. Happens often
        if ras.sweepScanline(slAA, 0):
          style = ras.style(0)
          if sh.isSolid(style):
            # Just solid fill
            renderScanlineAAsolid(slAA, ren, sh.color(style))
          else:
            # Arbitrary span generator
            var spanAA = slAA.begin()
            numSpans = slAA.numSpans()
            while true:
              len = spanAA.len
              sh.generateSpan(colorSpan, spanAA.x, slAA.getY(), len, style)
              ren.blendColorHspan(spanAA.x, slAA.getY(), spanAA.len, colorSpan, spanAA.covers)
              dec numSpans
              if numSpans == 0: break
              inc spanAA
      else:
        if ras.sweepScanline(slBin, -1):
          # Clear the spans of the mixBufer
          var spanBin = slBin.begin()
          numSpans = slBin.numSpans()
          while true:
            zeroMem(mixBufer + spanBin.x - minX, spanBin.len * sizeof(getColorT(BaseRenderer)))
            dec numSpans
            if numSpans == 0: break
            inc spanBin
      
          for i in 0.. <numStyles:
            style = ras.style(i)
            solid = sh.isSolid(style)
      
            if ras.sweepScanline(slAA, i):
              var spanAA   = slAA.begin()
              numSpans = slAA.numSpans()
              if solid:
                # Just solid fill
                while true:
                  var
                    c = sh.color(style)
                    colors = mixBufer + spanAA.x - minX
                    covers = spanAA.covers
                  len = spanAA.len
                  doWhile len != 0:
                    if covers[] == coverFull:
                      colors[] = c
                    else:
                      colors[].add(c, covers[])
                    inc colors
                    inc covers
                    dec len
                  dec numSpans
                  if numSpans == 0: break
                  inc spanAA
              else:
                # Arbitrary span generator
                while true:
                  len = spanAA.len;
                  var
                    colors = mixBufer + spanAA.x - minX
                    cspan  = colorSpan
      
                  sh.generateSpan(cspan, spanAA.x, slAA.getY(), len, style)
                  var covers = spanAA.covers
                  doWhile len != 0:
                    if covers[] == coverFull:
                      colors[] = cspan[]
                    else:
                      colors[].add(cspan[], covers[])
                    inc cspan
                    inc colors
                    inc covers
                    dec len
                  dec numSpans
                  if numSpans == 0: break
                  inc spanAA
      
          # Emit the blended result as a color hspan
          spanBin = slBin.begin()
          numSpans = slBin.numSpans()
          while true:
            ren.blendColorHspan(spanBin.x, slBin.getY(), spanBin.len,
              mixBufer + spanBin.x - minX, nil, coverFull)
            dec numSpans
            if numSpans == 0: break
            inc spanBin
      numStyles = ras.sweepStyles()

proc renderScanlinesCompoundLayered*[Rasterizer, ScanlineAA, BaseRenderer,
  SpanAllocator, StyleHandler](ras: var Rasterizer, slAA: var ScanlineAA,
  ren: var BaseRenderer, alloc: var SpanAllocator, sh: var StyleHandler) =
  mixin reset, isSolid
    
  if ras.rewindScanlines():    
    var
      minX = ras.minX()
      len = ras.maxX() - minX + 2

    slAA.reset(minX, ras.maxX())

    var
      colorSpan   = alloc.allocate(len * 2)
      mixBuffer   = colorSpan + len
      coverBuffer = ras.allocateCoverBuffer(len)
      numSpans: int
      numStyles: int
      style: int
      solid: bool
    
    numStyles = ras.sweepStyles()
    
    while numStyles > 0:
      if numStyles == 1:
        # Optimization for a single style. Happens often
        if ras.sweepScanline(slAA, 0):          
          style = ras.style(0)
          if sh.isSolid(style):
            # Just solid fill
            renderScanlineAASolid(slAA, ren, sh.color(style))
          else:
            # Arbitrary span generator
            var spanAA   = slAA.begin()
            numSpans = slAA.numSpans()
            while true:
              len = spanAA.len
              sh.generateSpan(colorSpan, spanAA.x, slAA.getY(), len, style)
              ren.blendColorHspan(spanAA.x, slAA.getY(), spanAA.len, colorSpan, spanAA.covers)
              dec numSpans
              if numSpans == 0: break
              inc spanAA        
      else:
        var
          slStart = ras.scanlineStart()
          slLen   = ras.scanlineLength()

        if slLen != 0:
          zeroMem(mixBuffer + slStart - minX, slLen * sizeof(getColorT(BaseRenderer)))
          zeroMem(coverBuffer + slStart - minX, slLen * sizeof(getColorT(BaseRenderer)))
          var slY = 0x7FFFFFFF

          for i in 0.. <numStyles:
            style = ras.style(i)
            solid = sh.isSolid(style)

            if ras.sweepScanline(slAA, i):
              var
                cover: uint
                spanAA   = slAA.begin()
              numSpans = slAA.numSpans()
              slY      = slAA.getY()
              if solid:
                # Just solid fill
                while true:
                  let c = sh.color(style)
                  len    = spanAA.len
                  var
                    colors = mixBuffer + spanAA.x - minX
                    srcCovers = spanAA.covers
                    dstCovers = coverBuffer + spanAA.x - minX
                  doWhile len != 0:
                    cover = srcCovers[]
                    if dstCovers[].uint + cover > coverFull.uint:
                      cover = coverFull.uint - dstCovers[].uint

                    if cover != 0:
                      colors[].add(c, cover)
                      dstCovers[] += cover.CoverType
                    inc colors
                    inc srcCovers
                    inc dstCovers
                    dec len
                  dec numSpans
                  if numSpans == 0: break
                  inc spanAA
              else:
                # Arbitrary span generator
                while true:
                  len = spanAA.len
                  var
                    colors = mixBuffer + spanAA.x - minX
                    cspan  = colorSpan

                  sh.generateSpan(cspan, spanAA.x, slAA.getY(), len, style)

                  var
                    srcCovers = spanAA.covers
                    dstCovers = coverBuffer + spanAA.x - minX

                  doWhile len != 0:
                    cover = srcCovers[]
                    if dstCovers[].uint + cover > coverFull.uint:
                      cover = coverFull.uint - dstCovers[].uint

                    if cover != 0:
                      colors[].add(cspan[], cover)
                      dstCovers[] += cover.CoverType

                    inc cspan
                    inc colors
                    inc srcCovers
                    inc dstCovers
                    dec len
                  dec numSpans
                  if numSpans == 0: break
                  inc spanAA
          ren.blendColorHspan(slStart, slY, slLen, mixBuffer + slStart - minX, nil, coverFull)          
      numStyles = ras.sweepStyles()
