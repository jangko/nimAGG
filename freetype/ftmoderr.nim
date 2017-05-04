import fttypes, tables

FT_ERROR_DEF(FT_ModErr): [
  {Base,      0x000, "base module"},
  {Autofit,   0x100, "autofitter module"},
  {BDF,       0x200, "BDF module"},
  {Bzip2,     0x300, "Bzip2 module"},
  {Cache,     0x400, "cache module"},
  {CFF,       0x500, "CFF module"},
  {CID,       0x600, "CID module"},
  {Gzip,      0x700, "Gzip module"},
  {LZW,       0x800, "LZW module"},
  {OTvalid,   0x900, "OpenType validation module"},
  {PCF,       0xA00, "PCF module"},
  {PFR,       0xB00, "PFR module"},
  {PSaux,     0xC00, "PS auxiliary module"},
  {PShinter,  0xD00, "PS hinter module"},
  {PSnames,   0xE00, "PS names module"},
  {Raster,    0xF00, "raster module"},
  {SFNT,     0x1000, "SFNT module"},
  {Smooth,   0x1100, "smooth raster module"},
  {TrueType, 0x1200, "TrueType module"},
  {Type1,    0x1300, "Type 1 module"},
  {Type42,   0x1400, "Type 42 module"},
  {Winfonts, 0x1500, "Windows FON/FNT module"},
  {GXvalid,  0x1600, "GX validation module"}]

type
  FT_ModErr_Msg* = object
    errors: TableRef[int, string]

proc newModErrMsg*(): FT_ModErr_Msg =
  result.errors = FT_ModErr_Table.newTable()

proc errorMessage*(self: FT_ModErr_Msg, errorCode: int): string =
  if self.errors.hasKey(errorCode):
    result = self.errors[errorCode]
  else:
    result = ""
