proc colorConv*[RenBuf, T](dst, src: var RenBuf, copyRow: T) =
  let
    width  = min(src.width(), dst.width())
    height = min(src.height(), dst.height())

  if width == 0: return
  for y in 0.. <height:
    copyRow(dst.rowPtr(0, y, width), src.rowPtr(y), width)

proc colorConvRow*[T](dst, src: ptr uint8, width: int, copyRow: T) {.inline.} =
  copyRow(dst, src, width)

template colorConvSame*(BPP: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) =
    moveMem(dst, src, width*BPP)