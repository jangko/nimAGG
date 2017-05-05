import fttypes, freetype, ftsystem
include ftimport

const
  FT_GASP_NO_TABLE* = - 1
  FT_GASP_DO_GRIDFIT* = 0x00000001
  FT_GASP_DO_GRAY* = 0x00000002
  FT_GASP_SYMMETRIC_SMOOTHING* = 0x00000008
  FT_GASP_SYMMETRIC_GRIDFIT* = 0x00000010

proc FT_Get_Gasp*(face: FT_Face; ppem: FT_UInt): FT_Int {.ftimport.}
