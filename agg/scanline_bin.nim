import basics

type
  SpanBin16* = object
    x*, len*: int16

  ScanlineBin* = object
    lastX: int
    y: int
    spans: seq[SpanBin16]
    curSpan: ptr SpanBin16

  SpanBin32* = object
    x*, len*: int32

  Scanline32Bin* = object
    maxLen: int
    lastX: int
    y: int
    spans: seq[SpanBin32]

proc initScanlineBin*(): ScanlineBin =
  result.lastX = 0x7FFFFFF0
  result.spans = @[]
  result.curSpan = nil

proc reset*(self: var ScanlineBin, minX, maxX: int) =
  let maxLen = maxX - minX + 3
  if maxLen > self.spans.len:
    self.spans.setLen(maxLen)

  self.lastX   = 0x7FFFFFF0
  self.curSpan = self.spans[0].addr

proc addCell*(self: var ScanlineBin, x: int, cover: uint) =
  if x == self.lastX+1:
    inc self.curSpan.len
  else:
    inc self.curSpan
    self.curSpan.x = int16(x)
    self.curSpan.len = 1
  self.lastX = x

proc addSpan*(self: var ScanlineBin, x, len: int, cover: uint) =
  if x == self.lastX+1:
    self.curSpan.len = self.curSpan.len + int16(len)
  else:
    inc self.curSpan
    self.curSpan.x = int16(x)
    self.curSpan.len = int16(len)
  self.lastX = x + len - 1

proc addCells*(self: var ScanlineBin, x, len: int, covers: ptr uint8) =
  self.addSpan(x, len, 0)

proc finalize*(self: var ScanlineBin, y: int) =
  self.y = y

proc resetSpans*(self: var ScanlineBin) =
  self.lastX  = 0x7FFFFFF0
  self.curSpan  = self.spans[0].addr

proc getY*(self: ScanlineBin): int = self.y
proc numSpans*(self: var ScanlineBin): int = self.curSpan - self.spans[0].addr
proc begin*(self: var ScanlineBin): ptr SpanBin16 = self.spans[1].addr

template getIterT*(x: typedesc[ScanlineBin]): typedesc = ptr SpanBin16

proc initScanline32bin*(): Scanline32Bin =
  result.maxLen = 0
  result.lastX = 0x7FFFFFF0
  result.spans = @[]

proc reset*(self: var Scanline32Bin, minX, maxX: int) =
  self.lastX = 0x7FFFFFF0
  self.spans.setLen(0)

proc last(x: var seq[SpanBin32]): var SpanBin32 =
  result = x[x.len-1]

proc addCell*(self: var Scanline32Bin, x: int, cover: uint) =
  if x == self.lastX+1:
    inc self.spans.last().len
  else:
    self.spans.add(SpanBin32(x: int32(x), len: 1))
  self.lastX = x

proc addSpan*(self: var Scanline32Bin,x, len: int, cover: uint) =
  if x == self.lastX+1:
    inc(self.spans.last().len, int32(len))
  else:
    self.spans.add(SpanBin32(x: int32(x), len: int32(len)))
  self.lastX = x + len - 1

proc addCells*(self: var Scanline32Bin,x, len: int, covers: ptr uint8) =
  self.addSpan(x, len, 0)

proc finalize*(self: var Scanline32Bin,y: int) =
  self.y = y

proc resetSpans*(self: var Scanline32Bin) =
  self.lastX = 0x7FFFFFF0
  self.spans.setLen(0)

proc getY*(self: Scanline32Bin): int = self.y
proc numSpans*(self: Scanline32Bin): int = self.spans.len
proc begin*(self: var Scanline32Bin): ptr SpanBin32 = self.spans[0].addr
