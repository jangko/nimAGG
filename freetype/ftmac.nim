import fttypes, freetype, ftsystem
include ftimport

type
  Handle = pointer
  PFSSpec = pointer
  PFSRef = pointer

proc FT_New_Face_From_FOND*(library: FT_Library; fond: Handle; face_index: FT_Long;
  aface: ptr FT_Face): FT_Error {.ftimport, deprecated.}

proc FT_GetFile_From_Mac_Name*(fontName: ptr cchar; pathSpec: PFSSpec;
  face_index: ptr FT_Long): FT_Error {.ftimport, deprecated.}

proc FT_GetFile_From_Mac_ATS_Name*(fontName: ptr cchar; pathSpec: PFSSpec;
  face_index: ptr FT_Long): FT_Error {.ftimport, deprecated.}

proc FT_GetFilePath_From_Mac_ATS_Name*(fontName: ptr cchar; path: ptr FT_UInt8;
  maxPathSize: FT_UInt32; face_index: ptr FT_Long): FT_Error {.ftimport, deprecated.}

proc FT_New_Face_From_FSSpec*(library: FT_Library; spec: PFSSpec;
  face_index: FT_Long; aface: ptr FT_Face): FT_Error {.ftimport, deprecated.}

proc FT_New_Face_From_FSRef*(library: FT_Library; `ref`: PFSRef;
  face_index: FT_Long; aface: ptr FT_Face): FT_Error {.ftimport, deprecated.}
