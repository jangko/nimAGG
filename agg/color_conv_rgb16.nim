import basics, color_conv

proc color_conv_gray16_to_gray8*(dst, src: ptr uint8, width: int) {.procvar.} =
  var
    s = cast[ptr uint16](src)
    d = dst
    w = width

  doWhile w != 0:
    d[] = (s[] shr 8'u16).uint8
    d.inc
    s.inc
    dec w

template color_conv_rgb24_rgb48(I1, I3: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int){.procvar.}  =
    var
      d = cast[ptr uint16](dst)
      s = src
      w = width

    doWhile w != 0:
      d[] = (s[I1].uint16 shl 8'u16) or s[I1].uint16; d.inc
      d[] = (s[1].uint16  shl 8'u16) or s[1].uint16; d.inc
      d[] = (s[I3].uint16 shl 8'u16) or s[I3].uint16; d.inc
      inc(s, 3)
      dec w

color_conv_rgb24_rgb48(0,2, color_conv_rgb24_to_rgb48)
color_conv_rgb24_rgb48(0,2, color_conv_bgr24_to_bgr48)
color_conv_rgb24_rgb48(2,0, color_conv_rgb24_to_bgr48)
color_conv_rgb24_rgb48(2,0, color_conv_bgr24_to_rgb48)


template color_conv_rgb48_rgb24(I1, I3: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = cast[ptr uint16](src)
      d = dst
      w = width

    doWhile w != 0:
      d[] = (s[I1] shr 8'u16).uint8; d.inc
      d[] = (s[1]  shr 8'u16).uint8; d.inc
      d[] = (s[I3] shr 8'u16).uint8; d.inc
      inc(s, 3)
      dec w

color_conv_rgb48_rgb24(0,2, color_conv_rgb48_to_rgb24)
color_conv_rgb48_rgb24(0,2, color_conv_bgr48_to_bgr24)
color_conv_rgb48_rgb24(2,0, color_conv_rgb48_to_bgr24)
color_conv_rgb48_rgb24(2,0, color_conv_bgr48_to_rgb24)


template color_conv_rgbAAA_rgb24(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = src
      d = dst
      w = width

    doWhile w != 0:
      let rgb = cast[ptr uint32](s)[]
      d[R] = uint8((rgb shr 22) and 0xFF)
      d[1] = uint8((rgb shr 12) and 0xFF)
      d[B] = uint8((rgb shr 2)  and 0xFF)
      inc(s, 4)
      inc(d, 3)
      dec w

color_conv_rgbAAA_rgb24(0,2, color_conv_rgbAAA_to_rgb24)
color_conv_rgbAAA_rgb24(2,0, color_conv_rgbAAA_to_bgr24)
color_conv_rgbAAA_rgb24(2,0, color_conv_bgrAAA_to_rgb24)
color_conv_rgbAAA_rgb24(0,2, color_conv_bgrAAA_to_bgr24)


template color_conv_rgbBBA_rgb24(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = src
      d = dst
      w = width

    doWhile w != 0:
      let rgb = cast[ptr uint32](s)[]
      d[R] = uint8((rgb shr 24) and 0xFF)
      d[1] = uint8((rgb shr 13) and 0xFF)
      d[B] = uint8((rgb shr 2)  and 0xFF)
      inc(s, 4)
      inc(d, 3)
      dec w

color_conv_rgbBBA_rgb24(0,2, color_conv_rgbBBA_to_rgb24)
color_conv_rgbBBA_rgb24(2,0, color_conv_rgbBBA_to_bgr24)


template color_conv_bgrABB_rgb24(B, R: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = src
      d = dst
      w = width

    doWhile w != 0:
      let bgr = cast[ptr uint32](s)[]
      d[R] = uint8((bgr shr 3)  and 0xFF)
      d[1] = uint8((bgr shr 14) and 0xFF)
      d[B] = uint8((bgr shr 24) and 0xFF)
      inc(s, 4)
      inc(d, 3)
      dec w

color_conv_bgrABB_rgb24(2,0, color_conv_bgrABB_to_rgb24)
color_conv_bgrABB_rgb24(0,2, color_conv_bgrABB_to_bgr24)

template color_conv_rgba64_rgb24(I1, I2, I3: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = cast[ptr uint16](src)
    doWhile w != 0:
      d[] = uint8(s[I1] shr 8'u16); d.inc
      d[] = uint8(s[I2] shr 8'u16); d.inc
      d[] = uint8(s[I3] shr 8'u16); d.inc
      inc(s, 4)
      dec w

color_conv_rgba64_rgb24(0,1,2, color_conv_rgba64_to_rgb24)  #----color_conv_rgba64_to_rgb24
color_conv_rgba64_rgb24(1,2,3, color_conv_argb64_to_rgb24)  #----color_conv_argb64_to_rgb24
color_conv_rgba64_rgb24(2,1,0, color_conv_bgra64_to_rgb24)  #----color_conv_bgra64_to_rgb24
color_conv_rgba64_rgb24(3,2,1, color_conv_abgr64_to_rgb24)  #----color_conv_abgr64_to_rgb24
color_conv_rgba64_rgb24(2,1,0, color_conv_rgba64_to_bgr24)  #----color_conv_rgba64_to_bgr24
color_conv_rgba64_rgb24(3,2,1, color_conv_argb64_to_bgr24)  #----color_conv_argb64_to_bgr24
color_conv_rgba64_rgb24(0,1,2, color_conv_bgra64_to_bgr24)  #----color_conv_bgra64_to_bgr24
color_conv_rgba64_rgb24(1,2,3, color_conv_abgr64_to_bgr24)  #----color_conv_abgr64_to_bgr24

template color_conv_rgba64_rgba32(I1, I2, I3, I4: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = cast[ptr uint16](src)
      d = dst
      w = width

    doWhile w != 0:
      d[] = uint8(s[I1] shr 8'u16); d.inc
      d[] = uint8(s[I2] shr 8'u16); d.inc
      d[] = uint8(s[I3] shr 8'u16); d.inc
      d[] = uint8(s[I4] shr 8'u16); d.inc
      inc(s, 4)
      dec w

color_conv_rgba64_rgba32(0,1,2,3, color_conv_rgba64_to_rgba32)  #----color_conv_rgba64_to_rgba32
color_conv_rgba64_rgba32(0,1,2,3, color_conv_argb64_to_argb32)  #----color_conv_argb64_to_argb32
color_conv_rgba64_rgba32(0,1,2,3, color_conv_bgra64_to_bgra32)  #----color_conv_bgra64_to_bgra32
color_conv_rgba64_rgba32(0,1,2,3, color_conv_abgr64_to_abgr32)  #----color_conv_abgr64_to_abgr32
color_conv_rgba64_rgba32(0,3,2,1, color_conv_argb64_to_abgr32)  #----color_conv_argb64_to_abgr32
color_conv_rgba64_rgba32(3,2,1,0, color_conv_argb64_to_bgra32)  #----color_conv_argb64_to_bgra32
color_conv_rgba64_rgba32(1,2,3,0, color_conv_argb64_to_rgba32)  #----color_conv_argb64_to_rgba32
color_conv_rgba64_rgba32(3,0,1,2, color_conv_bgra64_to_abgr32)  #----color_conv_bgra64_to_abgr32
color_conv_rgba64_rgba32(3,2,1,0, color_conv_bgra64_to_argb32)  #----color_conv_bgra64_to_argb32
color_conv_rgba64_rgba32(2,1,0,3, color_conv_bgra64_to_rgba32)  #----color_conv_bgra64_to_rgba32
color_conv_rgba64_rgba32(3,2,1,0, color_conv_rgba64_to_abgr32)  #----color_conv_rgba64_to_abgr32
color_conv_rgba64_rgba32(3,0,1,2, color_conv_rgba64_to_argb32)  #----color_conv_rgba64_to_argb32
color_conv_rgba64_rgba32(2,1,0,3, color_conv_rgba64_to_bgra32)  #----color_conv_rgba64_to_bgra32
color_conv_rgba64_rgba32(0,3,2,1, color_conv_abgr64_to_argb32)  #----color_conv_abgr64_to_argb32
color_conv_rgba64_rgba32(1,2,3,0, color_conv_abgr64_to_bgra32)  #----color_conv_abgr64_to_bgra32
color_conv_rgba64_rgba32(3,2,1,0, color_conv_abgr64_to_rgba32)  #----color_conv_abgr64_to_rgba32


template color_conv_rgb24_rgba64(I1, I2, I3, A: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = src
      d = cast[ptr uint16](dst)
      w = width

    doWhile w != 0:
      d[I1] = (s[0].uint16 shl 8'u16) or s[0].uint16
      d[I2] = (s[1].uint16 shl 8'u16) or s[1].uint16
      d[I3] = (s[2].uint16 shl 8'u16) or s[2].uint16
      d[A]  = 65535
      inc(d, 4)
      inc(s, 3)
      dec w

color_conv_rgb24_rgba64(1,2,3,0, color_conv_rgb24_to_argb64)  #----color_conv_rgb24_to_argb64
color_conv_rgb24_rgba64(3,2,1,0, color_conv_rgb24_to_abgr64)  #----color_conv_rgb24_to_abgr64
color_conv_rgb24_rgba64(2,1,0,3, color_conv_rgb24_to_bgra64)  #----color_conv_rgb24_to_bgra64
color_conv_rgb24_rgba64(0,1,2,3, color_conv_rgb24_to_rgba64)  #----color_conv_rgb24_to_rgba64
color_conv_rgb24_rgba64(3,2,1,0, color_conv_bgr24_to_argb64)  #----color_conv_bgr24_to_argb64
color_conv_rgb24_rgba64(1,2,3,0, color_conv_bgr24_to_abgr64)  #----color_conv_bgr24_to_abgr64
color_conv_rgb24_rgba64(0,1,2,3, color_conv_bgr24_to_bgra64)  #----color_conv_bgr24_to_bgra64
color_conv_rgb24_rgba64(2,1,0,3, color_conv_bgr24_to_rgba64)  #----color_conv_bgr24_to_rgba64


template color_conv_rgb24_gray16(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      s = src
      d = cast[ptr uint16](dst)
      w = width

    doWhile w != 0:
      d[] = (s[R].int*77 + s[1].int*150 + s[B].int*29).uint16; d.inc
      inc(s, 3)
      dec w

color_conv_rgb24_gray16(0,2, color_conv_rgb24_to_gray16)  #----color_conv_rgb24_to_gray16
color_conv_rgb24_gray16(2,0, color_conv_bgr24_to_gray16)  #----color_conv_bgr24_to_gray16

template color_conv_gray16_rgb24(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = cast[ptr uint16](src)
    doWhile w != 0:
      let ss = uint8((s[] shr 8) and 0xFF)
      d[R] = ss
      d[1] = ss
      d[B] = ss
      inc(d, 3)
      inc s
      dec w

color_conv_gray16_rgb24(0,2, color_conv_gray16_to_rgb24)  #----color_conv_gray16_to_rgb24
color_conv_gray16_rgb24(2,0, color_conv_gray16_to_bgr24)  #----color_conv_gray16_to_bgr24