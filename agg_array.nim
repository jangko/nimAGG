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