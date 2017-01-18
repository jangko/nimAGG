import math

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
