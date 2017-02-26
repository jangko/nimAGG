import agg_basics, agg_math, agg_bezier_arc, strutils

type
  VertexStorage* = ref object
    mVert: seq[VertexD]

proc newVertexStorage*(): VertexStorage =
  new(result)
  result.mVert = @[]

proc removeAll*(self: VertexStorage) =
  self.mVert.setLen(0)

proc freeAll*(self: VertexStorage) =
  self.mVert.setLen(0)

proc addVertex*(self: VertexStorage, x: float64, y: float64, cmd: uint) =
  self.mVert.add VertexD(x:x, y:y, cmd:cmd)

proc modifyVertex*(self: VertexStorage, idx: int, x: float64, y: float64) =
  var v = self.mVert[idx].addr
  v.x = x
  v.y = y

proc modifyVertex*(self: VertexStorage, idx: int, x: float64, y: float64, cmd: uint) =
  var v = self.mVert[idx].addr
  v.x   = x
  v.y   = y
  v.cmd = cmd

proc modifyCommand*(self: VertexStorage, idx: int, cmd: uint) =
  self.mVert[idx].cmd = cmd

proc swapVertices*(self: VertexStorage, v1, v2: int) =
  swap(self.mVert[v1], self.mVert[v2])

proc lastCommand*(self: VertexStorage): uint =
  result = if self.mVert.len > 0: self.mVert[self.mVert.len - 1].cmd else: pathCmdStop

proc vertex*(self: VertexStorage, idx: int, x, y: var float64): uint =
  var v = self.mVert[idx].addr
  x = v.x
  y = v.y
  result = v.cmd

proc lastVertex*(self: VertexStorage, x, y: var float64): uint =
  if self.mVert.len == 0:
    x = 0.0
    y = 0.0
    return pathCmdStop

  result = self.vertex(self.mVert.len - 1, x, y)

proc prevVertex*(self: VertexStorage, x, y: var float64): uint =
  if self.mVert.len < 2:
    x = 0.0
    y = 0.0
    return pathCmdStop
  result = self.vertex(self.mVert.len - 2, x, y)

proc lastX*(self: VertexStorage): float64 =
  result = if self.mVert.len > 0: self.mVert[self.mVert.len - 1].x else: 0.0'f64

proc lastY*(self: VertexStorage): float64 =
  result = if self.mVert.len > 0: self.mVert[self.mVert.len - 1].y else: 0.0'f64

proc totalVertices*(self: VertexStorage): int =
  result = self.mVert.len

proc command*(self: VertexStorage, idx: int): uint =
  result = self.mVert[idx].cmd


type
  PolyPlainAdaptor*[T] = object
    mData: ptr T
    mPtr: ptr T
    mEnd: ptr T
    mClosed: bool
    mStop: bool

proc initPolyPlainAdaptor*[T](data: ptr T, numPoints: int, closed: bool): PolyPlainAdaptor[T] =
  result.mData = data
  result.mPtr = data
  result.mEnd = data + numPoints * 2
  result.mClosed = closed
  result.mStop = false

proc rewind*[T](self: var PolyPlainAdaptor[T], x: int) =
  self.mPtr = self.mData
  self.mStop = false

proc vertex*[T](self: var PolyPlainAdaptor[T], x, y: var T): uint =
  if self.mPtr < self.mEnd:
    let first = self.mPtr == self.mData
    x = self.mPtr[]; inc self.mPtr
    y = self.mPtr[]; inc self.mPtr
    return if first: pathCmdMoveTo else: pathCmdLineTo

  x = 0.0
  y = 0.0

  if self.mClosed and (not self.mStop):
    self.mStop = true
    return pathCmdEndPoly or pathFlagsClose

  result = pathCmdStop

type
  PolyContainerAdaptor*[Container] = object
    mContainer: ptr Container
    mIndex: int
    mClosed: bool
    mStop: bool

proc initPolyContainerAdaptor*[C](): PolyContainerAdaptor[C] =
  result.mContainer = nil
  result.mIndex  = 0
  result.mClosed = false
  result.mStop = false

proc initPolyContainerAdaptor*[C](data: var C, closed: bool): PolyContainerAdaptor[C] =
  result.mContainer = data.addr
  result.mIndex = 0
  result.mClosed = closed
  result.mStop = false

proc init*[C](self: var PolyContainerAdaptor[C], data: var C, closed: bool) =
  self.mContainer = data.addr
  self.mIndex = 0
  self.mClosed = closed
  self.mStop = false

proc rewind*[C](self: var PolyContainerAdaptor[C], pathId: int) =
  self.mIndex = 0
  self.mStop = false

proc vertex*[C](self: var PolyContainerAdaptor[C], x, y: var float64): uint =
  if self.mIndex < self.mContainer[].len:
    let
      first = self.mIndex == 0
      v = self.mContainer[][self.mIndex]
    inc self.mIndex
    x = v.x
    y = v.y
    return if first: pathCmdMoveTo else: pathCmdLineTo

  x = 0.0
  y = 0.0
  if self.mClosed and not self.mStop:
    self.mStop = true
    return pathCmdEndPoly or pathFlagsClose

  result = pathCmdStop


type
  PolyContainerReverseAdaptor*[Container] = object
    mContainer: ptr Container
    mIndex: int
    mClosed: bool
    mStop: bool

proc initPolyContainerReverseAdaptor*[C](): PolyContainerReverseAdaptor[C] =
  result.mContainer = nil
  result.mIndex  = 0
  result.mClosed = false
  result.mStop = false

proc initPolyContainerReverseAdaptor*[C](data: var C, closed: bool): PolyContainerReverseAdaptor[C] =
  result.mContainer = data.addr
  result.mIndex = 0
  result.mClosed = closed
  result.mStop = false

proc init*[C](self: var PolyContainerReverseAdaptor[C], data: var C, closed: bool) =
  self.mContainer = data.addr
  self.mIndex = 0
  self.mClosed = closed
  self.mStop = false

proc rewind*[C](self: var PolyContainerReverseAdaptor[C], pathId: int) =
  self.mIndex = self.mContainer[].len - 1
  self.mStop = false

proc vertex*[C](self: var PolyContainerReverseAdaptor[C], x, y: var float64): uint =
  if self.mIndex >= 0:
    let
      first = self.mIndex == self.mContainer[].len - 1
      v = self.mContainer[][self.mIndex]
    dec self.mIndex
    x = v.x
    y = v.y
    return if first: pathCmdMoveTo else: pathCmdLineTo

  x = 0.0
  y = 0.0
  if self.mClosed and not self.mStop:
    self.mStop = true
    return pathCmdEndPoly or pathFlagsClose
  result = pathCmdStop

type
  LineAdaptor* = object
    mCoord: array[4, float64]
    mLine: PolyPlainAdaptor[float64]

proc initLineAdaptor*(): LineAdaptor =
  result.mLine = initPolyPlainAdaptor(result.mCoord[0].addr, 2, false)

proc initLineAdaptor*(x1, y1, x2, y2: float64): LineAdaptor =
  result.mLine = initPolyPlainAdaptor(result.mCoord[0].addr, 2, false)
  result.mCoord[0] = x1
  result.mCoord[1] = y1
  result.mCoord[2] = x2
  result.mCoord[3] = y2

proc init*(self: var LineAdaptor, x1, y1, x2, y2: float64) =
  self.mCoord[0] = x1
  self.mCoord[1] = y1
  self.mCoord[2] = x2
  self.mCoord[3] = y2
  self.mLine.rewind(0)

proc rewind*(self: var LineAdaptor, pathId: int) =
  self.mLine.rewind(0)

proc vertex*(self: var LineAdaptor, x, y: var float64): uint =
  self.mLine.vertex(x, y)

# A container to store vertices with their flags.
# A path consists of a number of contours separated with "move_to"
# commands. The path storage can keep and maintain more than one
# path.
# To navigate to the beginning of a particular path, use rewind(path_id)
# Where path_id is what start_new_path() returns. So, when you call
# start_new_path() you need to store its return value somewhere else
# to navigate to the path afterwards.
#
# See also: vertex_source concept

type
  PathBase*[VC] = object
    mVert: VC
    iter: int

  PathStorage* = PathBase[VertexStorage]

proc initPathBase*[VC](vertices: VC): PathBase[VC] =
  result.mVert = vertices
  result.iter = 0
  
proc initPathBase*[VC](): PathBase[VC] =
  result.iter = 0
  
proc initPathStorage*(): auto =
  result = initPathBase(newVertexStorage())

proc removeAll*[VC](self: var PathBase[VC]) =
  self.mVert.removeAll()
  self.iter = 0

proc freeAll*[VC](self: var PathBase[VC]) =
  self.mVert.freeAll()
  self.iter = 0

proc relToAbs*[VC](self: var PathBase[VC], x, y: var float64) =
  if self.mVert.totalVertices() != 0:
    var x2, y2: float64
    if isVertex(self.mVert.lastVertex(x2, y2)):
      inc(x, x2)
      inc(y, y2)

proc lastX*[VC](self: var PathBase[VC]): float64 {.inline.} =
  result = self.mVert.lastX()

proc lastY*[VC](self: var PathBase[VC]): float64 {.inline.} =
  result = self.mVert.lastY()

proc endPoly*[VC](self: var PathBase[VC], flags = pathFlagsClose) {.inline.} =
  mixin addVertex, lastCommand
  if isVertex(self.mVert.lastCommand()):
    self.mVert.addVertex(0.0, 0.0, pathCmdEndPoly or flags)

proc closePolygon*[VC](self: var PathBase[VC], flags = pathFlagsNone) {.inline.} =
  self.endPoly(pathFlagsClose or flags)

proc totalVertices*[VC](self: var PathBase[VC]): int {.inline.} =
  result = self.mVert.totalVertices()

proc lastVertex*[VC](self: var PathBase[VC], x, y: var float64): uint {.inline.} =
  result = self.mVert.lastVertex(x, y)

proc prevVertex*[VC](self: var PathBase[VC], x, y: var float64): uint {.inline.} =
  result = self.mVert.prevVertex(x, y)

proc vertex*[VC](self: var PathBase[VC], idx: int, x, y: var float64): uint {.inline.} =
  result = self.mVert.vertex(idx, x, y)

proc command*[VC](self: PathBase[VC], idx: int): uint {.inline.} =
  result = self.mVert.command(idx)

proc modifyVertex*[VC](self: var PathBase[VC], idx: int, x: float64, y: float64) =
  self.mVert.modifyVertex(idx, x, y)

proc modifyVertex*[VC](self: var PathBase[VC], idx: int, x: float64, y: float64, cmd: uint) =
  self.mVert.modifyVertex(idx, x, y, cmd)

proc modifyCommand*[VC](self: var PathBase[VC], idx: int, cmd: uint) =
  self.mVert.modifyCommand(idx, cmd)

proc rewind*[VC](self: var PathBase[VC], pathId: int) {.inline.} =
  self.iter = pathId

proc vertex*[VC](self: var PathBase[VC], x, y: var float64): uint {.inline.} =
  if self.iter >= self.mVert.totalVertices(): return pathCmdStop
  result = self.mVert.vertex(self.iter, x, y)
  inc self.iter

proc startNewPath*[VC](self: var PathBase[VC]): int {.inline.} =
  if not isStop(self.mVert.lastCommand()):
    self.mVert.addVertex(0.0, 0.0, pathCmdStop)
  result = self.mVert.totalVertices()

proc moveTo*[VC](self: var PathBase[VC], x: float64, y: float64) {.inline.} =
  mixin addVertex
  self.mVert.addVertex(x, y, pathCmdMoveTo)

proc moveRel*[VC](self: var PathBase[VC], dx, dy: float64) {.inline.} =
  self.relToAbs(dx, dy)
  self.mVert.addVertex(dx, dy, pathCmdMoveTo)

proc lineTo*[VC](self: var PathBase[VC], x: float64, y: float64) {.inline.} =
  mixin addVertex
  self.mVert.addVertex(x, y, pathCmdLineTo)

proc lineRel*[VC](self: var PathBase[VC], dx, dy: float64) {.inline.} =
  self.relToAbs(dx, dy)
  self.mVert.addVertex(dx, dy, pathCmdLineTo)

proc hlineTo*[VC](self: var PathBase[VC], x: float64) {.inline.} =
  self.mVert.addVertex(x, self.lastY(), pathCmdLineTo)

proc hlineRel*[VC](self: var PathBase[VC], dx: float64) {.inline.} =
  var
    dx = dx
    dy: float64 = 0
  self.relToAbs(dx, dy)
  self.mVert.addVertex(dx, dy, pathCmdLineTo)

proc vlineTo*[VC](self: var PathBase[VC], y: float64) {.inline.} =
  self.mVert.addVertex(self.lastX(), y, pathCmdLineTo)

proc vlineRel*[VC](self: var PathBase[VC], dy: float64) {.inline.} =
  var
    dy = dy
    dx: float64 = 0
  self.relToAbs(dx, dy)
  self.mVert.addVertex(dx, dy, pathCmdLineTo)

proc concatPath*[VC, VertexSource](self: var PathBase[VC], vs: var VertexSource, pathId = 0) =
  var x, y: float64

  vs.rewind(pathId)
  var cmd = vs.vertex(x, y)

  while not isStop(cmd):
    self.mVert.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

proc joinPath*[VC, VertexSource](self: var PathBase[VC], vs: VertexSource, pathId = 0) =
  var x, y: float64

  vs.rewind(pathId)
  var cmd = vs.vertex(x, y)

  if not isStop(cmd):
    if isVertex(cmd):
      var x0, y0: float64
      var cmd0 = self.lastVertex(x0, y0)
      if isVertex(cmd0):
        if calcDistance(x, y, x0, y0) > vertexDistEpsilon:
          if isMoveTo(cmd): cmd = pathCmdLineTo
          self.mVert.addVertex(x, y, cmd)
      else:
       if isStop(cmd0):
         cmd = pathCmdMoveTo
       else:
         if isMoveTo(cmd): cmd = pathCmdLineTo
       self.mVert.addVertex(x, y, cmd)

    cmd = vs.vertex(x, y)
    while not isStop(cmd):
      self.mVert.addVertex(x, y, if isMoveTo(cmd): pathCmdLineTo else: cmd)
      cmd = vs.vertex(x, y)

proc concatPoly*[VC, T](self: var PathBase[VC], data: ptr T, numPoints: int, closed: bool) =
  var poly = initPolyPlainAdaptor(data, numPoints, closed)
  self.concatPath(poly)

proc joinPoly*[VC, T](self: var PathBase[VC], data: ptr T, numPoints: int, closed: bool) =
  var poly = initPolyPlainAdaptor(data, numPoints, closed)
  self.joinPath(poly)

proc transform*[VC, Trans](self: var PathBase[VC], trans: Trans, pathId = 0) =
  let numVer = self.mVert.totalVertices()
  var pathId = pathId
  while pathId < numVer:
    var x, y: float64
    var cmd = self.mVert.vertex(pathId, x, y)
    if isStop(cmd): break
    if isVertex(cmd):
      trans.transform(x, y)
      self.mVert.modifyVertex(pathId, x, y)
    inc pathId

proc transformAllPaths*[VC, Trans](self: var PathBase[VC], trans: Trans) =
  let numVer = self.mVert.totalVertices()
  for idx in 0.. <numVer:
    var x, y: float64
    if isVertex(self.mVert.vertex(idx, x, y)):
      trans.transform(x, y)
      self.mVert.modifyVertex(idx, x, y)

proc arcTo*[VC](self: var PathBase[VC], rx, ry, angle: float64, largeArcFlag, sweepFlag: bool, x, y: float64) =
  if self.mVert.totalVertices() and isVertex(self.mVert.lastCommand()):
    const epsilon = 1e-30
    var
      x0: float64 = 0.0
      y0: float64 = 0.0

    self.mVert.lastVertex(x0, y0)
    rx = abs(rx)
    ry = abs(ry)

    # Ensure radii are valid
    #-------------------------
    if rx < epsilon or ry < epsilon:
      self.lineTo(x, y)
      return

    if calcDistance(x0, y0, x, y) < epsilon:
      # If the endpoints (x, y) and (x0, y0) are identical, then this
      # is equivalent to omitting the elliptical arc segment entirely.
      return

    var a = initBezierArcSvg(x0, y0, rx, ry, angle, largeArcFlag, sweepFlag, x, y)
    if a.isRadiiOK():
      self.joinPath(a)
    else:
      self.lineTo(x, y)
  else:
    self.moveTo(x, y)

proc arcRel*[VC](self: var PathBase[VC], rx, ry, angle: float64, largeArcFlag, sweepFlag: bool, dx, dy: float64) =
  self.relToAbs(dx, dy)
  self.arcTo(rx, ry, angle, largeArcFlag, sweepFlag, dx, dy)

proc curve3*[VC](self: var PathBase[VC], xCtrl, yCtrl, xTo, yTo: float64) =
  self.mVert.addVertex(xCtrl, yCtrl, pathCmdCurve3)
  self.mVert.addVertex(xTo,   yTo,   pathCmdCurve3)

proc curve3Rel*[VC](self: var PathBase[VC], dxCtrl, dyCtrl, dxTo, dyTo: float64) =
  var
    dxCtrl = dxCtrl
    dyCtrl = dyCtrl
    dxTo = dxTo
    dyTo = dyTo

  self.relToAbs(dxCtrl, dyCtrl)
  self.relToAbs(dxTo,  dyTo)
  self.mVert.addVertex(dxCtrl, dyCtrl, pathCmdCurve3)
  self.mVert.addVertex(dxTo,   dyTo,   pathCmdCurve3)

proc curve3*[VC](self: var PathBase[VC], xTo, yTo: float64) =
  var x0, y0: float64

  if isVertex(self.mVert.lastVertex(x0, y0)):
    var
      xCtrl, yCtrl: float64
      cmd = self.mVert.prevVertex(xCtrl, yCtrl)

    if isCurve(cmd):
      xCtrl = x0 + x0 - xCtrl
      yCtrl = y0 + y0 - yCtrl
    else:
      xCtrl = x0
      yCtrl = y0
    self.curve3(xCtrl, yCtrl, xTo, yTo)

proc curve3Rel*[VC](self: var PathBase[VC], dxTo, dyTo: float64) =
  var
    dxTo = dxTo
    dyTo = dyTo
  self.relToAbs(dxTo, dyTo)
  self.curve3(dxTo, dyTo)

proc curve4*[VC](self: var PathBase[VC], xCtrl1, yCtrl1, xCtrl2, yCtrl2, xTo, yTo: float64) =
  self.mVert.addVertex(xCtrl1, yCtrl1, pathCmdCurve4)
  self.mVert.addVertex(xCtrl2, yCtrl2, pathCmdCurve4)
  self.mVert.addVertex(xTo,    yTo,    pathCmdCurve4)

proc curve4Rel*[VC](self: var PathBase[VC], dxCtrl1, dyCtrl1, dxCtrl2, dyCtrl2, dxTo, dyTo: float64) =
  var
    dxCtrl1 = dxCtrl1
    dyCtrl1 = dyCtrl1
    dxCtrl2 = dxCtrl2
    dyCtrl2 = dxCtrl2
    dxTo = dxTo
    dyTo = dyTo

  self.relToAbs(dxCtrl1, dyCtrl1)
  self.relToAbs(dxCtrl2, dyCtrl2)
  self.relToAbs(dxTo,    dyTo)
  self.mVert.addVertex(dxCtrl1, dyCtrl1, pathCmdCurve4)
  self.mVert.addVertex(dxCtrl2, dyCtrl2, pathCmdCurve4)
  self.mVert.addVertex(dxTo,    dyTo,    pathCmdCurve4)

proc curve4*[VC](self: var PathBase[VC], xCtrl2, yCtrl2, xTo, yTo: float64) =
  var x0, y0: float64

  if isVertex(self.lastVertex(x0, y0)):
    var xCtrl1, yCtrl1: float64
    var cmd = self.prevVertex(xCtrl1, yCtrl1)

    if isCurve(cmd):
      xCtrl1 = x0 + x0 - xCtrl1
      yCtrl1 = y0 + y0 - yCtrl1
    else:
      xCtrl1 = x0
      yCtrl1 = y0

    self.curve4(xCtrl1, yCtrl1, xCtrl2, yCtrl2, xTo, yTo)

proc curve4Rel*[VC](self: var PathBase[VC], dxCtrl2, dyCtrl2, dxTo, dyTo: float64) =
  var
    dxCtrl2 = dxCtrl2
    dyCtrl2 = dyCtrl2
    dxTo = dxTo
    dyTo = dyTo

  self.relToAbs(dxCtrl2, dyCtrl2)
  self.relToAbs(dxTo, dyTo)
  self.curve4(dxCtrl2, dyCtrl2, dxTo, dyTo)

proc perceivePolygonOrientation*[VC](self: var PathBase[VC], start, stop: int): uint =
  let np = stop - start
  var
    area = 0.0'f64
    x1, y1, x2, y2: float64

  for i in 0.. <np:
    discard self.mVert.vertex(start + i,            x1, y1)
    discard self.mVert.vertex(start + (i + 1) mod np, x2, y2)
    area += x1 * y2 - y1 * x2

  result = if area < 0.0: pathFlagsCw else: pathFlagsCcw

proc invertPolygon*[VC](self: var PathBase[VC], start, stop: int) =
  var
    tmpCmd = self.mVert.command(start)
    stop = stop
    start = start

  dec stop # Make "end" inclusive

  # Shift all commands to one position
  for i in start.. <stop:
    self.mVert.modifyCommand(i, self.mVert.command(i + 1))

  # Assign starting command to the ending command
  self.mVert.modifyCommand(stop, tmpCmd)

  # Reverse the polygon
  while stop > start:
    self.mVert.swapVertices(start, stop)
    inc start
    dec stop

proc invertPolygon*[VC](self: var PathBase[VC], start: int) =
  let len = self.mVert.totalVertices()
  var start = start

  # Skip all non-vertices at the beginning
  while start < len and (not isVertex(self.mVert.command(start))):
    inc start

  # Skip all insignificant move_to
  while start+1 < len and
    isMoveTo(self.mVert.command(start)) and
    isMoveTo(self.mVert.command(start+1)):
    inc start

  # Find the last vertex
  var stop = start + 1
  while stop < len and (not isNextPoly(self.mVert.command(stop))):
    inc stop

  self.invertPolygon(start, stop)

proc arrangePolygonOrientation*[VC](self: var PathBase[VC], start: int, orientation: uint): int =
  if orientation == pathFlagsNone: return start
  let len = self.mVert.totalVertices()

  var start = start
  # Skip all non-vertices at the beginning
  while start < len and (not isVertex(self.mVert.command(start))):
    inc start

  # Skip all insignificant move_to
  while start+1 < len and
    isMoveTo(self.mVert.command(start)) and
    isMoveTo(self.mVert.command(start+1)):
    inc start

  # Find the last vertex
  var stop = start + 1
  while stop < len and (not isNextPoly(self.mVert.command(stop))):
    inc stop

  if stop - start > 2:
    if self.perceivePolygonOrientation(start, stop) != orientation:
      # Invert polygon, set orientation flag, and skip all end_poly
      self.invertPolygon(start, stop)
      if stop < len:
        var cmd = self.mVert.command(stop)
        while stop < len and isEndPoly(cmd):
          self.mVert.modifyCommand(stop, setOrientation(cmd, orientation))
          inc stop
          cmd = self.mVert.command(stop)

  result = stop

proc arrangeOrientations*[VC](self: var PathBase[VC], start: int, orientation: uint): int =
  var start = start

  if orientation != pathFlagsNone:
    let len = self.mVert.totalVertices()
    while start < len:
      start = self.arrangePolygonOrientation(start, orientation)
      if start < len and isStop(self.mVert.command(start)):
        inc start
        break

  result = start

proc arrangeOrientationsAllPaths*[VC](self: var PathBase[VC], orientation: uint) =
  if orientation != pathFlagsNone:
    let len = self.mVert.totalVertices()
    var start = 0
    while start < len:
      start = self.arrangeOrientations(start, orientation)

proc flipX*[VC](self: var PathBase[VC], x1, x2: float64) =
  var x, y: float64
  let len = self.mVert.totalVertices()
  for i in 0.. <len:
    let cmd = self.mVert.vertex(i, x, y)
    if isVertex(cmd):
      self.mVert.modifyVertex(i, x2 - x + x1, y)

proc flipY*[VC](self: var PathBase[VC], y1, y2: float64) =
  var x, y: float64
  let len = self.mVert.totalVertices()
  for i in 0.. <len:
    let cmd = self.mVert.vertex(i, x, y)
    if isVertex(cmd):
      self.mVert.modifyVertex(i, x, y2 - y + y1)

proc translate*[VC](self: var PathBase[VC], dx, dy: float64, pathId: int) =
  let numVer = self.mVert.totalVertices()
  var pathId = pathId
  while pathId < numVer:
    var
      x, y: float64
      cmd = self.mVert.vertex(pathId, x, y)
    if isStop(cmd): break
    if isVertex(cmd):
      inc(x, dx)
      inc(y, dy)
      self.mVert.modifyVertex(pathId, x, y)
    inc pathId

proc translateAllPaths*[VC](self: var PathBase[VC], dx, dy: float64) =
  let numVer = self.mVert.totalVertices()
  for idx in 0.. <numVer:
    var x, y: float64
    if isVertex(self.mVert.vertex(idx, x, y)):
      inc(x, dx)
      inc(y, dy)
      self.mVert.modifyVertex(idx, x, y)

type
  VertexStlStorage*[Container] = object
    mVert: Container

proc removeAll*[C](self: var VertexStlStorage[C]) =
  self.mVert.removeAll()

proc freeAll*[C](self: var VertexStlStorage[C]) =
  self.mVert.clear()

proc addVertex*[C](self: var VertexStlStorage[C], x, y: float64, cmd: uint) =
  mixin add
  self.mVert.add VertexD(x: x, y: y, cmd: cmd)

proc modifyVertex*[C](self: var VertexStlStorage[C], idx: int, x, y: float64) =
  var v = self.mVert[idx].addr
  v.x = x
  v.y = y

proc modifyVertex*[C](self: var VertexStlStorage[C], idx: int, x, y: float64, cmd: uint) =
  var v = self.mVert[idx].addr
  v.x = x
  v.y = y
  v.cmd = cmd

proc modifyCommand*[C](self: var VertexStlStorage[C], idx: int, cmd: uint) =
  self.mVert[idx].cmd = cmd

proc swapVertices*[C](self: var VertexStlStorage[C], v1, v2: int) =
  swap(self.mVert[v1], self.mVert[v2])

proc lastCommand*[C](self: VertexStlStorage[C]): uint =
  result = if self.mVert.len != 0: self.mVert[self.mVert.len - 1].cmd else: pathCmdStop
  
proc vertex*[C](self: var VertexStlStorage[C], idx: int, x, y: var float64): uint =
  let v = self.mVert[idx].addr
  x = v.x
  y = v.y
  v.cmd
  
proc lastVertex*[C](self: VertexStlStorage[C], x, y: var float64): uint =
  if self.mVert.len == 0:
    x = 0.0
    y = 0.0
    return pathCmdStop
  result = self.vertex(self.mVert.len - 1, x, y)

proc prevVertex*[C](self: VertexStlStorage[C], x, y: var float64): uint =
  if self.mVert.len < 2:
    x = 0.0
    y = 0.0
    return pathCmdStop
  result = self.vertex(self.mVert.len - 2, x, y)

proc lastX*[C](self: VertexStlStorage[C]): float64 =
  result = if self.mVert.len != 0: self.mVert[self.mVert.len - 1].x else: 0.0

proc lastY*[C](self: VertexStlStorage): float64 =
  result = if self.mVert.len != 0: self.mVert[self.mVert.len - 1].y else: 0.0

proc totalVertices*[C](self: VertexStlStorage[C]): int =
  self.mVert.len

proc command*[C](self: VertexStlStorage[C], idx: int): uint =
  self.mVert[idx].cmd
