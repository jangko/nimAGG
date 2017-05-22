import basics

type
  SpanSolid*[ColorT] = object
    mColor: ColorT

proc color*[ColorT](self: var SpanSolid, c: ColorT) = self.mColor = c
proc color*[ColorT](self: var SpanSolid): ColorT = self.mColor

proc prepare*[ColorT](self: var SpanSolid) = discard

proc generate*[ColorT](self: var SpanSolid, span: ptr ColorT, x, y, len: int) =
  var len = len
  doWhile len != 0:
    span[] = self.mColor
    inc self
    dec len


