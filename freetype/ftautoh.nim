import fttypes, freetype
include ftimport

const
  FT_AUTOHINTER_SCRIPT_NONE* = 0
  FT_AUTOHINTER_SCRIPT_LATIN* = 1
  FT_AUTOHINTER_SCRIPT_CJK* = 2
  FT_AUTOHINTER_SCRIPT_INDIC* = 3

type
  FT_Prop_GlyphToScriptMap* = object
    face*: FT_Face
    map*: ptr FT_UShort

  FT_Prop_IncreaseXHeight* = object
    face*: FT_Face
    limit*: FT_UInt
