include ftimport

type
  FT_Uint8* = uint8
  FT_Uint32* = uint32
  FT_Int32* = int32
  FT_Bool* = cuchar
  FT_FWord* = cshort
  FT_UFWord* = cushort
  FT_Char* = cchar
  FT_Byte* = cuchar
  FT_Bytes* = ptr FT_Byte
  FT_Tag* = FT_UInt32
  FT_String* = cchar
  FT_Short* = cshort
  FT_UShort* = cushort
  FT_Int* = cint
  FT_UInt* = cuint
  FT_Long* = clong
  FT_ULong* = culong
  FT_F2Dot14* = cshort
  FT_F26Dot6* = clong
  FT_Fixed* = clong
  FT_Error* = cint
  FT_Pointer* = pointer
  FT_Offset* = csize

  #ft_ptrdiff_t  FT_PtrDist;

proc FT_MAKE_TAG*[T](x1, x2, x3, x4: T): FT_Tag {.compileTime.} =
  result = FT_Tag(
    (FT_ULong(x1) shl 24 ) or
    (FT_ULong(x2) shl 16 ) or
    (FT_ULong(x3) shl  8 ) or
     FT_ULong(x4) )


type
  FT_Generic_Finalizer* = proc(obj: pointer) {.ftcallback.}

  FT_Generic* = object
    data: pointer
    finalizer: FT_Generic_Finalizer

  FT_UnitVector* = object
    x, y: FT_F2Dot14

  FT_Matrix* = object
    xx, xy: FT_Fixed
    yx, yy: FT_Fixed

  FT_Data* = object
    pointer: ptr FT_Byte
    length: FT_Int

  FT_ListNode* = ptr FT_ListNodeRec

  FT_List* = ptr FT_ListRec

  FT_ListNodeRec* = object
    prev, next: FT_ListNode
    data: pointer

  FT_ListRec* = object
    head, tail: FT_ListNode

template FT_IS_EMPTY*(list: untyped): untyped =
  ( (list).head == nil )

import macros, strutils

macro FT_ERROR_DEF*(name: untyped, body: untyped): untyped =
  var list = "const\n"
  var table = "const\n  $1_Table* = {\n" % [$name]

  for x in body[0]:
    list.add("    $1_$2* = $3\n" % [$name, $x[0], $x[1].intVal])
    table.add("    $1: \"$2\",\n" % [$x[1].intVal, $x[2]])

  table.add "    }\n"

  result = parseStmt(list & table)
