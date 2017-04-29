import agg_basics, agg_line_aa_basics, agg_vertex_sequence, math

proc cmpDistStart(d: int): bool = d > 0
proc cmpDistEnd(d: int): bool = d <= 0

type
  LineAAVertex* = object
    x, y, len: int

proc initLineAAVertex*(x, y: int): LineAAVertex =
  result.x = x
  result.y = y
  result.len = 0

proc cmp*(self, val: var LineAAVertex): bool =
  let
    dx = val.x - self.x
    dy = val.y - self.y

  self.len = uround(sqrt((dx * dx + dy * dy).float64))
  result =  self.len > (lineSubpixelScale + lineSubpixelScale div 2)

type
  OutlineAAJoin* = enum
    outlineNoJoin
    outlineMiterJoin
    outlineRoundJoin
    outlineMiterAccurateJoin

  RasterizerOutlineAA*[Renderer] =object
    mRen: ptr Renderer
    mSrcVertices: VertexSequence[LineAAVertex]
    mLineJoin: OutlineAAJoin
    mRoundCap: bool
    mStartX, mStartY: int

  DrawVars = object
    idx: int
    x1, y1, x2, y2: int
    curr, next: LineParameters
    lcurr, lnext: int
    xb1, yb1, xb2, yb2: int
    flags: uint

proc render*[Renderer](self: var RasterizerOutlineAA[Renderer], closePolygon: bool)
proc draw*[Renderer](self: var RasterizerOutlineAA[Renderer], dv: var DrawVars, start, stop: int)

proc initRasterizerOutlineAA*[Renderer](ren: var Renderer): RasterizerOutlineAA[Renderer] =
  result.mRen = ren.addr
  result.mLineJoin = if ren.accurateJoinOnly(): outlineMiterAccurateJoin else: outlineRoundJoin
  result.mRoundCap = false
  result.mStartX = 0
  result.mStartY = 0
  result.mSrcVertices = initVertexSequence[LineAAVertex]()

proc attach*[Renderer](self: var RasterizerOutlineAA[Renderer], ren: var Renderer) =
  self.mRen = ren.addr

proc lineJoin*[Renderer](self: var RasterizerOutlineAA[Renderer], join: OutlineAAJoin) =
  self.mLineJoin = if self.mRen[].accurateJoinOnly(): outlineMiterAccurateJoin else: join

proc lineJoin*[Renderer](self: RasterizerOutlineAA[Renderer]): bool = self.mLineJoin

proc roundCap*[Renderer](self: var RasterizerOutlineAA[Renderer], v: bool) = self.mRoundCap = v
proc roundCap*[Renderer](self: RasterizerOutlineAA[Renderer]): bool = self.mRoundCap

proc moveTo*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: int) =
  self.mStartX = x
  self.mStartY = y
  self.mSrcVertices.modifyLast(initLineAAVertex(x, y))

proc lineTo*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: int) =
  self.mSrcVertices.add(initLineAAVertex(x, y))

proc moveToD*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: float64, Coord: typedesc) =
  self.moveTo(Coord.conv(x), Coord.conv(y))

proc lineToD*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: float64, Coord: typedesc) =
  self.lineTo(Coord.conv(x), Coord.conv(y))

proc moveToD*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: float64) =
  self.moveTo(LineCoord.conv(x), LineCoord.conv(y))

proc lineToD*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: float64) =
  self.lineTo(LineCoord.conv(x), LineCoord.conv(y))

proc addVertex*[Renderer](self: var RasterizerOutlineAA[Renderer], x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    self.render(false)
    self.moveToD(x, y, LineCoord)
  else:
    if isEndPoly(cmd):
      self.render(isClosed(cmd))
      if isClosed(cmd):
        self.moveTo(self.mStartX, self.mStartY)
    else:
      self.lineToD(x, y, LineCoord)

proc addPath*[Renderer, VertexSource](self: var RasterizerOutlineAA[Renderer], vs: var VertexSource, pathId = 0) =
  mixin rewind
  var
    x, y: float64
    cmd: uint

  vs.rewind(pathId)
  cmd = vs.vertex(x, y)

  while not isStop(cmd):
    self.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

  self.render(false)

proc renderAllPaths*[Renderer, VertexSource, ColorT](self: var RasterizerOutlineAA[Renderer],
  vs: var VertexSource, colors: openArray[ColorT], pathId: openArray[int], numPaths: int) =
  for i in 0.. <numPaths:
    self.mRen[].color(colors[i])
    self.addPath(vs, pathId[i])

proc renderCtrl*[Renderer, Ctrl](self: var RasterizerOutlineAA[Renderer], c: var Ctrl) =
  for i in 0.. <c.numPaths():
    self.mRen[].color(c.color(i))
    self.addPath(c, i)

proc draw*[Renderer](self: var RasterizerOutlineAA[Renderer], dv: var DrawVars, start, stop: int) =
  for i in start.. <stop:
    if self.mLineJoin == outlineRoundJoin:
      dv.xb1 = dv.curr.x1 + (dv.curr.y2 - dv.curr.y1)
      dv.yb1 = dv.curr.y1 - (dv.curr.x2 - dv.curr.x1)
      dv.xb2 = dv.curr.x2 + (dv.curr.y2 - dv.curr.y1)
      dv.yb2 = dv.curr.y2 - (dv.curr.x2 - dv.curr.x1)

    case dv.flags
    of 0:
      self.mRen[].line3(dv.curr, dv.xb1, dv.yb1, dv.xb2, dv.yb2)
    of 1:
      self.mRen[].line2(dv.curr, dv.xb2, dv.yb2)
    of 2:
      self.mRen[].line1(dv.curr, dv.xb1, dv.yb1)
    of 3:
      self.mRen[].line0(dv.curr)
    else: discard

    if self.mLineJoin == outlineRoundJoin and ((dv.flags and 2) == 0):
        self.mRen[].pie(dv.curr.x2, dv.curr.y2,
                        dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                        dv.curr.y2 - (dv.curr.x2 - dv.curr.x1),
                        dv.curr.x2 + (dv.next.y2 - dv.next.y1),
                        dv.curr.y2 - (dv.next.x2 - dv.next.x1))

    dv.x1 = dv.x2
    dv.y1 = dv.y2
    dv.lcurr = dv.lnext
    var vx = self.mSrcVertices[dv.idx]
    dv.lnext = vx.len

    inc dv.idx
    if dv.idx >= self.mSrcVertices.len: dv.idx = 0

    let v = addr(self.mSrcVertices[dv.idx])
    dv.x2 = v.x
    dv.y2 = v.y

    dv.curr = dv.next
    dv.next = initLineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext)
    dv.xb1 = dv.xb2
    dv.yb1 = dv.yb2

    case self.mLineJoin
    of outlineNoJoin:
        dv.flags = 3
    of outlineMiterJoin:
        dv.flags = dv.flags shr 1
        dv.flags = dv.flags or
          ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()).uint shl 1)
        if (dv.flags and 2) == 0:
          bisectrix(dv.curr, dv.next, dv.xb2, dv.yb2)
    of outlineRoundJoin:
      dv.flags = dv.flags shr 1
      dv.flags = dv.flags or
        ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()).uint shl 1)
    of outlineMiterAccurateJoin:
      dv.flags = 0
      bisectrix(dv.curr, dv.next, dv.xb2, dv.yb2)

proc render*[Renderer](self: var RasterizerOutlineAA[Renderer], closePolygon: bool) =
  self.mSrcVertices.close(closePolygon)

  var
    dv: DrawVars
    x1, y1, x2, y2, lprev: int

  if closePolygon:
    if self.mSrcVertices.len >= 3:
      dv.idx = 2

      var v = addr(self.mSrcVertices[self.mSrcVertices.len - 1])
      x1    = v.x
      y1    = v.y
      lprev = v.len

      v  = addr(self.mSrcVertices[0])
      x2 = v.x
      y2 = v.y
      dv.lcurr = v.len
      var prev = initLineParameters(x1, y1, x2, y2, lprev)

      v = addr(self.mSrcVertices[1])
      dv.x1    = v.x
      dv.y1    = v.y
      dv.lnext = v.len
      dv.curr = initLineParameters(x2, y2, dv.x1, dv.y1, dv.lcurr)

      v = addr(self.mSrcVertices[dv.idx])
      dv.x2 = v.x
      dv.y2 = v.y
      dv.next = initLineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext)

      dv.xb1 = 0
      dv.yb1 = 0
      dv.xb2 = 0
      dv.yb2 = 0

      case self.mLineJoin
      of outlineNoJoin:
          dv.flags = 3
      of outlineMiterJoin, outlineRoundJoin:
        dv.flags = ((prev.diagonalQuadrant() == dv.curr.diagonalQuadrant()).int or
          ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()).int shl 1)).uint
      of outlineMiterAccurateJoin:
        dv.flags = 0
      else: discard


      if (dv.flags and 1) == 0 and self.mLineJoin != outlineRoundJoin:
         bisectrix(prev, dv.curr, dv.xb1, dv.yb1)

      if (dv.flags and 2) == 0 and self.mLineJoin != outlineRoundJoin:
         bisectrix(dv.curr, dv.next, dv.xb2, dv.yb2)

      self.draw(dv, 0, self.mSrcVertices.len)
  else:
    case self.mSrcVertices.len
      of 0, 1: discard
      of 2:
        var v = addr(self.mSrcVertices[0])
        x1    = v.x
        y1    = v.y
        lprev = v.len
        v     = addr(self.mSrcVertices[1])
        x2    = v.x
        y2    = v.y
        var lp = initLineParameters(x1, y1, x2, y2, lprev)
        if self.mRoundCap:
          self.mRen[].semidot(cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1))

        self.mRen[].line3(lp,
                    x1 + (y2 - y1),
                    y1 - (x2 - x1),
                    x2 + (y2 - y1),
                    y2 - (x2 - x1))
        if self.mRoundCap:
          self.mRen[].semidot(cmpDistEnd, x2, y2, x2 + (y2 - y1), y2 - (x2 - x1))
      of 3:
        var
          x3, y3, lnext: int
          v     = addr(self.mSrcVertices[0])

        x1    = v.x
        y1    = v.y
        lprev = v.len
        v     = addr(self.mSrcVertices[1])
        x2    = v.x
        y2    = v.y
        lnext = v.len
        v     = addr(self.mSrcVertices[2])
        x3    = v.x
        y3    = v.y
        var
          lp1 = initLineParameters(x1, y1, x2, y2, lprev)
          lp2 = initLineParameters(x2, y2, x3, y3, lnext)

        if self.mRoundCap:
          self.mRen[].semidot(cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1))

        if self.mLineJoin == outlineRoundJoin:
          self.mRen[].line3(lp1, x1 + (y2 - y1), y1 - (x2 - x1),
                            x2 + (y2 - y1), y2 - (x2 - x1))

          self.mRen[].pie(x2, y2, x2 + (y2 - y1), y2 - (x2 - x1),
                          x2 + (y3 - y2), y2 - (x3 - x2))

          self.mRen[].line3(lp2, x2 + (y3 - y2), y2 - (x3 - x2),
                            x3 + (y3 - y2), y3 - (x3 - x2))
        else:
          bisectrix(lp1, lp2, dv.xb1, dv.yb1)
          self.mRen[].line3(lp1, x1 + (y2 - y1), y1 - (x2 - x1), dv.xb1, dv.yb1)
          self.mRen[].line3(lp2, dv.xb1, dv.yb1, x3 + (y3 - y2), y3 - (x3 - x2))

        if self.mRoundCap:
          self.mRen[].semidot(cmpDistEnd, x3, y3, x3 + (y3 - y2), y3 - (x3 - x2))
      else:
        dv.idx = 3

        var v = addr(self.mSrcVertices[0])
        x1    = v.x
        y1    = v.y
        lprev = v.len

        v  = addr(self.mSrcVertices[1])
        x2 = v.x
        y2 = v.y
        dv.lcurr = v.len
        var prev = initLineParameters(x1, y1, x2, y2, lprev)

        v = addr(self.mSrcVertices[2])
        dv.x1    = v.x
        dv.y1    = v.y
        dv.lnext = v.len
        dv.curr = initLineParameters(x2, y2, dv.x1, dv.y1, dv.lcurr)

        v = addr(self.mSrcVertices[dv.idx])
        dv.x2 = v.x
        dv.y2 = v.y
        dv.next = initLineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext)

        dv.xb1 = 0
        dv.yb1 = 0
        dv.xb2 = 0
        dv.yb2 = 0

        case self.mLineJoin
        of outlineNoJoin:
          dv.flags = 3
        of outlineMiterJoin, outlineRoundJoin:
            dv.flags = (prev.diagonalQuadrant() == dv.curr.diagonalQuadrant()).uint or
                       ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()).uint shl 1)
        of outlineMiterAccurateJoin:
            dv.flags = 0

        if self.mRoundCap:
          self.mRen[].semidot(cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1))

        if (dv.flags and 1) == 0:
          if self.mLineJoin == outlineRoundJoin:
            self.mRen[].line3(prev, x1 + (y2 - y1), y1 - (x2 - x1),
                              x2 + (y2 - y1), y2 - (x2 - x1))
            self.mRen[].pie(prev.x2, prev.y2,
                      x2 + (y2 - y1), y2 - (x2 - x1),
                      dv.curr.x1 + (dv.curr.y2 - dv.curr.y1),
                      dv.curr.y1 - (dv.curr.x2 - dv.curr.x1))
          else:
            bisectrix(prev, dv.curr, dv.xb1, dv.yb1)
            self.mRen[].line3(prev, x1 + (y2 - y1), y1 - (x2 - x1), dv.xb1, dv.yb1)
        else:
          self.mRen[].line1(prev, x1 + (y2 - y1), y1 - (x2 - x1))

        if (dv.flags and 2) == 0 and self.mLineJoin != outlineRoundJoin:
          bisectrix(dv.curr, dv.next, dv.xb2, dv.yb2)

        self.draw(dv, 1, self.mSrcVertices.len - 2)

        if (dv.flags and 1) == 0:
          if self.mLineJoin == outlineRoundJoin:
            self.mRen[].line3(dv.curr,
                          dv.curr.x1 + (dv.curr.y2 - dv.curr.y1),
                          dv.curr.y1 - (dv.curr.x2 - dv.curr.x1),
                          dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                          dv.curr.y2 - (dv.curr.x2 - dv.curr.x1))
          else:
            self.mRen[].line3(dv.curr, dv.xb1, dv.yb1,
                          dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                          dv.curr.y2 - (dv.curr.x2 - dv.curr.x1))
        else:
          self.mRen[].line2(dv.curr,
                        dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                        dv.curr.y2 - (dv.curr.x2 - dv.curr.x1))
        if self.mRoundCap:
          self.mRen[].semidot(cmpDistEnd, dv.curr.x2, dv.curr.y2,
                          dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                          dv.curr.y2 - (dv.curr.x2 - dv.curr.x1))

  self.mSrcVertices.removeAll()
