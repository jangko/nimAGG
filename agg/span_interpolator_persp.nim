import trans_perspective, dda_line, basics, math

template spanInterpolatorPerspExact(name: untyped, SubpixelShift: int = 8) =
  type
    name* = object
      mTransDir: TransPerspective
      mTransInv: TransPerspective
      mIterator: IteratorXPersp
      mScaleX: Dda2LineInterpolator
      mScaleY: Dda2LineInterpolator

  template getSubPixelShift*(x: typedesc[name]): int = SubpixelShift
  template getSubPixelScale*(x: typedesc[name]): int = 1 shl SubPixelShift

  # Set the transformations using two arbitrary quadrangles.
  proc quadToQuad*(self: var name, src, dst: openArray[float64]) =
    discard self.mTransDir.quadToQuad(src, dst)
    discard self.mTransInv.quadToQuad(dst, src)

  # Set the direct transformations, i.e., rectangle -> quadrangle
  proc rectToQuad*(self: var name, x1, y1, x2, y2: float64, quad: openArray[float64]) =
    var src: array[8, float64]
    src[0] = x1; src[6] = x1
    src[2] = x2; src[4] = x2
    src[1] = y1; src[3] = y1
    src[5] = y2; src[7] = y2
    self.quadToQuad(src, quad)

  # Set the reverse transformations, i.e., quadrangle -> rectangle
  proc quadToRect*(self: var name, quad: openArray[float64],  x1, y1, x2, y2: float64) =
    var dst: array[8, float64]
    dst[0] = x1; dst[6] = x1
    dst[2] = x2; dst[4] = x2
    dst[1] = y1; dst[3] = y1
    dst[5] = y2; dst[7] = y2
    self.quadToQuad(quad, dst)

  # Arbitrary quadrangle transformations
  proc `init name`*(src, dst: openArray[float64]): name =
    result.quadToQuad(src, dst)

  # Direct transformations
  proc `init name`*(x1, y1, x2, y2: float64, quad: openArray[float64]): name =
    result.rectToQuad(x1, y1, x2, y2, quad)

  # Reverse transformations
  proc `init name`*(quad: openArray[float64], x1, y1, x2, y2: float64): name =
    result.quadToRect(quad, x1, y1, x2, y2)

  # Check if the equations were solved successfully
  proc isValid*(self: name): bool =
    self.mTransDir.isValid()

  proc begin*(self: var name, x, y: float64, len: int) =
    const
      subPixelShift = getSubPixelShift(name)
      subPixelScale = float64(getSubPixelScale(name))

    var
      x = x
      y = y

    self.mIterator = self.mTransDir.begin(x, y, 1.0)
    var
      xt = self.mIterator.x
      yt = self.mIterator.y
      dx, dy: float64
      delta = 1.0 / subPixelScale

    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)

    dx -= x
    dy -= y
    let sx1 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift
    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)

    dx -= x
    dy -= y
    let sy1 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    x += len.float64
    xt = x
    yt = y
    self.mTransDir.transform(xt, yt)

    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)

    dx -= x
    dy -= y
    let sx2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)

    dx -= x
    dy -= y
    let sy2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    self.mScaleX = initDda2LineInterpolator(sx1, sx2, len)
    self.mScaleY = initDda2LineInterpolator(sy1, sy2, len)

  proc resynchronize*(self: var name, xe, ye: float64, len: int) =
    const
      subPixelShift = getSubPixelShift(name)
      subPixelScale = float64(getSubPixelScale(name))

    var
      # Assume x1,y1 are equal to the ones at the previous end point
      sx1 = self.mScaleX.y()
      sy1 = self.mScaleY.y()

      # Calculate transformed coordinates at x2,y2
      xt = xe
      yt = ye

    self.mTransDir.transform(xt, yt)

    var
      delta = 1.0 / subPixelScale
      dx, dy: float64

    # Calculate scale by X at x2,y2
    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)

    dx -= xe
    dy -= ye
    let sx2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Calculate scale by Y at x2,y2
    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)

    dx -= xe
    dy -= ye
    let sy2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Initialize the interpolators
    self.mScaleX = initDda2LineInterpolator(sx1, sx2, len)
    self.mScaleY = initDda2LineInterpolator(sy1, sy2, len)

  proc inc*(self: var name) =
    inc self.mIterator
    inc self.mScaleX
    inc self.mScaleY

  proc coordinates*(self: name, x, y: var int) =
    const subPixelScale = getSubPixelScale(name)
    x = iround(self.mIterator.x * subPixelScale)
    y = iround(self.mIterator.y * subPixelScale)

  proc localScale*(self: name, x, y: var int) =
    x = self.mScaleX.y()
    y = self.mScaleY.y()

  proc transform*(self: name, x, y: var float64) =
    self.mTransDir.transform(x, y)

template spanInterpolatorPerspLerp(name: untyped, SubpixelShift: int = 8) =
  type
    name* = object
      mTransDir: TransPerspective
      mTransInv: TransPerspective
      mCoordX: Dda2LineInterpolator
      mCoordY: Dda2LineInterpolator
      mScaleX: Dda2LineInterpolator
      mScaleY: Dda2LineInterpolator

  template getSubPixelShift*(x: typedesc[name]): int = SubpixelShift
  template getSubPixelScale*(x: typedesc[name]): int = 1 shl SubPixelShift

# Set the transformations using two arbitrary quadrangles.
  proc quadToQuad*(self: var name, src, dst: openArray[float64]) =
    discard self.mTransDir.quadToQuad(src, dst)
    discard self.mTransInv.quadToQuad(dst, src)

  # Set the direct transformations, i.e., rectangle -> quadrangle
  proc rectToQuad*(self: var name, x1, y1, x2, y2: float64, quad: openArray[float64]) =
    var src: array[8, float64]
    src[0] = x1; src[6] = x1
    src[2] = x2; src[4] = x2
    src[1] = y1; src[3] = y1
    src[5] = y2; src[7] = y2
    self.quadToQuad(src, quad)

  # Set the reverse transformations, i.e., quadrangle -> rectangle
  proc quadToRect*(self: var name, quad: openArray[float64], x1, y1, x2, y2: float64) =
    var dst: array[8, float64]
    dst[0] = x1; dst[6] = x1
    dst[2] = x2; dst[4] = x2
    dst[1] = y1; dst[3] = y1
    dst[5] = y2; dst[7] = y2
    self.quadToQuad(quad, dst)

  # Arbitrary quadrangle transformations
  proc `init name`*(src, dst: openArray[float64]): name =
    result.quadToQuad(src, dst)

  # Direct transformations
  proc `init name`*(x1, y1, x2, y2: float64, quad: openArray[float64]): name =
    result.rectToQuad(x1, y1, x2, y2, quad)

  # Reverse transformations
  proc `init name`*(quad: openArray[float64], x1, y1, x2, y2: float64): name =
    result.quadToRect(quad, x1, y1, x2, y2)

  # Check if the equations were solved successfully
  proc isValid*(self: name): bool =
    self.mTransDir.isValid()

  proc begin*(self: var name, x, y: float64, len: int) =
    const
      subPixelShift = getSubPixelShift(name)
      subPixelScale = getSubPixelScale(name)

    var
      # Calculate transformed coordinates at x1,y1
      xt = x
      yt = y
      x = x
      y = y

    self.mTransDir.transform(xt, yt)
    var
      x1 = iround(xt * subPixelScale)
      y1 = iround(yt * subPixelScale)
      dx, dy: float64
      delta = 1.0 / float64(subPixelScale)

    # Calculate scale by X at x1,y1
    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)
    dx -= x
    dy -= y
    let sx1 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Calculate scale by Y at x1,y1
    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)
    dx -= x
    dy -= y
    let sy1 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Calculate transformed coordinates at x2,y2
    x += len.float64
    xt = x
    yt = y
    self.mTransDir.transform(xt, yt)
    let x2 = iround(xt * subPixelScale)
    let y2 = iround(yt * subPixelScale)

    # Calculate scale by X at x2,y2
    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)
    dx -= x
    dy -= y
    let sx2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Calculate scale by Y at x2,y2
    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)
    dx -= x
    dy -= y
    let sy2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Initialize the interpolators
    self.mCoordX = initDda2LineInterpolator(x1,  x2,  len)
    self.mCoordY = initDda2LineInterpolator(y1,  y2,  len)
    self.mScaleX = initDda2LineInterpolator(sx1, sx2, len)
    self.mScaleY = initDda2LineInterpolator(sy1, sy2, len)

  proc resynchronize*(self: var name, xe, ye: float64, len: int) =
    const
      subPixelShift = getSubPixelShift(name)
      subPixelScale = getSubPixelScale(name)

    var
      # Assume x1,y1 are equal to the ones at the previous end point
      x1  = self.mCoordX.y()
      y1  = self.mCoordY.y()
      sx1 = self.mScaleX.y()
      sy1 = self.mScaleY.y()

      # Calculate transformed coordinates at x2,y2
      xt = xe
      yt = ye

    self.mTransDir.transform(xt, yt)
    var
      x2 = iround(xt * subPixelScale)
      y2 = iround(yt * subPixelScale)
      delta = 1.0 / float64(subPixelScale)
      dx, dy: float64

    # Calculate scale by X at x2,y2
    dx = xt + delta
    dy = yt
    self.mTransInv.transform(dx, dy)
    dx -= xe
    dy -= ye
    let sx2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Calculate scale by Y at x2,y2
    dx = xt
    dy = yt + delta
    self.mTransInv.transform(dx, dy)
    dx -= xe
    dy -= ye
    let sy2 = uround(subPixelScale/sqrt(dx*dx + dy*dy)) shr subPixelShift

    # Initialize the interpolators
    self.mCoordX = initDda2LineInterpolator(x1,  x2,  len)
    self.mCoordY = initDda2LineInterpolator(y1,  y2,  len)
    self.mScaleX = initDda2LineInterpolator(sx1, sx2, len)
    self.mScaleY = initDda2LineInterpolator(sy1, sy2, len)

  proc inc*(self: var name) =
    inc self.mCoordX
    inc self.mCoordY
    inc self.mScaleX
    inc self.mScaleY

  proc coordinates*(self: name, x, y: var int) =
    x = self.mCoordX.y()
    y = self.mCoordY.y()

  proc localScale*(self: name, x, y: var int) =
    x = self.mScaleX.y()
    y = self.mScaleY.y()

  proc transform*(self: name, x, y: var float64) =
    self.mTransDir.transform(x, y)

spanInterpolatorPerspExact(SpanInterpolatorPerspExact)
spanInterpolatorPerspLerp(SpanInterpolatorPerspLerp)