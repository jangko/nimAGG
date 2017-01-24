import agg_basics, agg_color_rgba, agg_dda_line, agg_span_gouraud, agg_math

export agg_span_gouraud

type
  RgbaCalc = object
    mX1, mY1, mDx, m1Dy: float64
    mR1, mG1, mB1, mA1: int
    mDr, mDg, mDb, mDa: int
    mR, mG, mB, mA, mX: int

  SpanGouraudRgba*[ColorT] = object of SpanGouraud[ColorT]
    mSwap: bool
    mY2: int
    mRgba1, mRgba2, mRgba3: RgbaCalc

const
  subPixelShift = 4
  subPixelScale = 1 shl subPixelShift

proc init[CoordT](self: var RgbaCalc, c1, c2: CoordT) =
  self.mX1  = c1.x - 0.5
  self.mY1  = c1.y - 0.5
  self.mDx  = c2.x - c1.x
  let dy = c2.y - c1.y
  self.m1Dy = if dy < 1e-5: 1e5 else: 1.0 / dy
  self.mR1  = c1.color.r.int
  self.mG1  = c1.color.g.int
  self.mB1  = c1.color.b.int
  self.mA1  = c1.color.a.int
  self.mDr  = c2.color.r.int - self.mR1
  self.mDg  = c2.color.g.int - self.mG1
  self.mDb  = c2.color.b.int - self.mB1
  self.mDa  = c2.color.a.int - self.mA1

proc calc(self: var RgbaCalc, y: float64) =
  var k = (y - self.mY1) * self.m1Dy
  if k < 0.0: k = 0.0
  if k > 1.0: k = 1.0
  self.mR = self.mR1 + iround(self.mDr.float64 * k)
  self.mG = self.mG1 + iround(self.mDg.float64 * k)
  self.mB = self.mB1 + iround(self.mDb.float64 * k)
  self.mA = self.mA1 + iround(self.mDa.float64 * k)
  self.mX = iround((self.mX1 + self.mDx * k) * subPixelScale)

proc initSpanGouraudRgba*[ColorT](): SpanGouraudRgba[ColorT] = discard

proc initSpanGouraudRgba*[ColorT](c1, c2, c3: ColorT,
  x1, y1, x2, y2, x3, y3: float64, d = 0'f64): SpanGouraudRgba[ColorT] =
  SpanGouraud[ColorT](result).init(c1, c2, c3, x1, y1, x2, y2, x3, y3, d)

proc colors*[ColorT, ColorB](self: var SpanGouraudRgba[ColorT], c1, c2, c3: ColorB) =
  when ColorT isnot ColorB:
    var c1 = construct(ColorT, c1)
    var c2 = construct(ColorT, c2)
    var c3 = construct(ColorT, c3)
    SpanGouraud[ColorT](self).colors(c1, c2, c3)
  else:
    SpanGouraud[ColorT](self).colors(c1, c2, c3)

proc triangle*[ColorT](self: var SpanGouraudRgba[ColorT], x1, y1, x2, y2, x3, y3, d: float64) =
  SpanGouraud[ColorT](self).triangle(x1, y1, x2, y2, x3, y3, d)

proc prepare*[ColorT](self: var SpanGouraudRgba[ColorT]) =
  type base = SpanGouraud[ColorT]

  let coord = base(self).arrangeVertices()
  self.mY2 = int(coord[1].y)

  self.mSwap = crossProduct(coord[0].x, coord[0].y,
                        coord[2].x, coord[2].y,
                        coord[1].x, coord[1].y) < 0.0

  self.mRgba1.init(coord[0], coord[2])
  self.mRgba2.init(coord[0], coord[1])
  self.mRgba3.init(coord[1], coord[2])

ddaLineInterpolator(DdaLine, 14)

proc generate*[ColorT](self: var SpanGouraudRgba[ColorT], span: ptr ColorT, x, y, len: int) =
  self.mRgba1.calc(y.float64) #(self.mRgba1.self.m1Dy > 2: self.mRgba1.self.mY1 : y)
  var
    pc1 = self.mRgba1.addr
    pc2 = self.mRgba2.addr
    span = span
    len = len

  if y <= self.mY2:
    # Bottom part of the triangle (first subtriangle)
    self.mRgba2.calc(y.float64 + self.mRgba2.m1Dy)
  else:
    # Upper part (second subtriangle)
    self.mRgba3.calc(y.float64 - self.mRgba3.m1Dy)
    pc2 = self.mRgba3.addr

  if self.mSwap:
    # It means that the triangle is oriented clockwise,
    # so that we need to swap the controlling structures
    swap(pc1, pc2)

  # Get the horizontal length with subpixel accuracy
  # and protect it from division by zero
  var nlen = abs(pc2.mX - pc1.mX)
  if nlen <= 0: nlen = 1

  var
    r = initDdaLine(pc1.mR, pc2.mR, nlen)
    g = initDdaLine(pc1.mG, pc2.mG, nlen)
    b = initDdaLine(pc1.mB, pc2.mB, nlen)
    a = initDdaLine(pc1.mA, pc2.mA, nlen)

  # Calculate the starting point of the gradient with subpixel
  # accuracy and correct (roll back) the interpolators.
  # This operation will also clip the beginning of the span
  # if necessary.
  var start = pc1.mX - (x shl subPixelShift)
  r    -= start
  g    -= start
  b    -= start
  a    -= start
  nlen += start

  var vr, vg, vb, va: int
  const lim = getBaseMask(ColorT)
  type ValueType = getValueType(ColorT)

  # Beginning part of the span. Since we rolled back the
  # interpolators, the color values may have overflow.
  # So that, we render the beginning part with checking
  # for overflow. It lasts until "start" is positive;
  # typically it's 1-2 pixels, but may be more in some ofs.
  #-------------------------
  while len != 0 and start > 0:
    vr = r.y()
    vg = g.y()
    vb = b.y()
    va = a.y()
    if vr < 0: vr = 0
    if vr > lim: vr = lim
    if vg < 0: vg = 0
    if vg > lim: vg = lim
    if vb < 0: vb = 0
    if vb > lim: vb = lim
    if va < 0: va = 0
    if va > lim: va = lim
    span.r = ValueType(vr)
    span.g = ValueType(vg)
    span.b = ValueType(vb)
    span.a = ValueType(va)
    r     += subPixelScale
    g     += subPixelScale
    b     += subPixelScale
    a     += subPixelScale
    nlen  -= subPixelScale
    start -= subPixelScale
    inc span
    dec len

  # Middle part, no checking for overflow.
  # Actual spans can be longer than the calculated length
  # because of anti-aliasing, thus, the interpolators can
  # overflow. But while "nlen" is positive we are safe.
  #-------------------------
  while len != 0 and nlen > 0:
    span.r = ValueType(r.y())
    span.g = ValueType(g.y())
    span.b = ValueType(b.y())
    span.a = ValueType(a.y())
    r    += subPixelScale
    g    += subPixelScale
    b    += subPixelScale
    a    += subPixelScale
    nlen -= subPixelScale
    inc span
    dec len

  # Ending part; checking for overflow.
  # Typically it's 1-2 pixels, but may be more in some ofs.
  #-------------------------
  while len != 0:
    vr = r.y()
    vg = g.y()
    vb = b.y()
    va = a.y()
    if vr < 0: vr = 0
    if vr > lim: vr = lim
    if vg < 0: vg = 0
    if vg > lim: vg = lim
    if vb < 0: vb = 0
    if vb > lim: vb = lim
    if va < 0: va = 0
    if va > lim: va = lim
    span.r = ValueType(vr)
    span.g = ValueType(vg)
    span.b = ValueType(vb)
    span.a = ValueType(va)
    r += subPixelScale
    g += subPixelScale
    b += subPixelScale
    a += subPixelScale
    inc span
    dec len