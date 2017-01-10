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

#[
scanline32_p8() :
    self.maxLen(0),
    self.lastX(0x7FFFFFF0),
    self.covers(),
    self.coverPtr(0)

proc reset(int min_x, int max_x)
{
    unsigned max_len = max_x - min_x + 3;
    if(max_len > self.covers.size())
    {
        self.covers.resize(max_len);
    }
    self.lastX    = 0x7FFFFFF0;
    self.coverPtr = &self.covers[0];
    self.spans.remove_all();

proc add_cell(int x, unsigned cover)
    *self.coverPtr = cover_type(cover);
    if(x == self.lastX+1 and self.spans.size() and self.spans.last().len > 0)
    {
        self.spans.last().len++;
    }
    else
    {
        self.spans.add(span(coord_type(x), 1, self.coverPtr));
    }
    self.lastX = x;
    self.coverPtr++;

proc add_cells(int x, unsigned len, const cover_type* covers)
    memcpy(self.coverPtr, covers, len * sizeof(cover_type));
    if(x == self.lastX+1 and self.spans.size() and self.spans.last().len > 0)
    {
        self.spans.last().len += coord_type(len);
    }
    else
    {
        self.spans.add(span(coord_type(x), coord_type(len), self.coverPtr));
    }
    self.coverPtr += len;
    self.lastX = x + len - 1;

proc add_span(int x, unsigned len, unsigned cover)
    if(x == self.lastX+1 and
       self.spans.size() and
       self.spans.last().len < 0 and
       cover == *self.spans.last().covers)
    {
        self.spans.last().len -= coord_type(len);
    }
    else
    {
        *self.coverPtr = cover_type(cover);
        self.spans.add(span(coord_type(x), -coord_type(len), self.coverPtr++));
    }
    self.lastX = x + len - 1;

proc finalize(int y)
    m_y = y;

proc reset_spans()
    self.lastX    = 0x7FFFFFF0;
    self.coverPtr = &self.covers[0];
    self.spans.remove_all();

int            y()         const { return m_y; }
unsigned       nuself.spans() const { return self.spans.size(); }
const_iterator begin()     const { return const_iterator(self.spans); }
]#