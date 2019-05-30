import basics, renderer_primitives, ellipse_bresenham, renderer_base

type
  Marker* = enum
    MarkerSquare
    MarkerDiamond
    MarkerCircle
    MarkerCrossedCircle
    MarkerSemiEllipseLeft
    MarkerSemiEllipseRight
    MarkerSemiEllipseUp
    MarkerSemiEllipseDown
    MarkerTriangleLeft
    MarkerTriangleRight
    MarkerTriangleUp
    MarkerTriangleDown
    MarkerFourRays
    MarkerCross
    MarkerX
    MarkerDash
    MarkerDot
    MarkerPixel

type
  RendererMarkers*[BaseRenderer, ColorT] = object of RendererPrimitives[BaseRenderer, ColorT]

proc coord*[R,C](self: RendererMarkers[R,C], c: float64): int =
  type base = RendererPrimitives[R,C]
  result = base.coord(c)

proc initRendererMarkersAux*[Renderer,ColorT](rbuf: var Renderer): RendererMarkers[Renderer, ColorT] =
  type base = RendererPrimitives[Renderer,ColorT]
  base(result).init(rbuf)

proc initRendererMarkers*[Renderer](rbuf: var Renderer): auto =
  result = initRendererMarkersAux[Renderer,getColorT(Renderer)](rbuf)

proc visible*[Renderer,ColorT](self: RendererMarkers[Renderer,ColorT], x, y, r: int): bool =
  mixin boundingClipBox
  type base = RendererPrimitives[Renderer,ColorT]
  var rc= initRectI(x-r, y-r, x+y, y+r)
  rc.clip(base(self).ren().boundingClipBox())

proc square*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).outlinedRectangle(x-r, y-r, x+r, y+r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc diamond*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHLine
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      dy = -r
      dx = 0
    doWhile dy <= 0:
      base(self).ren().blendPixel(x - dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dx, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y - dy, base(self).lineColor(), coverFull)
      if dx != 0:
        base(self).ren().blendHline(x-dx+1, y+dy, x+dx-1, base(self).fillColor(), coverFull)
        base(self).ren().blendHline(x-dx+1, y-dy, x+dx-1, base(self).fillColor(), coverFull)
      inc dy
      inc dx
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc circle*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).outlinedEllipse(x, y, r, r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc crossedCircle*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendHline, blendVline, blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).outlinedEllipse(x, y, r, r)
    var r6 = r + (r shr 1)
    if r <= 2: inc r6
    var r = r shr 1
    base(self).ren().blendHline(x-r6, y, x-r,  base(self).lineColor(), coverFull)
    base(self).ren().blendHline(x+r,  y, x+r6, base(self).lineColor(), coverFull)
    base(self).ren().blendVline(x, y-r6, y-r,  base(self).lineColor(), coverFull)
    base(self).ren().blendVline(x, y+r,  y+r6, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiEllipseLeft*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendVline, blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      r8 = r * 4 div 5
      dy = -r
      dx = 0
      ei = initEllipseBresenhamInterpolator(r * 3 div 5, r+r8)
    doWhile dy < r8:
      dx += ei.getDx()
      dy += ei.getDy()

      base(self).ren().blendPixel(x + dy, y + dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dy, y - dx, base(self).lineColor(), coverFull)

      if ei.getDy() != 0 and dx != 0:
         base(self).ren().blendVline(x+dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendVline(x+dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiEllipseRight*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendVline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      r8 = r * 4 div 5
      dy = -r
      dx = 0
      ei = initEllipseBresenhamInterpolator(r * 3 div 5, r+r8)
    doWhile dy < r8:
      dx += ei.getDx()
      dy += ei.getDy()

      base(self).ren().blendPixel(x - dy, y + dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y - dx, base(self).lineColor(), coverFull)

      if ei.getDy() != 0 and dx != 0:
        base(self).ren().blendVline(x-dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendVline(x-dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiEllipseUp*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      r8 = r * 4 div 5
      dy = -r
      dx = 0
      ei = initEllipseBresenhamInterpolator(r * 3 div 5, r+r8)
    doWhile dy < r8:
      dx += ei.getDx()
      dy += ei.getDy()

      base(self).ren().blendPixel(x + dx, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dx, y - dy, base(self).lineColor(), coverFull)

      if ei.getDy() != 0 and dx != 0:
        base(self).ren().blendHline(x-dx+1, y-dy, x+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendHline(x-dx, y-dy-1, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiEllipseDown*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      r8 = r * 4 div 5
      dy = -r
      dx = 0
      ei = initEllipseBresenhamInterpolator(r * 3 div 5, r+r8)
    doWhile dy < r8:
      dx += ei.getDx()
      dy += ei.getDy()

      base(self).ren().blendPixel(x + dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dx, y + dy, base(self).lineColor(), coverFull)

      if ei.getDy() != 0 and dx != 0:
        base(self).ren().blendHline(x-dx+1, y+dy, x+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendHline(x-dx, y+dy+1, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc triangleLeft*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendVline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return

  if r != 0:
    var
      dy = -r
      dx = 0
      flip = 0
      r6 = r * 3 div 5
    doWhile dy < r6:
      base(self).ren().blendPixel(x + dy, y - dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dy, y + dx, base(self).lineColor(), coverFull)

      if dx != 0:
        base(self).ren().blendVline(x+dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc dy
      dx += flip
      flip = flip xor 1
    base(self).ren().blendVline(x+dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc triangleRight*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendVline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      dy = -r
      dx = 0
      flip = 0
      r6 = r * 3 div 5
    doWhile dy < r6:
      base(self).ren().blendPixel(x - dy, y - dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y + dx, base(self).lineColor(), coverFull)

      if dx != 0:
        base(self).ren().blendVline(x-dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc dy
      dx += flip
      flip = flip xor 1
    base(self).ren().blendVline(x-dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc triangleUp*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      dy = -r
      dx = 0
      flip = 0
      r6 = r * 3 div 5
    doWhile dy < r6:
      base(self).ren().blendPixel(x - dx, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y - dy, base(self).lineColor(), coverFull)

      if dx != 0:
        base(self).ren().blendHline(x-dx+1, y-dy, x+dx-1, base(self).fillColor(), coverFull)
      inc dy
      dx += flip
      flip = flip xor 1
    base(self).ren().blendHline(x-dx, y-dy, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc triangleDown*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      dy = -r
      dx = 0
      flip = 0
      r6 = r * 3 div 5
    doWhile dy < r6:
      base(self).ren().blendPixel(x - dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y + dy, base(self).lineColor(), coverFull)

      if dx != 0:
        base(self).ren().blendHline(x-dx+1, y+dy, x+dx-1, base(self).fillColor(), coverFull)
      inc dy
      dx += flip
      flip = flip xor 1
    base(self).ren().blendHline(x-dx, y+dy, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc fourRays*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendVline, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var
      dy = -r
      dx = 0
      flip = 0
      r3 = -(r div 3)
    doWhile dy <= r3:
      base(self).ren().blendPixel(x - dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dx, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dx, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dy, y - dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dy, y + dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y - dx, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y + dx, base(self).lineColor(), coverFull)

      if dx != 0:
        base(self).ren().blendHline(x-dx+1, y+dy,   x+dx-1, base(self).fillColor(), coverFull)
        base(self).ren().blendHline(x-dx+1, y-dy,   x+dx-1, base(self).fillColor(), coverFull)
        base(self).ren().blendVline(x+dy,   y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
        base(self).ren().blendVline(x-dy,   y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc dy
      dx += flip
      flip = flip xor 1
    base(self).solidRectangle(x+r3+1, y+r3+1, x-r3-1, y-r3-1)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc cross*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendVline, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).ren().blendVline(x, y-r, y+r, base(self).lineColor(), coverFull)
    base(self).ren().blendHline(x-r, y, x+r, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc xing*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    var dy = -r * 7 div 10
    doWhile dy < 0:
      base(self).ren().blendPixel(x + dy, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y + dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x + dy, y - dy, base(self).lineColor(), coverFull)
      base(self).ren().blendPixel(x - dy, y - dy, base(self).lineColor(), coverFull)
      inc dy
  base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc dash*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel, blendHline
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).ren().blendHline(x-r, y, x+r, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc dot*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).solidEllipse(x, y, r, r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc pixel*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  mixin blendPixel
  type base = RendererPrimitives[Renderer,ColorT]
  base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc marker*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int, shape: Marker) =
  case shape
  of MarkerSquare:           self.square(x, y, r)
  of MarkerDiamond:          self.diamond(x, y, r)
  of MarkerCircle:           self.circle(x, y, r)
  of MarkerCrossedCircle:    self.crossedCircle(x, y, r)
  of MarkerSemiEllipseLeft:  self.semiEllipseLeft(x, y, r)
  of MarkerSemiEllipseRight: self.semiEllipseRight(x, y, r)
  of MarkerSemiEllipseUp:    self.semiEllipseUp(x, y, r)
  of MarkerSemiEllipseDown:  self.semiEllipseDown(x, y, r)
  of MarkerTriangleLeft:     self.triangleLeft(x, y, r)
  of MarkerTriangleRight:    self.triangleRight(x, y, r)
  of MarkerTriangleUp:       self.triangleUp(x, y, r)
  of MarkerTriangleDown:     self.triangleDown(x, y, r)
  of MarkerFourRays:         self.fourRays(x, y, r)
  of MarkerCross:            self.cross(x, y, r)
  of MarkerX:                self.xing(x, y, r)
  of MarkerDash:             self.dash(x, y, r)
  of MarkerDot:              self.dot(x, y, r)
  of MarkerPixel:            self.pixel(x, y, r)

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y: ptr T, r: T, shape: Marker) =
  type base = RendererPrimitives[Renderer,ColorT]
  var
    n = n
    x = x
    y = y

  if n <= 0: return
  if r == 0:
    doWhile n != 0:
      base(self).ren().blendPixel(int(x[]), int(y[]), base(self).fillColor(), coverFull)
      inc x
      inc y
      dec n
    return

  case shape
  of MarkerSquare:           doWhile n != 0: self.square(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerDiamond:          doWhile n != 0: self.diamond(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerCircle:           doWhile n != 0: self.circle(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerCrossedCircle:    doWhile n != 0: self.crossedCircle(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerSemiEllipseLeft:  doWhile n != 0: self.semiEllipseLeft(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerSemiEllipseRight: doWhile n != 0: self.semiEllipseRight(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerSemiEllipseUp:    doWhile n != 0: self.semiEllipseUp(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerSemiEllipseDown:  doWhile n != 0: self.semiEllipseDown(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerTriangleLeft:     doWhile n != 0: self.triangleLeft(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerTriangleRight:    doWhile n != 0: self.triangleRight(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerTriangleUp:       doWhile n != 0: self.triangleUp(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerTriangleDown:     doWhile n != 0: self.triangleDown(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerFourRays:         doWhile n != 0: self.fourRays(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerCross:            doWhile n != 0: self.cross(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerX:                doWhile n != 0: self.xing(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerDash:             doWhile n != 0: self.dash(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerDot:              doWhile n != 0: self.dot(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of MarkerPixel:            doWhile n != 0: self.pixel(int(x[]), int(y[]), int(r)); inc x; inc y; dec n

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, shape: Marker) =
  if n <= 0: return
  case shape
  of MarkerSquare:           doWhile n != 0: self.square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerDiamond:          doWhile n != 0: self.diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerCircle:           doWhile n != 0: self.circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerCrossedCircle:    doWhile n != 0: self.crossedCircle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerSemiEllipseLeft:  doWhile n != 0: self.semiEllipseLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerSemiEllipseRight: doWhile n != 0: self.semiEllipseRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerSemiEllipseUp:    doWhile n != 0: self.semiEllipseUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerSemiEllipseDown:  doWhile n != 0: self.semiEllipseDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerTriangleLeft:     doWhile n != 0: self.triangleLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerTriangleRight:    doWhile n != 0: self.triangleRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerTriangleUp:       doWhile n != 0: self.triangleUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerTriangleDown:     doWhile n != 0: self.triangleDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerFourRays:         doWhile n != 0: self.fourRays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerCross:            doWhile n != 0: self.cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerX:                doWhile n != 0: self.xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerDash:             doWhile n != 0: self.dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerDot:              doWhile n != 0: self.dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of MarkerPixel:            doWhile n != 0: self.pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, fc: ptr ColorT, shape: Marker) =
  if n <= 0: return
  case shape
  of MarkerSquare:           doWhile n != 0: base(self).fillColor(fc[]); self.square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerDiamond:          doWhile n != 0: base(self).fillColor(fc[]); self.diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerCircle:           doWhile n != 0: base(self).fillColor(fc[]); self.circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerCrossedCircle:    doWhile n != 0: base(self).fillColor(fc[]); self.crossedCircle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerSemiEllipseLeft:  doWhile n != 0: base(self).fillColor(fc[]); self.semiEllipseLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerSemiEllipseRight: doWhile n != 0: base(self).fillColor(fc[]); self.semiEllipseRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerSemiEllipseUp:    doWhile n != 0: base(self).fillColor(fc[]); self.semiEllipseUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerSemiEllipseDown:  doWhile n != 0: base(self).fillColor(fc[]); self.semiEllipseDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerTriangleLeft:     doWhile n != 0: base(self).fillColor(fc[]); self.triangleLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerTriangleRight:    doWhile n != 0: base(self).fillColor(fc[]); self.triangleRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerTriangleUp:       doWhile n != 0: base(self).fillColor(fc[]); self.triangleUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerTriangleDown:     doWhile n != 0: base(self).fillColor(fc[]); self.triangleDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerFourRays:         doWhile n != 0: base(self).fillColor(fc[]); self.fourRays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerCross:            doWhile n != 0: base(self).fillColor(fc[]); self.cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerX:                doWhile n != 0: base(self).fillColor(fc[]); self.xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerDash:             doWhile n != 0: base(self).fillColor(fc[]); self.dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerDot:              doWhile n != 0: base(self).fillColor(fc[]); self.dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of MarkerPixel:            doWhile n != 0: base(self).fillColor(fc[]); self.pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, fc, lc: ptr ColorT, shape: Marker) =
  if n <= 0: return
  case shape
  of MarkerSquare:           doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerDiamond:          doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerCircle:           doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerCrossedCircle:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.crossedCircle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerSemiEllipseLeft:  doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.semiEllipseLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerSemiEllipseRight: doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.semiEllipseRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerSemiEllipseUp:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.semiEllipseUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerSemiEllipseDown:  doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.semiEllipseDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerTriangleLeft:     doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.triangleLeft(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerTriangleRight:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.triangleRight(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerTriangleUp:       doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.triangleUp(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerTriangleDown:     doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.triangleDown(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerFourRays:         doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.fourRays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerCross:            doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerX:                doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerDash:             doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerDot:              doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of MarkerPixel:            doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); self.pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
