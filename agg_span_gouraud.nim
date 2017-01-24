import agg_basics, agg_math

type
  CoordType[ColorT] = object
    x*, y*: float64
    color*: ColorT

  SpanGouraud*[ColorT] = object of RootObj
    mCoord: array[3, CoordType[ColorT]]
    mX, mY: array[8, float64]
    mCmd: array[8, uint]
    mVertex: int

proc init*[ColorT](self: var SpanGouraud[ColorT]) =
  self.mVertex(0)
  self.mCmd[0] = pathCmdStop

proc initSpanGouraud*[ColorT](): SpanGouraud[ColorT] =
  result.init()

proc colors*[ColorT](self: var SpanGouraud[ColorT], c1, c2, c3: ColorT)
proc triangle*[ColorT](self: var SpanGouraud[ColorT], x1, y1, x2, y2, x3, y3, d: float64)

proc init*[ColorT](self: var SpanGouraud[ColorT], c1, c2, c3: ColorT; x1, y1, x2, y2, x3, y3, d: float64) =
  self.mVertex = 0
  self.colors(c1, c2, c3)
  self.triangle(x1, y1, x2, y2, x3, y3, d)

proc initSpanGouraud*[ColorT](c1, c2, c3: ColorT; x1, y1, x2, y2, x3, y3, d: float64): SpanGouraud[ColorT] =
  result.init(c1, c2, c3, x1, y1, x2, y2, x3, y3, d)

proc colors[ColorT](self: var SpanGouraud[ColorT], c1, c2, c3: ColorT) =
  self.mCoord[0].color = c1
  self.mCoord[1].color = c2
  self.mCoord[2].color = c3

#--------------------------------------------------------------------
# Sets the triangle and dilates it if needed.
# The trick here is to calculate beveled joins in the vertices of the
# triangle and render it as a 6-vertex polygon.
# It's necessary to achieve numerical stability.
# However, the coordinates to interpolate colors are calculated
# as miter joins (calcIntersection).
proc triangle[ColorT](self: var SpanGouraud[ColorT], x1, y1, x2, y2, x3, y3, d: float64) =
  self.mCoord[0].x = x1; self.mX[0] = x1
  self.mCoord[0].y = y1; self.mY[0] = y1
  self.mCoord[1].x = x2; self.mX[1] = x2
  self.mCoord[1].y = y2; self.mY[1] = y2
  self.mCoord[2].x = x3; self.mX[2] = x3
  self.mCoord[2].y = y3; self.mY[2] = y3
  self.mCmd[0] = pathCmdMoveTo
  self.mCmd[1] = pathCmdLineTo
  self.mCmd[2] = pathCmdLineTo
  self.mCmd[3] = pathCmdStop

  if d != 0.0:
    dilateTriangle(self.mCoord[0].x, self.mCoord[0].y,
                   self.mCoord[1].x, self.mCoord[1].y,
                   self.mCoord[2].x, self.mCoord[2].y,
                   self.mX[0].addr, self.mY[0].addr, d)

    discard calcIntersection(self.mX[4], self.mY[4], self.mX[5], self.mY[5],
                     self.mX[0], self.mY[0], self.mX[1], self.mY[1],
                     self.mCoord[0].x, self.mCoord[0].y)

    discard calcIntersection(self.mX[0], self.mY[0], self.mX[1], self.mY[1],
                     self.mX[2], self.mY[2], self.mX[3], self.mY[3],
                     self.mCoord[1].x, self.mCoord[1].y)

    discard calcIntersection(self.mX[2], self.mY[2], self.mX[3], self.mY[3],
                     self.mX[4], self.mY[4], self.mX[5], self.mY[5],
                     self.mCoord[2].x, self.mCoord[2].y)

    self.mCmd[3] = pathCmdLineTo
    self.mCmd[4] = pathCmdLineTo
    self.mCmd[5] = pathCmdLineTo
    self.mCmd[6] = pathCmdStop

# Vertex Source Interface to feed the coordinates to the rasterizer
proc rewind*[ColorT](self: var SpanGouraud[ColorT], pathId: int) =
  self.mVertex = 0

proc vertex*[ColorT](self: var SpanGouraud[ColorT], x, y: var float64): uint =
  x = self.mX[self.mVertex]
  y = self.mY[self.mVertex]
  result = self.mCmd[self.mVertex]
  inc self.mVertex

proc arrangeVertices*[ColorT](self: var SpanGouraud[ColorT]): array[3, CoordType[ColorT]] =
  result[0] = self.mCoord[0]
  result[1] = self.mCoord[1]
  result[2] = self.mCoord[2]

  if self.mCoord[0].y > self.mCoord[2].y:
    result[0] = self.mCoord[2]
    result[2] = self.mCoord[0]

  if result[0].y > result[1].y:
    swap(result[1], result[0])

  if result[1].y > result[2].y:
    swap(result[2], result[1])