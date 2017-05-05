import freetype, fttypes, ftimage
include ftimport

proc FT_Outline_Get_BBox*(outline: ptr FT_Outline; abbox: ptr FT_BBox): FT_Error {.ftimport.}
