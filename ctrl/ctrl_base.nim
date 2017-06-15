import agg / [trans_affine, basics, renderer_scanline]

type
  CtrlBase* = ref object of RootObj
    m*: RectD
    mFlipY*: bool
    mMtx*: ptr TransAffine
    mEnabled*: bool

proc init*(self: CtrlBase, x1, y1, x2, y2: float64, flipY: bool) =
  self.m = initRectD(x1,y1,x2,y2)
  self.mFlipY = flipY
  self.mMtx = nil
  self.mEnabled = true

proc isEnabled*(self: CtrlBase): bool = self.mEnabled

proc isEnabled*(self: CtrlBase, enabled: bool) =
  self.mEnabled = enabled

proc transform*(self: CtrlBase, mtx: var TransAffine) =
  self.mMtx = mtx.addr

proc noTransform*(self: CtrlBase) =
  self.mMtx = nil

proc transformXY*(self: CtrlBase, x, y: var float64) =
  if self.mFlipY:
    y = self.m.y1 + self.m.y2 - y

  if self.mMtx != nil:
    self.mMtx[].transform(x, y)

proc inverseTransformXY*(self: CtrlBase, x, y: var float64) =
  if self.mMtx != nil:
    self.mMtx[].inverseTransform(x, y)

  if self.mFlipY:
    y = self.m.y1 + self.m.y2 - y

proc scale*(self: CtrlBase): float64 =
  result = if self.mMtx != nil: self.mMtx[].scale() else: 1.0

method inRect*(self: CtrlBase, x, y: float64): bool {.base.} = discard
method onMouseButtonDown*(self: CtrlBase, x, y: float64): bool {.base.} = discard
method onMouseButtonUp*(self: CtrlBase, x, y: float64): bool {.base.} = discard
method onMouseMove*(self: CtrlBase, x, y: float64, buttonFlag: bool): bool {.base.} = discard
method onArrowKeys*(self: CtrlBase, left, right, down, up: bool): bool {.base.} = discard

proc renderCtrl*[Rasterizer, Scanline, Renderer, Ctrl](ras: var Rasterizer,
  sl: var Scanline, ren: var Renderer, c: var Ctrl) =
  for i in 0.. <c.numPaths():
    ras.reset()
    ras.addPath(c, i)
    renderScanlinesAASolid(ras, sl, ren, c.color(i))

proc renderCtrlRs*[Rasterizer, Scanline, Renderer, Ctrl](ras: var Rasterizer,
  sl: var Scanline, ren: var Renderer, c: var Ctrl) =
  for i in 0.. <c.numPaths():
    ras.reset()
    ras.addPath(c, i)
    ren.color(c.color(i))
    renderScanlines(ras, sl, ren)
