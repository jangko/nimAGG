import agg_basics

template vertexBlockStorage*(name: untyped, BlockShift: int = 8, BlockPool: int = 256) =
  type
    name*[T] = object
      mTotalVertices: int
      mTotalBlocks: int
      mMaxBlocks: int
      mBlocks: seq[seq[T]]

  template blockShift*[T](x: typedesc[name[T]]): int = BlockShift
  template blockSize*[T](x: typedesc[name[T]]): int = (1 shl BlockShift)
  template blockMask*[T](x: typedesc[name[T]]): int = (blockSize(x) - 1)
  template blockPool*[T](x: typedesc[name[T]]): int = BlockPool
  template construct*[T](x: typedesc[name[T]]): untyped = callTemplate(name)[T]()

  proc `init name`*[T](): name[T] =
    result.mTotalVertices = 0
    result.mTotalBlocks = 0
    result.mMaxBlocks = 0
    result.mBlocks = nil

  proc allocateBlock*[T](self: var name[T], nb: int) =
    if self.mBlocks == nil: self.mBlocks = newSeq[seq[T]](BlockPool)
    if nb >= self.mMaxBlocks:
      self.mBlocks.setLen(self.mMaxBlocks + BlockPool)
      inc(self.mMaxBlocks, BlockPool)

    if self.mBlocks[nb] == nil: self.mBlocks[nb] = newSeq[T](blockSize(name[T]))
    inc self.mTotalBlocks

  proc storagePtr*[T](self: var name[T]): ptr T =
    let nb = self.mTotalVertices shr blockShift(name[T])
    if nb >= self.mTotalBlocks:
      self.allocateBlock(nb)

    addr(self.mBlocks[nb][self.mTotalVertices and blockMask(name[T])])

  proc freeAll*[T](self: var name[T]) =
    if self.mTotalBlocks != 0:
      self.mTotalBlocks   = 0
      self.mMaxBlocks     = 0
      self.mTotalVertices = 0

  proc removeAll*[T](self: var name[T]) {.inline.} =
    self.mTotalVertices = 0

  proc addVertex*[T](self: var name[T], x, y: float64, cmd: uint) {.inline.} =
    type ValueT = getValueT(T)
    var pv = self.storagePtr()
    pv.x = ValueT(x)
    pv.y = ValueT(y)
    pv.cmd = uint8(cmd)
    inc self.mTotalVertices

  proc modifyVertex*[T](self: var name[T], idx: int, x, y: float64) {.inline.} =
    type ValueT = getValueT(T)
    var pv = addr(self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])])
    pv.x = ValueT(x)
    pv.y = ValueT(y)

  proc modifyVertex*[T](self: var name[T], idx: int, x, y: float64, cmd: uint) {.inline.} =
    type ValueT = getValueT(T)
    var pv = addr(self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])])
    pv.x = ValueT(x)
    pv.y = ValueT(y)
    pv.cmd = uint8(cmd)

  proc modifyCommand*[T](self: var name[T], idx: int, cmd: uint) {.inline.} =
    self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])].cmd = uint8(cmd)

  proc swapVertices*[T](self: var name[T], a, b: int) {.inline.} =
    var pa = addr(self.mBlocks[a shr blockShift(name[T])][a and blockMask(name[T])])
    var pb = addr(self.mBlocks[b shr blockShift(name[T])][b and blockMask(name[T])])
    swap(pa.x, pb.x)
    swap(pa.y, pb.y)
    swap(pa.cmd, pb.cmd)

  proc command*[T](self: name[T], idx: int): uint {.inline.} =
    self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])].cmd

  proc vertex*[T](self: name[T], idx: int, x,y: var float64): uint {.inline.} =
    var pv = unsafeAddr(self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])])
    x = float64(pv.x)
    y = float64(pv.y)
    result = pv.cmd

  proc lastCommand*[T](self: name[T]): uint {.inline.} =
    if self.mTotalVertices != 0:
      return self.command(self.mTotalVertices - 1)
    result = pathCmdStop

  proc lastVertex*[T](self: name[T], x,y: var float64): uint {.inline.} =
    if self.mTotalVertices != 0:
      return self.vertex(self.mTotalVertices - 1, x, y)
    result = pathCmdStop

  proc prevVertex*[T](self: name[T], x,y: var float64): uint {.inline.} =
    if self.mTotalVertices > 1:
      return self.vertex(self.mTotalVertices - 2, x, y)
    result = pathCmdStop

  proc lastX*[T](self: name[T]): float64 {.inline.} =
    if self.mTotalVertices != 0:
      let idx = self.mTotalVertices - 1
      return self.mCoordBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])].x
    result = 0.0

  proc lastY*[T](self: name[T]): float64 {.inline.} =
    if self.mTotalVertices != 0:
      let idx = self.mTotalVertices - 1
      return self.mCoordBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])].y
    result = 0.0

  proc totalVertices*[T](self: name[T]): int {.inline.} =
    self.mTotalVertices
