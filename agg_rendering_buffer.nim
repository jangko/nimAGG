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

  RenderingBuffer* = RowAccessor[uint8]
  RenderingBufferCached* = RowPtrCache[uint8]

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

proc newRenderingBuffer*(buf: ptr uint8, width, height: uint, stride: int): RenderingBuffer =
  result = newRowAccessor[uint8](buf, width, height, stride)

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
  result = self.start + y * self.stride

proc rowPtr*[T](self: RowAccessor[T], x, y, z: int): ptr T {.inline.} =
  result = self.start + y * self.stride

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

  var p = buf
  if stride < 0:
    p = buf - int(height - 1) * stride

  for i in 0.. <height.int:
    self.rows[i] = p
    inc(p, stride)

proc newRowPtrCache*[T](buf: ptr T, width, height: uint, stride: int): RowPtrCache[T] =
  new(result)
  result.buf = nil
  result.rows = newSeq[ptr T](height.int)
  result.width = 0
  result.height = 0
  result.stride = 0
  result.attach(buf, width, height, stride)

proc newRenderingBufferCached*(buf: ptr uint8, width, height: uint, stride: int): RenderingBufferCached =
  result = newRowPtrCache[uint8](buf, width, height, stride)

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