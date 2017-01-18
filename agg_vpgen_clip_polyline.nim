import agg_basics, agg_clip_liang_barsky

type
  VpgenClipPolyline* = object
    mClipBox: RectD
    mX1, mY1: float64
    mX, mY: array[2, float64]
    mCmd: array[2, uint]
    mNumVertices: int
    mVertex: int
    mMoveTo: bool
    
proc initVpgenClipPolyline*(): VpgenClipPolyline =
  result.mClipBox = initRectD(0, 0, 1, 1)
  result.mX1 = 0
  result.mY1 = 0
  result.mNumVertices = 0
  result.mVertex = 0
  result.mMoveTo = false
  
template construct*(x: typedesc[VpgenClipPolyline]): untyped = initVpgenClipPolyline()

proc clipBox*(self: var VpgenClipPolyline, x1, y1, x2, y2: float64) =
  self.mClipBox.x1 = x1
  self.mClipBox.y1 = y1
  self.mClipBox.x2 = x2
  self.mClipBox.y2 = y2
  self.mClipBox.normalize()
  
proc x1*(self: VpgenClipPolyline): float64 = self.mClipBox.x1
proc y1*(self: VpgenClipPolyline): float64 = self.mClipBox.y1
proc x2*(self: VpgenClipPolyline): float64 = self.mClipBox.x2
proc y2*(self: VpgenClipPolyline): float64 = self.mClipBox.y2

proc autoClose*(x: typedesc[VpgenClipPolyline]): bool = false
proc autoUnclose*(x: typedesc[VpgenClipPolyline]): bool = true

proc reset*(self: var VpgenClipPolyline) =
  self.mVertex = 0
  self.mNumVertices = 0
  self.mMoveTo = false
        
proc moveTo*(self: var VpgenClipPolyline, x, y: float64) =
  self.mVertex = 0
  self.mNumVertices = 0
  self.mX1 = x
  self.mY1 = y
  self.mMoveTo = true
  
proc lineTo*(self: var VpgenClipPolyline, x, y: float64) =
  var
    x2 = x
    y2 = y
    flags = clipLineSegment(self.mX1, self.mY1, x2, y2, self.mClipBox)
  
  self.mVertex = 0
  self.mNumVertices = 0
  if (flags and 4) == 0:
    if (flags and 1) != 0 or self.mMoveTo:
      self.mX[0] = self.mX1
      self.mY[0] = self.mY1
      self.mCmd[0] = pathCmdMoveTo
      self.mNumVertices = 1
    self.mX[self.mNumVertices] = x2
    self.mY[self.mNumVertices] = y2
    self.mCmd[self.mNumVertices] = pathCmdLineTo
    inc self.mNumVertices
    self.mMoveTo = (flags and 2) != 0
    
  self.mX1 = x
  self.mY1 = y
  
proc vertex*(self: var VpgenClipPolyline, x, y: var float64): uint =
  if self.mVertex < self.mNumVertices:
    x = self.mX[self.mVertex]
    y = self.mY[self.mVertex]
    result = self.mCmd[self.mVertex]
    inc self.mVertex
    return result
  
  result = pathCmdStop
