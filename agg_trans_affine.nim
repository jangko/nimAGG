import math, agg_basics

type
  TransAffine* = object
    sx*, shy*, shx*, sy*, tx*, ty*: float64

proc initTransAffine*(v0, v1, v2, v3, v4, v5: float64): TransAffine =
  result.sx = v0
  result.shy = v1
  result.shx = v2
  result.sy = v3
  result.tx = v4
  result.ty = v5

proc initTransAffine*(): TransAffine =
  result = initTransAffine(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

proc multiply*(a: var TransAffine, m: TransAffine) =
  var
    t0 = a.sx  * m.sx + a.shy * m.shx
    t2 = a.shx * m.sx + a.sy  * m.shx
    t4 = a.tx  * m.sx + a.ty  * m.shx + m.tx

  a.shy = a.sx  * m.shy + a.shy * m.sy
  a.sy  = a.shx * m.shy + a.sy  * m.sy
  a.ty  = a.tx  * m.shy + a.ty  * m.sy + m.ty
  a.sx  = t0
  a.shx = t2
  a.tx  = t4

proc reset*(a: var TransAffine) =
  a.sx = 1.0
  a.sy = 1.0
  a.shy = 0.0
  a.shx = 0.0
  a.tx = 0.0
  a.ty = 0.0

proc `*=`*(a: var TransAffine, m: TransAffine) =
  a.multiply(m)

proc determinantReciprocal(a: var TransAffine): float64 =
  result = 1.0 / (a.sx * a.sy - a.shy * a.shx)

proc invert*(a: var TransAffine) =
  let
    d  = a.determinantReciprocal()
    t0 =  a.sy * d

  a.sy  =  a.sx  * d
  a.shy = -a.shy * d
  a.shx = -a.shx * d

  let t4 = -a.tx * t0  - a.ty * a.shx

  a.ty = -a.tx * a.shy - a.ty * a.sy

  a.sx = t0
  a.tx = t4

proc transform*(a: var TransAffine, x, y: var float64) {.inline.} =
  let tmp = x
  x = tmp * a.sx + y * a.shx + a.tx
  y = tmp * a.shy + y * a.sy  + a.ty

proc transAffineTranslation*(x, y: float64): TransAffine =
  result = initTransAffine(1.0, 0.0, 0.0, 1.0, x, y)

proc transAffineRotation*(a: float64): TransAffine =
  result = initTransAffine(cos(a), sin(a), -sin(a), cos(a), 0.0, 0.0)

proc transAffineScaling*(x, y: float64): TransAffine =
  result = initTransAffine(x, 0.0, 0.0, y, 0.0, 0.0)

proc transAffineScaling*(s: float64): TransAffine =
  result = initTransAffine(s, 0.0, 0.0, s, 0.0, 0.0)