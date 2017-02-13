import agg_basics, agg_rasterizer_cells_aa, agg_rasterizer_sl_clip, algorithm

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

proc notEqual*(self: CellStyleAA, ex, ey: int, c: CellStyleAA): int =
  result = (ex - self.x) or (ey - self.y) or (self.left - c.left) or (self.right - c.right)

const
  aaShift  = 8
  aaScale  = 1 shl aaShift
  aaMask   = aaScale - 1
  aaScale2 = aaScale * 2
  aaMask2  = aaScale2 - 1
    
type
  LayerOrder = enum
    layerUnsorted, #------layerUnsorted
    layerDirect,   #------layerDirect
    layerInverse   #------layerInverse

  StyleInfo = object
    startCell: uint
    numCells: uint
    lastX: int

  CellInfo = object
    x, area, cover: int
    
  RasterizerCompoundAA1*[ClipT, CoordT] = object
    mOutline: RasterizerCellsAA[CellStyleAA]
    mClipper: ClipT              
    mFillingRule: FillingRule         
    mLayerOrder: LayerOrder
    mStyles: seq[StyleInfo]  # Active Styles
    mAst: seq[uint]          # Active Style Table (unique values)
    mAsm: seq[uint8]         # Active Style Mask
    mCells: seq[CellInfo]
    mCoverBuf: seq[CoverType]
    mMasterAlpha: seq[uint]
    mMinStyle, mMaxStyle: int
    mStartX, mStartY: CoordT
    mScanY, mSlStart: int
    mSlLen: int
    
  RasterizerCompoundAA* = RasterizerCompoundAA1[RasterizerSlClipInt, getCoordT(RasterizerSlClipInt)]
  
proc initRasterizerCompoundAA1*[ClipT, CoordT](): RasterizerCompoundAA1[ClipT, CoordT] =
  result.mOutline = newRasterizerCellsAA[CellStyleAA]()
  result.mClipper = construct(ClipT)
  result.mFillingRule = fillNonZero
  result.mLayerOrder = layerDirect
  result.mStyles = @[]  # Active Styles
  result.mAst = @[]     # Active Style Table (unique values)
  result.mAsm = @[]     # Active Style Mask
  result.mCells = @[]
  result.mCoverBuf = @[]
  result.mMasterAlpha = @[]
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
  if self.isMoveTo(cmd):
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
  self.mOutline.minX()
  
proc minY*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int = 
  self.mOutline.minY()
  
proc maxX*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int = 
  self.mOutline.maxX()
  
proc maxY*[ClipT, CoordT](self: RasterizerCompoundAA1[ClipT, CoordT]): int = 
  self.mOutline.maxY()
  
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
  self.mScanY = self.mOutline.minY()
  self.mStyles.allocate(self.mMaxStyle - self.mMinStyle + 2, 128)
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
  result = sar((cover * masterAlpha + aaMask), aaShift)

# Sweeps one scanline with one style index. The style ID can be
# determined by calling style().
proc sweepScanline*[ClipT, CoordT, Scanline](self: var RasterizerCompoundAA1[ClipT, CoordT], 
  sl: var Scanline, styleIdx: int): bool =
  var scanY = self.mScanY - 1
  if scanY > self.mOutline.maxY(): return false
  
  sl.resetSpans()
  
  var masterAlpha: uint = aaMask
  
  if styleIdx < 0:
    styleIdx = 0
  else:
    inc styleIdx
    masterAlpha = self.mMasterAlpha[self.mAst[styleIdx] + self.mMinStyle - 1]
  
  var 
    st = self.mStyles[self.mAst[styleIdx]]
    numCells = st.numCells
    cell = self.mCells[st.startCell].addr
    cover = 0
    
  while numCells != 0:
    var 
      alpha: uint
      x = cell.x
      area = cell.area
    
    cover += cell.cover
    inc cell
    
    if area != 0:
      alpha = calculateAlpha((cover shl (polySubPixelShift + 1)) - area, masterAlpha)
      sl.addAell(x, alpha)
      inc x
    
    if numCells != 0 and cell.x > x:
      alpha = calculateAlpha(cover shl (poly_subPixelShift + 1),  masterAlpha)
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
    
  if (self.mAsm[nbyte] and mask) == 0:
     self.mAst.add(styleId)
     self.mAsm[nbyte] = self.mAsm[nbyte] or mask
     style.startCell = 0
     style.numCells = 0
     style.lastX = -0x7FFFFFFF
     inc style.startCell

proc sweepStyles*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]): uint =
  while true:
    if self.mScanY > self.mOutline.maxY(): return 0
    
    var
      numCells  = self.mOutline.scanlineNumCells(self.mScanY)
      cells     = self.mOutline.scanlineCells(self.mScanY)
      numStyles = self.mMaxStyle - self.mMinStyle + 2
      currCell: ptr CellStyleAA
      styleId: uint
      style: ptr StyleInfo
      cell: ptr CellInfo
    
    self.mCells.allocate(numCells * 2, 256) # Each cell can have two styles
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
      for i in 0.. <self.mAst.len:
        let 
          st = self.mStyles[self.mAst[i]]
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
          style.lastX = currCell.x
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
          style.lastX =  currCell.x
          inc style.numCells
        dec numCells
        
    if self.mAst.len > 1: break
    inc self.mScanY
  
  inc self.mScanY
  
  if self.mLayerOrder != layerUnsorted:
    var tmp = newSeq[uint](self.mAst.len - 1)
    copyMem(tmp[0].addr, self.mAst[1].addr, sizeof(uint) * tmp.len)
    if self.mLayerOrder == layerDirect:
      tmp.sort(cmp, Ascending)
    else:
      tmp.sort(cmp, Descending)
    copyMem(self.mAst[1].addr, tmp[0].addr, sizeof(uint) * tmp.len)
      
  result = self.mAst.len - 1

proc style*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], styleIdx: int): uint {.inline.} =
  self.mAst[styleIdx + 1] + self.mMinStyle - 1


proc navigateScanline*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], y: int): bool =
  self.mOutline.sortCells()
  if self.mOutline.totalCells() == 0:
    return false
  if self.mMaxStyle < self.mMinStyle:
    return false
  if y < self.mOutline.minY() or y > self.mOutline.maxY():
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
  self.sweepScanline(sl, -1)
  result = sl.hit()

proc allocateCoverBuffer*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], len: int): ptr CoverType =
  self.mCoverBuf.allocate(len, 256)
  self.mCoverBuf[0].addr


proc allocateMasterAlpha*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT]) =
  while self.mMasterAlpha.len <= self.mMaxStyle:
    self.mMasterAlpha.add(aaMask)

proc masterAlpha*[ClipT, CoordT](self: var RasterizerCompoundAA1[ClipT, CoordT], style: int, alpha: float64) =
  if style >= 0:
    while self.mMasterAlpha.len <= style:
      self.mMasterAlpha.add(aaMask)
    self.mMasterAlpha[style] = uround(alpha * aaMask)
