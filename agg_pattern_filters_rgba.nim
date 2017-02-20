import agg_basics, agg_line_aa_basics, agg_color_rgba

type
  PatternFilterNN*[ColorT] = object
  PatternFilterNNRgba8*  = PatternFilterNN[Rgba8]
  PatternFilterNNRgba16* = PatternFilterNN[Rgba16]

proc dilation*[ColorT](z: typedesc[PatternFilterNN[ColorT]]): int = 0

proc pixelLowRes*[ColorT](z: typedesc[PatternFilterNN[ColorT]],
  buf: openArray[ptr ColorT], p: ptr ColorT, x, y: int) =
  p[] = buf[y][x]

proc pixelHighRes*[ColorT](z: typedesc[PatternFilterNN[ColorT]],
  buf: openArray[ptr ColorT], p: ptr ColorT, x, y: int) =
  p[] = buf[y shr lineSubpixelShift][x shr lineSubpixelShift]

type
  PatternFilterBilinearRgba*[ColorT] = object
  PatternFilterBilinearRgba8*  = PatternFilterBilinearRgba[Rgba8]
  PatternFilterBilinearRgba16* = PatternFilterBilinearRgba[Rgba16]

proc dilation*[ColorT](z: typedesc[PatternFilterBilinearRgba[ColorT]]): int = 1

proc pixelLowRes*[ColorT](z: typedesc[PatternFilterBilinearRgba[ColorT]],
  buf: openArray[ptr ColorT], p: ptr ColorT, x, y: int) =
  p[] = buf[y][x]

proc pixelHighRes*[ColorT](z: typedesc[PatternFilterBilinearRgba[ColorT]],
  buf: openArray[ptr ColorT], p: ptr ColorT, x, y: int) =

  type
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)

  var
    r = CalcT(lineSubpixelScale * lineSubpixelScale div 2)
    g = r
    b = r
    a = r
    xLr = sar(x, lineSubpixelShift)
    yLr = sar(y, lineSubpixelShift)
    p   = addr(buf[yLr][xLr])

  x = x and lineSubpixelMask
  y = y and lineSubpixelMask

  var weight = (lineSubpixelScale - x) * (lineSubpixelScale - y)

  r += weight * p.r
  g += weight * p.g
  b += weight * p.b
  a += weight * p.a

  inc p

  weight = x * (lineSubpixelScale - y)
  r += weight * p.r
  g += weight * p.g
  b += weight * p.b
  a += weight * p.a

  p = addr(buf[yLr + 1][xLr])

  weight = (lineSubpixelScale - x) * y
  r += weight * p.r
  g += weight * p.g
  b += weight * p.b
  a += weight * p.a

  inc p

  weight = x * y
  r += weight * p.r
  g += weight * p.g
  b += weight * p.b
  a += weight * p.a

  p.r = ValueT(r shr lineSubpixelShift * 2)
  p.g = ValueT(g shr lineSubpixelShift * 2)
  p.b = ValueT(b shr lineSubpixelShift * 2)
  p.a = ValueT(a shr lineSubpixelShift * 2)
