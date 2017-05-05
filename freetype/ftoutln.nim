import fttypes, freetype, ftimage, ftsystem
include ftimport

proc FT_Outline_Decompose*(outline: var FT_Outline; func_interface: var FT_Outline_Funcs;
  user: pointer): FT_Error {.ftimport.}

proc decompose*(outline: var FT_Outline; funcInterface: var FT_Outline_Funcs;
  user: pointer): FT_Error {.inline.} =
  FT_Outline_Decompose(outline, funcInterface, user)

proc FT_Outline_New*(library: FT_Library; numPoints: FT_UInt; numContours: FT_Int;
  anoutline: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_New_Internal*(memory: FT_Memory; numPoints: FT_UInt;
  numContours: FT_Int; anoutline: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Done*(library: FT_Library; outline: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Done_Internal*(memory: FT_Memory; outline: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Check*(outline: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Get_CBox*(outline: var FT_Outline; acbox: var FT_BBox){.ftimport.}

proc FT_Outline_Translate*(outline: var FT_Outline; xOffset: FT_Pos; yOffset: FT_Pos){.ftimport.}

proc FT_Outline_Copy*(source: var FT_Outline; target: var FT_Outline): FT_Error {.ftimport.}

proc FT_Outline_Transform*(outline: var FT_Outline; matrix: var FT_Matrix){.ftimport.}

proc FT_Outline_Embolden*(outline: var FT_Outline; strength: FT_Pos): FT_Error {.ftimport.}

proc FT_Outline_EmboldenXY*(outline: var FT_Outline; xstrength: FT_Pos;
  ystrength: FT_Pos): FT_Error {.ftimport.}

proc FT_Outline_Reverse*(outline: var FT_Outline){.ftimport.}

proc FT_Outline_Get_Bitmap*(library: FT_Library; outline: var FT_Outline;
  abitmap: var FT_Bitmap): FT_Error {.ftimport.}

proc FT_Outline_Render*(library: FT_Library; outline: var FT_Outline;
  params: var FT_Raster_Params): FT_Error {.ftimport.}

type
  FT_Orientation* = enum
    FT_ORIENTATION_TRUETYPE = 0, FT_ORIENTATION_POSTSCRIPT = 1, FT_ORIENTATION_NONE

const
  FT_ORIENTATION_FILL_RIGHT* = FT_ORIENTATION_TRUETYPE
  FT_ORIENTATION_FILL_LEFT*  = FT_ORIENTATION_POSTSCRIPT

proc FT_Outline_Get_Orientation*(outline: var FT_Outline): FT_Orientation {.ftimport.}
