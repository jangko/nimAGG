import fttypes, ftimage, ftsystem
include ftimport

type
  FT_Encoding* = distinct uint32

proc FT_ENC_TAG*[T](a, b, c, d: T): FT_Encoding =
  result = FT_Encoding((FT_UInt32(a) shl 24) or
           (FT_UInt32(b) shl 16) or
           (FT_UInt32(c) shl  8) or
            FT_UInt32(d))

const
  FT_ENCODING_NONE*      = FT_ENC_TAG(0, 0, 0, 0)
  FT_ENCODING_MS_SYMBOL* = FT_ENC_TAG('s', 'y', 'm', 'b')
  FT_ENCODING_UNICODE*   = FT_ENC_TAG('u', 'n', 'i', 'c')

  FT_ENCODING_SJIS*      = FT_ENC_TAG('s', 'j', 'i', 's')
  FT_ENCODING_GB2312*    = FT_ENC_TAG('g', 'b', ' ', ' ')
  FT_ENCODING_BIG5*      = FT_ENC_TAG('b', 'i', 'g', '5')
  FT_ENCODING_WANSUNG*   = FT_ENC_TAG('w', 'a', 'n', 's')
  FT_ENCODING_JOHAB*     = FT_ENC_TAG('j', 'o', 'h', 'a')

  # for backwards compatibility
  FT_ENCODING_MS_SJIS*    = FT_ENCODING_SJIS
  FT_ENCODING_MS_GB2312*  = FT_ENCODING_GB2312
  FT_ENCODING_MS_BIG5*    = FT_ENCODING_BIG5
  FT_ENCODING_MS_WANSUNG* = FT_ENCODING_WANSUNG
  FT_ENCODING_MS_JOHAB*   = FT_ENCODING_JOHAB

  FT_ENCODING_ADOBE_STANDARD* = FT_ENC_TAG('A', 'D', 'O', 'B')
  FT_ENCODING_ADOBE_EXPERT*   = FT_ENC_TAG('A', 'D', 'B', 'E')
  FT_ENCODING_ADOBE_CUSTOM*   = FT_ENC_TAG('A', 'D', 'B', 'C')
  FT_ENCODING_ADOBE_LATIN_1*  = FT_ENC_TAG('l', 'a', 't', '1')

  FT_ENCODING_OLD_LATIN_2*    = FT_ENC_TAG('l', 'a', 't', '2')
  FT_ENCODING_APPLE_ROMAN*    = FT_ENC_TAG('a', 'r', 'm', 'n')

type
  FT_Glyph_Metrics* = object
    width*: FT_Pos
    height*: FT_Pos
    horiBearingX*: FT_Pos
    horiBearingY*: FT_Pos
    horiAdvance*: FT_Pos
    vertBearingX*: FT_Pos
    vertBearingY*: FT_Pos
    vertAdvance*: FT_Pos

  FT_Bitmap_Size* = object
    height*: FT_Short
    width*: FT_Short
    size*: FT_Pos
    x_ppem*: FT_Pos
    y_ppem*: FT_Pos

  FT_Library*   = distinct pointer #ptr FT_LibraryRec
  FT_Module*    = distinct pointer #ptr FT_ModuleRec
  FT_Driver*    = distinct pointer #ptr FT_DriverRec
  FT_Renderer*  = distinct pointer #ptr FT_RendererRec
  FT_Face*      = ptr FT_FaceRec
  FT_Size*      = ptr FT_SizeRec
  FT_GlyphSlot* = ptr FT_GlyphSlotRec
  FT_CharMap*   = ptr FT_CharMapRec

  FT_CharMapRec* = object
    face*: FT_Face
    encoding*: FT_Encoding
    platform_id*: FT_UShort
    encoding_id*: FT_UShort

  FT_Face_Internal* = distinct pointer #ptr FT_Face_InternalRec

  FT_FaceRec* = object
    num_faces*: FT_Long
    face_index*: FT_Long
    face_flags*: FT_Long
    style_flags*: FT_Long
    num_glyphs*: FT_Long
    family_name*: ptr FT_String
    style_name*: ptr FT_String
    num_fixed_sizes*: FT_Int
    available_sizes*: ptr FT_Bitmap_Size
    num_charmaps*: FT_Int
    charmaps*: ptr FT_CharMap
    `generic`*: FT_Generic
    bbox*: FT_BBox
    units_per_EM*: FT_UShort
    ascender*: FT_Short
    descender*: FT_Short
    height*: FT_Short
    max_advance_width*: FT_Short
    max_advance_height*: FT_Short
    underline_position*: FT_Short
    underline_thickness*: FT_Short
    glyph*: FT_GlyphSlot
    size*: FT_Size
    charmap*: FT_CharMap
    driver*: FT_Driver
    memory*: FT_Memory
    stream*: FT_Stream
    sizes_list*: FT_ListRec
    autohint*: FT_Generic
    extensions*: pointer
    internal*: FT_Face_Internal

  FT_Size_Internal* = distinct pointer #ptr FT_Size_InternalRec

  FT_Size_Metrics* = object
    x_ppem*: FT_UShort
    y_ppem*: FT_UShort
    x_scale*: FT_Fixed
    y_scale*: FT_Fixed
    ascender*: FT_Pos
    descender*: FT_Pos
    height*: FT_Pos
    max_advance*: FT_Pos

  FT_SizeRec* = object
    face*: FT_Face
    `generic`*: FT_Generic
    metrics*: FT_Size_Metrics
    internal*: FT_Size_Internal

  FT_SubGlyph* = distinct pointer#ptr FT_SubGlyphRec

  FT_Slot_Internal* = distinct pointer#ptr FT_Slot_InternalRec

  FT_GlyphSlotRec* = object
    library*: FT_Library
    face*: FT_Face
    next*: FT_GlyphSlot
    reserved*: FT_UInt
    `generic`*: FT_Generic
    metrics*: FT_Glyph_Metrics
    linearHoriAdvance*: FT_Fixed
    linearVertAdvance*: FT_Fixed
    advance*: FT_Vector
    format*: FT_Glyph_Format
    bitmap*: FT_Bitmap
    bitmap_left*: FT_Int
    bitmap_top*: FT_Int
    outline*: FT_Outline
    num_subglyphs*: FT_UInt
    subglyphs*: FT_SubGlyph
    control_data*: pointer
    control_len*: clong
    lsb_delta*: FT_Pos
    rsb_delta*: FT_Pos
    other*: pointer
    internal*: FT_Slot_Internal

const
  ft_encoding_none*           = FT_ENCODING_NONE
  ft_encoding_unicode*        = FT_ENCODING_UNICODE
  ft_encoding_symbol*         = FT_ENCODING_MS_SYMBOL
  ft_encoding_latin_1*        = FT_ENCODING_ADOBE_LATIN_1
  ft_encoding_latin_2*        = FT_ENCODING_OLD_LATIN_2
  ft_encoding_sjis*           = FT_ENCODING_SJIS
  ft_encoding_gb2312*         = FT_ENCODING_GB2312
  ft_encoding_big5*           = FT_ENCODING_BIG5
  ft_encoding_wansung*        = FT_ENCODING_WANSUNG
  ft_encoding_johab*          = FT_ENCODING_JOHAB
  ft_encoding_adobe_standard* = FT_ENCODING_ADOBE_STANDARD
  ft_encoding_adobe_expert*   = FT_ENCODING_ADOBE_EXPERT
  ft_encoding_adobe_custom*   = FT_ENCODING_ADOBE_CUSTOM
  ft_encoding_apple_roman*    = FT_ENCODING_APPLE_ROMAN

const
  FT_FACE_FLAG_SCALABLE*         = (1 shl 0)
  FT_FACE_FLAG_FIXED_SIZES*      = (1 shl 1)
  FT_FACE_FLAG_FIXED_WIDTH*      = (1 shl 2)
  FT_FACE_FLAG_SFNT*             = (1 shl 3)
  FT_FACE_FLAG_HORIZONTAL*       = (1 shl 4)
  FT_FACE_FLAG_VERTICAL*         = (1 shl 5)
  FT_FACE_FLAG_KERNING*          = (1 shl 6)
  FT_FACE_FLAG_FAST_GLYPHS*      = (1 shl 7)
  FT_FACE_FLAG_MULTIPLE_MASTERS* = (1 shl 8)
  FT_FACE_FLAG_GLYPH_NAMES*      = (1 shl 9)
  FT_FACE_FLAG_EXTERNAL_STREAM*  = (1 shl 10)
  FT_FACE_FLAG_HINTER*           = (1 shl 11)
  FT_FACE_FLAG_CID_KEYED*        = (1 shl 12)
  FT_FACE_FLAG_TRICKY*           = (1 shl 13)
  FT_FACE_FLAG_COLOR*            = (1 shl 14)

template FT_HAS_HORIZONTAL*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_HORIZONTAL) != 0)

template FT_HAS_VERTICAL*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_VERTICAL) != 0)

template FT_HAS_KERNING*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_KERNING) != 0)

template FT_IS_SCALABLE*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_SCALABLE) != 0)

template FT_IS_SFNT*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_SFNT) != 0)

template FT_IS_FIXED_WIDTH*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_FIXED_WIDTH) != 0)

template FT_HAS_FIXED_SIZES*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_FIXED_SIZES) != 0)

template FT_HAS_FAST_GLYPHS*(face: untyped): untyped =
  false

template FT_HAS_GLYPH_NAMES*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_GLYPH_NAMES) != 0)

template FT_HAS_MULTIPLE_MASTERS*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_MULTIPLE_MASTERS) != 0)

template FT_IS_NAMED_INSTANCE*(face: untyped): untyped =
  (((face).face_index and 0x7FFF0000) != 0)

template FT_IS_CID_KEYED*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_CID_KEYED) != 0)

template FT_IS_TRICKY*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_TRICKY) != 0)

template FT_HAS_COLOR*(face: untyped): untyped =
  (((face).face_flags and FT_FACE_FLAG_COLOR) != 0)

const
  FT_STYLE_FLAG_ITALIC* = (1 shl 0)
  FT_STYLE_FLAG_BOLD*   = (1 shl 1)

proc FT_Init_FreeType*(alibrary: var FT_Library): FT_Error {.ft_import.}
proc FT_Done_FreeType*(library: FT_Library): FT_Error {.ft_import.}

proc init*(lib: var FT_Library): FT_Error {.inline.} =
  FT_Init_FreeType(lib)

proc done*(lib: FT_Library): FT_Error {.inline,discardable.} =
  FT_Done_FreeType(lib)

const
  FT_OPEN_MEMORY*   = 0x00000001
  FT_OPEN_STREAM*   = 0x00000002
  FT_OPEN_PATHNAME* = 0x00000004
  FT_OPEN_DRIVER*   = 0x00000008
  FT_OPEN_PARAMS*   = 0x00000010
  ft_open_memory*   = FT_OPEN_MEMORY
  ft_open_stream*   = FT_OPEN_STREAM
  ft_open_pathname* = FT_OPEN_PATHNAME
  ft_open_driver*   = FT_OPEN_DRIVER
  ft_open_params*   = FT_OPEN_PARAMS

type
  FT_Parameter* = object
    tag*: FT_ULong
    data*: FT_Pointer

  FT_Open_Args* = object
    flags*: FT_UInt
    memory_base*: ptr FT_Byte
    memory_size*: FT_Long
    pathname*: ptr FT_String
    stream*: FT_Stream
    driver*: FT_Module
    num_params*: FT_Int
    params*: ptr FT_Parameter

proc FT_New_Face*(library: FT_Library; filepathname: cstring; face_index: FT_Long;
  aface: var FT_Face): FT_Error {.ft_import.}
  
proc FT_New_Memory_Face*(library: FT_Library; file_base: cstring;
  file_size: FT_Long; face_index: FT_Long; aface: var FT_Face): FT_Error {.ft_import.}
  
proc FT_Open_Face*(library: FT_Library; args: var FT_Open_Args; face_index: FT_Long;
  aface: var FT_Face): FT_Error {.ft_import.}
  
proc FT_Attach_File*(face: FT_Face; filepathname: cstring): FT_Error {.ft_import.}
proc FT_Attach_Stream*(face: FT_Face; parameters: var FT_Open_Args): FT_Error {.ft_import.}
proc FT_Reference_Face*(face: FT_Face): FT_Error {.ft_import.}
proc FT_Done_Face*(face: FT_Face): FT_Error {.ft_import.}
proc FT_Select_Size*(face: FT_Face; strike_index: FT_Int): FT_Error {.ft_import.}

proc newFace*(lib: FT_Library, filePathName: string; faceIndex: int; face: var FT_Face): FT_Error {.inline.} =
  FT_New_Face(lib, filePathName, FT_Long(faceIndex), face)

proc done*(face: FT_Face): FT_Error {.inline,discardable.} =
  FT_Done_Face(face)

type
  FT_Size_Request_Type* = enum
    FT_SIZE_REQUEST_TYPE_NOMINAL, FT_SIZE_REQUEST_TYPE_REAL_DIM,
    FT_SIZE_REQUEST_TYPE_BBOX, FT_SIZE_REQUEST_TYPE_CELL,
    FT_SIZE_REQUEST_TYPE_SCALES, FT_SIZE_REQUEST_TYPE_MAX

  FT_Size_Request* = object
    typ*: FT_Size_Request_Type
    width*: FT_Long
    height*: FT_Long
    horiResolution*: FT_UInt
    vertResolution*: FT_UInt

proc FT_Request_Size*(face: FT_Face; req: var FT_Size_Request): FT_Error {.ft_import.}

proc FT_Set_Char_Size*(face: FT_Face; char_width, char_height: FT_F26Dot6;
  horz_resolution, vert_resolution: FT_UInt): FT_Error {.ft_import.}
  
proc FT_Set_Pixel_Sizes*(face: FT_Face; pixel_width: FT_UInt; pixel_height: FT_UInt): FT_Error {.ft_import.}
proc FT_Load_Glyph*(face: FT_Face; glyph_index: FT_UInt; load_flags: FT_Int32): FT_Error {.ft_import.}
proc FT_Load_Char*(face: FT_Face; char_code: FT_ULong; load_flags: FT_Int32): FT_Error {.ft_import.}

proc setCharSize*(face: FT_Face; charWidth, charHeight: FT_F26Dot6;
  horzResolution, vertResolution: FT_UInt): FT_Error {.inline,discardable.} =
  FT_Set_Char_Size(face, FT_F26Dot6(charWidth), FT_F26Dot6(charHeight),
    FT_UInt(horzResolution), FT_UInt(vertResolution))

proc setPixelSizes*(face: FT_Face; pixelWidth, pixelHeight: FT_UInt): FT_Error {.inline,discardable.} =
  FT_Set_Pixel_Sizes(face, pixelWidth, pixelHeight)

proc loadGlyph*(face: FT_Face; glyphIndex: FT_UInt; loadFlags: FT_Int32): FT_Error {.inline,discardable.} =
  FT_Load_Glyph(face, glyphIndex, loadFlags)

proc FT_LOAD_TARGET[T](x: T): FT_Int32 {.compileTime.} =
  result = FT_Int32(FT_Int32(x) and 15) shl 16

type
  FT_Render_Mode* = enum
    FT_RENDER_MODE_NORMAL = 0, FT_RENDER_MODE_LIGHT, FT_RENDER_MODE_MONO,
    FT_RENDER_MODE_LCD, FT_RENDER_MODE_LCD_V, FT_RENDER_MODE_MAX

const
  FT_LOAD_DEFAULT*                      = 0x00000000
  FT_LOAD_NO_SCALE*                     = (1 shl 0)
  FT_LOAD_NO_HINTING*                   = (1 shl 1)
  FT_LOAD_RENDER*                       = (1 shl 2)
  FT_LOAD_NO_BITMAP*                    = (1 shl 3)
  FT_LOAD_VERTICAL_LAYOUT*              = (1 shl 4)
  FT_LOAD_FORCE_AUTOHINT*               = (1 shl 5)
  FT_LOAD_CROP_BITMAP*                  = (1 shl 6)
  FT_LOAD_PEDANTIC*                     = (1 shl 7)
  FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH*  = (1 shl 9)
  FT_LOAD_NO_RECURSE*                   = (1 shl 10)
  FT_LOAD_IGNORE_TRANSFORM*             = (1 shl 11)
  FT_LOAD_MONOCHROME*                   = (1 shl 12)
  FT_LOAD_LINEAR_DESIGN*                = (1 shl 13)
  FT_LOAD_NO_AUTOHINT*                  = (1 shl 15)
  FT_LOAD_COLOR*                        = (1 shl 20)
  FT_LOAD_COMPUTE_METRICS*              = (1 shl 21)
  FT_LOAD_BITMAP_METRICS_ONLY*          = (1 shl 22)
  FT_LOAD_ADVANCE_ONLY*                 = (1 shl 8)
  FT_LOAD_SBITS_ONLY*                   = (1 shl 14)

  FT_LOAD_TARGET_NORMAL*  = FT_LOAD_TARGET(FT_RENDER_MODE_NORMAL)
  FT_LOAD_TARGET_LIGHT*   = FT_LOAD_TARGET(FT_RENDER_MODE_LIGHT)
  FT_LOAD_TARGET_MONO*    = FT_LOAD_TARGET(FT_RENDER_MODE_MONO)
  FT_LOAD_TARGET_LCD*     = FT_LOAD_TARGET(FT_RENDER_MODE_LCD)
  FT_LOAD_TARGET_LCD_V*   = FT_LOAD_TARGET(FT_RENDER_MODE_LCD_V)


template FT_LOAD_TARGET_MODE*(x: untyped): untyped =
  ((FT_Render_Mode)(((x) shr 16) and 15))

proc FT_Set_Transform*(face: FT_Face; matrix: var FT_Matrix; delta: var FT_Vector) {.ft_import.}

const
  ft_render_mode_normal* = FT_RENDER_MODE_NORMAL
  ft_render_mode_mono*   = FT_RENDER_MODE_MONO

proc FT_Render_Glyph*(slot: FT_GlyphSlot; render_mode: FT_Render_Mode): FT_Error {.ft_import.}

proc render*(slot: FT_GlyphSlot; renderMode: FT_Render_Mode): FT_Error {.inline,discardable.} =
  FT_Render_Glyph(slot, renderMode)

type
  FT_Kerning_Mode* = enum
    FT_KERNING_DEFAULT = 0, FT_KERNING_UNFITTED, FT_KERNING_UNSCALED

const
  ft_kerning_default*  = FT_KERNING_DEFAULT
  ft_kerning_unfitted* = FT_KERNING_UNFITTED
  ft_kerning_unscaled* = FT_KERNING_UNSCALED

proc FT_Get_Kerning*(face: FT_Face; left_glyph: FT_UInt; right_glyph: FT_UInt;
  kern_mode: FT_UInt; akerning: var FT_Vector): FT_Error {.ft_import.}
  
proc FT_Get_Track_Kerning*(face: FT_Face; point_size: FT_Fixed; degree: FT_Int;
  akerning: var FT_Fixed): FT_Error {.ft_import.}
  
proc FT_Get_Glyph_Name*(face: FT_Face; glyph_index: FT_UInt; buffer: FT_Pointer;
  buffer_max: FT_UInt): FT_Error {.ft_import.}
  
proc FT_Get_Postscript_Name*(face: FT_Face): cstring {.ft_import.}
proc FT_Select_Charmap*(face: FT_Face; encoding: FT_Encoding): FT_Error {.ft_import.}
proc FT_Set_Charmap*(face: FT_Face; charmap: FT_CharMap): FT_Error {.ft_import.}
proc FT_Get_Charmap_Index*(charmap: FT_CharMap): FT_Int {.ft_import.}
proc FT_Get_Char_Index*(face: FT_Face; charcode: FT_ULong): FT_UInt {.ft_import.}
proc FT_Get_First_Char*(face: FT_Face; agindex: var FT_UInt): FT_ULong {.ft_import.}
proc FT_Get_Next_Char*(face: FT_Face; char_code: FT_ULong; agindex: var FT_UInt): FT_ULong {.ft_import.}
proc FT_Get_Name_Index*(face: FT_Face; glyph_name: var FT_String): FT_UInt {.ft_import.}

proc charIndex*(face: FT_Face; charCode: FT_ULong): FT_UInt {.inline.} =
  FT_Get_Char_Index(face, charCode)

const
  FT_SUBGLYPH_FLAG_ARGS_ARE_WORDS*      = 1
  FT_SUBGLYPH_FLAG_ARGS_ARE_XY_VALUES*  = 2
  FT_SUBGLYPH_FLAG_ROUND_XY_TO_GRID*    = 4
  FT_SUBGLYPH_FLAG_SCALE*               = 8
  FT_SUBGLYPH_FLAG_XY_SCALE*            = 0x00000040
  FT_SUBGLYPH_FLAG_2X2*                 = 0x00000080
  FT_SUBGLYPH_FLAG_USE_MY_METRICS*      = 0x00000200

proc FT_Get_SubGlyph_Info*(glyph: FT_GlyphSlot; sub_index: FT_UInt;
                          p_index: var FT_Int; p_flags: var FT_UInt;
                          p_arg1: var FT_Int; p_arg2: var FT_Int;
                          p_transform: var FT_Matrix): FT_Error {.ft_import.}
const
  FT_FSTYPE_INSTALLABLE_EMBEDDING*        = 0x00000000
  FT_FSTYPE_RESTRICTED_LICENSE_EMBEDDING* = 0x00000002
  FT_FSTYPE_PREVIEW_AND_PRINT_EMBEDDING*  = 0x00000004
  FT_FSTYPE_EDITABLE_EMBEDDING*           = 0x00000008
  FT_FSTYPE_NO_SUBSETTING*                = 0x00000100
  FT_FSTYPE_BITMAP_EMBEDDING_ONLY*        = 0x00000200

proc FT_Get_FSType_Flags*(face: FT_Face): FT_UShort {.ft_import.}

proc FT_Face_GetCharVariantIndex*(face: FT_Face; charcode: FT_ULong;
  variantSelector: FT_ULong): FT_UInt {.ft_import.}
  
proc FT_Face_GetCharVariantIsDefault*(face: FT_Face; charcode: FT_ULong;
  variantSelector: FT_ULong): FT_Int {.ft_import.}
  
proc FT_Face_GetVariantSelectors*(face: FT_Face): ptr FT_UInt32 {.ft_import.}
proc FT_Face_GetVariantsOfChar*(face: FT_Face; charcode: FT_ULong): ptr FT_UInt32 {.ft_import.}
proc FT_Face_GetCharsOfVariant*(face: FT_Face; variantSelector: FT_ULong): ptr FT_UInt32 {.ft_import.}
proc FT_MulDiv*(a: FT_Long; b: FT_Long; c: FT_Long): FT_Long {.ft_import.}
proc FT_MulFix*(a: FT_Long; b: FT_Long): FT_Long {.ft_import.}
proc FT_DivFix*(a: FT_Long; b: FT_Long): FT_Long {.ft_import.}
proc FT_RoundFix*(a: FT_Fixed): FT_Fixed {.ft_import.}
proc FT_CeilFix*(a: FT_Fixed): FT_Fixed {.ft_import.}
proc FT_FloorFix*(a: FT_Fixed): FT_Fixed {.ft_import.}
proc FT_Vector_Transform*(vec: var FT_Vector; matrix: var FT_Matrix) {.ft_import.}

const
  FREETYPE_MAJOR* = 2
  FREETYPE_MINOR* = 7
  FREETYPE_PATCH* = 1

proc FT_Library_Version*(library: FT_Library; amajor: var FT_Int; aminor: var FT_Int;
  apatch: var FT_Int) {.ft_import.}
  
proc FT_Face_CheckTrueTypePatents*(face: FT_Face): FT_Bool {.ft_import.}

proc FT_Face_SetUnpatentedHinting*(face: FT_Face; value: FT_Bool): FT_Bool {.ft_import.}
