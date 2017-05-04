import fttypes, freetype
include ftimport

proc FT_Get_CID_Registry_Ordering_Supplement*(face: FT_Face;
  registry: ptr ptr cchar; ordering: ptr ptr cchar; supplement: ptr FT_Int): FT_Error {.ftimport.}

proc FT_Get_CID_Is_Internally_CID_Keyed*(face: FT_Face; is_cid: ptr FT_Bool): FT_Error {.ftimport.}

proc FT_Get_CID_From_Glyph_Index*(face: FT_Face; glyph_index: FT_UInt;
  cid: ptr FT_UInt): FT_Error {.ftimport.}
