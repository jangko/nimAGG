import agg_basics, agg_rasterizer_cells_aa, agg_rasterizer_sl_clip, agg_gamma_functions
import strutils

export agg_rasterizer_cells_aa

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
  aaScale  = 1 shl aa_shift
  aaMask   = aa_scale - 1
  aaScale2 = aa_scale * 2
  aaMask2  = aa_scale2 - 1

type
  StatusE = enum
   statusInitial
   statusMoveTo
   statusLineTo
   statusClosed

  RasterizerScanlineAA1*[ClipType, CoordType] = ref object
    outline: RasterizerCellsAA[CellAA]
    clipper: ClipType
    gamma: array[aaScale, int]
    fillingRule: FillingRule
    autoClose: bool
    startX: CoordType
    startY: CoordType
    status: StatusE
    scanY: int
  
  RasterizerScanlineAA* = RasterizerScanlineAA1[RasterizerSlClipInt, getCoordType(RasterizerSlClipInt)]

proc newRasterizerScanlineAA1*[ClipType, CoordType](): RasterizerScanlineAA1[ClipType, CoordType] =
  new(result)
  result.outline = newRasterizerCellsAA[CellAA]()
  result.clipper = construct(ClipType)
  result.fillingRule = fillNonZero
  result.autoClose = true
  result.startX = 0
  result.startY = 0
  result.status = statusInitial
  for i in 0.. <aaScale: result.gamma[i] = i

proc setGamma*[ClipType, CoordType, GammaF](self: RasterizerScanlineAA1[ClipType, CoordType], gamma: GammaF) =
  for i in 0.. <aaScale:
    self.gamma[i] = uround(gamma.getGammaValue(i.float64 / aaMask) * aaMask)

proc newRasterizerScanlineAA2*[ClipType, CoordType, GammaF](gammaFunction: GammaF): RasterizerScanlineAA1[ClipType, CoordType] =
  new(result)
  result.outline = newRasterizerCellsAA[CellAA]()
  result.clipper = construct(ClipType)
  result.fillingRule = fillNonZero
  result.autoClose = true
  result.startX = 0
  result.startY = 0
  result.status = statusInitial
  result.setGamma(gammaFunction)

template newRasterizerScanlineAA*(ClipType: typedesc): untyped =
  newRasterizerScanlineAA1[ClipType, getCoordType(ClipType)]()

template newRasterizerScanlineAA*(): untyped =
  newRasterizerScanlineAA1[RasterizerSlClipInt, getCoordType(RasterizerSlClipInt)]()

template newRasterizerScanlineAA*(ClipType: typedesc, gamma: typed): untyped =
  newRasterizerScanlineAA2[ClipType, getCoordType(ClipType), gamma.type](gamma)

proc newRasterizerScanlineAA*[T](gamma: T): auto =
  newRasterizerScanlineAA2[RasterizerSlClipInt, getCoordType(RasterizerSlClipInt), T](gamma)

proc reset*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]) =
  self.outline.reset()
  self.status = statusInitial

proc resetClipping*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]) =
  self.reset()
  self.clipper.resetClipping()

proc clipBox*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvType(ClipT)
  self.reset()
  self.clipper.clipBox(Conv.upscale(x1), Conv.upscale(y1),
                       Conv.upscale(x2), Conv.upscale(y2))

proc setFillingRule*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; fillingRule: FillingRule) =
  self.fillingRule = fillingRule

proc autoClose*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; flag: bool) =
  self.autoClose = flag

proc applyGamma*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; cover: uint): uint =
  result = self.gamma[cover]

proc closePolygon*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]) =
  if self.status == statusLineTo:
    self.clipper.lineTo(self.outline, self.startX, self.startY)
    self.status = statusClosed

proc moveTo*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x, y: int) =
  template Conv: untyped = getConvType(ClipT)

  if self.outline.sorted(): self.reset()
  if self.autoClose: self.closePolygon()

  self.startX = Conv.downscale(x)
  self.startY = Conv.downscale(y)

  self.clipper.moveTo(self.startX, self.startY)
  self.status = statusMoveTo

proc lineTo*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x, y: int) =
  template Conv: untyped = getConvType(ClipT)

  self.clipper.lineTo(self.outline, Conv.downscale(x), Conv.downscale(y))
  self.status = statusLineTo

proc moveToD*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64) =
  template Conv: untyped = getConvType(ClipT)

  if self.outline.sorted(): self.reset()
  if self.autoClose: self.closePolygon()

  self.startX = Conv.upscale(x)
  self.startY = Conv.upscale(y)

  self.clipper.moveTo(self.startX, self.startY)
  self.status = statusMoveTo

proc lineToD*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64) =
  template Conv: untyped = getConvType(ClipT)

  self.clipper.lineTo(self.outline, Conv.upscale(x), Conv.upscale(y))
  self.status = statusLineTo

proc addVertex*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    self.moveToD(x, y)
  elif isVertex(cmd):
    self.lineToD(x, y)
  elif isClose(cmd):
    self.closePolygon()

proc edge*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: int) =
  template Conv: untyped = getConvType(ClipT)

  if self.outline.sorted(): self.reset()

  self.clipper.moveTo(Conv.downscale(x1), Conv.downscale(y1))
  self.clipper.lineTo(self.outline, Conv.downscale(x2), Conv.downscale(y2))
  self.status = statusMoveTo

proc edgeD*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvType(ClipT)

  if self.outline.sorted(): self.reset()

  self.clipper.moveTo(Conv.upscale(x1), Conv.upscale(y1))
  self.clipper.lineTo(self.outline, Conv.upscale(x2), Conv.upscale(y2))
  self.status = statusMoveTo

proc addPath*[ClipT, CoordT, VertexSource](self: RasterizerScanlineAA1[ClipT, CoordT]; vs: var VertexSource, pathId = 0'u) =
  var x, y: float64
  vs.rewind(pathId)
  if self.outline.sorted(): self.reset()

  var cmd = vs.vertex(x, y)
  while not isStop(cmd):
    self.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

proc minX*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMinX()
proc minY*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMinY()
proc maxX*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMaxX()
proc maxY*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]): int = self.outline.getMaxY()

proc sort*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]) =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

proc rewindScanlines*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]): bool =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

  if self.outline.totalCells() == 0:
    return false

  self.scanY = self.outline.getMinY()
  result = true

proc navigateScanline*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; y: int): bool =
  if self.autoClose: self.closePolygon()
  self.outline.sortCells()

  if (self.outline.totalCells() == 0) or
     (y < self.outline.getMinY()) or
     (y > self.outline.getMaxY()):
     return false

  self.scanY = y
  result = true
  
proc calculateAlpha*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; area: int): int {.inline.} =
  var cover = sar(area, (polySubpixelShift*2 + 1 - aaShift))
  
  if cover < 0: cover = -cover
  if self.fillingRule == fillEvenOdd:
    cover = cover and aaMask2
    if cover > aaScale:
      cover = aaScale2 - cover

  if cover > aaMask: cover = aaMask
  
  result = self.gamma[cover]

proc sweepScanline*[ClipT, CoordT, Scanline](self: RasterizerScanlineAA1[ClipT, CoordT]; sl: var Scanline): bool =
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
  
proc hitTest*[ClipT, CoordT](self: RasterizerScanlineAA1[ClipT, CoordT]; tx, ty: int): bool =
  if not self.navigateScanline(ty): return false
  var sl = initScanlineHitTest(tx)

  self.sweepScanline(sl)
  result = sl.hit()