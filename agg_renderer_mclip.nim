import agg_basics, agg_renderer_base, agg_color_rgba, agg_rendering_buffer

type
  RendererMclip*[PixFmt] = object
    mRen: RendererBase[PixFmt]
    mClip: seq[RectI]
    mCurrCb: uint
    mBounds: RectI

proc initRendererMclip*[PixFmt](pixf: var PixFmt): RendererMclip[PixFmt] =
  result.mRen = initRendererBase(pixf)
  result.mCurrCb = 0
  result.mBounds = initRectI(result.mRen.xmin(), result.mRen.ymin(), result.mRen.xmax(), result.mRen.ymax())
  result.mClip = @[]

proc attach*[PixFmt](self: var RendererMclip[PixFmt], pixf: var PixFmt) =
  self.mRen.attach(pixf)
  self.resetClipping(true)

proc ren*[PixFmt](self: RendererMclip[PixFmt]): var PixFmt = self.mRen.ren()

proc width*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.width()
proc height*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.height()

proc clipBox*[PixFmt](self: RendererMclip[PixFmt]): var RectI = self.mRen.clipBox()
proc xmin*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.xmin()
proc ymin*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.ymin()
proc xmax*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.xmax()
proc ymax*[PixFmt](self: RendererMclip[PixFmt]): int = self.mRen.ymax()

proc boundingClipBox*[PixFmt](self: RendererMclip[PixFmt]): var REctI = self.mBounds
proc boundingXmin*[PixFmt](self: RendererMclip[PixFmt]): int = self.mBounds.x1
proc boundingYmin*[PixFmt](self: RendererMclip[PixFmt]): int = self.mBounds.y1
proc boundingXmax*[PixFmt](self: RendererMclip[PixFmt]): int = self.mBounds.x2
proc boundingYmax*[PixFmt](self: RendererMclip[PixFmt]): int = self.mBounds.y2

proc firstClipBox*[PixFmt](self: var RendererMclip[PixFmt]) =
  self.mCurrCb = 0
  if self.mClip.len != 0:
    let cb = self.mClip[0].addr
    self.mRen.clipboxNaked(cb.x1, cb.y1, cb.x2, cb.y2)

proc nextClipBox*[PixFmt](self: var RendererMclip[PixFmt]): bool =
  inc self.mCurrCb
  if self.mCurrCb < self.mClip.len:
    let cb = self.mClip[self.mCurrCb].addr
    self.mRen.clipboxNaked(cb.x1, cb.y1, cb.x2, cb.y2)
    return true
  result = false

proc resetClipping*[PixFmt](self: var RendererMclip[PixFmt], visibility: bool) =
  self.mRen.resetClipping(visibility)
  self.mClip.removeAll()
  self.mCurrCb = 0
  self.mBounds = self.mRen.clipBox()

proc addClipBox*[PixFmt](self: var RendererMclip[PixFmt], x1, y1, x2, y2: int) =
  var cb = initRectI(x1, y1, x2, y2)
  cb.normalize()
  if cb.clip(initRectI(0, 0, self.width() - 1, self.height() - 1)):
    self.mClip.add(cb)
    if cb.x1 < self.mBounds.x1: self.mBounds.x1 = cb.x1
    if cb.y1 < self.mBounds.y1: self.mBounds.y1 = cb.y1
    if cb.x2 > self.mBounds.x2: self.mBounds.x2 = cb.x2
    if cb.y2 > self.mBounds.y2: self.mBounds.y2 = cb.y2

proc clear*[PixFmt, ColorT](self: var RendererMclip[PixFmt], c: ColorT) =
  self.mRen.clear(c)

proc copyPixel*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y: int, c: ColorT) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    if self.mRen.inbox(x, y):
      self.mRen.ren().copyPixel(x, y, c)
      break

proc blendPixel*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y: int, c: ColorT, cover: CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    if self.mRen.inbox(x, y):
      self.mRen.ren().blendPixel(x, y, c, cover)
      break

proc pixel*[PixFmt](self: var RendererMclip[PixFmt], x, y: int): auto =
  type ColorT = getColorT(PixFmt)
  if self.mRen.inbox(x, y):
    return self.mRen.ren().pixel(x, y)
  result = noColor(ColorT)

proc copyHline*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x1, y, x2: int, c: ColorT) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.copyHline(x1, y, x2, c)

proc copyVline*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y1, y2: int, c: ColorT) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.copyVline(x, y1, y2, c)

proc blendHline*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x1, y, x2: int, c: ColorT, cover: CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendHline(x1, y, x2, c, cover)

proc blendVline*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y1, y2: int, c: ColorT, cover: CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendVline(x, y1, y2, c, cover)

proc copyBar*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x1, y1, x2, y2: int, c: ColorT) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.copyBar(x1, y1, x2, y2, c)

proc blendBar*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x1, y1, x2, y2: int, c: ColorT, cover: CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendBar(x1, y1, x2, y2, c, cover)

proc blendSolidHspan*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y, len: int, c: ColorT, covers: ptr CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendSolidHspan(x, y, len, c, covers)

proc blendSolidVspan*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y, len: int, c: ColorT, covers: ptr CoverType) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendSolidVspan(x, y, len, c, covers)

proc copyColorHspan*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y, len: int, colors: ptr ColorT) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.copyColorHspan(x, y, len, colors)

proc blendColorHspan*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y, len: int, colors: ptr ColorT, covers: ptr CoverType, cover: CoverType = coverFull) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendColorHspan(x, y, len, colors, covers, cover)

proc blendColorVspan*[PixFmt, ColorT](self: var RendererMclip[PixFmt], x, y, len: int, colors: ptr ColorT, covers: ptr CoverType, cover: CoverType = coverFull) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendColorVspan(x, y, len, colors, covers, cover)

proc copyFrom*[PixFmt](self: var RendererMclip[PixFmt], src: var RenderingBuffer, rc: ptr RectI = nil, xTo = 0, yTo = 0) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.copyFrom(src, rc, xTo, yTo)

proc blendFrom*[PixFmt,SrcPixelFormatRenderer](self: var RendererMclip[PixFmt], src: var SrcPixelFormatRenderer,
  rectSrcPtr: ptr RectI = nil, dx = 0, dy = 0, cover: CoverType = coverFull) =
  self.firstClipBox()
  doWhile self.nextCipBox():
    self.mRen.blendFrom(src, rectSrcPtr, dx, dy, cover)
