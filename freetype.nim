when defined(MACOSX):
  const FT_LIB_NAME* = "libfreetype-6.dylib"
elif defined(UNIX):
  const FT_LIB_NAME* = "libfreetype-6.so"
else:
  const FT_LIB_NAME* = "libfreetype-6.dll"

when defined(windows):
  {.pragma: ft_import, stdcall, importc, dynlib: FT_LIB_NAME.}
  {.pragma: ft_callback, stdcall.}
else:
  {.pragma: ft_import, cdecl, importc, dynlib: FT_LIB_NAME.}
  {.pragma: ft_callback, cdecl.}

type
  FT_Encoding* = distinct uint32
  FT_Library* = distinct pointer
  FT_Error* = cint
  FT_F26Dot6* = clong
  FT_UInt* = cuint
  FT_Long* = clong
  FT_String* = cchar
  FT_Int* = cint
  FT_Short* = cshort
  FT_UShort* = cushort
  FT_Pos* = clong
  FT_Fixed* = clong
  FT_Glyph_Format* = distinct culong

proc FT_IMAGE_TAG[T](a, b, c, d: T): FT_Glyph_Format {.compileTime.} =
  result = FT_Glyph_Format((culong(a) shl 24) or (culong(b) shl 16) or (culong(c) shl  8) or culong(d))

const
  FT_GLYPH_FORMAT_NONE*      = FT_IMAGE_TAG(0, 0, 0, 0)
  FT_GLYPH_FORMAT_COMPOSITE* = FT_IMAGE_TAG('c', 'o', 'm', 'p')
  FT_GLYPH_FORMAT_BITMAP*    = FT_IMAGE_TAG('b', 'i', 't', 's')
  FT_GLYPH_FORMAT_OUTLINE*   = FT_IMAGE_TAG('o', 'u', 't', 'l')
  FT_GLYPH_FORMAT_PLOTTER*   = FT_IMAGE_TAG('p', 'l', 'o', 't')

type
  FT_Face* = ptr FT_FaceRec
  FT_CharMap* = ptr FT_CharMapRec

  FT_Vector* = object
    x*, y*: FT_Pos

  FT_Bitmap_Size* = object
    height: FT_Short
    width: FT_Short
    size: FT_Pos
    x_ppem: FT_Pos
    y_ppem: FT_Pos

  FT_CharMapRec = object
    face: FT_Face
    encoding: FT_Encoding
    platform_id: FT_UShort
    encoding_id: FT_UShort

  FT_Generic_Finalizer = proc(obj: pointer) {.cdecl.}

  FT_Generic = object
    data: pointer
    finalizer: FT_Generic_Finalizer

  FT_BBox = object
    xMin, yMin: FT_Pos
    xMax, yMax: FT_Pos

  FT_Glyph_Metrics = object
    width: FT_Pos
    height: FT_Pos

    horiBearingX: FT_Pos
    horiBearingY: FT_Pos
    horiAdvance: FT_Pos

    vertBearingX: FT_Pos
    vertBearingY: FT_Pos
    vertAdvance: FT_Pos

  FT_Bitmap = object
    rows: cuint
    width: cuint
    pitch: cint
    buffer: cstring
    num_grays: cushort
    pixel_mode: cuchar
    palette_mode: cuchar
    palette: pointer

  FT_Outline = object
    n_contours: cshort      # number of contours in glyph
    n_points: cshort        # number of points in the glyph

    points: ptr FT_Vector   # the outline's points
    tags: cstring           # the points flags
    contours: ptr cshort    # the contour end points
    flags: cint             # outline masks

  FT_Matrix = object
    xx, xy: FT_Fixed
    yx, yy: FT_Fixed

  FT_SubGlyphRec = object
    index: FT_Int
    flags: FT_UShort
    arg1: FT_Int
    arg2: FT_Int
    transform: FT_Matrix

  FT_SubGlyph = ptr FT_SubGlyphRec

  FT_GlyphSlotRec = object
    library: FT_Library
    face: FT_Face
    nect: FT_GlyphSlot
    reserved: FT_UInt
    generik: FT_Generic

    metrics: FT_Glyph_Metrics
    linearHoriAdvance: FT_Fixed
    linearVertAdvance: FT_Fixed
    advance: FT_Vector

    format: FT_Glyph_Format

    bitmap: FT_Bitmap
    bitmap_left: FT_Int
    bitmap_top: FT_Int

    outline: FT_Outline

    num_subglyphs: FT_UInt
    subglyphs: FT_SubGlyph

    control_data: pointer
    control_len: clong

    lsb_delta: FT_Pos
    rsb_delta: FT_Pos

    other: pointer

    internal: FT_Slot_Internal

  FT_Slot_Internal = distinct pointer
  FT_GlyphSlot = ptr FT_GlyphSlotRec
  FT_Driver = distinct pointer
  FT_Memory = distinct pointer
  FT_Stream = distinct pointer
  FT_ListNode = distinct pointer
  FT_Face_Internal = distinct pointer
  FT_Size = distinct pointer

  FT_ListRec = object
    head: FT_ListNode
    tail: FT_ListNode

  FT_FaceRec* = object
    numFaces*: FT_Long
    faceIndex: FT_Long

    faceFlags: FT_Long
    styleFlags: FT_Long

    numGlpyhs: FT_Long

    familyName: ptr FT_String
    styleName: ptr FT_string

    numFixedSizes: FT_int
    availableSizes: ptr FT_Bitmap_Size

    numCharmaps: FT_Int
    charmaps: ptr FT_CharMap

    generik: FT_Generic

    # The following member variables (down to `underline_thickness')
    # are only relevant to scalable outlines; cf. @FT_Bitmap_Size
    # for bitmap fonts.
    bbox: FT_BBox

    units_per_EM: FT_UShort
    ascender*: FT_Short
    descender*: FT_Short
    height*: FT_Short

    max_advance_width: FT_Short
    max_advance_height: FT_Short

    underline_position: FT_Short
    underline_thickness: FT_Short

    glyph: FT_GlyphSlot
    size: FT_Size
    charmap: FT_CharMap

    driver: FT_Driver
    memory: FT_Memory
    stream: FT_Stream

    sizesList: FT_ListRec

    autohint: FT_Generic # face-specific auto-hinter data
    extensions: pointer # unused

    internal: FT_Face_Internal

proc isNil*(a: FT_Library): bool {.inline.} = cast[pointer](a) == nil
proc isNil*(a: FT_Face): bool {.inline.} = cast[pointer](a) == nil

proc FT_ENC_TAG[T](a, b, c, d: T): FT_Encoding {.compileTime.} =
  result = FT_Encoding((uint32(a) shl 24) or (uint32(b) shl 16) or (uint32(c) shl  8) or uint32(d))

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

proc FT_Init_FreeType*(lib: var FT_Library): FT_Error {.ft_import.}
proc FT_Set_Char_Size*(face: FT_Face, char_width, char_height: FT_F26Dot6;
  horz_resolution, vert_resolution: FT_UInt): FT_Error {.ft_import.}
proc FT_Set_Pixel_Sizes*(face: FT_Face, pixel_width, pixel_height: FT_UInt): FT_Error {.ft_import.}
proc FT_Attach_File*(face: FT_Face, filepathname: cstring): FT_Error {.ft_import.}
proc FT_Select_Charmap*(face: FT_Face, encoding: FT_Encoding): FT_Error {.ft_import.}

type
  FT_Kerning_Mode = FT_Uint

const
  FT_KERNING_DEFAULT*  = 0
  FT_KERNING_UNFITTED* = 1
  FT_KERNING_UNSCALED* = 2

  FT_FACE_FLAG_SCALABLE*          = 1 shl  0
  FT_FACE_FLAG_FIXED_SIZES*       = 1 shl  1
  FT_FACE_FLAG_FIXED_WIDTH*       = 1 shl  2
  FT_FACE_FLAG_SFNT*              = 1 shl  3
  FT_FACE_FLAG_HORIZONTAL*        = 1 shl  4
  FT_FACE_FLAG_VERTICAL*          = 1 shl  5
  FT_FACE_FLAG_KERNING*           = 1 shl  6
  FT_FACE_FLAG_FAST_GLYPHS*       = 1 shl  7
  FT_FACE_FLAG_MULTIPLE_MASTERS*  = 1 shl  8
  FT_FACE_FLAG_GLYPH_NAMES*       = 1 shl  9
  FT_FACE_FLAG_EXTERNAL_STREAM*   = 1 shl 10
  FT_FACE_FLAG_HINTER*            = 1 shl 11
  FT_FACE_FLAG_CID_KEYED*         = 1 shl 12
  FT_FACE_FLAG_TRICKY*            = 1 shl 13
  FT_FACE_FLAG_COLOR*             = 1 shl 14

proc FT_Get_Kerning*(face: FT_Face, left_glyph, right_glyph: FT_UInt,
  kern_mode: FT_Kerning_Mode, kern: var FT_Vector): FT_Error {.ft_import.}

proc FT_HAS_KERNING*(face: FT_Face): bool {.inline.} =
  result = (face.faceFlags and FT_FACE_FLAG_KERNING) != 0

proc FT_Done_Face*(face: FT_Face): FT_Error {.ft_import.}
proc FT_Done_FreeType*(library: FT_Library): FT_Error {.ft_import.}
