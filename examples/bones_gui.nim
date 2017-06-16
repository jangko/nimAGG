import agg / [basics, rendering_buffer, scanline_u, renderer_scanline,
  pixfmt_rgb, color_rgba, gamma_functions, renderer_base, calc,
  path_storage, conv_stroke, math_stroke, rasterizer_scanline_aa,
  rounded_rect, span_gradient, trans_affine, span_interpolator_linear,
  span_allocator, color_util, arc, ellipse, conv_transform, conv_curve]
import platform.support, ctrl.slider, math, strutils

{.compile: "bone_color.c".}
proc test_color(x,y,w,h: float32) {.importc.}

const
  frameWidth = 800
  frameHeight = 600
  flipY = true

type
  Action = enum
    actionNone
    actionBeginPath
    actionClosePath
    actionFill
    actionStroke
    actionGradient
    actionShape
    actionState
    
  State = object
    mtx: TransAffine
    strokeWidth: float64
    strokeColor: Rgba8
    fillColor: Rgba8
    isIdentity: bool
    fillingRule: FillingRule
    
  PixFmt = PixFmtBgr24
  RendererBaseT = RendererBase[PixFmt]
  
  App = ref object of PlatformSupport
    sl: ScanlineU8
    rb: RendererBaseT
    ras: RasterizerScanlineAA
    spanAllocator: SpanAllocator[Rgba8]
    ren: RendererScanlineAASolid[RendererBaseT, Rgba8]
    ps: PathStorage
    lastAction: Action
    state: State
    states: seq[State]
    
proc initState(): State =
  result.mtx = initTransAffine()
  result.isIdentity = true
  result.strokeWidth = 1.0
  result.strokeColor = Rgba8.noColor()
  result.fillColor = Rgba8.noColor()
  result.fillingRule = fillNonZero
  
proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.sl  = initScanlineU8()
  result.ras = initRasterizerScanlineAA()
  result.spanAllocator = initSpanAllocator[Rgba8]()  
  result.ps  = initPathStorage()
  result.state = initState()
  result.states = @[]
  result.lastAction = actionNone
  
proc beginPath(app: App) =
  app.ps.removeAll()
  app.lastAction = actionBeginPath
  
proc moveTo(app: App, x, y: float64) =
  app.ps.moveTo(x, y)
  app.lastAction = actionShape

proc lineTo(app: App, x, y: float64) =
  app.ps.lineTo(x, y)
  app.lastAction = actionShape

proc bezierTo(app: App, cx1, cy1, cx2, cy2, x, y: float64) =
  app.ps.curve4(cx1, cy1, cx2, cy2, x, y)
  app.lastAction = actionShape
  
proc closePath(app: App) =
  app.ps.closePolygon()
  app.lastAction = actionClosePath

proc save(app: App) =
  app.states.add app.state
  app.lastAction = actionState
  
proc restore(app: App) =
  if app.states.len > 0:
    app.state = app.states.pop()
  app.lastAction = actionState

proc resetTransform(app: App) =
  app.state.mtx.reset()
  app.state.isIdentity = true
  app.lastAction = actionState

proc translate(app: App, x, y: float64) =
  app.state.mtx = transAffineTranslation(x, y) * app.state.mtx
  app.state.isIdentity = false
  app.lastAction = actionState
  
proc rotate(app: App, a: float64) =
  app.state.mtx = transAffineRotation(a) * app.state.mtx
  app.state.isIdentity = false
  app.lastAction = actionState

proc scale(app: App, sx, sy: float64) =
  app.state.mtx = transAffineScaling(sx, sy) * app.state.mtx
  app.state.isIdentity = false
  app.lastAction = actionState
  
proc fillHole(app: App, fill: bool) =
  app.state.fillingRule = if fill: fillNonZero else: fillEvenOdd
  app.ras.fillingRule(app.state.fillingRule)
  app.lastAction = actionState
  
proc applyTransform[VS](app: App, vertexSource: var VS) =
  if app.state.isIdentity:
    var curve = initConvCurve(vertexSource)
    app.ras.addPath(curve)
  else:
    var curve = initConvCurve(vertexSource)
    var trans = initConvTransform(curve, app.state.mtx)
    app.ras.addPath(trans)

proc applyTransformStroke[VS](app: App, vertexSource: var VS) =
  if app.state.isIdentity:
    var curve = initConvCurve(vertexSource)
    var stroke = initConvStroke(curve)
    stroke.width(app.state.strokeWidth)
    app.ras.addPath(stroke)
  else:
    var curve = initConvCurve(vertexSource)
    var trans = initConvTransform(curve, app.state.mtx)
    var stroke = initConvStroke(trans)
    stroke.width(app.state.strokeWidth)
    app.ras.addPath(stroke)
    
proc roundRect(app: App, x1, y1, x2, y2, r: float64) =
  var rr = initRoundedRect(x1, y1, x2, y2, r)
  rr.normalizeRadius()
  app.ps.joinPath(rr)
  app.lastAction = actionShape
  
proc rect(app: App, x1, y1, x2, y2: float64) =
  app.ps.moveTo(x1, y1)
  app.ps.lineTo(x2, y1)
  app.ps.lineTo(x2, y2)
  app.ps.lineTo(x1, y2)
  app.ps.closePolygon()
  app.lastAction = actionShape
  
proc fill(app: App) =
  app.ren.color(app.state.fillColor)
  if app.ras.isClean() or app.lastAction notin {actionFill, actionGradient}:
    app.applyTransform(app.ps)
  renderScanlines(app.ras, app.sl, app.ren)
  app.lastAction = actionFill

proc fillColor(app: App, color: Rgba8) =
  app.state.fillColor = color
  app.lastAction = actionState
  
proc gradientAffine(x1, y1, x2, y2: float64, gradient_d2 = 100.0): TransAffine =
  let
    dx = x2 - x1
    dy = y2 - y1

  result.reset()
  result *= transAffineScaling(sqrt(dx * dx + dy * dy) / gradient_d2)
  result *= transAffineRotation(arctan2(dy, dx))
  result *= transAffineTranslation(x1, y1)
  result.invert()
  
proc linearGradient(app: App, sx, sy, ex, ey: float64, c1, c2: Rgba8) =
  var 
    sx = sx
    sy = sy
    ex = ex
    ey = ey
  
  app.state.mtx.transform(sx, sy)
  app.state.mtx.transform(ex, ey)
  
  var
    gradientFunc: GradientX
    gradientMtx      = gradientAffine(sx, sy, ex, ey, 255)
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    colorFunc        = initGradientLinearColor(c1, c2)
    spanGradient     = initSpanGradient(spanInterpolator, gradientFunc, colorFunc, 0, 255)
  
  if app.ras.isClean() or app.lastAction notin {actionFill, actionGradient}:  
    app.applyTransform(app.ps)

  renderScanlinesAA(app.ras, app.sl, app.rb, app.spanAllocator, spanGradient)
  app.lastAction = actionGradient

proc radialAffine(cx, cy, r: float64, gradient_d2 = 100.0): TransAffine =
  result.reset()
  result *= transAffineScaling(r / gradient_d2)
  result *= transAffineTranslation(cx, cy)
  result.invert()
  
proc radialGradient(app: App, cx, cy, inr, outr: float64, c1, c2: Rgba8) =
  var 
    cx = cx
    cy = cy
    r  = outr - inr
  
  app.state.mtx.transform(cx, cy)
  
  var
    gradientFunc: GradientRadialD
    gradientMtx      = radialAffine(cx, cy, r, 255)
    spanInterpolator = initSpanInterpolatorLinear(gradientMtx)
    colorFunc        = initGradientLinearColor(c1, c2)
    spanGradient     = initSpanGradient(spanInterpolator, gradientFunc, colorFunc, 0, 255)
  
  if app.ras.isClean() or app.lastAction notin {actionFill, actionGradient}:  
    app.applyTransform(app.ps)

  renderScanlinesAA(app.ras, app.sl, app.rb, app.spanAllocator, spanGradient)
  app.lastAction = actionGradient
                 
proc stroke(app: App) =
  if app.ras.isClean() or app.lastAction notin {actionStroke}:
    app.applyTransformStroke(app.ps)
  app.ren.color(app.state.strokeColor)
  renderScanlines(app.ras, app.sl, app.ren)
  app.lastAction = actionStroke
  
proc strokeWidth(app: App, width: float64) =
  app.state.strokeWidth = width
  app.lastAction = actionState
  
proc strokeColor(app: App, color: Rgba8) =
  app.state.strokeColor = color
  app.lastAction = actionState
  
proc arc(app: App, cx, cy, r, a0, a1: float64, ccw: bool) =
  var arc = initArc(cx, cy, r, r, a0, a1, ccw)
  app.ps.joinPath(arc)
  app.lastAction = actionShape
  
proc ellipse(app: App, x, y, rx, ry: float64) =
  var ell = initEllipse(x, y, rx, ry)
  app.ps.concatPath(ell)
  app.ps.closePolygon()
  app.lastAction = actionShape

proc circle(app: App, x, y, r: float64) =
  var ell = initEllipse(x, y, r, r)
  app.ps.concatPath(ell)
  app.ps.closePolygon()
  app.lastAction = actionShape
  
proc drawButton(app: App, x1, y1, x2, y2: float64, c: Rgba8) =
  var cornerRadius = 4.0
  
  app.beginPath()
  app.roundRect(x1+1, y1+1, x2-1, y2-1, cornerRadius-1)
  app.fillColor(c)
  app.fill()
  
  let 
    c1 = initRgba8(255,255,255,150)
    c2 = initRgba8(0,0,0,0)
  app.linearGradient(x1, y1, x1, y2, c1, c2)
  
  app.beginPath()
  app.roundRect(x1+0.5, y1+0.5, x2-0.5, y2-0.5, cornerRadius-0.5)
  app.strokeColor(initRgba8(0,0,0,48))
  app.stroke()
  
proc print(c: Rgba) =
  var text = "$1 $2 $3" % [c.r.formatFloat(ffDecimal, 3), 
    c.g.formatFloat(ffDecimal, 3), c.b.formatFloat(ffDecimal, 3)]
  echo text

proc drawColorWheel(app: App, x, y, w, h, t: float64) =
  var 
    hue = math.sin(t * 0.12f)
    cx = x + w*0.5f
    cy = y + h*0.5f
    r1 = (if w < h: w else: h) * 0.5f - 5.0f
    r0 = r1 - 20.0f
    aeps = 0.5f / r1 # half a pixel arc length in radians (2pi cancels out).

  app.save()
  
  for i in 0.. <6:
    let a0 = i.float64 / 6.0f * pi * 2.0f - aeps
    let a1 = (i.float64+1.0f) / 6.0f * pi * 2.0f + aeps
    app.beginPath()
    app.arc(cx, cy, r0, a0, a1, true)
    app.arc(cx, cy, r1, a1, a0, false)
    app.closePath()
    let
      ax = cx + math.cos(a0) * (r0+r1)*0.5f
      ay = cy + math.sin(a0) * (r0+r1)*0.5f
      bx = cx + math.cos(a1) * (r0+r1)*0.5f
      by = cy + math.sin(a1) * (r0+r1)*0.5f
      c0 = initRgba8(hsl2Rgba(a0/(pi*2),1.0f,0.55f))
      c1 = initRgba8(hsl2Rgba(a1/(pi*2),1.0f,0.55f))
    app.linearGradient(ax, ay, bx, by, c0, c1)
    
  app.beginPath()
  app.circle(cx,cy, r0-0.5f)
  app.circle(cx,cy, r1+0.5f)
  app.strokeWidth(2.0f)
  app.strokeColor(initRgba8(0,0,0,64))
  app.stroke()
  
  # Selector
  app.save()
  app.translate(cx,cy)
  app.rotate(hue*pi*2)

  # Marker on
  app.strokeWidth(4.0f)
  app.beginPath()
  app.roundRect(r0-1,-2,r1+1,4, 2)
  app.strokeColor(initRgba8(0,0,0,90))
  app.stroke()
 
  app.strokeWidth(2.0f)
  app.beginPath()
  app.roundRect(r0-1,-2,r1+1,4,2)
  app.strokeColor(initRgba8(255,255,255,192))
  app.stroke()
 
  
  # Center triangle
  var
    r = r0 - 6
    ax = math.cos(120.0f/180.0f*pi) * r
    ay = math.sin(120.0f/180.0f*pi) * r
    bx = math.cos(-120.0f/180.0f*pi) * r
    by = math.sin(-120.0f/180.0f*pi) * r
    
  app.beginPath()
  app.moveTo(r, 0)
  app.lineTo(ax, ay)
  app.lineTo(bx, by)
  app.closePath()
  
  var
    c0 = initRgba8(hsl2Rgba(hue,1.0f,0.5f))
    c1 = initRgba8(255,255,255,255)  
    c2 = initRgba8(0,0,0,0)
    c3 = initRgba8(0,0,0,255)
  app.linearGradient(r,0, ax,ay, c0, c1)
  app.linearGradient((r+ax)*0.5f,(0+ay)*0.5f, bx,by, c2, c3)
  app.strokeColor(initRgba8(0,0,0,64))
  app.stroke()

  # Select circle on triangle
  ax = math.cos(120.0f/180.0f*pi) * r*0.3f
  ay = math.sin(120.0f/180.0f*pi) * r*0.4f
  
  app.beginPath()
  app.circle(ax,ay, 9)
  app.circle(ax,ay, 4)
  app.fillHole(false)
  app.radialGradient(ax, ay, 0, 9.0, initRgba8(0,0,0,100), initRgba8(0,0,0,0))
      
  app.strokeWidth(2.0f)
  app.beginPath()
  app.circle(ax,ay,5)
  app.strokeColor(initRgba8(255,255,255,192))
  app.stroke() 
   
  app.restore()
  app.restore()
 
proc drawGraph(app: App, x, y, w, h, t: float64) =
  var
    samples, sx, sy: array[6, float64]
    dx = w/5.0f
  
  samples[0] = (1+math.sin(t*1.2345f  + math.cos(t*0.33457f)*0.44f))*0.5f
  samples[1] = (1+math.sin(t*0.68363f + math.cos(t*1.3f)*1.55f))*0.5f
  samples[2] = (1+math.sin(t*1.1642f  + math.cos(t*0.33457)*1.24f))*0.5f
  samples[3] = (1+math.sin(t*0.56345f + math.cos(t*1.63f)*0.14f))*0.5f
  samples[4] = (1+math.sin(t*1.6245f  + math.cos(t*0.254f)*0.3f))*0.5f
  samples[5] = (1+math.sin(t*0.345f   + math.cos(t*0.03f)*0.6f))*0.5f

  for i in 0.. <6:
    sx[i] = x+i.float64*dx
    sy[i] = y+h*samples[i]*0.8
  
  # Graph background
  app.beginPath()
  app.moveTo(sx[0], sy[0])
  for i in 1.. <6:
    app.bezierTo(sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i])
  app.lineTo(x+w, 0)
  app.lineTo(x, 0)
  app.linearGradient(x,0,x,h, initRgba8(0,160,192,0), initRgba8(0,160,192,64))

  # Graph line
  app.beginPath()
  app.moveTo(sx[0], sy[0]+2)
  for i in 1.. <6:
    app.bezierTo(sx[i-1]+dx*0.5f,sy[i-1]+2, sx[i]-dx*0.5f,sy[i]+2, sx[i],sy[i]+2)
  app.strokeColor(initRgba8(0,0,0,32))
  app.strokeWidth(3.0f)
  app.stroke()
  
  app.beginPath()
  app.moveTo(sx[0], sy[0])
  for i in 1.. <6:
    app.bezierTo(sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i])
  app.strokeColor(initRgba8(0,160,192,255))
  app.strokeWidth(3.0f)
  app.stroke()

  # Graph sample pos
  for i in 0.. <6:    
    app.beginPath()
    app.rect(sx[i]-10, sy[i]-10+2, 20,20)
    app.radialGradient(sx[i],sy[i]+2, 3.0f,8.0f, initRgba8(0,0,0,32), initRgba8(0,0,0,0))
#[
  nvgBeginPath(vg)
  for (i = 0; i < 6; i++)
    nvgCircle(sx[i], sy[i], 4.0f)
  nvgFillColor(initRgba8(0,160,192,255))
  nvgFill(vg)
  nvgBeginPath(vg)
  for (i = 0; i < 6; i++)
    nvgCircle(sx[i], sy[i], 2.0f)
  nvgFillColor(initRgba8(220,220,220,255))
  nvgFill(vg)

  nvgStrokeWidth(1.0f)
]#
 
method onDraw(app: App) =
  var
    pf  = construct(PixFmt, app.rbufWindow())
    x1 = 10.0
    y1 = app.height() - 10.0
    x2 = 110.0
    y2 = app.height() - 30.0
    c  = initRgba8(230,16,8)
    t  = 2.7
    
  app.rb  = initRendererBase(pf)
  app.ren = initRendererScanlineAASolid(app.rb)  
  app.rb.clear(initRgba(0.3,0.3,0.3))  
  app.drawButton(x1, y1, x2, y2, c)  
  app.drawColorWheel(app.width() - 300.0, app.height() - 300.0, 250.0f, 250.0f, t)
  #app.drawGraph(0.0, app.height()/4.0, app.width(), app.height()/2.0, t)
  
method onMouseButtonDown(app: App, x, y: int, flags: InputFlags) =
  discard
  
method onMouseMove(app: App, x, y: int, flags: InputFlags) =
  discard
  
method onMouseButtonUp(app: App, x, y: int, flags: InputFlags) =
  discard
  
proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("GUI demo")

  if app.init(frameWidth, frameHeight, {window_resize}, "gui_demo"):
    return app.run()

  result = 1

discard main()
