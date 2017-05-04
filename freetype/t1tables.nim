import fttypes, ftimage, freetype
include ftimport

type
  PS_FontInfoRec* = object
    version*: ptr FT_String
    notice*: ptr FT_String
    full_name*: ptr FT_String
    family_name*: ptr FT_String
    weight*: ptr FT_String
    italic_angle*: FT_Long
    is_fixed_pitch*: FT_Bool
    underline_position*: FT_Short
    underline_thickness*: FT_UShort

  PS_FontInfo* = ptr PS_FontInfoRec

  T1_FontInfo* = PS_FontInfoRec

  PS_PrivateRec* = object
    unique_id*: FT_Int
    lenIV*: FT_Int
    num_blue_values*: FT_Byte
    num_other_blues*: FT_Byte
    num_family_blues*: FT_Byte
    num_family_other_blues*: FT_Byte
    blue_values*: array[14, FT_Short]
    other_blues*: array[10, FT_Short]
    family_blues*: array[14, FT_Short]
    family_other_blues*: array[10, FT_Short]
    blue_scale*: FT_Fixed
    blue_shift*: FT_Int
    blue_fuzz*: FT_Int
    standard_width*: array[1, FT_UShort]
    standard_height*: array[1, FT_UShort]
    num_snap_widths*: FT_Byte
    num_snap_heights*: FT_Byte
    force_bold*: FT_Bool
    round_stem_up*: FT_Bool
    snap_widths*: array[13, FT_Short]
    snap_heights*: array[13, FT_Short]
    expansion_factor*: FT_Fixed
    language_group*: FT_Long
    password*: FT_Long
    min_feature*: array[2, FT_Short]

  PS_Private* = ptr PS_PrivateRec

  T1_Private* = PS_PrivateRec

  T1_Blend_Flags* = enum
    T1_BLEND_UNDERLINE_POSITION = 0, T1_BLEND_UNDERLINE_THICKNESS,
    T1_BLEND_ITALIC_ANGLE, T1_BLEND_BLUE_VALUES, T1_BLEND_OTHER_BLUES,
    T1_BLEND_STANDARD_WIDTH, T1_BLEND_STANDARD_HEIGHT, T1_BLEND_STEM_SNAP_WIDTHS,
    T1_BLEND_STEM_SNAP_HEIGHTS, T1_BLEND_BLUE_SCALE, T1_BLEND_BLUE_SHIFT,
    T1_BLEND_FAMILY_BLUES, T1_BLEND_FAMILY_OTHER_BLUES, T1_BLEND_FORCE_BOLD,
    T1_BLEND_MAX

const
  t1_blend_underline_position* = T1_BLEND_UNDERLINE_POSITION
  t1_blend_underline_thickness* = T1_BLEND_UNDERLINE_THICKNESS
  t1_blend_italic_angle* = T1_BLEND_ITALIC_ANGLE
  t1_blend_blue_values* = T1_BLEND_BLUE_VALUES
  t1_blend_other_blues* = T1_BLEND_OTHER_BLUES
  t1_blend_standard_widths* = T1_BLEND_STANDARD_WIDTH
  t1_blend_standard_height* = T1_BLEND_STANDARD_HEIGHT
  t1_blend_stem_snap_widths* = T1_BLEND_STEM_SNAP_WIDTHS
  t1_blend_stem_snap_heights* = T1_BLEND_STEM_SNAP_HEIGHTS
  t1_blend_blue_scale* = T1_BLEND_BLUE_SCALE
  t1_blend_blue_shift* = T1_BLEND_BLUE_SHIFT
  t1_blend_family_blues* = T1_BLEND_FAMILY_BLUES
  t1_blend_family_other_blues* = T1_BLEND_FAMILY_OTHER_BLUES
  t1_blend_force_bold* = T1_BLEND_FORCE_BOLD
  t1_blend_max* = T1_BLEND_MAX
  T1_MAX_MM_DESIGNS* = 16
  T1_MAX_MM_AXIS* = 4
  T1_MAX_MM_MAP_POINTS* = 20

type
  PS_DesignMapRec* = object
    num_points*: FT_Byte
    design_points*: ptr FT_Long
    blend_points*: ptr FT_Fixed

  PS_DesignMap* = ptr PS_DesignMapRec

  T1_DesignMap* = PS_DesignMapRec

  PS_BlendRec* = object
    num_designs*: FT_UInt
    num_axis*: FT_UInt
    axis_names*: array[T1_MAX_MM_AXIS, ptr FT_String]
    design_pos*: array[T1_MAX_MM_DESIGNS, ptr FT_Fixed]
    design_map*: array[T1_MAX_MM_AXIS, PS_DesignMapRec]
    weight_vector*: ptr FT_Fixed
    default_weight_vector*: ptr FT_Fixed
    font_infos*: array[T1_MAX_MM_DESIGNS + 1, PS_FontInfo]
    privates*: array[T1_MAX_MM_DESIGNS + 1, PS_Private]
    blend_bitflags*: FT_ULong
    bboxes*: array[T1_MAX_MM_DESIGNS + 1, ptr FT_BBox]
    default_design_vector*: array[T1_MAX_MM_DESIGNS, FT_UInt]
    num_default_design_vector*: FT_UInt

  PS_Blend* = ptr PS_BlendRec

  T1_Blend* = PS_BlendRec

  CID_FaceDictRec* = object
    private_dict*: PS_PrivateRec
    len_buildchar*: FT_UInt
    forcebold_threshold*: FT_Fixed
    stroke_width*: FT_Pos
    expansion_factor*: FT_Fixed
    paint_type*: FT_Byte
    font_type*: FT_Byte
    font_matrix*: FT_Matrix
    font_offset*: FT_Vector
    num_subrs*: FT_UInt
    subrmap_offset*: FT_ULong
    sd_bytes*: FT_Int

  CID_FaceDict* = ptr CID_FaceDictRec

  CID_FontDict* = CID_FaceDictRec

  CID_FaceInfoRec* = object
    cid_font_name*: ptr FT_String
    cid_version*: FT_Fixed
    cid_font_type*: FT_Int
    registry*: ptr FT_String
    ordering*: ptr FT_String
    supplement*: FT_Int
    font_info*: PS_FontInfoRec
    font_bbox*: FT_BBox
    uid_base*: FT_ULong
    num_xuid*: FT_Int
    xuid*: array[16, FT_ULong]
    cidmap_offset*: FT_ULong
    fd_bytes*: FT_Int
    gd_bytes*: FT_Int
    cid_count*: FT_ULong
    num_dicts*: FT_Int
    font_dicts*: CID_FaceDict
    data_offset*: FT_ULong

  CID_FaceInfo* = ptr CID_FaceInfoRec

  CID_Info* = CID_FaceInfoRec

proc FT_Has_PS_Glyph_Names*(face: FT_Face): FT_Int {.ftimport.}

proc FT_Get_PS_Font_Info*(face: FT_Face; afont_info: PS_FontInfo): FT_Error {.ftimport.}

proc FT_Get_PS_Font_Private*(face: FT_Face; afont_private: PS_Private): FT_Error {.ftimport.}

type
  T1_EncodingType* = enum
    T1_ENCODING_TYPE_NONE = 0, T1_ENCODING_TYPE_ARRAY, T1_ENCODING_TYPE_STANDARD,
    T1_ENCODING_TYPE_ISOLATIN1, T1_ENCODING_TYPE_EXPERT

  PS_Dict_Keys* = enum
    PS_DICT_FONT_TYPE, PS_DICT_FONT_MATRIX, PS_DICT_FONT_BBOX, PS_DICT_PAINT_TYPE,
    PS_DICT_FONT_NAME, PS_DICT_UNIQUE_ID, PS_DICT_NUM_CHAR_STRINGS,
    PS_DICT_CHAR_STRING_KEY, PS_DICT_CHAR_STRING, PS_DICT_ENCODING_TYPE,
    PS_DICT_ENCODING_ENTRY, PS_DICT_NUM_SUBRS, PS_DICT_SUBR, PS_DICT_STD_HW,
    PS_DICT_STD_VW, PS_DICT_NUM_BLUE_VALUES, PS_DICT_BLUE_VALUE, PS_DICT_BLUE_FUZZ,
    PS_DICT_NUM_OTHER_BLUES, PS_DICT_OTHER_BLUE, PS_DICT_NUM_FAMILY_BLUES,
    PS_DICT_FAMILY_BLUE, PS_DICT_NUM_FAMILY_OTHER_BLUES,
    PS_DICT_FAMILY_OTHER_BLUE, PS_DICT_BLUE_SCALE, PS_DICT_BLUE_SHIFT,
    PS_DICT_NUM_STEM_SNAP_H, PS_DICT_STEM_SNAP_H, PS_DICT_NUM_STEM_SNAP_V,
    PS_DICT_STEM_SNAP_V, PS_DICT_FORCE_BOLD, PS_DICT_RND_STEM_UP,
    PS_DICT_MIN_FEATURE, PS_DICT_LEN_IV, PS_DICT_PASSWORD, PS_DICT_LANGUAGE_GROUP,
    PS_DICT_VERSION, PS_DICT_NOTICE, PS_DICT_FULL_NAME, PS_DICT_FAMILY_NAME,
    PS_DICT_WEIGHT, PS_DICT_IS_FIXED_PITCH, PS_DICT_UNDERLINE_POSITION,
    PS_DICT_UNDERLINE_THICKNESS, PS_DICT_FS_TYPE, PS_DICT_ITALIC_ANGLE

const
  PS_DICT_MAX* = PS_DICT_ITALIC_ANGLE

proc FT_Get_PS_Font_Value*(face: FT_Face; key: PS_Dict_Keys; idx: FT_UInt;
                          value: pointer; value_len: FT_Long): FT_Long {.ftimport.}
