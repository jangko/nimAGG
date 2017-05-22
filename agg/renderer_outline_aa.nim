import basics
import calc, line_aa_basics, dda_line, ellipse_bresenham
import renderer_base, gamma_functions, clip_liang_barsky

type
  DistanceInterpolator0* = object
    mDx, mDy, mDist: int

proc initDistanceInterpolator0*(x1, y1, x2, y2, x, y: int): DistanceInterpolator0 =
  result.mDx = lineMr(x2) - lineMr(x1)
  result.mDy = lineMr(y2) - lineMr(y1)
  result.mDist = (lineMr(x + lineSubpixelScale div 2) - lineMr(x2)) * result.mDy -
                 (lineMr(y + lineSubpixelScale div 2) - lineMr(y2)) * result.mDx

  result.mDx = result.mDx shl lineMrSubPixelShift
  result.mDy = result.mDy shl lineMrSubPixelShift

proc incX*(self: var DistanceInterpolator0) = self.mDist += self.mDy
proc dist*(self: DistanceInterpolator0): int = self.mDist

type
  DistanceInterpolator00* = object
    mDx1, mDy1, mDx2, mDy2: int
    mDist1, mDist2: int

proc initDistanceInterpolator00*(xc, yc, x1, y1, x2, y2, x, y: int): DistanceInterpolator00 =
  result.mDx1 = lineMr(x1) - lineMr(xc)
  result.mDy1 = lineMr(y1) - lineMr(yc)
  result.mDx2 = lineMr(x2) - lineMr(xc)
  result.mDy2 = lineMr(y2) - lineMr(yc)
  result.mDist1 = (lineMr(x + lineSubpixelScale div 2) - lineMr(x1)) * result.mDy1 -
                  (lineMr(y + lineSubpixelScale div 2) - lineMr(y1)) * result.mDx1
  result.mDist2 = (lineMr(x + lineSubpixelScale div 2) - lineMr(x2)) * result.mDy2 -
                  (lineMr(y + lineSubpixelScale div 2) - lineMr(y2)) * result.mDx2

  result.mDx1 = result.mDx1 shl lineMrSubPixelShift
  result.mDy1 = result.mDy1 shl lineMrSubPixelShift
  result.mDx2 = result.mDx2 shl lineMrSubPixelShift
  result.mDy2 = result.mDy2 shl lineMrSubPixelShift

proc incX*(self: var DistanceInterpolator00) =
  self.mDist1 += self.mDy1
  self.mDist2 += self.mDy2

proc dist1*(self: DistanceInterpolator00): int = self.mDist1
proc dist2*(self: DistanceInterpolator00): int = self.mDist2


type
  DistanceInterpolator1* = object
    mDx, mDy, mDist: int

proc initDistanceInterpolator1*(x1, y1, x2, y2, x, y: int): DistanceInterpolator1 =
  result.mDx = x2 - x1
  result.mDy = y2 - y1
  result.mDist = iround(float64(x + lineSubpixelScale div 2 - x2) * float64(result.mDy) -
                        float64(y + lineSubpixelScale div 2 - y2) * float64(result.mDx))

  result.mDx = result.mDx shl lineSubpixelShift
  result.mDy = result.mDy shl lineSubpixelShift

proc incX*(self: var DistanceInterpolator1) = self.mDist += self.mDy
proc decX*(self: var DistanceInterpolator1) = self.mDist -= self.mDy
proc incY*(self: var DistanceInterpolator1) = self.mDist -= self.mDx
proc decY*(self: var DistanceInterpolator1) = self.mDist += self.mDx

proc incX*(self: var DistanceInterpolator1, dy: int) =
  self.mDist += self.mDy
  if dy > 0: self.mDist -= self.mDx
  if dy < 0: self.mDist += self.mDx

proc decX*(self: var DistanceInterpolator1, dy: int) =
  self.mDist -= self.mDy
  if dy > 0: self.mDist -= self.mDx
  if dy < 0: self.mDist += self.mDx

proc incY*(self: var DistanceInterpolator1, dx: int) =
  self.mDist -= self.mDx
  if dx > 0: self.mDist += self.mDy
  if dx < 0: self.mDist -= self.mDy

proc decY*(self: var DistanceInterpolator1, dx: int) =
  self.mDist += self.mDx
  if dx > 0: self.mDist += self.mDy
  if dx < 0: self.mDist -= self.mDy

proc dist*(self: DistanceInterpolator1): int = self.mDist
proc dx*(self: DistanceInterpolator1): int = self.mDx
proc dy*(self: DistanceInterpolator1): int = self.mDy

type
  DistanceInterpolator2* = object
    mDx, mDy, mDxStart, mDyStart: int
    mDist, mDistStart: int

proc initDistanceInterpolator2*(x1, y1, x2, y2, sx, sy, x, y: int): DistanceInterpolator2 =
  result.mDx = x2 - x1
  result.mDy = y2 - y1
  result.mDxStart = lineMr(sx) - lineMr(x1)
  result.mDyStart = lineMr(sy) - lineMr(y1)
  result.mDist = iround(float64(x + lineSubpixelScale div 2 - x2) * float64(result.mDy) -
                        float64(y + lineSubpixelScale div 2 - y2) * float64(result.mDx))

  result.mDistStart = (lineMr(x + lineSubpixelScale div 2) - lineMr(sx)) * result.mDyStart -
                      (lineMr(y + lineSubpixelScale div 2) - lineMr(sy)) * result.mDxStart

  result.mDx      = result.mDx shl lineSubpixelShift
  result.mDy      = result.mDy shl lineSubpixelShift
  result.mDxStart = result.mDxStart shl lineMrSubPixelShift
  result.mDyStart = result.mDyStart shl lineMrSubPixelShift

proc initDistanceInterpolator2*(x1, y1, x2, y2, ex, ey, x, y, z: int): DistanceInterpolator2 =
  result.mDx = x2 - x1
  result.mDy = y2 - y1
  result.mDxStart = lineMr(ex) - lineMr(x2)
  result.mDyStart = lineMr(ey) - lineMr(y2)
  result.mDist = iround(float64(x + lineSubpixelScale div 2 - x2) * float64(result.mDy) -
                        float64(y + lineSubpixelScale div 2 - y2) * float64(result.mDx))
  result.mDistStart = (lineMr(x + lineSubpixelScale div 2) - lineMr(ex)) * result.mDyStart -
                      (lineMr(y + lineSubpixelScale div 2) - lineMr(ey)) * result.mDxStart
  result.mDx      = result.mDx shl lineSubpixelShift
  result.mDy      = result.mDy shl lineSubpixelShift
  result.mDxStart = result.mDxStart shl lineMrSubPixelShift
  result.mDyStart = result.mDyStart shl lineMrSubPixelShift

proc incX*(self: var DistanceInterpolator2) =
  self.mDist += self.mDy
  self.mDistStart += self.mDyStart

proc decX*(self: var DistanceInterpolator2) =
  self.mDist -= self.mDy
  self.mDistStart -= self.mDyStart

proc incY*(self: var DistanceInterpolator2) =
  self.mDist -= self.mDx
  self.mDistStart -= self.mDxStart

proc decY*(self: var DistanceInterpolator2) =
  self.mDist += self.mDx
  self.mDistStart += self.mDxStart

proc incX*(self: var DistanceInterpolator2, dy: int) =
  self.mDist      += self.mDy
  self.mDistStart += self.mDyStart
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart

  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart

proc decX*(self: var DistanceInterpolator2, dy: int) =
  self.mDist      -= self.mDy
  self.mDistStart -= self.mDyStart
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart

  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart

proc incY*(self: var DistanceInterpolator2, dx: int) =
  self.mDist      -= self.mDx
  self.mDistStart -= self.mDxStart
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart

  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart

proc decY*(self: var DistanceInterpolator2, dx: int) =
  self.mDist      += self.mDx
  self.mDistStart += self.mDxStart
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart

  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart

proc dist*(self: DistanceInterpolator2): int = self.mDist
proc distStart*(self: DistanceInterpolator2): int = self.mDistStart
proc distEnd*(self: DistanceInterpolator2): int = self.mDistStart

proc dx*(self: DistanceInterpolator2): int = self.mDx
proc dy*(self: DistanceInterpolator2): int = self.mDy
proc dxStart*(self: DistanceInterpolator2): int = self.mDxStart
proc dyStart*(self: DistanceInterpolator2): int = self.mDyStart
proc dxEnd*(self: DistanceInterpolator2): int = self.mDxStart
proc dyEnd*(self: DistanceInterpolator2): int = self.mDyStart

type
  DistanceInterpolator3* = object
    mDx, mDy, mDxStart, mDyStart: int
    mDxEnd, mDyEnd, mDist: int
    mDistStart, mDistEnd: int

proc initDistanceInterpolator3*(x1, y1, x2, y2, sx, sy, ex, ey, x, y: int): DistanceInterpolator3 =
  result.mDx = x2 - x1
  result.mDy = y2 - y1
  result.mDxStart = lineMr(sx) - lineMr(x1)
  result.mDyStart = lineMr(sy) - lineMr(y1)
  result.mDxEnd = lineMr(ex) - lineMr(x2)
  result.mDyEnd = lineMr(ey) - lineMr(y2)
  result.mDist = iround(float64(x + lineSubpixelScale div 2 - x2) * float64(result.mDy) -
                        float64(y + lineSubpixelScale div 2 - y2) * float64(result.mDx))
  result.mDistStart = (lineMr(x + lineSubpixelScale div 2) - lineMr(sx)) * result.mDyStart -
                      (lineMr(y + lineSubpixelScale div 2) - lineMr(sy)) * result.mDxStart
  result.mDistEnd = (lineMr(x + lineSubpixelScale div 2) - lineMr(ex)) * result.mDyEnd -
                    (lineMr(y + lineSubpixelScale div 2) - lineMr(ey)) * result.mDxEnd
  result.mDx      = result.mDx shl lineSubpixelShift
  result.mDy      = result.mDy shl lineSubpixelShift
  result.mDxStart = result.mDxStart shl lineMrSubPixelShift
  result.mDyStart = result.mDyStart shl lineMrSubPixelShift
  result.mDxEnd   = result.mDxEnd shl lineMrSubPixelShift
  result.mDyEnd   = result.mDyEnd shl lineMrSubPixelShift

proc incX*(self: var DistanceInterpolator3) =
  self.mDist += self.mDy
  self.mDistStart += self.mDyStart
  self.mDistEnd += self.mDyEnd

proc decX*(self: var DistanceInterpolator3) =
  self.mDist -= self.mDy
  self.mDistStart -= self.mDyStart
  self.mDistEnd -= self.mDyEnd

proc incY*(self: var DistanceInterpolator3) =
  self.mDist -= self.mDx
  self.mDistStart -= self.mDxStart
  self.mDistEnd -= self.mDxEnd

proc decY*(self: var DistanceInterpolator3) =
  self.mDist += self.mDx
  self.mDistStart += self.mDxStart
  self.mDistEnd += self.mDxEnd

proc incX*(self: var DistanceInterpolator3, dy: int) =
  self.mDist      += self.mDy
  self.mDistStart += self.mDyStart
  self.mDistEnd   += self.mDyEnd
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart
    self.mDistEnd   -= self.mDxEnd
  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart
    self.mDistEnd   += self.mDxEnd

proc decX*(self: var DistanceInterpolator3, dy: int) =
  self.mDist      -= self.mDy
  self.mDistStart -= self.mDyStart
  self.mDistEnd   -= self.mDyEnd
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart
    self.mDistEnd   -= self.mDxEnd

  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart
    self.mDistEnd   += self.mDxEnd

proc incY*(self: var DistanceInterpolator3, dx: int) =
  self.mDist      -= self.mDx
  self.mDistStart -= self.mDxStart
  self.mDistEnd   -= self.mDxEnd
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart
    self.mDistEnd   += self.mDyEnd
  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart
    self.mDistEnd   -= self.mDyEnd

proc decY*(self: var DistanceInterpolator3, dx: int) =
  self.mDist      += self.mDx
  self.mDistStart += self.mDxStart
  self.mDistEnd   += self.mDxEnd
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart
    self.mDistEnd   += self.mDyEnd
  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart
    self.mDistEnd   -= self.mDyEnd

proc dist*(self: DistanceInterpolator3): int = self.mDist
proc distStart*(self: DistanceInterpolator3): int = self.mDistStart
proc distEnd*(self: DistanceInterpolator3): int = self.mDistEnd

proc dx*(self: DistanceInterpolator3): int = self.mDx
proc dy*(self: DistanceInterpolator3): int = self.mDy
proc dxStart*(self: DistanceInterpolator3): int = self.mDxStart
proc dyStart*(self: DistanceInterpolator3): int = self.mDyStart
proc dxEnd*(self: DistanceInterpolator3): int = self.mDxEnd
proc dyEnd*(self: DistanceInterpolator3): int = self.mDyEnd

const
  maxHalfWidth = 64

type
  LineInterpolatorAABase*[Renderer] = object of RootObj
    mLp: ptr LineParameters
    mLi: Dda2LineInterpolator
    mRen: ptr Renderer
    mLen, mX, mY, mOldX: int
    mOldY, mCount, mWidth: int
    mMaxExtent, mStep: int
    mDist: array[maxHalfWidth + 1, int]
    mCovers: array[maxHalfWidth * 2 + 4, CoverType]

proc init*[Renderer](self: var LineInterpolatorAABase[Renderer], ren: var Renderer, lp: var LineParameters) =
  self.mLp = lp.addr
  self.mLi = initDda2LineInterpolator(if lp.vertical: lineDblHr(lp.x2 - lp.x1) else: lineDblHr(lp.y2 - lp.y1),
    if lp.vertical: abs(lp.y2 - lp.y1) else: abs(lp.x2 - lp.x1) + 1)

  self.mRen = ren.addr
  self.mLen = if lp.vertical == (lp.inc > 0): -lp.len else: lp.len
  self.mX = sar(lp.x1, lineSubpixelShift)
  self.mY = sar(lp.y1, lineSubpixelShift)
  self.mOldX = self.mX
  self.mOldY = self.mY
  self.mCount = if lp.vertical:
    abs(sar(lp.y2, lineSubpixelShift) - self.mY) else:
    abs(sar(lp.x2, lineSubpixelShift) - self.mX)


  self.mWidth = ren.subPixelWidth()
  #self.mMaxExtent(self.mWidth shr (lineSubpixelShift - 2)),
  self.mMaxExtent = (self.mWidth + lineSubpixelMask) shr lineSubpixelShift
  self.mStep = 0

  var li = initDda2LineInterpolator(0, if lp.vertical:
    (lp.dy shl lineSubpixelShift) else: (lp.dx shl lineSubpixelShift), lp.len)

  let stop = self.mWidth + lineSubpixelScale * 2
  for i in 0.. <maxHalfWidth:
    self.mDist[i] = li.y()
    if self.mDist[i] >= stop: break
    inc li

  self.mDist[maxHalfWidth] = 0x7FFF0000

proc stepHorBase*[Renderer,DI](self: var LineInterpolatorAABase[Renderer], di: var DI): int =
  inc self.mLi
  self.mX += self.mLp[].inc
  self.mY = sar((self.mLp[].y1 + self.mLi.y()), lineSubpixelShift)

  if self.mLp[].inc > 0: di.incX(self.mY - self.mOldY)
  else:                  di.decX(self.mY - self.mOldY)

  self.mOldY = self.mY
  result = di.dist() div self.mLen

proc stepVerBase*[Renderer,DI](self: var LineInterpolatorAABase[Renderer], di: var DI): int =
  inc self.mLi
  self.mY += self.mLp[].inc
  self.mX = sar((self.mLp[].x1 + self.mLi.y()), lineSubpixelShift)

  if self.mLp[].inc > 0: di.incY(self.mX - self.mOldX)
  else:                  di.decY(self.mX - self.mOldX)

  self.mOldX = self.mX
  result = di.dist() div self.mLen

proc vertical*[Renderer](self: LineInterpolatorAABase[Renderer]): bool = self.mLp[].vertical
proc width*[Renderer](self: LineInterpolatorAABase[Renderer]): int = self.mWidth
proc count*[Renderer](self: LineInterpolatorAABase[Renderer]): int = self.mCount

type
  LineInterpolatorAA0*[Renderer] = object of LineInterpolatorAABase[Renderer]
    mDi: DistanceInterpolator1

proc initLineInterpolatorAA0*[Renderer](ren: var Renderer, lp: var LineParameters): LineInterpolatorAA0[Renderer] =
  LineInterpolatorAABase[Renderer](result).init(ren, lp)

  result.mDi = initDistanceInterpolator1(lp.x1, lp.y1, lp.x2, lp.y2, lp.x1 and (not lineSubpixelMask), lp.y1 and (not lineSubpixelMask))
  result.mLi.adjustForward()

proc stepHor*[Renderer](self: var LineInterpolatorAA0[Renderer]): bool =
  mixin blendSolidVspan
  type
    base = LineInterpolatorAABase[Renderer]
  var
    dist, dy: int
    s1 = base(self).stepHorBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0

  p1[] = CoverType(base(self).mRen[].cover(s1))
  inc p1

  dy = 1
  dist = base(self).mDist[dy] - s1
  while dist <= base(self).mWidth:
    p1[] = CoverType(base(self).mRen[].cover(dist))
    inc p1
    inc dy
    dist = base(self).mDist[dy] - s1

  dy = 1
  dist = base(self).mDist[dy] + s1
  while dist <= base(self).mWidth:
    dec p0
    p0[] = CoverType(base(self).mRen[].cover(dist))
    inc dy
    dist = base(self).mDist[dy] + s1

  base(self).mRen[].blendSolidVspan(base(self).mX,
                                  base(self).mY - dy + 1,
                                  p1 - p0, p0)
  inc base(self).mStep
  result = base(self).mStep < base(self).mCount

proc stepVer*[Renderer](self: var LineInterpolatorAA0[Renderer]): bool =
  mixin blendSolidHspan
  type
    base = LineInterpolatorAABase[Renderer]

  var
    dist, dx: int
    s1 = base(self).stepVerBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0

  p1[] = CoverType(base(self).mRen[].cover(s1))
  inc p1

  dx = 1
  dist = base(self).mDist[dx] - s1
  while dist <= base(self).mWidth:
    p1[] = CoverType(base(self).mRen[].cover(dist))
    inc p1
    inc dx
    dist = base(self).mDist[dx] - s1

  dx = 1
  dist = base(self).mDist[dx] + s1
  while dist <= base(self).mWidth:
    dec p0
    p0[] = CoverType(base(self).mRen[].cover(dist))
    inc dx
    dist = base(self).mDist[dx] + s1

  base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                    base(self).mY,
                                    (p1 - p0), p0)
  inc base(self).mStep
  result = base(self).mStep < base(self).mCount


type
  LineInterpolatorAA1*[Renderer] = object of LineInterpolatorAABase[Renderer]
    mDi: DistanceInterpolator2

proc initLineInterpolatorAA1*[R](ren: var R, lp: var LineParameters, sx, sy: int): LineInterpolatorAA1[R] =
  type base = LineInterpolatorAABase[R]

  base(result).init(ren, lp)
  result.mDi = initDistanceInterpolator2(lp.x1, lp.y1, lp.x2, lp.y2, sx, sy,
    lp.x1 and not(lineSubpixelMask), lp.y1 and not(lineSubpixelMask))

  var
    dist1_start, dist2_start: int
    npix = 1

  if lp.vertical:
    doWhile base(result).mStep >= -base(result).mMaxExtent:
      dec base(result).mLi
      base(result).mY -= lp.inc
      base(result).mX = (base(result).mLp[].x1 + base(result).mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decY(base(result).mX - base(result).mOldX)
      else:          result.mDi.incY(base(result).mX - base(result).mOldX)

      base(result).mOldX = base(result).mX

      dist1_start = result.mDi.distStart()
      dist2_start = dist1_start

      var dx = 0
      if dist1_start < 0: inc npix
      doWhile base(result).mDist[dx] <= base(result).mWidth:
        dist1_start += result.mDi.dyStart()
        dist2_start -= result.mDi.dyStart()
        if dist1_start < 0: inc npix
        if dist2_start < 0: inc npix
        inc dx

      dec base(result).mStep
      if npix == 0: break
      npix = 0
  else:
    doWhile base(result).mStep >= -base(result).mMaxExtent:
      dec base(result).mLi
      base(result).mX -= lp.inc
      base(result).mY = (base(result).mLp[].y1 + base(result).mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decX(base(result).mY - base(result).mOldY)
      else:          result.mDi.incX(base(result).mY - base(result).mOldY)

      base(result).mOldY = base(result).mY

      dist1_start = result.mDi.distStart()
      dist2_start = dist1_start

      var dy = 0
      if dist1_start < 0: inc npix
      doWhile base(result).mDist[dy] <= base(result).mWidth:
        dist1_start -= result.mDi.dxStart()
        dist2_start += result.mDi.dxStart()
        if dist1_start < 0: inc npix
        if dist2_start < 0: inc npix
        inc dy

      dec base(result).mStep
      if npix == 0: break
      npix = 0

  base(result).mLi.adjustForward()

proc stepHor*[R](self: var LineInterpolatorAA1[R]): bool =
  mixin blendSolidVspan
  type base = LineInterpolatorAABase[R]
  var
    dist, dy: int
    s1 = base(self).stepHorBase(self.mDi)
    distStart = self.mDi.distStart()
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0

  p1[] = 0
  if distStart <= 0:
    p1[] = CoverType((self).mRen[].cover(s1))
  inc p1

  dy = 1
  dist = base(self).mDist[dy] - s1
  while dist <= base(self).mWidth:
    distStart -= self.mDi.dxStart()
    p1[] = 0
    if distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(dist))
    inc p1
    inc dy
    dist = base(self).mDist[dy] - s1

  dy = 1
  distStart = self.mDi.distStart()
  dist = base(self).mDist[dy] + s1
  while dist <= base(self).mWidth:
    distStart += self.mDi.dxStart()
    dec p0
    p0[] = 0
    if distStart <= 0:
      p0[] = CoverType((self).mRen[].cover(dist))
    inc dy
    dist = base(self).mDist[dy] + s1

  base(self).mRen[].blendSolidVspan(base(self).mX,
                                    base(self).mY - dy + 1,
                                    p1 - p0,
                                    p0)

  inc base(self).mStep
  result = base(self).mStep < base(self).mCount

proc stepVer*[R](self: var LineInterpolatorAA1[R]): bool =
  mixin blendSolidHspan
  type
    base = LineInterpolatorAABase[R]

  var
    dist, dx: int
    s1 = base(self).stepVerBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0
    distStart = self.mDi.distStart()

  p1[] = 0
  if distStart <= 0:
    p1[] = CoverType((self).mRen[].cover(s1))
  inc p1

  dx = 1
  dist = base(self).mDist[dx] - s1
  while dist <= base(self).mWidth:
    distStart += self.mDi.dyStart()
    p1[] = 0
    if distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(dist))
    inc p1
    inc dx
    dist = base(self).mDist[dx] - s1

  dx = 1
  distStart = self.mDi.distStart()
  dist = base(self).mDist[dx] + s1
  while dist <= base(self).mWidth:
    distStart -= self.mDi.dyStart()
    dec p0
    p0[] = 0
    if distStart <= 0:
      p0[] = CoverType((self).mRen[].cover(dist))
    inc dx
    dist = base(self).mDist[dx] + s1

  base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                    base(self).mY,
                                    p1 - p0,
                                    p0)
  inc base(self).mStep
  result = base(self).mStep < base(self).mCount

type
  LineInterpolatorAA2*[Renderer] = object of LineInterpolatorAABase[Renderer]
    mDi: DistanceInterpolator2

proc initLineInterpolatorAA2*[Renderer](ren: var Renderer,
  lp: var LineParameters, ex, ey: int): LineInterpolatorAA2[Renderer] =
  type
    base = LineInterpolatorAABase[Renderer]

  base(result).init(ren, lp)
  result.mDi = initDistanceInterpolator2(lp.x1, lp.y1, lp.x2, lp.y2, ex, ey, lp.x1 and (not(lineSubpixelMask)), lp.y1 and (not(lineSubpixelMask)), 0)
  base(result).mLi.adjustForward()
  base(result).mStep -= base(result).mMaxExtent

proc stepHor*[R](self: var LineInterpolatorAA2[R]): bool =
  mixin blendSolidVspan
  type
    base = LineInterpolatorAABase[R]

  var
    distEnd, dist, dy: int
    s1 = base(self).stepHorBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0

  distEnd = self.mDi.distEnd()
  var npix = 0
  p1[] = 0
  if distEnd > 0:
    p1[] = CoverType((self).mRen[].cover(s1))
    inc npix
  inc p1

  dy = 1
  dist = base(self).mDist[dy] - s1
  while dist <= base(self).mWidth:
    distEnd -= self.mDi.dxEnd()
    p1[] = 0
    if distEnd > 0:
      p1[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc p1
    inc dy
    dist = base(self).mDist[dy] - s1

  dy = 1
  distEnd = self.mDi.distEnd()
  dist = base(self).mDist[dy] + s1
  while dist <= base(self).mWidth:
    distEnd += self.mDi.dxEnd()
    dec p0
    p0[] = 0
    if distEnd > 0:
      p0[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc dy
    dist = base(self).mDist[dy] + s1

  base(self).mRen[].blendSolidVspan(base(self).mX,
                                    base(self).mY - dy + 1,
                                    p1 - p0,
                                    p0)
  inc base(self).mStep
  result = npix != 0 and base(self).mStep < base(self).mCount

proc stepVer*[R](self: var LineInterpolatorAA2[R]): bool =
  mixin blendSolidHspan
  type
    base = LineInterpolatorAABase[R]

  var
    dist, dx: int
    s1 = base(self).stepVerBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0
    distEnd = self.mDi.distEnd()
    npix = 0

  p1[] = 0
  if distEnd > 0:
    p1[] = CoverType((self).mRen[].cover(s1))
    inc npix
  inc p1

  dx = 1
  dist = base(self).mDist[dx] - s1
  while dist <= base(self).mWidth:
    distEnd += self.mDi.dyEnd()
    p1[] = 0
    if distEnd > 0:
      p1[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc p1
    inc dx
    dist = base(self).mDist[dx] - s1

  dx = 1
  distEnd = self.mDi.distEnd()
  dist = base(self).mDist[dx] + s1
  while dist <= base(self).mWidth:
    distEnd -= self.mDi.dyEnd()
    dec p0
    p0[] = 0
    if distEnd > 0:
      p0[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc dx
    dist = base(self).mDist[dx] + s1

  base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                    base(self).mY,
                                    p1 - p0,
                                    p0)

  inc base(self).mStep
  result = npix != 0 and base(self).mStep < base(self).mCount

type
  LineInterpolatorAA3*[Renderer] = object of LineInterpolatorAABase[Renderer]
    mDi: DistanceInterpolator3

proc initLineInterpolatorAA3*[R](ren: var R, lp: var LineParameters, sx, sy, ex, ey: int): LineInterpolatorAA3[R] =
  type base = LineInterpolatorAABase[R]
  base(result).init(ren, lp)

  result.mDi = initDistanceInterpolator3(lp.x1, lp.y1, lp.x2, lp.y2, sx, sy, ex, ey,
      lp.x1 and not(lineSubpixelMask), lp.y1 and not(lineSubpixelMask))

  var
    dist1_start, dist2_start: int
    npix = 1

  if lp.vertical:
    doWhile base(result).mStep >= -base(result).mMaxExtent:
      dec base(result).mLi
      base(result).mY -= lp.inc
      base(result).mX = (base(result).mLp[].x1 + base(result).mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decY(base(result).mX - base(result).mOldX)
      else:          result.mDi.incY(base(result).mX - base(result).mOldX)

      base(result).mOldX = base(result).mX

      dist2_start = result.mDi.distStart()
      dist1_start = dist2_start

      var dx = 0
      if dist1_start < 0: inc npix
      doWhile base(result).mDist[dx] <= base(result).mWidth:
        dist1_start += result.mDi.dyStart()
        dist2_start -= result.mDi.dyStart()
        if dist1_start < 0: inc npix
        if dist2_start < 0: inc npix
        inc dx

      if npix == 0: break
      npix = 0
      dec base(result).mStep
  else:
    doWhile base(result).mStep >= -base(result).mMaxExtent:
      dec base(result).mLi
      base(result).mX -= lp.inc
      base(result).mY = (base(result).mLp[].y1 + base(result).mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decX(base(result).mY - base(result).mOldY)
      else:          result.mDi.incX(base(result).mY - base(result).mOldY)

      base(result).mOldY = base(result).mY

      dist2_start = result.mDi.distStart()
      dist1_start = dist2_start

      var dy = 0
      if dist1_start < 0: inc npix
      doWhile base(result).mDist[dy] <= base(result).mWidth:
        dist1_start -= result.mDi.dxStart()
        dist2_start += result.mDi.dxStart()
        if dist1_start < 0: inc npix
        if dist2_start < 0: inc npix
        inc dy

      if npix == 0: break
      npix = 0
      dec base(result).mStep

  base(result).mLi.adjustForward()
  base(result).mStep -= base(result).mMaxExtent;

proc stepHor*[R](self: var LineInterpolatorAA3[R]): bool =
  mixin blendSolidVspan
  type base = LineInterpolatorAABase[R]
  var
    dist, dy : int
    s1 = base(self).stepHorBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0
    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()
    npix = 0

  p1[] = 0
  if distEnd > 0:
    if distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(s1))
    inc npix
  inc p1

  dy = 1
  dist = base(self).mDist[dy] - s1
  while dist <= base(self).mWidth:
    distStart -= self.mDi.dxStart()
    distEnd   -= self.mDi.dxEnd()
    p1[] = 0
    if distEnd > 0 and distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc p1
    inc dy
    dist = base(self).mDist[dy] - s1

  dy = 1
  distStart = self.mDi.distStart()
  distEnd   = self.mDi.distEnd()
  dist = base(self).mDist[dy] + s1
  while dist <= base(self).mWidth:
    distStart += self.mDi.dxStart()
    distEnd   += self.mDi.dxEnd()
    dec p0
    p0[] = 0
    if distEnd > 0 and distStart <= 0:
      p0[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc dy
    dist = base(self).mDist[dy] + s1

  base(self).mRen[].blendSolidVspan(base(self).mX,
                                    base(self).mY - dy + 1,
                                    p1 - p0,
                                    p0)
  inc base(self).mStep
  return npix != 0 and base(self).mStep  < base(self).mCount

proc stepVer*[R](self: var LineInterpolatorAA3[R]): bool =
  mixin blendSolidHspan
  type base = LineInterpolatorAABase[R]
  var
    dist, dx : int
    s1 = base(self).stepVerBase(self.mDi)
    p0 = addr(base(self).mCovers[0]) + maxHalfWidth + 2
    p1 = p0
    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()
    npix = 0

  p1[] = 0
  if distEnd > 0:
    if distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(s1))
    inc npix
  inc p1

  dx = 1
  dist = base(self).mDist[dx] - s1
  while dist <= base(self).mWidth:
    distStart += self.mDi.dyStart()
    distEnd   += self.mDi.dyEnd()
    p1[] = 0
    if distEnd > 0 and distStart <= 0:
      p1[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc p1
    inc dx
    dist = base(self).mDist[dx] - s1

  dx = 1
  distStart = self.mDi.distStart()
  distEnd   = self.mDi.distEnd()
  dist = base(self).mDist[dx] + s1
  while dist <= base(self).mWidth:
    distStart -= self.mDi.dyStart()
    distEnd   -= self.mDi.dyEnd()
    dec p0
    p0[] = 0
    if distEnd > 0 and distStart <= 0:
      p0[] = CoverType((self).mRen[].cover(dist))
      inc npix
    inc dx
    dist = base(self).mDist[dx] + s1

  base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                    base(self).mY,
                                    p1 - p0,
                                    p0)
  inc base(self).mStep
  result = npix != 0 and base(self).mStep < base(self).mCount

const
  subPixelShift = lineSubpixelShift
  subPixelScale = 1 shl subPixelShift
  #subPixelMask  = subPixelScale - 1

  aaShift = 8
  aaScale = 1 shl aaShift
  aaMask  = aaScale - 1

type
  LineProfileAA* = object
    mProfile: seq[uint8]
    mGamma: array[aaScale, uint8]
    msubPixelWidth: int
    mMinWidth: float64
    mSmootherWidth: float64

proc width*(self: var LineProfileAA, w: float64)

proc gamma*[GammaF](self: var LineProfileAA, gammaF: var GammaF) =
  for i in 0.. <aaScale:
    self.mGamma[i] = uround(gammaF.getGammaValue(float64(i) / aaMask) * aaMask).uint8

proc initLineProfileAA*(): LineProfileAA =
  result.msubPixelWidth = 0
  result.mMinWidth = 1.0
  result.mSmootherWidth = 1.0
  result.mProfile = @[]
  for i in 0.. <aaScale: result.mGamma[i] = i.uint8

proc initLineProfileAA*[GammaF](w: float64, gammaF: var GammaF): LineProfileAA =
  result.msubPixelWidth = 0
  result.mMinWidth = 1.0
  result.mSmootherWidth = 1.0
  result.mProfile = @[]
  result.gamma(gammaF)
  result.width(w)

proc minWidth*(self: var LineProfileAA, w: float64) =
  self.mMinWidth = w

proc smootherWidth*(self: var LineProfileAA, w: float64) =
  self.mSmootherWidth = w

proc profileSize*(self: LineProfileAA): int =
  self.mProfile.len

proc subPixelWidth*(self: LineProfileAA): int =
  self.msubPixelWidth

proc minWidth*(self: LineProfileAA): float64 =
  self.mMinWidth

proc smootherWidth*(self: LineProfileAA): float64 =
  self.mSmootherWidth

proc value*(self: var LineProfileAA, dist: int): uint8 =
  self.mProfile[dist + subPixelScale*2]

proc profile*(self: var LineProfileAA, w: float64): ptr uint8 =
  self.msubPixelWidth = uround(w * subPixelScale)
  let size = self.msubPixelWidth + subPixelScale * 6
  if size > self.mProfile.len:
    self.mProfile.setLen(size)
  result = addr(self.mProfile[0])

proc set*(self: var LineProfileAA, centerWidth, smootherWidth: float64) =
  var
    baseVal = 1.0
    centerWidth = centerWidth
    smootherWidth = smootherWidth

  if centerWidth == 0.0:   centerWidth = 1.0 / subPixelScale
  if smootherWidth == 0.0: smootherWidth = 1.0 / subPixelScale

  var width = centerWidth + smootherWidth
  if width < self.mMinWidth:
    let k = width / self.mMinWidth
    baseVal *= k
    centerWidth = centerWidth / k
    smootherWidth = smootherWidth / k

  var
    ch = self.profile(centerWidth + smootherWidth)
    subPixelCenterWidth = (centerWidth * subPixelScale).int
    subPixelSmootherWidth = (smootherWidth * subPixelScale).int
    chCenter   = ch + subPixelScale*2
    chSmoother = chCenter + subPixelCenterWidth
    val = self.mGamma[(baseVal * aaMask).int]

  ch = chCenter
  for i in 0.. <subPixelCenterWidth:
    ch[] = val.uint8
    inc ch

  for i in 0.. <subPixelSmootherWidth:
    let idx = int((baseVal - baseVal * (float64(i) / subPixelSmootherWidth.float64)) * aaMask)
    chSmoother[] = self.mGamma[idx]
    inc chSmoother

  let nSmoother = self.profileSize() -
                   subPixelSmootherWidth -
                   subPixelCenterWidth -
                   subPixelScale*2

  val = self.mGamma[0]
  for i in 0.. < nSmoother:
    chSmoother[] = val.uint8
    inc chSmoother

  ch = chCenter
  for i in 0.. <subPixelScale*2:
    dec ch
    ch[] = chCenter[]
    inc chCenter

proc width(self: var LineProfileAA, w: float64) =
  var w = w
  if w < 0.0: w = 0.0

  if w < self.mSmootherWidth: w += w
  else:                       w += self.mSmootherWidth

  w *= 0.5

  w -= self.mSmootherWidth
  var s = self.mSmootherWidth
  if w < 0.0:
    s += w
    w = 0.0

  self.set(w, s)

type
  RendererOutlineAA*[BaseRenderer, ColorT] = object
    mRen: ptr BaseRenderer
    mProfile: ptr LineProfileAA
    mColor: ColorT
    mClipBox: RectI
    mClipping: bool

proc init[R,C](ren: var R, prof: var LineProfileAA): RendererOutlineAA[R,C] =
  result.mRen = ren.addr
  result.mProfile = prof.addr
  result.mClipBox = initRectI(0,0,0,0)
  result.mClipping = false

proc initRendererOutlineAA*[R](ren: var R, prof: var LineProfileAA): auto =
  mixin getColorT
  result = init[R, getColorT(R)](ren, prof)

proc attach*[R,C](self: var RendererOutlineAA[R,C], ren: var R) =
  self.mRen = ren.addr

proc color*[R,ColorA, ColorB](self: var RendererOutlineAA[R,ColorA], c: ColorB) =
  when ColorA is not ColorB:
    self.mColor = construct(ColorA, c)
  else:
    self.mColor = c

proc color*[R,C](self: RendererOutlineAA[R,C]): C =
  self.mColor

proc profile*[R,C](self: var RendererOutlineAA[R,C], prof: var LineProfileAA) =
  self.mProfile = prof.addr

proc profile*[R,C](self: RendererOutlineAA[R,C]): var LineProfileAA = self.mProfile[]
proc subPixelWidth*[R,C](self: RendererOutlineAA[R,C]): int = self.mProfile[].subPixelWidth()

proc resetClipping*[R,C](self: var RendererOutlineAA[R,C]) =
  self.mClipping = false

proc clipBox*[R,C](self: var RendererOutlineAA[R,C], x1, y1, x2, y2: float64) =
  self.mClipBox.x1 = LineCoordSat.conv(x1)
  self.mClipBox.y1 = LineCoordSat.conv(y1)
  self.mClipBox.x2 = LineCoordSat.conv(x2)
  self.mClipBox.y2 = LineCoordSat.conv(y2)
  self.mClipping = true

proc cover*[R,C](self: var RendererOutlineAA[R,C], d: int): int =
  self.mProfile[].value(d).int

proc blendSolidHspan*[R,C](self: var RendererOutlineAA[R,C],x, y, len: int, covers: ptr CoverType) =
  self.mRen[].blendSolidHspan(x, y, len, self.mColor, covers)

proc blendSolidVspan*[R,C](self: var RendererOutlineAA[R,C],x, y, len: int, covers: ptr CoverType) =
  self.mRen[].blendSolidVspan(x, y, len, self.mColor, covers)

proc accurateJoinOnly*[R,C](self: var RendererOutlineAA[R,C]): bool = false

proc semiDotHline*[R,C,Cmp](self: var RendererOutlineAA[R,C], cmp: Cmp, xc1, yc1, xc2, yc2, x1, y1, x2: int) =
  var
    covers: array[maxHalfWidth * 2 + 4, CoverType]
    p0 = covers[0].addr
    p1 = covers[0].addr
    x = x1 shl lineSubpixelShift
    y = y1 shl lineSubpixelShift
    w = self.subPixelWidth()
    di = initDistanceInterpolator0(xc1, yc1, xc2, yc2, x, y)

  x += lineSubpixelScale div 2
  y += lineSubpixelScale div 2

  var
    x1 = x1
    x0 = x1
    dx = x - xc1
    dy = y - yc1

  doWhile x1 <= x2:
    let d = fastSqrt(dx*dx + dy*dy)
    p1[] = 0
    if cmp(di.dist()) and d <= w:
      p1[] = CoverType(self.cover(d))
    inc p1
    dx += lineSubpixelScale
    di.incX()
    inc x1

  self.mRen[].blendSolidHspan(x0, y1, p1 - p0, self.color(), p0)

proc semiDot*[R,C,Cmp](self: var RendererOutlineAA[R,C], cmp: Cmp, xc1, yc1, xc2, yc2: int) =
  if self.mClipping and clippingFlags(xc1, yc1, self.mClipBox) != 0: return

  var
    r = (self.subPixelWidth() + lineSubpixelMask) shr lineSubpixelShift

  if r < 1: r = 1

  var
    ei = initEllipseBresenhamInterpolator(r, r)
    dx = 0
    dy = -r
    dy0 = dy
    dx0 = dx
    x = xc1 shr lineSubpixelShift
    y = yc1 shr lineSubpixelShift

  doWhile dy < 0:
    dx += ei.getDx()
    dy += ei.getDy()

    if dy != dy0:
      self.semiDotHline(cmp, xc1, yc1, xc2, yc2, x-dx0, y+dy0, x+dx0)
      self.semiDotHline(cmp, xc1, yc1, xc2, yc2, x-dx0, y-dy0, x+dx0)
    dx0 = dx
    dy0 = dy
    inc ei

  self.semiDotHline(cmp, xc1, yc1, xc2, yc2, x-dx0, y+dy0, x+dx0)

proc pieHline*[R,C](self: var RendererOutlineAA[R,C], xc, yc, xp1, yp1, xp2, yp2, xh1, yh1, xh2: int) =
  if self.mClipping and clippingFlags(xc, yc, self.mClipBox) != 0: return

  var
    covers: array[maxHalfWidth * 2 + 4, CoverType]
    p0 = covers[0].addr
    p1 = covers[0].addr
    x = xh1 shl lineSubpixelShift
    y = yh1 shl lineSubpixelShift
    w = self.subPixelWidth()
    di = initDistanceInterpolator00(xc, yc, xp1, yp1, xp2, yp2, x, y)

  x += lineSubpixelScale div 2
  y += lineSubpixelScale div 2

  var
    xh1 = xh1
    xh0 = xh1
    dx = x - xc
    dy = y - yc

  doWhile xh1 <= xh2:
    let d = fastSqrt(dx*dx + dy*dy)
    p1[] = 0
    if di.dist1() <= 0 and di.dist2() > 0 and d <= w:
      p1[] = CoverType(self.cover(d))
    inc p1
    dx += lineSubpixelScale
    di.incX()
    inc xh1

  self.mRen[].blendSolidHspan(xh0, yh1, p1 - p0, self.color(), p0)

proc pie*[R,C](self: var RendererOutlineAA[R,C], xc, yc, x1, y1, x2, y2: int) =
  var r = (self.subPixelWidth() + lineSubpixelMask) shr lineSubpixelShift
  if r < 1: r = 1

  var
    ei = initEllipseBresenhamInterpolator(r, r)
    dx = 0
    dy = -r
    dy0 = dy
    dx0 = dx
    x = xc shr lineSubpixelShift
    y = yc shr lineSubpixelShift

  doWhile dy < 0:
    dx += ei.getDx()
    dy += ei.getDy()

    if dy != dy0:
      self.pieHline(xc, yc, x1, y1, x2, y2, x-dx0, y+dy0, x+dx0)
      self.pieHline(xc, yc, x1, y1, x2, y2, x-dx0, y-dy0, x+dx0)
    dx0 = dx
    dy0 = dy
    inc ei

  self.pieHline(xc, yc, x1, y1, x2, y2, x-dx0, y+dy0, x+dx0)

proc line0NoClip*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters) =
  if lp.len > lineMaxLength:
    var lp1, lp2: LineParameters
    lp.divide(lp1, lp2)
    self.line0NoClip(lp1)
    self.line0NoClip(lp2)
    return

  var li = initLineInterpolatorAA0(self, lp)
  if li.count() != 0:
    if li.vertical():
      while li.stepVer(): discard
    else:
      while li.stepHor(): discard

proc line0*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters) =
  if self.mClipping:
    var
      x1 = lp.x1
      y1 = lp.y1
      x2 = lp.x2
      y2 = lp.y2
      flags = clipLineSegment(x1, y1, x2, y2, self.mClipBox)

    if (flags and 4) == 0:
      if flags != 0:
        var lp2 = initLineParameters(x1, y1, x2, y2, uround(calcDistance(x1, y1, x2, y2)))
        self.line0NoClip(lp2)
      else:
        self.line0NoClip(lp)
  else:
    self.line0NoClip(lp)

proc line1NoClip*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, sx, sy: int) =
  if lp.len > lineMaxLength:
    var lp1, lp2: LineParameters
    lp.divide(lp1, lp2)
    self.line1NoClip(lp1, (lp.x1 + sx) shr 1, (lp.y1 + sy) shr 1)
    self.line1NoClip(lp2, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1))
    return

  var
    sx = sx
    sy = sy
  fixDegenerateBisectrixStart(lp, sx, sy)
  var li = initLineInterpolatorAA1(self, lp, sx, sy)
  if li.vertical():
    while li.stepVer(): discard
  else:
    while li.stepHor(): discard

proc line1*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, sx, sy: int) =
  if self.mClipping:
    var
      sx = sx
      sy = sy
      x1 = lp.x1
      y1 = lp.y1
      x2 = lp.x2
      y2 = lp.y2
      flags = clipLineSegment(x1, y1, x2, y2, self.mClipBox)
    if (flags and 4) == 0:
      if flags != 0:
        var lp2 = initLineParameters(x1, y1, x2, y2, uround(calcDistance(x1, y1, x2, y2)))
        if (flags and 1) != 0:
          sx = x1 + (y2 - y1)
          sy = y1 - (x2 - x1)
        else:
          while abs(sx - lp.x1) + abs(sy - lp.y1) > lp2.len:
            sx = (lp.x1 + sx) shr 1
            sy = (lp.y1 + sy) shr 1
        self.line1NoClip(lp2, sx, sy)
      else:
        self.line1NoClip(lp, sx, sy)
  else:
    self.line1NoClip(lp, sx, sy)

proc line2NoClip*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, ex, ey: int) =
  if lp.len > lineMaxLength:
    var lp1, lp2: LineParameters
    lp.divide(lp1, lp2)
    self.line2NoClip(lp1, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1))
    self.line2NoClip(lp2, (lp.x2 + ex) shr 1, (lp.y2 + ey) shr 1)
    return

  var
    ex = ex
    ey = ey
  fixDegenerateBisectrixEnd(lp, ex, ey)
  var li = initLineInterpolatorAA2(self, lp, ex, ey)
  if li.vertical():
    while li.stepVer(): discard
  else:
    while li.stepHor(): discard

proc line2*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, ex, ey: int) =
  if self.mClipping:
    var
      ex = ex
      ey = ey
      x1 = lp.x1
      y1 = lp.y1
      x2 = lp.x2
      y2 = lp.y2
      flags = clipLineSegment(x1, y1, x2, y2, self.mClipBox)
    if (flags and 4) == 0:
      if flags != 0:
        var lp2 = initLineParameters(x1, y1, x2, y2, uround(calcDistance(x1, y1, x2, y2)))
        if (flags and 2) != 0:
          ex = x2 + (y2 - y1)
          ey = y2 - (x2 - x1)
        else:
          while abs(ex - lp.x2) + abs(ey - lp.y2) > lp2.len:
            ex = (lp.x2 + ex) shr 1
            ey = (lp.y2 + ey) shr 1
        self.line2NoClip(lp2, ex, ey)
      else:
        self.line2NoClip(lp, ex, ey)
  else:
    self.line2NoClip(lp, ex, ey)

proc line3NoClip*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, sx, sy, ex, ey: int) =
  var
    sx = sx
    sy = sy
    ex = ex
    ey = ey

  if lp.len > lineMaxLength:
    var
      lp1, lp2: LineParameters

    lp.divide(lp1, lp2)
    var
      mx = lp1.x2 + (lp1.y2 - lp1.y1)
      my = lp1.y2 - (lp1.x2 - lp1.x1)

    self.line3NoClip(lp1, (lp.x1 + sx) shr 1, (lp.y1 + sy) shr 1, mx, my)
    self.line3NoClip(lp2, mx, my, (lp.x2 + ex) shr 1, (lp.y2 + ey) shr 1)
    return

  fixDegenerateBisectrixStart(lp, sx, sy)
  fixDegenerateBisectrixEnd(lp, ex, ey)

  var li = initLineInterpolatorAA3(self, lp, sx, sy, ex, ey)

  if li.vertical():
    while li.stepVer(): discard
  else:
    while li.stepHor(): discard

proc line3*[R,C](self: var RendererOutlineAA[R,C], lp: var LineParameters, sx, sy, ex, ey: int) =
  var
    sx = sx
    sy = sy
    ex = ex
    ey = ey

  if self.mClipping:
    var
      x1 = lp.x1
      y1 = lp.y1
      x2 = lp.x2
      y2 = lp.y2
      flags = clipLineSegment(x1, y1, x2, y2, self.mClipBox)
    if (flags and 4) == 0:
      if flags != 0:
        var lp2 = initLineParameters(x1, y1, x2, y2, uround(calcDistance(x1, y1, x2, y2)))
        if (flags and 1) != 0:
          sx = x1 + (y2 - y1)
          sy = y1 - (x2 - x1)
        else:
          while abs(sx - lp.x1) + abs(sy - lp.y1) > lp2.len:
            sx = (lp.x1 + sx) shr 1
            sy = (lp.y1 + sy) shr 1

        if (flags and 2) != 0:
          ex = x2 + (y2 - y1)
          ey = y2 - (x2 - x1)
        else:
          while abs(ex - lp.x2) + abs(ey - lp.y2) > lp2.len:
            ex = (lp.x2 + ex) shr 1
            ey = (lp.y2 + ey) shr 1
        self.line3NoClip(lp2, sx, sy, ex, ey)
      else:
        self.line3NoClip(lp, sx, sy, ex, ey)
  else:
    self.line3NoClip(lp, sx, sy, ex, ey)
