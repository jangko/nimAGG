import fttypes, freetype, ftsystem
include ftimport

proc FT_Get_Font_Format*(face: FT_Face): ptr cchar {.ftimport.}

proc FT_Get_X11_Font_Format*(face: FT_Face): ptr cchar {.ftimport.}
