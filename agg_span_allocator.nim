import agg_basics

type
  SpanAllocator*[ColorT] = object
    mSpan: seq[ColorT]
  

proc initSpanAllocator*[ColorT](): SpanAllocator[ColorT] =
  result.mSpan = @[]
  
proc allocate*[ColorT](self: var SpanAllocator, len: int): ptr ColorT =
  if len > self.mSpan.len:
    # To reduce the number of reallocs we align the 
    # span_len to 256 color elements. 
    # Well, I just like this number and it looks reasonable.
    self.mSpan.resize(((len + 255) shr 8) shl 8)
    
  result = self.mSpan[0].addr

proc span*[ColorT](self: var SpanAllocator): ptr ColorT {.inline.} = self.mSpan[0].addr
proc maxSpanLen*[ColorT](self: var SpanAllocator): int {.inline.} = self.mSpan.len
