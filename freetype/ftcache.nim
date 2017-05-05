import fttypes, freetype, ftimage, ftglyph
include ftimport

type
  FTC_FaceID* = FT_Pointer
  FTC_Face_Requester* = proc(face_id: FTC_FaceID; library: FT_Library;
                           req_data: FT_Pointer; aface: var FT_Face): FT_Error {.ftcallback.}
  FTC_Manager* = distinct pointer#ptr FTC_ManagerRec
  FTC_Node* = distinct pointer#ptr FTC_NodeRec

proc FTC_Manager_New*(library: FT_Library; max_faces: FT_UInt; max_sizes: FT_UInt;
  max_bytes: FT_ULong; requester: FTC_Face_Requester; req_data: FT_Pointer;
  amanager: var FTC_Manager): FT_Error {.ftimport.}

proc FTC_Manager_Reset*(manager: FTC_Manager) {.ftimport.}

proc FTC_Manager_Done*(manager: FTC_Manager) {.ftimport.}

proc FTC_Manager_LookupFace*(manager: FTC_Manager; face_id: FTC_FaceID;
  aface: var FT_Face): FT_Error {.ftimport.}

type
  FTC_ScalerRec* = object
    face_id*: FTC_FaceID
    width*: FT_UInt
    height*: FT_UInt
    pixel*: FT_Int
    x_res*: FT_UInt
    y_res*: FT_UInt

  FTC_Scaler* = ptr FTC_ScalerRec

proc FTC_Manager_LookupSize*(manager: FTC_Manager; scaler: FTC_Scaler;
  asize: ptr FT_Size): FT_Error {.ftimport.}

proc FTC_Node_Unref*(node: FTC_Node; manager: FTC_Manager) {.ftimport.}

proc FTC_Manager_RemoveFaceID*(manager: FTC_Manager; face_id: FTC_FaceID) {.ftimport.}

type
  FTC_CMapCache* = distinct pointer #ptr FTC_CMapCacheRec

proc FTC_CMapCache_New*(manager: FTC_Manager; acache: ptr FTC_CMapCache): FT_Error {.ftimport.}

proc FTC_CMapCache_Lookup*(cache: FTC_CMapCache; face_id: FTC_FaceID;
 cmap_index: FT_Int; char_code: FT_UInt32): FT_UInt {.ftimport.}

type
  FTC_ImageTypeRec* = object
    face_id*: FTC_FaceID
    width*: FT_UInt
    height*: FT_UInt
    flags*: FT_Int32

  FTC_ImageType* = ptr FTC_ImageTypeRec

template FTC_IMAGE_TYPE_COMPARE*(d1, d2: untyped): untyped =
  ((d1).face_id == (d2).face_id and (d1).width == (d2).width and (d1).flags == (d2).flags)

type
  FTC_ImageCache* = distinct pointer #ptr FTC_ImageCacheRec

proc FTC_ImageCache_New*(manager: FTC_Manager; acache: var FTC_ImageCache): FT_Error {.ftimport.}

proc FTC_ImageCache_Lookup*(cache: FTC_ImageCache; `type`: FTC_ImageType;
  gindex: FT_UInt; aglyph: var FT_Glyph; anode: var FTC_Node): FT_Error {.ftimport.}

proc FTC_ImageCache_LookupScaler*(cache: FTC_ImageCache; scaler: FTC_Scaler;
  load_flags: FT_ULong; gindex: FT_UInt; aglyph: var FT_Glyph; anode: var FTC_Node): FT_Error {.ftimport.}

type
  FTC_SBit* = ptr FTC_SBitRec

  FTC_SBitRec* = object
    width*: FT_Byte
    height*: FT_Byte
    left*: FT_Char
    top*: FT_Char
    format*: FT_Byte
    max_grays*: FT_Byte
    pitch*: FT_Short
    xadvance*: FT_Char
    yadvance*: FT_Char
    buffer*: ptr FT_Byte

  FTC_SBitCache* = distinct pointer#ptr FTC_SBitCacheRec

proc FTC_SBitCache_New*(manager: FTC_Manager; acache: var FTC_SBitCache): FT_Error {.ftimport.}

proc FTC_SBitCache_Lookup*(cache: FTC_SBitCache; `type`: FTC_ImageType;
  gindex: FT_UInt; sbit: var FTC_SBit; anode: var FTC_Node): FT_Error {.ftimport.}

proc FTC_SBitCache_LookupScaler*(cache: FTC_SBitCache; scaler: FTC_Scaler;
  load_flags: FT_ULong; gindex: FT_UInt; sbit: var FTC_SBit; anode: var FTC_Node): FT_Error {.ftimport.}
