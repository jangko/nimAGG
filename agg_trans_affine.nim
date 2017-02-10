import math, agg_basics

const
  affineEpsilon = 1e-14

type
  TransAffine* = object
    sx*, shy*, shx*, sy*, tx*, ty*: float64

# Custom matrix. Usually used in derived classes
proc initTransAffine*(v0, v1, v2, v3, v4, v5: float64): TransAffine =
  result.sx = v0
  result.shy = v1
  result.shx = v2
  result.sy = v3
  result.tx = v4
  result.ty = v5

proc determinant*(a: TransAffine): float64 =
  result = a.sx * a.sy - a.shy * a.shx

proc determinantReciprocal(a: TransAffine): float64 =
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

#---------------------------------- Parellelogram transformations
# transform a parallelogram to another one. Src and dst are
# pointers to arrays of three points (double[6], x1,y1,...) that
# identify three corners of the parallelograms assuming implicit
# fourth point. The arguments are arrays of double[6] mapped
# to x1,y1, x2,y2, x3,y3  where the coordinates are:
#        *-----------------*
#       /          (x3,y3)/
#      /                 /
#     /(x1,y1)   (x2,y2)/
#    *-----------------*
proc parlToParl*(src, dst: openArray[float64]): TransAffine =
  result.sx  = src[2] - src[0]
  result.shy = src[3] - src[1]
  result.shx = src[4] - src[0]
  result.sy  = src[5] - src[1]
  result.tx  = src[0]
  result.ty  = src[1]

  let tmp = initTransAffine(dst[2] - dst[0],
    dst[3] - dst[1],
    dst[4] - dst[0],
    dst[5] - dst[1],
    dst[0], dst[1])

  result.invert()
  result.multiply(tmp)

proc rectToParl*(x1, y1, x2, y2: float64, parl: openArray[float64]): TransAffine =
  var src: array[6, float64]
  src[0] = x1
  src[1] = y1
  src[2] = x2
  src[3] = y1
  src[4] = x2
  src[5] = y2
  result = parlToParl(src, parl)

proc parlToRect*(parl: openArray[float64], x1, y1, x2, y2: float64): TransAffine =
  var dst: array[6, float64]
  dst[0] = x1
  dst[1] = y1
  dst[2] = x2
  dst[3] = y1
  dst[4] = x2
  dst[5] = y2
  result = parlToParl(parl, dst)

# Identity matrix
proc initTransAffine*(): TransAffine =
  result = initTransAffine(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

# Custom matrix from m[6]
proc initTransAffine*(m: openArray[float64]): TransAffine =
  result = initTransAffine(m[0], m[1], m[2], m[3], m[4], m[5])

# Rectangle to a parallelogram.
proc initTransAffine*(x1, y1, x2, y2: float64, parl: openArray[float64]): TransAffine =
  rectToParl(x1, y1, x2, y2, parl)

# Parallelogram to a rectangle.
proc initTransAffine*(parl: openArray[float64], x1, y1, x2, y2: float64): TransAffine =
  parlToRect(parl, x1, y1, x2, y2)

# Arbitrary parallelogram transformation.
proc initTransAffine*(src, dst: openArray[float64]): TransAffine =
  parlToParl(src, dst)

proc reset*(a: var TransAffine) =
  a.sx = 1.0
  a.sy = 1.0
  a.shy = 0.0
  a.shx = 0.0
  a.tx = 0.0
  a.ty = 0.0

proc transform*(a: TransAffine, x, y: var float64) {.inline.} =
  let tmp = x
  x = tmp * a.sx + y * a.shx + a.tx
  y = tmp * a.shy + y * a.sy  + a.ty

proc transform2x2*(a: TransAffine, x, y: var float64) {.inline.} =
  let tmp = x
  x = tmp * a.sx  + y * a.shx
  y = tmp * a.shy + y * a.sy

proc inverseTransform*(z: TransAffine, x, y: var float64) {.inline.} =
  let d = z.determinantReciprocal()
  let a = (x - z.tx) * d
  let b = (y - z.ty) * d
  x = a * z.sy - b * z.shx
  y = b * z.sx - a * z.shy

# Get the average scale (by X and Y).
# Basically used to calculate the approximation_scale when
# decomposinting curves into line segments.
proc scale*(a: TransAffine): float64 {.inline.} =
  let
    x = 0.707106781 * a.sx  + 0.707106781 * a.shx
    y = 0.707106781 * a.shy + 0.707106781 * a.sy
  result = sqrt(x*x + y*y)

proc translate*(a: var TransAffine, x, y: float64) {.inline.} =
  a.tx += x
  a.ty += y

proc rotate*(a: var TransAffine, v: float64) {.inline.} =
  let
    ca = cos(v)
    sa = sin(v)
    t0 = a.sx  * ca - a.shy * sa
    t2 = a.shx * ca - a.sy * sa
    t4 = a.tx  * ca - a.ty * sa
  a.shy = a.sx  * sa + a.shy * ca
  a.sy  = a.shx * sa + a.sy * ca
  a.ty  = a.tx  * sa + a.ty * ca
  a.sx  = t0
  a.shx = t2
  a.tx  = t4

proc scale*(a: var TransAffine, s: float64) {.inline.} =
  let m = s # Possible hint for the optimizer
  a.sx  *= m
  a.shx *= m
  a.tx  *= m
  a.shy *= m
  a.sy  *= m
  a.ty  *= m

proc scale*(a: var TransAffine, x, y: float64) {.inline.} =
  let mm0 = x # Possible hint for the optimizer
  let mm3 = y
  a.sx  *= mm0
  a.shx *= mm0
  a.tx  *= mm0
  a.shy *= mm3
  a.sy  *= mm3
  a.ty  *= mm3

proc premultiply*(a: var TransAffine, m: TransAffine) {.inline.} =
  var t = m
  t.multiply(a)
  a = t

proc multiplyInv*(a: var TransAffine, m: TransAffine) {.inline.} =
  var t = m
  t.invert()
  a.multiply(t)

proc premultiplyInv*(a: var TransAffine, m: TransAffine) {.inline.} =
  var t = m
  t.invert()
  t.multiply(a)
  a = t

# Mirroring around X
proc flipX*(a: var TransAffine) {.inline.} =
  a.sx  = -a.sx
  a.shy = -a.shy
  a.tx  = -a.tx

# Mirroring around Y
proc flipY*(a: var TransAffine) {.inline.} =
  a.shx = -a.shx
  a.sy  = -a.sy
  a.ty  = -a.ty

# Store matrix to an array [6] of double
proc storeTo*(a: TransAffine, m: var openArray[float64]) =
  m[0] = a.sx
  m[1] = a.shy
  m[2] = a.shx
  m[3] = a.sy
  m[4] = a.tx
  m[5] = a.ty

# Load matrix from an array [6] of double
proc loadFrom*(a: var TransAffine, m: openArray[float64]) =
  a.sx  = m[0]
  a.shy = m[1]
  a.shx = m[2]
  a.sy  = m[3]
  a.tx  = m[4]
  a.ty  = m[5]

# Multiply the matrix by another one
proc `*=`*(a: var TransAffine, m: TransAffine) {.inline.} =
  a.multiply(m)

# Multiply the matrix by inverse of another one
proc `/=`*(a: var TransAffine, m: TransAffine) {.inline.} =
  a.multiplyInv(m)

# Multiply the matrix by another one and return
# the result in a separete matrix.
proc `*`*(a, m: TransAffine): TransAffine {.inline.} =
  result = a
  result.multiply(m)

# Multiply the matrix by inverse of another one
# and return the result in a separete matrix.
proc `/`*(a, m: TransAffine): TransAffine {.inline.} =
  result = a
  result.multiplyInv(m)

# Calculate and return the inverse matrix
proc `~`*(a: TransAffine): TransAffine {.inline.} =
  result = a
  result.invert()

proc isIdentity*(a: TransAffine, epsilon: float64): bool =
  result = isEqualEps(a.sx,  1.0, epsilon) and
           isEqualEps(a.shy, 0.0, epsilon) and
           isEqualEps(a.shx, 0.0, epsilon) and
           isEqualEps(a.sy,  1.0, epsilon) and
           isEqualEps(a.tx,  0.0, epsilon) and
           isEqualEps(a.ty,  0.0, epsilon)

proc isValid*(a: TransAffine, epsilon: float64): bool =
  result = abs(a.sx) > epsilon and abs(a.sy) > epsilon

proc isEqual(a, m: TransAffine, epsilon: float64): bool =
  result = isEqualEps(a.sx,  m.sx,  epsilon) and
           isEqualEps(a.shy, m.shy, epsilon) and
           isEqualEps(a.shx, m.shx, epsilon) and
           isEqualEps(a.sy,  m.sy,  epsilon) and
           isEqualEps(a.tx,  m.tx,  epsilon) and
           isEqualEps(a.ty,  m.ty,  epsilon)

# Equal operator with default epsilon
proc `==`*(a, m: TransAffine): bool =
  a.isEqual(m, affineEpsilon)

# Not Equal operator with default epsilon
proc `!=`*(a, m: TransAffine): bool =
  result = not a.isEqual(m, affineEpsilon)

# Determine the major parameters. Use with caution considering
# possible degenerate cases.
proc scalingAbs*(a: TransAffine, x, y: var float64) {.inline.} =
  # Used to calculate scaling coefficients in image resampling.
  # When there is considerable shear this method gives us much
  # better estimation than just sx, sy.
  x = sqrt(a.sx  * a.sx  + a.shx * a.shx)
  y = sqrt(a.shy * a.shy + a.sy  * a.sy)

proc translation*(a: TransAffine, dx, dy: var float64) {.inline.} =
  dx = a.tx
  dy = a.ty

proc rotation(a: TransAffine): float64 =
  var
    x1 = 0.0
    y1 = 0.0
    x2 = 1.0
    y2 = 0.0
  a.transform(x1, y1)
  a.transform(x2, y2)
  result = arctan2(y2-y1, x2-x1)

proc transAffineRotation*(a: float64): TransAffine
proc scaling*(a: TransAffine, x, y: var float64)  =
  var
    x1 = 0.0
    y1 = 0.0
    x2 = 1.0
    y2 = 1.0
  var t = a
  t *= transAffineRotation(-a.rotation())
  t.transform(x1, y1)
  t.transform(x2, y2)
  x = x2 - x1
  y = y2 - y1

proc transAffineTranslation*(x, y: float64): TransAffine =
  result = initTransAffine(1.0, 0.0, 0.0, 1.0, x, y)

proc transAffineRotation*(a: float64): TransAffine =
  result = initTransAffine(cos(a), sin(a), -sin(a), cos(a), 0.0, 0.0)

proc transAffineScaling*(x, y: float64): TransAffine =
  result = initTransAffine(x, 0.0, 0.0, y, 0.0, 0.0)

proc transAffineScaling*(s: float64): TransAffine =
  result = initTransAffine(s, 0.0, 0.0, s, 0.0, 0.0)

proc transAffineSkewing*(x, y: float64): TransAffine =
  result = initTransAffine(1.0, tan(y), tan(x), 1.0, 0.0, 0.0)

proc transAffineLineSegment*(x1, y1, x2, y2, dist: float64): TransAffine =
  let
    dx = x2 - x1
    dy = y2 - y1

  result = initTransAffine()

  if dist > 0.0:
    result.multiply(transAffineScaling(sqrt(dx * dx + dy * dy) / dist))
    result.multiply(transAffineRotation(arctan2(dy, dx)))
    result.multiply(transAffineTranslation(x1, y1))

proc transAffineReflectionUnit(ux, uy: float64): TransAffine =
  result = initTransAffine(2.0 * ux * ux - 1.0,
    2.0 * ux * uy,
    2.0 * ux * uy,
    2.0 * uy * uy - 1.0,
    0.0, 0.0)

proc transAffineReflection*(a: float64): TransAffine =
  result = transAffineReflectionUnit(cos(a), sin(a))

proc transAffineReflection*(x, y: float64): TransAffine =
  result = transAffineReflectionUnit(x / sqrt(x * x + y * y), y / sqrt(x * x + y * y))
