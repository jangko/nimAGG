import agg_basics, polyBool/polyBool, agg_path_storage

type
  PolyBoolOp* = enum
    polyBoolUnion
    polyBoolIntersect
    polyBoolXor
    polyBoolAMinusB
    polyBoolBMinusA

  ConvPolyBool*[VSA, VSB] = object
    mPolyBool: PolyBool
    mSrcA: ptr VSA
    mSrcB: ptr VSB
    mOp: PolyBoolOp
    mResult: PathStorage

proc initConvPolyBool*[VSA,VSB](a: var VSA, b: var VSB, op: PolyBoolOp = polyBoolUnion): ConvPolyBool[VSA,VSB] =
  result.mSrcA = a.addr
  result.mSrcB = b.addr
  result.mOp = op
  result.mPolyBool = initPolyBool()
  result.mResult   = initPathStorage()

proc attachPolyA*[VSA,VSB](self: var ConvPolyBool[VSA,VSB], src: var VSA) =
  self.mSrcA = src.addr

proc attachPolyB*[VSA,VSB](self: var ConvPolyBool[VSA,VSB], src: var VSB) =
  self.mSrcB = src.addr

proc operation*[VSA,VSB](self: var ConvPolyBool[VSA,VSB], op: PolyBoolOp) =
  self.mOp = op

proc polygonToPath(path: var PathStorage, poly: Polygon) =
  path.removeAll()
  for r in poly.regions:
    for i in 0.. <r.len:
      if i == 0:
        path.moveTo(r[i].x, r[i].y)
      else:
        path.lineTo(r[i].x, r[i].y)
    path.closePolygon()

proc sourceToPolygon[VertexSource](vs: var VertexSource): Polygon =
  result = initPolygon()
  result.addRegion()

  var
    x, y: float64
    cmd = vs.vertex(x, y)
    start_x = 0.0
    start_y = 0.0
    starting_first_line = true

  while not isStop(cmd):
    if isVertex(cmd):
      if isMoveTo(cmd):
        if not starting_first_line:
          result.addRegion()
        start_x = x
        start_y = y
      result.addVertex(x, y)
      starting_first_line = false
    elif isEndPoly(cmd):
      if not starting_first_line and isClosed(cmd):
        result.addVertex(start_x, start_y)
    cmd = vs.vertex(x, y)

proc sourceToSegments[VertexSource](pb: var PolyBool, vs: var VertexSource): Segments =
  var
    x, y: float64
    cmd = vs.vertex(x, y)
    start_x = 0.0
    start_y = 0.0
    starting_first_line = true

  pb.startPolygon()
  while not isStop(cmd):
    if isVertex(cmd):
      if isMoveTo(cmd):
        if not starting_first_line:
          pb.startRegion()
        start_x = x
        start_y = y
      pb.addVertex(x, y)
      starting_first_line = false
    elif isEndPoly(cmd):
      if not starting_first_line and isClosed(cmd):
        pb.addVertex(start_x, start_y)
      pb.endRegion()
    cmd = vs.vertex(x, y)
  pb.endPolygon()

# Vertex Source Interface
proc rewind*[VSA,VSB](self: var ConvPolyBool[VSA,VSB], pathId: int) =
  mixin rewind
  self.mSrcA[].rewind(pathId)
  self.mSrcB[].rewind(pathId)
  self.mResult.removeAll()

  var
    polyA = sourceToPolygon(self.mSrcA[])
    polyB = sourceToPolygon(self.mSrcB[])
    polyRes: Polygon

  case self.mOp
  of polyBoolUnion:
    polyRes = self.mPolyBool.clipUnion(polyA, polyB)
  of polyBoolIntersect:
    polyRes = self.mPolyBool.clipIntersect(polyA, polyB)
  of polyBoolXor:
    polyRes = self.mPolyBool.clipXor(polyA, polyB)
  of polyBoolAMinusB:
    polyRes = self.mPolyBool.clipDifference(polyA, polyB)
  of polyBoolBMinusA:
    polyRes = self.mPolyBool.clipDifference(polyB, polyA)

  self.mResult.polygonToPath(polyRes)

  #[var
    polyA = self.mPolyBool.sourceToSegments(self.mSrcA[])
    polyB = self.mPolyBool.sourceToSegments(self.mSrcB[])
    combined: Combined
    polyRes: Segments

  if self.mOp == polyBoolBMinusA:
    combined = self.mPolyBool.combine(polyB, polyA)
  else:
    combined = self.mPolyBool.combine(polyA, polyB)

  case self.mOp
  of polyBoolUnion:
    polyRes = self.mPolyBool.selectUnion(combined)
  of polyBoolIntersect:
    polyRes = self.mPolyBool.selectIntersect(combined)
  of polyBoolXor:
    polyRes = self.mPolyBool.selectXor(combined)
  of polyBoolAMinusB:
    polyRes = self.mPolyBool.selectDifference(combined)
  of polyBoolBMinusA:
    polyRes = self.mPolyBool.selectDifference(combined)

  self.mResult.polygonToPath(self.mPolyBool.polygon(polyRes))]#

proc vertex*[VSA,VSB](self: var ConvPolyBool[VSA,VSB], x, y: var float64): uint =
  self.mResult.vertex(x, y)