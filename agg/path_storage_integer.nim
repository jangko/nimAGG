import basics, macros, strutils, vector
export vector

const
  cmdMoveTo = 0
  cmdLineTo = 1
  cmdCurve3 = 2
  cmdCurve4 = 3

template vertexInteger(name: untyped, CoordShift: int = 6) =
  type
    name*[T] = object
      x, y: T

  template getCoordShift[T](x: typedesc[name[T]]): int = CoordShift
  template getCoordScale[T](x: typedesc[name[T]]): int = 1 shl getCoordShift(x)

  proc `init name`*[T](x, y: T, flag: uint): name[T] =
    result.x = T(((x.uint shl 1) and not 1.uint) or (flag and 1))
    result.y = T(((y.uint shl 1) and not 1.uint) or (flag shr 1))

  proc vertex*[T](self: name[T], x, y: var float64, dx = 0.0, dy = 0.0, scale=1.0): uint =
    const coordScale = getCoordScale(self.type)

    x = dx + (float64(sar(self.x, 1)) / coordScale) * scale
    y = dy + (float64(sar(self.y, 1)) / coordScale) * scale

    case ((self.y and 1) shl 1) or (self.x and 1)
    of cmdMoveTo: return pathCmdMoveTo
    of cmdLineTo: return pathCmdLineTo
    of cmdCurve3: return pathCmdCurve3
    of cmdCurve4: return pathCmdCurve4
    else: discard
    return pathCmdStop

macro callTemplate(a, b: untyped, c: typed): untyped =
  result = parseExpr("vertexInteger($1, $2)" % [$a & $b, $c.intVal])

template pathStorageInteger(name: untyped, CoordShift: int = 6) =
  callTemplate(name, VI, CoordShift)

  type
    name*[T] = object
      mStorage: PodBVector[`name VI`[T]]
      mVertexIdx: int
      mClosed: bool

  template getValueT*[T](x: typedesc[name[T]]): typedesc = T

  proc `init name`*[T](): name[T] =
    result.mStorage = initPodBVector[`name VI`[T]]()
    result.mVertexIdx = 0
    result.mClosed = true

  proc removeAll*[T](self: var name[T]) =
    self.mStorage.removeAll()

  proc moveTo*[T](self: var name[T], x, y: T) =
    self.mStorage.add(`init name VI`(x, y, cmdMoveTo))

  proc lineTo*[T](self: var name[T], x, y: T) =
    self.mStorage.add(`init name VI`(x, y, cmdLineTo))

  proc curve3*[T](self: var name[T], xCtrl, yCtrl, xTo, yTo: T) =
    self.mStorage.add(`init name VI`(xCtrl, yCtrl, cmdCurve3))
    self.mStorage.add(`init name VI`(xTo,   yTo,   cmdCurve3))

  proc curve4*[T](self: var name[T], xCtrl1, yCtrl1, xCtrl2, yCtrl2, xTo, yTo: T) =
    self.mStorage.add(`init name VI`(xCtrl1, yCtrl1, cmdCurve4))
    self.mStorage.add(`init name VI`(xCtrl2, yCtrl2, cmdCurve4))
    self.mStorage.add(`init name VI`(xTo,    yTo,    cmdCurve4))

  proc closePolygon*[T](self: name[T]) = discard

  proc len*[T](self: name[T]): int =
    self.mStorage.len

  proc vertex*[T](self: name[T], idx: int, x, y: var float64) =
    return self.mStorage[idx].vertex(x, y)

  proc byteSize*[T](self: name[T]): int =
    type VertexType = `name VI`[T]
    self.mStorage.len * sizeof(VertexType)

  proc serialize*[T](self: var name[T], p: ptr uint8) =
    type VertexType = `name VI`[T]
    var p = p
    for i in 0..<self.mStorage.len:
      copyMem(p, self.mStorage[i].addr, sizeof(VertexType))
      p += sizeof(VertexType)

  proc rewind*[T](self: var name[T], pathId: int) =
    self.mVertexIdx = 0
    self.mClosed = true

  proc vertex*[T](self: var name[T], x, y: var float64): uint =
    if self.mStorage.len < 2 or self.mVertexIdx > self.mStorage.len:
      x = 0
      y = 0
      return pathCmdStop

    if self.mVertexIdx == self.mStorage.len:
      x = 0
      y = 0
      inc self.mVertexIdx
      return pathCmdEndPoly or pathFlagsClose

    var cmd = self.mStorage[self.mVertexIdx].vertex(x, y)
    if isMoveTo(cmd) and not self.mClosed:
      x = 0
      y = 0
      self.mClosed = true
      return pathCmdEndPoly or pathFlagsClose

    self.mClosed = false
    inc self.mVertexIdx
    return cmd

  proc boundingRect*[T](self: name[T]): RectD =
    var bounds = initRectD(1e100, 1e100, -1e100, -1e100)
    if self.mStorage.len == 0:
      bounds.x1 = 0.0
      bounds.y1 = 0.0
      bounds.x2 = 0.0
      bounds.y2 = 0.0
    else:
      for i in 0..<self.mStorage.len:
        var x, y: float64
        discard self.mStorage[i].vertex(x, y)
        if x < bounds.x1: bounds.x1 = x
        if y < bounds.y1: bounds.y1 = y
        if x > bounds.x2: bounds.x2 = x
        if y > bounds.y2: bounds.y2 = y
    result = bounds

  proc `$`*[T](self: name[T]): string =
    result = ""
    var x, y: float64
    for v in self.mStorage:
      discard v.vertex(x, y)
      result.add($x & "  " & $y)
      result.add("\n")

pathStorageInteger(PathStorageInteger, 6)

template serializedIntegerPathAdaptor(name: untyped, CoordShift: int = 6) =
  callTemplate(name, VI, CoordShift)

  type
    name*[T] = object
      mData: ptr uint8
      mEnd: ptr uint8
      mPtr: ptr uint8
      mDx, mDy: float64
      mScale: float64
      mVertices: int

  proc `init name`*[T](): name[T] =
    result.mData = nil
    result.mEnd = nil
    result.mPtr = nil
    result.mDx = 0.0
    result.mDy = 0.0
    result.mScale = 1.0
    result.mVertices = 0

  proc `init name`*[T](data: ptr uint8, size: int, dx, dy: float64): name[T] =
    result.mData = data
    result.mEnd  = data + size
    result.mPtr  = data
    result.mDx = dx
    result.mDy = dy
    result.mVertices = 0

  proc init*[T](self: var name[T], data: ptr uint8, size: int, dx, dy: float64, scale=1.0) =
    self.mData     = data
    self.mEnd      = data + size
    self.mPtr      = data
    self.mDx       = dx
    self.mDy       = dy
    self.mScale    = scale
    self.mVertices = 0

  proc rewind*[T](self: var name[T], pathId: int) =
    self.mPtr      = self.mData
    self.mVertices = 0

  proc vertex*[T](self: var name[T], x, y: var float64): uint =
    type VertexType = `name VI`[T]
    if self.mData == nil or self.mPtr > self.mEnd:
      x = 0
      y = 0
      return pathCmdStop

    if self.mPtr == self.mEnd:
      x = 0
      y = 0
      self.mPtr += sizeof(VertexType)
      return pathCmdEndPoly or pathFlagsClose

    var v: VertexType
    copyMem(v.addr, self.mPtr, sizeof(VertexType))
    var cmd = v.vertex(x, y, self.mDx, self.mDy, self.mScale)
    if isMoveTo(cmd) and self.mVertices > 2:
      x = 0
      y = 0
      self.mVertices = 0
      return pathCmdEndPoly or pathFlagsClose

    inc self.mVertices
    self.mPtr += sizeof(VertexType)
    return cmd

serializedIntegerPathAdaptor(SerializedIntegerPathAdaptor, 6)
