import fttypes, freetype, ftsystem
include ftimport

type
  FT_Incremental* = distinct pointer #ptr FT_IncrementalRec

  FT_Incremental_MetricsRec* = object
    bearing_x*: FT_Long
    bearing_y*: FT_Long
    advance*: FT_Long
    advance_v*: FT_Long

  FT_Incremental_Metrics* = ptr FT_Incremental_MetricsRec

  FT_Incremental_GetGlyphDataFunc* = proc(incremental: FT_Incremental;
    glyph_index: FT_UInt; adata: ptr FT_Data): FT_Error {.ftcallback.}

  FT_Incremental_FreeGlyphDataFunc* = proc(incremental: FT_Incremental;
    data: ptr FT_Data) {.ftcallback.}

  FT_Incremental_GetGlyphMetricsFunc* = proc(incremental: FT_Incremental;
    glyph_index: FT_UInt; vertical: FT_Bool;
    ametrics: ptr FT_Incremental_MetricsRec): FT_Error {.ftcallback.}

  FT_Incremental_FuncsRec* = object
    get_glyph_data*: FT_Incremental_GetGlyphDataFunc
    free_glyph_data*: FT_Incremental_FreeGlyphDataFunc
    get_glyph_metrics*: FT_Incremental_GetGlyphMetricsFunc

  FT_Incremental_InterfaceRec* = object
    funcs*: ptr FT_Incremental_FuncsRec
    `object`*: FT_Incremental

  FT_Incremental_Interface* = ptr FT_Incremental_InterfaceRec

const
  FT_PARAM_TAG_INCREMENTAL* = FT_MAKE_TAG('i', 'n', 'c', 'r')
