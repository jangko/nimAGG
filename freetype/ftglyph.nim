import fttypes, freetype, ftimage, ftmodapi
include ftimport

type
  FT_Glyph* = ptr FT_GlyphRec

  FT_GlyphRec* = object
    library*: FT_Library
    clazz*: ptr FT_Glyph_Class
    format*: FT_Glyph_Format
    advance*: FT_Vector

  FT_BitmapGlyph* = ptr FT_BitmapGlyphRec

  FT_BitmapGlyphRec* = object
    root*: FT_GlyphRec
    left*: FT_Int
    top*: FT_Int
    bitmap*: FT_Bitmap

  FT_OutlineGlyph* = ptr FT_OutlineGlyphRec

  FT_OutlineGlyphRec* = object
    root*: FT_GlyphRec
    outline*: FT_Outline

  FT_Glyph_InitFunc*      = proc(glyph: FT_Glyph; slot: FT_GlyphSlot): FT_Error {.ftcallback.}
  FT_Glyph_DoneFunc*      = proc(glyph: FT_Glyph) {.ftcallback.}
  FT_Glyph_TransformFunc* = proc(glyph: FT_Glyph; matrix: var FT_Matrix;
                                 delta: var FT_Vector) {.ftcallback.}
  FT_Glyph_GetBBoxFunc*   = proc(glyph: FT_Glyph; abbox: var FT_BBox) {.ftcallback.}
  FT_Glyph_CopyFunc*      = proc(source: FT_Glyph; target: FT_Glyph): FT_Error {.ftcallback.}
  FT_Glyph_PrepareFunc*   = proc(glyph: FT_Glyph; slot: FT_GlyphSlot): FT_Error {.ftcallback.}

  FT_Glyph_Class* = object
    glyph_size*: FT_Long
    glyph_format*: FT_Glyph_Format
    glyph_init*: FT_Glyph_InitFunc
    glyph_done*: FT_Glyph_DoneFunc
    glyph_copy*: FT_Glyph_CopyFunc
    glyph_transform*: FT_Glyph_TransformFunc
    glyph_bbox*: FT_Glyph_GetBBoxFunc
    glyph_prepare*: FT_Glyph_PrepareFunc

  FT_Renderer_RenderFunc* = proc(renderer: FT_Renderer; slot: FT_GlyphSlot;
    mode: FT_UInt; origin: var FT_Vector): FT_Error {.ftcallback.}

  FT_Renderer_TransformFunc* = proc(renderer: FT_Renderer; slot: FT_GlyphSlot;
    matrix: var FT_Matrix; delta: var FT_Vector): FT_Error {.ftcallback.}

  FT_Renderer_GetCBoxFunc* = proc(renderer: FT_Renderer; slot: FT_GlyphSlot;
    cbox: var FT_BBox) {.ftcallback.}

  FT_Renderer_SetModeFunc* = proc(renderer: FT_Renderer; mode_tag: FT_ULong;
    mode_ptr: FT_Pointer): FT_Error {.ftcallback.}

  FTRenderer_render* = FT_Renderer_RenderFunc
  FTRenderer_transform* = FT_Renderer_TransformFunc
  FTRenderer_getCBox* = FT_Renderer_GetCBoxFunc
  FTRenderer_setMode* = FT_Renderer_SetModeFunc

  FT_Renderer_Class* = object
    root*: FT_Module_Class
    glyph_format*: FT_Glyph_Format
    render_glyph*: FT_Renderer_RenderFunc
    transform_glyph*: FT_Renderer_TransformFunc
    get_glyph_cbox*: FT_Renderer_GetCBoxFunc
    set_mode*: FT_Renderer_SetModeFunc
    raster_class*: ptr FT_Raster_Funcs

proc FT_Get_Renderer*(library: FT_Library; format: FT_Glyph_Format): FT_Renderer {.ftimport.}

proc FT_Set_Renderer*(library: FT_Library; renderer: FT_Renderer;
  num_params: FT_UInt; parameters: var FT_Parameter): FT_Error {.ftimport.}

proc FT_Get_Glyph*(slot: FT_GlyphSlot; aglyph: var FT_Glyph): FT_Error {.ftimport.}
proc FT_Glyph_Copy*(source: FT_Glyph; target: var FT_Glyph): FT_Error {.ftimport.}
proc FT_Glyph_Transform*(glyph: FT_Glyph; matrix: var FT_Matrix; delta: var FT_Vector): FT_Error {.ftimport.}

type
  FT_Glyph_BBox_Mode* = enum
    FT_GLYPH_BBOX_UNSCALED = 0, FT_GLYPH_BBOX_GRIDFIT = 1, FT_GLYPH_BBOX_TRUNCATE = 2,
    FT_GLYPH_BBOX_PIXELS = 3

const
  FT_GLYPH_BBOX_SUBPIXELS* = FT_GLYPH_BBOX_UNSCALED
  ft_glyph_bbox_unscaled*  = FT_GLYPH_BBOX_UNSCALED
  ft_glyph_bbox_subpixels* = FT_GLYPH_BBOX_SUBPIXELS
  ft_glyph_bbox_gridfit*   = FT_GLYPH_BBOX_GRIDFIT
  ft_glyph_bbox_truncate*  = FT_GLYPH_BBOX_TRUNCATE
  ft_glyph_bbox_pixels*    = FT_GLYPH_BBOX_PIXELS

proc FT_Glyph_Get_CBox*(glyph: FT_Glyph; bbox_mode: FT_UInt; acbox: var FT_BBox) {.ftimport.}

proc FT_Glyph_To_Bitmap*(the_glyph: var FT_Glyph; render_mode: FT_Render_Mode;
  origin: var FT_Vector; destroy: FT_Bool): FT_Error {.ftimport.}

proc FT_Done_Glyph*(glyph: FT_Glyph) {.ftimport.}

proc FT_Matrix_Multiply*(a: var FT_Matrix; b: var FT_Matrix) {.ftimport.}

proc FT_Matrix_Invert*(matrix: var FT_Matrix): FT_Error {.ftimport.}
