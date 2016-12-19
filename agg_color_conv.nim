template color_conv_same*(BPP: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) =
    moveMem(dst, src, width*BPP)