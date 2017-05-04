when defined(MACOSX):
  const FT_LIB_NAME* = "libfreetype-6.dylib"
elif defined(UNIX):
  const FT_LIB_NAME* = "libfreetype-6.so"
else:
  const FT_LIB_NAME* = "libfreetype-6.dll"

when defined(windows):
  {.pragma: ft_import, stdcall, importc, dynlib: FT_LIB_NAME.}
  {.pragma: ft_callback, stdcall.}
else:
  {.pragma: ft_import, cdecl, importc, dynlib: FT_LIB_NAME.}
  {.pragma: ft_callback, cdecl.}