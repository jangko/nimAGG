import basics, dda_line, color_rgba, color_gray, algorithm, vector

ddaLineInterpolator(LineInterpolator, 14)

type
  ColorInterpolator*[ColorT] = object
    mC1, mC2: ColorT
    mLen, mCount: int

  ColorInterpolatorRgba8* = object
    r, g, b, a: LineInterpolator

  ColorInterpolatorGray8* = object
    v, a: LineInterpolator

template getColorT*[ColorT](x: typedesc[ColorInterpolator[ColorT]]): untyped = ColorT
template getColorT*(x: typedesc[ColorInterpolatorRgba8]): untyped = Rgba8
template getColorT*(x: typedesc[ColorInterpolatorGray8]): untyped = Gray8

proc initCI*[ColorT](c1, c2: ColorT, len: int): ColorInterpolator[ColorT] =
  result.mC1 = c1
  result.mC2 = c2
  result.mLen = len
  result.mCount = 0

proc initColorInterpolatorRgba8*(c1, c2: Rgba8, len: int): ColorInterpolatorRgba8 =
  result.r = initLineInterpolator(c1.r.int, c2.r.int, len)
  result.g = initLineInterpolator(c1.g.int, c2.g.int, len)
  result.b = initLineInterpolator(c1.b.int, c2.b.int, len)
  result.a = initLineInterpolator(c1.a.int, c2.a.int, len)

proc initColorInterpolatorGray8*(c1, c2: Gray8, len: int): ColorInterpolatorGray8 =
  result.v = initLineInterpolator(c1.v.int, c2.v.int, len)
  result.a = initLineInterpolator(c1.a.int, c2.a.int, len)

template initColorInterpolator*[ColorT](c1, c2: ColorT, len: int): untyped =
  when ColorT is Rgba8:
    initColorInterpolatorRgba8(c1, c2, len)
  elif ColorT is Gray8:
    initColorInterpolatorGray8(c1, c2, len)
  else:
    initCI[ColorT](c1, c2, len)

proc inc*[ColorT](self: var ColorInterpolator[ColorT]) =
  inc self.mCount

proc color*[ColorT](self: ColorInterpolator[ColorT]): ColorT =
  result = self.mC1.gradient(self.mC2, float64(self.mCount) / float64(self.mLen))

proc inc*(self: var ColorInterpolatorRgba8) =
  inc self.r
  inc self.g
  inc self.b
  inc self.a

proc color*(self: var ColorInterpolatorRgba8): Rgba8 =
  result = initRgba8(self.r.y().uint, self.g.y().uint, self.b.y().uint, self.a.y().uint)

proc inc*(self: var ColorInterpolatorGray8) =
  inc self.v
  inc self.a

proc color*(self: var ColorInterpolatorGray8): Gray8 =
  result = initGray8(self.v.y().uint, self.a.y().uint)

template gradientLutAux*(name: untyped, colorInterpolator, ColorT: typed, colorLutSize: int = 256) =
  type
    `name ColorPoint`* = object
      offset: float64
      color: ColorT

    name* = object
      mColorProfile: seq[`name ColorPoint`]
      mColorLut: seq[ColorT]

  proc `init name ColorPoint`*(offset: float64, c: ColorT): `name ColorPoint` =
    result.offset = offset
    result.color  = c

    if offset < 0.0: result.offset = 0.0
    if offset > 1.0: result.offset = 1.0

  proc offsetLess(a, b: `name ColorPoint`): int =
    result = cmp(a.offset, b.offset)

  proc offsetEqual(a, b: `name ColorPoint`): bool =
    result = a.offset == b.offset

  proc `init name`*(size = colorLutSize): name =
    result.mColorProfile = @[]
    result.mColorLut = newSeq[ColorT](size)

  # Build Gradient Lut
  # First, call removeAll(), then add_color() at least twice,
  # then build_lut(). Argument "offset" in add_color must be
  # in range [0...1] and defines a color stop as it is described
  # in SVG specification, section Gradients and Patterns.
  # The simplest linear gradient is:
  #    gradient_lut.add_color(0.0, start_color)
  #    gradient_lut.add_color(1.0, end_color)

  proc removeAll*(self: var name) =
    self.mColorProfile.setLen(0)

  proc addColor*(self: var name, offset: float64, color: ColorT) =
    self.mColorProfile.add(`init name ColorPoint`(offset, color))

  # Size-index Interface. This class can be used directly as the
  # ColorF in span_gradient. All it needs is two access methods
  # size() and operator [].
  proc len*(self: name): int = self.mColorLut.len
  proc `[]`*(self: name, i: int): ColorT =
    result = self.mColorLut[i]

  proc buildLut*(self: var name) =
    sort(self.mColorProfile, offsetLess)
    self.mColorProfile.setLen(removeDuplicates(self.mColorProfile, offsetEqual))

    if self.mColorProfile.len >= 2:
      var
        start = uround(self.mColorProfile[0].offset * self.mColorLut.len.float64)
        stop: int
        c = self.mColorProfile[0].color

      for i in 0.. <start:
        self.mColorLut[i] = c

      for i in 1.. <self.mColorProfile.len:
        stop  = uround(self.mColorProfile[i].offset * self.mColorLut.len.float64)
        var ci = initColorInterpolator[ColorT](self.mColorProfile[i-1].color,
                              self.mColorProfile[i].color,
                              stop - start + 1)
        while start < stop:
          self.mColorLut[start] = ci.color()
          inc ci
          inc start

      let last = self.mColorProfile.len - 1
      c = self.mColorProfile[last].color
      while stop < self.mColorLut.len:
        self.mColorLut[stop] = c
        inc stop

template gradientLut*(name: untyped, colorInterpolator: typed, colorLutSize: int = 256): untyped =
  gradientLutAux(name, colorInterpolator, getColorT(colorInterpolator), colorLutSize)

gradientLut(GradientLut, ColorInterpolatorRgba8)