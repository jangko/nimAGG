import basics

type
  ScanlineCellStorage*[T] = object
    mCells: seq[seq[T]]

proc initScanlineCellStorage*[T](): ScanlineCellStorage[T] =
  result.mCells = @[]

# Copying
proc initScanlineCellStorage*[T](v: ScanlineCellStorage[T]): ScanlineCellStorage[T] =
  result.mCells = v.mCells

proc removeAll*[T](self: var ScanlineCellStorage[T]) =
  self.mCells.setLen(0)

proc copy*[T](self: var ScanlineCellStorage[T], v: ScanlineCellStorage[T]) =
  self.mCells = v.mCells

proc addCells*[T](self: var ScanlineCellStorage[T], cells: ptr T, numCells: int): int =
  result = self.mCells.len
  self.mCells.add newSeq[T](numCells)
  copyMem(self.mCells[result][0].addr, cells, numCells * sizeof(T))

proc `[]`*[T](self: var ScanlineCellStorage[T], idx: int): ptr T =
  if idx >= self.mCells.len: return nil
  self.mCells[idx][0].addr

type
  SpanDataAA = object
    x: int32
    len: int32     # If negative, it's a solid span, covers is valid
    coversId: int  # The index of the cells in the scanline_cell_storage

  ScanlineDataAA = object
    y: int
    numSpans: int
    startSpan: int

  ScanlineStorageAA*[T] = object
    mCovers: ScanlineCellStorage[T]
    mSpans: seq[SpanDataAA]
    mScanlines: seq[ScanlineDataAA]
    mFakeSpan: SpanDataAA
    mFakeScanline: ScanlineDataAA
    mMinX, mMinY: int
    mMaxX, mMaxY: int
    mCurScanline: int

  EmbeddedScanlineAA[T] = object
    mStorage: ptr ScanlineStorageAA[T]
    mScanline: ScanlineDataAA
    mScanlineIdx: int

  spanAA[T] = object
    x: int32
    len: int32 # If negative, it's a solid span, covers is valid
    covers: ptr T

  ConstIteratorAA*[T] = object
    mStorage: ptr ScanlineStorageAA[T]
    mSpanIdx: int
    mSpan: spanAA[T]

template getCoverT*[T](x: typedesc[ConstIteratorAA[T]]): typedesc = T
template getIterT*[T](x: typedesc[ScanlineStorageAA[T]]): typedesc = ConstIteratorAA[T]

proc initSpan[T](self: var ConstIteratorAA[T]) =
  var s = self.mStorage[].spanByIndex(self.mSpanIdx)
  self.mSpan.x      = s.x
  self.mSpan.len    = s.len
  self.mSpan.covers = self.mStorage[].coversByIndex(s.coversId)

proc initConstIteratorAA*[T](sl: var EmbeddedScanlineAA[T]): ConstIteratorAA[T] =
  result.mStorage = sl.mStorage
  result.mSpanIdx = sl.mScanline.startSpan
  result.initSpan()

proc inc*[T](self: var ConstIteratorAA[T]) {.inline.} =
  inc self.mSpanIdx
  self.initSpan()

proc x*[T](self: ConstIteratorAA[T]): int {.inline.} =
  self.span.x.int

proc len*[T](self: ConstIteratorAA[T]): int {.inline.} =
  self.span.len.int

proc covers*[T](self: ConstIteratorAA[T]): ptr T {.inline.} =
  self.span.covers

proc init[T](self: var EmbeddedScanlineAA[T], scanlineIdx: int) =
  self.mScanlineIdx = scanlineIdx
  self.mScanline = self.mStorage[].scanlineByIndex(self.mScanlineIdx)

proc initEmbeddedScanlineAA*[T](storage: var ScanlineStorageAA[T]): EmbeddedScanlineAA[T] =
  result.mStorage = storage.addr
  result.init(0)

proc reset*[T](self: EmbeddedScanlineAA[T], maxX, maxY: int)=
  discard

proc numSpans*[T](self: EmbeddedScanlineAA[T]): int =
  self.mScanline.numSpans

proc getY*[T](self: EmbeddedScanlineAA[T]): int =
  self.mScanline.y

proc begin*[T](self: var EmbeddedScanlineAA[T]): ConstIteratorAA[T] =
  initConstIteratorAA(self)

proc initScanlineStorageAA*[T](): ScanlineStorageAA[T] =
  result.mCovers = initScanlineCellStorage[T]()
  result.mSpans = @[]
  result.mScanlines = @[]
  result.mMinX =  0x7FFFFFFF
  result.mMinY =  0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF
  result.mCurScanline = 0
  result.mFakeScanline.y = 0
  result.mFakeScanline.numSpans = 0
  result.mFakeScanline.startSpan = 0
  result.mFakeSpan.x = 0
  result.mFakeSpan.len = 0
  result.mFakeSpan.coversId = 0

# Renderer Interface
proc prepare*[T](self: var ScanlineStorageAA[T]) =
  self.mCovers.removeAll()
  self.mScanlines.setLen(0)
  self.mSpans.setLen(0)
  self.mMinX =  0x7FFFFFFF
  self.mMinY =  0x7FFFFFFF
  self.mMaxX = -0x7FFFFFFF
  self.mMaxY = -0x7FFFFFFF
  self.mCurScanline = 0

proc render*[T, Scanline](self: var ScanlineStorageAA[T], sl: var Scanline) =
  mixin getY, numSpans, begin
  var
    slThis: ScanlineDataAA
    y = sl.getY()

  if y < self.mMinY: self.mMinY = y
  if y > self.mMaxY: self.mMaxY = y

  slThis.y = y
  slThis.numSpans  = sl.numSpans()
  slThis.startSpan = self.mSpans.len
  var
    span = sl.begin()
    numSpan = slThis.numSpans

  while true:
    var sp: SpanDataAA

    sp.x         = span.x
    sp.len       = span.len
    var len      = abs(sp.len)
    sp.coversId  = self.mCovers.addCells(span.covers, len)
    self.mSpans.add(sp)

    var
      x1 = sp.x
      x2 = sp.x + len - 1

    if x1 < self.mMinX: self.mMinX = x1
    if x2 > self.mMaxX: self.mMaxX = x2
    dec numSpan
    if numSpan == 0: break
    inc span

  self.mScanlines.add(slThis)

# Iterate scanlines interface
proc minX*[T](self: ScanlineStorageAA[T]): int = self.mMinX
proc minY*[T](self: ScanlineStorageAA[T]): int = self.mMinY
proc maxX*[T](self: ScanlineStorageAA[T]): int = self.mMaxX
proc maxY*[T](self: ScanlineStorageAA[T]): int = self.mMaxY

proc rewindScanlines*[T](self: var ScanlineStorageAA[T]): bool =
  self.mCurScanline = 0
  result = self.mScanlines.len > 0

proc sweepScanline*[T, Scanline](self: var ScanlineStorageAA[T], sl: var Scanline): bool =
  mixin addCells
  sl.resetSpans()
  while true:
    if self.mCurScanline >= self.mScanlines.len: return false
    var
      slThis = self.mScanlines[self.mCurScanline].addr
      numSpans = slThis.numSpans
      spanIdx  = slThis.startSpan

    doWhile numSpans != 0:
      var
        sp = self.mSpans[spanIdx].addr
        covers = self.coversByIndex(sp.coversId)

      inc spanIdx
      if sp.len < 0:
        sl.addSpan(sp.x, -sp.len, covers[])
      else:
        sl.addCells(sp.x, sp.len, covers)
      dec numSpans

    inc self.mCurScanline
    if sl.numSpans() != 0:
      sl.finalize(slThis.y)
      break

  result = true

# Specialization for embedded_scanline
proc sweepScanline*[T](self: var ScanlineStorageAA[T], sl: var EmbeddedScanlineAA[T]): bool =
  doWhile sl.numSpans() == 0:
    if self.mCurScanline >= self.mScanlines.len: return false
    sl.init(self.mCurScanline)
    inc self.mCurScanline

  result = true

proc byteSize*[T](self: var ScanlineStorageAA[T]): int =
  var size = sizeof(int32) * 4 # minX, minY, maxX, maxY

  for i in 0..<self.mScanlines.len:
    size += sizeof(int32) * 3 # scanline size in bytes, Y, numSpans

    var
      slThis = self.mScanlines[i].addr
      numSpans = slThis.numSpans
      spanIdx  = slThis.startSpan

    doWhile numSpans != 0:
      var sp = self.mSpans[spanIdx].addr
      inc spanIdx

      size += sizeof(int32) * 2    # X, span_len
      if sp.len < 0:
        size += sizeof(T)          # cover
      else:
        size += sizeof(T) * sp.len # covers
      dec numSpans

  result = size

proc writeInt32(dst: ptr uint8, val: int32) =
  var val = val
  dst[0] = cast[ptr uint8](val.addr)[0]
  dst[1] = cast[ptr uint8](val.addr)[1]
  dst[2] = cast[ptr uint8](val.addr)[2]
  dst[3] = cast[ptr uint8](val.addr)[3]

proc serialize*[T](self: var ScanlineStorageAA[T], data: ptr uint8) =
  var data = data
  writeInt32(data, self.minX().int32) # minX
  data += sizeof(int32)
  writeInt32(data, self.minY().int32) # minY
  data += sizeof(int32)
  writeInt32(data, self.maxX().int32) # maxX
  data += sizeof(int32)
  writeInt32(data, self.maxY().int32) # maxY
  data += sizeof(int32)

  for i in 0..<self.mScanlines.len:
    var
      slThis  = self.mScanlines[i].addr
      sizePtr = data
      numSpans = slThis.numSpans
      spanIdx  = slThis.startSpan

    data += sizeof(int32)  # Reserve space for scanline size in bytes

    writeInt32(data, slThis.y.int32)           # Y
    data += sizeof(int32)

    writeInt32(data, slThis.numSpans.int32)    # numSpans
    data += sizeof(int32)

    doWhile numSpans != 0:
      var
        sp = self.mSpans[spanIdx].addr
        covers = self.coversByIndex(sp.coversId)

      inc spanIdx

      writeInt32(data, sp.x.int32)      # X
      data += sizeof(int32)

      writeInt32(data, sp.len.int32)          # span_len
      data += sizeof(int32)

      if sp.len < 0:
        copyMem(data, covers, sizeof(T))
        data += sizeof(T)
      else:
        copyMem(data, covers, sp.len * sizeof(T))
        data += sizeof(T) * sp.len
      dec numSpans

    writeInt32(sizePtr, int32(data - sizePtr))

proc scanlineByIndex*[T](self: var ScanlineStorageAA[T], i: int): var ScanlineDataAA =
  result = if i < self.mScanlines.len: self.mScanlines[i] else: self.mFakeScanline

proc spanByIndex*[T](self: var ScanlineStorageAA[T], i: int): var SpanDataAA =
  result = if i < self.mSpans.len: self.mSpans[i] else: self.mFakeSpan

proc coversByIndex*[T](self: var ScanlineStorageAA[T], i: int): ptr T =
  self.mCovers[i]

type
  ScanlineStorageAA8*  = ScanlineStorageAA[uint8]
  ScanlineStorageAA16* = ScanlineStorageAA[uint16]
  ScanlineStorageAA32* = ScanlineStorageAA[uint32]

proc initScanlineStorageAA8*(): ScanlineStorageAA8 =
  initScanlineStorageAA[uint8]()

proc initScanlineStorageAA16*(): ScanlineStorageAA16 =
  initScanlineStorageAA[uint16]()

proc initScanlineStorageAA32*(): ScanlineStorageAA32 =
  initScanlineStorageAA[uint32]()


type
  SerializedScanlinesAdaptorAA*[T] = object
    mData, mEnd, mPtr: ptr uint8
    mDx, mDy: int
    mMinX, mMinY: int
    mMaxX, mMaxY: int

  EmbeddedScanlineAdaptorAA*[T] = object
    mPtr: ptr uint8
    mY, mNumSpans: int
    mDx: int

  SpanIteratorAdaptorAA[T] = object
    x: int32
    len: int32 # If negative, it's a solid span, "covers" is valid
    covers: ptr T

  ConstIteratorAdaptorAA*[T] = object
    mPtr: ptr uint8
    mSpan: SpanIteratorAdaptorAA[T]
    mDx: int

template getCoverT*[T](x: typedesc[ConstIteratorAdaptorAA[T]]): typedesc = T
template getIterT*[T](x: typedesc[SerializedScanlinesAdaptorAA[T]]): typedesc = ConstIteratorAdaptorAA[T]
template embeddedScanlineT*[T](x: typedesc[SerializedScanlinesAdaptorAA[T]]): typedesc =
  EmbeddedScanlineAdaptorAA[T.type]

proc readInt32*[T](self: var ConstIteratorAdaptorAA[T]): int32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

proc initSpan*[T](self: var ConstIteratorAdaptorAA[T]) =
  self.mSpan.x      = self.readInt32() + self.mDx.int32
  self.mSpan.len    = self.readInt32()
  self.mSpan.covers = self.mPtr

proc initConstIteratorAdaptorAA*[T](sl: var EmbeddedScanlineAdaptorAA[T]): ConstIteratorAdaptorAA[T] =
  result.mPtr = sl.mPtr
  result.mDx  = sl.mDx
  result.initSpan()

proc inc*[T](self: var ConstIteratorAdaptorAA[T]) =
  if self.mSpan.len < 0:
    self.mPtr += sizeof(T)
  else:
    self.mPtr += self.mSpan.len * sizeof(T)
  self.initSpan()

proc x*[T](self: ConstIteratorAdaptorAA[T]): int {.inline.} =
  self.mSpan.x.int

proc len*[T](self: ConstIteratorAdaptorAA[T]): int {.inline.} =
  self.mSpan.len.int

proc covers*[T](self: ConstIteratorAdaptorAA[T]): ptr T {.inline.} =
  self.mSpan.covers

proc initEmbeddedScanlineAdaptorAA*[T](): EmbeddedScanlineAdaptorAA[T] =
  result.mPtr = nil
  result.mY = 0
  result.mNumSpans = 0

proc reset*[T](self: EmbeddedScanlineAdaptorAA[T], maxX, maxY: int) =
  discard

proc numSpans*[T](self: EmbeddedScanlineAdaptorAA[T]): int =
  self.mNumSpans

proc getY*[T](self: EmbeddedScanlineAdaptorAA[T]): int =
  self.mY

proc begin*[T](self: var EmbeddedScanlineAdaptorAA[T]): ConstIteratorAdaptorAA[T] =
  initConstIteratorAdaptorAA(self)

proc readInt32*[T](self: var EmbeddedScanlineAdaptorAA[T]): int32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

proc init*[T](self: var EmbeddedScanlineAdaptorAA[T], p: ptr uint8, dx, dy: int) =
  self.mPtr      = p
  self.mY        = self.readInt32() + dy
  self.mNumSpans = self.readInt32()
  self.mDx       = dx

proc initSerializedScanlinesAdaptorAA*[T](): SerializedScanlinesAdaptorAA[T] =
  result.mData = nil
  result.mEnd  = nil
  result.mPtr  = nil
  result.mDx   = 0
  result.mDy   = 0
  result.mMinX = 0x7FFFFFFF
  result.mMinY = 0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF

proc initSerializedScanlinesAdaptorAA*[T](data: ptr uint8,
  size: int, dx, dy: float64): SerializedScanlinesAdaptorAA[T] =
  result.mData = data
  result.mEnd  = data + size
  result.mPtr  = data
  result.mDx   = iround(dx)
  result.mDy   = iround(dy)
  result.mMinX = 0x7FFFFFFF
  result.mMinY = 0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF

proc init*[T](self: var SerializedScanlinesAdaptorAA[T], data: ptr uint8,
  size: int, dx, dy: float64) =
  self.mData = data
  self.mEnd  = data + size
  self.mPtr  = data
  self.mDx   = iround(dx)
  self.mDy   = iround(dy)
  self.mMinX = 0x7FFFFFFF
  self.mMinY = 0x7FFFFFFF
  self.mMaxX = -0x7FFFFFFF
  self.mMaxY = -0x7FFFFFFF

proc readInt32*[T](self: var SerializedScanlinesAdaptorAA[T]): int32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

proc readInt32u*[T](self: var SerializedScanlinesAdaptorAA[T]): uint32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

# Iterate scanlines interface
proc rewindScanlines*[T](self: var SerializedScanlinesAdaptorAA[T]): bool =
  self.mPtr = self.mData
  if self.mPtr < self.mEnd:
    self.mMinX = self.readInt32() + self.mDx
    self.mMinY = self.readInt32() + self.mDy
    self.mMaxX = self.readInt32() + self.mDx
    self.mMaxY = self.readInt32() + self.mDy
  result = self.mPtr < self.mEnd

proc minX*[T](self: SerializedScanlinesAdaptorAA[T]): int = self.mMinX
proc minY*[T](self: SerializedScanlinesAdaptorAA[T]): int = self.mMinY
proc maxX*[T](self: SerializedScanlinesAdaptorAA[T]): int = self.mMaxX
proc maxY*[T](self: SerializedScanlinesAdaptorAA[T]): int = self.mMaxY

proc sweepScanline*[T,Scanline](self: var SerializedScanlinesAdaptorAA[T], sl: var Scanline): bool =
  sl.resetSpans()
  while true:
    if self.mPtr >= self.mEnd: return false

    discard self.readInt32()      # Skip scanline size in bytes
    var
      y = self.readInt32() + self.mDy
      numSpans = self.readInt32()

    doWhile numSpans != 0:
      var
        x = self.readInt32() + self.mDx
        len = self.readInt32()

      if len < 0:
        sl.addSpan(x, -len, self.mPtr[])
        self.mPtr += sizeof(T)
      else:
        sl.addCells(x, len, self.mPtr)
        self.mPtr += len * sizeof(T)
      dec numSpans

    if sl.numSpans() != 0:
      sl.finalize(y)
      break

  result = true

# Specialization for embedded_scanline
proc sweepScanline*[T](self: var SerializedScanlinesAdaptorAA[T], sl: var EmbeddedScanlineAdaptorAA[T]): bool =
  doWhile sl.numSpans() == 0:
    if self.mPtr >= self.mEnd: return false

    var byteSize = self.readInt32u()
    sl.init(self.mPtr, self.mDx, self.mDy)
    self.mPtr += byteSize.int - sizeof(int32)

  result = true

type
  SerializedScanlinesAdaptorAA8*  = SerializedScanlinesAdaptorAA[uint8]
  SerializedScanlinesAdaptorAA16* = SerializedScanlinesAdaptorAA[uint16]
  SerializedScanlinesAdaptorAA32* = SerializedScanlinesAdaptorAA[uint32]

proc initSerializedScanlinesAdaptorAA8*(): SerializedScanlinesAdaptorAA8 =
  initSerializedScanlinesAdaptorAA[uint8]()

proc initSerializedScanlinesAdaptorAA16*(): SerializedScanlinesAdaptorAA16 =
  initSerializedScanlinesAdaptorAA[uint16]()

proc initSerializedScanlinesAdaptorAA32*(): SerializedScanlinesAdaptorAA32 =
  initSerializedScanlinesAdaptorAA[uint32]()
