import strutils, times, nimBMP

type
  PixelMap[T] = object
    mWidth : int
    mHeight: int
    mPixElem: int
    mBuffer: seq[T]

proc create[T](self: var PixelMap[T], width, height, PixElem) =
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
  
type
  PlatformSpecific[T] = object
    mFormat: PixFormat
    mSysFormat: PixFormat
    mFlipY: bool
    mPixElem: int
    mSysPixElem: int
    mWinPmap: PixelMap[T]
    mImgPmap: array[maxImages, PixelMap[T]]
    mStartTime: float64

proc initPlatformSpecific[T](format: PixFormat[T], flipY: bool): PlatformSpecific =
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
    result.mPixElem = 2
    result.mSysBpp = 8
  of pix_format_rgb565, pix_format_rgb555:
    result.mSysFormat = pix_format_rgb555
    result.mBpp = 16
    result.mSysBpp = 16
  of pix_format_rgbAAA, pix_format_bgrAAA,
     pix_format_rgbBBA, pix_format_bgrABB:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 32
    result.mSysBpp = 24
  of pix_format_rgb24, pix_format_bgr24:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 24
    result.mSysBpp = 24
  of pix_format_rgb48, pix_format_bgr48:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 48
    result.mSysBpp = 24
  of pix_format_bgra32, pix_format_abgr32,
     pix_format_argb32, pix_format_rgba32:
    result.mSysFormat = pix_format_bgra32
    result.mBpp = 32
    result.mSysBpp = 32
  of pix_format_bgra64, pix_format_abgr64,
     pix_format_argb64, pix_format_rgba64:
    result.mSysFormat = pix_format_bgra32
    result.mBpp = 64
    result.mSysBpp = 32
  else: discard

proc createPmap[T,RenBuf](self: var PlatformSpecific[T], width, height: int, wnd: var RenBuf) =
  self.mWinPmap.create(width, height, self.mBpp)
  let stride = if self.mFlipY: self.mWinPmap.stride() else: -self.mWinPmap.stride()
  wnd.attach(self.mWinPmap.buf(), self.mWinPmap.width(),
             self.mWinPmap.height(), stride)

proc convertPmap[RenBuf](dst, src: var RenBuf, format: PixFormat) =
  case format
  of pix_format_gray8: discard
  of pix_format_gray16: color_conv(dst, src, color_conv_gray16_to_gray8)
  of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_rgb555)
  of pix_format_rgbAAA: color_conv(dst, src, color_conv_rgbAAA_to_bgr24)
  of pix_format_bgrAAA: color_conv(dst, src, color_conv_bgrAAA_to_bgr24)
  of pix_format_rgbBBA: color_conv(dst, src, color_conv_rgbBBA_to_bgr24)
  of pix_format_bgrABB: color_conv(dst, src, color_conv_bgrABB_to_bgr24)
  of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_bgr24)
  of pix_format_rgb48:  color_conv(dst, src, color_conv_rgb48_to_bgr24)
  of pix_format_bgr48:  color_conv(dst, src, color_conv_bgr48_to_bgr24)
  of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_bgra32)
  of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_bgra32)
  of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_bgra32)
  of pix_format_bgra64: color_conv(dst, src, color_conv_bgra64_to_bgra32)
  of pix_format_abgr64: color_conv(dst, src, color_conv_abgr64_to_bgra32)
  of pix_format_argb64: color_conv(dst, src, color_conv_argb64_to_bgra32)
  of pix_format_rgba64: color_conv(dst, src, color_conv_rgba64_to_bgra32)
  else: discard

proc displayPmap[T,RenBuf](self: var PlatformSpecific[T], dc: HDC, src: var RenBuf) =
  if self.mSysFormat == self.mFormat:
    self.mWinPmap.draw(dc)
  else:
    var
      pmap = initPixelMap()
      rbuf = construct(RenBuf)

    pmap.create(self.mWinPmap.width(), self.mWinPmap.height(), self.mSysBpp)
    rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
    convertPmap(rbuf, src, self.mFormat)
    pmap.draw(dc)

proc savePmap[T,RenBuf](self: var PlatformSpecific[T], fn: string, idx: int, src: var RenBuf): bool =
  if self.mSysFormat == self.mFormat:
    return self.mImgPmap[idx].saveAsBmp(fn)
  else:
    var
      pmap = initPixelMap()
      rbuf = construct(RenBuf)

    pmap.create(self.mImgPmap[idx].width(), self.mImgPmap[idx].height(), self.mSysBpp)
    rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
    convertPmap(rbuf, src, self.mFormat)
    return pmap.saveAsBmp(fn)

proc loadPmap[T,RenBuf](self: var PlatformSpecific[T], fn: string, idx: int, dst: var RenBuf): bool =
  var
    pmap= initPixelMap()
    rbuf = construct(RenBuf)

  if not pmap.loadFromBmp(fn): return false

  rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
  self.mImgPmap[idx].create(pmap.width(), pmap.height(), self.mBpp, 0)

  dst.attach(self.mImgPmap[idx].buf(),
             self.mImgPmap[idx].width(),
             self.mImgPmap[idx].height(),
             if self.mFlipY: self.mImgPmap[idx].stride() else: -self.mImgPmap[idx].stride())

  case self.mFormat
  of pix_format_gray8:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_gray8)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_gray8)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_gray8)
    else: discard

  of pix_format_gray16:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_gray16)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_gray16)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_gray16)
    else: discard
  of pix_format_rgb555:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgb555)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgb555)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgb555)
    else: discard
  of pix_format_rgb565:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgb565)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgb565)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgb565)
    else: discard
  of pix_format_rgb24:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgb24)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgb24)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgb24)
    else: discard
  of pix_format_bgr24:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_bgr24)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_bgr24)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_bgr24)
    else: discard
  of pix_format_rgb48:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgb48)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgb48)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgb48)
    else: discard
  of pix_format_bgr48:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_bgr48)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_bgr48)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_bgr48)
    else: discard
  of pix_format_abgr32:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_abgr32)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_abgr32)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_abgr32)
    else: discard
  of pix_format_argb32:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_argb32)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_argb32)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_argb32)
    else: discard
  of pix_format_bgra32:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_bgra32)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_bgra32)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_bgra32)
    else: discard
  of pix_format_rgba32:
    case pmap.bpp()
    of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgba32)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgba32)
    of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgba32)
    else: discard
  of pix_format_abgr64:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_abgr64)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_abgr64)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_abgr64)
    else: discard
  of pix_format_argb64:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_argb64)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_argb64)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_argb64)
    else: discard
  of pix_format_bgra64:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_bgra64)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_bgra64)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_bgra64)
    else: discard
  of pix_format_rgba64:
    case pmap.bpp()
    #of 16: color_conv(dst, rbuf, color_conv_rgb555_to_rgba64)
    of 24: color_conv(dst, rbuf, color_conv_bgr24_to_rgba64)
    #of 32: color_conv(dst, rbuf, color_conv_bgra32_to_rgba64)
    else: discard
  else: discard
  result = true

proc translate[T](self: var PlatformSpecific[T], keyCode: int): KeyCode =
  self.mLastTranslatedKey = if keyCode > 255: key_none else: self.mKeyMap[keyCode]
  result = self.mLastTranslatedKey

proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  self.mSpecific = initPlatformSpecific[T](format, flipY)
  self.mFormat = format
  self.mBpp = self.mSpecific.mBpp
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY = flipY
  self.mInitialWidth = 10
  self.mInitialHeight = 10
  self.mCaption = "Anti-Grain Geometry Application"

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap
  if self.mSpecific.mHwnd != NULL:
    discard setWindowText(self.mSpecific.mHwnd, self.mCaption)

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

    self.mSpecific.mImgPmap[idx].create(w, h, self.mSpecific.mBpp)
    var stride = self.mSpecific.mImgPmap[idx].stride()
    self.mRbufImage[idx].attach(self.mSpecific.mImgPmap[idx].buf(),
                                self.mSpecific.mImgPmap[idx].width(),
                                self.mSpecific.mImgPmap[idx].height(),
                                if self.mFlipY: stride else: - stride)
    return true
  result = false


proc init[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags): bool =
  if self.mSpecific.mSysFormat == pix_format_undefined:
    return false

  self.mWindowFlags = flags

  self.mSpecific.createPmap(width, height, self.mRBufWindow)
  self.mInitialWidth = width
  self.mInitialHeight = height
  self.onInit()
  result = true

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
  if paramCount() > 0:
    if paramStr(1) == "-v":
      if self.init(width, height, {window_hidden}):
        self.onDraw()
        self.copyWindowToImg(maxImages - 1)
        discard self.saveImg(maxImages - 1, fileName)
        return false
  result = self.init(width, height, flags)

proc run[T,R](self: GenericPlatform[T,R]): int =
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
  self.mStartTime = cpuTime()

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  result = cpuTime() - self.mStartTime

proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName
