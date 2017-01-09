import agg_basics

type
  Span16U8* = object
    x*: int16
    len*: int16
    covers*: ptr uint8
        
  ScanlineU8* = object
    minX: int
    lastX: int
    y: int
    covers: seq[uint8]
    spans: seq[Span16U8]
    curSpan: ptr Span16U8

proc initScanlineU8*(): ScanlineU8 =
  result.minX = 0
  result.lastX = 0x7FFFFFF0
  result.curSpan = nil
  result.covers = @[]
  result.spans = @[]
    
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

