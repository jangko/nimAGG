include ftimport

type
  FT_Pos* = clong

  FT_Vector* = object
    x*, y*: FT_Pos

  FT_BBox* = object
    xMin*, yMin*: FT_Pos
    xMax*, yMax*: FT_Pos

  FT_Pixel_Mode* = enum
    FT_PIXEL_MODE_NONE = 0, FT_PIXEL_MODE_MONO, FT_PIXEL_MODE_GRAY,
    FT_PIXEL_MODE_GRAY2, FT_PIXEL_MODE_GRAY4, FT_PIXEL_MODE_LCD,
    FT_PIXEL_MODE_LCD_V, FT_PIXEL_MODE_BGRA, FT_PIXEL_MODE_MAX

  FT_Glyph_Format* = distinct culong

proc FT_IMAGE_TAG[T](a, b, c, d: T): FT_Glyph_Format {.compileTime.} =
  result = FT_Glyph_Format((culong(a) shl 24) or
                           (culong(b) shl 16) or
                           (culong(c) shl  8) or
                            culong(d))

const
  FT_GLYPH_FORMAT_NONE*      = FT_IMAGE_TAG(0, 0, 0, 0)
  FT_GLYPH_FORMAT_COMPOSITE* = FT_IMAGE_TAG('c', 'o', 'm', 'p')
  FT_GLYPH_FORMAT_BITMAP*    = FT_IMAGE_TAG('b', 'i', 't', 's')
  FT_GLYPH_FORMAT_OUTLINE*   = FT_IMAGE_TAG('o', 'u', 't', 'l')
  FT_GLYPH_FORMAT_PLOTTER*   = FT_IMAGE_TAG('p', 'l', 'o', 't')

const
  ft_pixel_mode_none*  = FT_PIXEL_MODE_NONE
  ft_pixel_mode_mono*  = FT_PIXEL_MODE_MONO
  ft_pixel_mode_grays* = FT_PIXEL_MODE_GRAY
  ft_pixel_mode_pal2*  = FT_PIXEL_MODE_GRAY2
  ft_pixel_mode_pal4*  = FT_PIXEL_MODE_GRAY4

type
  FT_Bitmap* = object
    rows*: cuint
    width*: cuint
    pitch*: cint
    buffer*: cstring
    num_grays*: cushort
    pixel_mode*: cuchar
    palette_mode*: cuchar
    palette*: pointer

  FT_Outline* = object
    n_contours*: cshort
    n_points*: cshort
    points*: ptr FT_Vector
    tags*: ptr cchar
    contours*: ptr cshort
    flags*: cint

const
  FT_OUTLINE_CONTOURS_MAX*    = high(int16)
  FT_OUTLINE_POINTS_MAX*      = high(int16)
  FT_OUTLINE_NONE*            = 0x00000000
  FT_OUTLINE_OWNER*           = 0x00000001
  FT_OUTLINE_EVEN_ODD_FILL*   = 0x00000002
  FT_OUTLINE_REVERSE_FILL*    = 0x00000004
  FT_OUTLINE_IGNORE_DROPOUTS* = 0x00000008
  FT_OUTLINE_SMART_DROPOUTS*  = 0x00000010
  FT_OUTLINE_INCLUDE_STUBS*   = 0x00000020
  FT_OUTLINE_HIGH_PRECISION*  = 0x00000100
  FT_OUTLINE_SINGLE_PASS*     = 0x00000200
  ft_outline_none*            = FT_OUTLINE_NONE
  ft_outline_owner*           = FT_OUTLINE_OWNER
  ft_outline_even_odd_fill*   = FT_OUTLINE_EVEN_ODD_FILL
  ft_outline_reverse_fill*    = FT_OUTLINE_REVERSE_FILL
  ft_outline_ignore_dropouts* = FT_OUTLINE_IGNORE_DROPOUTS
  ft_outline_high_precision*  = FT_OUTLINE_HIGH_PRECISION
  ft_outline_single_pass*     = FT_OUTLINE_SINGLE_PASS

template FT_CURVE_TAG*(flag: untyped): untyped =
  (flag and 3)

const
  FT_CURVE_TAG_ON*           = 1
  FT_CURVE_TAG_CONIC*        = 0
  FT_CURVE_TAG_CUBIC*        = 2
  FT_CURVE_TAG_HAS_SCANMODE* = 4
  FT_CURVE_TAG_TOUCH_X*      = 8
  FT_CURVE_TAG_TOUCH_Y*      = 16
  FT_CURVE_TAG_TOUCH_BOTH*   = (FT_CURVE_TAG_TOUCH_X or FT_CURVE_TAG_TOUCH_Y)

type
  FT_Outline_MoveToFunc*  = proc(to: var FT_Vector; user: pointer): cint {.ftcallback.}
  FT_Outline_LineToFunc*  = proc(to: var FT_Vector; user: pointer): cint {.ftcallback.}
  FT_Outline_ConicToFunc* = proc(control, to: var FT_Vector; user: pointer): cint {.ftcallback.}
  FT_Outline_CubicToFunc* = proc(control1, control2, to: var FT_Vector; user: pointer): cint {.ftcallback.}

  FT_Outline_Funcs* = object
    moveTo*: FT_Outline_MoveToFunc
    lineTo*: FT_Outline_LineToFunc
    conicTo*: FT_Outline_ConicToFunc
    cubicTo*: FT_Outline_CubicToFunc
    shift*: cint
    delta*: FT_Pos

const
  ft_glyph_format_none*      = FT_GLYPH_FORMAT_NONE
  ft_glyph_format_composite* = FT_GLYPH_FORMAT_COMPOSITE
  ft_glyph_format_bitmap*    = FT_GLYPH_FORMAT_BITMAP
  ft_glyph_format_outline*   = FT_GLYPH_FORMAT_OUTLINE
  ft_glyph_format_plotter*   = FT_GLYPH_FORMAT_PLOTTER

type
  FT_Raster* = distinct pointer #ptr FT_RasterRec

  FT_Span* = object
    x*: cshort
    len*: cushort
    coverage*: cuchar

  FT_SpanFunc*            = proc(y, count: cint; spans: var FT_Span; user: pointer) {.ftcallback.}
  FT_Raster_Span_Func*    = FT_SpanFunc
  FT_Raster_BitTest_Func* = proc(y, x: cint; user: pointer): cint {.ftcallback.}
  FT_Raster_BitSet_Func*  = proc(y, x: cint; user: pointer) {.ftcallback.}

const
  FT_RASTER_FLAG_DEFAULT* = 0x00000000
  FT_RASTER_FLAG_AA*      = 0x00000001
  FT_RASTER_FLAG_DIRECT*  = 0x00000002
  FT_RASTER_FLAG_CLIP*    = 0x00000004
  ft_raster_flag_default* = FT_RASTER_FLAG_DEFAULT
  ft_raster_flag_aa*      = FT_RASTER_FLAG_AA
  ft_raster_flag_direct*  = FT_RASTER_FLAG_DIRECT
  ft_raster_flag_clip*    = FT_RASTER_FLAG_CLIP

type
  FT_Raster_Params* = object
    target*: ptr FT_Bitmap
    source*: pointer
    flags*: cint
    gray_spans*: FT_SpanFunc
    black_spans*: FT_SpanFunc
    bit_test*: FT_Raster_BitTest_Func
    bit_set*: FT_Raster_BitSet_Func
    user*: pointer
    clip_box*: FT_BBox

  FT_Raster_NewFunc*     = proc(memory: pointer; raster: var FT_Raster): cint {.ftcallback.}
  FT_Raster_DoneFunc*    = proc(raster: FT_Raster) {.ftcallback.}
  FT_Raster_ResetFunc*   = proc(raster: FT_Raster; pool_base: cstring; pool_size: culong) {.ftcallback.}
  FT_Raster_SetModeFunc* = proc(raster: FT_Raster; mode: culong; args: pointer): cint {.ftcallback.}
  FT_Raster_RenderFunc*  = proc(raster: FT_Raster; params: var FT_Raster_Params): cint {.ftcallback.}

type
  FT_Raster_Funcs* = object
    glyph_format*: FT_Glyph_Format
    raster_new*: FT_Raster_NewFunc
    raster_reset*: FT_Raster_ResetFunc
    raster_set_mode*: FT_Raster_SetModeFunc
    raster_render*: FT_Raster_RenderFunc
    raster_done*: FT_Raster_DoneFunc
