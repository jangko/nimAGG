import agg_basics, math, agg_trans_affine

const 
  bezierArcAngleEpsilon = 0.01
  
type
  BezierArc = object
    mVertex: int
    mNumVertices: int
    mVertices: array[26, float64]
    cmd: uint

  BezierArcSvg = object
    arc: BezierArc
    radiiOK: bool

proc arcToBezier(cx, cy, rx, ry, startAngle, sweepAngle: float64, curve: ptr float64) =
  let
    x0 = cos(sweepAngle / 2.0)
    y0 = sin(sweepAngle / 2.0)
    tx = (1.0 - x0) * 4.0 / 3.0
    ty = y0 - tx * x0 / y0
  var
    px: array[4, float64]
    py: array[4, float64]
    
  px[0] =  x0; py[0] = -y0
  px[1] =  x0 + tx; py[1] = -ty
  px[2] =  x0 + tx; py[2] =  ty
  px[3] =  x0; py[3] =  y0
  
  let sn = sin(startAngle + sweepAngle / 2.0)
  let cs = cos(startAngle + sweepAngle / 2.0)
    
  for i in 0..3:
    curve[i * 2]     = cx + rx * (px[i] * cs - py[i] * sn)
    curve[i * 2 + 1] = cy + ry * (px[i] * sn + py[i] * cs)

proc init*(self: var BezierArc, x, y, rx, ry, startAngle, sweepAngle: float64) =
  var 
    startAngle = startAngle mod (2.0 * pi)
    sweepAngle = sweepAngle
  
  if sweepAngle >=  2.0 * pi: sweepAngle =  2.0 * pi
  if sweepAngle <= -2.0 * pi: sweepAngle = -2.0 * pi
  
  if abs(sweepAngle) < 1e-10:
    self.mNumVertices = 4
    self.cmd = pathCmdLineTo
    self.mVertices[0] = x + rx * cos(startAngle)
    self.mVertices[1] = y + ry * sin(startAngle)
    self.mVertices[2] = x + rx * cos(startAngle + sweepAngle)
    self.mVertices[3] = y + ry * sin(startAngle + sweepAngle)
    return
  
  var
    totalSweep = 0.0
    localSweep = 0.0
    prevSweep: float64
    done = false
    
  self.mNumVertices = 2
  self.cmd = pathCmdCurve4
  
  doWhile((not done) and self.mNumVertices < 26):
    if sweepAngle < 0.0:
      prevSweep  = totalSweep
      localSweep = -pi * 0.5
      totalSweep -= pi * 0.5
      if totalSweep <= sweepAngle + bezierArcAngleEpsilon:
        localSweep = sweepAngle - prevSweep
        done = true
    else:
      prevSweep  = totalSweep
      localSweep =  pi * 0.5
      totalSweep += pi * 0.5
      if totalSweep >= sweepAngle - bezierArcAngleEpsilon:
        localSweep = sweepAngle - prevSweep
        done = true
  
    arcToBezier(x, y, rx, ry, startAngle, localSweep, self.mVertices[self.mNumVertices - 2].addr)
  
    self.mNumVertices += 6
    startAngle += localSweep
    
proc initBezierArc*(x, y, rx, ry, startAngle, sweepAngle: float64): BezierArc =
  result.init(x, y, rx, ry, startAngle, sweepAngle)

proc rewind*(self: var BezierArc, pathId: int) =
  self.mVertex = 0

proc vertex*(self: var BezierArc, x, y: var float64): uint =
  if self.mVertex >= self.mNumVertices: return pathCmdStop
  x = self.mVertices[self.mVertex]
  y = self.mVertices[self.mVertex + 1]
  self.mVertex += 2
  return if self.mVertex == 2: pathCmdMoveTo else: self.cmd

# Supplemantary functions. num_vertices() actually returns doubled 
# number of vertices. That is, for 1 vertex it returns 2.
proc numVertices*(self: BezierArc): int = self.mNumVertices
proc vertices*(self: var BezierArc): ptr float64 = self.mVertices[0].addr

proc init*(self: var BezierArcSvg, x0, y0, rx, ry, angle: float64, largeArcFlag, sweepFlag: bool, x2, y2: float64) =
  self.radiiOK = true
  
  var 
    rx = rx
    ry = ry
    
  if rx < 0.0: rx = -rx
  if ry < 0.0: ry = -rx
  
  # Calculate the middle point between 
  # the current and the final points
  var
    dx2 = (x0 - x2) / 2.0
    dy2 = (y0 - y2) / 2.0
    cos_a = cos(angle)
    sin_a = sin(angle)
  
    # Calculate (x1, y1)
    x1 =  cos_a * dx2 + sin_a * dy2
    y1 = -sin_a * dx2 + cos_a * dy2
  
    # Ensure radii are large enough
    prx = rx * rx
    pry = ry * ry
    px1 = x1 * x1
    py1 = y1 * y1
  
  # Check that radii are large enough
  var radii_check = px1/prx + py1/pry
  if radii_check > 1.0:
    rx = sqrt(radii_check) * rx
    ry = sqrt(radii_check) * ry
    prx = rx * rx
    pry = ry * ry
    if radii_check > 10.0: self.radiiOK = false
  
  # Calculate (cx1, cy1)
  var
    sign = if largeArcFlag == sweepFlag: -1.0 else: 1.0
    sq   = (prx*pry - prx*py1 - pry*px1) / (prx*py1 + pry*px1)
    coef = sign * sqrt(if sq < 0.0: 0.0 else: sq)
    cx1  = coef *  ((rx * y1) / ry)
    cy1  = coef * -((ry * x1) / rx)
    
    # Calculate (cx, cy) from (cx1, cy1)
    sx2 = (x0 + x2) / 2.0
    sy2 = (y0 + y2) / 2.0
    cx = sx2 + (cos_a * cx1 - sin_a * cy1)
    cy = sy2 + (sin_a * cx1 + cos_a * cy1)
  
    # Calculate the start_angle (angle1) and the sweep_angle (dangle)
  
    ux =  (x1 - cx1) / rx
    uy =  (y1 - cy1) / ry
    vx = (-x1 - cx1) / rx
    vy = (-y1 - cy1) / ry
    p, n: float64
  
  # Calculate the angle start
  n = sqrt(ux*ux + uy*uy)
  p = ux # (1 * ux) + (0 * uy)
  sign = if uy < 0: -1.0 else: 1.0
  var v = p / n
  if v < -1.0: v = -1.0
  if v >  1.0: v =  1.0
  var startAngle = sign * arccos(v)
  
  # Calculate the sweep angle
  n = sqrt((ux*ux + uy*uy) * (vx*vx + vy*vy))
  p = ux * vx + uy * vy
  sign = if ux * vy - uy * vx < 0: -1.0 else: 1.0
  v = p / n
  if v < -1.0: v = -1.0
  if v >  1.0: v =  1.0
  var sweepAngle = sign * arccos(v)
  if not sweepFlag and sweepAngle > 0:
    sweepAngle -= pi * 2.0
  elif sweepFlag and sweepAngle < 0:
    sweepAngle += pi * 2.0
  
  # We can now build and transform the resulting arc
  self.arc.init(0.0, 0.0, rx, ry, startAngle, sweepAngle)
  
  var mtx = transAffineRotation(angle)
  mtx *= transAffineTranslation(cx, cy)
  
  for i in countup(2, self.arc.numVertices()-2, 2):
    mtx.transform((self.arc.vertices() + i)[], (self.arc.vertices() + i + 1)[])
  
  # We must make sure that the starting and ending points
  # exactly coincide with the initial (x0,y0) and (x2,y2)
  self.arc.vertices()[0] = x0
  self.arc.vertices()[1] = y0
  if self.arc.numVertices() > 2:
    self.arc.vertices()[self.arc.numVertices() - 2] = x2
    self.arc.vertices()[self.arc.numVertices() - 1] = y2
 
proc initBezierArcSvg*(x1, y1, rx, ry, angle: float64, largeArcFlag, sweepFlag: bool, x2, y2: float64): BezierArcSvg =
  result.init(x1, y1, rx, ry, angle, largeArcFlag, sweepFlag, x2, y2)

proc isRadiiOK*(self: BezierArcSvg): bool =
  result = self.radiiOK
  
proc rewind*(self: var BezierArcSvg, pathId: int) =
  self.arc.rewind(0)

proc vertex*(self: var BezierArcSvg; x, y: var float64): uint =
  result = self.arc.vertex(x, y)

# Supplemantary functions. num_vertices() actually returns doubled 
# number of vertices. That is, for 1 vertex it returns 2.
 
proc numVertices*(self: var BezierArcSvg): int = 
  self.arc.numVertices()
  
proc vertices*(self: var BezierArcSvg): ptr float64 = 
  self.arc.vertices()
