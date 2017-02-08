import agg_basics

type
  RasterizerOutline*[Renderer] = object
    ren: ptr Renderer
    startX: int
    startY: int
    vertices: int

proc initRasterizerOutline*[Renderer](ren: var Renderer): RasterizerOutline[Renderer] =
  result.ren = ren.addr
  result.startX = 0
  result.startY = 0
  result.vertices = 0

proc attach*[Renderer](self: var RasterizerOutline[Renderer], ren: var Renderer) =
  self.ren = ren.addr

proc moveTo*[Renderer](self: var RasterizerOutline[Renderer], x, y: int) =
  mixin moveTo
  self.vertices = 1
  self.ren[].moveTo(x, y)
  self.startX = x
  self.startY = y

proc lineTo*[Renderer](self: var RasterizerOutline[Renderer], x, y: int) =
  mixin lineTo
  inc self.vertices
  self.ren[].lineTo(x, y)

proc moveToD*[Renderer](self: var RasterizerOutline[Renderer], x, y: float64) =
  self.moveTo(Renderer.coord(x), Renderer.coord(y))

proc lineToD*[Renderer](self: var RasterizerOutline[Renderer], x, y: float64) =
  self.lineTo(Renderer.coord(x), Renderer.coord(y))

proc close*[Renderer](self: var RasterizerOutline[Renderer]) =
  if self.vertices > 2:
    self.lineTo(self.startX, self.startY)
  self.vertices = 0

proc addVertex*[Renderer](self: var RasterizerOutline[Renderer], x, y: float64, cmd: uint) =
  if isMoveTo(cmd):
    self.moveToD(x, y)
  else:
    if isEndPoly(cmd):
      if isClosed(cmd): self.close()
    else:
      self.lineToD(x, y)

proc addPath*[Renderer,VertexSource](self: var RasterizerOutline[Renderer], vs: var VertexSource, pathId = 0) =
  var
    x,y: float64
    cmd: uint

  vs.rewind(pathId)
  cmd = vs.vertex(x, y)

  while not isStop(cmd):
    self.addVertex(x, y, cmd)
    cmd = vs.vertex(x, y)

proc renderAllPaths*[Renderer,VertexSource,ColorT](self: var RasterizerOutline[Renderer],
  vs: var VertexSource, colors: openArray[ColorT], pathId: openArray[int], numPaths: int) =
  for i in 0.. <numPaths:
    self.ren[].lineColor(colors[i])
    self.addPath(vs, pathId[i])

proc renderCtrl*[Renderer, Ctrl](self: var RasterizerOutline[Renderer], c: var Ctrl) =
  for i in 0.. <c.numPaths():
    self.ren[].lineColor(c.color(i))
    self.addPath(c, i)
