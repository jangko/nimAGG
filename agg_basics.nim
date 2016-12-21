import math

template `+`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

template `+=`*[T](p: ptr T, off: int) =
  p = p + off

template inc*[T](p: ptr T) =
  p = p + 1

template inc*[T](p: ptr T, off: int) =
  p = p + off

template `-`*[T](p: ptr T, off: int): ptr T =
  cast[ptr type(p[])](cast[ByteAddress](p) -% off * sizeof(p[]))

template `-=`*[T](p: ptr T, off: int) =
  p = p - off

template `[]`*[T](p: ptr T, off: int): T =
  (p + off)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

template doWhile*(a: typed, b: typed) =
  while true:
    b
    if not a:
      break

type
  const_row_info*[T] = object
    x1, x2: int
    data: ptr T
        
proc uround*(x: float64): int {.inline.} =
  result = math.round(x).int