import math, agg_basics

# Coinciding points maximal distance (Epsilon)
const
  vertexDistEpsilon* = 1e-14
  intersectionEpsilon* = 1.0e-30

proc calcDistance*(x1, y1, x2, y2: float64): float64 {.inline.} =
  let dx = x2-x1
  let dy = y2-y1
  sqrt(dx * dx + dy * dy)

proc calcIntersection*(ax, ay, bx, by, cx, cy, dx, dy: float64; x, y: var float64): bool =
  let num = (ay-cy) * (dx-cx) - (ax-cx) * (dy-cy)
  let den = (bx-ax) * (dy-cy) - (by-ay) * (dx-cx)
  if abs(den) < intersectionEpsilon: return false
  let r = num / den
  x = ax + r * (bx-ax)
  y = ay + r * (by-ay)
  result = true

proc crossProduct*(x1, y1, x2, y2, x, y: float64): float64 {.inline.} =
  result = (x - x2) * (y2 - y1) - (y - y2) * (x2 - x1)

proc calcSqDistance*(x1, y1, x2, y2: float64): float64  {.inline.} =
  let dx = x2-x1
  let dy = y2-y1
  result = dx * dx + dy * dy

proc calcPolygonArea*[Storage](st: var Storage): float64 =
  var
    sum = 0.0
    x  = st[0].x
    y  = st[0].y
    xs = x
    ys = y

  for i in 1.. <st.size:
    let v = st[i].addr
    sum += x * v.y - y * v.x
    x = v.x
    y = v.y
  result = (sum + x * ys - y * xs) * 0.5

proc calcOrthogonal(thickness, x1, y1, x2, y2: float64, x, y: var float64) =
  var
    dx = x2 - x1
    dy = y2 - y1
    d = sqrt(dx*dx + dy*dy)

  x =  thickness * dy / d
  y = -thickness * dx / d

proc dilateTriangle*(x1, y1, x2, y2, x3, y3: float64, x, y: ptr float64, d: float64) {.inline.} =
  var
    dx1=0.0
    dy1=0.0
    dx2=0.0
    dy2=0.0
    dx3=0.0
    dy3=0.0
    loc = crossProduct(x1, y1, x2, y2, x3, y3)
    d = d
    x = x
    y = y

  if abs(loc) > intersectionEpsilon:
    if crossProduct(x1, y1, x2, y2, x3, y3) > 0.0:
      d = -d
    calcOrthogonal(d, x1, y1, x2, y2, dx1, dy1)
    calcOrthogonal(d, x2, y2, x3, y3, dx2, dy2)
    calcOrthogonal(d, x3, y3, x1, y1, dx3, dy3)

  x[] = x1 + dx1; y[] = y1 + dy1; inc x; inc y
  x[] = x2 + dx1; y[] = y2 + dy1; inc x; inc y
  x[] = x2 + dx2; y[] = y2 + dy2; inc x; inc y
  x[] = x3 + dx2; y[] = y3 + dy2; inc x; inc y
  x[] = x3 + dx3; y[] = y3 + dy3; inc x; inc y
  x[] = x1 + dx3; y[] = y1 + dy3; inc x; inc y

