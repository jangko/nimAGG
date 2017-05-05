import fttypes, freetype, ftsystem
include ftimport

const
  FT_MODULE_FONT_DRIVER* = 1
  FT_MODULE_RENDERER* = 2
  FT_MODULE_HINTER* = 4
  FT_MODULE_STYLER* = 8
  FT_MODULE_DRIVER_SCALABLE* = 0x00000100
  FT_MODULE_DRIVER_NO_OUTLINES* = 0x00000200
  FT_MODULE_DRIVER_HAS_HINTER* = 0x00000400
  FT_MODULE_DRIVER_HINTS_LIGHTLY* = 0x00000800
  ft_module_font_driver* = FT_MODULE_FONT_DRIVER
  ft_module_renderer* = FT_MODULE_RENDERER
  ft_module_hinter* = FT_MODULE_HINTER
  ft_module_styler* = FT_MODULE_STYLER
  ft_module_driver_scalable* = FT_MODULE_DRIVER_SCALABLE
  ft_module_driver_no_outlines* = FT_MODULE_DRIVER_NO_OUTLINES
  ft_module_driver_has_hinter* = FT_MODULE_DRIVER_HAS_HINTER
  ft_module_driver_hints_lightly* = FT_MODULE_DRIVER_HINTS_LIGHTLY

type
  FT_Module_Interface* = FT_Pointer
  FT_Module_Constructor* = proc(module: FT_Module): FT_Error {.ftcallback.}
  FT_Module_Destructor* = proc(module: FT_Module) {.ftcallback.}
  FT_Module_Requester* = proc(module: FT_Module; name: ptr cchar): FT_Module_Interface {.ftcallback.}

  FT_Module_Class* = object
    module_flags*: FT_ULong
    module_size*: FT_Long
    module_name*: ptr FT_String
    module_version*: FT_Fixed
    module_requires*: FT_Fixed
    module_interface*: pointer
    module_init*: FT_Module_Constructor
    module_done*: FT_Module_Destructor
    get_interface*: FT_Module_Requester


proc FT_Add_Module*(library: FT_Library; clazz: ptr FT_Module_Class): FT_Error {.ftimport.}
proc FT_Get_Module*(library: FT_Library; module_name: ptr cchar): FT_Module {.ftimport.}
proc FT_Remove_Module*(library: FT_Library; module: FT_Module): FT_Error {.ftimport.}
proc FT_Property_Set*(library: FT_Library; module_name: ptr FT_String;
                     property_name: ptr FT_String; value: pointer): FT_Error {.ftimport.}
proc FT_Property_Get*(library: FT_Library; module_name: ptr FT_String;
                     property_name: ptr FT_String; value: pointer): FT_Error {.ftimport.}
proc FT_Reference_Library*(library: FT_Library): FT_Error {.ftimport.}
proc FT_New_Library*(memory: FT_Memory; alibrary: ptr FT_Library): FT_Error {.ftimport.}
proc FT_Done_Library*(library: FT_Library): FT_Error {.ftimport.}

type
  FT_DebugHook_Func* = proc(arg: pointer) {.ftcallback.}

proc FT_Set_Debug_Hook*(library: FT_Library; hook_index: FT_UInt;
                       debug_hook: FT_DebugHook_Func) {.ftimport.}
proc FT_Add_Default_Modules*(library: FT_Library) {.ftimport.}

type
  FT_TrueTypeEngineType* = enum
    FT_TRUETYPE_ENGINE_TYPE_NONE = 0, FT_TRUETYPE_ENGINE_TYPE_UNPATENTED,
    FT_TRUETYPE_ENGINE_TYPE_PATENTED

proc FT_Get_TrueType_Engine_Type*(library: FT_Library): FT_TrueTypeEngineType {.ftimport.}
