import agg_basics

proc clippingFlags*[T](x, y: T, clipBox: RectBase[T]): uint {.inline.} =
  result =         (x > clipBox.x2).uint or
           ((y > clipBox.y2).uint shl 1) or
           ((x < clipBox.x1).uint shl 2) or
           ((y < clipBox.y1).uint shl 3)

proc clippingFlagsX*[T](x: T, clipBox: RectBase[T]): uint {.inline.} =
  result = (x > clipBox.x2).uint or ((x < clipBox.x1).uint shl 2)

proc clippingFlagsY*[T](y: T, clipBox: RectBase[T]): uint {.inline.} =
  result = ((y > clipBox.y2).uint shl 1) or ((y < clipBox.y1).uint shl 3)
