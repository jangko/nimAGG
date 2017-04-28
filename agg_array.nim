type
  PodBVector*[T] = object
    data: seq[T]

proc initPodBVector*[T](): PodBVector[T] =
  result.data = @[]

proc add*[T](self: var PodBVector[T], val: T) {.inline.} =
  self.data.add(val)

proc removeAll*[T](self: var PodBVector[T]) {.inline.} =
  self.data.setLen(0)

proc len*[T](self: PodBVector[T]): int {.inline.} = self.data.len

proc `[]`*[T](self: var PodBVector[T], idx: int): var T = self.data[idx]

proc `[]=`*[T](self: var PodBVector[T], idx: int, v: T) = 
  self.data[idx] = v

template getValueT*[T](x: typedesc[PodBVector[T]]): typedesc = T


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
