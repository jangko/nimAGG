import agg_basics

type
  SpanDataBin* = object
    x, len: int32

  ScanlineDataBin* = object
    y: int
    numSpans: int
    startSpan: int

  ScanlineStorageBin* = object
    mSpans: seq[SpanDataBin]
    mScanlines: seq[ScanlineDataBin]
    mFakeSpan: SpanDataBin
    mFakeScanline: ScanlineDataBin
    mMinX, mMinY, mMaxX, mMaxY: int
    mCurScanline: int

  EmbeddedScanlineBin* = object
    mStorage: ptr ScanlineStorageBin
    mScanline: ScanlineDataBin
    mScanlineIdx: int

proc initScanlineStorageBin*(): ScanlineStorageBin =
  result.mSpans = newSeqOfCap[SpanDatabin](256)
  result.mScanlines = @[]
  result.mMinX = 0x7FFFFFFF
  result.mMinY = 0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF
  result.mCurScanline = 0

  result.mFakeScanline.y = 0
  result.mFakeScanline.numSpans = 0
  result.mFakeScanline.startSpan = 0
  result.mFakeSpan.x = 0
  result.mFakeSpan.len = 0

# Renderer Interface
proc prepare*(self: var ScanlineStorageBin) =
  self.mScanlines.setLen(0)
  self.mSpans.setLen(0)
  self.mMinX =  0x7FFFFFFF
  self.mMinY =  0x7FFFFFFF
  self.mMaxX = -0x7FFFFFFF
  self.mMaxY = -0x7FFFFFFF
  self.mCurScanline = 0

proc render*[Scanline](self: var ScanlineStorageBin, sl: var Scanline) =
  var
    y = sl.getY()
    slThis: ScanlineDataBin

  if y < self.mMinY: self.mMinY = y
  if y > self.mMaxY: self.mMaxY = y

  slThis.y = y
  slThis.numSpans = sl.numSpans()
  slThis.startSpan = self.mSpans.len

  var
    span = sl.begin()
    numSpans = slThis.numSpans

  while true:
    var sp: SpanDataBin
    sp.x   = span.x
    sp.len = abs(span.len)
    self.mSpans.add(sp)
    var
      x1 = sp.x
      x2 = sp.x + sp.len - 1

    if x1 < self.mMinX: self.mMinX = x1
    if x2 > self.mMaxX: self.mMaxX = x2
    dec numSpans
    if numSpans == 0: break
    inc span

  self.mScanlines.add(slThis)

# Iterate scanlines interface
proc minX*(self: ScanlineStorageBin): int = self.mMinX
proc minY*(self: ScanlineStorageBin): int = self.mMinY
proc maxX*(self: ScanlineStorageBin): int = self.mMaxX
proc maxY*(self: ScanlineStorageBin): int = self.mMaxY

proc rewindScanlines*(self: var ScanlineStorageBin): bool =
  self.mCurScanline = 0
  result = self.mScanlines.len > 0

proc sweepScanline*[Scanline](self: var ScanlineStorageBin, sl: var Scanline): bool =
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
      inc spanIdx
      sl.addSpan(sp.x, sp.len, coverFull)
      dec numSpans

    inc self.mCurScanline
    if sl.numSpans() != 0:
      sl.finalize(slThis.y)
      break

  result = true

proc numSpans*(self: var EmbeddedScanlineBin): int
proc setup(self: var EmbeddedScanlineBin, scanlineIdx: int)

# Specialization for embedded_scanline
proc sweepScanline*(self: var ScanlineStorageBin, sl: var EmbeddedScanlineBin): bool =
  doWhile sl.numSpans() == 0:
    if self.mCurScanline >= self.mScanlines.len: return false
    sl.setup(self.mCurScanline)
    inc self.mCurScanline

  result = true

proc byteSize*(self: var ScanlineStorageBin): int =
  var size = sizeof(int32) * 4 # minX, minY, maxX, maxY
  for i in 0.. <self.mScanlines.len:
    size += sizeof(int32) * 2 + # Y, numSpans
            self.mScanlines[i].numSpans * sizeof(int32) * 2 # X, span_len

  result = size

proc writeInt32(dst: ptr uint8, val: int32) =
  var val = val
  dst[0] = cast[ptr uint8](val.addr)[0]
  dst[1] = cast[ptr uint8](val.addr)[1]
  dst[2] = cast[ptr uint8](val.addr)[2]
  dst[3] = cast[ptr uint8](val.addr)[3]

proc serialize*(self: var ScanlineStorageBin, data: ptr uint8) =
  var data = data

  writeInt32(data, self.minX().int32) # minX
  data += sizeof(int32)
  writeInt32(data, self.minY().int32) # minY
  data += sizeof(int32)
  writeInt32(data, self.maxX().int32) # maxX
  data += sizeof(int32)
  writeInt32(data, self.maxY().int32) # maxY
  data += sizeof(int32)

  for i in 0.. <self.mScanlines.len:
    var slThis = self.mScanlines[i].addr

    writeInt32(data, slThis.y.int32)      # Y
    data += sizeof(int32)

    writeInt32(data, slThis.numSpans.int32)    # numSpans
    data += sizeof(int32)

    var
      numSpans = slThis.numSpans
      spanIdx  = slThis.startSpan

    doWhile numSpans != 0:
      var sp = self.mSpans[spanIdx].addr
      inc spanIdx
      writeInt32(data, sp.x.int32)    # X
      data += sizeof(int32)
      writeInt32(data, sp.len.int32)  # len
      data += sizeof(int32)
      dec numSpans

proc scanlineByIndex*(self: ScanlineStorageBin, i: int): ScanlineDataBin =
  result = if i < self.mScanlines.len: self.mScanlines[i] else: self.mFakeScanline

proc spanByIndex*(self: ScanlineStorageBin, i: int): SpanDataBin =
  result = if i < self.mSpans.len: self.mSpans[i] else: self.mFakeSpan

type
  ConstIteratorBin* = object
    mStorage: ptr ScanlineStorageBin
    mSpanIdx: int
    mSpan: SpanDatabin

proc initConstIteratorBin*(sl: var EmbeddedScanlineBin): ConstIteratorBin =
  result.mStorage = sl.mStorage
  result.mSpanIdx = sl.mScanline.startSpan
  result.mSpan    = result.mStorage[].spanByIndex(result.mSpanIdx)

proc inc*(self: var ConstIteratorBin) {.inline.} =
  inc self.mSpanIdx
  self.mSpan = self.mStorage[].spanByIndex(self.mSpanIdx)

proc x*(self: ConstIteratorBin): int {.inline.} =
  self.mSpan.x

proc len*(self: ConstIteratorBin): int {.inline.} =
  self.mSpan.len

proc initEmbeddedScanlineBin*(storage: var ScanlineStorageBin): EmbeddedScanlineBin =
  result.mStorage = storage.addr
  result.setup(0)

proc setup(self: var EmbeddedScanlineBin, scanlineIdx: int) =
  self.mScanlineIdx = scanlineIdx
  self.mScanline = self.mStorage[].scanlineByIndex(self.mScanlineIdx)

proc reset*(self: var EmbeddedScanlineBin, maxX, maxY: int) =
  discard

proc numSpans(self: var EmbeddedScanlineBin): int =
  self.mScanline.numSpans

proc getY*(self: var EmbeddedScanlineBin): int =
  self.mScanline.y

proc begin*(self: var EmbeddedScanlineBin): ConstIteratorBin =
  initConstIteratorBin(self)

type
  SerializedScanlinesAdaptorBin* = object
    mData: ptr uint8
    mEnd: ptr uint8
    mPtr: ptr uint8
    mDx, mDy: int
    mMinX, mMinY: int
    mMaxX, mMaxY: int

  EmbeddedScanlineAdaptorBin* = object
    mPtr: ptr uint8
    mY: int
    mNumSpans: int
    mDx: int

type
  span32 = object
    x: int32
    len: int32

  ConstIteratorAdaptorBin* = object
    mPtr: ptr uint8
    mSpan: span32
    mDx: int

proc readInt32(self: var ConstIteratorAdaptorBin): int32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

proc initConstIteratorAdaptorBin(sl: var EmbeddedScanlineAdaptorBin): ConstIteratorAdaptorBin =
  result.mPtr = sl.mPtr
  result.mDx  = sl.mDx
  result.mSpan.x   = result.readInt32() + result.mDx.int32
  result.mSpan.len = result.readInt32()

proc inc*(self: var ConstIteratorAdaptorBin) =
  self.mSpan.x   = self.readInt32() + self.mDx.int32
  self.mSpan.len = self.readInt32()
  
proc x*(self: ConstIteratorAdaptorBin): int {.inline.} =
  self.mSpan.x

proc len*(self: ConstIteratorAdaptorBin): int {.inline.} =
  self.mSpan.len
  
proc initEmbeddedScanlineAdaptorBin*(): EmbeddedScanlineAdaptorBin =
  result.mPtr = nil
  result.mY = 0
  result.mNumSpans = 0

proc reset*(self: var EmbeddedScanlineAdaptorBin, maxX, maxY: int) =
  discard

proc numSpans*(self: EmbeddedScanlineAdaptorBin): int =
  self.mNumSpans

proc getY*(self: EmbeddedScanlineAdaptorBin): int =
  self.mY

proc begin*(self: var EmbeddedScanlineAdaptorBin): ConstIteratorAdaptorBin =
  initConstIteratorAdaptorBin(self)

proc readInt32*(self: var EmbeddedScanlineAdaptorBin): int32 =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

proc init*(self: var EmbeddedScanlineAdaptorBin, p: ptr uint8, dx, dy: int) =
  self.mPtr      = p
  self.mY        = self.readInt32() + dy
  self.mNumSpans = self.readInt32()
  self.mDx       = dx

proc initSerializedScanlinesAdaptorBin*(): SerializedScanlinesAdaptorBin =
  result.mData = nil
  result.mEnd = nil
  result.mPtr = nil
  result.mDx = 0
  result.mDy = 0
  result.mMinX = 0x7FFFFFFF
  result.mMinY = 0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF

proc initSerializedScanlinesAdaptorBin*(data: ptr uint8,
  size: int, dx, dy: float64): SerializedScanlinesAdaptorBin =
  result.mData = data
  result.mEnd  = data + size
  result.mPtr  = data
  result.mDx = iround(dx)
  result.mDy = iround(dy)
  result.mMinX = 0x7FFFFFFF
  result.mMinY = 0x7FFFFFFF
  result.mMaxX = -0x7FFFFFFF
  result.mMaxY = -0x7FFFFFFF

proc init*(self: var SerializedScanlinesAdaptorBin, data: ptr uint8,
  size: int, dx, dy: float64) =
  self.mData  = data
  self.mEnd   = data + size
  self.mPtr   = data
  self.mDx    = iround(dx)
  self.mDy    = iround(dy)
  self.mMinX = 0x7FFFFFFF
  self.mMinY = 0x7FFFFFFF
  self.mMaxX = -0x7FFFFFFF
  self.mMaxY = -0x7FFFFFFF

proc readInt32(self: var SerializedScanlinesAdaptorBin): int =
  cast[ptr uint8](result.addr)[0] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[1] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[2] = self.mPtr[]; inc self.mPtr
  cast[ptr uint8](result.addr)[3] = self.mPtr[]; inc self.mPtr

# Iterate scanlines interface
proc rewindScanlines*(self: var SerializedScanlinesAdaptorBin): bool =
  self.mPtr = self.mData
  if self.mPtr < self.mEnd:
    self.mMinX = self.readInt32() + self.mDx
    self.mMinY = self.readInt32() + self.mDy
    self.mMaxX = self.readInt32() + self.mDx
    self.mMaxY = self.readInt32() + self.mDy
  result = self.mPtr < self.mEnd

proc minX*(self: SerializedScanlinesAdaptorBin): int = self.mMinX
proc minY*(self: SerializedScanlinesAdaptorBin): int = self.mMinY
proc maxX*(self: SerializedScanlinesAdaptorBin): int = self.mMaxX
proc maxY*(self: SerializedScanlinesAdaptorBin): int = self.mMaxY

proc sweepScanline*[Scanline](self: var SerializedScanlinesAdaptorBin, sl: var Scanline): bool =
  sl.resetSpans()
  while true:
    if self.mPtr >= self.mEnd: return false

    var
      y = self.readInt32() + self.mDy
      numSpans = self.readInt32()

    doWhile numSpans != 0:
      var
        x   = self.readInt32() + self.mDx
        len = self.readInt32()

      if len < 0: len = -len
      sl.addSpan(x, len, coverFull)
      dec numSpans

    if sl.numSpans() != 0:
      sl.finalize(y)
      break

  result = true

# Specialization for embedded_scanline
proc sweepScanline*(self: var SerializedScanlinesAdaptorBin, sl: var EmbeddedScanlineAdaptorBin): bool =
  doWhile sl.numSpans() == 0:
    if self.mPtr >= self.mEnd: return false

    sl.init(self.mPtr, self.mDx, self.mDy)

    # Jump to the next scanline
    discard self.readInt32()            # Y
    var numSpans = self.readInt32()     # numSpans
    self.mPtr += numSpans * sizeof(int32) * 2

  result = true
