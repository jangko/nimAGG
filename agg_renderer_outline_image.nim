import agg_math, agg_line_aa_basics, agg_dda_line
import agg_clip_liang_barsky, agg_rendering_buffer
import agg_basics, agg_color_rgba, agg_pixfmt_rgb
import agg_pattern_filters_rgba

type
  LineImageScale*[Source] = object
    mSource: ptr Source
    mHeight, mScale: float64

proc initLineImageScale*[Source](src: var Source, height: float64): LineImageScale[Source] =
  result.mSource = src.addr
  result.mHeight = height
  result.mScale  = src.height() / height

proc width*[Source](self: LineImageScale[Source]): float64 = self.mSource.width()
proc height*[Source](self: LineImageScale[Source]): float64 = self.mHeight

proc pixel*[Source](self: LineImageScale[Source], x, y: int): auto =
  let
    srcY = (y + 0.5) * self.mScale - 0.5
    h  = self.mSource.height() - 1
    y1 = ufloor(srcY)
    y2 = y1 + 1
    pix1 = if y1 < 0: noColor(getColorT(Source)) else: self.mSource.pixel(x, y1)
    pix2 = if y2 > h: noColor(getColorT(Source)) else: self.mSource.pixel(x, y2)
  result = pix1.gradient(pix2, srcY - y1)

type
  LineImagePattern*[Filter, ColorT] = object of RootObj
    mBuf: RowPtrCache[ColorT]
    mFilter: ptr Filter
    mDilation: int
    mDilationHr: int
    mData: seq[ColorT]
    mWidth, mHeight: int
    mWidthHr: int
    mHalfHeightHr: int
    mOffsetYHr: int

proc init[Filter, ColorT](self: var LineImagePattern[Filter, ColorT], filter: var Filter) =
  self.mBuf = initRowPtrCache[ColorT]()
  self.mFilter = filter.addr
  self.mDilation = dilation(Filter) + 1
  self.mDilationHr = self.mDilation shl lineSubpixelShift
  self.mData = @[]
  self.mWidth = 0
  self.mHeight = 0
  self.mWidthHr = 0
  self.mHalfHeightHr = 0
  self.mOffsetYHr = 0

proc initLineImagePatternAux[Filter, ColorT](filter: var Filter): LineImagePattern[Filter, ColorT] =
  result.init(filter)

proc initLineImagePattern*[Filter](filter: var Filter): auto =
  result = initLineImagePatternAux[Filter, getColorT(Filter)](filter)

proc create*[Filter, Source, ColorT](self: var LineImagePattern[Filter, ColorT], src: Source)

proc init[Filter, Source, ColorT](self: var LineImagePattern[Filter, ColorT], filter: var Filter, src: var Source) =
  self.mBuf = initRowPtrCache[ColorT]()
  self.mFilter = filter.addr
  self.mDilation = filter.dilation() + 1
  self.mDilationHr = self.mDilation shl lineSubpixelShift
  self.mData = @[]
  self.mWidth = 0
  self.mHeight = 0
  self.mWidthHr = 0
  self.mHalfHeightHr = 0
  self.mOffsetYHr = 0
  self.create(src)

proc initLineImagePatternAux[Filter, Source, ColorT](filter: var Filter, src: var Source): LineImagePattern[Filter, ColorT] =
  result.init(filter, src)

proc initLineImagePattern*[Filter, Source](filter: var Filter, src: var Source): auto =
  result = initLineImagePatternAux[Filter, Source, getColorT(Filter)](filter, src)

proc create[Filter, Source, ColorT](self: var LineImagePattern[Filter, ColorT], src: Source) =
  self.mHeight  = int(uceil(src.height().float64))
  self.mWidth   = int(uceil(src.width().float64))
  
  self.mWidthHr = uround(src.width().float64 * lineSubpixelScale)
  self.mHalfHeightHr  = uround(src.height().float64 * lineSubpixelScale / 2)
  self.mOffsetYHr     = self.mDilationHr + self.mHalfHeightHr - lineSubpixelScale div 2
  self.mHalfHeightHr += lineSubpixelScale div 2
  self.mData.setLen((self.mWidth + self.mDilation * 2) * (self.mHeight + self.mDilation * 2))
  self.mBuf.attach(self.mData[0].addr,
    self.mWidth  + self.mDilation * 2,
    self.mHeight + self.mDilation * 2,
    self.mWidth  + self.mDilation * 2)

  var d1, d2: ptr ColorT

  for y in 0.. <self.mHeight:
    d1 = self.mBuf.rowPtr(y + self.mDilation) + self.mDilation
    for x in 0.. <self.mWidth:
      d1[] = src.pixel(x, y)
      inc d1

  var
    s1, s2: ptr ColorT

  for y in 0.. <self.mDilation:
    #s1 = self.mBuf.rowPtr(self.mHeight + self.mDilation - 1) + self.mDilation;
    #s2 = self.mBuf.rowPtr(self.mDilation) + self.mDilation;
    d1 = self.mBuf.rowPtr(self.mDilation + self.mHeight + y) + self.mDilation
    d2 = self.mBuf.rowPtr(self.mDilation - y - 1) + self.mDilation
    for x in 0.. <self.mWidth:
      #*d1++ = ColorT(*s1++, 0)
      #*d2++ = ColorT(*s2++, 0)
      d1[] = noColor(ColorT)
      d2[] = noColor(ColorT)
      inc d1
      inc d2

  let h = self.mHeight + self.mDilation * 2
  for y in 0.. <h:
    s1 = self.mBuf.rowPtr(y) + self.mDilation
    s2 = self.mBuf.rowPtr(y) + self.mDilation + self.mWidth
    d1 = self.mBuf.rowPtr(y) + self.mDilation + self.mWidth
    d2 = self.mBuf.rowPtr(y) + self.mDilation

    for x in 0..<self.mDilation:
      d1[] = s1[]
      inc d1
      inc s1
      dec d2
      dec s2
      d2[] = s2[]

proc patternWidth*[Filter, ColorT](self: LineImagePattern[Filter, ColorT]): int =
  self.mWidthHr

proc lineWidth*[Filter, ColorT](self: LineImagePattern[Filter, ColorT]): int =
  self.mHalfHeightHr

proc width*[Filter, ColorT](self: LineImagePattern[Filter, ColorT]): float64 =
  self.mHeight

proc pixel*[Filter, ColorT](self: var LineImagePattern[Filter, ColorT], p: ptr ColorT, x, y: int) =
  pixelHighRes(Filter, self.mBuf.rows(),
    p, x mod self.mWidthHr + self.mDilationHr, y + self.mOffsetYHr)

proc filter*[Filter, ColorT](self: LineImagePattern[Filter, ColorT]): var Filter = self.mFilter[]

type
  LineImagePatternPow2*[Filter, ColorT] = object of LineImagePattern[Filter, ColorT]
    mMask: uint

proc create*[Filter, ColorT, Source](self: var LineImagePatternPow2[Filter, ColorT], src: Source)

proc initLineImagePatternPow2Aux*[Filter, ColorT](filter: var Filter): LineImagePatternPow2[Filter, ColorT] =
  type base = LineImagePattern[Filter, ColorT]
  base(result).init(filter)
  result.mMask = lineSubpixelMask

proc initLineImagePatternPow2*[Filter, ColorT](filter: var Filter): LineImagePatternPow2[Filter, ColorT] =
  result = initLineImagePatternPow2Aux[Filter, getColorT(Filter)](filter)

proc initLineImagePatternPow2Aux*[Filter, ColorT, Source](filter: var Filter,
  src: var Source): LineImagePatternPow2[Filter, ColorT] =
  type base = LineImagePattern[Filter, ColorT]
  base(result).init(filter)
  result.mMask = lineSubpixelMask
  result.create(src)

proc initLineImagePatternPow2*[Filter, ColorT, Source](filter: var Filter,
  src: var Source): LineImagePatternPow2[Filter, ColorT] =
  result = initLineImagePatternPow2Aux[Filter, getColorT(Filter)](filter, src)

proc create[Filter, ColorT, Source](self: var LineImagePatternPow2[Filter, ColorT], src: Source) =
  type base = LineImagePattern[Filter, ColorT]
  base(self).create(src)

  self.mMask = 1
  while self.mMask < self.mWidth:
    self.mMask = self.mMask shl 1
    self.mMask = self.mMask or 1

  self.mMask = self.mMask shl lineSubpixelShift - 1
  self.mMask = self.mMask or lineSubpixelMask
  self.mWidthHr = self.mMask + 1

proc pixel*[Filter, ColorT](self: LineImagePatternPow2[Filter, ColorT], p: ptr ColorT, x, y: int) =
  type base = LineImagePattern[Filter, ColorT]
  self.mFilter[].pixelHighRes(base(self).self.mBuf.rows(),
    p, (x and self.mMask) + self.mDilationHr, y + self.mOffsetYHr)

type
  DistanceInterpolator4* = object
    mDx, mDy, mDxStart, mDyStart: int
    mDxPict, mDyPict, mDxEnd, mDyEnd: int
    mDist, mDistStart, mDistPict: int
    mDistEnd, mLen: int

proc initDistanceInterpolator4*(x1, y1, x2, y2, sx, sy, ex, ey, len: int,
  scale: float64, x, y: int): DistanceInterpolator4 =
  result.mDx = x2 - x1
  result.mDy = y2 - y1
  result.mDxStart = lineMr(sx) - lineMr(x1)
  result.mDyStart = lineMr(sy) - lineMr(y1)
  result.mDxEnd = lineMr(ex) - lineMr(x2)
  result.mDyEnd = lineMr(ey) - lineMr(y2)

  result.mDist = iround(float64(x + lineSubpixelScale div 2 - x2) *
    float64(result.mDy) -
    float64(y + lineSubpixelScale div 2 - y2) *
    float64(result.mDx))

  result.mDistStart = (lineMr(x + lineSubpixelScale div 2) - lineMr(sx)) * result.mDyStart -
                    (lineMr(y + lineSubpixelScale div 2) - lineMr(sy)) * result.mDxStart

  result.mDistEnd = (lineMr(x + lineSubpixelScale div 2) - lineMr(ex)) * result.mDyEnd -
                  (lineMr(y + lineSubpixelScale div 2) - lineMr(ey)) * result.mDxEnd

  result.mLen = uround(len.float64 / scale)

  var
    d = len.float64 * scale
    dx = iround(float64((x2 - x1) shl lineSubpixelShift) / d)
    dy = iround(float64((y2 - y1) shl lineSubpixelShift) / d)

  result.mDxPict   = -dy
  result.mDyPict   =  dx
  result.mDistPict = ((x + lineSubpixelScale div 2 - (x1 - dy)) * result.mDyPict -
                      (y + lineSubpixelScale div 2 - (y1 + dx)) * result.mDxPict) shr lineSubpixelShift

  result.mDx      = result.mDx      shl lineSubpixelShift
  result.mDy      = result.mDy      shl lineSubpixelShift
  result.mDxStart = result.mDxStart shl lineMr_subPixelShift
  result.mDyStart = result.mDyStart shl lineMr_subPixelShift
  result.mDxEnd   = result.mDxEnd   shl lineMr_subPixelShift
  result.mDyEnd   = result.mDyEnd   shl lineMr_subPixelShift

proc incX*(self: var DistanceInterpolator4) =
  self.mDist      += self.mDy
  self.mDistStart += self.mDyStart
  self.mDistPict  += self.mDyPict
  self.mDistEnd   += self.mDyEnd

proc decX*(self: var DistanceInterpolator4) =
  self.mDist      -= self.mDy
  self.mDistStart -= self.mDyStart
  self.mDistPict  -= self.mDyPict
  self.mDistEnd   -= self.mDyEnd

proc incY*(self: var DistanceInterpolator4) =
  self.mDist      -= self.mDx
  self.mDistStart -= self.mDxStart
  self.mDistPict  -= self.mDxPict
  self.mDistEnd   -= self.mDxEnd

proc decY*(self: var DistanceInterpolator4) =
  self.mDist      += self.mDx
  self.mDistStart += self.mDxStart
  self.mDistPict  += self.mDxPict
  self.mDistEnd   += self.mDxEnd

proc incX*(self: var DistanceInterpolator4, dy: int) =
  self.mDist      += self.mDy
  self.mDistStart += self.mDyStart
  self.mDistPict  += self.mDyPict
  self.mDistEnd   += self.mDyEnd
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart
    self.mDistPict  -= self.mDxPict
    self.mDistEnd   -= self.mDxEnd
  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart
    self.mDistPict  += self.mDxPict
    self.mDistEnd   += self.mDxEnd

proc decX*(self: var DistanceInterpolator4, dy: int) =
  self.mDist      -= self.mDy
  self.mDistStart -= self.mDyStart
  self.mDistPict  -= self.mDyPict
  self.mDistEnd   -= self.mDyEnd
  if dy > 0:
    self.mDist      -= self.mDx
    self.mDistStart -= self.mDxStart
    self.mDistPict  -= self.mDxPict
    self.mDistEnd   -= self.mDxEnd
  if dy < 0:
    self.mDist      += self.mDx
    self.mDistStart += self.mDxStart
    self.mDistPict  += self.mDxPict
    self.mDistEnd   += self.mDxEnd

proc incY*(self: var DistanceInterpolator4, dx: int) =
  self.mDist      -= self.mDx
  self.mDistStart -= self.mDxStart
  self.mDistPict  -= self.mDxPict
  self.mDistEnd   -= self.mDxEnd
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart
    self.mDistPict  += self.mDyPict
    self.mDistEnd   += self.mDyEnd
  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart
    self.mDistPict  -= self.mDyPict
    self.mDistEnd   -= self.mDyEnd

proc decY*(self: var DistanceInterpolator4, dx: int) =
  self.mDist      += self.mDx
  self.mDistStart += self.mDxStart
  self.mDistPict  += self.mDxPict
  self.mDistEnd   += self.mDxEnd
  if dx > 0:
    self.mDist      += self.mDy
    self.mDistStart += self.mDyStart
    self.mDistPict  += self.mDyPict
    self.mDistEnd   += self.mDyEnd
  if dx < 0:
    self.mDist      -= self.mDy
    self.mDistStart -= self.mDyStart
    self.mDistPict  -= self.mDyPict
    self.mDistEnd   -= self.mDyEnd

proc dist*(self: DistanceInterpolator4): int = self.mDist
proc distStart*(self: DistanceInterpolator4): int = self.mDistStart
proc distPict*(self: DistanceInterpolator4): int = self.mDistPict
proc distEnd*(self: DistanceInterpolator4): int = self.mDistEnd
proc dx*(self: DistanceInterpolator4): int =  self.mDx
proc dy*(self: DistanceInterpolator4): int =  self.mDy
proc dxStart*(self: DistanceInterpolator4): int = self.mDxStart
proc dyStart*(self: DistanceInterpolator4): int = self.mDyStart
proc dxPict*(self: DistanceInterpolator4): int = self.mDxPict
proc dyPict*(self: DistanceInterpolator4): int = self.mDyPict
proc dxEnd*(self: DistanceInterpolator4): int = self.mDxEnd
proc dyEnd*(self: DistanceInterpolator4): int = self.mDyEnd
proc len*(self: DistanceInterpolator4): int = self.mLen

const
  MaxHalfWidth = 64

type
  LineInterpolatorImage*[Renderer, ColorT] = object
    mLp: ptr LineParameters
    mLi: Dda2LineInterpolator
    mDi: DistanceInterpolator4
    mRen: ptr Renderer
    mPlen, mX, mY: int
    mOldX, mOldY, mCount: int
    mWidth, mMaxExtent: int
    mStart, mStep: int
    mDistPos: array[MaxHalfWidth + 1, int]
    mColors: array[MaxHalfWidth * 2 + 4, ColorT]

proc initLineInterpolatorImageAux*[R,C](ren: var R, lp: var LineParameters,
  sx, sy, ex, ey, patternStart: int, scaleX: float64): LineInterpolatorImage[R, C] =
  mixin patternWidth, y
  result.mLp = lp.addr

  let
    xx = if lp.vertical: lineDblHr(lp.x2 - lp.x1) else: lineDblHr(lp.y2 - lp.y1)
    yy = if lp.vertical: abs(lp.y2 - lp.y1) else: abs(lp.x2 - lp.x1) + 1

  result.mLi = initDda2LineInterpolator(xx, yy)

  result.mDi = initDistanceInterpolator4(lp.x1, lp.y1, lp.x2, lp.y2, sx, sy, ex, ey,
    lp.len, scaleX, lp.x1 and (not lineSubpixelMask), lp.y1 and (not lineSubpixelMask))

  result.mRen = ren.addr
  result.mX = lp.x1 shr lineSubpixelShift
  result.mY = lp.y1 shr lineSubpixelShift
  result.mOldX = result.mX
  result.mOldY = result.mY

  let
    c1 = abs((lp.y2 shr lineSubpixelShift) - result.mY)
    c2 = abs((lp.x2 shr lineSubpixelShift) - result.mX)

  result.mCount = if lp.vertical: c1 else: c2
  result.mWidth = ren.subPixelWidth()
  #result.mMaxExtent = result.mWidth shr (lineSubpixelShift - 2)

  result.mMaxExtent = (result.mWidth + lineSubpixelScale) shr lineSubpixelShift
  result.mStart = patternStart + (result.mMaxExtent + 2) * ren.patternWidth()
  result.mStep = 0

  var
    dy = lp.dy shl lineSubpixelShift
    dx = lp.dx shl lineSubpixelShift
    li = initDda2LineInterpolator(0, if lp.vertical: dy else: dx, lp.len)
    stop = result.mWidth + lineSubpixelScale * 2

  for i in 0.. <MaxHalfWidth:
    result.mDistPos[i] = li.y()
    if result.mDistPos[i] >= stop: break
    inc li
  result.mDistPos[MaxHalfWidth] = 0x7FFF0000

  var
    dist1Start: int
    dist2Start: int
    npix = 1

  if lp.vertical:
    doWhile result.mStep >= -result.mMaxExtent:
      dec result.mLi
      result.mY -= lp.inc
      result.mX = (result.mLp.x1 + result.mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decY(result.mX - result.mOldX)
      else:          result.mDi.incY(result.mX - result.mOldX)
      result.mOldX = result.mX

      dist2Start = result.mDi.distStart()
      dist1Start = dist2Start

      var dx = 0
      if dist1Start < 0: inc npix
      doWhile result.mDistPos[dx] <= result.mWidth:
        dist1Start += result.mDi.dyStart()
        dist2Start -= result.mDi.dyStart()
        if dist1Start < 0: inc npix
        if dist2Start < 0: inc npix
        inc dx

      if npix == 0: break
      npix = 0
      dec result.mStep
  else:
    doWhile result.mStep >= -result.mMaxExtent:
      dec result.mLi
      result.mX -= lp.inc
      result.mY = (result.mLp.y1 + result.mLi.y()) shr lineSubpixelShift

      if lp.inc > 0: result.mDi.decX(result.mY - result.mOldY)
      else:          result.mDi.incX(result.mY - result.mOldY)
      result.mOldY = result.mY
      dist2Start = result.mDi.distStart()
      dist1Start = dist2Start

      var dy = 0
      if dist1Start < 0: inc npix
      doWhile result.mDistPos[dy] <= result.mWidth:
        dist1Start -= result.mDi.dxStart()
        dist2Start += result.mDi.dxStart()
        if dist1Start < 0: inc npix
        if dist2Start < 0: inc npix
        inc dy

      if npix == 0: break
      npix = 0
      dec result.mStep

  result.mLi.adjustForward()
  result.mStep -= result.mMaxExtent

proc initLineInterpolatorImage*[R](ren: var R, lp: var LineParameters,
  sx, sy, ex, ey, patternStart: int, scaleX: float64): auto =
  initLineInterpolatorImageAux[R, getColorT(R)](ren, lp, sx ,sy, ex, ey, patternStart, scaleX)

proc stepHor*[R,C](self: var LineInterpolatorImage[R, C]): bool =
  mixin blendColorVspan

  inc self.mLi
  self.mX += self.mLp.inc
  self.mY = (self.mLp.y1 + self.mLi.y()) shr lineSubpixelShift

  if self.mLp.inc > 0: self.mDi.incX(self.mY - self.mOldY)
  else:                self.mDi.decX(self.mY - self.mOldY)

  self.mOldY = self.mY

  var
    s1 = int(self.mDi.dist() / self.mLp.len)
    s2 = -s1

  if self.mLp.inc < 0: s1 = -s1

  var
    dy, dist: int
    distStart = self.mDi.distStart()
    distPict  = self.mDi.distPict() + self.mStart
    distEnd   = self.mDi.distEnd()
    p0 = self.mColors[0].addr + MaxHalfWidth + 2
    p1 = p0
    npix = 0

  p1[].clear()
  if distEnd > 0:
    if distStart <= 0:
      self.mRen[].pixel(p1, distPict, s2)
    inc npix
  inc p1

  dy = 1
  dist = self.mDistPos[dy]
  while dist - s1 <= self.mWidth:
    distStart -= self.mDi.dxStart()
    distPict  -= self.mDi.dxPict()
    distEnd   -= self.mDi.dxEnd()
    p1[].clear()
    if distEnd > 0 and distStart <= 0:
      if self.mLp.inc > 0: dist = -dist
      self.mRen[].pixel(p1, distPict, s2 - dist)
      inc npix
    inc p1
    inc dy
    dist = self.mDistPos[dy]

  dy = 1
  distStart = self.mDi.distStart()
  distPict  = self.mDi.distPict() + self.mStart
  distEnd   = self.mDi.distEnd()
  dist = self.mDistPos[dy]
  while dist + s1 <= self.mWidth:
    distStart += self.mDi.dxStart()
    distPict  += self.mDi.dxPict()
    distEnd   += self.mDi.dxEnd()
    dec p0
    p0[].clear()
    if distEnd > 0 and distStart <= 0:
      if self.mLp.inc > 0: dist = -dist
      self.mRen[].pixel(p0, distPict, s2 + dist)
      inc npix
    inc dy
    dist = self.mDistPos[dy]

  self.mRen[].blendColorVspan(self.mX, self.mY - dy + 1, cast[int](p1 - p0), p0)
  inc self.mStep

  result = npix != 0 and self.mStep < self.mCount


proc stepVer*[R,C](self: var LineInterpolatorImage[R, C]): bool =
  mixin blendColorHspan
  inc self.mLi
  self.mY += self.mLp.inc
  self.mX = (self.mLp.x1 + self.mLi.y()) shr lineSubpixelShift

  if self.mLp.inc > 0: self.mDi.incY(self.mX - self.mOldX)
  else:                self.mDi.decY(self.mX - self.mOldX)

  self.mOldX = self.mX

  var
    s1 = int(self.mDi.dist() / self.mLp.len)
    s2 = -s1

  if self.mLp.inc > 0: s1 = -s1

  var
    dist, dx: int
    distStart = self.mDi.distStart()
    distPict  = self.mDi.distPict() + self.mStart
    distEnd   = self.mDi.distEnd()
    p0 = self.mColors[0].addr + MaxHalfWidth + 2
    p1 = p0
    npix = 0

  p1[].clear()
  if distEnd > 0:
    if distStart <= 0:
      self.mRen[].pixel(p1, distPict, s2.int)
    inc npix
  inc p1

  dx = 1
  dist = self.mDistPos[dx]
  while dist - s1 <= self.mWidth:
    distStart += self.mDi.dyStart()
    distPict  += self.mDi.dyPict()
    distEnd   += self.mDi.dyEnd()
    p1[].clear()
    if distEnd > 0 and distStart <= 0:
      if self.mLp.inc > 0: dist = -dist
      self.mRen[].pixel(p1, distPict, s2 + dist)
      inc npix
    inc p1
    inc dx
    dist = self.mDistPos[dx]

  dx = 1
  distStart = self.mDi.distStart()
  distPict  = self.mDi.distPict() + self.mStart
  distEnd   = self.mDi.distEnd()
  dist = self.mDistPos[dx]
  while dist + s1 <= self.mWidth:
    distStart -= self.mDi.dyStart()
    distPict  -= self.mDi.dyPict()
    distEnd   -= self.mDi.dyEnd()
    dec p0
    p0[].clear()
    if distEnd > 0 and distStart <= 0:
      if self.mLp.inc > 0: dist = -dist
      self.mRen[].pixel(p0, distPict, s2 - dist)
      inc npix
    inc dx
    dist = self.mDistPos[dx]
  
  self.mRen[].blendColorHspan(self.mX - dx + 1, self.mY, cast[int](p1 - p0), p0)
  inc self.mStep

  result = npix != 0 and self.mStep < self.mCount

proc patternEnd*[R,C](self: var LineInterpolatorImage[R, C]): int =
  self.mStart + self.mDi.len()

proc vertical*[R,C](self: var LineInterpolatorImage[R, C]): bool =
  self.mLp.vertical

proc width*[R,C](self: var LineInterpolatorImage[R, C]): int =
  self.mWidth

proc count*[R,C](self: var LineInterpolatorImage[R, C]): int =
  self.mCount


type
  RendererOutlineImage*[BaseRenderer, ImagePattern] = object
    mRen: ptr BaseRenderer
    mPattern: ptr ImagePattern
    mStart: int
    mScaleX: float64
    mClipBox: RectI
    mClipping: bool

template getColorT*[B,I](x: typedesc[RendererOutlineImage[B,I]]): typedesc = getColorT(B.type)

proc initRendererOutlineImage*[B, I](ren: var B, patt: var I): RendererOutlineImage[B, I] =
  result.mRen = ren.addr
  result.mPattern = patt.addr
  result.mStart = 0
  result.mScaleX = 1.0
  result.mClipBox = initRectI(0,0,0,0)
  result.mClipping = false

proc attach*[B, I](self: var RendererOutlineImage[B, I], ren: var B) =
  self.mRen = ren.addr

proc pattern*[B, I](self: var RendererOutlineImage[B, I], patt: var I) =
  self.mPattern = patt.addr

proc pattern*[B, I](self: RendererOutlineImage[B, I]): var I =
  self.mPattern[]

proc resetClipping*[B, I](self: var RendererOutlineImage[B, I]) =
  self.mClipping = false

proc clipBox*[B, I](self: var RendererOutlineImage[B, I], x1, y1, x2, y2: float64) =
  self.mClipBox.x1 = LineCoordSat.conv(x1)
  self.mClipBox.y1 = LineCoordSat.conv(y1)
  self.mClipBox.x2 = LineCoordSat.conv(x2)
  self.mClipBox.y2 = LineCoordSat.conv(y2)
  self.mClipping = true;

proc scaleX*[B, I](self: var RendererOutlineImage[B, I], s: float64) =
  self.mScaleX = s

proc scaleX*[B, I](self: RendererOutlineImage[B, I]): float64 =
  self.mScaleX

proc startX*[B, I](self: var RendererOutlineImage[B, I], s: float64) =
  self.mStart = iround(s * lineSubpixelScale)

proc startX*[B, I](self: RendererOutlineImage[B, I]): float64 =
  float64(self.mStart) / lineSubpixelScale

proc subPixelWidth*[B, I](self: RendererOutlineImage[B, I]): int =
  self.mPattern[].lineWidth()

proc patternWidth*[B, I](self: RendererOutlineImage[B, I]): int =
  self.mPattern[].patternWidth()

proc width*[B, I](self: RendererOutlineImage[B, I]): float64 =
  float64(self.subPixelWidth()) / lineSubpixelScale

proc pixel*[B, I, ColorT](self: var RendererOutlineImage[B, I], p: ptr ColorT, x, y: int) =
  self.mPattern[].pixel(p, x, y)

proc blendColorHspan*[B, I, ColorT](self: var RendererOutlineImage[B, I], x, y, len: int, colors: ptr ColorT) =
  self.mRen[].blendColorHspan(x, y, len, colors, nil)

proc blendColorVspan*[B, I, ColorT](self: var RendererOutlineImage[B, I], x, y, len: int, colors: ptr ColorT) =
  self.mRen[].blendColorVspan(x, y, len, colors, nil)

proc accurateJoinOnly*[B, I](self: RendererOutlineImage[B, I]): bool = true

proc semidot*[B, I, Cmp](self: RendererOutlineImage[B, I], cmp: Cmp, u,v,w,x: int) = discard
proc pie*[B, I](self: RendererOutlineImage[B, I], a,b,c,d,e,f: int) = discard
proc line0*[B, I](self: RendererOutlineImage[B, I], lp: LineParameters) = discard
proc line1*[B, I](self: RendererOutlineImage[B, I], lp: LineParameters, x,y:int) = discard
proc line2*[B, I](self: RendererOutlineImage[B, I], lp: LineParameters, x,y:int) = discard

proc line3NoClip*[B, I](self: var RendererOutlineImage[B, I], lp: var LineParameters, sx, sy, ex, ey: int) =
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
  var li = initLineInterpolatorImage(self, lp, sx, sy, ex, ey, self.mStart, self.mScaleX)

  if li.vertical():
    while li.stepVer(): discard
  else:
    while li.stepHor(): discard
  self.mStart += uround(lp.len.float64 / self.mScaleX)

proc line3*[B, I](self: var RendererOutlineImage[B, I], lp: var LineParameters, sx, sy, ex, ey: int) =
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
      start = self.mStart

    if (flags and 4) == 0:
      if flags != 0:
        var lp2 = initLineParameters(x1, y1, x2, y2, uround(calcDistance(x1, y1, x2, y2)))
        if (flags and 1) != 0:
          self.mStart += uround(calcDistance(lp.x1, lp.y1, x1, y1) / self.mScaleX)
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
    self.mStart = start + uround(lp.len.float64 / self.mScaleX)
  else:
    self.line3NoClip(lp, sx, sy, ex, ey)
