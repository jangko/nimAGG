import agg_basics, agg_renderer_base, agg_dda_line, agg_ellipse_bresenham
import agg_rendering_buffer, agg_color_rgba

type
  RendererPrimitives*[BaseRenderer, ColorT] = object of RootObj
    mRen: ptr BaseRenderer
    mFillColor: ColorT
    mLineColor: ColorT
    currX: int
    currY: int

template getColorT*[B,C](x: typedesc[RendererPrimitives[B,C]]): typedesc = getColorT(B.type)

proc init*[B,C](self: var RendererPrimitives[B,C], ren: var B) =
  self.mRen = ren.addr
  self.mFillColor = noColor(C)
  self.mLineColor = noColor(C)
  self.currX = 0
  self.currY = 0

proc initRendererPrimitivesAux*[B,C](ren: var B): RendererPrimitives[B,C] =
  result.init(ren)

proc initRendererPrimitives*[B](ren: var B): auto =
  result = initRendererPrimitivesAux[B, getColorT(B)](ren)

proc attach*[B,C](self: var RendererPrimitives[B,C], ren: var B) =
  self.mRen = ren.addr

proc coord*[B,C](x: typedesc[RendererPrimitives[B,C]], c: float64): int =
  result = iround(c * SubpixelScale)

proc fillColor*[B,C,CT](self: var RendererPrimitives[B,C], c: CT) =
  when C isnot CT:
    self.mFillColor = construct(C, c)
  else:
    self.mFillColor = c

proc lineColor*[B,C,CT](self: var RendererPrimitives[B,C], c: CT) =
  when C isnot CT:
    self.mLineColor = construct(C, c)
  else:
    self.mLineColor = c

proc fillColor*[B,C](self: RendererPrimitives[B,C]): C = self.mFillColor
proc lineColor*[B,C](self: RendererPrimitives[B,C]): C = self.mLineColor

proc rectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  mixin blendHLine, blendVLine
  self.mRen[].blendHline(x1,   y1,   x2-1, self.mLineColor, coverFull)
  self.mRen[].blendVline(x2,   y1,   y2-1, self.mLineColor, coverFull)
  self.mRen[].blendHline(x1+1, y2,   x2,   self.mLineColor, coverFull)
  self.mRen[].blendVline(x1,   y1+1, y2,   self.mLineColor, coverFull)

proc solidRectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  mixin blendBar
  self.mRen[].blendBar(x1, y1, x2, y2, self.mFillColor, coverFull)

proc outlinedRectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  mixin blendBar
  self.rectangle(x1, y1, x2, y2)
  self.mRen[].blendBar(x1+1, y1+1, x2-1, y2-1, self.mFillColor, coverFull)

proc ellipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
  var
    ei = initEllipseBresenhamInterpolator(rx, ry)
    dx = 0
    dy = -ry

  doWhile dy < 0:
    dx += ei.dx()
    dy += ei.dy()
    self.mRen[].blendPixel(x + dx, y + dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x + dx, y - dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x - dx, y - dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x - dx, y + dy, self.mLineColor, coverFull)
    inc ei

proc solidEllipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
  mixin blendHLine
  var
    ei = initEllipseBresenhamInterpolator(rx, ry)
    dx = 0
    dy = -ry
    dy0 = dy
    dx0 = dx

  doWhile dy < 0:
    dx += ei.getDx()
    dy += ei.getDy()

    if dy != dy0:
      self.mRen[].blendHline(x-dx0, y+dy0, x+dx0, self.mFillColor, coverFull)
      self.mRen[].blendHline(x-dx0, y-dy0, x+dx0, self.mFillColor, coverFull)

    dx0 = dx
    dy0 = dy
    inc ei

  self.mRen[].blendHline(x-dx0, y+dy0, x+dx0, self.mFillColor, coverFull)

proc outlinedEllipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
  mixin blendPixel, blendHLine
  var
    ei = initEllipseBresenhamInterpolator(rx, ry)
    dx = 0
    dy = -ry

  doWhile dy < 0:
    dx += ei.getDx()
    dy += ei.getDy()

    self.mRen[].blendPixel(x + dx, y + dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x + dx, y - dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x - dx, y - dy, self.mLineColor, coverFull)
    self.mRen[].blendPixel(x - dx, y + dy, self.mLineColor, coverFull)

    if ei.getDy() != 0 and dx != 0:
      self.mRen[].blendHline(x-dx+1, y+dy, x+dx-1, self.mFillColor, coverFull)
      self.mRen[].blendHline(x-dx+1, y-dy, x+dx-1, self.mFillColor, coverFull)

    inc ei

proc line*[B,C](self: var RendererPrimitives[B,C], xx1, yy1, xx2, yy2: int, last = false) =
  mixin blendPixel
  var
    li = initLineBresenhamInterpolator(xx1, yy1, xx2, yy2)
    len = li.len()

  if len == 0:
    if last:
      self.mRen[].blendPixel(LineBresenhamInterpolator.lineLr(xx1),
        LineBresenhamInterpolator.lineLr(yy1), self.mLineColor, coverFull)
    return

  if last: inc len

  if li.isVer():
    doWhile len != 0:
      self.mRen[].blendPixel(li.x2(), li.y1(), self.mLineColor, coverFull)
      li.vstep()
      dec len
  else:
    doWhile len != 0:
      self.mRen[].blendPixel(li.x1(), li.y2(), self.mLineColor, coverFull)
      li.hstep()
      dec len

proc moveTo*[B,C](self: var RendererPrimitives[B,C], x, y: int) =
  self.currX = x
  self.currY = y

proc lineTo*[B,C](self: var RendererPrimitives[B,C], x, y: int, last = false) =
  self.line(self.currX, self.currY, x, y, last)
  self.currX = x
  self.currY = y

proc ren*[B,C](self: RendererPrimitives[B,C]): var B = self.mRen[]
proc rbuf*[B,C](self: RendererPrimitives[B,C]): var RenderingBuffer = self.mRen[].rbuf()
