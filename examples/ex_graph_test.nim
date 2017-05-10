import agg/[basics, rendering_buffer, rasterizer_scanline_aa, rasterizer_outline, 
  conv_stroke, conv_dash, conv_curve, conv_contour, conv_marker, conv_marker_adaptor, 
  conv_concat, arrowhead, vcgen_markers_term, scanline_p, scanline_u, renderer_scanline, 
  renderer_primitives, span_allocator, span_gradient, span_interpolator_linear, pixfmt_rgb,
  curves, color_rgba, renderer_base, ellipse, trans_affine, gamma_functions]
import ctrl/[slider, rbox, cbox], random, platform.support, strutils

const
  frameWidth = 700
  frameHeight = 530
  flipY = true

type
  Node = object
    x, y: float64

  Edge = object
    node1, node2: int

  Graph = object
    nodes: seq[Node]
    edges: seq[Edge]

proc initGraph(numNodes, numEdges: int): Graph =
  result.nodes = newSeq[Node](numNodes)
  result.edges = newseq[Edge](numEdges)

  randomize()

  for i in 0.. <numNodes:
    result.nodes[i].x = random(1.0) * 0.75 + 0.1
    result.nodes[i].y = random(1.0) * 0.85 + 0.1

  var i = 0
  while i < numEdges:
    result.edges[i].node1 = random(numNodes)
    result.edges[i].node2 = random(numNodes)
    if result.edges[i].node1 == result.edges[i].node2: dec i
    inc i

proc getNumNodes(self: Graph): int =
  self.nodes.len

proc getNumEdges(self: Graph): int =
  self.edges.len

proc getNode(self: Graph, idx: int, w, h: float64): Node =
  if idx < self.nodes.len:
    result = self.nodes[idx]
    result.x = result.x * w
    result.y = result.y * h

proc getEdge(self: Graph, idx: int): Edge =
  if idx < self.edges.len:
    result = self.edges[idx]

type
  Line = object
    x1, y1, x2, y2: float64
    f: int

proc initLine(x1, y1, x2, y2: float64): Line =
  result.x1 = x1
  result.y1 = y1
  result.x2 = x2
  result.y2 = y2
  result.f  = 0

proc rewind(self: var Line, pathId: int) =
  self.f = 0

proc vertex(self: var Line, x, y: var float64): uint =
  if self.f == 0:
    inc self.f
    x = self.x1
    y = self.y1
    return pathCmdMoveTo

  if self.f == 1:
    inc self.f
    x = self.x2
    y = self.y2
    return pathCmdLineTo

  return pathCmdStop

type
  Curve = object
    c: Curve4

proc initCurve(x1, y1, x2, y2: float64, k=0.5): Curve =
  result.c = initCurve4(x1, y1,
                x1 - (y2 - y1) * k,
                y1 + (x2 - x1) * k,
                x2 + (y2 - y1) * k,
                y2 - (x2 - x1) * k,
                x2, y2)

proc rewind(self: var Curve, pathId: int) =
  self.c.rewind(pathId)

proc vertex(self: var Curve, x, y: var float64): uint =
  self.c.vertex(x, y)

type
  StrokeDraftSimple[Source] = object
    s: ptr Source

proc initStrokeDraftSimple[S](src: var S, w: float64): StrokeDraftSimple[S] =
  result.s = src.addr

proc rewind[S](self: var StrokeDraftSimple[S], pathId: int) =
  self.s[].rewind(pathId)

proc vertex[S](self: var StrokeDraftSimple[S], x, y: var float64): uint =
  self.s[].vertex(x, y)

type
  StrokeDraftArrow[S] = object
    s: ConvMarkerAdaptor[S, VcgenMarkersTerm]
    ah: ArrowHead
    m: ConvMarker[VcgenMarkersTerm, ArrowHead]
    c: ConvConcat[ConvMarkerAdaptor[S, VcgenMarkersTerm], ConvMarker[VcgenMarkersTerm, ArrowHead]]

proc initStrokeDraftArrow[S](src: var S, w: float64): StrokeDraftArrow[S] =
  result.s  = initConvMarkerAdaptorAux[S, VcgenMarkersTerm](src)
  result.ah = initArrowHead()
  result.m  = initConvMarker(result.s.markers(), result.ah)
  result.c  = initConvConcat(result.s, result.m)
  result.ah.head(0, 10, 5, 0)
  result.s.shorten(10.0)

proc rewind[S](self: var StrokeDraftArrow[S], pathId: int) =
  self.c.rewind(pathId)

proc vertex[S](self: var StrokeDraftArrow[S], x, y: var float64): uint =
  self.c.vertex(x, y)

type
  StrokeFineSimple[S] = object
    s: ConvStroke[S, NullMarkers]

proc initStrokeFineSimple[S](src: var S, w: float64): StrokeFineSimple[S] =
  result.s = initConvStroke(src)
  result.s.width(w)

proc rewind[S](self: var StrokeFineSimple[S], pathId: int) =
  self.s.rewind(pathId)

proc vertex[S](self: var StrokeFineSimple[S], x, y: var float64): uint =
  self.s.vertex(x, y)

type
  StrokeFineArrow[S] = object
    s: ConvStroke[S, VcgenMarkersTerm]
    ah: ArrowHead
    m: ConvMarker[VcgenMarkersTerm, ArrowHead]
    c: ConvConcat[ConvStroke[S, VcgenMarkersTerm], ConvMarker[VcgenMarkersTerm, ArrowHead]]

proc initStrokeFineArrow[S](src: var S, w: float64): StrokeFineArrow[S] =
  result.s  = initConvStrokeAux[S, VcgenMarkersTerm](src)
  result.ah = initArrowHead()
  result.m  = initConvMarker(result.s.markers(), result.ah)
  result.c  = initConvConcat(result.s, result.m)
  result.s.width(w)
  result.ah.head(0, 10, 5, 0)
  result.s.shorten(w * 2.0)

proc rewind[S](self: var StrokeFineArrow[S], pathId: int) =
  self.c.rewind(pathId)

proc vertex[S](self: var StrokeFineArrow[S], x, y: var float64): uint =
  self.c.vertex(x, y)

type
  DashStrokeDraftSimple[S] = object
    d: ConvDash[S, VcgenMarkersTerm]

proc initDashStrokeDraftSimple[S](src: var S, dashLen, gapLen, w: float64): DashStrokeDraftSimple[S] =
  result.d = initConvDashAux[S, VcgenMarkersTerm](src)
  result.d.addDash(dashLen, gapLen)

proc rewind[S](self: var DashStrokeDraftSimple[S], pathId: int) =
  self.d.rewind(pathId)

proc vertex[S](self: var  DashStrokeDraftSimple[S], x, y: var float64): uint =
  self.d.vertex(x, y)

type
  DashStrokeDraftArrow[S] = object
    d: ConvDash[S, VcgenMarkersTerm]
    ah: ArrowHead
    m: ConvMarker[VcgenMarkersTerm, ArrowHead]
    c: ConvConcat[ConvDash[S, VcgenMarkersTerm], ConvMarker[VcgenMarkersTerm, ArrowHead]]

proc initDashStrokeDraftArrow[S](src: var S, dashLen, gapLen, w: float64): DashStrokeDraftArrow[S] =
  result.d  = initConvDashAux[S, VcgenMarkersTerm](src)
  result.ah = initArrowHead()
  result.m  = initConvMarker(result.d.markers(), result.ah)
  result.c  = initConvconcat(result.d, result.m)
  result.d.addDash(dashLen, gapLen)
  result.ah.head(0, 10, 5, 0)
  result.d.shorten(10.0)

proc rewind[S](self: var DashStrokeDraftArrow[S], pathId: int) =
  self.c.rewind(pathId)

proc vertex[S](self: var DashStrokeDraftArrow[S], x, y: var float64): uint =
  self.c.vertex(x, y)

type
  DashStrokeFineSimple[S] = object
    d: ConvDash[S, NullMarkers]
    s: ConvStroke[ConvDash[S, NullMarkers], NullMarkers]

proc initDashStrokeFineSimple[S](src: var S, dashLen, gapLen, w: float64): DashStrokeFineSimple[S] =
  result.d = initConvDash(src)
  result.s = initConvStroke(result.d)
  result.d.add_dash(dashLen, gapLen)
  result.s.width(w)

proc rewind[S](self: var DashStrokeFineSimple[S], pathId: int) =
  self.s.rewind(pathId)

proc vertex[S](self: var DashStrokeFineSimple[S], x, y: var float64): uint =
  self.s.vertex(x, y)

type
  DashStrokeFineArrow[S] = object
    d: ConvDash[S, VcgenMarkersTerm]
    s: ConvStroke[ConvDash[S, VcgenMarkersTerm], NullMarkers]
    ah: ArrowHead
    m: ConvMarker[VcgenMarkersTerm, ArrowHead]
    c: ConvConcat[ConvStroke[ConvDash[S, VcgenMarkersTerm], NullMarkers], ConvMarker[VcgenMarkersTerm, ArrowHead]]

proc initDashStrokeFineArrow[S](src: var S, dashLen, gapLen, w: float64): DashStrokeFineArrow[S] =
  result.d  = initConvDashAux[S, VcgenMarkersTerm](src)
  result.s  = initConvStroke(result.d)
  result.ah = initArrowHead()
  result.m  = initConvMarker(result.d.markers(), result.ah)
  result.c  = initConvConcat(result.s, result.m)
  result.d.addDash(dashLen, gapLen)
  result.s.width(w)
  result.ah.head(0, 10, 5, 0)
  result.d.shorten(w * 2.0)

proc rewind[S](self: var DashStrokeFineArrow[S], pathId: int) =
  self.c.rewind(pathId)

proc vertex[S](self: var DashStrokeFineArrow[S], x, y: var float64): uint =
  self.c.vertex(x, y)


type
  PixFmt = PixFmtBgr24

  App = ref object of PlatformSupport
    mType: RboxCtrl[Rgba8]
    mWidth: SliderCtrl[Rgba8]
    benchmark: CboxCtrl[Rgba8]
    draw_nodes: CboxCtrl[Rgba8]
    draw_edges: CboxCtrl[Rgba8]
    draft: CboxCtrl[Rgba8]
    noArrow: CboxCtrl[Rgba8]
    translucent: CboxCtrl[Rgba8]
    graph: Graph
    gradientColors: array[256, Rgba8]
    draw: int
    sl: ScanlineU8

proc newApp(format: PixFormat, flipY: bool): App =
  new(result)
  PlatformSupport(result).init(format, flipY)

  result.mType = newRboxCtrl[Rgba8](-1, -1, -1, -1, not flipY)
  result.mWidth = newSliderCtrl[Rgba8](110+80, 8.0, 110+200.0+80, 8.0 + 7.0, not flipY)
  result.benchmark = newCboxCtrl[Rgba8](110+200+80+8, 8.0-2.0, "Benchmark", not flipY)
  result.drawNodes = newCboxCtrl[Rgba8](110+200+80+8, 8.0-2.0+15.0, "Draw Nodes", not flipY)
  result.drawEdges = newCboxCtrl[Rgba8](200+200+80+8, 8.0-2.0+15.0, "Draw Edges", not flipY)
  result.draft = newCboxCtrl[Rgba8](200+200+80+8, 8.0-2.0, "Draft Mode", not flipY)
  result.noArrow = newCboxCtrl[Rgba8](300+200+80+8, 8.0-2.0, "No Arrow", not flipY)
  result.translucent = newCboxCtrl[Rgba8](110+80, 8.0-2.0+15.0, "Translucent Mode", not flipY)

  result.addCtrl(result.mType)
  result.addCtrl(result.mWidth)
  result.addCtrl(result.benchmark)
  result.addCtrl(result.drawNodes)
  result.addCtrl(result.drawEdges)
  result.addCtrl(result.draft)
  result.addCtrl(result.noArrow)
  result.addCtrl(result.translucent)

  result.noArrow.status(true)
  result.sl = initScanlineU8()
  result.graph = initGraph(200, 100)
  result.draw = 3
  result.mType.textSize(8.0)
  result.mType.addItem("Solid lines")
  result.mType.addItem("Bezier curves")
  result.mType.addItem("Dashed curves")
  result.mType.addItem("Poygons AA")
  result.mType.addItem("Poygons Bin")
  result.mType.curItem(1)

  result.mWidth.numSteps(20)
  result.mWidth.setRange(0.0, 5.0)
  result.mWidth.value(2.0)
  result.mWidth.label("Width=$1")
  result.benchmark.textSize(8.0)
  result.drawNodes.textSize(8.0)
  result.draft.textSize(8.0)
  result.drawNodes.status(true)
  result.drawEdges.status(true)
  result.drawEdges.textSize(8.0)

  var
    c1 = initRgba(1, 1, 0, 0.25)
    c2 = initRgba(0, 0, 1)

  for i in 0..255:
    result.gradientColors[i] = initRgba8(c1.gradient(c2, float64(i) / 255.0))

proc draw_nodes_draft(app: App) =
  var
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)
    prim   = initRendererPrimitives(rb)

  for i in 0.. <app.graph.getNumNodes():
    let n = app.graph.getNode(i, app.width(), app.height())
    prim.fillColor(app.gradientColors[147])
    prim.lineColor(app.gradientColors[255])
    prim.outlinedEllipse(int(n.x), int(n.y), 10, 10)
    prim.fillColor(app.gradientColors[50])
    prim.solidEllipse(int(n.x), int(n.y), 4, 4)

proc draw_nodes_fine(app: App, ras: var RasterizerScanlineAA) =
  var
    sa = initSpanAllocator[Rgba8]()
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)

  for i in 0.. <app.graph.getNumNodes():
    var
      n = app.graph.getNode(i, app.width(), app.height())
      ell = initEllipse(n.x, n.y, 5.0 * app.mWidth.value(), 5.0 * app.mWidth.value())
      x, y: float64
    case app.draw
    of 0:
      ell.rewind(0)
      while not isStop(ell.vertex(x, y)): discard
    of 1:
      ras.reset()
      ras.addPath(ell)
    of 2:
      ras.reset()
      ras.addPath(ell)
      ras.sort()
    of 3:
      var
        gf: GradientRadialD
        mtx   = initTransAffine()
        inter = initSpanInterpolatorLinear(mtx)
        sg    = initSpanGradient(inter, gf, app.gradientColors, 0.0, 10.0)
        ren   = initRendererScanlineAA(rb, sa, sg)

      mtx *= transAffineScaling(app.mWidth.value() / 2.0)
      mtx *= transAffineTranslation(n.x, n.y)
      mtx.invert()

      ras.addPath(ell)
      renderScanlines(ras, app.sl, ren)
    else:
      discard

type
  BaseRenderer = RendererBase[PixFmtRgb24]
  SolidRenderer = RendererScanlineAASolid[BaseRenderer, Rgba8]
  DraftRenderer = RendererScanlineBinSolid[BaseRenderer, Rgba8]

proc render_edge_fine[Source](app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer, src: var Source) =
  var
    x, y: float64
  case app.draw
  of 0:
    src.rewind(0)
    while not isStop(src.vertex(x, y)):
      discard
  of 1:
    ras.reset()
    ras.addPath(src)
  of 2:
    ras.reset()
    ras.addPath(src)
    ras.sort()
  of 3:
    var
      r = random(0x7F)
      g = random(0x7F)
      b = random(0x7F)
      a = 255
    if app.translucent.status(): a = 80
    ras.addPath(src)

    if app.mType.curItem() < 4:
      ren_fine.color(initRgba8(r, g, b, a))
      renderScanlines(ras, app.sl, renFine)
    else:
      renDraft.color(initRgba8(r, g, b, a))
      renderScanlines(ras, app.sl, renDraft)
  else:
    discard

proc strokeDraft[S, R](app: App, a: var S, b: float64, ras: var R) =
  if app.noArrow.status():
    var s = initStrokeDraftSimple(a, b)
    ras.addPath(s)
  else:
    var s = initStrokeDraftArrow(a, b)
    ras.addPath(s)

proc dashStrokeDraft[S, R](app: App, a: var S, b, c, d: float64, ras: var R) =
  if app.noArrow.status():
    var s = initDashStrokeDraftSimple(a, b, c, d)
    ras.addPath(s)
  else:
    var s = initDashStrokeDraftArrow(a, b, c, d)
    ras.addPath(s)

proc strokeFine[S,R](app: App, a: var S, b: float64, ras: var R,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =
  if app.noArrow.status():
    var s = initStrokeFineSimple(a, b)
    app.render_edge_fine(ras, renFine, renDraft, s)
  else:
    var s = initStrokeFineArrow(a, b)
    app.render_edge_fine(ras, renFine, renDraft, s)

proc dashStrokeFine[S,R](app: App, a: var S, b, c, d: float64, ras: var R,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =
  if app.noArrow.status():
    var s = initDashStrokeFineSimple(a, b, c, d)
    app.render_edge_fine(ras, renFine, renDraft, s)
  else:
    var s = initDashStrokeFineArrow(a, b, c, d)
    app.render_edge_fine(ras, renFine, renDraft, s)

proc draw_lines_draft(app: App) =
  var
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)
    prim   = initRendererPrimitives(rb)
    ras    = initRasterizerOutline(prim)

  for i in 0.. <app.graph.getNumEdges():
    var
      e  = app.graph.getEdge(i)
      n1 = app.graph.getNode(e.node1, app.width(), app.height())
      n2 = app.graph.getNode(e.node2, app.width(), app.height())
      ln = initLine(n1.x, n1.y, n2.x, n2.y)
      r = random(0x7F)
      g = random(0x7F)
      b = random(0x7F)
      a = 255
    if app.translucent.status(): a = 80
    prim.lineColor(initRgba8(r, g, b, a))
    app.strokeDraft(ln, app.mWidth.value(), ras)

proc draw_curves_draft(app: App) =
  var
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)
    prim   = initRendererPrimitives(rb)
    ras    = initRasterizerOutline(prim)

  for i in 0.. <app.graph.getNumEdges():
    var
      e  = app.graph.getEdge(i)
      n1 = app.graph.getNode(e.node1, app.width(), app.height())
      n2 = app.graph.getNode(e.node2, app.width(), app.height())
      c  = initCurve(n1.x, n1.y, n2.x, n2.y)
      r = random(0x7F)
      g = random(0x7F)
      b = random(0x7F)
      a = 255
    if app.translucent.status(): a = 80
    prim.lineColor(initRgba8(r, g, b, a))
    app.strokeDraft(c, app.mWidth.value(), ras)

proc draw_dashes_draft(app: App) =
  var
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)
    prim   = initRendererPrimitives(rb)
    ras    = initRasterizerOutline(prim)

  for i in 0.. < app.graph.getNumEdges():
    var
      e  = app.graph.getEdge(i)
      n1 = app.graph.getNode(e.node1, app.width(), app.height())
      n2 = app.graph.getNode(e.node2, app.width(), app.height())
      c  = initCurve(n1.x, n1.y, n2.x, n2.y)
      r = random(0x7F)
      g = random(0x7F)
      b = random(0x7F)
      a = 255
    if app.translucent.status(): a = 80
    prim.lineColor(initRgba8(r, g, b, a))
    app.dashStrokeDraft(c, 6.0, 3.0, app.mWidth.value(), ras)

proc draw_lines_fine(app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =

  for i in 0.. <app.graph.getNumEdges():
    var
      b  = app.graph.getEdge(i)
      n1 = app.graph.getNode(b.node1, app.width(), app.height())
      n2 = app.graph.getNode(b.node2, app.width(), app.height())
      ln = initLine(n1.x, n1.y, n2.x, n2.y)

    app.strokeFine(ln, app.mWidth.value(), ras, renFine, renDraft)


proc draw_curves_fine(app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =
  for i in 0.. <app.graph.getNumEdges():
    var
      b  = app.graph.getEdge(i)
      n1 = app.graph.getNode(b.node1, app.width(), app.height())
      n2 = app.graph.getNode(b.node2, app.width(), app.height())
      c  = initCurve(n1.x, n1.y, n2.x, n2.y)

    app.strokeFine(c, app.mWidth.value(), ras, renFine, renDraft)

proc draw_dashes_fine(app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =
  for i in 0.. <app.graph.getNumEdges():
    var
      b  = app.graph.getEdge(i)
      n1 = app.graph.getNode(b.node1, app.width(), app.height())
      n2 = app.graph.getNode(b.node2, app.width(), app.height())
      c  = initCurve(n1.x, n1.y, n2.x, n2.y)

    app.dashStrokeFine(c, 6.0, 3.0, app.mWidth.value(), ras, renFine, renDraft)

proc draw_polygons(app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =

  if app.mType.curItem() == 4:
    ras.gamma(initGammaThreshold(0.5))

  for i in 0.. <app.graph.getNumEdges():
    var
      b  = app.graph.getEdge(i)
      n1 = app.graph.getNode(b.node1, app.width(), app.height())
      n2 = app.graph.getNode(b.node2, app.width(), app.height())
      c  = initCurve(n1.x, n1.y, n2.x, n2.y)
    app.render_edge_fine(ras, renFine, renDraft, c)
  ras.gamma(initGammaNone())


proc draw_scene(app: App, ras: var RasterizerScanlineAA,
  renFine: var SolidRenderer, renDraft: var DraftRenderer) =

  ras.gamma(initGammaNone())
  randomize()

  if app.drawNodes.status():
    if app.draft.status():
      app.draw_nodes_draft()
    else:
      app.draw_nodes_fine(ras)

  if app.drawEdges.status():
    if app.draft.status():
      case app.mType.curItem()
      of 0: app.draw_lines_draft()
      of 1: app.draw_curves_draft()
      of 2: app.draw_dashes_draft()
      else: discard
    else:
      case app.mType.curItem()
      of 0: app.draw_lines_fine(ras, renFine, renDraft)
      of 1: app.draw_curves_fine(ras, renFine, renDraft)
      of 2: app.draw_dashes_fine(ras, renFine, renDraft)
      of 3, 4: app.draw_polygons(ras, renFine, renDraft)
      else: discard

method onDraw(app: App) =
  var
    pixf   = initPixfmtRgb24(app.rbufWindow())
    rb     = initRendererBase(pixf)
    ras    = initRasterizerScanlineAA()
    renFine  = initRendererScanlineAASolid(rb)
    renDraft = initRendererScanlineBinSolid(rb)

  rb.clear(initRgba(1, 1, 1))
  app.draw_scene(ras, renFine, renDraft)

  ras.fillingRule(FillingRule.fillNonZero)
  renderCtrl(ras, app.sl, rb, app.mType)
  renderCtrl(ras, app.sl, rb, app.mWidth)
  renderCtrl(ras, app.sl, rb, app.benchmark)
  renderCtrl(ras, app.sl, rb, app.drawNodes)
  renderCtrl(ras, app.sl, rb, app.drawEdges)
  renderCtrl(ras, app.sl, rb, app.draft)
  renderCtrl(ras, app.sl, rb, app.noArrow)
  renderCtrl(ras, app.sl, rb, app.translucent)

method onCtrlChange(app: App) =
  if app.benchmark.status():
    app.onDraw()
    app.updateWindow()

    var
      pixf   = initPixfmtRgb24(app.rbufWindow())
      rb     = initRendererBase(pixf)
      ras    = initRasterizerScanlineAA()
      renFine  = initRendererScanlineAASolid(rb)
      renDraft = initRendererScanlineBinSolid(rb)
      buf: string

    if app.draft.status():
      app.startTimer()
      for i in 0.. <10:
        app.draw_scene(ras, renFine, renDraft)
      let t1 = app.elapsedTime()
      buf = "$1f milliseconds" % [t1.formatFloat(ffDecimal, 3)]
    else:
      var times: array[5, float64]
      for x in 0.. <4:
        app.draw = x
        app.startTimer()
        for i in 0.. <10:
          app.draw_scene(ras, renFine, renDraft)
        times[app.draw] = app.elapsedTime()

      app.draw = 3

      times[4]  = times[3]
      times[3] -= times[2]
      times[2] -= times[1]
      times[1] -= times[0]

      buf = "  pipeline  add_path         sort       render       total\n$1 $2 $3 $4 $5" % [
        times[0].formatFloat(ffDecimal, 3),
        times[1].formatFloat(ffDecimal, 3),
        times[2].formatFloat(ffDecimal, 3),
        times[3].formatFloat(ffDecimal, 3),
        times[4].formatFloat(ffDecimal, 3)]

    app.message(buf)

    app.benchmark.status(false)
    app.forceRedraw()

proc main(): int =
  var app = newApp(pix_format_bgr24, flipY)
  app.caption("AGG Example. Line Join")

  if app.init(frameWidth, frameHeight, {window_resize}, "graph_test"):
    return app.run()

  result = 1

discard main()
