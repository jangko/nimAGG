import agg_basics

proc boundingRect*[VertexSource, CoordT, T](vs: var VertexSource; gi: T;
  start, num: int; x1, y1, x2, y2: var CoordT): bool =

  x1 = CoordT(1)
  y1 = CoordT(1)
  x2 = CoordT(0)
  y2 = CoordT(0)

  var
    first = true
    x, y: float64

  for i in 0.. <num:
    vs.rewind(gi[start + i])
    var cmd = vs.vertex(x, y)
    while not isStop(cmd):
      if isVertex(cmd):
        if first:
          x1 = CoordT(x)
          y1 = CoordT(y)
          x2 = CoordT(x)
          y2 = CoordT(y)
          first = false
        else:
          if  CoordT(x) < x1: x1 = CoordT(x)
          if  CoordT(y) < y1: y1 = CoordT(y)
          if  CoordT(x) > x2: x2 = CoordT(x)
          if  CoordT(y) > y2: y2 = CoordT(y)
      cmd = vs.vertex(x, y)
  result = x1 <= x2 and y1 <= y2


proc boundingRectSingle*[VertexSource, CoordT](vs: var VertexSource, pathId: int;
  x1, y1, x2, y2: var CoordT): bool =

  var
    x, y: float64
    first = true

  x1 = CoordT(1)
  y1 = CoordT(1)
  x2 = CoordT(0)
  y2 = CoordT(0)

  vs.rewind(pathId)
  var cmd = vs.vertex(x, y)
  while not isStop(cmd):
    if isVertex(cmd):
      if first:
        x1 = CoordT(x)
        y1 = CoordT(y)
        x2 = CoordT(x)
        y2 = CoordT(y)
        first = false
      else:
        if CoordT(x) < x1: x1 = CoordT(x)
        if CoordT(y) < y1: y1 = CoordT(y)
        if CoordT(x) > x2: x2 = CoordT(x)
        if CoordT(y) > y2: y2 = CoordT(y)
    cmd = vs.vertex(x, y)

  result = x1 <= x2 and y1 <= y2
  
proc boundingRectD*[VertexSource](vs: var VertexSource, pathId: int = 0): RectD {.inline.} =
  discard boundingRectSingle(vs, pathId, result.x1, result.y1, result.x2, result.y2)
  result
