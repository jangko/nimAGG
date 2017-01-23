import agg_basics, agg_color_rgba, agg_pixfmt_rgb

type
  SpanPatternRgba*[Source] = object
    mSrc: ptr Source
    mOffsetX: int
    mOffsetY: int
    
    
proc initSpanPatternRgba*[Source](src: var Source, offsetX, offsetY: int): SpanPatternRgba[Source] =
  result.mSrc = src.addr
  result.mOffsetX = offsetX
  result.mOffsetY = offsetY
    
proc attach*[Source](self: var SpanPatternRgba[Source], v: var Source) = self.mSrc = v.addr
proc source*[Source](self: SpanPatternRgba[Source]): var Source = self.mSrc[]

proc offsetX*[Source](self: var SpanPatternRgba[Source], v: int) = self.mOffsetX = v
proc offsetY*[Source](self: var SpanPatternRgba[Source], v: int) = self.mOffsetY = v
proc offsetX*[Source](self: SpanPatternRgba[Source]): int = self.mOffsetX
proc offsetY*[Source](self: SpanPatternRgba[Source]): int = self.mOffsetY
proc alpha*[Source,A](self: var SpanPatternRgba[Source], v: A) = discard
proc alpha*[Source,A](self: SpanPatternRgba[Source]): A = 0

proc prepare*[Source](self: SpanPatternRgba[Source]) = discard
proc generate*[Source, ColorT](self: var SpanPatternRgba[Source], span: ptr ColorT, x, y, len: int) =
  type
    OrderType = getOrderType(Source)
    ValueType = getValueType(getColorType(Source))
  var
    x = x
    y = y
    len = len
    
  x += self.mOffsetX
  y += self.mOffsetY
  var p = cast[ptr ValueType](self.mSrc[].span(x, y, len))
  doWhile len != 0:
    span.r = p[OrderType.R]
    span.g = p[OrderType.G]
    span.b = p[OrderType.B]
    span.a = p[OrderType.A]
    p = cast[ptr ValueType](self.mSrc[].nextX())
    inc span
    dec len