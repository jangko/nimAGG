import fttypes, freetype
include ftimport

type
  FT_SfntName* = object
    platform_id*: FT_UShort
    encoding_id*: FT_UShort
    language_id*: FT_UShort
    name_id*: FT_UShort
    string*: ptr FT_Byte
    string_len*: FT_UInt

proc FT_Get_Sfnt_Name_Count*(face: FT_Face): FT_UInt {.ftimport.}

proc FT_Get_Sfnt_Name*(face: FT_Face; idx: FT_UInt; aname: ptr FT_SfntName): FT_Error {.ftimport.}

const
  FT_PARAM_TAG_IGNORE_PREFERRED_FAMILY* = FT_MAKE_TAG('i', 'g', 'p', 'f')
  FT_PARAM_TAG_IGNORE_PREFERRED_SUBFAMILY* = FT_MAKE_TAG('i', 'g', 'p', 's')
