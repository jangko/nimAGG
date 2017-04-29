import agg_basics

template podBVector(name: untyped, SS: int = 6) =
  type
    name*[T] = object
      mSize: int
      mNumBlocks: int
      mMaxBlocks: int
      mBlocks: seq[seq[T]]
      mBlockPtrInc: int
        
  template blockShift*[T](x: typedesc[name[T]]): int = SS
  template blockSize*[T](x: typedesc[name[T]]): int = 1 shl blockShift(x)
  template blockMask*[T](x: typedesc[name[T]]): int = blockSize(x) - 1
  template getValueT*[T](x: typedesc[name[T]]): typedesc = T
  
  proc `init name`*[T](): name[T] =
    result.mSize = 0
    result.mNumBlocks = 0
    result.mMaxBlocks = 0 
    result.mBlocks = nil
    result.mBlockPtrInc = blockSize(name[T])
  
  proc `init name`*[T](blockPtrInc: int): name[T] =
    result.mSize = 0
    result.mNumBlocks = 0
    result.mMaxBlocks = 0 
    result.mBlocks = nil
    result.mBlockPtrInc = blockPtrInc
  
  proc removeAll*[T](self: var name[T]) = 
    self.mSize = 0
    
  proc clear*[T](self: var name[T]) = 
    self.mSize = 0
    
  proc freeTail*[T](self: var name[T], size: int) =
    if size < self.mSize:
      let nb = (size + blockMask(name[T])) shr blockShift(name[T])
      while self.mNumBlocks > nb: dec self.mNumBlocks
      self.mBlocks.setLen(self.mNumBlocks)
      if self.mNumBlocks == 0:
        self.mBlocks = nil
        self.mMaxBlocks = 0
      self.mSize = size
    
  proc freeAll*[T](self: var name[T]) =
    self.freeTail(0)
    
  proc allocateBlock[T](self: var name[T], nb: int) =
    if nb >= self.mMaxBlocks:
      if self.mBlocks == nil:
        self.mBlocks = newSeq[seq[T]](self.mMaxBlocks + self.mBlockPtrInc)
      else:
        self.mBlocks.setLen(self.mMaxBlocks + self.mBlockPtrInc)
      self.mMaxBlocks += self.mBlockPtrInc
    self.mBlocks[nb] = newSeq[T](blockSize(name[T]))
    inc self.mNumBlocks
  
  proc dataPtr[T](self: var name[T]): ptr T {.inline.} =
    let nb = self.mSize shr blockShift(name[T])
    if nb >= self.mNumBlocks: self.allocateBlock(nb)
    self.mBlocks[nb][self.mSize and blockMask(name[T])].addr
    
  proc dataPtr[T](self: var name[T], idx: int): ptr T {.inline.} =
    self.mBlocks[idx shr blockShift(name[T])][idx and blockMask(name[T])] .addr
    
  proc add*[T](self: var name[T], val: T) =
    self.dataPtr()[] = val
    inc self.mSize
    
  proc pushBack*[T](self: var name[T], val: T)  = 
    self.add(val)
    
  proc removeLast*[T](self: var name[T]) =
    if self.mSize != 0: dec self.mSize
  
  proc modifyLast*[T](self: var name[T], val: T) =
    mixin removeLast
    self.removeLast()
    self.add(val)
    
  proc allocateContinuousBlock*[T](self: var name[T], numElements: int): int =
    if numElements < blockSize(name[T]):
      discard self.dataPtr() # Allocate initial block if necessary
      var 
        rest = blockSize(name[T]) - (self.mSize and blockMask(name[T]))
        index: int
        
      if numElements <= rest:
        # The rest of the block is good, we can use it
        index = self.mSize
        self.mSize += numElements
        return index
  
      # New block
      self.mSize += rest
      discard self.dataPtr()
      index = self.mSize
      self.mSize += numElements
      return index
    result = -1 # Impossible to allocate
    
  proc addArray*[T](self: var name[T], p: ptr T, numElem: int) =
    for i in 0.. <numElem:
      self.add(p[i])

  proc addArray*[T](self: var name[T], p: openArray[T]) =
    for x in p:
      self.add(x)
  
  proc addData*[T, DataAccessor](self: var name[T], data: var DataAccessor) =
    while data.size() != 0:
      self.add(data.get())
      inc data
      
  proc cutAt*[T](self: var name[T], size: int) =
    if size < self.mSize: self.mSize = size
  
  proc size*[T](self: var name[T]): int =
    self.mSize
  
  proc len*[T](self: var name[T]): int =
    self.mSize
    
  proc `[]=`*[T](self: var name[T], i: int, val: T) =
    self.mBlocks[i shr blockShift(name[T])][i and blockMask(name[T])] = val
    
  proc `[]`*[T](self: var name[T], i: int): T =    
    self.mBlocks[i shr blockShift(name[T])][i and blockMask(name[T])]
    
  proc at*[T](self: var name[T], i: int): T =
    self.mBlocks[i shr blockShift(name[T])][i and blockMask(name[T])] 
  
  proc valueAt*[T](self: var name[T], i: int): T =
    self.mBlocks[i shr blockShift(name[T])][i and blockMask(name[T])] 
  
  proc curr*[T](self: var name[T], idx: int): T =
    self.`[]`(idx)
  
  proc prev*[T](self: var name[T], idx: int): T =
    self.`[]`((idx + self.mSize - 1) mod self.mSize)
  
  proc next*[T](self: var name[T], idx: int): T =
    self.`[]`((idx + 1) mod self.mSize)
  
  proc last*[T](self: var name[T]): T =
    self.`[]`(self.mSize - 1)
    
  proc byteSize*[T](self: var name[T]): int =
    result = self.mSize * sizeof(T)
  
  proc serialize*[T](self: var name[T], p: ptr uint8) =
    var p = p
    for i in 0.. <self.mSize:
      copyMem(p, self.dataPtr(i), sizeof(T))
      inc(p, sizeof(T))
          
  proc deserialize*[T](self: var name[T], data: ptr uint8, byteSize: int) =
    self.removeAll()
    var 
      byteSize = byteSize div sizeof(T)
      data = data
    for i in 0.. <byteSize:
      var p = self.dataPtr()
      copyMem(p, data, sizeof(T))
      inc self.mSize
      inc(data, sizeof(T))
    
  proc deserialize*[T](self: var name[T], start: int, emptyVal: T,  data: ptr uint8, byteSize: int) =
    while self.mSize < start:
      self.add(emptyVal)
  
    var
      byteSize = byteSize div sizeof(T)
      data = data
      
    for i in 0.. <byteSize:
      if start + i < self.mSize:
        copyMem(self.dataPtr(start + i), data, sizeof(T))
      else:
        var p = self.dataPtr()
        copyMem(p, data, sizeof(T))
        inc self.mSize
      inc(data, sizeof(T))
    
  proc deserialize*[T, ByteAccessor](self: var name[T], data: ByteAccessor) =
    self.removeAll()
    let elemSize = data.size() div sizeof(T)
  
    for i in 0.. <elemSize:
      var p = cast[ptr uint8](self.dataPtr())
      for j in 0.. <sizeof(T):
        p[] = data.get()
        inc data
        inc p
      inc self.mSize
  
  proc deserialize*[T,ByteAccessor](self: var name[T], start: int, emptyVal: T, data: ByteAccessor) =
    while self.mSize < start:
      self.add(emptyVal)
    
    let elemSize = data.size() div sizeof(T)
    for i in 0.. <elemSize:
      var p: ptr uint8
      if start + i < self.mSize:
        p = cast[ptr uint8](self.dataPtr(start + i))
      else:
        p = cast[ptr uint8](self.dataPtr())
        inc self.mSize
      for j in 0.. <sizeof(T):
        p[] = data.get()
        inc data
        inc p
  
  proc getBlock*[T](self: var name[T], nb: int): ptr T =
    if self.mBlocks[nb] == nil: return nil
    self.mBlocks[nb][0].addr
  
podBVector(PodBVector)

template podAutoVector*(name: untyped, T: typed, Size: int) =
  type
    name* = object
      mArray: array[Size, T]
      mSize: int

  proc `init name`*(): name =
    result.mSize = 0

  proc removeAll*(self: var name) =
    self.mSize = 0

  proc clear*(self: var name) =
    self.mSize = 0

  proc add*(self: var name, v: T) =
    self.mArray[self.mSize] = v
    inc self.mSize

  proc incSize*(self: var name, size: int)  =
    self.mSize += size

  proc len*(self: name): int =
    self.mSize

  proc `[]`*(self: name, i: int): T =
    self.mArray[i]

  proc `[]`*(self: var name, i: int): var T =
    self.mArray[i]

  proc `[]=`*(self: var name, i: int, v: T) =
    self.mArray[i] = v


# Remove duplicates from a sorted array. It doesn't cut the
# tail of the array, it just returns the number of remaining elements.
proc removeDuplicates*[T, Equal](arr: var openArray[T], equal: Equal): int =
  if arr.len < 2: return arr.len

  var
    i = 1
    j = 1

  while i < arr.len:
    var e = arr[i]
    if not equal(e, arr[i - 1]):
      arr[j] = e
      inc j
    inc i

  result = j

type
  PodVector*[T] = object
    mSize: int
    mCapacity: int
    mArray: seq[T]

proc initPodVector*[T](): PodVector[T] =
  result.mSize = 0
  result.mCapacity = 0
  result.mArray = nil

proc initPodVector*[T](cap: int, extraTail = 0): PodVector[T] =
  result.mSize = 0
  result.mCapacity = cap + extraTail
  result.mArray = newSeq[T](result.mCapacity)

# Set new capacity. All data is lost, size is set to zero.
proc capacity*[T](self: var PodVector[T], cap: int, extraTail = 0) =
  self.mSize = 0
  if cap > self.mCapacity:
    self.mCapacity = cap + extraTail
    if self.mCapacity != 0:
      if self.mArray != nil: self.mArray.setLen(self.mCapacity)
      else: self.mArray = newSeq[T](self.mCapacity)

proc capacity*[T](self: PodVector[T]): int =
  self.mCapacity

# Allocate n elements. All data is lost,
# but elements can be accessed in range 0...size-1.
proc allocate*[T](self: var PodVector[T], size: int, extraTail = 0) =
  self.capacity(size, extraTail)
  self.mSize = size

# Resize keeping the content.
proc resize*[T](self: var PodVector[T], newSize: int) =
  if newSize > self.mSize:
    if newSize > self.mCapacity:
      self.mArray.setLen(self.mCapacity)
  else:
    self.mSize = newSize

proc zero*[T](self: var PodVector[T]) =
  zeroMem(self.mArray[0].addr, sizeof(T) * self.mSize)

proc add*[T](self: var PodVector[T], v: T) =
  self.mArray[self.mSize] = v
  inc self.mSize

proc pushBack*[T](self: var PodVector[T], v: T) =
  self.mArray[self.mSize] = v
  inc self.mSize

proc insertAt*[T](self: var PodVector[T], pos: int, val: T) =
  if pos >= self.mSize:
    self.mArray[self.mSize] = val
  else:
    moveMem(self.mArray[pos + 1].addr, self.mArray[pos].addr, (self.mSize - pos) * sizeof(T))
    self.mArray[pos] = val
  inc self.mSize

proc incCize*[T](self: var PodVector[T], size: int) =
  self.mSize += size

proc size*[T](self: PodVector[T]): int =
  self.mSize

proc byteSize*[T](self: PodVector[T]): int  =
  self.mSize * sizeof(T)

proc serialize*[T](self: var PodVector[T], p: ptr uint8) =
  if self.mSize != 0:
    copyMem(p, self.mArray, self.mSize * sizeof(T))

proc deserialize*[T](self: var PodVector[T], data: ptr uint8, byteSize: int) =
  let byteSize = byteSize div sizeof(T)
  self.allocate(byteSize)
  if byteSize != 0:
    copyMem(self.mArray[0].addr, data, byteSize * sizeof(T))
    
proc `[]=`*[T](self: var PodVector[T], i: int, v: T) =
  self.mArray[i] = v

proc `[]`*[T](self: var PodVector[T], i: int): var T =
  self.mArray[i]

proc at*[T](self: var PodVector[T], i: int): var T =
  self.mArray[i]

proc valueAt*[T](self: var PodVector[T], i: int): var T =
  self.mArray[i]

proc data*[T](self: var PodVector[T]): ptr T = self.mArray[0].addr

proc removeAll*[T](self: var PodVector[T]) =
  self.mSize = 0

proc clear*[T](self: var PodVector[T]) =
  self.mSize = 0

proc cutAt*[T](self: var PodVector[T], num: int) =
  if num < self.mSize:
    self.mSize = num
