import strutils, streams
import agg / [basics, rendering_buffer, scanline_u, renderer_scanline,
  pixfmt_rgb, color_rgba, gamma_functions, renderer_base, calc, trans_affine,
  path_storage, conv_stroke, math_stroke, rasterizer_scanline_aa, conv_transform,
  gsv_text, ellipse]
import platform.support, ctrl.slider, math

let human = """
# 0.0000 0.0000 0.0000 0.0000 4 0 Root
## 0.0000 0.0000 1.5708 30.0000 0 0 Head
## 0.0000 0.0000 -1.5708 50.0000 2 0 Back
### 0.0000 0.0000 -0.7854 50.0000 1 0 LLeg
#### 0.0000 0.0000 0.7854 50.0000 0 0 LLeg2
### 0.0000 0.0000 0.7854 50.0000 1 0 RLeg
#### 0.0000 0.0000 -0.7854 50.0000 0 0 RLeg2
## 0.0000 0.0000 -0.1000 40.0000 1 0 LArm
### 0.0000 0.0000 0.1000 40.0000 0 0 LArm2
## 0.0000 0.0000 3.2416 40.0000 1 0 RArm
### 0.0000 0.0000 -0.1000 40.0000 0 0 RArm2
"""

let snake = """
# 0.0000 0.0000 0.2000 50.0000 1 3 Root
## 0.0000 0.0000 0.7000 50.0000 1 0 One
### 0.0000 0.0000 1.0000 50.0000 1 0 Two
#### 0.0000 0.0000 0.5000 50.0000 1 0 Three
##### 0.0000 0.0000 1.0000 50.0000 1 0 Four
###### 0.0000 0.0000 1.0000 50.0000 0 0 Five
"""

let star = """
# 0.0 0.0 0.0 0 5 3 Root
## 0.0 0.0 0.000 100 0 0 One
## 0.0 0.0 1.256 100 0 0 Two
## 0.0 0.0 2.512 100 0 0 Three
## 0.0 0.0 3.768 100 0 0 Four
## 0.0 0.0 5.024 100 0 0 Five
"""

type
  BoneFlag = enum
    BONE_ABSOLUTE_ANGLE
    BONE_ABSOLUTE_POSITION

  BoneFlags = set[BoneFlag]

  Bone = ref object
    name: string
    x, y: float64
    angle: float64
    length: float64
    flags: BoneFlags
    children: seq[Bone]
    parent: Bone

const
  BONE_ABSOLUTE = {BONE_ABSOLUTE_ANGLE, BONE_ABSOLUTE_POSITION}

proc addChild(root: Bone, x, y, angle, length: float64, flags: BoneFlags, name: string): Bone =
  if root == nil: # If there is no root, create one
    new(result)
    result.parent = nil
  else:
    # Allocate the child
    new(result)
    result.parent = root # Set it's parent
    root.children.add(result)

  # Set data
  result.x = x
  result.y = y
  result.angle  = angle
  result.length = length
  result.flags  = flags
  result.name   = name
  result.children = @[]

proc dumpTree(root: Bone, level: int): string =
  if root == nil: return ""

  result = ""
  for i in 0.. <level:
    result.add '#' # We print `#` to signal the level of this bone.

  result.add(" $1 $2 $3 $4 $5 $6 $7\n" % [$root.x, $root.y,
    $root.angle, $root.length, $root.children.len, $cast[uint](root.flags), root.name])

  # Recursively call this on my children
  for child in root.children:
    result.add dumpTree(child, level + 1)

proc loadBone(s: Stream): Bone =
  # Get the info about this bone
  var
    line = ""
    actualLevel = 0
    root, temp: Bone

  while s.readLine(line):
    var
      parts = line.split(' ')
      depth = parts[0].len - 1
      x = parseFloat(parts[1])
      y = parseFloat(parts[2])
      angle  = parseFloat(parts[3])
      length = parseFloat(parts[4])
      flags  = cast[BoneFlags](parseInt(parts[5]))
      name   = parts[7]

    if depth < 0:
      echo "wrong bone depth"
      return nil

    # If actual level is too high, go down
    while actualLevel > depth:
      dec actualLevel
      temp = temp.parent

    # If no root is defined, make one at level 0
    if root == nil and depth == 0:
      root = addChild(nil, x, y, angle, length, flags, name)
      temp = root
    else:
      temp = addChild(temp, x, y, angle, length, flags, name)
  
    # Since the boneAddChild returns child's address, we go up a level in the hierarchy
    inc actualLevel
  
  result = root  

const
  frameWidth = 600
  frameHeight = 400
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    root: Bone
    pf: PixFmt
    rb: RendererBase[PixFmt]
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    ps: PathStorage
    worldMtx: TransAffine
    
proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  var s = newStringStream(human)
  result.root = s.loadBone()
  
  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()
  result.ps  = initPathStorage()
  result.worldMtx = initTransAffine()
  
proc drawDot(app: App, mtx: TransAffine) =
  var localMtx = mtx
  localMtx *= app.worldMtx
  var ell = initEllipse(0, 0, 4, 4, 10)
  var cell = initConvTransform(ell, localMtx)
  app.ras.addPath(cell)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, initRgba8(0,255,0))

proc drawLine(app: App, len: float64, mtx: TransAffine) =
  var localMtx = mtx
  localMtx *= app.worldMtx
  app.ps.removeAll()
  app.ps.moveTo(0, 0)
  app.ps.lineTo(len, 0)
  var stroke = initConvStroke(app.ps)
  var trans = initConvTransform(stroke, localMtx)
  app.ras.addPath(trans)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, initRgba8(255,0,255))

proc draw(app: App, root: Bone, mtx: TransAffine) =
  var loc = mtx # push Matrix

  loc = transAffineTranslation(root.x, root.y) * loc
  loc = transAffineRotation(root.angle) * loc
  app.drawDot(loc)
  app.drawLine(root.length, loc)
  
  # Translate to reach the new starting position
  loc = transAffineTranslation(root.length, 0) * loc
  
  # Call function on my children
  for child in root.children:
    app.draw(child, loc)

  # pop Matrix
  
method onDraw(app: App) =
  app.pf  = construct(PixFmt, app.rbufWindow())
  app.rb  = initRendererBase(app.pf)
  app.worldMtx = transAffineTranslation(250, 250)
  app.rb.clear(initRgba(1,1,1))
  var loc = initTransAffine()
  app.draw(app.root, loc)    
  
method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  discard

method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  discard

method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  discard

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("Bone Demo")

  if app.init(frameWidth, frameHeight, {window_resize}, "bone_demo"):
    return app.run()

  result = 1

discard main()
