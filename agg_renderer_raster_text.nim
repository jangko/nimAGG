import agg_basics, agg_glyph_raster_bin, agg_renderer_base

type
  RendererRasterHtextSolid*[BaseRenderer, GlyphGenerator, ColorT] = object
    mRen: ptr BaseRenderer
    mGlyph: ptr GlyphGenerator
    mColor: ColorT

proc initRendererRasterHtextSolidAux*[B,G,C](ren: var B, glyph: var G): RendererRasterHtextSolid[B,G,C] =
  result.mRen = ren.addr
  result.mGlyph = glyph.addr

proc initRendererRasterHtextSolid*[B,G](ren: var B, glyph: var G): auto =
  initRendererRasterHtextSolidAux[B,G,getColorT(B)](ren, glyph)

proc attach*[B,G,C](self: var RendererRasterHtextSolid[B,G,C], ren: var B) =
  self.mRen = ren.addr

proc color*[B,G,CA,CB](self: var RendererRasterHtextSolid[B,G,CA], c: CB) =
  when CA is not CB:
    self.mColor = construct(CA, c)
  else:
    self.mColor = c

proc color*[B,G,C](self: RendererRasterHtextSolid[B,G,C]): C =
  self.mColor

proc renderText*[B,G,C](self: RendererRasterHtextSolid[B,G,C], x, y: float64, str: string, flip = false) =
  var
    r: GlyphRect
    x = x
    y = y

  for c in str:
    self.mGlyph[].prepare(r, x, y, c.ord, flip)
    if r.x2 >= r.x1:
      if flip:
        for i in r.y1..r.y2:
          self.mRen[].blendSolidHspan(r.x1, i, (r.x2 - r.x1 + 1),
                                      self.mColor, self.mGlyph[].span(r.y2 - i))
      else:
        for i in r.y1..r.y2:
          self.mRen[].blendSolidHspan(r.x1, i, (r.x2 - r.x1 + 1),
                                      self.mColor, self.mGlyph[].span(i - r.y1))
    x += r.dx
    y += r.dy

type
  RendererRasterVtextSolid*[BaseRenderer, GlyphGenerator, ColorT] = object
    mRen: ptr BaseRenderer
    mGlyph: ptr GlyphGenerator
    mColor: ColorT

proc initRendererRasterVtextSolidAux*[B,G,C](ren: var B, glyph: var G): RendererRasterVtextSolid[B,G,C] =
  result.mRen = ren.addr
  result.mGlyph = glyph.addr

proc initRendererRasterVtextSolid*[B,G](ren: var B, glyph: var G): auto =
  initRendererRasterVtextSolidAux[B,G,getColorT(B)](ren, glyph)

proc attach*[B,G,C](self: var RendererRasterVtextSolid[B,G,C], ren: var B) =
  self.mRen = ren.addr

proc color*[B,G,CA,CB](self: var RendererRasterVtextSolid[B,G,CA], c: CB) =
  when CA is not CB:
    self.mColor = construct(CA, c)
  else:
    self.mColor = c

proc color*[B,G,C](self: RendererRasterVtextSolid[B,G,C]): C =
  self.mColor

proc renderText*[B,G,C](self: RendererRasterVtextSolid[B,G,C], x, y: float64, str: string, flip = false) =
  var
    r: GlyphRect
    x = x
    y = y

  for c in str:
    self.mGlyph[].prepare(r, x, y, c.ord, not flip)
    if r.x2 >= r.x1:
      if flip:
        for i in r.y1..r.y2:
          self.mRen[].blendSolidVspan(i, r.x1, (r.x2 - r.x1 + 1),
                                      self.mColor, self.mGlyph[].span(i - r.y1))
      else:
        for i in r.y1..r.y2:
          self.mRen[].blendSolidVspan(i, r.x1, (r.x2 - r.x1 + 1),
                                      self.mColor, self.mGlyph[].span(r.y2 - i))

    x += r.dx
    y += r.dy


type
  ConstSpan* = object
    x*, len*: int
    covers*: ptr CoverType

  ScanlineSingleSpan = object
    mY: int
    mSpan: ConstSpan

  RendererRasterHtext*[ScanlineRenderer, GlyphGenerator] = object
    mRen: ptr ScanlineRenderer
    mGlyph: ptr GlyphGenerator

proc initConstSpan(x, len: int, covers: ptr CoverType): ConstSpan =
  result.x = x
  result.len = len
  result.covers = covers

proc initScanlineSingleSpan(x, y, len: int, covers: ptr CoverType): ScanlineSingleSpan =
  result.mY = y
  result.mSpan = initConstSpan(x, len, covers)

proc getY*(self: ScanlineSingleSpan): int =
  self.mY

proc numSpans*(self: ScanlineSingleSpan): int = 1

proc begin*(self: var ScanlineSingleSpan): ptr ConstSpan =
  self.mSpan.addr

proc initRendererRasterHtext*[R, G](ren: var R, glyph: var G): RendererRasterHtext[R,G] =
  result.mRen = ren.addr
  result.mGlyph = glyph.addr

proc renderText*[R, G](self: var RendererRasterHtext[R,G], x, y: float64, str: string, flip = false) =
  mixin prepare
  var
    r: GlyphRect
    x = x
    y = y

  for c in str:
    self.mGlyph[].prepare(r, x, y, c.ord, flip)
    if r.x2 >= r.x1:
      self.mRen[].prepare()
      if flip:
        for i in r.y1..r.y2:
          var span = initScanlineSingleSpan(r.x1, i, (r.x2 - r.x1 + 1), self.mGlyph[].span(r.y2 - i))
          self.mRen[].render(span)
      else:
        for i in r.y1..r.y2:
          var span = initScanlineSingleSpan(r.x1, i, (r.x2 - r.x1 + 1), self.mGlyph[].span(i - r.y1))
          self.mRen[].render(span)
    x += r.dx
    y += r.dy
