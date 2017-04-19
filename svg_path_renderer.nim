import agg_path_storage, agg_conv_transform, agg_conv_stroke
import agg_conv_curve, agg_color_rgba, agg_renderer_scanline
import agg_rasterizer_scanline_aa, agg_basics, agg_conv_contour
import agg_trans_affine, svg_path_tokenizer, agg_bounding_rect
import agg_basics

type
  ConvCount*[VertexSource] = object
    mSource: ptr VertexSource
    mCount: int

proc initConvCount*[VS](vs: var VS): ConvCount[VS] =
  result.mSource = vs.addr
  result.mCount = 0

proc count*[VS](self: var ConvCount[VS], n: int) =
  self.mCount = n

proc count*[VS](self: ConvCount[VS]): int =
  self.mCount

proc rewind*[VS](self: var ConvCount[VS], pathId: int) =
  self.mSource[].rewind(pathId)

proc vertex*[VS](self: var ConvCount[VS], x, y: var float64): uint =
  inc self.mCount
  self.mSource[].vertex(x, y)

type
  PathFlag* = enum
    FillFlag
    StrokeFlag
    EvenOddFlag
    
  PathFlags* = set[PathFlag]
  
  PathAttributes* = object
    index*: int
    fillColor*, strokeColor*: Rgba8
    flag*: PathFlags
    lineJoin*: LineJoin
    lineCap*: LineCap
    miterLimit*: float64
    strokeWidth*: float64
    transform*: TransAffine

proc initPathAttributes*(): PathAttributes =
  result.index = 0
  result.fillColor = initRgba8(0,0,0)
  result.strokeColor = initRgba8(0,0,0)
  result.flag = {FillFlag}
  result.lineJoin = miterJoin
  result.lineCap = buttCap
  result.miterLimit = 4.0
  result.strokeWidth = 1.0
  result.transform = initTransAffine()

proc initPathAttributes*(attr: PathAttributes): PathAttributes =
  result.index = attr.index
  result.fillColor = attr.fillColor
  result.strokeColor = attr.strokeColor
  result.flag = attr.flag
  result.lineJoin = attr.lineJoin
  result.lineCap = attr.lineCap
  result.miterLimit = attr.miterLimit
  result.strokeWidth = attr.strokeWidth
  result.transform = attr.transform

proc initPathAttributes*(attr: PathAttributes, idx: int): PathAttributes =
  result.index = idx
  result.fillColor = attr.fillColor
  result.strokeColor = attr.strokeColor
  result.flag = attr.flag
  result.lineJoin = attr.lineJoin
  result.lineCap = attr.lineCap
  result.miterLimit = attr.miterLimit
  result.strokeWidth = attr.strokeWidth
  result.transform = attr.transform

type
  AttrStorage = seq[PathAttributes]
  Curved = ConvCurve[PathStorage]
  CurvedCount = ConvCount[Curved]
  CurvedStroked = ConvStroke[CurvedCount, NullMarkers]
  CurvedStrokedTrans = ConvTransform[CurvedStroked, TransAffine]
  CurvedTrans = ConvTransform[CurvedCount, TransAffine]
  CurvedTransContour = ConvContour[CurvedTrans]

  PathRenderer* = object
    mStorage: PathStorage
    mAttrStorage: AttrStorage
    mAttrStack: AttrStorage
    mTransform: TransAffine
    mCurved: Curved
    mCurvedCount: CurvedCount
    mCurvedStroked: CurvedStroked
    mCurvedStrokedTrans: CurvedStrokedTrans
    mCurvedTrans: CurvedTrans
    mCurvedTransContour: CurvedTransContour
    
proc initPathRenderer*(): PathRenderer =
  result.mStorage = initPathStorage()
  result.mAttrStorage = @[]
  result.mAttrStack = @[]
  
  result.mCurved = initConvCurve(result.mStorage)
  result.mCurvedCount = initConvCount(result.mCurved)

  result.mCurvedStroked = initConvStroke(result.mCurvedCount)
  result.mCurvedStrokedTrans = initConvTransform(result.mCurvedStroked, result.mTransform)

  result.mCurvedTrans = initConvTransform(result.mCurvedCount, result.mTransform)
  result.mCurvedTransContour = initConvContour(result.mCurvedTrans)
  result.mCurvedTransContour.autoDetectOrientation(false)

proc removeAll*(self: var PathRenderer) =
  self.mStorage.removeAll()
  self.mAttrStorage.setLen(0)
  self.mAttrStack.setLen(0)
  self.mTransform.reset()

proc vertexCount*(self: PathRenderer): int =
  self.mCurvedCount.count()
  
proc curAttr*(self: var PathRenderer): var PathAttributes =
  if self.mAttrStack.len() == 0:
    raise SVGError("curAttr : Attribute stack is empty")

  self.mAttrStack[^1]
  
proc pushAttr*(self: var PathRenderer) =
  if self.mAttrStack.len() != 0:
    self.mAttrStack.add(self.mAttrStack[^1])
  else:
    self.mAttrStack.add(initPathAttributes())
    
proc popAttr*(self: var PathRenderer) =
  if self.mAttrStack.len() == 0:
    raise SVGError("popAttr : Attribute stack is empty")

  self.mAttrStack.removeLast()

proc beginPath*(self: var PathRenderer) =
  self.pushAttr()
  let idx = self.mStorage.startNewPath()
  self.mAttrStorage.add(initPathAttributes(self.curAttr(), idx))

proc endPath*(self: var PathRenderer) =
  if self.mAttrStorage.len() == 0:
    raise SVGError("end_path : The path was not begun")

  var 
    attr = self.curAttr()
    idx = self.mAttrStorage[^1].index
    
  attr.index = idx
  self.mAttrStorage[^1] = attr
  self.popAttr()

proc moveTo*(self: var PathRenderer, x, y: float64, rel: bool = false) =  # M, m
  var
    x = x
    y = y
    
  if rel: self.mStorage.relToAbs(x, y)
  self.mStorage.moveTo(x, y)

proc lineTo*(self: var PathRenderer, x, y: float64, rel: bool = false) = # L, l
  var
    x = x
    y = y

  if rel: self.mStorage.relToAbs(x, y)
  self.mStorage.lineTo(x, y)

proc hlineTo*(self: var PathRenderer, x: float64, rel: bool = false) =  # H, h
  var
    x2 = 0.0
    y2 = 0.0
    x = x
    
  if self.mStorage.totalVertices() != 0:
    discard self.mStorage.vertex(self.mStorage.totalVertices() - 1, x2, y2)
    if rel: x += x2
    self.mStorage.lineTo(x, y2)
    
proc vlineTo*(self: var PathRenderer, y: float64, rel: bool = false) = # V, v
  var
    x2 = 0.0
    y2 = 0.0
    y = y
    
  if self.mStorage.totalVertices() != 0:
    discard self.mStorage.vertex(self.mStorage.totalVertices() - 1, x2, y2)
    if rel: y += y2
    self.mStorage.lineTo(x2, y)

proc curve3*(self: var PathRenderer, x1, y1, x, y: float64, rel: bool = false) =  # Q, q
  var
    x1 = x1
    y1 = y1
    x = x
    y = y
    
  if rel: 
    self.mStorage.relToAbs(x1, y1)
    self.mStorage.relToAbs(x, y)
  self.mStorage.curve3(x1, y1, x, y)

proc curve3*(self: var PathRenderer, x, y: float64, rel: bool = false) = # T, t
  if rel: 
    self.mStorage.curve3Rel(x, y)
  else:
    self.mStorage.curve3(x, y)

proc curve4*(self: var PathRenderer, x1, y1, x2, y2, x, y: float64, rel: bool = false) = # C, c
  var
    x1 = x1
    y1 = y1
    x2 = x2
    y2 = y2
    x = x
    y = y
 
  if rel: 
    self.mStorage.relToAbs(x1, y1)
    self.mStorage.relToAbs(x2, y2)
    self.mStorage.relToAbs(x,  y)
  self.mStorage.curve4(x1, y1, x2, y2, x, y)

proc curve4*(self: var PathRenderer, x2, y2, x, y: float64, rel: bool = false) = # S, s
  if rel: 
    self.mStorage.curve4Rel(x2, y2, x, y)
  else:
    self.mStorage.curve4(x2, y2, x, y)

proc closeSubpath*(self: var PathRenderer) =
  self.mStorage.endPoly(pathFlagsClose)

proc fill*(self: var PathRenderer, f: Rgba8) =
  self.curAttr().fillColor = f
  self.curAttr().flag.incl FillFlag

proc stroke*(self: var PathRenderer, s: Rgba8) =
  self.curAttr().strokeColor = s
  self.curAttr().flag.incl StrokeFlag

proc evenOdd*(self: var PathRenderer, flag: bool) =
  if flag:
    self.curAttr().flag.incl EvenOddFlag
  else:
    self.curAttr().flag.excl EvenOddFlag

proc strokeWidth*(self: var PathRenderer, w: float64) =
  self.curAttr().strokeWidth = w
  
proc fillNone*(self: var PathRenderer) =
  self.curAttr().flag.excl FillFlag

proc strokeNone*(self: var PathRenderer) =
  self.curAttr().flag.excl StrokeFlag

proc fillOpacity*(self: var PathRenderer, op: float64) =
  self.curAttr().fillColor.opacity(op)

proc strokeOpacity*(self: var PathRenderer, op: float64) =
  self.curAttr().strokeColor.opacity(op)

proc lineJoin*(self: var PathRenderer, join: LineJoin) =
  self.curAttr().lineJoin = join

proc lineCap*(self: var PathRenderer, cap: LineCap) =
  self.curAttr().lineCap = cap

proc miterLimit*(self: var PathRenderer, ml: float64) =
  self.curAttr().miterLimit = ml

proc transform*(self: var PathRenderer): var TransAffine =
  self.curAttr().transform

proc parsePath*(self: var PathRenderer, tok: var Pathtokenizer, debug: bool = false) =
  while tok.next():
    var
      arg: array[10, float64]
      cmd = tok.lastCommand()
      
    case cmd
    of 'M', 'm':
      arg[0] = tok.lastNumber()
      arg[1] = tok.next(cmd)
      self.moveTo(arg[0], arg[1], cmd == 'm')
    of 'L', 'l':
      arg[0] = tok.lastNumber()
      arg[1] = tok.next(cmd)
      self.lineTo(arg[0], arg[1], cmd == 'l')
    of 'V', 'v':
      self.vlineTo(tok.lastNumber(), cmd == 'v')
    of 'H', 'h':
      self.hlineTo(tok.lastNumber(), cmd == 'h')
    of 'Q', 'q':
      arg[0] = tok.lastNumber()
      for i in 1.. <4:
        arg[i] = tok.next(cmd)
      self.curve3(arg[0], arg[1], arg[2], arg[3], cmd == 'q')
    of 'T', 't':
      arg[0] = tok.lastNumber()
      arg[1] = tok.next(cmd)
      self.curve3(arg[0], arg[1], cmd == 't')
    of 'C', 'c':
      arg[0] = tok.lastNumber()
      for i in 1.. <6:
        arg[i] = tok.next(cmd)
      self.curve4(arg[0], arg[1], arg[2], arg[3], arg[4], arg[5], cmd == 'c')
    of 'S', 's':
      arg[0] = tok.lastNumber()
      for i in 1.. <4:
        arg[i] = tok.next(cmd)
      self.curve4(arg[0], arg[1], arg[2], arg[3], cmd == 's')
    of 'A', 'a':
      raise SVGError("parse_path: Command A: NOT IMPLEMENTED YET")
    of 'Z', 'z':
      self.closeSubpath()
    else:
      raise SVGError("parse_path: Invalid Command " & $cmd)
            
# Make all polygons CCW-oriented
proc arrangeOrientations*(self: var PathRenderer) =
  self.mStorage.arrangeOrientationsAllPaths(pathFlagsCcw)

# Expand all polygons 
proc expand*(self: var PathRenderer, value: float64) =
  self.mCurvedTransContour.width(value)

proc `[]`*(self: var PathRenderer, idx: int): int =
  self.mTransform = self.mAttrStorage[idx].transform
  self.mAttrStorage[idx].index

proc boundingRect*(self: var PathRenderer, x1, y1, x2, y2: var float64) =
  var trans = initConvTransform(self.mStorage, self.mTransform)
  discard boundingRect(trans, self, 0, self.mAttrStorage.len(), x1, y1, x2, y2)

# Rendering. One can specify two additional parameters: 
# trans_affine and opacity. They can be used to transform the whole
# image and/or to make it translucent.
proc render*[Rasterizer, Scanline, Renderer](self: var PathRenderer, ras: var Rasterizer, 
  sl: var Scanline, ren: var Renderer, mtx: var TransAffine, cb: RectI, opacity = 1.0) =

  mixin clipBox, rewind
  
  ras.clipBox(cb.x1.float64, cb.y1.float64, cb.x2.float64, cb.y2.float64)
  self.mCurvedCount.count(0)
  
  for attr in self.mAttrStorage:
    self.mTransform = attr.transform
    self.mTransform *= mtx
    var scl = self.mTransform.scale()
    #self.mCurved.approximation_method(curve_inc)
    self.mCurved.approximationScale(scl)
    self.mCurved.angleTolerance(0.0)
    
    var color: Rgba8
    
    if FillFlag in attr.flag:
      ras.reset()
      ras.fillingRule(if EvenOddFlag in attr.flag: fillEvenOdd else: fillNonZero)
      #if abs(self.mCurvedTransContour.width()) < 0.0001:
      ras.addPath(self.mCurvedTrans, attr.index)
      #else:
        #self.mCurvedTransContour.miterLimit(attr.miterLimit)
        #ras.addPath(self.mCurvedTransContour, attr.index)
    
      color = attr.fillColor
      color.opacity(color.opacity() * opacity)
      ren.color(color)
      renderScanlines(ras, sl, ren)
    
    if StrokeFlag in attr.flag:
        self.mCurvedStroked.width(attr.strokeWidth)
        #self.mCurvedStroked.line_join((attr.line_join == miter_join) ? miter_join_round : attr.line_join)
        self.mCurvedStroked.lineJoin(attr.lineJoin)
        self.mCurvedStroked.lineCap(attr.lineCap)
        self.mCurvedStroked.miterLimit(attr.miterLimit)
        self.mCurvedStroked.innerJoin(innerRound)
        self.mCurvedStroked.approximationScale(scl)
    
        # If the *visual* line width is considerable we 
        # turn on processing of curve cusps.
        if attr.strokeWidth * scl > 1.0:
          self.mCurved.angleTolerance(0.2)
          
        ras.reset()
        ras.fillingRule(fillNonZero)
        ras.addPath(self.mCurvedStrokedTrans, attr.index)
        color = attr.strokeColor
        color.opacity(color.opacity() * opacity)
        ren.color(color)
        renderScanlines(ras, sl, ren)
