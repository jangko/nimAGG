import agg_basics

const
  clippingFlagsX1Clipped = 4
  clippingFlagsX2Clipped = 1
  clippingFlagsY1Clipped = 8
  clippingFlagsY2Clipped = 2
  clippingFlagsXClipped = clippingFlagsX1Clipped or clippingFlagsX2Clipped
  clippingFlagsYClipped = clippingFlagsY1Clipped or clippingFlagsY2Clipped


proc clippingFlags*[T](x, y: T, clipBox: var RectBase[T]): uint {.inline.} =
  result = (x > clipBox.x2).uint or
           ((y > clipBox.y2).uint shl 1) or
           ((x < clipBox.x1).uint shl 2) or
           ((y < clipBox.y1).uint shl 3)

proc clippingFlagsX*[T](x: T, clipBox: var RectBase[T]): uint {.inline.} =
  result = (x > clipBox.x2).uint or ((x < clipBox.x1).uint shl 2)

proc clippingFlagsY*[T](y: T, clipBox: var RectBase[T]): uint {.inline.} =
  result = ((y > clipBox.y2).uint shl 1) or ((y < clipBox.y1).uint shl 3)

proc clipMovePoint*[T](x1, y1, x2, y2: T, clipBox: var RectBase[T], x, y: var T, flags: uint): bool =
   var bound: T

   if (flags and clippingFlagsXClipped) != 0:
     if x1 == x2:
       return false
     bound = if (flags and clippingFlagsX1Clipped) != 0: clipBox.x1 else: clipBox.x2
     y = T(float64(bound - x1) * float64(y2 - y1) / float64(x2 - x1) + float64(y1))
     x = bound

   var flags = clippingFlagsY(y, clipBox)
   if (flags and clippingFlagsYClipped) != 0:
     if y1 == y2:
       return false
     bound = if (flags and clippingFlagsY1Clipped) != 0: clipBox.y1 else: clipBox.y2
     x = T(float64(bound - y1) * float64(x2 - x1) / float64(y2 - y1) + float64(x1))
     y = bound
   result = true

# Returns: ret >= 4        - Fully clipped
#          (ret & 1) != 0  - First point has been moved
#          (ret & 2) != 0  - Second point has been moved
proc clipLineSegment*[T](x1, y1, x2, y2: var T, clipBox: var RectBase[T]): uint =
  var
    f1 = clippingFlags(x1, y1, clipBox)
    f2 = clippingFlags(x2, y2, clipBox)

  result = 0

  if (f2 or f1) == 0:
    # Fully visible
    return 0

  if (f1 and clippingFlagsXClipped) != 0 and
    (f1 and clippingFlagsXClipped) == (f2 and clippingFlagsXClipped):
    # Fully clipped
    return 4

  if (f1 and clippingFlagsYClipped) != 0 and
    (f1 and clippingFlagsYClipped) == (f2 and clippingFlagsYClipped):
    # Fully clipped
    return 4

  var
    tx1 = x1
    ty1 = y1
    tx2 = x2
    ty2 = y2

  if f1 != 0:
    if not clipMovePoint(tx1, ty1, tx2, ty2, clipBox, x1, y1, f1):
      return 4
    if x1 == x2 and y1 == y2:
      return 4
    result = result or 1

  if f2 != 0:
    if not clipMovePoint(tx1, ty1, tx2, ty2, clipBox, x2, y2, f2):
      return 4
    if x1 == x2 and y1 == y2:
      return 4
    result = result or 2

proc clipLiangBarsky*[T](x1, y1, x2, y2: float64, clipBox: var RectBase[T], x, y: ptr T): int =
  const
    nearzero = 1e-30

  var
    x = x
    y = y
    deltax = x2 - x1
    deltay = y2 - y1
    xin, xout, yin, yout: float64
    tinx, tiny, toutx, touty: float64
    tin1, tin2, tout1: float64
    np = 0

  if deltax == 0.0:
    # bump off of the vertical
    deltax = if x1 > clipBox.x1: -nearzero else: nearzero

  if deltay == 0.0:
    # bump off of the horizontal
    deltay = if y1 > clipBox.y1: -nearzero else: nearzero

  if deltax > 0.0:
    # points to right
    xin  = clipBox.x1
    xout = clipBox.x2
  else:
    xin  = clipBox.x2
    xout = clipBox.x1

  if deltay > 0.0:
    # points up
    yin  = clipBox.y1
    yout = clipBox.y2
  else:
    yin  = clipBox.y2
    yout = clipBox.y1

  tinx = (xin - x1) / deltax
  tiny = (yin - y1) / deltay

  if tinx < tiny:
    # hits x first
    tin1 = tinx
    tin2 = tiny
  else:
    # hits y first
    tin1 = tiny
    tin2 = tinx

  if tin1 <= 1.0:
    if 0.0 < tin1:
      x[] = T(xin); inc x
      y[] = T(yin); inc y
      inc np

    if tin2 <= 1.0:
      toutx = (xout - x1) / deltax
      touty = (yout - y1) / deltay

      tout1 = if toutx < touty: toutx else: touty

      if tin2 > 0.0 or tout1 > 0.0:
        if tin2 <= tout1:
          if tin2 > 0.0:
            if tinx > tiny:
              x[] = T(xin); inc x
              y[] = T(y1 + tinx * deltay); inc y
            else:
              x[] = T(x1 + tiny * deltax); inc x
              y[] = T(yin); inc y
            inc np

          if tout1 < 1.0:
            if toutx < touty:
              x[] = T(xout); inc x
              y[] = T(y1 + toutx * deltay); inc y
            else:
              x[] = T(x1 + touty * deltax); inc x
              y[] = T(yout); inc y
          else:
            x[] = x2; inc x
            y[] = y2; inc y
          inc np
        else:
          if tinx > tiny:
            x[] = T(xin); inc x
            y[] = T(yout); inc y
          else:
            x[] = T(xout); inc x
            y[] = T(yin); inc y
          inc np
  result = np
