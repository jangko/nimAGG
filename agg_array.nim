type
  PodBVector*[T] = object
    data: seq[T]

proc initPodBVector*[T](): PodBVector[T] =
  result.data = @[]

proc add*[T](self: var PodBVector[T], val: T) {.inline.} =
  self.data.add(val)

proc removeAll*[T](self: var PodBVector[T]) {.inline.} =
  self.data.setLen(0)

proc size*[T](self: PodBVector[T]): int {.inline.} = self.data.len

proc `[]`*[T](self: var PodBVector[T], idx: int): var T = self.data[idx]

template getValueType*[T](x: typedesc[PodBVector[T]]): typedesc = T

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
