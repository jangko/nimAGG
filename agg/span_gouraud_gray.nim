import basics, color_gray, dda_line, span_gouraud, calc

export span_gouraud

type
  GrayCalc = object
    mX1, mY1, mDx, m1Dy: float64
    mV1, mA1, mDv, mDa: int
    mV, mA, mX: int

  SpanGouraudGray*[ColorT] = object of SpanGouraud[ColorT]
    mSwap: bool
    mY2: int
    mC1, mC2, mC3: GrayCalc

const
  subPixelShift = 4
  subPixelScale = 1 shl subPixelShift

proc init[CoordT](self: var GrayCalc, c1, c2: CoordT) =
  self.mX1  = c1.x - 0.5
  self.mY1  = c1.y - 0.5
  self.mDx  = c2.x - c1.x
  let dy = c2.y - c1.y
  self.m1Dy = if abs(dy) < 1e-10: 1e10 else: 1.0 / dy
  self.mV1 = int(c1.color.v)
  self.mA1 = int(c1.color.a)
  self.mDv = c2.color.v.int - self.mV1
  self.mDa = c2.color.a.int - self.mA1

proc calc(self: var GrayCalc, y: float64) =
  var k = (y - self.mY1) * self.m1Dy
  if k < 0.0: k = 0.0
  if k > 1.0: k = 1.0
  self.mV = self.mV1 + iround(self.mDv.float64 * k)
  self.mA = self.mA1 + iround(self.mDa.float64 * k)
  self.mX = iround((self.mX1 + self.mDx * k) * subPixelScale)

proc initSpanGouraudGray*[ColorT](): SpanGouraudGray[ColorT] = discard

proc initSpanGouraudGray*[ColorT](c1, c2, c3: ColorT,
  x1, y1, x2, y2, x3, y3: float64; d = 0.0'f64): SpanGouraudGray[ColorT] =
  SpanGouraud[ColorT](result).init(c1, c2, c3, x1, y1, x2, y2, x3, y3, d)

proc colors*[ColorT, ColorB](self: var SpanGouraudGray[ColorT], c1, c2, c3: ColorB) =
  when ColorT isnot ColorB:
    var c1 = construct(ColorT, c1)
    var c2 = construct(ColorT, c2)
    var c3 = construct(ColorT, c3)
    SpanGouraud[ColorT](self).colors(c1, c2, c3)
  else:
    SpanGouraud[ColorT](self).colors(c1, c2, c3)

proc triangle*[ColorT](self: var SpanGouraudGray[ColorT], x1, y1, x2, y2, x3, y3, d: float64) =
  SpanGouraud[ColorT](self).triangle(x1, y1, x2, y2, x3, y3, d)

proc prepare*[ColorT](self: var SpanGouraudGray[ColorT]) =
  type base = SpanGouraud[ColorT]
  let coord = base(self).arrangeVertices()
  self.mY2 = int(coord[1].y)

  self.mSwap = crossProduct(coord[0].x, coord[0].y,
                         coord[2].x, coord[2].y,
                         coord[1].x, coord[1].y) < 0.0

  self.mC1.init(coord[0], coord[2])
  self.mC2.init(coord[0], coord[1])
  self.mC3.init(coord[1], coord[2])

ddaLineInterpolator(DdaLine, 14)

proc generate*[ColorT](self: var SpanGouraudGray[ColorT], span: ptr ColorT, x, y, len: int) =
  self.mC1.calc(y.float64)

  var
    pc1 = self.mC1.addr
    pc2 = self.mC2.addr

  if y < self.mY2:
    # Bottom part of the triangle (first subtriangle)
    self.mC2.calc(y.float64 + self.mC2.m1Dy)
  else:
    # Upper part (second subtriangle)
    self.mC3.calc(y.float64 - self.mC3.m1Dy)
    pc2 = self.mC3.addr

  if self.mSwap:
    # It means that the triangle is oriented clockwise,
    # so that we need to swap the controlling structures
    swap(pc2, pc1)

  # Get the horizontal length with subpixel accuracy
  # and protect it from division by zero
  var nlen = abs(pc2.mX - pc1.mX)
  if nlen <= 0: nlen = 1

  var
    v = initDdaLine(pc1.mV, pc2.mV, nlen)
    a = initDdaLine(pc1.mA, pc2.mA, nlen)

  # Calculate the starting point of the gradient with subpixel
  # accuracy and correct (roll back) the interpolators.
  # This operation will also clip the beginning of the span
  # if necessary.
  var start = pc1.mX - (x shl subPixelShift)
  v -= start
  a -= start
  nlen += start

  var
    vv, va: int
    span = span
    len = len
  const lim = getBaseMask(ColorT)
  type ValueT = getValueT(ColorT)

  # Beginning part of the span. Since we rolled back the
  # interpolators, the color values may have overflow.
  # So that, we render the beginning part with checking
  # for overflow. It lasts until "start" is positive;
  # typically it's 1-2 pixels, but may be more in some ofs.
  while len != 0 and start > 0:
    vv = v.y()
    va = a.y()
    if vv < 0: vv = 0
    if vv > lim: vv = lim
    if va < 0: va = 0
    if va > lim: va = lim
    span.v = ValueT(vv)
    span.a = ValueT(va)
    v += subPixelScale
    a += subPixelScale
    nlen -= subPixelScale
    start -= subPixelScale
    inc span
    dec len

  # Middle part, no checking for overflow.
  # Actual spans can be longer than the calculated length
  # because of anti-aliasing, thus, the interpolators can
  # overflow. But while "nlen" is positive we are safe.
  while len != 0 and nlen > 0:
    span.v = ValueT(v.y())
    span.a = ValueT(a.y())
    v += subPixelScale
    a += subPixelScale
    nlen -= subPixelScale
    inc span
    dec len

  # Ending part; checking for overflow.
  # Typically it's 1-2 pixels, but may be more in some ofs.
  while len != 0:
    vv = v.y()
    va = a.y()
    if vv < 0: vv = 0
    if vv > lim: vv = lim
    if va < 0: va = 0
    if va > lim: va = lim
    span.v = ValueT(vv)
    span.a = ValueT(va)
    v += subPixelScale
    a += subPixelScale
    inc span
    dec len
