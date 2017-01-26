import agg_math, agg_line_aa_basics, agg_dda_line, agg_ellipse_bresenham
import agg_renderer_base, agg_gamma_functions, agg_clip_liang_barsky
import agg_basics

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
  LineInterpolatorAAbase*[Renderer] = object of RootObj
    mLp: ptr LineParameters
    mLi: Dda2LineInterpolator
    mRen: ptr Renderer
    mLen, mX, mY, mOldX: int
    mOldY, mCount, mWidth: int
    mMaxExtent, mStep: int
    mDist: array[maxHalfWidth + 1, int]
    mCovers: array[maxHalfWidth * 2 + 4, CoverType]

proc init*[Renderer](self: var LineInterpolatorAAbase[Renderer], ren: var Renderer, lp: var LineParameters) =
  self.mLp = lp.addr
  self.mLi = initDda2LineInterpolator(if lp.vertical: lineDblHr(lp.x2 - lp.x1) else: lineDblHr(lp.y2 - lp.y1),
    if lp.vertical: abs(lp.y2 - lp.y1) else: abs(lp.x2 - lp.x1) + 1)

  self.mRen = ren.addr
  self.mLen = if lp.vertical == (lp.inc > 0): -lp.len else: lp.len
  self.mX = lp.x1 shr lineSubpixelShift
  self.mY = lp.y1 shr lineSubpixelShift
  self.mOldX = self.mX
  self.mOldY = self.mY
  self.mCount = if lp.vertical:
    abs((lp.y2 shr lineSubpixelShift) - self.mY) else:
    abs((lp.x2 shr lineSubpixelShift) - self.mX)


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

proc stepHorBase*[Renderer,DI](self: var LineInterpolatorAAbase[Renderer], di: var DI): int =
  inc self.mLi
  self.mX += self.mLp[].inc
  self.mY = (self.mLp[].y1 + self.mLi.y()) shr lineSubpixelShift

  if self.mLp[].inc > 0: di.incX(self.mY - self.mOldY)
  else:                  di.decX(self.mY - self.mOldY)

  self.mOldY = self.mY
  result = di.dist() / self.mLen

proc stepVerBase*[Renderer,DI](self: var LineInterpolatorAAbase[Renderer], di: var DI): int =
  inc self.mLi
  self.mY += self.mLp[].inc
  self.mX = (self.mLp[].x1 + self.mLi.y()) shr lineSubpixelShift

  if self.mLp[].inc > 0: di.incY(self.mX - self.mOldX)
  else:                  di.decY(self.mX - self.mOldX)

  self.mOldX = self.mX
  result = di.dist() / self.mLen

proc vertical*[Renderer](self: LineInterpolatorAAbase[Renderer]): bool = self.mLp[].vertical
proc width*[Renderer](self: LineInterpolatorAAbase[Renderer]): int = self.mWidth
proc count*[Renderer](self: LineInterpolatorAAbase[Renderer]): int = self.mCount

type
  LineInterpolatorAA0*[Renderer] = object of LineInterpolatorAAbase[Renderer]
    mDi: DistanceInterpolator1

proc initLineInterpolatorAA0*[Renderer](ren: var Renderer, lp: var LineParameters): LineInterpolatorAA0[Renderer] =
  LineInterpolatorAAbase[Renderer](result).init(ren, lp)
  
  result.mDi(lp.x1, lp.y1, lp.x2, lp.y2, lp.x1 and (not lineSubpixelMask), lp.y1 and (not lineSubpixelMask))
  result.mLi.adjustForward()
    
proc stepHor*[Renderer](self: var LineInterpolatorAA0[Renderer]): bool =
  type 
    base = LineInterpolatorAAbase[Renderer]
  var
    dist, dy: int
    s1 = base(self).stepHorBase(self.mDi)
    p0 = base(self).mCovers + base(self).maxHalfWidth + 2
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
  type 
    base = LineInterpolatorAAbase[Renderer]

  var
    dist, dx: int
    s1 = base(self).stepVerBase(self.mDi)
    p0 = base(self).mCovers + base(self).maxHalfWidth + 2
    p1 = p0

  p1[] = CoverType(base(self).mRen[].cover(s1))
  inc p1

  dx = 1
  dist = base(self).mDist[dx] - s1
  while dist <= base(self).mWidth:
    p1[] = CoverType(base(self).mRen[].cover(dist))
    inc p1
    inc dx

  dx = 1
  dist = base(self).mDist[dx] + s1
  while base <= base(self).mWidth:
    dec p0
    p0[] = CoverType(base(self).mRen[].cover(dist))    
    inc dx

  base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                    base(self).mY,
                                    (p1 - p0), p0)
  inc base(self).mStep         
  result = base(self).mStep < base(self).mCount


type
  LineInterpolatorAA1 = object of LineInterpolatorAAbase[Renderer]
    mDi: DistanceInterpolator2
    
#[
line_interpolator_aa1(ren: var Renderer, lp: var LineParameters,
                      sx, sy: int) :
    LineInterpolatorAABase[Renderer](ren, lp),
    self.mDi(lp.x1, lp.y1, lp.x2, lp.y2, sx, sy,
         lp.x1 and not(lineSubpixelMask, lp.y1 and not(lineSubpixelMask)
{
    int dist1_start;
    int dist2_start;

    int npix = 1;

    if lp.vertical)
    {
        do
        {
            --base(self).mLi;
            base(self).mY -= lp.inc;
            base(self).mX = (base(self).mLp[].x1 + base(self).mLi.y()) shr lineSubpixelShift;

            if lp.inc > 0) self.mDi.decY(base(self).mX - base(self).mOldX)
            else           self.mDi.incY(base(self).mX - base(self).mOldX)

            base(self).mOldX = base(self).mX;

            dist1_start = dist2_start = self.mDi.distStart()

            int dx = 0;
            if dist1_start < 0) inc npix
            do
            {
                dist1_start += self.mDi.dyStart()
                dist2_start -= self.mDi.dyStart()
                if dist1_start < 0) inc npix
                if dist2_start < 0) inc npix
                inc dx
            }
            while base(self).mDist[dx] <= base(self).mWidth)
            dec base(self).mStep
            if npix == 0: break;
            npix = 0;
        }
        while base(self).mStep >= -base(self).mMaxExtent)
    }
    else:
    {
        do
        {
            --base(self).mLi;
            base(self).mX -= lp.inc;
            base(self).mY = (base(self).mLp[].y1 + base(self).mLi.y()) shr lineSubpixelShift;

            if lp.inc > 0) self.mDi.decX(base(self).mY - base(self).mOldY)
            else           self.mDi.incX(base(self).mY - base(self).mOldY)

            base(self).mOldY = base(self).mY;

            dist1_start = dist2_start = self.mDi.distStart()

            int dy = 0;
            if dist1_start < 0) inc npix
            do
            {
                dist1_start -= self.mDi.dxStart()
                dist2_start += self.mDi.dxStart()
                if dist1_start < 0) inc npix
                if dist2_start < 0) inc npix
                inc dy
            }
            while base(self).mDist[dy] <= base(self).mWidth)
            dec base(self).mStep
            if npix == 0: break;
            npix = 0;
        }
        while base(self).mStep >= -base(self).mMaxExtent)
    }
    base(self).mLi.adjustForward()

bool stepHor()
{
    int distStart;
    int dist;
    int dy;
    int s1 = base(self).stepHorBase(self.mDi)

    distStart = self.mDi.distStart()
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    *p1 = 0;
    if distStart <= 0)
    {
        *p1 = CoverType((self).mRen[].cover(s1)
    }
    inc p1

    dy = 1;
    while (dist = base(self).mDist[dy] - s1) <= base(self).mWidth)
    {
        distStart -= self.mDi.dxStart()
        *p1 = 0;
        if distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
        }
        inc p1
        inc dy
    }

    dy = 1;
    distStart = self.mDi.distStart()
    while (dist = base(self).mDist[dy] + s1) <= base(self).mWidth)
    {
        distStart += self.mDi.dxStart()
        *--p0 = 0;
        if distStart <= 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
        }
        inc dy
    }

    base(self).mRen[].blendSolidVspan(base(self).mX,
                                       base(self).mY - dy + 1,
                                       p1 - p0,
                                       p0)
    return ++base(self).mStep < base(self).mCount;

bool stepVer()
{
    int distStart;
    int dist;
    int dx;
    int s1 = base(self).stepVerBase(self.mDi)
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    distStart = self.mDi.distStart()

    *p1 = 0;
    if distStart <= 0)
    {
        *p1 = CoverType((self).mRen[].cover(s1)
    }
    inc p1

    dx = 1;
    while (dist = base(self).mDist[dx] - s1) <= base(self).mWidth)
    {
        distStart += self.mDi.dyStart()
        *p1 = 0;
        if distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
        }
        inc p1
        inc dx
    }

    dx = 1;
    distStart = self.mDi.distStart()
    while (dist = base(self).mDist[dx] + s1) <= base(self).mWidth)
    {
        distStart -= self.mDi.dyStart()
        *--p0 = 0;
        if distStart <= 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
        }
        inc dx
    }
    base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                       base(self).mY,
                                       p1 - p0,
                                       p0)
    return ++base(self).mStep < base(self).mCount;
}


[Renderer> class line_interpolator_aa2 :
object of LineInterpolatorAABase[Renderer]
distance_interpolator2 self.mDi;

line_interpolator_aa2(ren: var Renderer, lp: var LineParameters,
                      ex, ey: int) :
    LineInterpolatorAABase[Renderer](ren, lp),
    self.mDi(lp.x1, lp.y1, lp.x2, lp.y2, ex, ey,
         lp.x1 and not(lineSubpixelMask, lp.y1 and not(lineSubpixelMask,
         0)
{
    base(self).mLi.adjustForward()
    base(self).mStep -= base(self).mMaxExtent;
}

bool stepHor()
{
    int distEnd;
    int dist;
    int dy;
    int s1 = base(self).stepHorBase(self.mDi)
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    distEnd = self.mDi.distEnd()

    int npix = 0;
    *p1 = 0;
    if distEnd > 0)
    {
        *p1 = CoverType((self).mRen[].cover(s1)
        inc npix
    }
    inc p1

    dy = 1;
    while (dist = base(self).mDist[dy] - s1) <= base(self).mWidth)
    {
        distEnd -= self.mDi.dxEnd()
        *p1 = 0;
        if distEnd > 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc p1
        inc dy
    }

    dy = 1;
    distEnd = self.mDi.distEnd()
    while (dist = base(self).mDist[dy] + s1) <= base(self).mWidth)
    {
        distEnd += self.mDi.dxEnd()
        *--p0 = 0;
        if distEnd > 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc dy
    }
    base(self).mRen[].blendSolidVspan(base(self).mX,
                                       base(self).mY - dy + 1,
                                       p1 - p0,
                                       p0)
    return npix and ++base(self).mStep < base(self).mCount;
}

bool stepVer()
{
    int distEnd;
    int dist;
    int dx;
    int s1 = base(self).stepVerBase(self.mDi)
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    distEnd = self.mDi.distEnd()

    int npix = 0;
    *p1 = 0;
    if distEnd > 0)
    {
        *p1 = CoverType((self).mRen[].cover(s1)
        inc npix
    }
    inc p1

    dx = 1;
    while (dist = base(self).mDist[dx] - s1) <= base(self).mWidth)
    {
        distEnd += self.mDi.dyEnd()
        *p1 = 0;
        if distEnd > 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc p1
        inc dx
    }

    dx = 1;
    distEnd = self.mDi.distEnd()
    while (dist = base(self).mDist[dx] + s1) <= base(self).mWidth)
    {
        distEnd -= self.mDi.dyEnd()
        *--p0 = 0;
        if distEnd > 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc dx
    }
    base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                       base(self).mY,
                                       p1 - p0,
                                       p0)
    return npix and ++base(self).mStep < base(self).mCount;
}


    

[Renderer> class line_interpolator_aa3 :
object of LineInterpolatorAABase[Renderer]
distance_interpolator3 self.mDi;   


line_interpolator_aa3(ren: var Renderer, lp: var LineParameters,
                      sx, sy, ex, ey: int) :
    LineInterpolatorAABase[Renderer](ren, lp),
    self.mDi(lp.x1, lp.y1, lp.x2, lp.y2, sx, sy, ex, ey,
         lp.x1 and not(lineSubpixelMask, lp.y1 and not(lineSubpixelMask)
{
    int dist1_start;
    int dist2_start;
    int npix = 1;
    if lp.vertical)
    {
        do
        {
            --base(self).mLi;
            base(self).mY -= lp.inc;
            base(self).mX = (base(self).mLp[].x1 + base(self).mLi.y()) shr lineSubpixelShift;

            if lp.inc > 0) self.mDi.decY(base(self).mX - base(self).mOldX)
            else           self.mDi.incY(base(self).mX - base(self).mOldX)

            base(self).mOldX = base(self).mX;

            dist1_start = dist2_start = self.mDi.distStart()

            int dx = 0;
            if dist1_start < 0) inc npix
            do
            {
                dist1_start += self.mDi.dyStart()
                dist2_start -= self.mDi.dyStart()
                if dist1_start < 0) inc npix
                if dist2_start < 0) inc npix
                inc dx
            }
            while base(self).mDist[dx] <= base(self).mWidth)
            if npix == 0: break;
            npix = 0;
        }
        while --base(self).mStep >= -base(self).mMaxExtent)
    }
    else:
    {
        do
        {
            --base(self).mLi;
            base(self).mX -= lp.inc;
            base(self).mY = (base(self).mLp[].y1 + base(self).mLi.y()) shr lineSubpixelShift;

            if lp.inc > 0) self.mDi.decX(base(self).mY - base(self).mOldY)
            else           self.mDi.incX(base(self).mY - base(self).mOldY)

            base(self).mOldY = base(self).mY;

            dist1_start = dist2_start = self.mDi.distStart()

            int dy = 0;
            if dist1_start < 0) inc npix
            do
            {
                dist1_start -= self.mDi.dxStart()
                dist2_start += self.mDi.dxStart()
                if dist1_start < 0) inc npix
                if dist2_start < 0) inc npix
                inc dy
            }
            while base(self).mDist[dy] <= base(self).mWidth)
            if npix == 0: break;
            npix = 0;
        }
        while --base(self).mStep >= -base(self).mMaxExtent)
    }
    base(self).mLi.adjustForward()
    base(self).mStep -= base(self).mMaxExtent;
}

bool stepHor()
{
    int distStart;
    int distEnd;
    int dist;
    int dy;
    int s1 = base(self).stepHorBase(self.mDi)
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()

    int npix = 0;
    *p1 = 0;
    if distEnd > 0)
    {
        if distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(s1)
        }
        inc npix
    }
    inc p1

    dy = 1;
    while (dist = base(self).mDist[dy] - s1) <= base(self).mWidth)
    {
        distStart -= self.mDi.dxStart()
        distEnd   -= self.mDi.dxEnd()
        *p1 = 0;
        if distEnd > 0 and distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc p1
        inc dy
    }

    dy = 1;
    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()
    while (dist = base(self).mDist[dy] + s1) <= base(self).mWidth)
    {
        distStart += self.mDi.dxStart()
        distEnd   += self.mDi.dxEnd()
        *--p0 = 0;
        if distEnd > 0 and distStart <= 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc dy
    }
    base(self).mRen[].blendSolidVspan(base(self).mX,
                                       base(self).mY - dy + 1,
                                       p1 - p0,
                                       p0)
    return npix and ++base(self).mStep < base(self).mCount;
}

bool stepVer()
{
    int distStart;
    int distEnd;
    int dist;
    int dx;
    int s1 = base(self).stepVerBase(self.mDi)
    CoverType* p0 = base(self).mCovers + base(self).maxHalfWidth + 2;
    CoverType* p1 = p0;

    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()

    int npix = 0;
    *p1 = 0;
    if distEnd > 0)
    {
        if distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(s1)
        }
        inc npix
    }
    inc p1

    dx = 1;
    while (dist = base(self).mDist[dx] - s1) <= base(self).mWidth)
    {
        distStart += self.mDi.dyStart()
        distEnd   += self.mDi.dyEnd()
        *p1 = 0;
        if distEnd > 0 and distStart <= 0)
        {
            *p1 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc p1
        inc dx
    }

    dx = 1;
    distStart = self.mDi.distStart()
    distEnd   = self.mDi.distEnd()
    while (dist = base(self).mDist[dx] + s1) <= base(self).mWidth)
    {
        distStart -= self.mDi.dyStart()
        distEnd   -= self.mDi.dyEnd()
        *--p0 = 0;
        if distEnd > 0 and distStart <= 0)
        {
            *p0 = CoverType((self).mRen[].cover(dist)
            inc npix
        }
        inc dx
    }
    base(self).mRen[].blendSolidHspan(base(self).mX - dx + 1,
                                       base(self).mY,
                                       p1 - p0,
                                       p0)
    return npix and ++base(self).mStep < base(self).mCount;
}



    




class line_profile_aa

    pod_array<ValueType> self.mProfile;
    ValueType            m_gamma[aa_scale];
    int                   m_subpixel_width;
    float64                m_min_width;
    float64                self.mSmoother_width;



    typedef int8u ValueType;
    enum subPixelScale_e
    {
        subPixelShift = lineSubpixelShift,
        subPixelScale = 1 shl subPixelShift,
        subpixel_mask  = subPixelScale - 1
    };

    enum aa_scale_e
    {
        aa_shift = 8,
        aa_scale = 1 shl aa_shift,
        aa_mask  = aa_scale - 1
    };

    #---------------------------------------------------------------------
    line_profile_aa() :
        m_subpixel_width(0),
        m_min_width(1.0),
        self.mSmoother_width(1.0)
    {
        int i;
        for(i = 0; i < aa_scale; i++) m_gamma[i] = (ValueType)i;
    }

    #---------------------------------------------------------------------
    [GammaF>
    line_profile_aa(float64 w, const GammaF& gamma_function) :
        m_subpixel_width(0),
        m_min_width(1.0),
        self.mSmoother_width(1.0)
    {
        gamma(gamma_function)
        width(w)
    }

    #---------------------------------------------------------------------
proc min_width(float64 w) = m_min_width = w
proc smoother_width(float64 w) = self.mSmoother_width = w

    #---------------------------------------------------------------------
    [GammaF> void gamma(const GammaF& gamma_function)
    {
        int i;
        for(i = 0; i < aa_scale; i++)
        {
            m_gamma[i] = ValueType(
                uround(gamma_function(float64(i) / aa_mask) * aa_mask))
        }
    }

proc width(float64 w)

    unsigned profile_size(): float64 = self.mProfile.len }
    int subpixel_width(): float64 = m_subpixel_width

    #---------------------------------------------------------------------
    float64 min_width(): float64 = m_min_width
    float64 smoother_width(): float64 = self.mSmoother_width

    #---------------------------------------------------------------------
    ValueType value(int dist) const
    {
        return self.mProfile[dist + subPixelScale*2];
    }

private:
    line_profile_aa(const line_profile_aa&)
    const line_profile_aa& operator = (const line_profile_aa&)

    ValueType* profile(float64 w)
proc set(float64 center_width, float64 smoother_width)



[BaseRenderer> class renderer_outline_aa
    mRen: ptr Renderer
    mProfile: ptr LineProfileAA
    mColor: ColorT
    mClipBox: RectI
    mClipping: bool
    
    typedef BaseRenderer base_ren_type;
    typedef renderer_outline_aa<base_ren_type> self_type;
    typedef typename base_ren_type::ColorT ColorT;

    renderer_outline_aa(base_ren_type& ren, const line_profile_aa& prof) :
        self.mRen(&ren),
        self.mProfile(&prof),
        self.mClipBox(0,0,0,0),
        self.mClipping(false)

proc attach(base_ren_type& ren) = self.mRen = &ren

proc color(c: ColorT) = self.mColor = c
  c: ColorTolor(): float64 = self.mColor

proc profile(const line_profile_aa& prof) = self.mProfile = &prof
const line_profile_aa& profile(): float64 = *self.mProfile
line_profile_aa& profile() = return *self.mProfile

int subpixel_width(): float64 = self.mProfile->subpixel_width()

proc resetClipping() = self.mClipping = false
proc clipBox(x1, y1, x2, y2: float64)
  self.mClipBox.x1 = line_coord_sat::conv(x1)
  self.mClipBox.y1 = line_coord_sat::conv(y1)
  self.mClipBox.x2 = line_coord_sat::conv(x2)
  self.mClipBox.y2 = line_coord_sat::conv(y2)
  self.mClipping = true

int cover(int d) const
  return self.mProfile->value(d)

proc blendSolidHspan(x, y, len: int, covers: ptr CoverType)
  self.mRen[].blendSolidHspan(x, y, len, self.mColor, covers)

proc blendSolidVspan(x, y, len: int, covers: ptr CoverType)
  self.mRen[].blendSolidVspan(x, y, len, self.mColor, covers)

static bool accurateJoinOnly() = return false

[Cmp>
proc semidot_hline(Cmp cmp, xc1, yc1, xc2, yc2, x1, y1, x2: int)

  cover: CoverTypes[line_interpolator_aa_base<self_type>::maxHalfWidth * 2 + 4];
  CoverType* p0 = covers;
  CoverType* p1 = covers;
  int x = x1 shl lineSubpixelShift;
  int y = y1 shl lineSubpixelShift;
  int w = subpixel_width()
  distance_interpolator0 di(xc1, yc1, xc2, yc2, x, y)
  x += lineSubpixelScale/2;
  y += lineSubpixelScale/2;

  int x0 = x1;
  int dx = x - xc1;
  int dy = y - yc1;
  do
  {
      int d = int(fast_sqrt(dx*dx + dy*dy))
      *p1 = 0;
      if cmp(di.dist()) and d <= w)
      {
          *p1 = (CoverType)cover(d)
      }
      inc p1
      dx += lineSubpixelScale;
      di.incX()
  }
  while ++x1 <= x2)
  self.mRen[].blendSolidHspan(x0, y1,
                          p1 - p0,
                          color(),
                          p0)



    [Cmp>
proc semidot(Cmp cmp, xc1, yc1, xc2, yc2: int)
  if self.mClipping and clipping_flags(xc1, yc1, self.mClipBox)) return;

  int r = ((subpixel_width() + lineSubpixelMask) shr lineSubpixelShift)
  if r < 1) r = 1;
  ellipse_bresenhaself.mInterpolator ei(r, r)
  int dx = 0;
  int dy = -r;
  int dy0 = dy;
  int dx0 = dx;
  int x = xc1 shr lineSubpixelShift;
  int y = yc1 shr lineSubpixelShift;

  do
  {
      dx += ei.dx()
      dy += ei.dy()

      if dy != dy0)
      {
          semidot_hline(cmp, xc1, yc1, xc2, yc2, x-dx0, y+dy0, x+dx0)
          semidot_hline(cmp, xc1, yc1, xc2, yc2, x-dx0, y-dy0, x+dx0)
      }
      dx0 = dx;
      dy0 = dy;
      ++ei;
  }
  while dy < 0)
  semidot_hline(cmp, xc1, yc1, xc2, yc2, x-dx0, y+dy0, x+dx0)


proc pie_hline(xc, yc, xp1, yp1, xp2, yp2, xh1, yh1, xh2: int)

  if self.mClipping and clipping_flags(xc, yc, self.mClipBox)) return;

  cover: CoverTypes[line_interpolator_aa_base<self_type>::maxHalfWidth * 2 + 4];
  CoverType* p0 = covers;
  CoverType* p1 = covers;
  int x = xh1 shl lineSubpixelShift;
  int y = yh1 shl lineSubpixelShift;
  int w = subpixel_width()

  distance_interpolator00 di(xc, yc, xp1, yp1, xp2, yp2, x, y)
  x += lineSubpixelScale/2;
  y += lineSubpixelScale/2;

  int xh0 = xh1;
  int dx = x - xc;
  int dy = y - yc;
  do
  {
      int d = int(fast_sqrt(dx*dx + dy*dy))
      *p1 = 0;
      if di.dist1() <= 0 and di.dist2() > 0 and d <= w)
      {
          *p1 = (CoverType)cover(d)
      }
      inc p1
      dx += lineSubpixelScale;
      di.incX()
  }
  while ++xh1 <= xh2)
  self.mRen[].blendSolidHspan(xh0, yh1,
                            p1 - p0,
                            color(),
                            p0)



proc pie(int xc, int yc, x1, y1, x2, y2: int)
  int r = ((subpixel_width() + lineSubpixelMask) shr lineSubpixelShift)
  if r < 1) r = 1;
  ellipse_bresenhaself.mInterpolator ei(r, r)
  int dx = 0;
  int dy = -r;
  int dy0 = dy;
  int dx0 = dx;
  int x = xc shr lineSubpixelShift;
  int y = yc shr lineSubpixelShift;

  do
  {
      dx += ei.dx()
      dy += ei.dy()

      if dy != dy0)
      {
          pie_hline(xc, yc, x1, y1, x2, y2, x-dx0, y+dy0, x+dx0)
          pie_hline(xc, yc, x1, y1, x2, y2, x-dx0, y-dy0, x+dx0)
      }
      dx0 = dx;
      dy0 = dy;
      ++ei;
  }
  while dy < 0)
  pie_hline(xc, yc, x1, y1, x2, y2, x-dx0, y+dy0, x+dx0)


proc line0_no_clip(lp: var LineParameters)
  if lp.len > lineMaxLength)
  {
      line_parameters lp1, lp2;
      lp.divide(lp1, lp2)
      line0_no_clip(lp1)
      line0_no_clip(lp2)
      return;
  }

  line_interpolator_aa0<self_type> li(*this, lp)
  if li.count())
  {
      if li.vertical())
      {
          while li.stepVer())
      }
      else:
      {
          while li.stepHor())
      }
  }


proc line0(lp: var LineParameters)
  if self.mClipping)
  {
      int x1 = lp.x1;
      int y1 = lp.y1;
      int x2 = lp.x2;
      int y2 = lp.y2;
      unsigned flags = clipLineSegment(&x1, &y1, &x2, &y2, self.mClipBox)
      if (flags & 4) == 0:
      {
          if flags)
          {
              line_parameters lp2(x1, y1, x2, y2,
                                uround(calcDistance(x1, y1, x2, y2)))
              line0_no_clip(lp2)
          }
          else:
          {
              line0_no_clip(lp)
          }
      }
  }
  else:
  {
      line0_no_clip(lp)
  }


proc line1_no_clip(lp: var LineParameters, sx, sy: int)
  if lp.len > lineMaxLength)
  {
      line_parameters lp1, lp2;
      lp.divide(lp1, lp2)
      line1_no_clip(lp1, (lp.x1 + sx) shr 1, (lp.y1 + sy) shr 1)
      line1_no_clip(lp2, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1))
      return;
  }

  fix_degenerate_bisectrix_start(lp, &sx, &sy)
  line_interpolator_aa1<self_type> li(*this, lp, sx, sy)
  if li.vertical())
  {
      while li.stepVer())
  }
  else:
  {
      while li.stepHor())
  }



proc line1(lp: var LineParameters, sx, sy: int)
  if self.mClipping)
  {
      int x1 = lp.x1;
      int y1 = lp.y1;
      int x2 = lp.x2;
      int y2 = lp.y2;
      unsigned flags = clipLineSegment(&x1, &y1, &x2, &y2, self.mClipBox)
      if (flags & 4) == 0:
      {
          if flags)
          {
              line_parameters lp2(x1, y1, x2, y2,
                                uround(calcDistance(x1, y1, x2, y2)))
              if flags & 1)
              {
                  sx = x1 + (y2 - y1)
                  sy = y1 - (x2 - x1)
              }
              else:
              {
                  while abs(sx - lp.x1) + abs(sy - lp.y1) > lp2.len)
                  {
                      sx = (lp.x1 + sx) shr 1;
                      sy = (lp.y1 + sy) shr 1;
                  }
              }
              line1_no_clip(lp2, sx, sy)
          }
          else:
          {
              line1_no_clip(lp, sx, sy)
          }
      }
  }
  else:
  {
      line1_no_clip(lp, sx, sy)
  }


proc line2NoClip(lp: var LineParameters, ex, ey: int)
  if lp.len > lineMaxLength)
  {
      line_parameters lp1, lp2;
      lp.divide(lp1, lp2)
      line2NoClip(lp1, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1))
      line2NoClip(lp2, (lp.x2 + ex) shr 1, (lp.y2 + ey) shr 1)
      return;
  }

  fix_degenerate_bisectrix_end(lp, &ex, &ey)
  line_interpolator_aa2<self_type> li(*this, lp, ex, ey)
  if li.vertical())
  {
      while li.stepVer())
  }
  else:
  {
      while li.stepHor())
  }


proc line2(lp: var LineParameters, ex, ey: int)
  if self.mClipping)
  {
      int x1 = lp.x1;
      int y1 = lp.y1;
      int x2 = lp.x2;
      int y2 = lp.y2;
      unsigned flags = clipLineSegment(&x1, &y1, &x2, &y2, self.mClipBox)
      if (flags & 4) == 0:
      {
          if flags)
          {
              line_parameters lp2(x1, y1, x2, y2,
                                uround(calcDistance(x1, y1, x2, y2)))
              if flags & 2)
              {
                  ex = x2 + (y2 - y1)
                  ey = y2 - (x2 - x1)
              }
              else:
              {
                  while abs(ex - lp.x2) + abs(ey - lp.y2) > lp2.len)
                  {
                      ex = (lp.x2 + ex) shr 1;
                      ey = (lp.y2 + ey) shr 1;
                  }
              }
              line2NoClip(lp2, ex, ey)
          }
          else:
          {
              line2NoClip(lp, ex, ey)
          }
      }
  }
  else:
  {
      line2NoClip(lp, ex, ey)
  }


proc line3NoClip(lp: var LineParameters, sx, sy, ex, ey: int)
  if lp.len > lineMaxLength)
  {
      line_parameters lp1, lp2;
      lp.divide(lp1, lp2)
      int mx = lp1.x2 + (lp1.y2 - lp1.y1)
      int my = lp1.y2 - (lp1.x2 - lp1.x1)
      line3NoClip(lp1, (lp.x1 + sx) shr 1, (lp.y1 + sy) shr 1, mx, my)
      line3NoClip(lp2, mx, my, (lp.x2 + ex) shr 1, (lp.y2 + ey) shr 1)
      return;
  }

  fix_degenerate_bisectrix_start(lp, &sx, &sy)
  fix_degenerate_bisectrix_end(lp, &ex, &ey)
  line_interpolator_aa3<self_type> li(*this, lp, sx, sy, ex, ey)
  if li.vertical())
  {
      while li.stepVer())
  }
  else:
  {
      while li.stepHor())
  }


proc line3(lp: var LineParameters, sx, sy, ex, ey: int)
  if self.mClipping)
  {
      int x1 = lp.x1;
      int y1 = lp.y1;
      int x2 = lp.x2;
      int y2 = lp.y2;
      unsigned flags = clipLineSegment(&x1, &y1, &x2, &y2, self.mClipBox)
      if (flags & 4) == 0:
      {
          if flags)
          {
              line_parameters lp2(x1, y1, x2, y2,
                                uround(calcDistance(x1, y1, x2, y2)))
              if flags & 1)
              {
                  sx = x1 + (y2 - y1)
                  sy = y1 - (x2 - x1)
              }
              else:
              {
                  while abs(sx - lp.x1) + abs(sy - lp.y1) > lp2.len)
                  {
                      sx = (lp.x1 + sx) shr 1;
                      sy = (lp.y1 + sy) shr 1;
                  }
              }
              if flags & 2)
              {
                  ex = x2 + (y2 - y1)
                  ey = y2 - (x2 - x1)
              }
              else:
              {
                  while abs(ex - lp.x2) + abs(ey - lp.y2) > lp2.len)
                  {
                      ex = (lp.x2 + ex) shr 1;
                      ey = (lp.y2 + ey) shr 1;
                  }
              }
              line3NoClip(lp2, sx, sy, ex, ey)
          }
          else:
          {
              line3NoClip(lp, sx, sy, ex, ey)
          }
      }
  }
  else:
  {
      line3NoClip(lp, sx, sy, ex, ey)
  }

]#