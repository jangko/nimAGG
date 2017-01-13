import agg_basics, agg_rendering_buffer, agg_pixfmt_rgb, strutils

type
  RendererBase*[PixFmt] = object
    ren: ptr PixFmt
    clipBox: RectI

template getColorType*[PixFmt](x: typedesc[RendererBase[PixFmt]]): typedesc = getColorType(PixFmt.type)

proc initRendererBase*[PixFmt](ren: var PixFmt): RendererBase[PixFmt] =
  result.ren = ren.addr
  result.clipBox = initRectI(0, 0, ren.width() - 1, ren.height() - 1)

proc attach*[PixFmt](self: var RendererBase[PixFmt], ren: var PixFmt) =
  self.ren = ren.addr
  self.clipBox = initRectI(0, 0, ren.width() - 1, ren.height() - 1)

proc getRen*[PixFmt](self: RendererBase[PixFmt]): PixFmt = self.ren

proc width*[PixFmt](self: RendererBase[PixFmt]): int = self.ren[].width()
proc height*[PixFmt](self: RendererBase[PixFmt]): int = self.ren[].height()

proc isClipBox*[PixFmt](self: var RendererBase[PixFmt], x1, y1, x2, y2: int): bool =
  var cb = initRectI(x1, y1, x2, y2)
  cb.normalize()
  if cb.clip(initRectI(0, 0, self.width() - 1, self.height() - 1)):
    self.clipBox = cb
    return true

  self.clipBox.x1 = 1
  self.clipBox.y1 = 1
  self.clipBox.x2 = 0
  self.clipBox.y2 = 0
  result = false

proc resetClipping*[PixFmt](self: var RendererBase[PixFmt], visibility: bool) =
  if visibility:
    self.clipBox.x1 = 0
    self.clipBox.y1 = 0
    self.clipBox.x2 = self.width() - 1
    self.clipBox.y2 = self.height() - 1
  else:
    self.clipBox.x1 = 1
    self.clipBox.y1 = 1
    self.clipBox.x2 = 0
    self.clipBox.y2 = 0

proc clipBoxNaked*[PixFmt](self: var RendererBase[PixFmt], x1, y1, x2, y2: int) =
  self.clipBox.x1 = x1
  self.clipBox.y1 = y1
  self.clipBox.x2 = x2
  self.clipBox.y2 = y2

proc inbox*[PixFmt](self: RendererBase[PixFmt], x, y: int): bool =
  result = x >= self.clipBox.x1 and y >= self.clipBox.y1 and
           x <= self.clipBox.x2 and y <= self.clipBox.y2

proc getClipBox*[PixFmt](self: RendererBase[PixFmt]): RectI = self.clipBox
proc xmin*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.x1
proc ymin*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.y1
proc xmax*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.x2
proc ymax*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.y2

proc boundingClipBox*[PixFmt](self: RendererBase[PixFmt]): RectI = self.clipBox
proc boundingXmin*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.x1
proc boundingYmin*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.y1
proc boundingXmax*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.x2
proc boundingYmax*[PixFmt](self: RendererBase[PixFmt]): int = self.clipBox.y2

proc clear*[PixFmt, ColorT](self: var RendererBase[PixFmt], c: ColorT) =
  when getColorType(PixFmt) isnot ColorT:
    var c = construct(getColorType(PixFmt), c)
  
  if self.width() != 0:
    for y in 0.. <self.height():
      self.ren[].copyHline(0, y, self.width(), c)

proc copyPixel*[PixFmt, ColorT](self: var RendererBase[PixFmt], x, y: int, c: ColorT) =
  if self.inbox(x, y):
    self.ren[].copyPixel(x, y, c)

proc blendPixel*[PixFmt, ColorT](self: var RendererBase[PixFmt], x, y: int, c: ColorT, cover: CoverType) =
  if self.inbox(x, y):
    self.ren[].blendPixel(x, y, c, cover)

proc pixel*[PixFmt](self: var RendererBase[PixFmt], x, y: int): auto =
  result = if self.inbox(x, y): self.ren[].pixel(x, y) else: getColorType(PixFmt).noColor()

proc copyHLine*[PixFmt, ColorT](self: RendererBase[PixFmt], x1, y, x2: int, c: ColorT) =
  var
    x1 = x1
    x2 = x2

  if x1 > x2: swap(x1, x2)
  if y  > self.ymax(): return
  if y  < self.ymin(): return
  if x1 > self.xmax(): return
  if x2 < self.xmin(): return

  if x1 < self.xmin(): x1 = self.xmin()
  if x2 > self.xmax(): x2 = self.xmax()

  self.ren[].copyHLine(x1, y, x2 - x1 + 1, c)


proc copyVLine*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y1, y2: int, c: ColorT) =
  var
    y1 = y1
    y2 = y2

  if y1 > y2: swap(y1, y2)
  if x > self.xmax(): return
  if x < self.xmin(): return
  if y1 > self.ymax(): return
  if y2 < self.ymin(): return

  if y1 < self.ymin(): y1 = self.ymin()
  if y2 > self.ymax(): y2 = self.ymax()

  self.ren[].copyVLine(x, y1, y2 - y1 + 1, c)

proc blendHline*[PixFmt, ColorT](self: RendererBase[PixFmt], x1, y, x2: int, c: ColorT, cover: CoverType) =
  var
    x1 = x1
    x2 = x2

  if x1 > x2: swap(x1, x2)
  if y  > self.ymax(): return
  if y  < self.ymin(): return
  if x1 > self.xmax(): return
  if x2 < self.xmin(): return

  if x1 < self.xmin(): x1 = self.xmin()
  if x2 > self.xmax(): x2 = self.xmax()

  self.ren[].blendHline(x1, y, x2 - x1 + 1, c, cover)

proc blendVline*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y1, y2: int, c: ColorT, cover: CoverType) =
  var
    y1 = y1
    y2 = y2

  if y1 > y2: swap(y1, y2)
  if x > self.xmax(): return
  if x < self.xmin(): return
  if y1 > self.ymax(): return
  if y2 < self.ymin(): return

  if y1 < self.ymin(): y1 = self.ymin()
  if y2 > self.ymax(): y2 = self.ymax()

  self.ren[].blendVline(x, y1, y2 - y1 + 1, c, cover)

proc copyBar*[PixFmt, ColorT](self: RendererBase[PixFmt], x1, y1, x2, y2: int, c: ColorT) =
  var rc = initRectI(x1, y1, x2, y2)
  rc.normalize()
  if rc.clip(self.getClipBox()):
    for y in rc.y1..rc.y2:
      self.ren[].copyHLine(rc.x1, y, rc.x2 - rc.x1 + 1, c)

proc blendBar*[PixFmt, ColorT](self: RendererBase[PixFmt], x1, y1, x2, y2: int, c: ColorT, cover: CoverType) =
  var rc = initRectI(x1, y1, x2, y2)
  rc.normalize()
  if rc.clip(self.getClipBox()):
    for y in rc.y1..rc.y2:
      self.ren[].blendHline(rc.x1, y, rc.x2 - rc.x1 + 1, c, cover)

proc blendSolidHSpan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int, c: ColorT, covers: ptr CoverType) =
  if y > self.ymax(): return
  if y < self.ymin(): return

  var
    len = len
    x = x
    covers = covers

  if x < self.xmin():
    len -= self.xmin() - x
    if len <= 0: return
    inc(covers, self.xmin() - x)
    x = self.xmin()

  if x + len > self.xmax():
    len = self.xmax() - x + 1
    if len <= 0: return

  self.ren[].blendSolidHSpan(x, y, len, c, covers)

proc blendSolidVSpan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int, c: ColorT, covers: ptr CoverType) =
  if x > self.xmax(): return
  if x < self.xmin(): return

  var
    len = len
    covers = covers

  if y < self.ymin():
    len -= self.ymin() - y
    if len <= 0: return
    inc(covers, self.ymin() - y)
    y = self.ymin()

  if y + len > self.ymax():
    len = self.ymax() - y + 1
    if len <= 0: return

  self.ren[].blendSolidVSpan(x, y, len, c, covers)

proc copyColorHspan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int, colors: ptr ColorT) =
  if y > self.ymax(): return
  if y < self.ymin(): return

  var
    len = len
    colors = colors

  if x < self.xmin():
    let d = self.xmin() - x
    len -= d
    if len <= 0: return
    inc(colors, d)
    x = self.xmin()

  if x + len > self.xmax():
    len = self.xmax() - x + 1
    if len <= 0: return

  self.ren[].copyColorHspan(x, y, len, colors)

proc copyColorVspan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int, colors: ptr ColorT) =
  if x > self.xmax(): return
  if x < self.xmin(): return

  var
    len = len
    colors = colors

  if y < self.ymin():
    let d = self.ymin() - y
    len -= d
    if len <= 0: return
    inc(colors, d)
    y = self.ymin()

  if y + len > self.ymax():
    len = self.ymax() - y + 1;
    if len <= 0: return

  self.ren[].copyColorVspan(x, y, len, colors)

proc blendColorHspan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int,
  colors: ptr ColorT, covers: ptr CoverType, cover: CoverType = coverFull) =

  if y > self.ymax(): return
  if y < self.ymin(): return

  var
    len = len
    colors = colors
    covers = covers

  if x < self.xmin():
    let d = self.xmin() - x
    len -= d
    if len <= 0: return
    if covers != nil: inc(covers, d)
    inc(colors, d)
    x = self.xmin()

  if x + len > self.xmax():
    len = self.xmax() - x + 1;
    if len <= 0: return

  self.ren[].blendColorHspan(x, y, len, colors, covers, cover)

proc blendColorVspan*[PixFmt, ColorT](self: RendererBase[PixFmt], x, y, len: int,
  colors: ptr ColorT, covers: ptr CoverType, cover: CoverType = coverFull) =

  if x > self.xmax(): return
  if x < self.xmin(): return

  var
    len = len
    colors = colors
    covers = covers

  if y < self.ymin():
    let d = self.ymin() - y
    len -= d
    if len <= 0: return
    if covers != nil: inc(covers, d)
    inc(colors, d)
    y = self.ymin()

  if y + len > self.ymax():
    len = ymax() - y + 1
    if len <= 0: return

  self.ren[].blendColorVspan(x, y, len, colors, covers, cover)

proc clipRectArea*[PixFmt](self: RendererBase[PixFmt], dst, src: var RectI, wsrc, hsrc: int): RectI =
  var
    rc = initRectI(0,0,0,0)
    cb = self.getClipBox()

  inc cb.x2
  inc cb.y2

  if src.x1 < 0:
    dst.x1 -= src.x1
    src.x1 = 0

  if src.y1 < 0:
    dst.y1 -= src.y1
    src.y1 = 0

  if src.x2 > wsrc: src.x2 = wsrc
  if src.y2 > hsrc: src.y2 = hsrc

  if dst.x1 < cb.x1:
    src.x1 += cb.x1 - dst.x1
    dst.x1 = cb.x1

  if dst.y1 < cb.y1:
    src.y1 += cb.y1 - dst.y1
    dst.y1 = cb.y1

  if dst.x2 > cb.x2: dst.x2 = cb.x2
  if dst.y2 > cb.y2: dst.y2 = cb.y2

  rc.x2 = dst.x2 - dst.x1
  rc.y2 = dst.y2 - dst.y1

  if rc.x2 > src.x2 - src.x1: rc.x2 = src.x2 - src.x1
  if rc.y2 > src.y2 - src.y1: rc.y2 = src.y2 - src.y1
  result = rc

proc copyFrom*[PixFmt, RenBuf](self: RendererBase[PixFmt], src: RenBuf, rectSrcPtr: ptr RectI = nil, dx = 0, dy = 0) =
  var rsrc = initRectI(0, 0, src.width(), src.height())

  if rectSrcPtr != nil:
    rsrc.x1 = rectSrcPtr.x1
    rsrc.y1 = rectSrcPtr.y1
    rsrc.x2 = rectSrcPtr.x2 + 1
    rsrc.y2 = rectSrcPtr.y2 + 1

  # Version with xdst, ydst (absolute positioning)
  # rdst = initRectI(xdst, ydst, xdst + rsrc.x2 - rsrc.x1, ydst + rsrc.y2 - rsrc.y1)

  # Version with dx, dy (relative positioning)
  var
    rdst = RectI(rsrc.x1 + dx, rsrc.y1 + dy, rsrc.x2 + dx, rsrc.y2 + dy)
    rc = self.clipRectArea(rdst, rsrc, src.width(), src.height())

  if rc.x2 > 0:
    var incy = 1
    if rdst.y1 > rsrc.y1:
      inc(rsrc.y1, rc.y2 - 1)
      inc(rdst.y1, rc.y2 - 1)
      incy = -1

    while rc.y2 > 0:
      self.ren[].copyFrom(src, rdst.x1, rdst.y1, rsrc.x1, rsrc.y1, rc.x2)
      inc(rdst.y1, incy)
      inc(rsrc.y1, incy)
      dec rc.y2

proc blendFrom*[PixFmt, SrcPixelFormatRenderer](self: RendererBase[PixFmt], src: SrcPixelFormatRenderer,
  rectSrcPtr: ptr RectI = nil, dx = 0, dy = 0, cover: CoverType = coverFull) =
  var rsrc = initRectI(0, 0, src.width(), src.height())
  if rectSrcPtr != nil:
    rsrc.x1 = rectSrcPtr.x1
    rsrc.y1 = rectSrcPtr.y1
    rsrc.x2 = rectSrcPtr.x2 + 1
    rsrc.y2 = rectSrcPtr.y2 + 1

  # Version with xdst, ydst (absolute positioning)
  #rdst = initRectI(xdst, ydst, xdst + rsrc.x2 - rsrc.x1, ydst + rsrc.y2 - rsrc.y1)

  # Version with dx, dy (relative positioning)
  var
    rdst = initRectI(rsrc.x1 + dx, rsrc.y1 + dy, rsrc.x2 + dx, rsrc.y2 + dy)
    rc = self.clipRectArea(rdst, rsrc, src.width(), src.height())

  if rc.x2 > 0:
    var incy = 1
    if rdst.y1 > rsrc.y1:
      rsrc.y1 += rc.y2 - 1
      rdst.y1 += rc.y2 - 1
      dec incy
    while rc.y2 > 0:
      var rw = src.row(rsrc.y1)
      if rw.data != nil:
        var
          x1src = rsrc.x1
          x1dst = rdst.x1
          len   = rc.x2
        if rw.x1 > x1src:
          x1dst += rw.x1 - x1src
          len   -= rw.x1 - x1src
          x1src  = rw.x1
        if len > 0:
          if x1src + len-1 > rw.x2:
            len -= x1src + len - rw.x2 - 1
          if len > 0:
            self.ren[].blendFrom(src, x1dst, rdst.y1, x1src, rsrc.y1, len, cover)
      inc(rdst.y1, incy)
      inc(rsrc.y1, incy)
      inc rc.y2

proc blendFromColor*[PixFmt, SrcPixelFormatRenderer, ColorT](self: RendererBase[PixFmt], src: SrcPixelFormatRenderer,
  color: ColorT, rectSrcPtr: ptr RectI = nil,  dx = 0, dy = 0, cover: CoverType = coverFull) =
  var rsrc = initRectI(0, 0, src.width(), src.height())
  if rectSrcPtr != nil:
    rsrc.x1 = rectSrcPtr.x1
    rsrc.y1 = rectSrcPtr.y1
    rsrc.x2 = rectSrcPtr.x2 + 1
    rsrc.y2 = rectSrcPtr.y2 + 1

  # Version with xdst, ydst (absolute positioning)
  #rdst = initRectI(xdst, ydst, xdst + rsrc.x2 - rsrc.x1, ydst + rsrc.y2 - rsrc.y1)

  # Version with dx, dy (relative positioning)
  var
    rdst = initRectI(rsrc.x1 + dx, rsrc.y1 + dy, rsrc.x2 + dx, rsrc.y2 + dy)
    rc = self.clipRectArea(rdst, rsrc, src.width(), src.height())

  if rc.x2 > 0:
    var incy = 1
    if rdst.y1 > rsrc.y1:
      rsrc.y1 += rc.y2 - 1
      rdst.y1 += rc.y2 - 1
      dec incy
    while rc.y2 > 0:
      var rw = src.row(rsrc.y1)
      if rw.data != nil:
        var
          x1src = rsrc.x1
          x1dst = rdst.x1
          len   = rc.x2
        if rw.x1 > x1src:
          x1dst += rw.x1 - x1src
          len   -= rw.x1 - x1src
          x1src  = rw.x1
        if len > 0:
          if x1src + len-1 > rw.x2:
            len -= x1src + len - rw.x2 - 1
          if len > 0:
            self.ren[].blendFromColor(src, color, x1dst, rdst.y1, x1src, rsrc.y1, len, cover)
      inc(rdst.y1, incy)
      inc(rsrc.y1, incy)
      inc rc.y2

proc blendFromLut*[PixFmt, SrcPixelFormatRenderer, ColorT](self: RendererBase[PixFmt], src: SrcPixelFormatRenderer,
  colorLut: ptr ColorT, rectSrcPtr: ptr RectI = nil, dx = 0, dy = 0, cover: CoverType = coverFull) =
  var rsrc = initRectI(0, 0, src.width(), src.height())
  if rectSrcPtr != nil:
    rsrc.x1 = rectSrcPtr.x1
    rsrc.y1 = rectSrcPtr.y1
    rsrc.x2 = rectSrcPtr.x2 + 1
    rsrc.y2 = rectSrcPtr.y2 + 1

  # Version with xdst, ydst (absolute positioning)
  #rdst = initRectI(xdst, ydst, xdst + rsrc.x2 - rsrc.x1, ydst + rsrc.y2 - rsrc.y1)

  # Version with dx, dy (relative positioning)
  var
    rdst = initRectI(rsrc.x1 + dx, rsrc.y1 + dy, rsrc.x2 + dx, rsrc.y2 + dy)
    rc = self.clipRectArea(rdst, rsrc, src.width(), src.height())

  if rc.x2 > 0:
    var incy = 1
    if rdst.y1 > rsrc.y1:
      rsrc.y1 += rc.y2 - 1
      rdst.y1 += rc.y2 - 1
      dec incy
    while rc.y2 > 0:
      var rw = src.row(rsrc.y1)
      if rw.data != nil:
        var
          x1src = rsrc.x1
          x1dst = rdst.x1
          len   = rc.x2
        if rw.x1 > x1src:
          x1dst += rw.x1 - x1src
          len   -= rw.x1 - x1src
          x1src  = rw.x1
        if len > 0:
          if x1src + len-1 > rw.x2:
            len -= x1src + len - rw.x2 - 1
          if len > 0:
            self.ren[].blendFromLut(src, colorLut, x1dst, rdst.y1, x1src, rsrc.y1, len, cover)
      inc(rdst.y1, incy)
      inc(rsrc.y1, incy)
      inc rc.y2
