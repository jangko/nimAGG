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
