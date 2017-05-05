import fttypes, freetype, ftimage
include ftimport

proc FT_Get_PFR_Metrics*(face: FT_Face; aoutline_resolution: ptr FT_UInt;
  ametrics_resolution: ptr FT_UInt; ametrics_x_scale: ptr FT_Fixed;
  ametrics_y_scale: ptr FT_Fixed): FT_Error {.ftimport.}

proc FT_Get_PFR_Kerning*(face: FT_Face; left: FT_UInt; right: FT_UInt;
  avector: ptr FT_Vector): FT_Error {.ftimport.}

proc FT_Get_PFR_Advance*(face: FT_Face; gindex: FT_UInt; aadvance: ptr FT_Pos): FT_Error {.ftimport.}
