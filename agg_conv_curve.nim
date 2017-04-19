import agg_basics, agg_curves

# Curve converter class. Any path storage can have Bezier curves defined
# by their control points. There're two types of curves supported: curve3
# and curve4. Curve3 is a conic Bezier curve with 2 endpoints and 1 control
# point. Curve4 has 2 control points (4 points in total) and can be used
# to interpolate more complicated curves. Curve4, unlike curve3 can be used
# to approximate arcs, both circular and elliptical. Curves are approximated
# with straight lines and one of the approaches is just to store the whole
# sequence of vertices that approximate our curve. It takes additional
# memory, and at the same time the consecutive vertices can be calculated
# on demand.
#
# Initially, path storages are not suppose to keep all the vertices of the
# curves (although, nothing prevents us from doing so). Instead, path_storage
# keeps only vertices, needed to calculate a curve on demand. Those vertices
# are marked with special commands. So, if the path_storage contains curves
# (which are not real curves yet), and we render this storage directly,
# all we will see is only 2 or 3 straight line segments (for curve3 and
# curve4 respectively). If we need to see real curves drawn we need to
# include this class into the conversion pipeline.
#
# Class conv_curve recognizes commands path_cmd_curve3 and path_cmd_curve4
# and converts these vertices into a move_to/line_to sequence.

type
   ConvCurve1*[VertexSource, C3, C4] = object of RootObj
     mSource: ptr VertexSource
     mLastX, mLastY: float64
     mCurve3: C3
     mCurve4: C4

   ConvCurve*[VS] = ConvCurve1[VS, Curve3, Curve4]

proc init*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], source: var VS) =
  self.mSource = source.addr
  self.mLastX = 0.0
  self.mLastY = 0.0
  self.mCurve3 = construct(C3)
  self.mCurve4 = construct(C4)

proc initConvCurve1*[VS, C3, C4](source: var VS): ConvCurve1[VS, C3, C4] =
  init[VS, C3, C4](result, source)

proc initConvCurve*[VS](source: var VS): ConvCurve[VS] =
  result = initConvCurve1[VS, Curve3, Curve4](source)

proc attach*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], source: var VS) =
  self.mSource = source.addr

proc approximationMethod*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], v: CurveApproximationMethod) =
  self.mCurve3.approximationMethod(v)
  self.mCurve4.approximationMethod(v)

proc approximationMethod*[VS, C3, C4](self: ConvCurve1[VS, C3, C4], ): CurveApproximationMethod =
  self.mCurve4.approximationMethod()

proc approximationScale*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], s: float64) =
  self.mCurve3.approximationScale(s)
  self.mCurve4.approximationScale(s)

proc approximationScale*[VS, C3, C4](self: ConvCurve1[VS, C3, C4]): float64 =
  self.mCurve4.approximationScale()

proc angleTolerance*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], v: float64) =
  self.mCurve3.angleTolerance(v)
  self.mCurve4.angleTolerance(v)

proc angleTolerance*[VS, C3, C4](self: ConvCurve1[VS, C3, C4]): float64 =
  self.mCurve4.angleTolerance()

proc cuspLimit*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], v: float64) =
  self.mCurve3.cuspLimit(v)
  self.mCurve4.cuspLimit(v)

proc cuspLimit*[VS, C3, C4](self: ConvCurve1[VS, C3, C4]): float64 =
  self.mCurve4.cuspLimit()

proc rewind*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], pathId: int) =
  mixin rewind
  self.mSource[].rewind(pathId)
  self.mLastX = 0.0
  self.mLastY = 0.0
  self.mCurve3.reset()
  self.mCurve4.reset()

proc vertex*[VS, C3, C4](self: var ConvCurve1[VS, C3, C4], x, y: var float64): uint =
  if not isStop(self.mCurve3.vertex(x, y)):
    self.mLastX = x
    self.mLastY = y
    return pathCmdLineTo

  if not isStop(self.mCurve4.vertex(x, y)):
    self.mLastX = x
    self.mLastY = y
    return pathCmdLineTo

  var
    ct2X, ct2Y, endX, endY: float64
    cmd = self.mSource[].vertex(x, y)

  case cmd
  of pathCmdCurve3:
    discard self.mSource[].vertex(endX, endY)
    self.mCurve3.init(self.mLastX, self.mLastY, x, y, endX, endY)
    discard self.mCurve3.vertex(x, y)    # First call returns path_cmd_move_to
    discard self.mCurve3.vertex(x, y)    # This is the first vertex of the curve
    cmd = pathCmdLineTo
  of pathCmdCurve4:
    discard self.mSource[].vertex(ct2X, ct2Y)
    discard self.mSource[].vertex(endX, endY)
    self.mCurve4.init(self.mLastX, self.mLastY, x, y, ct2X, ct2Y, endX, endY)
    discard self.mCurve4.vertex(x, y)    # First call returns path_cmd_move_to
    discard self.mCurve4.vertex(x, y)    # This is the first vertex of the curve
    cmd = pathCmdLineTo
  else:
    discard

  self.mLastX = x
  self.mLastY = y
  return cmd
