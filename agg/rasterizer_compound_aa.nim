import basics, rasterizer_cells_aa, rasterizer_sl_clip, vector

type
  CellStyleAA = object
    x, y, cover, area: int
    left, right: int16

proc initial*(self: var CellStyleAA) =
  self.x     = 0x7FFFFFFF
  self.y     = 0x7FFFFFFF
  self.cover = 0
  self.area  = 0
  self.left  = -1
  self.right = -1

proc style*(self: var CellStyleAA, c: CellStyleAA) =
  self.left  = c.left
  self.right = c.right

proc notEqual*(self: CellStyleAA, ex, ey: int, c: CellStyleAA): bool =
  result = ((ex - self.x) or (ey - self.y) or (self.left - c.left) or (self.right - c.right)) != 0

const
  aaShift  = 8
  aaScale  = 1 shl aaShift
  aaMask   = aaScale - 1
  aaScale2 = aaScale * 2
  aaMask2  = aaScale2 - 1

type
  LayerOrder* = enum
    layerUnsorted #------layerUnsorted
    layerDirect   #------layerDirect
    layerInverse  #------layerInverse

  StyleInfo = object
    startCell: int
    numCells: int
    lastX: int

  CellInfo = object
    x, area, cover: int

  RasterizerCompoundAA1*[ClipT, CoordT] = object
    mOutline: RasterizerCellsAA[CellStyleAA]
    mClipper: ClipT
    mFillingRule: FillingRule
    mLayerOrder: LayerOrder

    mStyles: PodVector[StyleInfo]  # Active Styles
    mAst: PodVector[uint]          # Active Style Table (unique values)
    mAsm: PodVector[uint8]         # Active Style Mask
    mCells: PodVector[CellInfo]
    mCoverBuf: PodVector[CoverType]
    mMasterAlpha: PodBVector[uint]

    mMinStyle, mMaxStyle: int
    mStartX, mStartY: CoordT
    mScanY, mSlStart: int
    mSlLen: int

  RasterizerCompoundAA* = RasterizerCompoundAA1[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt)]

proc initRasterizerCompoundAA1*[ClipT, CoordT](): RasterizerCompoundAA1[ClipT, CoordT] =
  result.mOutline = initRasterizerCellsAA[CellStyleAA]()
  result.mClipper = construct(ClipT)
  result.mFillingRule = fillNonZero
  result.mLayerOrder = layerDirect
  result.mStyles = initPodVector[StyleInfo]()  # Active Styles
  result.mAst = initPodVector[uint]()     # Active Style Table (unique values)
  result.mAsm = initPodVector[uint8]()     # Active Style Mask
  result.mCells = initPodVector[CellInfo]()
  result.mCoverBuf = initPodVector[CoverType]()
  result.mMasterAlpha = initPodBVector[uint]()
  result.mMinStyle = 0x7FFFFFFF
  result.mMaxStyle = -0x7FFFFFFF
  result.mStartX = 0
  result.mStartY = 0
  result.mScanY = 0x7FFFFFFF
  result.mSlStart = 0
  result.mSlLen = 0

template initRasterizerCompoundAA*(ClipT: typedesc): untyped =
  initRasterizerCompoundAA1[ClipT, getCoordT(ClipT)]()

template initRasterizerCompoundAA*(): untyped =
  initRasterizerCompoundAA1[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt)]()

proc reset*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]) =
  self.mOutline.reset()
  self.mMinStyle =  0x7FFFFFFF
  self.mMaxStyle = -0x7FFFFFFF
  self.mScanY    =  0x7FFFFFFF
  self.mSlStart  =  0
  self.mSlLen    =  0

proc moveTo*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x, y: int) =
  template Conv: untyped = getConvT(ClipT)
  if self.mOutline.sorted():
    self.reset()

  self.mStartX = Conv.downscale(x)
  self.mStartY = Conv.downscale(y)
  self.mClipper.moveTo(self.mStartX, self.mStartY)

proc lineTo*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x, y: int) =
  template Conv: untyped = getConvT(ClipT)
  self.mClipper.lineTo(self.mOutline, Conv.downscale(x), Conv.downscale(y))

proc moveToD*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x, y: float64) =
  template Conv: untyped = getConvT(ClipT)
  if self.mOutline.sorted():
    self.reset()

  self.mStartX = Conv.upscale(x)
  self.mStartY = Conv.upscale(y)
  self.mClipper.moveTo(self.mStartX, self.mStartY)

proc lineToD*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x, y: float64) =
  template Conv: untyped = getConvT(ClipT)
  self.mClipper.lineTo(self.mOutline, Conv.upscale(x), Conv.upscale(y))

proc addVertex*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    self.moveToD(x, y)
  elif isVertex(cmd):
    self.lineToD(x, y)
  elif isClose(cmd):
    self.mClipper.lineTo(self.mOutline, self.mStartX, self.mStartY)

proc addPath*[ClipT, CoordT, VertexSource](self: var RasterizerCompoundAA1[ClipT, CoordT],
  vs: var VertexSource, pathId = 0) =
  var
    x,y: float64
    cmd: uint

  vs.rewind(pathId)
  if self.mOutline.sorted(): self.reset()
  cmd = vs.vertex(x, y)
  while not isStop(cmd):
    self.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

proc minX*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mOutline.getMinX()

proc minY*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mOutline.getMinY()

proc maxX*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mOutline.getMaxX()

proc maxY*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mOutline.getMaxY()

proc minStyle*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mMinStyle

proc maxStyle*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mMaxStyle

proc sort*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]) {.inline.} =
  self.mOutline.sortCells()

proc rewindScanlines*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]): bool =
  self.mOutline.sortCells()
  if self.mOutline.totalCells() == 0:
    return false
  if self.mMaxStyle < self.mMinStyle:
    return false
  self.mScanY = self.mOutline.getMinY()
  self.mStyles.allocate(self.mMaxStyle - self.mMinStyle + 2, 128)
  self.mStyles.zero()
  self.allocateMasterAlpha()
  result = true

proc scanlineStart*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mSlStart

proc scanlineLength*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]): int =
  self.mSlLen

proc calculateAlpha*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], area: int, masterAlpha: uint): uint {.inline.} =
  var cover = sar(area, (polySubPixelShift*2 + 1 - aaShift))
  if cover < 0: cover = -cover
  if self.mFillingRule == fillEvenOdd:
    cover = cover and aaMask2
    if cover > aaScale:
      cover = aaScale2 - cover
  if cover > aaMask: cover = aaMask
  result = (cover.uint * masterAlpha + aaMask) shr aaShift

# Sweeps one scanline with one style index. The style ID can be
# determined by calling style().
proc sweepScanline*[ClipT, CoordT, Scanline](self: var RasterizerCompoundAA1[ClipT, CoordT],
  sl: var Scanline, styleIdx: int): bool =
  mixin resetSpans, addCell, addSpan, numSpans, finalize
  var scanY = self.mScanY - 1
  if scanY > self.mOutline.getMaxY(): return false

  sl.resetSpans()

  var
    masterAlpha: uint = aaMask
    styleIdx = styleIdx

  if styleIdx < 0:
    styleIdx = 0
  else:
    inc styleIdx
    masterAlpha = self.mMasterAlpha[self.mAst[styleIdx].int + self.mMinStyle - 1]

  var
    st = self.mStyles[self.mAst[styleIdx].int]
    numCells = st.numCells
    cell = self.mCells[st.startCell.int].addr
    cover = 0

  while numCells != 0:
    var
      alpha: uint
      x = cell.x
      area = cell.area

    cover += cell.cover
    inc cell

    if area != 0:
      alpha = self.calculateAlpha((cover shl (polySubPixelShift + 1)) - area, masterAlpha)
      sl.addCell(x, alpha)
      inc x

    if numCells != 0 and cell.x > x:
      alpha = self.calculateAlpha(cover shl (polySubPixelShift + 1),  masterAlpha)
      if alpha != 0:
        sl.addSpan(x, cell.x - x, alpha)
    dec numCells

  if sl.numSpans() == 0: return false
  sl.finalize(scanY)
  result = true

proc fillingRule*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], fillingRule: FillingRule) =
  self.mFillingRule = fillingRule

proc layerOrder*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], order: LayerOrder) =
  self.mLayerOrder = order

proc clipBox*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvT(ClipT)
  self.reset()
  self.mClipper.clipBox(Conv.upscale(x1),
                        Conv.upscale(y1),
                        Conv.upscale(x2),
                        Conv.upscale(y2))

proc resetClipping*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]) =
  self.reset()
  self.mClipper.resetClipping()

proc styles*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], left, right: int) =
  var cell: CellStyleAA
  cell.initial()
  cell.left = int16(left)
  cell.right = int16(right)
  self.mOutline.style(cell)

  if left  >= 0 and left  < self.mMinStyle: self.mMinStyle = left
  if left  >= 0 and left  > self.mMaxStyle: self.mMaxStyle = left
  if right >= 0 and right < self.mMinStyle: self.mMinStyle = right
  if right >= 0 and right > self.mMaxStyle: self.mMaxStyle = right

proc edge*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x1, y1, x2, y2: int) =
  template Conv: untyped = getConvT(ClipT)
  if self.mOutline.sorted(): reset()
  self.mClipper.moveTo(Conv.downscale(x1), Conv.downscale(y1))
  self.mClipper.lineTo(self.mOutline, Conv.downscale(x2), Conv.downscale(y2))

proc edgeD*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], x1, y1, x2, y2: float64) =
  template Conv: untyped = getConvT(ClipT)
  if self.mOutline.sorted(): reset()
  self.mClipper.moveTo(Conv.upscale(x1), Conv.upscale(y1))
  self.mClipper.lineTo(self.mOutline, Conv.upscale(x2), Conv.upscale(y2))

proc addStyle*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], styleId: int) =
  var styleId = styleId
  if styleId < 0: styleId  = 0
  else:           styleId -= self.mMinStyle - 1

  var
    nbyte = styleId shr 3
    mask  = 1 shl (styleId and 7)
    style = self.mStyles[styleId].addr

  if (self.mAsm[nbyte].int and mask) == 0:
     self.mAst.add(styleId.uint)
     self.mAsm[nbyte] = (self.mAsm[nbyte].int or mask).uint8
     style.startCell = 0
     style.numCells = 0
     style.lastX = -0x7FFFFFFF
  inc style.startCell

proc sweepStyles*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]): int =

  while true:
    if self.mScanY > self.mOutline.getMaxY(): return 0

    var
      numCells  = self.mOutline.scanlineNumCells(self.mScanY)
      cells     = self.mOutline.scanlineCells(self.mScanY)
      numStyles = self.mMaxStyle - self.mMinStyle + 2
      currCell: ptr CellStyleAA
      styleId: int
      style: ptr StyleInfo
      cell: ptr CellInfo

    self.mCells.allocate(numCells * 2, 256) # Each cell can have two styles
    self.mCells.zero()
    self.mAst.capacity(numStyles, 64)
    self.mAsm.allocate((numStyles + 7) shr 3, 8)
    self.mAsm.zero()

    if numCells != 0:
      # Pre-add zero (for no-fill style, that is, -1).
      # We need that to ensure that the "-1 style" would go first.
      self.mAsm[0] = self.mAsm[0] or 1
      self.mAst.add(0)
      style = self.mStyles[0].addr
      style.startCell = 0
      style.numCells = 0
      style.lastX = -0x7FFFFFFF

      self.mSlStart = cells[0].x
      self.mSlLen   = cells[numCells-1].x - self.mSlStart + 1

      while numCells != 0:
        currCell = cells[]
        inc cells
        self.addStyle(currCell.left)
        self.addStyle(currCell.right)
        dec numCells

      # Convert the Y-histogram into the array of starting indexes
      var startCell = 0
      for i in 0.. <self.mAst.size:
        var
          st = self.mStyles[self.mAst[i].int].addr
          v = st.startCell
        st.startCell = startCell
        startCell += v

      cells = self.mOutline.scanlineCells(self.mScanY)
      numCells = self.mOutline.scanlineNumCells(self.mScanY)

      while numCells != 0:
        currCell = cells[]
        inc cells
        styleId = if currCell.left < 0: 0 else: currCell.left - self.mMinStyle + 1
        style = self.mStyles[styleId].addr

        if currCell.x == style.lastX:
          cell = self.mCells[style.startCell + style.numCells - 1].addr
          cell.area  += currCell.area
          cell.cover += currCell.cover
        else:
          cell = self.mCells[style.startCell + style.numCells].addr
          cell.x       = currCell.x
          cell.area    = currCell.area
          cell.cover   = currCell.cover
          style.lastX  = currCell.x
          inc style.numCells

        styleId = if currCell.right < 0: 0 else: currCell.right - self.mMinStyle + 1
        style = self.mStyles[styleId].addr

        if currCell.x == style.lastX:
          cell = self.mCells[style.startCell + style.numCells - 1].addr
          cell.area  -= currCell.area
          cell.cover -= currCell.cover
        else:
          cell = self.mCells[style.startCell + style.numCells].addr
          cell.x       =  currCell.x
          cell.area    = -currCell.area
          cell.cover   = -currCell.cover
          style.lastX  =  currCell.x
          inc style.numCells
        dec numCells

    if self.mAst.size() > 1: break
    inc self.mScanY

  inc self.mScanY

  if self.mLayerOrder != layerUnsorted:
    if self.mLayerOrder == layerDirect: self.mAst.sort(lessThan, 1)
    else: self.mAst.sort(greaterThan, 1)

  result = self.mAst.size() - 1

proc style*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], styleIdx: int): int {.inline.} =
  self.mAst[styleIdx + 1].int + self.mMinStyle - 1

proc navigateScanline*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], y: int): bool =
  self.mOutline.sortCells()
  if self.mOutline.totalCells() == 0:
    return false
  if self.mMaxStyle < self.mMinStyle:
    return false
  if y < self.mOutline.getMinY() or y > self.mOutline.getMaxY():
    return false
  self.mScanY = y
  self.mStyles.allocate(self.mMaxStyle - self.mMinStyle + 2, 128)
  self.allocateMasterAlpha()
  result = true

proc hitTest*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], tx, ty: int): bool =
  if not self.navigateScanline(ty):
    return false

  let numStyles = self.sweepStyles()
  if numStyles <= 0:
    return false

  var sl = initScanlineHitTest(tx)
  discard self.sweepScanline(sl, -1)
  result = sl.getHit()

proc allocateCoverBuffer*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], len: int): ptr CoverType =
  self.mCoverBuf.allocate(len, 256)
  self.mCoverBuf.zero()
  self.mCoverBuf[0].addr

proc allocateMasterAlpha*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]) =
  while self.mMasterAlpha.len <= self.mMaxStyle:
    self.mMasterAlpha.add(aaMask)

proc masterAlpha*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], style: int, alpha: float64) =
  if style >= 0:
    while self.mMasterAlpha.len <= style:
      self.mMasterAlpha.add(aaMask)
    self.mMasterAlpha[style] = uround(alpha * aaMask).uint
