import fttypes, ftimage, freetype, t1tables
include ftimport

type
  FT_MM_Axis* = object
    name*: ptr FT_String
    minimum*: FT_Long
    maximum*: FT_Long

  FT_Multi_Master* = object
    num_axis*: FT_UInt
    num_designs*: FT_UInt
    axis*: array[T1_MAX_MM_AXIS, FT_MM_Axis]

  FT_Var_Axis* = object
    name*: ptr FT_String
    minimum*: FT_Fixed
    def*: FT_Fixed
    maximum*: FT_Fixed
    tag*: FT_ULong
    strid*: FT_UInt

  FT_Var_Named_Style* = object
    coords*: ptr FT_Fixed
    strid*: FT_UInt
    psid*: FT_UInt

  FT_MM_Var* = object
    num_axis*: FT_UInt
    num_designs*: FT_UInt
    num_namedstyles*: FT_UInt
    axis*: ptr FT_Var_Axis
    namedstyle*: ptr FT_Var_Named_Style


proc FT_Get_Multi_Master*(face: FT_Face; amaster: ptr FT_Multi_Master): FT_Error {.ftimport.}

proc FT_Get_MM_Var*(face: FT_Face; amaster: ptr ptr FT_MM_Var): FT_Error {.ftimport.}

proc FT_Set_MM_Design_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Long): FT_Error {.ftimport.}

proc FT_Set_Var_Design_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Get_Var_Design_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Set_MM_Blend_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Get_MM_Blend_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Set_Var_Blend_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Get_Var_Blend_Coordinates*(face: FT_Face; num_coords: FT_UInt;
  coords: ptr FT_Fixed): FT_Error {.ftimport.}
