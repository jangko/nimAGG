import agg_basics, agg_vertex_sequence, agg_array

type
  Status = enum
    initial
    makingPath
    ready

  TransSinglePath* = object
    mSrcVertices: VertexSequence[VertexDist]
    mBaseLength: float64
    mKindex: float64
    mStatus: Status
    mPreserveXscale: bool

proc initTransSinglePath*(): TransSinglePath =
  result.mBaseLength = 0.0
  result.mKindex = 0.0
  result.mStatus = initial
  result.mPreserveXscale = true
  result.mSrcVertices = initVertexSequence[VertexDist]()

proc baseLength*(self: var TransSinglePath, v: float64) =
  self.mBaseLength = v

proc baseLength*(self: TransSinglePath): float64 =
  self.mBaseLength

proc preserveXscale*(self: var TransSinglePath, f: bool) =
  self.mPreserveXscale = f

proc preserveXscale*(self: TransSinglePath): bool =
  self.mPreserveXscale

proc reset*(self: var TransSinglePath) =
  self.mSrcVertices.removeAll()
  self.mKindex = 0.0
  self.mStatus = initial

proc lineTo*(self: var TransSinglePath, x, y: float64) =
  if self.mStatus == makingPath:
    self.mSrcVertices.add(initVertexDist(x, y))

proc moveTo*(self: var TransSinglePath, x, y: float64) =
  if self.mStatus == initial:
    self.mSrcVertices.modifyLast(initVertexDist(x, y))
    self.mStatus = makingPath
  else:
    self.lineTo(x, y)

proc finalizePath*(self: var TransSinglePath) =
  if self.mStatus == makingPath and self.mSrcVertices.len() > 1:
    var dist, d: float64

    self.mSrcVertices.close(false)
    if self.mSrcVertices.len() > 2:
      if self.mSrcVertices[self.mSrcVertices.len() - 2].dist * 10.0 <
         self.mSrcVertices[self.mSrcVertices.len() - 3].dist:
         d = self.mSrcVertices[self.mSrcVertices.len() - 3].dist +
             self.mSrcVertices[self.mSrcVertices.len() - 2].dist

         self.mSrcVertices[self.mSrcVertices.len() - 2] = self.mSrcVertices[self.mSrcVertices.len() - 1]

         self.mSrcVertices.removeLast()
         self.mSrcVertices[self.mSrcVertices.len() - 2].dist = d

    dist = 0.0
    for v in mitems(self.mSrcVertices):
      var d = v.dist
      v.dist = dist
      dist += d
    self.mKindex = float64(self.mSrcVertices.len() - 1) / dist
    self.mStatus = ready

proc addPath*[VertexSource](self: var TransSinglePath, vs: var VertexSource, pathId = 0) =
  var
    x, y: float64
    cmd: uint

  vs.rewind(pathId)
  cmd = vs.vertex(x, y)
  while not isStop(cmd):
    if isMoveTo(cmd):
      self.moveTo(x, y)
    else:
      if isVertex(cmd):
        self.lineTo(x, y)
    cmd = vs.vertex(x, y)
  self.finalizePath()

proc totalLength*(self: TransSinglePath): float64 =
  if self.mBaseLength >= 1e-10: return self.mBaseLength
  if self.mStatus == ready:
    result = self.mSrcVertices.last().dist
  else:
    result = 0.0

proc transform*(self: TransSinglePath, x, y: var float64) =
  if self.mStatus == ready:
    if self.mBaseLength > 1e-10:
      x *= self.mSrcVertices.last().dist / self.mBaseLength

    var
      x1 = 0.0
      y1 = 0.0
      dx = 1.0
      dy = 1.0
      d  = 0.0
      dd = 1.0
    if x < 0.0:
      # Extrapolation on the left
      x1 = self.mSrcVertices[0].x
      y1 = self.mSrcVertices[0].y
      dx = self.mSrcVertices[1].x - x1
      dy = self.mSrcVertices[1].y - y1
      dd = self.mSrcVertices[1].dist - self.mSrcVertices[0].dist
      d  = x
    elif x > self.mSrcVertices[self.mSrcVertices.len() - 1].dist:
      # Extrapolation on the right
      var
        i = self.mSrcVertices.len() - 2
        j = self.mSrcVertices.len() - 1
      x1 = self.mSrcVertices[j].x
      y1 = self.mSrcVertices[j].y
      dx = x1 - self.mSrcVertices[i].x
      dy = y1 - self.mSrcVertices[i].y
      dd = self.mSrcVertices[j].dist - self.mSrcVertices[i].dist
      d  = x - self.mSrcVertices[j].dist
    else:
      # Interpolation
      var
        i = 0
        j = self.mSrcVertices.len() - 1
      if self.mPreserveXscale:
        while (j - i) > 1:
          let k = (i + j) shr 1
          if  x < self.mSrcVertices[k].dist:
            j = k
          else:
            i = k

        d  = self.mSrcVertices[i].dist
        dd = self.mSrcVertices[j].dist - d
        d  = x - d
      else:
        i = int(x * self.mKindex)
        j = i + 1
        dd = self.mSrcVertices[j].dist - self.mSrcVertices[i].dist
        d = ((x * self.mKindex) - i.float64) * dd
      x1 = self.mSrcVertices[i].x
      y1 = self.mSrcVertices[i].y
      dx = self.mSrcVertices[j].x - x1
      dy = self.mSrcVertices[j].y - y1
    var
      x2 = x1 + dx * d / dd
      y2 = y1 + dy * d / dd
    x = x2 - y * dy / dd
    y = y2 + y * dx / dd
