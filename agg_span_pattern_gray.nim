import agg_basics, agg_color_gray, agg_pixfmt_rgb

type
  SpanPatternGray*[Source, AType] = object
    mSrc: ptr Source
    mOffsetX, mOffsetY: int
    mAlpha: AType
    
proc init[Source, AType](src: var Source, offsetX, offsetY: int): SpanPatternGray[Source, AType] =
  const baseMask = getBaseMask(getColorType(Source))
  result.mSrc = src.addr
  result.mOffsetX = offsetX
  result.mOffsetY = offsetY
  result.mAlpha = baseMask

proc initSpanPatternGray*[Source](src: var Source, offsetX, offsetY: int): auto =
  result = init[Source, getValueType(getColorType(Source))](src, offsetX, offsetY)

proc attach*[S,A](self: var SpanPatternGray[S,A], v: var S) = 
  self.mSrc = v.addr
  
proc source*[S,A](self: SpanPatternGray[S,A]): var S = self.mSrc[]

proc offsetX*[S,A](self: var SpanPatternGray[S,A], v: int) = self.mOffsetX = v
proc offsetY*[S,A](self: var SpanPatternGray[S,A], v: int) = self.mOffsetY = v
proc offsetX*[S,A](self: SpanPatternGray[S,A]): int = self.mOffsetX
proc offsetY*[S,A](self: SpanPatternGray[S,A]): int = self.mOffsetY
proc alpha*[S,A](self: var SpanPatternGray[S,A], v: A) = self.mAlpha = v
proc alpha*[S,A](self: SpanPatternGray[S,A]): A = self.mAlpha

proc prepare*[S,A](self: SpanPatternGray[S,A]) = discard
proc generate*[S,A, ColorT](self: var SpanPatternGray[S,A], span: ColorT, x, y, len: int) =
  var 
    x = x
    y = y
    len = len
    
  x += self.mOffsetX
  y += self.mOffsetY
  var p = cast[ptr A](self.mSrc[].span(x, y, len))
  doWhile len != 0:
    span.v = p[]
    span.a = self.mAlpha
    p = cast[ptr A](self.mSrc[].nextX())
    inc span
    dec len






