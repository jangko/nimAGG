import fttypes, freetype, ftimage
include ftimport

proc FT_Bitmap_Init*(abitmap: var FT_Bitmap) {.ftimport.}

proc FT_Bitmap_New*(abitmap: var FT_Bitmap) {.ftimport.}

proc FT_Bitmap_Copy*(library: FT_Library;
  source: var FT_Bitmap; target: var FT_Bitmap): FT_Error {.ftimport.}

proc FT_Bitmap_Embolden*(library: FT_Library; bitmap: var FT_Bitmap,
  xStrength: FT_Pos; yStrength: FT_Pos): FT_Error {.ftimport.}

proc FT_Bitmap_Convert*(library: FT_Library; source: var FT_Bitmap;
  target: var FT_Bitmap; alignment: FT_Int): FT_Error {.ftimport.}

proc FT_GlyphSlot_Own_Bitmap*(slot: FT_GlyphSlot): FT_Error {.ftimport.}

proc FT_Bitmap_Done*(library: FT_Library; bitmap: var FT_Bitmap): FT_Error {.ftimport.}
