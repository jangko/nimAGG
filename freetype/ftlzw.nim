import fttypes, ftsystem
include ftimport

proc FT_Stream_OpenLZW*(stream: FT_Stream; source: FT_Stream): FT_Error {.ftimport.}
