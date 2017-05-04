import freetype, fttypes
include ftimport

const
  FT_ADVANCE_FLAG_FAST_ONLY* = 0x20000000

proc FT_Get_Advance*(face: FT_Face; gindex: FT_UInt; load_flags: FT_Int32;
                    padvance: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Get_Advances*(face: FT_Face; start: FT_UInt; count: FT_UInt;
                     load_flags: FT_Int32; padvances: ptr FT_Fixed): FT_Error {.ftimport.}
