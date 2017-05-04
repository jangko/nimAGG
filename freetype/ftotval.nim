import fttypes, freetype
include ftimport

const
  FT_VALIDATE_BASE* = 0x00000100
  FT_VALIDATE_GDEF* = 0x00000200
  FT_VALIDATE_GPOS* = 0x00000400
  FT_VALIDATE_GSUB* = 0x00000800
  FT_VALIDATE_JSTF* = 0x00001000
  FT_VALIDATE_MATH* = 0x00002000
  FT_VALIDATE_OT* = (FT_VALIDATE_BASE or FT_VALIDATE_GDEF or FT_VALIDATE_GPOS or
      FT_VALIDATE_GSUB or FT_VALIDATE_JSTF or FT_VALIDATE_MATH)

proc FT_OpenType_Validate*(face: FT_Face; validation_flags: FT_UInt;
                          BASE_table: ptr FT_Bytes; GDEF_table: ptr FT_Bytes;
                          GPOS_table: ptr FT_Bytes; GSUB_table: ptr FT_Bytes;
                          JSTF_table: ptr FT_Bytes): FT_Error {.ftimport.}

proc FT_OpenType_Free*(face: FT_Face; table: FT_Bytes){.ftimport.}
