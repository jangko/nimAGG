import fttypes, freetype, ftimage, ftglyph
include ftimport

type
  FT_Stroker* = distinct pointer #ptr FT_StrokerRec

  FT_Stroker_LineJoin* = enum
    FT_STROKER_LINEJOIN_ROUND = 0, FT_STROKER_LINEJOIN_BEVEL = 1,
    FT_STROKER_LINEJOIN_MITER_VARIABLE = 2, FT_STROKER_LINEJOIN_MITER_FIXED = 3

  FT_Stroker_LineCap* = enum
    FT_STROKER_LINECAP_BUTT = 0, FT_STROKER_LINECAP_ROUND, FT_STROKER_LINECAP_SQUARE

  FT_StrokerBorder* = enum
    FT_STROKER_BORDER_LEFT = 0, FT_STROKER_BORDER_RIGHT

const
  FT_STROKER_LINEJOIN_MITER* = FT_STROKER_LINEJOIN_MITER_VARIABLE

proc FT_Outline_GetInsideBorder*(outline: ptr FT_Outline): FT_StrokerBorder {.ftimport.}

proc FT_Outline_GetOutsideBorder*(outline: ptr FT_Outline): FT_StrokerBorder {.ftimport.}

proc FT_Stroker_New*(library: FT_Library; astroker: ptr FT_Stroker): FT_Error {.ftimport.}

proc FT_Stroker_Set*(stroker: FT_Stroker; radius: FT_Fixed; line_cap: FT_Stroker_LineCap;
  line_join: FT_Stroker_LineJoin; miter_limit: FT_Fixed) {.ftimport.}

proc FT_Stroker_Rewind*(stroker: FT_Stroker) {.ftimport.}

proc FT_Stroker_ParseOutline*(stroker: FT_Stroker; outline: ptr FT_Outline;
  opened: FT_Bool): FT_Error {.ftimport.}

proc FT_Stroker_BeginSubPath*(stroker: FT_Stroker; to: ptr FT_Vector; open: FT_Bool): FT_Error {.ftimport.}

proc FT_Stroker_EndSubPath*(stroker: FT_Stroker): FT_Error {.ftimport.}

proc FT_Stroker_LineTo*(stroker: FT_Stroker; to: ptr FT_Vector): FT_Error {.ftimport.}

proc FT_Stroker_ConicTo*(stroker: FT_Stroker; control: ptr FT_Vector;
  to: ptr FT_Vector): FT_Error {.ftimport.}

proc FT_Stroker_CubicTo*(stroker: FT_Stroker; control1: ptr FT_Vector;
  control2: ptr FT_Vector; to: ptr FT_Vector): FT_Error {.ftimport.}

proc FT_Stroker_GetBorderCounts*(stroker: FT_Stroker; border: FT_StrokerBorder;
  anum_points: ptr FT_UInt; anum_contours: ptr FT_UInt): FT_Error {.ftimport.}

proc FT_Stroker_ExportBorder*(stroker: FT_Stroker; border: FT_StrokerBorder;
  outline: ptr FT_Outline) {.ftimport.}

proc FT_Stroker_GetCounts*(stroker: FT_Stroker; anum_points: ptr FT_UInt;
  anum_contours: ptr FT_UInt): FT_Error {.ftimport.}

proc FT_Stroker_Export*(stroker: FT_Stroker; outline: ptr FT_Outline) {.ftimport.}

proc FT_Stroker_Done*(stroker: FT_Stroker) {.ftimport.}

proc FT_Glyph_Stroke*(pglyph: ptr FT_Glyph; stroker: FT_Stroker; destroy: FT_Bool): FT_Error {.ftimport.}

proc FT_Glyph_StrokeBorder*(pglyph: ptr FT_Glyph; stroker: FT_Stroker;
  inside: FT_Bool; destroy: FT_Bool): FT_Error {.ftimport.}
