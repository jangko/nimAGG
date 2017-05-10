import basics

type
  GlyphRasterBin* = object
    mFont: ptr uint8
    mSpan: array[32, CoverType]
    mBits: ptr uint8
    mGlyphWidth: int
    mGlyphByteWidth: int

  GlyphRect* = object
    x1*,y1*,x2*,y2*: int
    dx*, dy*: float64

proc value(p: ptr uint8): uint16 =
  when system.cpuEndian == littleEndian:
    result = p[1].uint16 shl 8
    result = result or p[0].uint16
  else:
    result = p[0].uint16 shl 8
    result = result or p[1].uint16

proc initGlyphRasterBin*(font: ptr uint8): GlyphRasterBin =
  result.mFont = font
  zeroMem(result.mSpan[0].addr, sizeof(result.mSpan))

proc font*(self: GlyphRasterBin): ptr uint8 =
  self.mFont

proc font*(self: var GlyphRasterBin, font: ptr uint8) =
  self.mFont = font

proc height*(self: GlyphRasterBin): float64 =
  self.mFont[0].float64

proc baseLine*(self: GlyphRasterBin): float64 =
  self.mFont[1].float64

proc width*(self: GlyphRasterBin, str: string): float64 =
  var
    startChar = self.mFont[2].int
    numChars = self.mFont[3].int
    w = 0

  for c in str:
    let
      glyph = c.ord
      bits = self.mFont + 4 + numChars * 2 + value(self.mFont + 4 + (glyph - startChar) * 2).int
    w += bits[].int

  result = w.float64

proc prepare*(self: var GlyphRasterBin, r: var GlyphRect, x, y: float64, glyph: int, flip: bool) =
  var
    startChar = self.mFont[2].int
    numChars = self.mFont[3].int

  self.mBits = self.mFont + 4 + numChars * 2 + value(self.mFont + 4 + (glyph - startChar) * 2).int

  self.mGlyphWidth = self.mBits[].int
  inc self.mBits
  self.mGlyphByteWidth = (self.mGlyphWidth + 7) shr 3

  r.x1 = int(x)
  r.x2 = r.x1 + self.mGlyphWidth - 1

  if flip:
    r.y1 = int(y) - self.mFont[0].int + self.mFont[1].int
    r.y2 = r.y1 + self.mFont[0].int - 1
  else:
    r.y1 = int(y) - self.mFont[1].int + 1
    r.y2 = r.y1 + self.mFont[0].int - 1
  r.dx = self.mGlyphWidth.float64
  r.dy = 0

proc span*(self: var GlyphRasterBin, i: int): ptr CoverType =
  var
    i = self.mFont[0].int - i - 1
    bits = self.mBits + i * self.mGlyphByteWidth
    val = bits[]
    nb = 0

  for j in 0.. <self.mGlyphWidth:
    self.mSpan[j] = CoverType(if (val and 0x80) != 0: coverFull else: coverNone)
    val = val shl 1
    inc nb
    if nb >= 8:
      inc bits
      val = bits[]
      nb = 0

  result = self.mSpan[0].addr
