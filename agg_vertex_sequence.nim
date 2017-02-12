import agg_math

# Vertex (x, y) with the distance to the next one. The last vertex has
# distance between the last and the first points if the polygon is closed
# and 0.0 if it's a polyline.

type
  VertexDist* = object of RootObj
    x*, y*, dist*: float64

proc initVertexDist*(x, y: float64): VertexDist =
  result.x = x
  result.y = y
  result.dist = 0.0

proc cmp*(self: var VertexDist, val: VertexDist): bool =
  self.dist = calcDistance(self.x, self.y, val.x, val.y)
  result = self.dist > vertexDistEpsilon
  if not result: self.dist = 1.0 / vertexDistEpsilon

type
  # Same as the above but with additional "command" value
  VertexDistCmd* = object of VertexDist
    cmd*: uint

proc cmp*(self: var VertexDistCmd, val: VertexDistCmd): bool =
  result = cmp(self.VertexDist, val.VertexDist)

proc initVertexDistCmd*(x, y: float64, cmd: uint): VertexDistCmd =
  result.x = x
  result.y = y
  result.dist = 0.0
  result.cmd = cmd

type
  VertexSequence*[T] = object
    vert: seq[T]

proc removeLast*[T](x: var seq[T]) {.inline.} =
  if x.len != 0: x.delete(x.len-1)

proc initVertexSequence*[T](): VertexSequence[T] =
  result.vert = @[]

proc add*[T](self: var VertexSequence[T], val: T) =
  if self.vert.len > 1:
    let len = self.vert.len
    if not self.vert[len-2].cmp(self.vert[len-1]):
       self.vert.removeLast()

  self.vert.add(val)

proc modifyLast*[T](self: var VertexSequence[T], val: T) =
  self.vert.removeLast()
  self.add(val)

proc close*[T](self: var VertexSequence[T], closed: bool) =
  while self.vert.len > 1:
    let len = self.vert.len
    if self.vert[len-2].cmp(self.vert[len-1]): break
    var t = self.vert[len-1]
    self.vert.removeLast()
    self.modifyLast(t)

  if closed:
    while  self.vert.len > 1:
      let len = self.vert.len
      if self.vert[len-1].cmp(self.vert[0]): break
      self.vert.removeLast()

proc curr*[T](self: var VertexSequence[T], idx: int): var T =
  self.vert[idx]

proc next*[T](self: var VertexSequence[T], idx: int): var T =
  self.vert[(idx + 1) mod self.vert.len]

proc prev*[T](self: var VertexSequence[T], idx: int): var T =
  let size = self.vert.len
  self.vert[(idx + size - 1) mod size]

proc `[]`*[T](self: var VertexSequence[T], idx: int): var T = self.vert[idx]
proc len*[T](self: VertexSequence[T]): int = self.vert.len
proc removeLast*[T](self: var VertexSequence[T]) = self.vert.removeLast()
proc removeAll*[T](self: var VertexSequence[T]) = self.vert.setLen(0)