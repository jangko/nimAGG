import basics

type
  GlyphDataType* = enum
    glyph_data_invalid = 0
    glyph_data_mono    = 1
    glyph_data_gray8   = 2
    glyph_data_outline = 3

  GlyphRendering* = enum
    glyph_ren_native_mono
    glyph_ren_native_gray8
    glyph_ren_outline
    glyph_ren_mono
    glyph_ren_gray8

  GlyphCache* = ref object
    glyphIndex*: int
    data*: seq[uint8]
    dataSize*: int
    dataType*: GlyphDataType
    bounds*: RectI
    advanceX*, advanceY*: float64
