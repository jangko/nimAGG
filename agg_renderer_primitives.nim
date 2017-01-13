import agg_basics, agg_renderer_base, agg_dda_line, agg_ellipse_bresenham, agg_color_rgba

type
  RendererPrimitives*[BaseRenderer, ColorT] = object
    ren: ptr BaseRenderer
    mFillColor: ColorT
    mLineColor: ColorT
    currX: int
    currT: int

template getColorType*[B,C](x: typedesc[RendererPrimitives[B,C]]): typedesc = getColorType(B.type)

proc initRendererPrimitives1*[B,C](ren: var B): RendererPrimitives[B,C] =
  result.ren = ren.addr
  result.mFillColor = noColor(C)
  result.mLineColor = noColor(C)
  result.currX = 0
  result.currY = 0

proc initRendererPrimitives*[B](ren: var B): auto =
  result = initRendererPrimitives1[B, getColorType(B)](ren)

proc attach*[B,C](self: var RendererPrimitives[B,C], ren: var B) =
  self.ren = ren.addr

proc coord*[B,C](x: typedesc[RendererPrimitives[B,C]], c: float64): int =
  result = iround(c * SubpixelScale)

proc fillColor*[B,C](self: var RendererPrimitives[B,C], c: C) = self.mFillColor = c
proc lineColor*[B,C](self: var RendererPrimitives[B,C], c: C) = self.mLineColor = c
proc fillColor*[B,C](self: RendererPrimitives[B,C]): var C = self.mFillColor
proc lineColor*[B,C](self: RendererPrimitives[B,C]): var C = self.mLineColor

proc rectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  self.ren[].blendHline(x1,   y1,   x2-1, self.mLineColor, coverFull)
  self.ren[].blendVline(x2,   y1,   y2-1, self.mLineColor, coverFull)
  self.ren[].blendHline(x1+1, y2,   x2,   self.mLineColor, coverFull)
  self.ren[].blendVline(x1,   y1+1, y2,   self.mLineColor, coverFull)

proc solid_rectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  self.ren[].blendBar(x1, y1, x2, y2, self.mFillColor, coverFull)

proc outlined_rectangle*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int) =
  rectangle(x1, y1, x2, y2)
  self.ren[].blendBar(x1+1, y1+1, x2-1, y2-1, self.mFillColor, coverFull)


proc ellipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
  var
    ei = initEllipseBresenhamInterpolator(rx, ry)
    dx = 0
    dy = -ry

  doWhile dy < 0:
    dx += ei.dx()
    dy += ei.dy()
    self.ren[].blendPixel(x + dx, y + dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x + dx, y - dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x - dx, y - dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x - dx, y + dy, self.mLineColor, coverFull)
    inc ei

proc solidEllipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
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
      self.ren[].blendHline(x-dx0, y+dy0, x+dx0, self.mFillColor, coverFull)
      self.ren[].blendHline(x-dx0, y-dy0, x+dx0, self.mFillColor, coverFull)

    dx0 = dx
    dy0 = dy
    inc ei

  self.ren[].blendHline(x-dx0, y+dy0, x+dx0, self.mFillColor, coverFull)

proc outlined_ellipse*[B,C](self: var RendererPrimitives[B,C], x, y, rx, ry: int) =
  var
    ei = initEllipseBresenhamInterpolator(rx, ry)
    dx = 0
    dy = -ry

  doWhile dy < 0:
    dx += ei.getDx()
    dy += ei.getDy()

    self.ren[].blendPixel(x + dx, y + dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x + dx, y - dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x - dx, y - dy, self.mLineColor, coverFull)
    self.ren[].blendPixel(x - dx, y + dy, self.mLineColor, coverFull)

    if ei.getDy() and dx != 0:
      self.ren[].blendHline(x-dx+1, y+dy, x+dx-1, self.mFillColor, coverFull)
      self.ren[].blendHline(x-dx+1, y-dy, x+dx-1, self.mFillColor, coverFull)

    inc ei

proc line*[B,C](self: var RendererPrimitives[B,C], x1, y1, x2, y2: int, last = false) =
  var
    li = LineBresenhamInterpolator(x1, y1, x2, y2)
    len = li.len()

  if len == 0:
    if last:
      self.ren[].blendPixel(LineBresenhamInterpolator.lineLr(x1),
        LineBresenhamInterpolator.lineLr(y1), self.mLineColor, coverFull)
    return

  if last: inc len

  if li.isVer():
    doWhile len != 0:
      self.ren[].blendPixel(li.x2(), li.y1(), self.mLineColor, coverFull)
      li.vstep()
      dec len
  else:
    doWhile len != 0:
      self.ren[].blendPixel(li.x1(), li.y2(), self.mLineColor, coverFull)
      li.hstep()
      dec len

proc moveTo*[B,C](self: var RendererPrimitives[B,C], x, y: int) =
  self.currX = x
  self.currY = y

proc lineTo*[B,C](self: var RendererPrimitives[B,C], x, y: int, last = false) =
  self.line(self.currX, self.currY, x, y, last)
  self.currX = x
  self.currY = y

proc getRen*[B,C](self: var RendererPrimitives[B,C]): var B = self.ren[]
