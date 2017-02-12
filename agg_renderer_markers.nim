import agg_basics, agg_renderer_primitives, agg_ellipse_bresenham, agg_renderer_base

type
  Marker* = enum
    marker_square,
    marker_diamond,
    marker_circle,
    marker_crossed_circle,
    marker_semiellipse_left,
    marker_semiellipse_right,
    marker_semiellipse_up,
    marker_semiellipse_down,
    marker_triangle_left,
    marker_triangle_right,
    marker_triangle_up,
    marker_triangle_down,
    marker_four_rays,
    marker_cross,
    marker_x,
    marker_dash,
    marker_dot,
    marker_pixel,
    end_of_markers

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
  type base = RendererPrimitives[Renderer,ColorT]
  var rc= initRectI(x-r, y-r, x+y, y+r)
  rc.clip(base(self).ren().boundingClipBox())

proc square*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).outlinedRectangle(x-r, y-r, x+r, y+r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc diamond*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).outlinedEllipse(x, y, r, r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc crossedCircle*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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

proc semiellipseLeft*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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

      if (ei.getDy() and dx) != 0:
         base(self).ren().blendVline(x+dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendVline(x+dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiellipseRight*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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

      if (ei.getDy() and dx) != 0:
        base(self).ren().blendVline(x-dy, y-dx+1, y+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendVline(x-dy, y-dx, y+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiellipseUp*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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

      if (ei.getDy() and dx) != 0:
        base(self).ren().blendHline(x-dx+1, y-dy, x+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendHline(x-dx, y-dy-1, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc semiellipseDown*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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

      if (ei.getDy() and dx) != 0:
        base(self).ren().blendHline(x-dx+1, y+dy, x+dx-1, base(self).fillColor(), coverFull)
      inc ei
    base(self).ren().blendHline(x-dx, y+dy+1, x+dx, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc triangleLeft*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).ren().blendVline(x, y-r, y+r, base(self).lineColor(), coverFull)
    base(self).ren().blendHline(x-r, y, x+r, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc xing*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
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
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).ren().blendHline(x-r, y, x+r, base(self).lineColor(), coverFull)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc dot*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  type base = RendererPrimitives[Renderer,ColorT]
  if not self.visible(x, y, r): return
  if r != 0:
    base(self).solid_ellipse(x, y, r, r)
  else:
    base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc pixel*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int) =
  type base = RendererPrimitives[Renderer,ColorT]
  base(self).ren().blendPixel(x, y, base(self).fillColor(), coverFull)

proc marker*[Renderer,ColorT](self: var RendererMarkers[Renderer,ColorT], x, y, r: int, shape: Marker) =
  case shape
  of marker_square:            self.square(x, y, r)
  of marker_diamond:           self.diamond(x, y, r)
  of marker_circle:            self.circle(x, y, r)
  of marker_crossed_circle:    self.crossed_circle(x, y, r)
  of marker_semiellipse_left:  self.semiellipse_left(x, y, r)
  of marker_semiellipse_right: self.semiellipse_right(x, y, r)
  of marker_semiellipse_up:    self.semiellipse_up(x, y, r)
  of marker_semiellipse_down:  self.semiellipse_down(x, y, r)
  of marker_triangle_left:     self.triangle_left(x, y, r)
  of marker_triangle_right:    self.triangle_right(x, y, r)
  of marker_triangle_up:       self.triangle_up(x, y, r)
  of marker_triangle_down:     self.triangle_down(x, y, r)
  of marker_four_rays:         self.four_rays(x, y, r)
  of marker_cross:             self.cross(x, y, r)
  of marker_x:                 self.xing(x, y, r)
  of marker_dash:              self.dash(x, y, r)
  of marker_dot:               self.dot(x, y, r)
  of marker_pixel:             self.pixel(x, y, r)
  else: discard

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
  of marker_square:            doWhile n != 0: self.square(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_diamond:           doWhile n != 0: self.diamond(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_circle:            doWhile n != 0: self.circle(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_crossed_circle:    doWhile n != 0: self.crossed_circle(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_semiellipse_left:  doWhile n != 0: self.semiellipse_left(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_semiellipse_right: doWhile n != 0: self.semiellipse_right(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_semiellipse_up:    doWhile n != 0: self.semiellipse_up(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_semiellipse_down:  doWhile n != 0: self.semiellipse_down(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_triangle_left:     doWhile n != 0: self.triangle_left(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_triangle_right:    doWhile n != 0: self.triangle_right(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_triangle_up:       doWhile n != 0: self.triangle_up(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_triangle_down:     doWhile n != 0: self.triangle_down(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_four_rays:         doWhile n != 0: self.four_rays(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_cross:             doWhile n != 0: self.cross(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_x:                 doWhile n != 0: self.xing(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_dash:              doWhile n != 0: self.dash(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_dot:               doWhile n != 0: self.dot(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  of marker_pixel:             doWhile n != 0: self.pixel(int(x[]), int(y[]), int(r)); inc x; inc y; dec n
  else: discard

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, shape: Marker) =
  if n <= 0: return
  case shape
  of marker_square:            doWhile n != 0: square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_diamond:           doWhile n != 0: diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_circle:            doWhile n != 0: circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_crossed_circle:    doWhile n != 0: crossed_circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_semiellipse_left:  doWhile n != 0: semiellipse_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_semiellipse_right: doWhile n != 0: semiellipse_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_semiellipse_up:    doWhile n != 0: semiellipse_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_semiellipse_down:  doWhile n != 0: semiellipse_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_triangle_left:     doWhile n != 0: triangle_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_triangle_right:    doWhile n != 0: triangle_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_triangle_up:       doWhile n != 0: triangle_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_triangle_down:     doWhile n != 0: triangle_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_four_rays:         doWhile n != 0: four_rays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_cross:             doWhile n != 0: cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_x:                 doWhile n != 0: xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_dash:              doWhile n != 0: dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_dot:               doWhile n != 0: dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  of marker_pixel:             doWhile n != 0: pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; dec n
  else: discard

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, fc: ptr ColorT, shape: Marker) =
  if n <= 0: return
  case shape
  of marker_square:            doWhile n != 0: base(self).fillColor(fc[]); self.square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_diamond:           doWhile n != 0: base(self).fillColor(fc[]); self.diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_circle:            doWhile n != 0: base(self).fillColor(fc[]); self.circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_crossed_circle:    doWhile n != 0: base(self).fillColor(fc[]); self.crossed_circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_semiellipse_left:  doWhile n != 0: base(self).fillColor(fc[]); self.semiellipse_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_semiellipse_right: doWhile n != 0: base(self).fillColor(fc[]); self.semiellipse_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_semiellipse_up:    doWhile n != 0: base(self).fillColor(fc[]); self.semiellipse_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_semiellipse_down:  doWhile n != 0: base(self).fillColor(fc[]); self.semiellipse_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_triangle_left:     doWhile n != 0: base(self).fillColor(fc[]); self.triangle_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_triangle_right:    doWhile n != 0: base(self).fillColor(fc[]); self.triangle_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_triangle_up:       doWhile n != 0: base(self).fillColor(fc[]); self.triangle_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_triangle_down:     doWhile n != 0: base(self).fillColor(fc[]); self.triangle_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_four_rays:         doWhile n != 0: base(self).fillColor(fc[]); self.four_rays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_cross:             doWhile n != 0: base(self).fillColor(fc[]); self.cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_x:                 doWhile n != 0: base(self).fillColor(fc[]); self.xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_dash:              doWhile n != 0: base(self).fillColor(fc[]); self.dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_dot:               doWhile n != 0: base(self).fillColor(fc[]); self.dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  of marker_pixel:             doWhile n != 0: base(self).fillColor(fc[]); self.pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; dec n
  else: discard

proc markers*[Renderer,ColorT,T](self: var RendererMarkers[Renderer,ColorT],
  n: int, x, y, r: ptr T, fc, lc: ptr ColorT, shape: Marker) =
  if n <= 0: return
  case shape
  of marker_square:            doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); square(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_diamond:           doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); diamond(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_circle:            doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_crossed_circle:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); crossed_circle(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_semiellipse_left:  doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); semiellipse_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_semiellipse_right: doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); semiellipse_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_semiellipse_up:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); semiellipse_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_semiellipse_down:  doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); semiellipse_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_triangle_left:     doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); triangle_left(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_triangle_right:    doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); triangle_right(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_triangle_up:       doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); triangle_up(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_triangle_down:     doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); triangle_down(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_four_rays:         doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); four_rays(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_cross:             doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); cross(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_x:                 doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); xing(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_dash:              doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); dash(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_dot:               doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); dot(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  of marker_pixel:             doWhile n != 0: base(self).fillColor(fc[]); base(self).lineColor(lc[]); pixel(int(x[]), int(y[]), int(r[])); inc x; inc y; inc r; inc fc; inc lc; dec n
  else: discard