import fttypes, freetype, ftsystem
include ftimport

proc FT_List_Find*(list: FT_List; data: pointer): FT_ListNode {.ftimport.}

proc FT_List_Add*(list: FT_List; node: FT_ListNode){.ftimport.}

proc FT_List_Insert*(list: FT_List; node: FT_ListNode){.ftimport.}

proc FT_List_Remove*(list: FT_List; node: FT_ListNode){.ftimport.}

proc FT_List_Up*(list: FT_List; node: FT_ListNode){.ftimport.}

type
  FT_List_Iterator* = proc(node: FT_ListNode; user: pointer): FT_Error {.ftcallback.}

proc FT_List_Iterate*(list: FT_List; `iterator`: FT_List_Iterator; user: pointer): FT_Error {.ftimport.}

type
  FT_List_Destructor* = proc(memory: FT_Memory; data: pointer; user: pointer) {.ftcallback.}

proc FT_List_Finalize*(list: FT_List; destroy: FT_List_Destructor; memory: FT_Memory;
  user: pointer) {.ftimport.}
