import basics, color_rgba, pixfmt_rgb

type
  SpanPatternRgb*[Source, AType] = object
    mSrc: ptr Source
    mOffsetX, mOffsetY: int
    mAlpha: AType

proc init[Source,AType](src: var Source, offsetX, offsetY: int): SpanPatternRgb[Source, AType] =
  const baseMask = getBaseMask(getColorT(Source))
  result.mSrc = src.addr
  result.mOffsetX = offsetX
  result.mOffsetY = offsetY
  result.mAlpha = baseMask

proc initSpanPatternRgb*[Source](src: var Source, offsetX, offsetY: int): auto =
  result = init[Source, getValueT(getColorT(Source))](src, offsetX, offsetY)

proc attach*[S,A](self: var SpanPatternRgb[S,A], v: var S) = self.mSrc = v.addr
proc source*[S,A](self: SpanPatternRgb[S,A]): var S = self.mSrc[]

proc offsetX*[S,A](self: var SpanPatternRgb[S,A], v: int) = self.mOffsetX = v
proc offsetY*[S,A](self: var SpanPatternRgb[S,A], v: int) = self.mOffsetY = v
proc offsetX*[S,A](self: SpanPatternRgb[S,A]): int = self.mOffsetX
proc offsetY*[S,A](self: SpanPatternRgb[S,A]): int = self.mOffsetY
proc alpha*[S,A,B](self: var SpanPatternRgb[S,A], v: B) =
  when A is not B:
    self.mAlpha = A(v)
  else:
    self.mAlpha = v

proc alpha*[S,A](self: SpanPatternRgb[S,A]): A = self.mAlpha

proc prepare*[S,A](self: SpanPatternRgb[S,A],) = discard
proc generate*[S,A, ColorT](self: var SpanPatternRgb[S,A], span: ColorT, x, y, len: int) =
  type
    OrderT = getOrderT(S)
  var
    x = x
    y = y
    len = len
    span = span

  x += self.mOffsetX
  y += self.mOffsetY
  var p = cast[ptr A](self.mSrc[].span(x, y, len))

  doWhile len != 0:
    span.r = p[OrderT.R]
    span.g = p[OrderT.G]
    span.b = p[OrderT.B]
    span.a = self.mAlpha
    p = cast[ptr A](self.mSrc[].nextX())
    inc span
    dec len
