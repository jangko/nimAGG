import agg_basics

type
  Span16P8* = object
    x*: int16
    len*: int16
    covers*: ptr uint8

  Span32P8* = object
    x*: int32
    len*: int32
    covers*: ptr uint8

  ScanlineP8* = object
    lastX: int
    y: int
    covers: seq[uint8]
    coverPtr: ptr uint8
    spans: seq[Span16P8]
    curSpan: ptr Span16P8

  Scanline32P8* = object
    maxLen: uint
    lastX: int
    y: int
    covers: seq[uint8]
    coverPtr: ptr uint8
    spans: seq[Span32P8]

proc initScanlineP8*(): ScanlineP8 =
  result.lastX = 0x7FFFFFF0
  result.covers = @[]
  result.coverPtr = nil
  result.spans = @[]
  result.curSpan = nil

proc reset*(self: var ScanlineP8, minX, maxX: int) =
  let maxLen = maxX - minX + 3
  if maxLen > self.spans.len:
    self.spans.setLen(maxLen)
    self.covers.setLen(maxLen)

  self.lastX    = 0x7FFFFFF0
  self.coverPtr = self.covers[0].addr
  self.curSpan  = self.spans[0].addr
  self.curSpan.len = 0

proc addCell*(self: var ScanlineP8, x: int, cover: uint) =
  self.coverPtr[] = cover.uint8

  if (x == self.lastX+1) and self.curSpan.len > 0:
    inc self.curSpan.len
  else:
    inc self.curSpan
    self.curSpan.covers = self.coverPtr
    self.curSpan.x = int16(x)
    self.curSpan.len = 1

  self.lastX = x
  inc self.coverPtr

proc addCells*(self: var ScanlineP8, x: int, len: int, covers: ptr uint8) =
  copyMem(self.coverPtr, covers, len * sizeof(uint8))
  if (x == self.lastX+1) and self.curSpan.len > 0:
    inc(self.curSpan.len, int16(len))
  else:
    inc self.curSpan
    self.curSpan.covers = self.coverPtr
    self.curSpan.x = int16(x)
    self.curSpan.len = int16(len)

  inc(self.coverPtr, len)
  self.lastX = x + len - 1

proc addSpan*(self: var ScanlineP8, x, len: int, cover: uint) =
  if (x == self.lastX+1) and
    (self.curSpan.len < 0) and
    (cover == self.curSpan.covers[]):
    dec(self.curSpan.len, int16(len))
  else:
    self.coverPtr[]     = cover.uint8
    inc(self.curSpan)
    self.curSpan.covers = self.coverPtr
    inc self.coverPtr
    self.curSpan.x      = int16(x)
    self.curSpan.len    = int16(-len)
  self.lastX = x + len - 1

proc finalize*(self: var ScanlineP8, y: int) =
  self.y = y

proc resetSpans*(self: var ScanlineP8) =
  self.lastX    = 0x7FFFFFF0
  self.coverPtr = self.covers[0].addr
  self.curSpan  = self.spans[0].addr
  self.curSpan.len = 0

proc getY*(self: ScanlineP8): int = self.y
proc numSpans*(self: var ScanlineP8): int = self.curSpan - self.spans[0].unsafeAddr

proc begin*(self: var ScanlineP8): ptr Span16P8 = self.spans[1].addr

proc initScanline32P8*(): Scanline32P8 =
  result.maxLen = 0
  result.lastX = 0x7FFFFFF0
  result.covers = @[]
  result.coverPtr = nil
  result.spans = @[]

proc reset*(self: var Scanline32P8, minX, maxX: int) =
  let maxLen = maxX - minX + 3
  if maxLen > self.covers.len:
    self.covers.setLen(maxLen)

  self.lastX    = 0x7FFFFFF0
  self.coverPtr = self.covers[0].addr
  self.spans.setLen(0)

proc last(x: var seq[Span32P8]): var Span32P8 =
  result = x[x.len-1]

proc addCell*(self: var Scanline32P8, x: int, cover: uint) =
  self.coverPtr[] = cover.uint8
  if x == self.lastX+1 and self.spans.len != 0 and self.spans.last().len > 0:
    inc self.spans.last().len
  else:
    self.spans.add(Span32P8(x: x.int32, len: 1, covers: self.coverPtr))

  self.lastX = x
  inc self.coverPtr

proc addCells*(self: var Scanline32P8, x: int, len: int, covers: ptr uint8) =
  copyMem(self.coverPtr, covers, len * sizeof(uint8))
  if x == self.lastX+1 and self.spans.len != 0 and self.spans.last().len > 0:
    inc self.spans.last().len
  else:
    self.spans.add(Span32P8(x: x.int32, len: int32(len), covers: self.coverPtr))

  inc(self.coverPtr, len)
  self.lastX = x + len - 1

proc addSpan*(self: var Scanline32P8, x: int, len: int, cover: uint) =
  if x == self.lastX+1 and
    self.spans.len != 0 and
    self.spans.last().len > 0 and
    cover == self.spans.last().covers[]:
    self.spans.last().len -= int32(len)
  else:
    self.coverPtr[] = uint8(cover)
    self.spans.add(Span32P8(x: x.int32, len: -int32(len), covers: self.coverPtr))
    inc self.coverPtr

  self.lastX = x + len - 1

proc finalize*(self: var Scanline32P8, y: int) =
  self.y = y

proc resetSpans*(self: var Scanline32P8) =
  self.lastX    = 0x7FFFFFF0
  self.coverPtr = self.covers[0].addr
  self.spans.setLen(0)

proc getY*(self: Scanline32P8): int = self.y
proc numSpans*(self: Scanline32P8): int = self.spans.len
proc begin*(self: var Scanline32P8): ptr Span32P8 = self.spans[0].addr
