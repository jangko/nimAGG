import agg_basics, agg_color_conv

template color_conv_rgb24(x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      d[] = s[2]; d.inc
      d[] = s[1]; d.inc
      d[] = s[0]; d.inc
      dec w
      inc(s, 3)

color_conv_rgb24 color_conv_rgb24_to_bgr24
color_conv_rgb24 color_conv_bgr24_to_rgb24
color_conv_same 3, color_conv_bgr24_to_bgr24
color_conv_same 3, color_conv_rgb24_to_rgb24

template color_conv_rgba32(I1, I2, I3, I4: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      d[] = s[I1]; d.inc
      d[] = s[I2]; d.inc
      d[] = s[I3]; d.inc
      d[] = s[I4]; d.inc
      dec w
      inc(s, 4)

color_conv_rgba32(0,3,2,1, color_conv_argb32_to_abgr32) #----color_conv_argb32_to_abgr32
color_conv_rgba32(3,2,1,0, color_conv_argb32_to_bgra32) #----color_conv_argb32_to_bgra32
color_conv_rgba32(1,2,3,0, color_conv_argb32_to_rgba32) #----color_conv_argb32_to_rgba32
color_conv_rgba32(3,0,1,2, color_conv_bgra32_to_abgr32) #----color_conv_bgra32_to_abgr32
color_conv_rgba32(3,2,1,0, color_conv_bgra32_to_argb32) #----color_conv_bgra32_to_argb32
color_conv_rgba32(2,1,0,3, color_conv_bgra32_to_rgba32) #----color_conv_bgra32_to_rgba32
color_conv_rgba32(3,2,1,0, color_conv_rgba32_to_abgr32) #----color_conv_rgba32_to_abgr32
color_conv_rgba32(3,0,1,2, color_conv_rgba32_to_argb32) #----color_conv_rgba32_to_argb32
color_conv_rgba32(2,1,0,3, color_conv_rgba32_to_bgra32) #----color_conv_rgba32_to_bgra32
color_conv_rgba32(0,3,2,1, color_conv_abgr32_to_argb32) #----color_conv_abgr32_to_argb32
color_conv_rgba32(1,2,3,0, color_conv_abgr32_to_bgra32) #----color_conv_abgr32_to_bgra32
color_conv_rgba32(3,2,1,0, color_conv_abgr32_to_rgba32) #----color_conv_abgr32_to_rgba32

color_conv_same 4, color_conv_rgba32_to_rgba32  #----color_conv_rgba32_to_rgba32
color_conv_same 4, color_conv_argb32_to_argb32  #----color_conv_argb32_to_argb32
color_conv_same 4, color_conv_bgra32_to_bgra32  #----color_conv_bgra32_to_bgra32
color_conv_same 4, color_conv_abgr32_to_abgr32  #----color_conv_abgr32_to_abgr32

template color_conv_rgb24_rgba32(I1, I2, I3, A: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      d[I1] = s[]; s.inc
      d[I2] = s[]; s.inc
      d[I3] = s[]; s.inc
      d[A]  = 255
      dec w
      inc(d, 4)

color_conv_rgb24_rgba32(1,2,3,0, color_conv_rgb24_to_argb32) #----color_conv_rgb24_to_argb32
color_conv_rgb24_rgba32(3,2,1,0, color_conv_rgb24_to_abgr32) #----color_conv_rgb24_to_abgr32
color_conv_rgb24_rgba32(2,1,0,3, color_conv_rgb24_to_bgra32) #----color_conv_rgb24_to_bgra32
color_conv_rgb24_rgba32(0,1,2,3, color_conv_rgb24_to_rgba32) #----color_conv_rgb24_to_rgba32
color_conv_rgb24_rgba32(3,2,1,0, color_conv_bgr24_to_argb32) #----color_conv_bgr24_to_argb32
color_conv_rgb24_rgba32(1,2,3,0, color_conv_bgr24_to_abgr32) #----color_conv_bgr24_to_abgr32
color_conv_rgb24_rgba32(0,1,2,3, color_conv_bgr24_to_bgra32) #----color_conv_bgr24_to_bgra32
color_conv_rgb24_rgba32(2,1,0,3, color_conv_bgr24_to_rgba32) #----color_conv_bgr24_to_rgba32


template color_conv_rgba32_rgb24(I1, I2, I3: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      d[] = s[I1]; d.inc
      d[] = s[I2]; d.inc
      d[] = s[I3]; d.inc
      inc(s, 4)
      dec w

color_conv_rgba32_rgb24(1,2,3, color_conv_argb32_to_rgb24)  #----color_conv_argb32_to_rgb24
color_conv_rgba32_rgb24(3,2,1, color_conv_abgr32_to_rgb24)  #----color_conv_abgr32_to_rgb24
color_conv_rgba32_rgb24(2,1,0, color_conv_bgra32_to_rgb24)  #----color_conv_bgra32_to_rgb24
color_conv_rgba32_rgb24(0,1,2, color_conv_rgba32_to_rgb24)  #----color_conv_rgba32_to_rgb24
color_conv_rgba32_rgb24(3,2,1, color_conv_argb32_to_bgr24)  #----color_conv_argb32_to_bgr24
color_conv_rgba32_rgb24(1,2,3, color_conv_abgr32_to_bgr24)  #----color_conv_abgr32_to_bgr24
color_conv_rgba32_rgb24(0,1,2, color_conv_bgra32_to_bgr24)  #----color_conv_bgra32_to_bgr24
color_conv_rgba32_rgb24(2,1,0, color_conv_rgba32_to_bgr24)  #----color_conv_rgba32_to_bgr24


template color_conv_rgb555_rgb24(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      let rgb = cast[ptr uint16](s)[]
      d[R] = uint8((rgb shr 7) and 0xF8)
      d[1] = uint8((rgb shr 2) and 0xF8)
      d[B] = uint8((rgb shl 3) and 0xF8)
      inc(s, 2)
      inc(d, 3)
      dec w

color_conv_rgb555_rgb24(2,0, color_conv_rgb555_to_bgr24)  #----color_conv_rgb555_to_bgr24
color_conv_rgb555_rgb24(0,2, color_conv_rgb555_to_rgb24)  #----color_conv_rgb555_to_rgb24


template color_conv_rgb24_rgb555(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      cast[ptr uint16](d)[] = uint16(((int(s[R]) shl 7) and 0x7C00) or
                               ((int(s[1]) shl 2) and 0x3E0)  or
                               ((int(s[B]) shr 3)))
      inc(s, 3)
      inc(d, 2)
      dec w

color_conv_rgb24_rgb555(2,0, color_conv_bgr24_to_rgb555)  #----color_conv_bgr24_to_rgb555
color_conv_rgb24_rgb555(0,2, color_conv_rgb24_to_rgb555)  #----color_conv_rgb24_to_rgb555


template color_conv_rgb565_rgb24(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      let rgb = cast[ptr uint16](s)[]
      d[R] = uint8((rgb shr 8) and 0xF8)
      d[1] = uint8((rgb shr 3) and 0xFC)
      d[B] = uint8((rgb shl 3) and 0xF8)
      inc(s, 2)
      inc(d, 3)
      dec w

color_conv_rgb565_rgb24(2,0, color_conv_rgb565_to_bgr24)  #----color_conv_rgb565_to_bgr24
color_conv_rgb565_rgb24(0,2, color_conv_rgb565_to_rgb24)  #----color_conv_rgb565_to_rgb24

template color_conv_rgb24_rgb565(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      cast[ptr uint16](d)[] = uint16(((int(s[R]) shl 8) and 0xF800) or
                              ((int(s[1]) shl 3) and 0x7E0) or
                              ((int(s[B]) shr 3)))
      inc(s, 3)
      inc(d, 2)
      dec w

color_conv_rgb24_rgb565(2,0, color_conv_bgr24_to_rgb565)  #----color_conv_bgr24_to_rgb565
color_conv_rgb24_rgb565(0,2, color_conv_rgb24_to_rgb565)  #----color_conv_rgb24_to_rgb565


template color_conv_rgb555_rgba32(R, G, B, A: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      let rgb = cast[ptr uint16](s)[]
      d[R] = uint8((rgb shr 7) and 0xF8)
      d[G] = uint8((rgb shr 2) and 0xF8)
      d[B] = uint8((rgb shl 3) and 0xF8)
      d[A] = uint8(rgb shr 15)
      inc(s, 2)
      inc(d, 4)
      dec w

color_conv_rgb555_rgba32(1,2,3,0, color_conv_rgb555_to_argb32)  #----color_conv_rgb555_to_argb32
color_conv_rgb555_rgba32(3,2,1,0, color_conv_rgb555_to_abgr32)  #----color_conv_rgb555_to_abgr32
color_conv_rgb555_rgba32(2,1,0,3, color_conv_rgb555_to_bgra32)  #----color_conv_rgb555_to_bgra32
color_conv_rgb555_rgba32(0,1,2,3, color_conv_rgb555_to_rgba32)  #----color_conv_rgb555_to_rgba32


template color_conv_rgba32_rgb555(R, G, B, A: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      cast[ptr uint16](d)[] = uint16(((int(s[R]) shl 7) and 0x7C00) or
                              ((int(s[G]) shl 2) and 0x3E0)  or
                              ((int(s[B]) shr 3)) or
                              ((int(s[A]) shl 8) and 0x8000))
      inc(s, 4)
      inc(d, 2)
      dec w

color_conv_rgba32_rgb555(1,2,3,0, color_conv_argb32_to_rgb555)  #----color_conv_argb32_to_rgb555
color_conv_rgba32_rgb555(3,2,1,0, color_conv_abgr32_to_rgb555)  #----color_conv_abgr32_to_rgb555
color_conv_rgba32_rgb555(2,1,0,3, color_conv_bgra32_to_rgb555)  #----color_conv_bgra32_to_rgb555
color_conv_rgba32_rgb555(0,1,2,3, color_conv_rgba32_to_rgb555)  #----color_conv_rgba32_to_rgb555

template color_conv_rgb565_rgba32(R, G, B, A: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      let rgb = cast[ptr uint16](s)[]
      d[R] = uint8((rgb shr 8) and 0xF8)
      d[G] = uint8((rgb shr 3) and 0xFC)
      d[B] = uint8((rgb shl 3) and 0xF8)
      d[A] = 255.uint8
      inc(s, 2)
      inc(d, 4)
      dec w

color_conv_rgb565_rgba32(1,2,3,0, color_conv_rgb565_to_argb32)  #----color_conv_rgb565_to_argb32
color_conv_rgb565_rgba32(3,2,1,0, color_conv_rgb565_to_abgr32)  #----color_conv_rgb565_to_abgr32
color_conv_rgb565_rgba32(2,1,0,3, color_conv_rgb565_to_bgra32)  #----color_conv_rgb565_to_bgra32
color_conv_rgb565_rgba32(0,1,2,3, color_conv_rgb565_to_rgba32)  #----color_conv_rgb565_to_rgba32


template color_conv_rgba32_rgb565(R, G, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      cast[ptr uint16](d)[] = uint16(((int(s[R]) shl 8) and 0xF800) or
                                     ((int(s[G]) shl 3) and 0x7E0)  or
                                     ((int(s[B]) shr 3)))
      inc(s, 4)
      inc(d, 2)
      dec w

color_conv_rgba32_rgb565(1,2,3, color_conv_argb32_to_rgb565)  #----color_conv_argb32_to_rgb565
color_conv_rgba32_rgb565(3,2,1, color_conv_abgr32_to_rgb565)  #----color_conv_abgr32_to_rgb565
color_conv_rgba32_rgb565(2,1,0, color_conv_bgra32_to_rgb565)  #----color_conv_bgra32_to_rgb565
color_conv_rgba32_rgb565(0,1,2, color_conv_rgba32_to_rgb565)  #----color_conv_rgba32_to_rgb565


proc color_conv_rgb555_to_rgb565*(dst, src: ptr uint8, width: int) {.procvar.} =
  var
    d = dst
    w = width
    s = src
  doWhile w != 0:
    let rgb = cast[ptr uint16](s)[]
    cast[ptr uint16](d)[] = uint16(((rgb shl 1) and 0xFFC0) or (rgb and 0x1F))
    inc(s, 2)
    inc(d, 2)
    dec w

proc color_conv_rgb565_to_rgb555*(dst, src: ptr uint8, width: int) {.procvar.} =
  var
    d = dst
    w = width
    s = src
  doWhile w != 0:
    let rgb = cast[ptr uint16](s)[]
    cast[ptr uint16](d)[] = uint16(((rgb shr 1) and 0x7FE0) or (rgb and 0x1F))
    inc(s, 2)
    inc(d, 2)
    dec w

color_conv_same(2, color_conv_rgb555_to_rgb555)  #----color_conv_rgb555_to_rgb555
color_conv_same(2, color_conv_rgb565_to_rgb565)  #----color_conv_rgb565_to_rgb565


template color_conv_rgb24_gray8(R, B: int, x: untyped) =
  proc x*(dst, src: ptr uint8, width: int) {.procvar.} =
    var
      d = dst
      w = width
      s = src
    doWhile w != 0:
      d[] = ((s[R].int*77 + s[1].int*150 + s[B].int*29) shr 8).uint8
      inc(s, 3)
      inc d
      dec w

color_conv_rgb24_gray8(0,2, color_conv_rgb24_to_gray8)  #----color_conv_rgb24_to_gray8
color_conv_rgb24_gray8(2,0, color_conv_bgr24_to_gray8)  #----color_conv_bgr24_to_gray8
