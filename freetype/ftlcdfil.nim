import fttypes, freetype, ftsystem
include ftimport

type
  FT_LcdFilter* = enum
    FT_LCD_FILTER_NONE = 0, FT_LCD_FILTER_DEFAULT = 1, FT_LCD_FILTER_LIGHT = 2,
    FT_LCD_FILTER_LEGACY1 = 3, FT_LCD_FILTER_LEGACY = 16, FT_LCD_FILTER_MAX


proc FT_Library_SetLcdFilter*(library: FT_Library; filter: FT_LcdFilter): FT_Error {.ftimport.}

proc FT_Library_SetLcdFilterWeights*(library: FT_Library; weights: ptr cuchar): FT_Error {.ftimport.}
