import agg_basics, agg_trans_affine, math

type
  TransPerspective* = object
    sx, shy, w0, shx, sy, w1, tx, ty, w2: float64

# Identity matrix
proc initTransPerspective*(): TransPerspective =
  result.sx  = 1; result.shy = 0; result.w0 = 0
  result.shx = 0; result.sy  = 1; result.w1 = 0
  result.tx  = 0; result.ty  = 0; result.w2 = 1

# Custom matrix
proc initTransPerspective*(v0, v1, v2, v3, v4, v5, v6, v7, v8: float64): TransPerspective =
  result.sx  = v0; result.shy = v1; result.w0 = v2
  result.shx = v3; result.sy  = v4; result.w1 = v5
  result.tx  = v6; result.ty  = v7; result.w2 = v8

# Custom matrix from m[9]
proc initTransPerspective*(m: ptr float64): TransPerspective =
  result.sx  = m[0]; result.shy = m[1]; result.w0 = m[2]
  result.shx = m[3]; result.sy  = m[4]; result.w1 = m[5]
  result.tx  = m[6]; result.ty  = m[7]; result.w2 = m[8]

# From affine
proc initTransPerspective*(a: TransAffine): TransPerspective =
  result.sx  = a.sx ; result.shy = a.shy; result.w0 = 0
  result.shx = a.shx; result.sy  = a.sy ; result.w1 = 0
  result.tx  = a.tx ; result.ty  = a.ty ; result.w2 = 1

# Rectangle to quadrilateral
proc initTransPerspective*(x1, y1, x2, y2: float64, quad: ptr float64): TransPerspective

# Quadrilateral to rectangle
proc initTransPerspective*(quad: ptr float64, x1, y1, x2, y2: float64): TransPerspective

# Arbitrary quadrilateral transformations
proc initTransPerspective*(src, dst: ptr float64): TransPerspective

#-------------------------------------- Quadrilateral transformations
# The arguments are double[8] that are mapped to quadrilaterals:
# x1,y1, x2,y2, x3,y3, x4,y4
proc quadToQuad*(self: var TransPerspective, qs, qd: ptr float64): bool

proc rectToQuad*(self: var TransPerspective, x1, y1, x2, y2: float64, q: ptr float64): bool

proc quadToRect*(self: var TransPerspective, q: ptr float64, x1, y1, x2, y2: float64): bool

# Map square (0,0,1,1) to the quadrilateral and vice versa
proc squareToQuad*(self: var TransPerspective, q: ptr float64): bool
proc quadToSquare*(self: var TransPerspective, q: ptr float64): bool


#--------------------------------------------------------- Operations
# Reset - load an identity matrix
proc reset*(self: var TransPerspective)

# Invert matrix. Returns false in degenerate of
proc invert*(self: var TransPerspective): bool

# Direct transformations operations
proc translate*(self: var TransPerspective, x, y: float64) {.inline.}
proc rotate*(self: var TransPerspective, a: float64) {.inline.}
proc scale*(self: var TransPerspective, s: float64) {.inline.}
proc scale*(self: var TransPerspective, x, y: float64) {.inline.}

# Multiply the matrix by another one
proc multiply*(self: var TransPerspective, a: TransPerspective)

# Multiply "m" by "this" and assign the result to "this"
proc premultiply*(self: var TransPerspective, b: TransPerspective)

# Multiply matrix to inverse of another one
proc multiplyInv*(self: var TransPerspective, m: TransPerspective)

# Multiply inverse of "m" by "this" and assign the result to "this"
proc premultiplyInv*(self: var TransPerspective, m: TransPerspective)

# Multiply the matrix by another one
proc multiply*(self: var TransPerspective, a: TransAffine)

# Multiply "m" by "this" and assign the result to "this"
proc premultiply*(self: var TransPerspective, b: TransAffine)

# Multiply the matrix by inverse of another one
proc multiplyInv*(self: var TransPerspective, m: TransAffine)

# Multiply inverse of "m" by "this" and assign the result to "this"
proc premultiplyInv*(self: var TransPerspective, m: TransAffine)

# Load/Store
proc storeTo*(self: TransPerspective, m: ptr float64) {.inline.}
proc loadFrom*(self: var TransPerspective, m: ptr float64) {.inline.}

# Operators
# Multiply the matrix by another one
proc `*=`*(self: var TransPerspective, m: TransPerspective) {.inline.} =
  self.multiply(m)

proc `*=`*(self: var TransPerspective, m: TransAffine) {.inline.} =
  self.multiply(m)

# Multiply the matrix by inverse of another one
proc `/=`*(self: var TransPerspective, m: TransPerspective) {.inline.} =
  self.multiplyInv(m)

proc `/=`*(self: var TransPerspective, m: TransAffine) {.inline.} =
  self.multiplyInv(m)

# Multiply the matrix by another one and return
# the result in a separete matrix.
proc `*`*(self: TransPerspective, m: TransPerspective): TransPerspective {.inline.} =
  result = self
  result.multiply(m)

proc `*`*(self: TransPerspective, m: TransAffine): TransPerspective {.inline.} =
  result = self
  result.multiply(m)

# Multiply the matrix by inverse of another one
# and return the result in a separete matrix.
proc `/`*(self: TransPerspective, m: TransPerspective): TransPerspective {.inline.} =
  result = self
  result.multiplyInv(m)

proc `/`*(self: var TransPerspective, m: var TransAffine): TransPerspective {.inline.} =
  result = self
  result.multiplyInv(m)

# Calculate and return the inverse matrix
proc `~`*(self: TransPerspective): TransPerspective {.inline.} =
  result = self
  discard result.invert()

proc isEqual*(self: TransPerspective, m: TransPerspective, epsilon: float64): bool {.inline.}

# Equal operator with default epsilon
proc `==`*(self: TransPerspective, m: TransPerspective): bool {.inline.} =
  self.isEqual(m, affineEpsilon)

# Not Equal operator with default epsilon
proc `!=`*(self: TransPerspective, m: TransPerspective): bool {.inline.} =
  result = not self.isEqual(m, affineEpsilon)


#---------------------------------------------------- Transformations
# Direct transformation of x and y
proc transform*(self: TransPerspective, px, py: var float64) {.inline.}

    # Direct transformation of x and y, affine part only
proc transformAffine*(self: TransPerspective, x, y: var float64) {.inline.}

    # Direct transformation of x and y, 2x2 matrix only, no translation
proc transform2x2*(self: TransPerspective, x, y: var float64) {.inline.}

    # Inverse transformation of x and y. It works slow because
    # it explicitly inverts the matrix on every call. For massive
    # operations it's better to invert() the matrix and then use
    # direct transformations.
proc inverseTransform*(self: TransPerspective, x, y: var float64): TransPerspective  {.inline.}

type
  IteratorX* = object
    den, denStep: float64
    nomX, nomXstep: float64
    nomY, nomYstep: float64
    x*, y*: float64

proc initIteratorX(px, py, step: float64, m: TransPerspective): IteratorX =
  result.den      = px * m.w0 + py * m.w1 + m.w2
  result.denStep  = m.w0 * step
  result.nomX     = px * m.sx + py * m.shx + m.tx
  result.nomXstep = step * m.sx
  result.nomY     = px * m.shy + py * m.sy + m.ty
  result.nomYstep = step * m.shy
  result.x        = result.nomX / result.den
  result.y        = result.nomY / result.den

proc inc*(self: var IteratorX) =
  self.den  += self.denStep
  self.nomX += self.nomXstep
  self.nomY += self.nomYstep

  var d = 1.0 / self.den
  self.x = self.nomX * d
  self.y = self.nomY * d

proc begin*(self: TransPerspective, x, y, step: float64): IteratorX =
  initIteratorX(x, y, step, self)

proc squareToQuad(self: var TransPerspective, q: ptr float64): bool =
  var
    dx = q[0] - q[2] + q[4] - q[6]
    dy = q[1] - q[3] + q[5] - q[7]

  if dx == 0.0 and dy == 0.0:
    # Affine of (parallelogram)
    #---------------
    self.sx  = q[2] - q[0]
    self.shy = q[3] - q[1]
    self.w0  = 0.0
    self.shx = q[4] - q[2]
    self.sy  = q[5] - q[3]
    self.w1  = 0.0
    self.tx  = q[0]
    self.ty  = q[1]
    self.w2  = 1.0
  else:
    var
      dx1 = q[2] - q[4]
      dy1 = q[3] - q[5]
      dx2 = q[6] - q[4]
      dy2 = q[7] - q[5]
      den = dx1 * dy2 - dx2 * dy1
    if den == 0.0:
      # Singular of
      #---------------
      self.sx = 0.0
      self.shy = 0.0
      self.w0 = 0.0
      self.shx = 0.0
      self.sy = 0.0
      self.w1 = 0.0
      self.tx = 0.0
      self.ty = 0.0
      self.w2 = 0.0
      return false
    # General of
    #---------------
    var
      u = (dx * dy2 - dy * dx2) / den
      v = (dy * dx1 - dx * dy1) / den
    self.sx  = q[2] - q[0] + u * q[2]
    self.shy = q[3] - q[1] + u * q[3]
    self.w0  = u
    self.shx = q[6] - q[0] + v * q[6]
    self.sy  = q[7] - q[1] + v * q[7]
    self.w1  = v
    self.tx  = q[0]
    self.ty  = q[1]
    self.w2  = 1.0
  result = true

proc invert*(self: var TransPerspective): bool =
  var
    d0 = self.sy  * self.w2 - self.w1  * self.ty
    d1 = self.w0  * self.ty - self.shy * self.w2
    d2 = self.shy * self.w1 - self.w0  * self.sy
    d  = self.sx  * d0 + self.shx * d1 + self.tx * d2
  if d == 0.0:
    self.sx = 0.0
    self.shy = 0.0
    self.w0 = 0.0
    self.shx = 0.0
    self.sy = 0.0
    self.w1 = 0.0
    self.tx = 0.0
    self.ty = 0.0
    self.w2 = 0.0
    return false

  d = 1.0 / d
  var a = self
  self.sx  = d * d0
  self.shy = d * d1
  self.w0  = d * d2
  self.shx = d * (a.w1  * a.tx  - a.shx * a.w2)
  self.sy  = d * (a.sx  * a.w2  - a.w0  * a.tx)
  self.w1  = d * (a.w0  * a.shx - a.sx  * a.w1)
  self.tx  = d * (a.shx * a.ty  - a.sy  * a.tx)
  self.ty  = d * (a.shy * a.tx  - a.sx  * a.ty)
  self.w2  = d * (a.sx  * a.sy  - a.shy * a.shx)
  result = true

proc quadToSquare(self: var TransPerspective, q: ptr float64): bool =
  if not self.squareToQuad(q): return false
  discard self.invert()
  result = true

proc quadToQuad(self: var TransPerspective, qs, qd: ptr float64): bool =
  var p: TransPerspective
  if not self.quadToSquare(qs): return false
  if not p.squareToQuad(qd): return false
  self.multiply(p)
  result = true

proc rectToQuad(self: var TransPerspective, x1, y1, x2, y2: float64, q: ptr float64): bool =
  var r: array[8, float64]
  r[0] = x1; r[6] = x1
  r[2] = x2; r[4] = x2
  r[1] = y1; r[3] = y1
  r[5] = y2; r[7] = y2
  result = self.quadToQuad(r[0].addr, q)

proc quadToRect(self: var TransPerspective, q: ptr float64, x1, y1, x2, y2: float64): bool =
  var r: array[8, float64]
  r[0] = x1; r[6] = x1
  r[2] = x2; r[4] = x2
  r[1] = y1; r[3] = y1
  r[5] = y2; r[7] = y2
  result = self.quadToQuad(q, r[0].addr)

proc initTransPerspective(x1, y1, x2, y2: float64, quad: ptr float64): TransPerspective =
  discard result.rectToQuad(x1, y1, x2, y2, quad)

proc initTransPerspective(quad: ptr float64, x1, y1, x2, y2: float64): TransPerspective =
  discard result.quadToRect(quad, x1, y1, x2, y2)

proc initTransPerspective(src, dst: ptr float64): TransPerspective =
  discard result.quadToQuad(src, dst)

proc reset*(self: var TransPerspective) =
  self.sx  = 1; self.shy = 0; self.w0 = 0
  self.shx = 0; self.sy  = 1; self.w1 = 0
  self.tx  = 0; self.ty  = 0; self.w2 = 1

proc multiply(self: var TransPerspective, a: TransPerspective) =
  var b = self
  self.sx  = a.sx  * b.sx  + a.shx * b.shy + a.tx * b.w0
  self.shx = a.sx  * b.shx + a.shx * b.sy  + a.tx * b.w1
  self.tx  = a.sx  * b.tx  + a.shx * b.ty  + a.tx * b.w2
  self.shy = a.shy * b.sx  + a.sy  * b.shy + a.ty * b.w0
  self.sy  = a.shy * b.shx + a.sy  * b.sy  + a.ty * b.w1
  self.ty  = a.shy * b.tx  + a.sy  * b.ty  + a.ty * b.w2
  self.w0  = a.w0  * b.sx  + a.w1  * b.shy + a.w2 * b.w0
  self.w1  = a.w0  * b.shx + a.w1  * b.sy  + a.w2 * b.w1
  self.w2  = a.w0  * b.tx  + a.w1  * b.ty  + a.w2 * b.w2

proc multiply(self: var TransPerspective, a: TransAffine) =
  var b = self
  self.sx  = a.sx  * b.sx  + a.shx * b.shy + a.tx * b.w0
  self.shx = a.sx  * b.shx + a.shx * b.sy  + a.tx * b.w1
  self.tx  = a.sx  * b.tx  + a.shx * b.ty  + a.tx * b.w2
  self.shy = a.shy * b.sx  + a.sy  * b.shy + a.ty * b.w0
  self.sy  = a.shy * b.shx + a.sy  * b.sy  + a.ty * b.w1
  self.ty  = a.shy * b.tx  + a.sy  * b.ty  + a.ty * b.w2

proc premultiply*(self: var TransPerspective, b: TransPerspective) =
  var a = self
  self.sx  = a.sx  * b.sx  + a.shx * b.shy + a.tx * b.w0
  self.shx = a.sx  * b.shx + a.shx * b.sy  + a.tx * b.w1
  self.tx  = a.sx  * b.tx  + a.shx * b.ty  + a.tx * b.w2
  self.shy = a.shy * b.sx  + a.sy  * b.shy + a.ty * b.w0
  self.sy  = a.shy * b.shx + a.sy  * b.sy  + a.ty * b.w1
  self.ty  = a.shy * b.tx  + a.sy  * b.ty  + a.ty * b.w2
  self.w0  = a.w0  * b.sx  + a.w1  * b.shy + a.w2 * b.w0
  self.w1  = a.w0  * b.shx + a.w1  * b.sy  + a.w2 * b.w1
  self.w2  = a.w0  * b.tx  + a.w1  * b.ty  + a.w2 * b.w2

proc premultiply*(self: var TransPerspective, b: TransAffine) =
  var a = self
  self.sx  = a.sx  * b.sx  + a.shx * b.shy
  self.shx = a.sx  * b.shx + a.shx * b.sy
  self.tx  = a.sx  * b.tx  + a.shx * b.ty  + a.tx
  self.shy = a.shy * b.sx  + a.sy  * b.shy
  self.sy  = a.shy * b.shx + a.sy  * b.sy
  self.ty  = a.shy * b.tx  + a.sy  * b.ty  + a.ty
  self.w0  = a.w0  * b.sx  + a.w1  * b.shy
  self.w1  = a.w0  * b.shx + a.w1  * b.sy
  self.w2  = a.w0  * b.tx  + a.w1  * b.ty  + a.w2

proc multiplyInv(self: var TransPerspective, m: TransPerspective) =
  var t = m
  discard t.invert()
  self.multiply(t)

proc multiplyInv(self: var TransPerspective, m: TransAffine) =
  var t = m
  t.invert()
  self.multiply(t)

proc premultiplyInv*(self: var TransPerspective, m: TransPerspective) =
  var t = m
  discard t.invert()
  t.multiply(self)

proc premultiplyInv*(self: var TransPerspective, m: TransAffine) =
  var t = initTransPerspective(m)
  discard t.invert()
  t.multiply(self)

proc translate*(self: var TransPerspective, x, y: float64) =
  self.tx += x
  self.ty += y

proc rotate*(self: var TransPerspective, a: float64) =
  self.multiply(transAffineRotation(a))

proc scale*(self: var TransPerspective, s: float64) =
  self.multiply(transAffineScaling(s))

proc scale*(self: var TransPerspective, x, y: float64) =
  self.multiply(transAffineScaling(x, y))

proc transform(self: TransPerspective, px, py: var float64) =
  var
    x = px
    y = py
    m = 1.0 / (x*self.w0 + y*self.w1 + self.w2)
  px = m * (x*self.sx  + y*self.shx + self.tx)
  py = m * (x*self.shy + y*self.sy  + self.ty)

proc transformAffine(self: TransPerspective, x, y: var float64) =
  var tmp = x
  x = tmp * self.sx  + y * self.shx + self.tx
  y = tmp * self.shy + y * self.sy  + self.ty

proc transform2x2(self: TransPerspective, x, y: var float64) =
  var tmp = x
  x = tmp * self.sx  + y * self.shx
  y = tmp * self.shy + y * self.sy

proc inverseTransform(self: TransPerspective, x, y: var float64): TransPerspective  =
  var t = self
  if t.invert():
    t.transform(x, y)
  result = t

proc storeTo(self: TransPerspective, m: ptr float64) =
  var m = m
  m[] = self.sx; inc m; m[] = self.shy; inc m; m[] = self.w0; inc m
  m[] = self.shx;inc m; m[] = self.sy;  inc m; m[] = self.w1; inc m
  m[] = self.tx; inc m; m[] = self.ty;  inc m; m[] = self.w2

proc loadFrom(self: var TransPerspective, m: ptr float64) =
  var m = m
  self.sx  = m[]; inc m; self.shy = m[]; inc m; self.w0 = m[]; inc m
  self.shx = m[]; inc m; self.sy  = m[]; inc m; self.w1 = m[]; inc m
  self.tx  = m[]; inc m; self.ty  = m[]; inc m; self.w2 = m[]

proc fromAffine*(self: var TransPerspective, a: TransAffine) {.inline.} =
  self.sx  = a.sx;  self.shy = a.shy; self.w0 = 0
  self.shx = a.shx; self.sy  = a.sy;  self.w1 = 0
  self.tx  = a.tx;  self.ty  = a.ty;  self.w2 = 1

proc determinant*(self: TransPerspective): float64 {.inline.} =
  result = self.sx  * (self.sy  * self.w2 - self.ty  * self.w1) +
           self.shx * (self.ty  * self.w0 - self.shy * self.w2) +
           self.tx  * (self.shy * self.w1 - self.sy  * self.w0)

proc determinantReciprocal*(self: TransPerspective): float64 {.inline.} =
  result = 1.0 / self.determinant()

proc isValid*(self: TransPerspective, epsilon: float64): bool {.inline.} =
  result = abs(self.sx) > epsilon and abs(self.sy) > epsilon and abs(self.w2) > epsilon

proc isIdentity*(self: TransPerspective, epsilon: float64): bool {.inline.} =
  result = isEqualEps(self.sx,  1.0, epsilon) and
           isEqualEps(self.shy, 0.0, epsilon) and
           isEqualEps(self.w0,  0.0, epsilon) and
           isEqualEps(self.shx, 0.0, epsilon) and
           isEqualEps(self.sy,  1.0, epsilon) and
           isEqualEps(self.w1,  0.0, epsilon) and
           isEqualEps(self.tx,  0.0, epsilon) and
           isEqualEps(self.ty,  0.0, epsilon) and
           isEqualEps(self.w2,  1.0, epsilon)

proc isEqual(self: TransPerspective, m: TransPerspective, epsilon: float64): bool =
  result = isEqualEps(self.sx,  m.sx,  epsilon) and
           isEqualEps(self.shy, m.shy, epsilon) and
           isEqualEps(self.w0,  m.w0,  epsilon) and
           isEqualEps(self.shx, m.shx, epsilon) and
           isEqualEps(self.sy,  m.sy,  epsilon) and
           isEqualEps(self.w1,  m.w1,  epsilon) and
           isEqualEps(self.tx,  m.tx,  epsilon) and
           isEqualEps(self.ty,  m.ty,  epsilon) and
           isEqualEps(self.w2,  m.w2,  epsilon)

proc scale*(self: TransPerspective): float64 {.inline.} =
  var
    x = 0.707106781 * self.sx  + 0.707106781 * self.shx
    y = 0.707106781 * self.shy + 0.707106781 * self.sy
  sqrt(x*x + y*y)

proc rotation*(self: TransPerspective): float64 {.inline.} =
  var
    x1 = 0.0
    y1 = 0.0
    x2 = 1.0
    y2 = 0.0
  self.transform(x1, y1)
  self.transform(x2, y2)
  arctan2(y2-y1, x2-x1)

proc translation*(self: TransPerspective, dx, dy: var float64) =
  dx = self.tx
  dy = self.ty

proc scaling*(self: TransPerspective, x, y: var float64) =
  var
    x1 = 0.0
    y1 = 0.0
    x2 = 1.0
    y2 = 1.0
    t = self

  t *= transAffineRotation(-self.rotation())
  t.transform(x1, y1)
  t.transform(x2, y2)
  x = x2 - x1
  y = y2 - y1

proc scalingAbs*(self: TransPerspective, x, y: var float64) =
  x = sqrt(self.sx  * self.sx  + self.shx * self.shx)
  y = sqrt(self.shy * self.shy + self.sy  * self.sy)

