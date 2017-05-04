import fttypes, freetype, ftimage, ftsystem
include ftimport

proc FT_Outline_Decompose*(outline: ptr FT_Outline; func_interface: ptr FT_Outline_Funcs;
  user: pointer): FT_Error {.ftimport.}

proc FT_Outline_New*(library: FT_Library; numPoints: FT_UInt; numContours: FT_Int;
  anoutline: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_New_Internal*(memory: FT_Memory; numPoints: FT_UInt;
  numContours: FT_Int; anoutline: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Done*(library: FT_Library; outline: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Done_Internal*(memory: FT_Memory; outline: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Check*(outline: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Get_CBox*(outline: ptr FT_Outline; acbox: ptr FT_BBox){.ftimport.}

proc FT_Outline_Translate*(outline: ptr FT_Outline; xOffset: FT_Pos; yOffset: FT_Pos){.ftimport.}

proc FT_Outline_Copy*(source: ptr FT_Outline; target: ptr FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Transform*(outline: ptr FT_Outline; matrix: ptr FT_Matrix){.ftimport.}

proc FT_Outline_Embolden*(outline: ptr FT_Outline; strength: FT_Pos): FT_Error {.ftimport.}

proc FT_Outline_EmboldenXY*(outline: ptr FT_Outline; xstrength: FT_Pos;
  ystrength: FT_Pos): FT_Error {.ftimport.}

proc FT_Outline_Reverse*(outline: ptr FT_Outline){.ftimport.}

proc FT_Outline_Get_Bitmap*(library: FT_Library; outline: ptr FT_Outline;
  abitmap: ptr FT_Bitmap): FT_Error {.ftimport.}

proc FT_Outline_Render*(library: FT_Library; outline: ptr FT_Outline;
  params: ptr FT_Raster_Params): FT_Error {.ftimport.}

type
  FT_Orientation* = enum
    FT_ORIENTATION_TRUETYPE = 0, FT_ORIENTATION_POSTSCRIPT = 1, FT_ORIENTATION_NONE

const
  FT_ORIENTATION_FILL_RIGHT* = FT_ORIENTATION_TRUETYPE
  FT_ORIENTATION_FILL_LEFT* = FT_ORIENTATION_POSTSCRIPT

proc FT_Outline_Get_Orientation*(outline: ptr FT_Outline): FT_Orientation {.ftimport.}
