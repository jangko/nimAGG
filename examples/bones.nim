import strutils, streams
import agg / [basics, rendering_buffer, scanline_u, renderer_scanline,
  pixfmt_rgb, color_rgba, gamma_functions, renderer_base, calc, trans_affine,
  path_storage, conv_stroke, math_stroke, rasterizer_scanline_aa, conv_transform,
  gsv_text, ellipse, scanline_bin, pixfmt_gray, color_gray]
import platform.support, ctrl.slider, math, nimBMP

let human = """
# 0.0000 0.0000 0.0000 0.0000 4 0 Root
## 0.0000 0.0000 1.5708 30.0000 0 0 Neck
### 0.0000 0.0000 0.0 20.0000 0 0 Head
## 0.0000 0.0000 -1.5708 70.0000 2 0 Back
### 0.0000 0.0000 -0.7854 60.0000 1 0 LHips
#### 0.0000 0.0000 0.7854 50.0000 0 0 LLeg
##### 0.0000 0.0000 -0.7854 30.0000 0 0 LFoot
### 0.0000 0.0000 0.7854 60.0000 1 0 RHips
#### 0.0000 0.0000 -0.7854 50.0000 0 0 RLeg
##### 0.0000 0.0000 0.7854 30.0000 0 0 RFoot
## 0.0000 0.0000 -0.1000 30.0000 1 0 LShoulder
### 0.0000 0.0000 -0.5000 40.0000 0 0 LArm
#### 0.0000 0.0000 -0.7000 40.0000 0 0 LArm2
##### 0.0000 0.0000 -0.7000 15.0000 0 0 LPalm
## 0.0000 0.0000 3.2416 30.0000 1 0 RShoulder
### 0.0000 0.0000 0.5000 40.0000 0 0 RArm
#### 0.0000 0.0000 0.7000 40.0000 0 0 RArm2
##### 0.0000 0.0000 0.7000 15.0000 0 0 RPalm
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
    mtx: TransAffine
    selected: bool
    level: int

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
  result.selected = false

proc dumpTree(root: Bone, level: int): string =
  if root == nil: return ""

  result = ""
  for i in 0..<level:
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
  frameWidth = 800
  frameHeight = 600
  flipY = true

type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    root: Bone
    selectedBone: Bone
    pf: PixFmt
    rb: RendererBase[PixFmt]
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    ps: PathStorage
    worldMtx: TransAffine
    bones: seq[Bone]
    boundRect: RectD
    jointRadius: float
    boneAngle: SliderCtrl[Rgba8]
    viewPort: RectD

proc calcMtx(app: App, bone: Bone, mtx: TransAffine) =
  var loc = mtx

  loc = transAffineTranslation(bone.x, bone.y) * loc
  loc = transAffineRotation(bone.angle) * loc
  bone.mtx = loc

  loc = transAffineTranslation(bone.length, 0) * loc
  for child in bone.children:
    app.calcMtx(child, loc)

proc linearizeBone(app: App, bone: Bone, level: int) =
  bone.level = level
  app.bones.add bone
  for child in bone.children:
    app.linearizeBone(child, level + 1)

proc calcBoundRect(bones: seq[Bone], r: float): RectD =
  var
    minx = 0.0
    miny = 0.0
    maxx = 0.0
    maxy = 0.0
    x = 0.0
    y = 0.0

  for bone in bones:
    x = 0.0
    y = 0.0
    bone.mtx.transform(x, y)
    if x > maxx: maxx = x
    if y > maxy: maxy = y
    if x < minx: minx = x
    if y < miny: miny = y
    x = bone.length
    y = 0
    bone.mtx.transform(x, y)
    if x > maxx: maxx = x
    if y > maxy: maxy = y
    if x < minx: minx = x
    if y < miny: miny = y

  result = initRectD(minx - r, miny - r, maxx + r, maxy + r)

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.boneAngle = newSliderCtrl[Rgba8](10, 10, frameWidth-10, 19, not flipY)
  result.boneAngle.setRange(-360.0, 360.0)
  result.boneAngle.value(0.0)
  result.boneAngle.label("Angle=$1")
  result.boneAngle.isEnabled(false)
  result.addCtrl(result.boneAngle)

  var s = newStringStream(snake)
  result.root = s.loadBone()
  
  result.ras = initRasterizerScanlineAA()
  result.sl  = initScanlineU8()
  result.ps  = initPathStorage()
  result.worldMtx = initTransAffine()
  result.bones = @[]
  result.jointRadius = 4.0
  var mtx = initTransAffine()
  result.calcMtx(result.root, mtx)
  result.linearizeBone(result.root, 0)
  result.boundRect = calcBoundRect(result.bones, result.jointRadius)

proc drawBone(app: App, bone: Bone, mtx: TransAffine) =
  let radius = app.jointRadius
  var localMtx = mtx
  localMtx *= app.worldMtx

  app.ps.removeAll()
  app.ps.moveTo(0, 0)
  app.ps.lineTo(0, radius)
  app.ps.lineTo(bone.length, 0)
  app.ps.lineTo(0, -radius)
  app.ps.closePolygon()
  var trans = initConvTransform(app.ps, localMtx)
  app.ras.addPath(trans)
  var color = if bone.selected: initRgba8(255,0,255) else: initRgba8(0,0,255)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, color)

  var ell = initEllipse(0, 0, radius, radius, 10)
  var cell = initConvTransform(ell, localMtx)
  app.ras.addPath(cell)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, initRgba8(0,255,0))

proc draw(app: App, bone: Bone, mtx: TransAffine) =
  var loc = mtx # push Matrix

  loc = transAffineTranslation(bone.x, bone.y) * loc
  loc = transAffineRotation(bone.angle) * loc
  app.drawBone(bone, loc)

  # Translate to reach the new starting position
  loc = transAffineTranslation(bone.length, 0) * loc

  # Call function on my children
  for child in bone.children:
    app.draw(child, loc)

proc drawBoneName(app: App) =
  var
    text = initGsvText()
    pt = initConvStroke(text)

  text.size(8.0)
  pt.width(1.5)
  let colorBlack = initRgba8(0,0,0)
  let colorPink = initRgba8(255,0,255)
  var y = 0.0

  for bone in app.bones:
    text.startPoint(bone.level.float * 10.0, app.height() - 20.0 + y)
    text.text("- " & bone.name)
    app.ras.addPath(pt)
    if bone.selected:
      renderScanlinesAASolid(app.ras, app.sl, app.rb, colorPink)
    else:
      renderScanlinesAASolid(app.ras, app.sl, app.rb, colorBlack)
    y -= 20.0

proc drawBoundingBox(app: App, bb: RectD) =
  app.ps.removeAll()
  app.ps.moveTo(bb.x1, bb.y1)
  app.ps.lineTo(bb.x2, bb.y1)
  app.ps.lineTo(bb.x2, bb.y2)
  app.ps.lineTo(bb.x1, bb.y2)
  app.ps.closePolygon()
  var stroke = initConvStroke(app.ps)
  var trans = initConvTransform(stroke, app.worldMtx)
  app.ras.addPath(trans)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, initRgba8(255,255,0))

method onResize(app: App, sx, sy: int) =
  app.viewPort = initRectD(120, 30, app.width(), app.height())
  
method onDraw(app: App) =
  app.pf  = construct(PixFmt, app.rbufWindow())
  app.rb  = initRendererBase(app.pf)

  if app.selectedBone != nil:
    var bone = app.selectedBone
    bone.angle = deg2rad(app.boneAngle.value())
    var mtx: TransAffine

    if bone.parent != nil:
      mtx = bone.parent.mtx
      mtx = transAffineTranslation(bone.parent.length, 0) * mtx
    else:
      mtx = initTransAffine()
    app.calcMtx(bone, mtx)
    app.boundRect = calcBoundRect(app.bones, app.jointRadius)
    
  app.rb.clear(initRgba(1,1,1))  

  var
    bb = app.boundRect
    w = bb.x2 - bb.x1
    h = bb.y2 - bb.y1

  var cx = (app.width() - w) / 2.0 + abs(bb.x1)
  var cy = (app.height() - h) / 2.0 + abs(bb.y1)
  app.worldMtx = transAffineTranslation(cx, cy)

  var loc = initTransAffine()
  app.draw(app.root, loc)
  
  # draw bounding box
  app.drawBoundingBox(bb)
  
  var vp = app.viewPort  
  app.ps.removeAll()
  app.ps.moveTo(vp.x1, vp.y1)
  app.ps.lineTo(vp.x2, vp.y1)
  app.ps.lineTo(vp.x2, vp.y2)
  app.ps.lineTo(vp.x1, vp.y2)
  app.ps.lineTo(vp.x1, vp.y1)
  var stroke = initConvStroke(app.ps)
  app.ras.addPath(stroke)
  renderScanlinesAASolid(app.ras, app.sl, app.rb, initRgba8(0,255,255))  
  
  app.drawBoneName()

  if app.selectedBone != nil:
    renderCtrl(app.ras, app.sl, app.rb, app.boneAngle)

# bone hittest using b/w pick buffer
proc pickBone(app: App, x, y: int) =
  # clear bone selection
  app.selectedBone = nil
  app.boneAngle.isEnabled(false)
  for bone in app.bones:
    bone.selected = false

  let radius = app.jointRadius
  for bone in app.bones:
    var
      mtx = bone.mtx * app.worldMtx
      ell = initEllipse(0, 0, radius, radius, 10)
      cell = initConvTransform(ell, mtx)

    app.ps.removeAll()
    app.ps.moveTo(0, 0)
    app.ps.lineTo(0, radius)
    app.ps.lineTo(bone.length, 0)
    app.ps.lineTo(0, -radius)
    app.ps.closePolygon()
    var trans = initConvTransform(app.ps, mtx)
    app.ras.addPath(trans)
    var hitTest = app.ras.hitTest(x, y)

    app.ras.addPath(cell)
    hitTest = hitTest or app.ras.hitTest(x, y)
    if hitTest:
      bone.selected = true
      app.selectedBone = bone
      app.boneAngle.isEnabled(true)
      app.boneAngle.value(rad2deg(bone.angle))
      break

method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  if mouseLeft in flags:
    if app.viewPort.hitTest(x.float64, y.float64):
      app.pickBone(x, y)
      app.forceRedraw()

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
