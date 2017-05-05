import fttypes, freetype
include ftimport

proc FT_New_Size*(face: FT_Face; size: ptr FT_Size): FT_Error {.ftimport.}

proc FT_Done_Size*(size: FT_Size): FT_Error {.ftimport.}

proc FT_Activate_Size*(size: FT_Size): FT_Error {.ftimport.}
