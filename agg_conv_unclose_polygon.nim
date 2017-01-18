import agg_basics

type
  ConvUnclosePolygon*[VertexSource] = object
    mSource: ptr VertexSource

proc initConvUnclosePolygon*[VertexSource](vs: var VertexSource): ConvUnclosePolygon[VertexSource] =
  result.mSource = vs.addr

proc attach*[VertexSource](self: var ConvUnclosePolygon[VertexSource], source: var VertexSource) =
  self.mSource = source.addr

proc rewind*[VertexSource](self: var ConvUnclosePolygon[VertexSource], pathId: int) =
  self.mSource[].rewind(pathId)

proc vertex*[VertexSource](self: var ConvUnclosePolygon[VertexSource], x, y: var float64): uint =
  var cmd = self.mSource[].vertex(x, y)
  if isEndPoly(cmd):
    cmd = cmd and (not pathFlagsClose)
  return cmd
