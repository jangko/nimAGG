import agg_basics

type
  RowAccessor*[T] = ref object
    buf: ptr T    # Pointer to rendering buffer
    start: ptr T  # Pointer to first pixel depending on stride
    width: uint   # Width in pixels
    height: uint  # Height in pixels
    stride: int   # Number of bytes per row. Can be < 0

  RowPtrCache*[T] = ref object
    buf: ptr T       # Pointer to rendering buffer
    rows: seq[ptr T] # Pointers to each row of the buffer
    width: uint      # Width in pixels
    height: uint     # Height in pixels
    stride: int      # Number of bytes per row. Can be < 0

  DynaRow*[T] = ref object
    rows: seq[RowInfo[T]]
    width: int
    height: int
    byteWidth: int

  RenderingBuffer* = RowAccessor[uint8]
  RenderingBufferCached* = RowPtrCache[uint8]
  RenderingBuffer16* = RowAccessor[uint16]
  RenderingBufferCached16* = RowPtrCache[uint16]

proc attach*[T](self: RowAccessor[T], buf: ptr T, width, height: uint, stride: int) =
  self.buf = buf
  self.start = buf
  self.width = width
  self.height = height
  self.stride = stride
  if stride < 0:
    self.start = self.buf - int(height - 1) * stride

proc newRowAccessor*[T](buf: ptr T, width, height: uint, stride: int): RowAccessor[T] =
  new(result)
  result.buf = nil
  result.start = nil
  result.width = 0
  result.height = 0
  result.stride = 0
  result.attach(buf, width, height, stride)

proc newRenderingBuffer*[T](buf: ptr T, width, height: uint, stride: int): RowAccessor[T] =
  result = newRowAccessor[T](buf, width, height, stride)

proc width*[T](self: RowAccessor[T]): int {.inline.} =
  result = self.width.int

proc height*[T](self: RowAccessor[T]): int {.inline.} =
  result = self.height.int

proc getBuf*[T](self: RowAccessor[T]): ptr T {.inline.} =
  result = self.buf

proc stride*[T](self: RowAccessor[T]): int {.inline.} =
  result = self.stride

proc strideAbs*[T](self: RowAccessor[T]): int {.inline.} =
  result = if self.stride < 0: -self.stride else: self.stride

proc rowPtr*[T](self: RowAccessor[T], y: int): ptr T {.inline.} =
  result = cast[ptr T](cast[ByteAddress](self.start) + y * self.stride)

proc rowPtr*[T](self: RowAccessor[T], x, y, len: int): ptr T {.inline.} =
  result = cast[ptr T](cast[ByteAddress](self.start) + y * self.stride)

proc row*[T](self: RowAccessor[T], y: int): RowInfo[T] {.inline.} =
  result = RowInfo[T](x1:0, x2:(self.width-1).int, data: self.rowPtr(y))

proc copyFrom*[T](self, src: RowAccessor[T]) =
  let
    h = min(self.height, src.height).int
    s = min(self.strideAbs(), src.strideAbs()) * sizeof(T)
    w = min(self.width, src.width).int

  for y in 0.. <h:
    copyMem(self.rowPtr(0, y, w), src.rowPtr(y), s)

proc clear*[T](self: RowAccessor[T], value: T) =
  let
    w = self.width.int
    h = self.height.int
    stride = self.strideAbs()

  for y in 0.. <h:
    var p = self.rowPtr(0, y, w)
    for x in 0.. <stride:
      p[] = value
      inc p


proc attach*[T](self: RowPtrCache, buf: ptr T, width, height: uint, stride: int) =
  self.buf = buf
  self.width = width
  self.height = height
  self.stride = stride

  if height.int > self.rows.len:
    self.rows.setLen(height.int)

  var p = cast[ByteAddress](buf)
  if stride < 0:
    p = cast[ByteAddress](buf) - int(height - 1) * stride

  for i in 0.. <height.int:
    self.rows[i] = cast[ptr T](p)
    inc(p, stride)

proc newRowPtrCache*[T](buf: ptr T, width, height: uint, stride: int): RowPtrCache[T] =
  new(result)
  result.buf = nil
  result.rows = newSeq[ptr T](height.int)
  result.width = 0
  result.height = 0
  result.stride = 0
  result.attach(buf, width, height, stride)

proc newRenderingBufferCached*[T](buf: ptr T, width, height: uint, stride: int): RowPtrCache[T] =
  result = newRowPtrCache[T](buf, width, height, stride)

proc width*[T](self: RowPtrCache[T]): int {.inline.} =
  result = self.width.int

proc height*[T](self: RowPtrCache[T]): int {.inline.} =
  result = self.height.int

proc getBuf*[T](self: RowPtrCache[T]): ptr T {.inline.} =
  result = self.buf

proc stride*[T](self: RowPtrCache[T]): int {.inline.} =
  result = self.stride

proc strideAbs*[T](self: RowPtrCache[T]): int {.inline.} =
  result = if self.stride < 0: -self.stride else: self.stride

proc rowPtr*[T](self: RowPtrCache[T], y: int): ptr T {.inline.} =
  result = self.rows[y]

proc rowPtr*[T](self: RowPtrCache[T], x, y, z: int): ptr T {.inline.} =
  result = self.rows[y]

proc row*[T](self: RowPtrCache[T], y: int): RowInfo[T] {.inline.} =
  result = RowInfo(x1:0, x2:(self.width-1).int, data: self.rows(y))

proc copyFrom*[T](self, src: RowPtrCache[T]) =
  let
    h = min(self.height, src.height).int
    s = min(self.strideAbs(), src.strideAbs()) * sizeof(T)
    w = min(self.width, src.width).int

  for y in 0.. <h:
    copyMem(self.rowPtr(0, y, w), src.rowPtr(y), s)

proc clear*[T](self: RowPtrCache[T], value: T) =
  let
    w = self.width.int
    h = self.height.int
    stride = self.strideAbs()

  for y in 0.. <h:
    var p = self.rowPtr(0, y, w)
    for x in 0.. <stride:
      p[] = value
      inc p

proc init*[T](self: DynaRow[T], width, height, byteWidth: int) =
  for i in 0.. <self.height:
    dealloc(self.rows[i].data)

  if (width and height) != 0:
    self.width  = width
    self.height = height
    self.byteWidth = byteWidth
    self.rows.setLen(height)
    zeroMem(self.rows[0].addr, sizeof(RowInfo[T]) * height)

proc finalizer[T](self: DynaRow[T]) =
  self.init(0, 0, 0)

proc newDynaRow*[T](width, height, byteWidth: int): DynaRow[T] =
  new(result, finalizer[T])
  result.rows = newSeq[RowInfo[T]](height)
  result.width = width
  result.height = height
  result.byteWidth = byteWidth
  zeroMem(result.rows[0].addr, sizeof(RowInfo[T]) * height)

proc width*[T](self: DynaRow[T]): int = self.width
proc height*[T](self: DynaRow[T]): int = self.height
proc byteWidth*[T](self: DynaRow[T]): int = self.byteWidth

proc rowPtr*[T](self: DynaRow[T], x, y, len: int): ptr T =
  var
    r = self.rows[y].addr
    x2 = x + len - 1
  if r.data != nil:
    if x  < r.x1: r.x1 = x
    if x2 > r.x2: r.x2 = x2
  else:
    r.data = cast[ptr T](alloc0(self.byteWidth))
    r.x1  = x
    r.x2  = x2
  result = r.data

proc rowPtr*[T](self: DynaRow[T], y: int): ptr T =
  result = self.rowPtr(0, y, self.width)

proc row*[T](self: DynaRow[T], y: int): auto =
  result = self.rows[y]

proc copyFrom*[T](self, src: DynaRow[T]) =
  let
    h = min(self.height, src.height).int
    w = min(self.width, src.width).int

  for y in 0.. <h:
    copyMem(self.rowPtr(0, y, w), src.rowPtr(y), self.byteWidth)

