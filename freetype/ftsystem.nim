include ftimport

type
  FT_Memory*       = ptr FT_MemoryRec

  FT_Alloc_Func*   = proc(memory: FT_Memory; size: clong): pointer {.ftcallback.}

  FT_Free_Func*    = proc(memory: FT_Memory; `block`: pointer) {.ftcallback.}

  FT_Realloc_Func* = proc(memory: FT_Memory; cur_size: clong; new_size: clong;
                          `block`: pointer): pointer {.ftcallback.}

  FT_MemoryRec* = object
    user*: pointer
    alloc*: FT_Alloc_Func
    free*: FT_Free_Func
    realloc*: FT_Realloc_Func

  FT_Stream* = ptr FT_StreamRec

  FT_StreamDesc* = object {.union.}
    value*: clong
    pointer*: pointer

  FT_Stream_IoFunc* = proc(stream: FT_Stream; offset: culong; buffer: cstring;
                           count: culong): culong {.ftcallback.}

  FT_Stream_CloseFunc* = proc(stream: FT_Stream) {.ftcallback.}

  FT_StreamRec* = object
    base*: cstring
    size*: culong
    pos*: culong
    descriptor*: FT_StreamDesc
    pathname*: FT_StreamDesc
    read*: FT_Stream_IoFunc
    close*: FT_Stream_CloseFunc
    memory*: FT_Memory
    cursor*: cstring
    limit*: cstring
