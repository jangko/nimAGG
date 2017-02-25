import agg_basics, math

const
  lineSubpixelShift* = 8
  lineSubpixelScale* = 1 shl lineSubpixelShift
  lineSubpixelMask*  = lineSubpixelScale - 1
  lineMaxCoord*      = (1 shl 28) - 1
  lineMaxLength*     = 1 shl (lineSubpixelShift + 10)

  lineMrSubPixelShift* = 4
  lineMrSubPixelScale* = 1 shl lineMrSubPixelShift
  lineMrSubPixelMask*  = lineMrSubPixelScale - 1

proc lineMr*(x: int): int {.inline.} =
  result = sar(x, (lineSubpixelShift - lineMrSubPixelShift))

proc lineHr*(x: int): int {.inline.} =
  result = x shl (lineSubpixelShift - lineMrSubPixelShift)

proc lineDblHr*(x: int): int {.inline.} =
  result = x shl lineSubpixelShift

type
  LineCoord* = object
  LineCoordSat* = object

proc conv*(z: typedesc[LineCoord], x: float64): int {.inline.} =
  result = iround(x * lineSubpixelScale)

proc conv*(z: typedesc[LineCoordSat], x: float64): int {.inline.} =
  result = iround(x * lineSubpixelScale, lineMaxCoord)

type
  LineParameters* = object
    x1*, y1*, x2*, y2*, dx*, dy*, sx*, sy*: int
    vertical*: bool
    inc*, len*, octant*: int

const
  s_orthogonal_quadrant = [ 0'u,0,1,1,3,3,2,2 ]
  s_diagonalQuadrant   = [ 0'u,1,2,1,0,3,2,3 ]

proc initLineParameters*(): LineParameters =
  discard

proc initLineParameters*(x1, y1, x2, y2, len: int): LineParameters =
  result.x1 = x1
  result.y1 = y1
  result.x2 = x2
  result.y2 = y2
  result.dx = abs(x2 - x1)
  result.dy = abs(y2 - y1)
  result.sx = if x2 > x1: 1 else: -1
  result.sy = if y2 > y1: 1 else: -1
  result.vertical = result.dy >= result.dx
  result.inc = if result.vertical: result.sy else: result.sx
  result.len = len
  result.octant = (result.sy and 4) or (result.sx and 2) or int(result.vertical)

proc orthogonalQuadrant*(self: LineParameters): uint = s_orthogonal_quadrant[self.octant]
proc diagonalQuadrant*(self: LineParameters): uint = s_diagonalQuadrant[self.octant]

proc sameOrthogonalQuadrant*(self, lp: LineParameters): bool =
  result = s_orthogonal_quadrant[self.octant] == s_orthogonal_quadrant[lp.octant]

proc sameDiagonalQuadrant*(self, lp: LineParameters): bool =
  result = s_diagonalQuadrant[self.octant] == s_diagonalQuadrant[lp.octant]

proc divide*(self: LineParameters, lp1, lp2: var LineParameters) =
  let
    xmid = sar(self.x1 + self.x2, 1)
    ymid = sar(self.y1 + self.y2, 1)
    len2 = sar(self.len, 1)

  lp1 = self
  lp2 = self

  lp1.x2  = xmid
  lp1.y2  = ymid
  lp1.len = len2
  lp1.dx  = abs(lp1.x2 - lp1.x1)
  lp1.dy  = abs(lp1.y2 - lp1.y1)

  lp2.x1  = xmid
  lp2.y1  = ymid
  lp2.len = len2
  lp2.dx  = abs(lp2.x2 - lp2.x1)
  lp2.dy  = abs(lp2.y2 - lp2.y1)

proc bisectrix*(l1, l2: var LineParameters, x, y: var int) =
  var
    k = float64(l2.len) / float64(l1.len)
    tx = float64(l2.x2) - float64(l2.x1 - l1.x1) * k
    ty = float64(l2.y2) - float64(l2.y1 - l1.y1) * k

  #All bisectrices must be on the right of the line
  #If the next point is on the left (l1 => l2.2)
  #then the bisectix should be rotated by 180 degrees.
  if float64(l2.x2 - l2.x1) * float64(l2.y1 - l1.y1) <
     float64(l2.y2 - l2.y1) * float64(l2.x1 - l1.x1) + 100.0:
     tx -= (tx - float64(l2.x1)) * 2.0
     ty -= (ty - float64(l2.y1)) * 2.0

  # Check if the bisectrix is too short
  var
    dx = tx - float64(l2.x1)
    dy = ty - float64(l2.y1)
  if sqrt(dx * dx + dy * dy).int < lineSubpixelScale:
    x = sar(l2.x1 + l2.x1 + (l2.y1 - l1.y1) + (l2.y2 - l2.y1), 1)
    y = sar(l2.y1 + l2.y1 - (l2.x1 - l1.x1) - (l2.x2 - l2.x1), 1)
    return

  x = iround(tx)
  y = iround(ty)

proc fixDegenerateBisectrixStart*(lp: LineParameters, x, y: var int) {.inline.} =
  let d = iround((float64(x - lp.x2) * float64(lp.y2 - lp.y1) -
                  float64(y - lp.y2) * float64(lp.x2 - lp.x1)) / float64(lp.len))
  if d < lineSubpixelScale div 2:
    x = lp.x1 + (lp.y2 - lp.y1)
    y = lp.y1 - (lp.x2 - lp.x1)

proc fixDegenerateBisectrixEnd*(lp: LineParameters, x, y: var int) {.inline.} =
  let d = iround((float64(x - lp.x2) * float64(lp.y2 - lp.y1) -
                  float64(y - lp.y2) * float64(lp.x2 - lp.x1)) / float64(lp.len))
  if d < lineSubpixelScale div 2:
    x = lp.x2 + (lp.y2 - lp.y1)
    y = lp.y2 - (lp.x2 - lp.x1)
