import basics, rasterizer_cells_aa, rasterizer_sl_clip, gamma_functions
import strutils

export rasterizer_cells_aa

type
 CellAA* = object
   x: int
   y: int
   cover: int
   area: int

proc initial*(self: var CellAA) =
  self.x = 0x7FFFFFFF
  self.y = 0x7FFFFFFF
  self.cover = 0
  self.area  = 0

proc style*(self, other: CellAA) = discard

proc notEqual*(self: CellAA, ex, ey: int, other: CellAA): bool =
  result = ((ex - self.x) or (ey - self.y)) != 0

const
  aaShift  = 8
  aaScale  = 1 shl aaShift
  aaMask   = aaScale - 1
  aaScale2 = aaScale * 2
  aaMask2  = aaScale2 - 1

type
  StatusE = enum
   statusInitial
   statusMoveTo
   statusLineTo
   statusClosed

  RasterizerScanlineAA1*[ClipType, CoordType] = object
    outline: RasterizerCellsAA[CellAA]
    clipper: ClipType
    mGamma: array[aaScale, int]
    mFillingRule: FillingRule
    autoClose: bool
    startX: CoordType
    startY: CoordType
    status: StatusE
    scanY: int

  RasterizerScanlineAA* = RasterizerScanlineAA1[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt)]

template getAAShift*[CL, CO](x: typedesc[RasterizerScanlineAA1[CL, CO]]): int = aaShift
template getAAScale*[CL, CO](x: typedesc[RasterizerScanlineAA1[CL, CO]]): int = aaScale
template getAAMask*[CL, CO](x: typedesc[RasterizerScanlineAA1[CL, CO]]): int = aaSMask
template getAAScale2*[CL, CO](x: typedesc[RasterizerScanlineAA1[CL, CO]]): int = aaScale2
template getAAMask2*[CL, CO](x: typedesc[RasterizerScanlineAA1[CL, CO]]): int = aaMask2

proc initRasterizerScanlineAA1*[ClipType, CoordType](): RasterizerScanlineAA1[ClipType, CoordType] =
  result.outline = initRasterizerCellsAA[CellAA]()
  result.clipper = construct(ClipType)
  result.mFillingRule = fillNonZero
  result.autoClose = true
  result.startX = 0
  result.startY = 0
  result.status = statusInitial
  for i in 0.. <aaScale: result.mGamma[i] = i

proc gamma*[ClipType, CoordType, GammaF](self: var RasterizerScanlineAA1[ClipType, CoordType], gamma: GammaF) =
  for i in 0.. <aaScale:
    self.mGamma[i] = uround(gamma.getGammaValue(i.float64 / aaMask) * aaMask)

proc initRasterizerScanlineAA2*[ClipType, CoordType, GammaF](gammaFunction: GammaF): RasterizerScanlineAA1[ClipType, CoordType] =
  result.outline = initRasterizerCellsAA[CellAA]()
  result.clipper = construct(ClipType)
  result.mFillingRule = fillNonZero
  result.autoClose = true
  result.startX = 0
  result.startY = 0
  result.status = statusInitial
  result.gamma(gammaFunction)

template initRasterizerScanlineAA*(ClipType: typedesc): untyped =
  initRasterizerScanlineAA1[ClipType, getCoordT(ClipType)]()

template initRasterizerScanlineAA*(): untyped =
  initRasterizerScanlineAA1[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt)]()

template initRasterizerScanlineAA*(ClipType: typedesc, gamma: typed): untyped =
  initRasterizerScanlineAA2[ClipType, getCoordT(ClipType), gamma.type](gamma)

proc initRasterizerScanlineAA*[T](gamma: T): auto =
  initRasterizerScanlineAA2[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt), T](gamma)

proc reset*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]) =
  self.outline.reset()
  self.status = statusInitial

proc resetClipping*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]) =
  self.reset()
  self.clipper.resetClipping()

proc clipBox*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvT(ClipT)
  self.reset()
  self.clipper.clipBox(Conv.upscale(x1), Conv.upscale(y1),
                       Conv.upscale(x2), Conv.upscale(y2))

proc fillingRule*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; fillingRule: FillingRule) =
  self.mFillingRule = fillingRule

proc autoClose*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; flag: bool) =
  self.autoClose = flag

proc applyGamma*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; cover: int): int =
  result = self.mGamma[cover]

proc closePolygon*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]) =
  if self.status == statusLineTo:
    self.clipper.lineTo(self.outline, self.startX, self.startY)
    self.status = statusClosed

proc moveTo*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x, y: int) =
  template Conv: untyped = getConvT(ClipT)

  if self.outline.sorted(): self.reset()
  if self.autoClose: self.closePolygon()

  self.startX = Conv.downscale(x)
  self.startY = Conv.downscale(y)

  self.clipper.moveTo(self.startX, self.startY)
  self.status = statusMoveTo

proc lineTo*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x, y: int) =
  template Conv: untyped = getConvT(ClipT)

  self.clipper.lineTo(self.outline, Conv.downscale(x), Conv.downscale(y))
  self.status = statusLineTo

proc moveToD*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64) =
  template Conv: untyped = getConvT(ClipT)

  if self.outline.sorted(): self.reset()
  if self.autoClose: self.closePolygon()

  self.startX = Conv.upscale(x)
  self.startY = Conv.upscale(y)

  self.clipper.moveTo(self.startX, self.startY)
  self.status = statusMoveTo

proc lineToD*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64) =
  template Conv: untyped = getConvT(ClipT)

  self.clipper.lineTo(self.outline, Conv.upscale(x), Conv.upscale(y))
  self.status = statusLineTo

proc addVertex*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    self.moveToD(x, y)
  elif isVertex(cmd):
    self.lineToD(x, y)
  elif isClose(cmd):
    self.closePolygon()

proc edge*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: int) =
  template Conv: untyped = getConvT(ClipT)

  if self.outline.sorted(): self.reset()

  self.clipper.moveTo(Conv.downscale(x1), Conv.downscale(y1))
  self.clipper.lineTo(self.outline, Conv.downscale(x2), Conv.downscale(y2))
  self.status = statusMoveTo

proc edgeD*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvT(ClipT)

  if self.outline.sorted(): self.reset()

  self.clipper.moveTo(Conv.upscale(x1), Conv.upscale(y1))
  self.clipper.lineTo(self.outline, Conv.upscale(x2), Conv.upscale(y2))
  self.status = statusMoveTo

proc addPath*[ClipT, CoordT, VertexSource](self: var RasterizerScanlineAA1[ClipT, CoordT]; vs: var VertexSource, pathId = 0) =
  mixin rewind, vertex
  var x, y: float64
  vs.rewind(pathId)

  if self.outline.sorted(): self.reset()
  var cmd = vs.vertex(x, y)
  while not isStop(cmd):
    self.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

proc minX*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMinX()
proc minY*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMinY()
proc maxX*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMaxX()
proc maxY*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMaxY()

proc sort*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]) =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

proc rewindScanlines*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]): bool =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

  if self.outline.totalCells() == 0:
    return false

  self.scanY = self.outline.getMinY()
  result = true

proc navigateScanline*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; y: int): bool =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

  if (self.outline.totalCells() == 0) or
     (y < self.outline.getMinY()) or
     (y > self.outline.getMaxY()):
     return false

  self.scanY = y
  result = true

proc calculateAlpha*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; area: int): int {.inline.} =
  var cover = sar(area, (polySubpixelShift*2 + 1 - aaShift))

  if cover < 0: cover = -cover
  if self.mFillingRule == fillEvenOdd:
    cover = cover and aaMask2
    if cover > aaScale:
      cover = aaScale2 - cover

  if cover > aaMask: cover = aaMask

  result = self.mGamma[cover]

proc sweepScanline*[ClipT, CoordT, Scanline](self: var RasterizerScanlineAA1[ClipT, CoordT]; sl: var Scanline): bool =
  mixin resetSpans, addCell, addSpan, numSpans, finalize

  while true:
    if self.scanY > self.outline.getMaxY(): return false
    sl.resetSpans()

    var
      numCells = self.outline.scanlineNumCells(self.scanY)
      cells = self.outline.scanlineCells(self.scanY)
      cover = 0

    while numCells != 0:
      var
        curCell = cells[]
        x       = curCell.x
        area    = curCell.area
        alpha: uint

      inc(cover, curCell.cover)

      # accumulate all cells with the same X
      dec numCells
      while numCells != 0:
        inc cells
        curCell = cells[]
        if curCell.x != x: break
        inc(area, curCell.area)
        inc(cover, curCell.cover)
        dec numCells

      if area != 0:
        alpha = self.calculateAlpha((cover shl (polySubpixelShift + 1)) - area).uint
        if alpha != 0:
          sl.addCell(x, alpha)
        inc x

      if numCells != 0 and curCell.x > x:
        alpha = self.calculateAlpha(cover shl (polySubpixelShift + 1)).uint
        if alpha != 0:
          sl.addSpan(x, curCell.x - x, alpha)

    if sl.numSpans() != 0: break
    inc self.scanY

  sl.finalize(self.scanY)
  inc self.scanY
  result = true

proc hitTest*[ClipT, CoordT](self: var RasterizerScanlineAA1[ClipT, CoordT]; tx, ty: int): bool =
  if not self.navigateScanline(ty): return false
  var sl = initScanlineHitTest(tx)

  discard self.sweepScanline(sl)
  result = sl.getHit()
