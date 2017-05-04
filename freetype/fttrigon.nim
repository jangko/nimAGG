import fttypes, ftimage
include ftimport

type FT_Angle* = FT_Fixed

const
  FT_ANGLE_PI*  = 180 shl 16
  FT_ANGLE_2PI* = FT_ANGLE_PI * 2
  FT_ANGLE_PI2* = FT_ANGLE_PI / 2
  FT_ANGLE_PI4* = FT_ANGLE_PI / 4

proc FT_Sin*(angle: FT_Angle): FT_Fixed {.ft_import.}
proc FT_Cos*(angle: FT_Angle): FT_Fixed {.ft_import.}
proc FT_Tan*(angle: FT_Angle): FT_Fixed {.ft_import.}
proc FT_Atan2*(x, y: FT_Fixed): FT_Angle {.ft_import.}
proc FT_Angle_Diff*(angle1, angle2: FT_Angle): FT_Angle {.ft_import.}
proc FT_Vector_Unit*(vec: var FT_Vector, angle: FT_Angle) {.ft_import.}
proc FT_Vector_Rotate*(vec: var FT_Vector, angle: FT_Angle) {.ft_import.}
proc FT_Vector_Length*(vec: var FT_Vector): FT_Fixed {.ft_import.}
proc FT_Vector_Polarize*(vec: var FT_Vector, length: var FT_Fixed, angle: var FT_Angle) {.ft_import.}
proc FT_Vector_From_Polar*(vec: var FT_Vector, length: FT_Fixed, angle: FT_Angle) {.ft_import.}
