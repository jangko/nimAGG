import basics

type
  Span16U8* = object
    x*: int16
    len*: int16
    covers*: ptr uint8

  ScanlineU8* = object of RootObj
    minX: int
    lastX: int
    y: int
    covers: seq[uint8]
    spans: seq[Span16U8]
    curSpan: ptr Span16U8

  ScanlineU8Am*[AlphaMask] = object of ScanlineU8
    alphaMask: ptr AlphaMask

  Span32U8* = object
    x*: int32
    len*: int32
    covers*: ptr uint8

  Scanline32U8* = object of RootObj
    minX: int
    lastX: int
    y: int
    covers: seq[uint8]
    spans: seq[Span32U8]

  Scanline32U8Am*[AlphaMask] = object of Scanline32U8
    alphaMask: var AlphaMask

template getIterT*(x: typedesc[ScanlineU8]): typedesc = ptr Span16U8
template getCoverT*(x: typedesc[ptr Span16U8]): typedesc = uint8

proc init(self: var ScanlineU8) =
  self.minX = 0
  self.lastX = 0x7FFFFFF0
  self.curSpan = nil
  self.covers = @[]
  self.spans = @[]

proc initScanlineU8*(): ScanlineU8 =
  result.init()

proc reset*(self: var ScanlineU8, minX, maxX: int) =
  let maxLen = maxX - minX + 2
  if maxLen > self.spans.len:
    self.spans.setLen(maxLen)
    self.covers.setLen(maxLen)

  self.lastX   = 0x7FFFFFF0
  self.minX    = minX
  self.curSpan = self.spans[0].addr

proc addCell*(self: var ScanlineU8, x: int, cover: uint) =
  var x = x - self.minX
  self.covers[x] = cover.uint8
  if x == self.lastX+1:
    inc self.curSpan.len
  else:
    inc self.curSpan
    self.curSpan.x      = int16(x + self.minX)
    self.curSpan.len    = 1
    self.curSpan.covers = self.covers[x].addr

  self.lastX = x

proc addCells*(self: var ScanlineU8, x: int, len: int, covers: ptr uint8) =
  var x = x - self.minX
  copyMem(self.covers[x].addr, covers, len * sizeof(uint8))
  if x == self.lastX+1:
    inc(self.curSpan.len, int16(len))
  else:
    inc self.curSpan
    self.curSpan.x      = int16(x + self.minX)
    self.curSpan.len    = int16(len)
    self.curSpan.covers = self.covers[x].addr

  self.lastX = x + len - 1

proc addSpan*(self: var ScanlineU8, x: int, len: int, cover: uint) =
  var x = x - self.minX
  setMem(self.covers[x].addr, cover, len)
  if x == self.lastX+1:
    inc(self.curSpan.len, int16(len))
  else:
    inc self.curSpan
    self.curSpan.x      = int16(x + self.minX)
    self.curSpan.len    = int16(len)
    self.curSpan.covers = self.covers[x].addr

  self.lastX = x + len - 1

proc finalize*(self: var ScanlineU8, y: int) =
  self.y = y

proc resetSpans*(self: var ScanlineU8) =
  self.lastX    = 0x7FFFFFF0
  self.curSpan  = self.spans[0].addr

proc getY*(self: ScanlineU8): int = self.y

proc numSpans*(self: var ScanlineU8): int = self.curSpan - self.spans[0].addr
proc begin*(self: var ScanlineU8): auto = self.spans[1].addr

proc initScanlineU8Am*[AlphaMask](am: var AlphaMask): ScanlineU8Am[AlphaMask] =
  ScanlineU8(result).init()
  result.alphaMask = am.addr

proc finalize*[AlphaMask](self: var ScanlineU8Am[AlphaMask], spanY: int) =
  ScanlineU8(self).finalize(spanY)
  if self.alphaMask != nil:
    var
      span = self.begin()
      count = self.numSpans()

    doWhile count != 0:
      self.alphaMask[].combineHspan(span.x, self.getY(), span.covers, span.len)
      inc span
      dec count


proc init(self: var Scanline32U8) =
  self.minX = 0
  self.lastX = 0x7FFFFFF0
  self.covers = @[]
  self.spans= @[]

proc initScanline32U8*(): Scanline32U8 =
  result.init()

proc reset*(self: var Scanline32U8, minX, maxX: int) =
  let maxLen = maxX - minX + 2
  if maxLen > self.covers.len:
    self.covers.setLen(maxLen)

  self.lastX = 0x7FFFFFF0
  self.minX  = minX
  self.spans.setLen(0)

proc last(x: var seq[Span32U8]): var Span32U8 =
  result = x[x.len-1]

proc addCell*(self: var Scanline32U8, x: int, cover: uint) =
  var x = x - self.minX
  self.covers[x] = uint8(cover)
  if x == self.lastX+1:
    inc self.spans.last().len
  else:
    self.spans.add(Span32U8(x: int32(x + self.minX), len: 1, covers: self.covers[x].addr))
  self.lastX = x

proc addCells*(self: var Scanline32U8, x, len: int, covers: ptr uint8) =
  var x = x - self.minX
  copyMem(self.covers[x].addr, covers, len * sizeof(uint8))

  if x == self.lastX+1:
    inc(self.spans.last().len, int32(len))
  else:
    self.spans.add(Span32U8(x: int32(x + self.minX), len: int32(len), covers: self.covers[x].addr))

  self.lastX = x + len - 1

proc addSpan*(self: var Scanline32U8, x, len: int, cover: uint) =
  var x = x - self.minX
  setMem(self.covers[x].addr, cover, len)

  if x == self.lastX+1:
    inc(self.spans.last().len, int32(len))
  else:
    self.spans.add(Span32U8(x: int32(x + self.minX), len: int32(len), covers: self.covers[x].addr))
  self.lastX = x + len - 1

proc finalize*(self: var Scanline32U8, y: int) =
  self.y = y

proc resetSpans*(self: var Scanline32U8) =
  self.lastX = 0x7FFFFFF0
  self.spans.setLen(0)

proc getY*(self: Scanline32U8): int = self.y
proc numSpans*(self: Scanline32U8): int =  self.spans.len
proc begin*(self: var Scanline32U8): ptr Span32U8 = self.spans[0].addr

proc initScanline32U8Am*[AlphaMask](am: var AlphaMask): Scanline32U8Am[AlphaMask] =
  Scanline32U8(result).init()
  result.alphaMask = am

proc finalize*[AlphaMask](self: Scanline32U8Am[AlphaMask], spanY: int) =
  Scanline32U8(self).finalize(spanY)
  if self.alphaMask != nil:
    var
      span = self.begin()
      count = self.numSpans()

    doWhile count != 0:
      self.alphaMask.combineHspan(span.x, self.getY(), span.covers, span.len)
      inc span
      dec count
