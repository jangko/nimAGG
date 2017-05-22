import strutils, nimBMP

include system/timers

type
  PixelMap[T] = object
    mWidth : int
    mHeight: int
    mPixElem: int
    mBuffer: seq[T]

proc initPixelMap[T](): PixelMap[T] =
  discard

proc create[T](self: var PixelMap[T], width, height, PixElem: int) =
  self.mWidth = width
  self.mHeight = height
  self.mPixElem = PixElem
  self.mBuffer = newSeq[T](width * height * PixElem)

proc width[T](self: PixelMap[T]): int =
  self.mWidth

proc height[T](self: PixelMap[T]): int =
  self.mHeight

proc stride[T](self: PixelMap[T]): int =
  self.mWidth * self.mPixElem

proc buf[T](self: var PixelMap[T]): ptr T =
  self.mBuffer[0].addr

proc save(self: PixelMap[uint8], fn: string): bool =
  if self.mPixElem == 1:
    saveBMP8(fn, self.mBuffer, self.mWidth, self.mHeight)
  elif self.mPixElem == 4:
    saveBMP32(fn, self.mBuffer, self.mWidth, self.mHeight)
  elif self.mPixElem == 3:
    saveBMP24(fn, self.mBuffer, self.mWidth, self.mHeight)
  else:
    doAssert(false)

proc load(self: var PixelMap[uint8], fn: string): bool =
  var bmp = loadBmp24(fn, seq[uint8])
  self.mWidth  = bmp.width
  self.mHeight = bmp.height
  self.mBuffer = bmp.data
  self.mPixElem = 3
  result = bmp.width != 0 and bmp.height != 0

type
  PlatformSpecific[T] = object
    mFormat: PixFormat
    mSysFormat: PixFormat
    mFlipY: bool
    mPixElem: int
    mSysPixElem: int
    mWinPmap: PixelMap[T]
    mImgPmap: array[maxImages, PixelMap[T]]
    mStartTime: Ticks
    mFileName: string

proc initPlatformSpecific[T](format: PixFormat, flipY: bool): PlatformSpecific[T] =
  result.mFormat = format
  result.mSysFormat = pix_format_undefined
  result.mFlipY = flipY
  result.mPixElem = 0
  result.mSysPixElem = 0

  case result.mFormat
  of pix_format_gray8:
    result.mSysFormat = pix_format_gray8
    result.mPixElem = 1
    result.mSysPixElem = 1
  of pix_format_gray16:
    result.mSysFormat = pix_format_gray8
    result.mPixElem = 1
    result.mSysPixElem = 1
  of pix_format_rgb565, pix_format_rgb555:
    result.mSysFormat = pix_format_rgb24
    result.mPixElem = 2
    result.mSysPixElem = 3
  of pix_format_rgbAAA, pix_format_bgrAAA,
     pix_format_rgbBBA, pix_format_bgrABB:
    result.mSysFormat = pix_format_rgb24
    result.mPixElem = 2
    result.mSysPixElem = 3
  of pix_format_rgb24, pix_format_bgr24:
    result.mSysFormat = pix_format_rgb24
    result.mPixElem = 3
    result.mSysPixElem = 3
  of pix_format_rgb48, pix_format_bgr48:
    result.mSysFormat = pix_format_rgb24
    result.mPixElem = 3
    result.mSysPixElem = 3
  of pix_format_bgra32, pix_format_abgr32,
     pix_format_argb32, pix_format_rgba32:
    result.mSysFormat = pix_format_rgba32
    result.mPixElem = 4
    result.mSysPixElem = 4
  of pix_format_bgra64, pix_format_abgr64,
     pix_format_argb64, pix_format_rgba64:
    result.mSysFormat = pix_format_rgba32
    result.mPixElem = 4
    result.mSysPixElem = 4
  else: discard

proc createPmap[T,RenBuf](self: var PlatformSpecific[T], w, h: int, wnd: var RenBuf) =
  self.mWinPmap.create(w, h, self.mPixElem)
  let stride = if self.mFlipY: -self.mWinPmap.stride() else: self.mWinPmap.stride()
  wnd.attach(self.mWinPmap.buf(), self.mWinPmap.width(), self.mWinPmap.height(), stride)

proc convertPmap[RenBuf](dst, src: var RenBuf, format: PixFormat) =
  case format
  of pix_format_gray16: colorConv(dst, src, color_conv_gray16_to_gray8)
  of pix_format_rgb565: colorConv(dst, src, color_conv_rgb565_to_rgb24)
  of pix_format_rgb555: colorConv(dst, src, color_conv_rgb555_to_rgb24)
  of pix_format_rgbAAA: colorConv(dst, src, color_conv_rgbAAA_to_rgb24)
  of pix_format_bgrAAA: colorConv(dst, src, color_conv_bgrAAA_to_rgb24)
  of pix_format_rgbBBA: colorConv(dst, src, color_conv_rgbBBA_to_rgb24)
  of pix_format_bgrABB: colorConv(dst, src, color_conv_bgrABB_to_rgb24)
  of pix_format_bgr24:  colorConv(dst, src, color_conv_bgr24_to_rgb24)
  of pix_format_rgb48:  colorConv(dst, src, color_conv_rgb48_to_rgb24)
  of pix_format_bgr48:  colorConv(dst, src, color_conv_bgr48_to_rgb24)
  of pix_format_argb32: colorConv(dst, src, color_conv_argb32_to_rgba32)
  of pix_format_abgr32: colorConv(dst, src, color_conv_abgr32_to_rgba32)
  of pix_format_bgra32: colorConv(dst, src, color_conv_bgra32_to_rgba32)
  of pix_format_bgra64: colorConv(dst, src, color_conv_bgra64_to_rgba32)
  of pix_format_abgr64: colorConv(dst, src, color_conv_abgr64_to_rgba32)
  of pix_format_argb64: colorConv(dst, src, color_conv_argb64_to_rgba32)
  of pix_format_rgba64: colorConv(dst, src, color_conv_rgba64_to_rgba32)
  else: discard

proc savePmap[T,RenBuf](self: var PlatformSpecific[T], fn: string, idx: int, src: var RenBuf): bool =
  if self.mSysFormat == self.mFormat:
    return self.mImgPmap[idx].save(fn)
  else:
    var rbuf = initRenderingBuffer()
    var pmap = initPixelMap[uint8]()

    pmap.create(self.mImgPmap[idx].width(), self.mImgPmap[idx].height(), self.mSysPixElem)
    rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: -pmap.stride() else: pmap.stride())
    convertPmap(rbuf, src, self.mFormat)
    return pmap.save(fn)

proc loadPmap[T,RenBuf](self: var PlatformSpecific[T], fn: string, idx: int, dst: var RenBuf): bool =
  type ValueT = getValueT(RenBuf)
  var
    pmap= initPixelMap[ValueT]()
    src = initRenderingBuffer()

  if not pmap.load(fn): return false

  src.attach(pmap.buf(),
             pmap.width(),
             pmap.height(),
             if self.mFlipY: -pmap.stride() else: pmap.stride())

  self.mImgPmap[idx].create(pmap.width(), pmap.height(), self.mSysPixElem)
  dst.attach(self.mImgPmap[idx].buf(),
             self.mImgPmap[idx].width(),
             self.mImgPmap[idx].height(),
             if self.mFlipY: -self.mImgPmap[idx].stride() else: self.mImgPmap[idx].stride())

  case self.mFormat
  of pix_format_gray8:  color_conv(dst, src, color_conv_rgb24_to_gray8)
  of pix_format_gray16: color_conv(dst, src, color_conv_rgb24_to_gray16)
  of pix_format_rgb555: color_conv(dst, src, color_conv_rgb24_to_rgb555)
  of pix_format_rgb565: color_conv(dst, src, color_conv_rgb24_to_rgb565)
  of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_rgb24)
  of pix_format_bgr24:  color_conv(dst, src, color_conv_rgb24_to_bgr24)
  of pix_format_rgb48:  color_conv(dst, src, color_conv_rgb24_to_rgb48)
  of pix_format_bgr48:  color_conv(dst, src, color_conv_rgb24_to_bgr48)
  of pix_format_abgr32: color_conv(dst, src, color_conv_rgb24_to_abgr32)
  of pix_format_argb32: color_conv(dst, src, color_conv_rgb24_to_argb32)
  of pix_format_bgra32: color_conv(dst, src, color_conv_rgb24_to_bgra32)
  of pix_format_rgba32: color_conv(dst, src, color_conv_rgb24_to_rgba32)
  of pix_format_abgr64: color_conv(dst, src, color_conv_rgb24_to_abgr64)
  of pix_format_argb64: color_conv(dst, src, color_conv_rgb24_to_argb64)
  of pix_format_bgra64: color_conv(dst, src, color_conv_rgb24_to_bgra64)
  of pix_format_rgba64: color_conv(dst, src, color_conv_rgb24_to_rgba64)
  else: discard
  result = true

proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  type ValueT = getValueT(R)
  self.mSpecific = initPlatformSpecific[ValueT](format, flipY)
  self.mFormat = format
  self.mBpp    = self.mSpecific.mPixElem * sizeof(T)
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY = flipY
  self.mInitialWidth = 10
  self.mInitialHeight = 10
  self.mCaption = "Anti-Grain Geometry Application"
  self.mResizeMtx = initTransAffine()

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap

proc loadImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  if idx < maxImages:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"
    return self.mSpecific.loadPmap(fileName, idx, self.mRbufImage[idx])
  result = true

proc saveImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  if idx < maxImages:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"
    return self.mSpecific.savePmap(fileName, idx, self.mRbufImage[idx])
  result = true

proc createImg[T,R](self: GenericPlatform[T,R], idx: int, w = 0, h = 0): bool =
  var
    w = w
    h = h

  if idx < maxImages:
    if w  == 0: w = self.mSpecific.mWinPmap.width()
    if h == 0: h = self.mSpecific.mWinPmap.height()

    self.mSpecific.mImgPmap[idx].create(w, h, self.mSpecific.mPixElem)
    var stride = self.mSpecific.mImgPmap[idx].stride()
    self.mRbufImage[idx].attach(self.mSpecific.mImgPmap[idx].buf(),
                                self.mSpecific.mImgPmap[idx].width(),
                                self.mSpecific.mImgPmap[idx].height(),
                                if self.mFlipY: -stride else: stride)
    return true
  result = false

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
  if self.mSpecific.mSysFormat == pix_format_undefined:
    return false

  self.mWindowFlags = flags

  self.mSpecific.createPmap(width, height, self.mRBufWindow)
  self.mInitialWidth = width
  self.mInitialHeight = height
  self.onInit()

  if paramCount() > 0:
    if paramStr(1) == "-v":
      self.onDraw()
      self.copyWindowToImg(maxImages - 1)
      discard self.saveImg(maxImages - 1, fileName)
      return false

  result = true

proc run[T,R](self: GenericPlatform[T,R]): int =
  self.onDraw()
  result = 0

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  discard

proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  discard

proc imgExt[T,R](self: GenericPlatform[T,R]): string = ".bmp"

proc rawDisplayHandler[T,R](self: GenericPlatform[T,R]): pointer =
  result = nil

proc message[T,R](self: GenericPlatform[T,R], msg: string) =
  echo msg

proc startTimer[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mStartTime = getTicks()

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  result = float64(getTicks() - self.mSpecific.mStartTime) / 1000_000.0

proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName
