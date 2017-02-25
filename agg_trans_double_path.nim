import agg_basics, agg_vertex_sequence

type
  Status = enum
    initial
    makingPath
    ready

  TransDoublePath* = object
    mSrcVertices1: VertexSequence[VertexDist]
    mSrcVertices2: VertexSequence[VertexDist]
    mBaseLength, mBaseHeight: float64
    mKindex1, mKindex2: float64
    mStatus1, mStatus2: Status
    mPreserveXscale: bool

proc initTransDoublePath*(): TransDoublePath =
  result.mKindex1 = 0.0
  result.mKindex2 = 0.0
  result.mBaseLength = 0.0
  result.mBaseHeight = 1.0
  result.mStatus1 = initial
  result.mStatus2 = initial
  result.mPreserveXscale = true
  result.mSrcVertices1 = initVertexSequence[VertexDist]()
  result.mSrcVertices2 = initVertexSequence[VertexDist]()

proc baseLength*(self: var TransDoublePath, v: float64) =
  self.mBaseLength = v

proc baseLength*(self:  TransDoublePath): float64 =
  self.mBaseLength

proc baseHeight*(self: var TransDoublePath, v: float64) =
  self.mBaseHeight = v

proc baseHeight*(self: TransDoublePath): float64 =
  self.mBaseHeight

proc preserveXscale*(self: var TransDoublePath, f: bool) =
  self.mPreserveXscale = f

proc preserveXscale*(self: TransDoublePath): bool =
  self.mPreserveXscale

proc reset*(self: var TransDoublePath) =
  self.mSrcVertices1.removeAll()
  self.mSrcVertices2.removeAll()
  self.mKindex1 = 0.0
  self.mKindex1 = 0.0
  self.mStatus1 = initial
  self.mStatus2 = initial

proc lineTo1*(self: var TransDoublePath, x, y: float64) =
  if self.mStatus1 == makingPath:
    self.mSrcVertices1.add(initVertexdist(x, y))

proc moveTo1*(self: var TransDoublePath, x, y: float64) =
  if self.mStatus1 == initial:
    self.mSrcVertices1.modifyLast(initVertexdist(x, y))
    self.mStatus1 = makingPath
  else:
    self.lineTo1(x, y)

proc lineTo2*(self: var TransDoublePath, x, y: float64) =
  if self.mStatus2 == makingPath:
    self.mSrcVertices2.add(initVertexdist(x, y))

proc moveTo2*(self: var TransDoublePath, x, y: float64) =
  if self.mStatus2 == initial:
    self.mSrcVertices2.modifyLast(initVertexdist(x, y))
    self.mStatus2 = makingPath
  else:
    self.lineTo2(x, y)

proc finalizePath*(self: var TransDoublePath, vertices: var VertexSequence[VertexDist]): float64 =
  var
    dist, d :float64

  vertices.close(false)
  if vertices.len() > 2:
    if vertices[vertices.len() - 2].dist * 10.0 < vertices[vertices.len() - 3].dist:
      d = vertices[vertices.len() - 3].dist + vertices[vertices.len() - 2].dist
      vertices[vertices.len() - 2] =  vertices[vertices.len() - 1]
      vertices.removeLast()
      vertices[vertices.len() - 2].dist = d

  dist = 0
  for v in mitems(vertices):
    d = v.dist;
    v.dist = dist
    dist += d
  result = float64(vertices.len() - 1) / dist

proc finalizePaths*(self: var TransDoublePath) =
  if self.mStatus1 == makingPath and self.mSrcVertices1.len() > 1 and
     self.mStatus2 == makingPath and self.mSrcVertices2.len() > 1:
    self.mKindex1 = self.finalizePath(self.mSrcVertices1)
    self.mKindex2 = self.finalizePath(self.mSrcVertices2)
    self.mStatus1 = ready
    self.mStatus2 = ready

proc totalLength1*(self: TransDoublePath): float64 =
  if self.mBaseLength >= 1e-10: return self.mBaseLength
  result = if self.mStatus1 == ready: self.mSrcVertices1[self.mSrcVertices1.len() - 1].dist else: 0.0

proc totalLength2*(self: var TransDoublePath): float64 =
  if self.mBaseLength >= 1e-10: return self.mBaseLength
  result = if self.mStatus2 == ready: self.mSrcVertices2[self.mSrcVertices2.len() - 1].dist else: 0.0

proc addPaths*[VertexSource1, VertexSource2](self: var TransDoublePath,
  vs1: var VertexSource1, vs2: var VertexSource2, path1Id = 0, path2Id = 0) =

  var
    x, y: float64
    cmd: uint

  vs1.rewind(path1Id)
  cmd = vs1.vertex(x, y)
  while not isStop(cmd):
   if isMoveTo(cmd):
      self.moveTo1(x, y)
   else:
     if isVertex(cmd):
       self.lineTo1(x, y)
   cmd = vs1.vertex(x, y)

  vs2.rewind(path2Id)
  cmd = vs2.vertex(x, y)
  while not isStop(cmd):
    if isMoveTo(cmd):
      self.moveTo2(x, y)
    else:
      if isVertex(cmd):
        self.lineTo2(x, y)
    cmd = vs2.vertex(x, y)
  self.finalizePaths()

proc transform1*(self: TransDoublePath, vertices: VertexSequence[VertexDist],
  kindex, kx: float64, x, y: var float64) =

  var
    x1 = 0.0
    y1 = 0.0
    dx = 1.0
    dy = 1.0
    d  = 0.0
    dd = 1.0

  x *= kx
  if x < 0.0:
    # Extrapolation on the left
    x1 = vertices[0].x
    y1 = vertices[0].y
    dx = vertices[1].x - x1
    dy = vertices[1].y - y1
    dd = vertices[1].dist - vertices[0].dist
    d  = x
  elif x > vertices[vertices.len() - 1].dist:
    # Extrapolation on the right
    var
      i = vertices.len() - 2
      j = vertices.len() - 1
    x1 = vertices[j].x
    y1 = vertices[j].y
    dx = x1 - vertices[i].x
    dy = y1 - vertices[i].y
    dd = vertices[j].dist - vertices[i].dist
    d  = x - vertices[j].dist
  else:
    # Interpolation
    var
      i = 0
      j = vertices.len() - 1
    if self.mPreserveXscale:
      while (j - i) > 1:
        let k = (i + j) shr 1
        if x < vertices[k].dist:
          j = k
        else:
          i = k

      d  = vertices[i].dist
      dd = vertices[j].dist - d
      d  = x - d
    else:
      i = int(x * kindex)
      j = i + 1
      dd = vertices[j].dist - vertices[i].dist
      d = ((x * kindex) - i.float64) * dd
    x1 = vertices[i].x
    y1 = vertices[i].y
    dx = vertices[j].x - x1
    dy = vertices[j].y - y1
  x = x1 + dx * d / dd
  y = y1 + dy * d / dd

proc transform*(self: var TransDoublePath, x, y: var float64) =
  if self.mStatus1 == ready and self.mStatus2 == ready:
    if self.mBaseLength > 1e-10:
      x *= self.mSrcVertices1[self.mSrcVertices1.len() - 1].dist / self.mBaseLength

    var
      x1 = x
      y1 = y
      x2 = x
      y2 = y
      dd = self.mSrcVertices2[self.mSrcVertices2.len() - 1].dist /
           self.mSrcVertices1[self.mSrcVertices1.len() - 1].dist

    self.transform1(self.mSrcVertices1, self.mKindex1, 1.0, x1, y1)
    self.transform1(self.mSrcVertices2, self.mKindex2, dd,  x2, y2)

    x = x1 + y * (x2 - x1) / self.mBaseHeight
    y = y1 + y * (y2 - y1) / self.mBaseHeight
