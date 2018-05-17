import basics, simul_eq

type
  TransBilinear* = object
    mMtx: array[4*2, float64]
    mValid: bool

proc quadToQuad*(self: var TransBilinear, src, dst: openArray[float64])
proc rectToQuad*(self: var TransBilinear, x1, y1, x2, y2: float64, quad: openArray[float64])
proc quadToRect*(self: var TransBilinear, quad: openArray[float64], x1, y1, x2, y2: float64)

proc initTransBilinear*(): TransBilinear =
  result.mValid = false

# Arbitrary quadrangle transformations
proc initTransBilinear*(src, dst: openArray[float64]): TransBilinear =
  result.quadToQuad(src, dst)

# Direct transformations
proc initTransBilinear*(x1, y1, x2, y2: float64, quad: openArray[float64]): TransBilinear =
  result.rectToQuad(x1, y1, x2, y2, quad)

# Reverse transformations
proc initTransBilinear*(quad: openArray[float64], x1, y1, x2, y2: float64): TransBilinear =
  result.quadToRect(quad, x1, y1, x2, y2)

simulEq(solve, 4, 2)

# Set the transformations using two arbitrary quadrangles.
proc quadToQuad(self: var TransBilinear, src, dst: openArray[float64]) =
  var
    left: array[4 * 4, float64]
    right: array[4 * 2, float64]

  for i in 0..<4:
    let
      ix = i * 2
      iy = ix + 1
    left[i * 4 + 0] = 1.0
    left[i * 4 + 1] = src[ix] * src[iy]
    left[i * 4 + 2] = src[ix]
    left[i * 4 + 3] = src[iy]

    right[i * 2 + 0] = dst[ix]
    right[i * 2 + 1] = dst[iy]

  self.mValid = solve(left, right, self.mMtx)

# Set the direct transformations, i.e., rectangle -> quadrangle
proc rectToQuad(self: var TransBilinear, x1, y1, x2, y2: float64, quad: openArray[float64]) =
  var src: array[8, float64]
  src[0] = x1; src[6] = x1
  src[2] = x2; src[4] = x2
  src[1] = y1; src[3] = y1
  src[5] = y2; src[7] = y2
  self.quadToQuad(src, quad)

# Set the reverse transformations, i.e., quadrangle -> rectangle
proc quadToRect(self: var TransBilinear, quad: openArray[float64], x1, y1, x2, y2: float64) =
  var dst: array[8, float64]
  dst[0] = x1; dst[6] = x1
  dst[2] = x2; dst[4] = x2
  dst[1] = y1; dst[3] = y1
  dst[5] = y2; dst[7] = y2
  self.quadToQuad(quad, dst)

# Check if the equations were solved successfully
proc isValid*(self: TransBilinear): bool =
  self.mValid

# Transform a point (x, y)
proc transform*(self: TransBilinear, x, y: var float64) =
  let
    tx = x
    ty = y
    xy = tx * ty

  x = self.mMtx[0 * 2 + 0] + self.mMtx[1 * 2 + 0] * xy + self.mMtx[2 * 2 + 0] * tx + self.mMtx[3 * 2 + 0] * ty
  y = self.mMtx[0 * 2 + 1] + self.mMtx[1 * 2 + 1] * xy + self.mMtx[2 * 2 + 1] * tx + self.mMtx[3 * 2 + 1] * ty

type
  IteratorXBilinear* = object
    incX, incY: float64
    x, y: float64

proc initIteratorXBilinear(tx, ty, step: float64, m: array[4 * 2, float64]): IteratorXBilinear =
  result.incX = m[1 * 2 + 0] * step * ty + m[2 * 2 + 0] * step
  result.incY = m[1 * 2 + 1] * step * ty + m[2 * 2 + 1] * step
  result.x = m[0 * 2 + 0] + m[1 * 2 + 0] * tx * ty + m[2 * 2 + 0] * tx + m[3 * 2 + 0] * ty
  result.y = m[0 * 2 + 1] + m[1 * 2 + 1] * tx * ty + m[2 * 2 + 1] * tx + m[3 * 2 + 1] * ty

proc inc*(self: var IteratorXBilinear) =
  self.x += self.incX
  self.y += self.incY

proc begin*(self: TransBilinear, x, y, step: float64): IteratorXBilinear =
  initIteratorXBilinear(x, y, step, self.mMtx)
