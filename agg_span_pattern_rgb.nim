import agg_basics, agg_color_rgba, agg_pixfmt_rgb

type
  SpanPatternRgb*[Source, AType] = object
    mSrc: ptr Source
    mOffsetX, mOffsetY: int
    mAlpha: AType

proc init[Source,AType](src: var Source, offsetX, offsetY: int): SpanPatternRgb[Source, AType] =
  const baseMask = getBaseMask(getColorType(Source))
  result.mSrc = src.addr
  result.mOffsetX = offsetX
  result.mOffsetY = offsetY
  result.mAlpha = baseMask

proc initSpanPatternRgb*[Source](src: var Source, offsetX, offsetY: int): auto =
  result = init[Source, getValueType(getColorType(Source))](src, offsetX, offsetY)

proc attach*[S,A](self: var SpanPatternRgb[S,A], v: var S) = self.mSrc = v.addr
proc source*[S,A](self: SpanPatternRgb[S,A]): var S = self.mSrc[]

proc offsetX*[S,A](self: var SpanPatternRgb[S,A], v: int) = self.mOffsetX = v
proc offsetY*[S,A](self: var SpanPatternRgb[S,A], v: int) = self.mOffsetY = v
proc offsetX*[S,A](self: SpanPatternRgb[S,A],): int = self.mOffsetX
proc offsetY*[S,A](self: SpanPatternRgb[S,A],): int = self.mOffsetY
proc alpha*[S,A](self: var SpanPatternRgb[S,A], v: A) = self.mAlpha = v
proc alpha*[S,A](self: SpanPatternRgb[S,A]): A = self.mAlpha

proc prepare*[S,A](self: SpanPatternRgb[S,A],) = discard
proc generate*[S,A, ColorT](self: var SpanPatternRgb[S,A], span: ColorT, x, y, len: int) =
  type
    OrderType = getOrderType(S)
  var
    x = x
    y = y
    len = len

  x += self.mOffsetX
  y += self.mOffsetY
  var p = cast[ptr A](self.mSrc[].span(x, y, len))

  doWhile len != 0:
    span.r = p[OrderType.R]
    span.g = p[OrderType.G]
    span.b = p[OrderType.B]
    span.a = self.mAlpha
    p = cast[ptr A](self.mSrc[].nextX())
    inc span
    dec len







