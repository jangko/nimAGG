import math, agg_basics

type
  TransAffine* = object
    sx, shy, shx, sy, tx, ty: float64
    
proc initTransAffine*(v0, v1, v2, v3, v4, v5: float64): TransAffine =
  result.sx = v0
  result.shy = v1 
  result.shx = v2
  result.sy = v3
  result.tx = v4
  result.ty = v5
        
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

proc `*=`*(a: var TransAffine, m: TransAffine) =
  a.multiply(m)

proc transform*(a: var TransAffine, x, y: ptr float64) {.inline.} =
  let tmp = x[]
  x[] = tmp * a.sx + y[] * a.shx + a.tx
  y[] = tmp * a.shy + y[] * a.sy  + a.ty
    
proc transAffineTranslation*(x, y: float64): TransAffine =
  result = initTransAffine(1.0, 0.0, 0.0, 1.0, x, y)

proc transAffineRotation*(a: float64): TransAffine =
  result = initTransAffine(cos(a), sin(a), -sin(a), cos(a), 0.0, 0.0)
