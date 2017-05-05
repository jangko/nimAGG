import fttypes, freetype, ftsystem
include ftimport

proc FT_Stream_OpenGzip*(stream: FT_Stream; source: FT_Stream): FT_Error {.ftimport.}

proc FT_Gzip_Uncompress*(memory: FT_Memory; output: ptr FT_Byte;
  output_len: ptr FT_ULong; input: ptr FT_Byte; input_len: FT_ULong): FT_Error {.ftimport.}
