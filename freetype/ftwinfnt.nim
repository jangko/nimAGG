import fttypes, freetype
include ftimport

const
  FT_WinFNT_ID_CP1252* = 0
  FT_WinFNT_ID_DEFAULT* = 1
  FT_WinFNT_ID_SYMBOL* = 2
  FT_WinFNT_ID_MAC* = 77
  FT_WinFNT_ID_CP932* = 128
  FT_WinFNT_ID_CP949* = 129
  FT_WinFNT_ID_CP1361* = 130
  FT_WinFNT_ID_CP936* = 134
  FT_WinFNT_ID_CP950* = 136
  FT_WinFNT_ID_CP1253* = 161
  FT_WinFNT_ID_CP1254* = 162
  FT_WinFNT_ID_CP1258* = 163
  FT_WinFNT_ID_CP1255* = 177
  FT_WinFNT_ID_CP1256* = 178
  FT_WinFNT_ID_CP1257* = 186
  FT_WinFNT_ID_CP1251* = 204
  FT_WinFNT_ID_CP874* = 222
  FT_WinFNT_ID_CP1250* = 238
  FT_WinFNT_ID_OEM* = 255

type
  FT_WinFNT_HeaderRec* = object
    version*: FT_UShort
    file_size*: FT_ULong
    copyright*: array[60, FT_Byte]
    file_type*: FT_UShort
    nominal_point_size*: FT_UShort
    vertical_resolution*: FT_UShort
    horizontal_resolution*: FT_UShort
    ascent*: FT_UShort
    internal_leading*: FT_UShort
    external_leading*: FT_UShort
    italic*: FT_Byte
    underline*: FT_Byte
    strike_out*: FT_Byte
    weight*: FT_UShort
    charset*: FT_Byte
    pixel_width*: FT_UShort
    pixel_height*: FT_UShort
    pitch_and_family*: FT_Byte
    avg_width*: FT_UShort
    max_width*: FT_UShort
    first_char*: FT_Byte
    last_char*: FT_Byte
    default_char*: FT_Byte
    break_char*: FT_Byte
    bytes_per_row*: FT_UShort
    device_offset*: FT_ULong
    face_name_offset*: FT_ULong
    bits_pointer*: FT_ULong
    bits_offset*: FT_ULong
    reserved*: FT_Byte
    flags*: FT_ULong
    A_space*: FT_UShort
    B_space*: FT_UShort
    C_space*: FT_UShort
    color_table_offset*: FT_UShort
    reserved1*: array[4, FT_ULong]

  FT_WinFNT_Header* = ptr FT_WinFNT_HeaderRec

proc FT_Get_WinFNT_Header*(face: FT_Face; aheader: ptr FT_WinFNT_HeaderRec): FT_Error {.ftimport.}
