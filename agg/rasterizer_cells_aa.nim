import basics, algorithm, strutils, vector

const
  cellBlockShift = 12
  cellBlockSize  = 1 shl cellBlockShift
  cellBlockMask  = cellBlockSize - 1
  cellBlockPool  = 256
  cellBlockLimit = 1024

type
  SortedY = object
    start, num: int

  RasterizerCellsAA*[CellType] = object
    numBlocks: int
    maxBlocks: int
    currBlock: int
    numCells: int
    cells: seq[seq[CellType]]
    currCellPtr: ptr CellType
    sortedCells: PodVector[ptr CellType]
    sortedY: PodVector[SortedY]
    currCell: CellType
    styleCell: CellType
    minX: int
    minY: int
    maxX: int
    maxY: int
    sorted: bool

proc reset*[T](self: var RasterizerCellsAA[T]) =
  self.numCells = 0
  self.currBlock = 0
  self.currCell.initial()
  self.styleCell.initial()
  self.sorted = false
  self.minX =  0x7FFFFFFF
  self.minY =  0x7FFFFFFF
  self.maxX = -0x7FFFFFFF
  self.maxY = -0x7FFFFFFF

proc style*[T](self: var RasterizerCellsAA[T], styleCell: T) =
  mixin style
  self.styleCell.style(styleCell)

proc getMinX*[T](self: RasterizerCellsAA[T]): int = self.minX
proc getMinY*[T](self: RasterizerCellsAA[T]): int = self.minY
proc getMaxX*[T](self: RasterizerCellsAA[T]): int = self.maxX
proc getMaxY*[T](self: RasterizerCellsAA[T]): int = self.maxY

proc initRasterizerCellsAA*[T](): RasterizerCellsAA[T] =
  result.numBlocks = 0
  result.maxBlocks = 0
  result.currBlock = 0
  result.numCells  = 0
  result.cells = @[]
  result.currCellPtr = nil
  result.sortedCells = initPodVector[ptr T]()
  result.sortedY = initPodVector[SortedY]()
  result.minX = 0x7FFFFFFF
  result.minY = 0x7FFFFFFF
  result.maxX = -0x7FFFFFFF
  result.maxY = -0x7FFFFFFF
  result.sorted = false
  result.styleCell.initial()
  result.currCell.initial()

proc allocateBlock[T](self: var RasterizerCellsAA[T]) =
  if self.currBlock >= self.numBlocks:
    if self.numBlocks >= self.maxBlocks:
      self.cells.setLen(self.maxBlocks + cellBlockPool)
      inc(self.maxBlocks, cellBlockPool)

    self.cells[self.numBlocks] = newSeq[T](cellBlockSize)
    inc self.numBlocks

  self.currCellPtr = addr(self.cells[self.currBlock][0])
  inc self.currBlock

proc addCurrCell[T](self: var RasterizerCellsAA[T]) =
  if(self.currCell.area or self.currCell.cover) != 0:
    if(self.numCells and cellBlockMask) == 0:
      if self.numBlocks >= cellBlockLimit: return
      self.allocateBlock()
    self.currCellPtr[] = self.currCell
    inc self.currCellPtr
    inc self.numCells

proc setCurrCell[T](self: var RasterizerCellsAA[T], x, y: int) =
  mixin style
  if self.currCell.notEqual(x, y, self.styleCell):
    self.addCurrCell()
    self.currCell.style(self.styleCell)
    self.currCell.x     = x
    self.currCell.y     = y
    self.currCell.cover = 0
    self.currCell.area  = 0

proc cmpX[T](a, b: T): bool = a.x < b.x

proc sortCells*[T](self: var RasterizerCellsAA[T]) =
  #Perform sort only the first time.
  if self.sorted: return

  self.addCurrCell()
  self.currCell.x     = 0x7FFFFFFF
  self.currCell.y     = 0x7FFFFFFF
  self.currCell.cover = 0
  self.currCell.area  = 0

  if self.numCells == 0: return

  # Allocate the array of cell pointers
  self.sortedCells.allocate(self.numCells, 16)

  # Allocate and zero the Y array
  self.sortedY.allocate(self.maxY - self.minY + 1, 16)
  self.sortedY.zero()

  # Create the Y-histogram (count the numbers of cells for each Y)
  var
    blockPtr = 0
    nb = self.numCells shr cellBlockShift
    cellPtr: ptr T
    i: int

  while nb != 0:
    cellPtr = self.cells[blockPtr][0].addr
    inc blockPtr
    i = cellBlockSize
    while i != 0:
      inc self.sortedY[cellPtr.y - self.minY].start
      inc cellPtr
      dec i
    dec nb

  if blockPtr < self.cells.len:
    cellPtr = self.cells[blockPtr][0].addr
    i = self.numCells and cellBlockMask
    while i != 0:
      inc self.sortedY[cellPtr.y - self.minY].start
      inc cellPtr
      dec i

  # Convert the Y-histogram into the array of starting indexes
  var start = 0
  for x in mitems(self.sortedY):
    let v = x.start
    x.start = start
    inc(start, v)

  # Fill the cell pointer array sorted by Y
  blockPtr = 0
  nb = self.numCells shr cellBlockShift
  while nb != 0:
    cellPtr = self.cells[blockPtr][0].addr
    inc blockPtr
    i = cellBlockSize
    while i != 0:
      var currY = addr(self.sortedY[cellPtr.y - self.minY])
      self.sortedCells[currY.start + currY.num] = cellPtr
      inc currY.num
      inc cellPtr
      dec i
    dec nb

  if blockPtr < self.cells.len:
    cellPtr = self.cells[blockPtr][0].addr
    i = self.numCells and cellBlockMask
    while i != 0:
      var currY = addr(self.sortedY[cellPtr.y - self.minY])
      self.sortedCells[currY.start + currY.num] = cellPtr
      inc currY.num
      inc cellPtr
      dec i

  # Finally arrange the X-arrays
  for x in items(self.sortedY):
    if x.num != 0:
      self.sortedCells.sort(cmpX[ptr T], x.start, x.start + x.num)

  self.sorted = true

proc totalCells*[T](self: RasterizerCellsAA[T]): int =
  result = self.numCells

proc scanlineNumCells*[T](self: var RasterizerCellsAA[T], y: int): int =
  result = self.sortedY[y - self.minY].num

proc scanlineCells*[T](self: var RasterizerCellsAA[T], y: int): ptr ptr T =
  result = self.sortedCells.data() + self.sortedY[y - self.minY].start

proc sorted*[T](self: RasterizerCellsAA[T]): bool =
  result = self.sorted

proc renderHline[T](self: var RasterizerCellsAA[T], ey, x1, y1, x2, y2: int) =
  var
    ex1 = sar(x1, polySubpixelShift)
    ex2 = sar(x2, polySubpixelShift)
    fx1 = x1 and polySubpixelMask
    fx2 = x2 and polySubpixelMask

  var
    delta, p, first, dx: int
    incr, lift, modx, rem: int
    y1 = y1

  #trivial case. Happens often
  if y1 == y2:
    self.setCurrCell(ex2, ey)
    return

  #everything is located in a single cell.  That is easy!
  if ex1 == ex2:
    delta = y2 - y1
    inc(self.currCell.cover, delta)
    inc(self.currCell.area, (fx1 + fx2) * delta)
    return

  #ok, we'll have to render a run of adjacent cells on the same
  #hline...
  p     = (polySubpixelScale - fx1) * (y2 - y1)
  first = polySubpixelScale
  incr  = 1

  dx = x2 - x1
  if dx < 0:
    p     = fx1 * (y2 - y1)
    first = 0
    incr  = -1
    dx    = -dx

  delta = p div dx
  modx  = p mod dx

  if modx < 0:
    dec delta
    inc(modx, dx)

  inc(self.currCell.cover, delta)
  inc(self.currCell.area, (fx1 + first) * delta)

  inc(ex1, incr)
  self.setCurrCell(ex1, ey)
  inc(y1, delta)

  if ex1 != ex2:
    p     = polySubpixelScale * (y2 - y1 + delta)
    lift  = p div dx
    rem   = p mod dx

    if rem < 0:
      dec lift
      inc(rem, dx)


    dec(modx, dx)

    while ex1 != ex2:
      delta = lift
      inc(modx, rem)
      if modx >= 0:
        dec(modx, dx)
        inc delta

      inc(self.currCell.cover, delta)
      inc(self.currCell.area, polySubpixelScale * delta)
      inc(y1, delta)
      inc(ex1, incr)
      self.setCurrCell(ex1, ey)

  delta = y2 - y1
  inc(self.currCell.cover, delta)
  inc(self.currCell.area, (fx2 + polySubpixelScale - first) * delta)

proc line*[T](self: var RasterizerCellsAA[T], x1, y1, x2, y2: int) =
  const
    dxLimit = 16384 shl polySubpixelShift

  let dx = x2 - x1
  if(dx >= dxLimit) or (dx <= -dxLimit):
    let cx = sar((x1 + x2), 1)
    let cy = sar((y1 + y2), 1)
    self.line(x1, y1, cx, cy)
    self.line(cx, cy, x2, y2)

  var
    dy = y2 - y1
    ex1 = sar(x1, polySubpixelShift)
    ex2 = sar(x2, polySubpixelShift)
    ey1 = sar(y1, polySubpixelShift)
    ey2 = sar(y2, polySubpixelShift)
    fy1 = y1 and polySubpixelMask
    fy2 = y2 and polySubpixelMask

    xFrom, xTo: int
    p, rem, modx, lift, delta, first, incr: int

  if ex1 < self.minX: self.minX = ex1
  if ex1 > self.maxX: self.maxX = ex1
  if ey1 < self.minY: self.minY = ey1
  if ey1 > self.maxY: self.maxY = ey1
  if ex2 < self.minX: self.minX = ex2
  if ex2 > self.maxX: self.maxX = ex2
  if ey2 < self.minY: self.minY = ey2
  if ey2 > self.maxY: self.maxY = ey2

  self.setCurrCell(ex1, ey1)

  #everything is on a single hline
  if ey1 == ey2:
    self.renderHline(ey1, x1, fy1, x2, fy2)
    return

  #Vertical line - we have to calculate start and end cells,
  #and then - the common values of the area and coverage for
  #all cells of the line. We know exactly there's only one
  #cell, so, we don't have to call renderHline().
  incr  = 1
  if dx == 0:
    var
      ex = sar(x1, polySubpixelShift)
      two_fx = (x1 - (ex shl polySubpixelShift)) shl 1
      area: int

    first = polySubpixelScale
    if dy < 0:
      first = 0
      incr  = -1

    xFrom = x1

    #renderHline(ey1, xFrom, fy1, xFrom, first)
    delta = first - fy1
    inc(self.currCell.cover, delta)
    inc(self.currCell.area, two_fx * delta)

    inc(ey1, incr)
    self.setCurrCell(ex, ey1)

    delta = first + first - polySubpixelScale
    area = two_fx * delta
    while ey1 != ey2:
      #renderHline(ey1, xFrom, polySubpixelScale - first, xFrom, first)
      self.currCell.cover = delta
      self.currCell.area  = area
      inc(ey1, incr)
      self.setCurrCell(ex, ey1)

    #renderHline(ey1, xFrom, polySubpixelScale - first, xFrom, fy2)
    delta = fy2 - polySubpixelScale + first
    inc(self.currCell.cover, delta)
    inc(self.currCell.area, two_fx * delta)
    return

  #ok, we have to render several hlines
  p     = (polySubpixelScale - fy1) * dx
  first = polySubpixelScale

  if dy < 0:
    p     = fy1 * dx
    first = 0
    incr  = -1
    dy    = -dy

  delta = p div dy
  modx  = p mod dy

  if modx < 0:
    dec delta
    inc(modx, dy)

  xFrom = x1 + delta
  self.renderHline(ey1, x1, fy1, xFrom, first)

  inc(ey1, incr)
  self.setCurrCell(sar(xFrom, polySubpixelShift), ey1)

  if ey1 != ey2:
    p     = polySubpixelScale * dx
    lift  = p div dy
    rem   = p mod dy

    if rem < 0:
      dec lift
      inc(rem, dy)

    dec(modx, dy)

    while ey1 != ey2:
      delta = lift
      inc(modx, rem)
      if modx >= 0:
        dec(modx, dy)
        inc delta

      xTo = xFrom + delta
      self.renderHline(ey1, xFrom, polySubpixelScale - first, xTo, first)
      xFrom = xTo

      inc(ey1, incr)
      self.setCurrCell(sar(xFrom, polySubpixelShift), ey1)

  self.renderHline(ey1, xFrom, polySubpixelScale - first, x2, fy2)

type
  ScanlineHitTest* = object
    x: int
    hit: bool

proc initScanlineHitTest*(x: int): ScanlineHitTest =
  result.x = x
  result.hit = false

proc resetSpans*(self: ScanlineHitTest) = discard
proc finalize*(self: ScanlineHitTest, x: int) = discard
proc addCell*(self: var ScanlineHitTest, x: int, cover: uint) =
  if self.x == x: self.hit = true

proc addSpan*(self: var ScanlineHitTest, x, len: int, cover: uint) =
  if self.x >= x and self.x < (x+len): self.hit = true

proc numSpans*(self: ScanlineHitTest): int = 1
proc getHit*(self: ScanlineHitTest): bool = self.hit
