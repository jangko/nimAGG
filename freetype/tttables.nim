import fttypes, freetype
include ftimport

type
  TT_Header* = object
    Table_Version*: FT_Fixed
    Font_Revision*: FT_Fixed
    CheckSum_Adjust*: FT_Long
    Magic_Number*: FT_Long
    Flags*: FT_UShort
    Units_Per_EM*: FT_UShort
    Created*: array[2, FT_Long]
    Modified*: array[2, FT_Long]
    xMin*: FT_Short
    yMin*: FT_Short
    xMax*: FT_Short
    yMax*: FT_Short
    Mac_Style*: FT_UShort
    Lowest_Rec_PPEM*: FT_UShort
    Font_Direction*: FT_Short
    Index_To_Loc_Format*: FT_Short
    Glyph_Data_Format*: FT_Short

  TT_HoriHeader* = object
    Version*: FT_Fixed
    Ascender*: FT_Short
    Descender*: FT_Short
    Line_Gap*: FT_Short
    advance_Width_Max*: FT_UShort
    min_Left_Side_Bearing*: FT_Short
    min_Right_Side_Bearing*: FT_Short
    xMax_Extent*: FT_Short
    caret_Slope_Rise*: FT_Short
    caret_Slope_Run*: FT_Short
    caret_Offset*: FT_Short
    Reserved*: array[4, FT_Short]
    metric_Data_Format*: FT_Short
    number_Of_HMetrics*: FT_UShort
    long_metrics*: pointer
    short_metrics*: pointer

  TT_VertHeader* = object
    Version*: FT_Fixed
    Ascender*: FT_Short
    Descender*: FT_Short
    Line_Gap*: FT_Short
    advance_Height_Max*: FT_UShort
    min_Top_Side_Bearing*: FT_Short
    min_Bottom_Side_Bearing*: FT_Short
    yMax_Extent*: FT_Short
    caret_Slope_Rise*: FT_Short
    caret_Slope_Run*: FT_Short
    caret_Offset*: FT_Short
    Reserved*: array[4, FT_Short]
    metric_Data_Format*: FT_Short
    number_Of_VMetrics*: FT_UShort
    long_metrics*: pointer
    short_metrics*: pointer

  TT_OS2* = object
    version*: FT_UShort
    xAvgCharWidth*: FT_Short
    usWeightClass*: FT_UShort
    usWidthClass*: FT_UShort
    fsType*: FT_UShort
    ySubscriptXSize*: FT_Short
    ySubscriptYSize*: FT_Short
    ySubscriptXOffset*: FT_Short
    ySubscriptYOffset*: FT_Short
    ySuperscriptXSize*: FT_Short
    ySuperscriptYSize*: FT_Short
    ySuperscriptXOffset*: FT_Short
    ySuperscriptYOffset*: FT_Short
    yStrikeoutSize*: FT_Short
    yStrikeoutPosition*: FT_Short
    sFamilyClass*: FT_Short
    panose*: array[10, FT_Byte]
    ulUnicodeRange1*: FT_ULong
    ulUnicodeRange2*: FT_ULong
    ulUnicodeRange3*: FT_ULong
    ulUnicodeRange4*: FT_ULong
    achVendID*: array[4, FT_Char]
    fsSelection*: FT_UShort
    usFirstCharIndex*: FT_UShort
    usLastCharIndex*: FT_UShort
    sTypoAscender*: FT_Short
    sTypoDescender*: FT_Short
    sTypoLineGap*: FT_Short
    usWinAscent*: FT_UShort
    usWinDescent*: FT_UShort
    ulCodePageRange1*: FT_ULong
    ulCodePageRange2*: FT_ULong
    sxHeight*: FT_Short
    sCapHeight*: FT_Short
    usDefaultChar*: FT_UShort
    usBreakChar*: FT_UShort
    usMaxContext*: FT_UShort
    usLowerOpticalPointSize*: FT_UShort
    usUpperOpticalPointSize*: FT_UShort

  TT_Postscript* = object
    FormatType*: FT_Fixed
    italicAngle*: FT_Fixed
    underlinePosition*: FT_Short
    underlineThickness*: FT_Short
    isFixedPitch*: FT_ULong
    minMemType42*: FT_ULong
    maxMemType42*: FT_ULong
    minMemType1*: FT_ULong
    maxMemType1*: FT_ULong

  TT_PCLT* = object
    Version*: FT_Fixed
    FontNumber*: FT_ULong
    Pitch*: FT_UShort
    xHeight*: FT_UShort
    Style*: FT_UShort
    TypeFamily*: FT_UShort
    CapHeight*: FT_UShort
    SymbolSet*: FT_UShort
    TypeFace*: array[16, FT_Char]
    CharacterComplement*: array[8, FT_Char]
    FileName*: array[6, FT_Char]
    StrokeWeight*: FT_Char
    WidthType*: FT_Char
    SerifStyle*: FT_Byte
    Reserved*: FT_Byte

  TT_MaxProfile* = object
    version*: FT_Fixed
    numGlyphs*: FT_UShort
    maxPoints*: FT_UShort
    maxContours*: FT_UShort
    maxCompositePoints*: FT_UShort
    maxCompositeContours*: FT_UShort
    maxZones*: FT_UShort
    maxTwilightPoints*: FT_UShort
    maxStorage*: FT_UShort
    maxFunctionDefs*: FT_UShort
    maxInstructionDefs*: FT_UShort
    maxStackElements*: FT_UShort
    maxSizeOfInstructions*: FT_UShort
    maxComponentElements*: FT_UShort
    maxComponentDepth*: FT_UShort

  FT_Sfnt_Tag* = enum
    FT_SFNT_HEAD, FT_SFNT_MAXP, FT_SFNT_OS2, FT_SFNT_HHEA, FT_SFNT_VHEA,
    FT_SFNT_POST, FT_SFNT_PCLT, FT_SFNT_MAX

const
  ft_sfnt_head* = FT_SFNT_HEAD
  ft_sfnt_maxp* = FT_SFNT_MAXP
  ft_sfnt_os2* = FT_SFNT_OS2
  ft_sfnt_hhea* = FT_SFNT_HHEA
  ft_sfnt_vhea* = FT_SFNT_VHEA
  ft_sfnt_post* = FT_SFNT_POST
  ft_sfnt_pclt* = FT_SFNT_PCLT

proc FT_Get_Sfnt_Table*(face: FT_Face, tag: FT_Sfnt_Tag): pointer {.ft_import.}

proc FT_Load_Sfnt_Table*(face: FT_Face, tag: FT_ULong, offset: FT_Long,
  buffer: ptr FT_Byte, length: ptr FT_ULong): FT_Error {.ft_import.}

proc FT_Sfnt_Table_Info*(face: FT_Face, table_index: FT_UInt,
  tag: ptr FT_ULong, length: ptr FT_ULong): FT_Error {.ft_import.}

proc FT_Get_CMap_Language_ID*(charmap: FT_CharMap): FT_ULong {.ft_import.}

proc FT_Get_CMap_Format*(charmap: FT_CharMap): FT_Long {.ft_import.}
