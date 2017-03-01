import agg_math, agg_basics

proc pathLength*[VertexSource](vs: var VertexSource, pathId = 0): float64 =
  var
    len = 0.0
    startX = 0.0
    startY = 0.0
    x1 = 0.0
    y1 = 0.0
    x2 = 0.0
    y2 = 0.0
    first = true
    cmd: uint

  vs.rewind(pathId)
  cmd = vs.vertex(x2, y2)
  while not isStop(cmd):
    if isVertex(cmd):
      if first or isMoveTo(cmd):
        startX = x2
        startY = y2
      else:
        len += calcDistance(x1, y1, x2, y2)
      x1 = x2
      y1 = y2
      first = false
    else:
      if isClose(cmd) and not first:
        len += calcDistance(x1, y1, startX, startY)
    cmd = vs.vertex(x2, y2)
  result = len

