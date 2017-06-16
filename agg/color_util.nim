import color_rgba, basics, math

proc hsvRgba*(h, s, v: float64, a = 1.0): Rgba =
  ## h = 0..360 degree
  ## s, v = 0..1
  const
    perm = [[0, 3, 1], [2, 0, 1], [1, 0, 3], [1, 2, 0], [3, 1, 0], [0, 1, 2]]

  let
    h  = ((h mod 360.0f) / 360.0) * 360.0
    i  = math.floor(((h / 60) mod 6))
    f  = (h / 60) - i
    vs = [v, v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)]

  result.r = vs[perm[i.int][0]]
  result.g = vs[perm[i.int][1]]
  result.b = vs[perm[i.int][2]]
  result.a = a

proc hslRgba*(hue, sat, lum: float64, a = 1.0): Rgba =
  ## h = 0..360 degree
  ## s, v = 0..1
  var
    v = if lum <= 0.5: (lum * (1.0 + sat)) else: (lum + sat - lum * sat)
    m = lum + lum - v
    sv = (v - m) / v
    hue = hue / 60.0 #get into range 0..6
    sextant = math.floor(hue)
    fract = hue - sextant
    vsf = v * sv * fract
    mid1 = m + vsf
    mid2 = v - vsf

  if v > 0:
    case sextant.int
    of 0: result.r = v;    result.g = mid1; result.b = m
    of 1: result.r = mid2; result.g = v;    result.b = m
    of 2: result.r = m;    result.g = v;    result.b = mid1
    of 3: result.r = m;    result.g = mid2; result.b = v
    of 4: result.r = mid1; result.g = m;    result.b = v
    of 5: result.r = v;    result.g = m;    result.b = mid2
    else: discard
  else:
    result.r = lum; result.g = lum; result.b = lum
  result.a = a

proc agg_hue(h, m1, m2: float64): float64 =
  var h = h
  if h < 0: h += 1.0
  if h > 1: h -= 1.0
  if h < 1.0/6.0:
    return m1 + (m2 - m1) * h * 6.0
  elif h < 3.0/6.0:
    return m2
  elif h < 4.0/6.0:
    return m1 + (m2 - m1) * (2.0/3.0 - h) * 6.0
  return m1

proc hsl2Rgba*(hue, sat, lum: float64, a = 1.0): Rgba =
  ## h = 0..2pi radian
  ## s, v = 0..1
  var
    hue = hue mod 1.0
    sat = clamp(sat, 0.0, 1.0)
    lum = clamp(lum, 0.0, 1.0)

  if hue < 0.0: hue += 1.0

  var
    m2 = if lum <= 0.5: (lum * (1.0 + sat)) else: (lum + sat - lum * sat)
    m1 = 2.0 * lum - m2

  result.r = clamp(agg_hue(hue + 1.0/3.0, m1, m2), 0.0, 1.0)
  result.g = clamp(agg_hue(hue, m1, m2), 0.0, 1.0)
  result.b = clamp(agg_hue(hue - 1.0/3.0, m1, m2), 0.0, 1.0)
  result.a = a
