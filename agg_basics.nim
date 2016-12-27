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

template `[]`*[O: enum; T](p: ptr T, off: O): T =
  (p + off.ord)[]

template `[]=`*[T](p: ptr T, off: int, val: T) =
  (p + off)[] = val

template `[]=`*[O: enum; T](p: ptr T, off: O, val: T) =
  (p + off.ord)[] = val

template doWhile*(a: typed, b: typed) =
  while true:
    b
    if not a:
      break

type
  RowInfo*[T] = object
    x1*, x2*: int
    data*: ptr T
        
proc uround*(x: float64): int {.inline.} =
  result = math.round(x).int
  
const
  coverShift* = 8                  #----cover_shift
  coverSize*  = 1 shl cover_shift  #----cover_size 
  coverMask*  = cover_size - 1     #----cover_mask 
  coverNone*  = 0                  #----cover_none 
  coverFull*  = cover_mask         #----cover_full 