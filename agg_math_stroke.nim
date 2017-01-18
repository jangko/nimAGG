import agg_basics, math, agg_array, agg_vertex_sequence, agg_math, strutils

type
  LineCap* = enum
    buttCap
    squareCap
    roundCap

  LineJoin* = enum
    miterJoin         = 0,
    miterJoinRevert   = 1,
    roundJoin         = 2,
    bevelJoin         = 3,
    miterJoinRound    = 4

  InnerJoin* = enum
    innerBevel
    innerMiter
    innerJag
    innerRound

  MathStroke* = object
    mWidth: float64
    mWidthAbs: float64
    mWidthEps: float64
    mWidthSign: float64
    mMiterLimit: float64
    mInnerMiterLimit: float64
    mApproxScale: float64
    mLineCap: LineCap
    mLineJoin: LineJoin
    mInnerJoin: InnerJoin

proc initMathStroke*(): MathStroke =
  result.mWidth = 0.5
  result.mWidthAbs = 0.5
  result.mWidthEps = 0.5/1024.0
  result.mWidthSign = 1
  result.mMiterLimit = 4.0
  result.mInnerMiterLimit = 1.01
  result.mApproxScale = 1.0
  result.mLineCap = buttCap
  result.mLineJoin = miterJoin
  result.mInnerJoin = innerMiter

proc lineCap*(self: var MathStroke, lc: LineCap) = self.mLineCap = lc
proc lineJoin*(self: var MathStroke, lj: LineJoin) = self.mLineJoin = lj
proc innerJoin*(self: var MathStroke, ij: InnerJoin) = self.mInnerJoin = ij

proc lineCap*(self: MathStroke): LineCap = self.mLineCap
proc lineJoin*(self: MathStroke): LineJoin = self.mLineJoin
proc innerJoin*(self: MathStroke): InnerJoin = self.mInnerJoin

proc width*(self: var MathStroke, w: float64) =
  self.mWidth = w * 0.5;
  if self.mWidth < 0:
    self.mWidthAbs  = -self.mWidth
    self.mWidthSign = -1
  else:
    self.mWidthAbs  = self.mWidth
    self.mWidthSign = 1

  self.mWidthEps = self.mWidth / 1024.0

proc miterLimit*(self: var MathStroke, ml: float64) = self.mMiterLimit = ml
proc miterLimitTheta*(self: var MathStroke, t: float64) = self.mMiterLimit = 1.0 / sin(t * 0.5)
proc innerMiterLimit*(self: var MathStroke, ml: float64) = self.mInnerMiterLimit = ml
proc approximationScale*(self: var MathStroke, asc: float64) = self.mApproxScale = asc

proc width*(self: MathStroke): float64 = self.mWidth * 2.0
proc miterLimit*(self: MathStroke): float64 = self.mMiterLimit
proc innerMiterLimit*(self: MathStroke): float64 = self.mInnerMiterLimit
proc approximationScale*(self: MathStroke): float64 = self.mApproxScale

proc addVertex[VertexConsumer](vc: var VertexConsumer, x, y: float64) {.inline.} =
  type CoordType = getValueType(VertexConsumer)
  vc.add(CoordType(x: x, y: y))

proc calcArc[VertexConsumer](self: var MathStroke, vc: var VertexConsumer, x, y, dx1, dy1, dx2, dy2: float64) =
  var
    a1 = arctan2(dy1 * self.mWidthSign, dx1 * self.mWidthSign)
    a2 = arctan2(dy2 * self.mWidthSign, dx2 * self.mWidthSign)
    da = a1 - a2
    n: int

  da = arccos(self.mWidthAbs / (self.mWidthAbs + 0.125 / self.mApproxScale)) * 2

  vc.addVertex(x + dx1, y + dy1)
  if self.mWidthSign > 0:
    if a1 > a2: a2 += 2 * pi
    n = int((a2 - a1) / da)
    da = (a2 - a1) / (n + 1).float64
    a1 += da
    for i in 0.. <n:
      vc.addVertex(x + cos(a1) * self.mWidth, y + sin(a1) * self.mWidth)
      a1 += da
  else:
    if a1 < a2: a2 -= 2 * pi
    n = int((a1 - a2) / da)
    da = (a1 - a2) / (n + 1).float64
    a1 -= da
    for i in 0.. <n:
      vc.addVertex(x + cos(a1) * self.mWidth, y + sin(a1) * self.mWidth)
      a1 -= da

  vc.addVertex(x + dx2, y + dy2)

proc calcMiter[VertexConsumer](self: var MathStroke, vc: var VertexConsumer,
  v0, v1, v2: VertexDist; dx1,dy1, dx2,dy2: float64; lj: LineJoin; mLimit, dBevel: float64) =

  var
    xi  = v1.x
    yi  = v1.y
    di  = 1.0'f64
    lim = self.mWidthAbs * mLimit
    miterLimitExceeded = true # Assume the worst
    intersectionFailed = true # Assume the worst

  if calcIntersection(v0.x + dx1, v0.y - dy1,
                      v1.x + dx1, v1.y - dy1,
                      v1.x + dx2, v1.y - dy2,
                      v2.x + dx2, v2.y - dy2,
                      xi, yi):

    # Calculation of the intersection succeeded
    di = calcDistance(v1.x, v1.y, xi, yi)
    if di <= lim:
      # Inside the miter limit
      vc.addVertex(xi, yi)
      miterLimitExceeded = false
    intersectionFailed = false
  else:
    # Calculation of the intersection failed, most probably
    # the three points lie one straight line.
    # First check if v0 and v2 lie on the opposite sides of vector:
    # (v1.x, v1.y) -> (v1.x+dx1, v1.y-dy1), that is, the perpendicular
    # to the line determined by vertices v0 and v1.
    # This condition determines whether the next line segments continues
    # the previous one or goes back.

    let x2 = v1.x + dx1
    let y2 = v1.y - dy1
    if (crossProduct(v0.x, v0.y, v1.x, v1.y, x2, y2) < 0.0) ==
      (crossProduct(v1.x, v1.y, v2.x, v2.y, x2, y2) < 0.0):
       # This of means that the next segment continues
       # the previous one (straight line)
       vc.addVertex(v1.x + dx1, v1.y - dy1)
       miterLimitExceeded = false

  if miterLimitExceeded:
    # Miter limit exceeded

    case lj
    of miterJoinRevert:
      # For the compatibility with SVG, PDF, etc,
      # we use a simple bevel join instead of
      # "smart" bevel
      vc.addVertex(v1.x + dx1, v1.y - dy1)
      vc.addVertex(v1.x + dx2, v1.y - dy2)

    of miterJoinRound:
      self.calcArc(vc, v1.x, v1.y, dx1, -dy1, dx2, -dy2)

    else:
      # If no miter-revert, calculate new dx1, dy1, dx2, dy2
      if intersectionFailed:
        var mLimit = mLimit * self.mWidthSign
        vc.addVertex(v1.x + dx1 + dy1 * mLimit, v1.y - dy1 + dx1 * mLimit)
        vc.addVertex(v1.x + dx2 - dy2 * mLimit, v1.y - dy2 - dx2 * mLimit)
      else:
        var
          x1 = v1.x + dx1
          y1 = v1.y - dy1
          x2 = v1.x + dx2
          y2 = v1.y - dy2
        di = (lim - dbevel) / (di - dbevel)
        vc.addVertex(x1 + (xi - x1) * di, y1 + (yi - y1) * di)
        vc.addVertex(x2 + (xi - x2) * di, y2 + (yi - y2) * di)

proc calcCap*[VertexConsumer](self: var MathStroke, vc: var VertexConsumer, v0, v1: VertexDist, len: float64) =
  vc.removeAll()

  var
    dx1 = (v1.y - v0.y) / len
    dy1 = (v1.x - v0.x) / len
    dx2 = 0.0
    dy2 = 0.0

  dx1 = dx1 * self.mWidth
  dy1 = dy1 * self.mWidth

  if self.mLineCap != roundCap:
    if self.mLineCap == squareCap:
      dx2 = dy1 * self.mWidthSign
      dy2 = dx1 * self.mWidthSign

    vc.addVertex(v0.x - dx1 - dx2, v0.y + dy1 - dy2)
    vc.addVertex(v0.x + dx1 - dx2, v0.y - dy1 - dy2)
  else:
    var
      da = arccos(self.mWidthAbs / (self.mWidthAbs + 0.125 / self.mApproxScale)) * 2
      a1: float64
      n = int(pi / da)

    da = pi / (n + 1).float64
    vc.addVertex(v0.x - dx1, v0.y + dy1)
    if self.mWidthSign > 0:
      a1 = arctan2(dy1, -dx1)
      a1 += da
      for i in 0.. <n:
        vc.addVertex(v0.x + cos(a1) * self.mWidth, v0.y + sin(a1) * self.mWidth)
        a1 += da
    else:
      a1 = arctan2(-dy1, dx1)
      a1 -= da
      for i in 0.. <n:
        vc.addVertex(v0.x + cos(a1) * self.mWidth, v0.y + sin(a1) * self.mWidth)
        a1 -= da
        
    vc.addVertex(v0.x + dx1, v0.y - dy1)

proc calcJoin*[VertexConsumer](self: var MathStroke, vc: var VertexConsumer,
  v0, v1, v2: VertexDist; len1, len2: float64) =

  var
    dx1 = self.mWidth * (v1.y - v0.y) / len1
    dy1 = self.mWidth * (v1.x - v0.x) / len1
    dx2 = self.mWidth * (v2.y - v1.y) / len2
    dy2 = self.mWidth * (v2.x - v1.x) / len2

  vc.removeAll()

  var cp = crossProduct(v0.x, v0.y, v1.x, v1.y, v2.x, v2.y)
  if (cp != 0) and ((cp > 0) == (self.mWidth > 0)):
    # Inner join

    var limit = (if len1 < len2: len1 else: len2) / self.mWidthAbs
    if limit < self.mInnerMiterLimit:
      limit = self.mInnerMiterLimit

    case self.mInnerJoin
    of inner_miter:
      self.calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2,
        miterJoinRevert, limit, 0)
    of innerJag, innerRound:
      cp = (dx1-dx2) * (dx1-dx2) + (dy1-dy2) * (dy1-dy2)
      if (cp < len1 * len1) and (cp < len2 * len2):
        self.calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2,
          miterJoinRevert, limit, 0)
      else:
        if self.mInnerJoin == innerJag:
          vc.addVertex(v1.x + dx1, v1.y - dy1)
          vc.addVertex(v1.x,       v1.y      )
          vc.addVertex(v1.x + dx2, v1.y - dy2)
        else:
          vc.addVertex(v1.x + dx1, v1.y - dy1)
          vc.addVertex(v1.x,       v1.y      )
          self.calcArc(vc, v1.x, v1.y, dx2, -dy2, dx1, -dy1)
          vc.addVertex(v1.x,       v1.y      )
          vc.addVertex(v1.x + dx2, v1.y - dy2)
  
    else: # inner_bevel
      vc.addVertex(v1.x + dx1, v1.y - dy1)
      vc.addVertex(v1.x + dx2, v1.y - dy2)
  else:
    # Outer join
    # Calculate the distance between v1 and
    # the central point of the bevel line segment
    var
      dx = (dx1 + dx2) / 2
      dy = (dy1 + dy2) / 2
      dbevel = sqrt(dx * dx + dy * dy)

    if (self.mLineJoin == roundJoin) or (self.mLineJoin == bevelJoin):
      # This is an optimization that reduces the number of points
      # in ofs of almost collinear segments. If there's no
      # visible difference between bevel and miter joins we'd rather
      # use miter join because it adds only one point instead of two.
      #
      # Here we calculate the middle point between the bevel points
      # and then, the distance between v1 and this middle point.
      # At outer joins this distance always less than stroke width,
      # because it's actually the height of an isosceles triangle of
      # v1 and its two bevel points. If the difference between this
      # width and this value is small (no visible bevel) we can
      # add just one point.
      #
      # The constant in the expression makes the result approximately
      # the same as in round joins and caps. You can safely comment
      # out this entire "if".

      if (self.mApproxScale * (self.mWidthAbs - dbevel)) < self.mWidthEps:
        if calcIntersection(v0.x + dx1, v0.y - dy1,
                            v1.x + dx1, v1.y - dy1,
                            v1.x + dx2, v1.y - dy2,
                            v2.x + dx2, v2.y - dy2,
                            dx, dy):
          vc.addVertex(dx, dy)
        else:
          vc.addVertex(v1.x + dx1, v1.y - dy1)
        return

    case self.mLineJoin:
    of miter_join, miter_join_revert, miter_join_round:
      self.calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2,
                  self.mLineJoin, self.mMiterLimit, dbevel)
    of roundJoin:
      self.calcArc(vc, v1.x, v1.y, dx1, -dy1, dx2, -dy2)
    else: # Bevel join
      vc.addVertex(v1.x + dx1, v1.y - dy1)
      vc.addVertex(v1.x + dx2, v1.y - dy2)
