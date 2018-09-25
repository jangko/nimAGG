import agg/[basics, color_conv_rgb8], times, nimBMP, strutils
#import objc/[objc, foundation, util], opengl, glu, math
import opengl, glu, math

include system/timers
{.compile: "platform_cocoa.m".}
{.passL: "-framework Cocoa".}
{.passL: "-framework OpenGL".}

type
  NSWindow = distinct pointer
  NSOpenGLView = distinct pointer
  NSAutoReleasePool = distinct pointer
  NSApplication = distinct pointer

  DrawRectT = proc(app: pointer) {.cdecl.}
  ReshapeT = proc(app: pointer, width, height: cint) {.cdecl.}
  EventHandlerT = proc(app: pointer, event, lparam, wparam: cint) {.cdecl.}

  CocoaFFI = object
    mWindow: NSWindow
    mView: NSOpenGLView
    mPool: NSAutoReleasePool
    mApp: NSApplication
    mPlatform: pointer
    mDrawRect: DrawRectT
    mReshape: ReshapeT
    mEventHandler: EventHandlerT
    appTerminate: cint
    waitMode: cint

  PlatformSpecific[T] = object
    mBufWindow: seq[T]
    mBufTmp: seq[T]
    mBufImg: array[maxImages, seq[T]]
    mScreenShotName: string
    mSwStart: Ticks
    mWindowTexID: GLuint
    mBpp: int
    mSysBpp: int
    mFormat: PixFormat
    mSysFormat: PixFormat
    mGLFormat: GLenum
    mInitialized: bool
    mFlipY: bool
    mCurX: int
    mCurY: int
    mInputFlags: InputFlags
    mFFI: CocoaFFI

proc initPlatformSpecific[T](format: PixFormat, flipY: bool): PlatformSpecific[T] =
  result.mFormat = format
  result.mSysFormat = pix_format_undefined
  result.mFlipY = flipY
  result.mBufWindow = @[]
  result.mBufTmp = @[]
  result.mInitialized = false
  zeroMem(result.mBufImg[0].addr, sizeof(result.mBufImg))
  result.mBpp = 0
  result.mSysBpp = 0
  result.mCurX = 0
  result.mCurY = 0
  result.mInputFlags = {}
  result.mScreenShotName = "screenshot"
  result.mSwStart = getTicks()

  case result.mFormat
  of pix_format_gray8:
    result.mSysFormat = pix_format_gray8
    result.mBpp = 8
    result.mSysBpp = 8
    result.mGLFormat = GL_RED
  of pix_format_gray16:
    result.mSysFormat = pix_format_gray8
    result.mBpp = 16
    result.mSysBpp = 8
    result.mGLFormat = GL_RED
  of pix_format_rgb565, pix_format_rgb555:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 16
    result.mSysBpp = 24
    result.mGLFormat = GL_BGR
  of pix_format_rgbAAA, pix_format_bgrAAA,
     pix_format_rgbBBA, pix_format_bgrABB:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 32
    result.mSysBpp = 24
    result.mGLFormat = GL_BGR
  of pix_format_rgb24, pix_format_bgr24:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 24
    result.mSysBpp = 24
    result.mGLFormat = GL_BGR
  of pix_format_rgb48, pix_format_bgr48:
    result.mSysFormat = pix_format_bgr24
    result.mBpp = 48
    result.mSysBpp = 24
    result.mGLFormat = GL_BGR
  of pix_format_bgra32, pix_format_abgr32,
     pix_format_argb32, pix_format_rgba32:
    result.mSysFormat = pix_format_bgra32
    result.mBpp = 32
    result.mSysBpp = 32
    result.mGLFormat = GL_BGRA
  of pix_format_bgra64, pix_format_abgr64,
     pix_format_argb64, pix_format_rgba64:
    result.mSysFormat = pix_format_bgra32
    result.mBpp = 64
    result.mSysBpp = 32
    result.mGLFormat = GL_BGRA
  else: discard

proc convertTex[RenBuf](dst, src: var RenBuf, format: PixFormat) =
  case format
  of pix_format_gray8: discard
  of pix_format_gray16: color_conv(dst, src, color_conv_gray16_to_gray8)
  of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_bgr24)
  of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_bgr24)
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

proc createPmap[T,RenBuf](self: var PlatformSpecific[T], w, h: int, wnd: var RenBuf) =
  self.mBufWindow.setLen(w * h * (self.mBpp div 8))
  setMem(self.mBufWindow[0].addr, 255, w * h * (self.mBpp div 8))
  wnd.attach(self.mBufWindow[0].addr,
    w, h, if self.mFlipY: w * (self.mBpp div 8) else: -w * (self.mBpp div 8))

proc cocoaInit(self: var CocoaFFI, showWindow: cint, title: cstring, w, h: cint) {.importc.}
proc run(self: var CocoaFFI) {.importc.}
proc cocoaInitGL(self: var CocoaFFI, data: cstring, w, h: cint, format: GLenum): GLuint {.importc.}
proc cocoaDeinit(self: var CocoaFFI, texID: GLuint) {.importc.}
proc forceRedraw(self: var CocoaFFI) {.importc.}
proc setTitle(self: var CocoaFFI, title: cstring) {.importc.}
proc blitImage(id: GLuint, data: cstring, x1, y1, x2, y2: GLint, format: GLenum) {.importc.}

proc blitImage[T,RenBuf](self: var PlatformSpecific[T], src: var RenBuf) =
  var
    x1 = GLint(0)
    y1 = GLint(0)
    x2 = GLint(src.width())
    y2 = GLint(src.height())

  if self.mFormat == self.mSysFormat:
    blitImage(self.mWindowTexID, cast[cstring](self.mBufWindow[0].addr),
      x1, y1, x2, y2, self.mGLFormat)
  else:
    let rowLen = src.width() * self.mSysBpp div 8
    if self.mBufTmp.len < rowLen * src.height():
      self.mBufTmp.setLen(rowLen * src.height())

    var dst = construct(RenBuf)
    dst.attach(self.mBufTmp[0].addr,
      src.width(), src.height(), if self.mFlipY: rowLen else: -rowLen)

    convertTex(dst, src, self.mFormat)
    blitImage(self.mWindowTexID, cast[cstring](self.mBufTmp[0].addr),
      x1, y1, x2, y2, self.mGLFormat)

proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  type ValueT = getValueT(R)
  self.mSpecific = initPlatformSpecific[ValueT](format, flipY)
  self.mSpecific.mFFI.waitMode = 1;
  self.mSpecific.mFFI.appTerminate = 0;
  self.mFormat = format
  self.mBpp = self.mSpecific.mBpp
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY = flipY
  self.mInitialWidth = 10
  self.mInitialHeight = 10
  self.mCaption = "Anti-Grain Geometry Application"
  self.mResizeMtx = initTransAffine()

proc drawRect[T,R](app: GenericPlatform[T,R]) {.cdecl.} =
  app.onDraw()
  app.updateWindow()

proc reshape[T,R](app: GenericPlatform[T,R], width, height: cint) {.cdecl.} =
  app.mSpecific.createPmap(width, height, app.rbufWindow())
  app.transAffineResizing(width, height)
  app.onResize(width, height)
  app.forceRedraw()

const
  MOUSE_LBUTTON_DOWN = 11
  MOUSE_LBUTTON_UP   = 12
  MOUSE_RBUTTON_DOWN = 13
  MOUSE_RBUTTON_UP   = 14
  MOUSE_MOVE         = 15
  KEY_DOWN           = 16
  KEY_UP             = 17
  IDLE_STATE         = 18

proc eventHandler[T,R](app: GenericPlatform[T,R], event, lparam, wparam: cint): cint {.cdecl.} =
  case event
  of IDLE_STATE:
    app.onIdle()
    return 1
  of MOUSE_LBUTTON_DOWN:
    app.mSpecific.mCurX = lParam
    if not app.flipY():
      app.mSpecific.mCurY = app.rbufWindow().height() - wParam
    else:
      app.mSpecific.mCurY = wParam

    app.mSpecific.mInputFlags.incl mouseLeft
    discard app.mCtrls.setCur(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64)
    if app.mCtrls.onMouseButtonDown(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64):
      app.onCtrlChange()
      app.forceRedraw()
    else:
      if app.mCtrls.inRect(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64):
        if app.mCtrls.setCur(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64):
          app.onCtrlChange()
          app.forceRedraw()
      else:
        app.onMouseButtonDown(app.mSpecific.mCurX,
                              app.mSpecific.mCurY,
                              app.mSpecific.mInputFlags)
    return 1
  of MOUSE_LBUTTON_UP:
    app.mSpecific.mCurX = lParam
    if not app.flipY():
      app.mSpecific.mCurY = app.rbufWindow().height() - wParam
    else:
      app.mSpecific.mCurY = wParam

    app.mSpecific.mInputFlags.incl mouseLeft

    if app.mCtrls.onMouseButtonUp(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64):
      app.onCtrlChange()
      app.forceRedraw()
    app.onMouseButtonUp(app.mSpecific.mCurX,
                        app.mSpecific.mCurY,
                        app.mSpecific.mInputFlags)
    return 1
  of MOUSE_RBUTTON_DOWN:
    app.mSpecific.mCurX = lParam
    if not app.flipY():
      app.mSpecific.mCurY = app.rbufWindow().height() - wParam
    else:
      app.mSpecific.mCurY = wParam

    app.mSpecific.mInputFlags.incl mouseRight
    app.onMouseButtonDown(app.mSpecific.mCurX,
                          app.mSpecific.mCurY,
                          app.mSpecific.mInputFlags)
    return 1
  of MOUSE_RBUTTON_UP:
    app.mSpecific.mCurX = lParam
    if not app.flipY():
      app.mSpecific.mCurY = app.rbufWindow().height() - wParam
    else:
      app.mSpecific.mCurY = wParam

    app.mSpecific.mInputFlags.incl mouseRight
    app.onMouseButtonUp(app.mSpecific.mCurX,
                        app.mSpecific.mCurY,
                        app.mSpecific.mInputFlags)
    return 1
  of MOUSE_MOVE:
    app.mSpecific.mCurX = lParam
    if not app.flipY():
      app.mSpecific.mCurY = app.rbufWindow().height() - wParam
    else:
      app.mSpecific.mCurY = wParam

    app.mSpecific.mInputFlags.incl mouseLeft

    let flag = mouseLeft in app.mSpecific.mInputFlags
    if app.mCtrls.onMouseMove(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64, flag):
      app.onCtrlChange()
      app.forceRedraw()
    else:
      if not app.mCtrls.inRect(app.mSpecific.mCurX.float64, app.mSpecific.mCurY.float64):
        app.onMouseMove(app.mSpecific.mCurX, app.mSpecific.mCurY, app.mSpecific.mInputFlags)
    return 1
  of KEY_DOWN:
    return 1
  of KEY_UP:
    return 1
  else:
    return 0

proc init[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags): bool =
  self.mWindowFlags = flags
  self.mSpecific.mFFI.mPlatform = cast[pointer](self)
  self.mSpecific.mFFI.mDrawRect = cast[DrawRectT](drawRect[T,R])
  self.mSpecific.mFFI.mReshape  = cast[ReshapeT](reshape[T,R])
  self.mSpecific.mFFI.mEventHandler  = cast[EventHandlerT](eventHandler[T,R])

  self.mInitialWidth = width
  self.mInitialHeight = height

  cocoaInit(self.mSpecific.mFFI, (window_hidden notin flags).cint,
    self.mCaption.cstring, width.cint, height.cint)

  self.mSpecific.createPmap(width, height, self.rbufWindow())

  self.mSpecific.mWindowTexID =
    cocoaInitGL(self.mSpecific.mFFI, cast[cstring](self.mSpecific.mBufWindow[0].addr),
    width.cint, height.cint, self.mSpecific.mGLFormat)

  self.mSpecific.mInitialized = true
  # trigger onInit event
  self.onInit()
  result = true

proc init[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
  if paramCount() > 0:
    if paramStr(1) == "-v":
      if self.init(width, height, {window_hidden}):
        self.mResizeMtx = initTransAffine()
        self.onDraw()
        self.copyWindowToImg(maxImages - 1)
        discard self.saveImg(maxImages - 1, fileName)
        return false
  self.mSpecific.mScreenShotName = fileName
  result = self.init(width, height, flags)

proc run[T,R](self: GenericPlatform[T,R]): int =
  if window_hidden notin self.mWindowFlags:
    self.mSpecific.mFFI.run()

  cocoaDeinit(self.mSpecific.mFFI, self.mSpecific.mWindowTexID)

proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  if self.mSpecific.mInitialized:
    self.mSpecific.blitImage(self.mRBufWindow)

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mFFI.forceRedraw()

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap
  self.mSpecific.mFFI.setTitle(self.mCaption.cstring)

proc loadImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  type ValueT = getValueT(R)
  if idx < maxImages:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"

    var
      bmp = loadBMP24(fileName, seq[ValueT])
      src = initRenderingBuffer(bmp.data[0].addr,
        bmp.width, bmp.height,
        if self.mFlipY: -bmp.width * 3 else: bmp.width * 3)

    discard self.createImg(idx, bmp.width, bmp.height)

    case self.mFormat
    of pix_format_rgb555: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgb555)
    of pix_format_rgb565: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgb565)
    of pix_format_rgb24:  color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgb24)
    of pix_format_bgr24:  color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_bgr24)
    of pix_format_rgba32: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgba32)
    of pix_format_argb32: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_argb32)
    of pix_format_bgra32: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_bgra32)
    of pix_format_abgr32: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_abgr32)
    else:
      discard

    return true

  result = false

proc convert[RenBuf](dst, src: var RenBuf, format: PixFormat) =
  case format
  of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_rgb24)
  of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_rgb24)
  of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_rgb24)
  of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_rgb24)
  of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_rgb24)
  of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_rgb24)
  of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_rgb24)
  of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_rgb24)
  else: discard

proc saveImg(fileName: string, buffer: seq[uint8], w, h: int) =
  saveBMP24(fileName, buffer, w, h)

proc saveImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  type ValueT = getValueT(R)

  if idx < maxImages and self.rbufImg(idx).getBuf() != nil:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"

    let
      w = self.rbufImg(idx).width()
      h = self.rbufImg(idx).height()

    var
      buffer = newSeq[ValueT](w * h * 3)
      dst    = initRenderingBuffer(buffer[0].addr, w, h, if self.mFlipY: -w * 3 else: w * 3)
    convert(dst, self.rbufImg(idx), self.mFormat)
    saveImg(fileName, buffer, w, h)
    return true

  result = false

proc createImg[T,R](self: GenericPlatform[T,R], idx: int, w = 0, h = 0): bool =
  type ValueT = getValueT(R)
  var
    width = w
    height = h

  if idx < maxImages:
    if width == 0:  width  = self.rbufWindow().width()
    if height == 0: height = self.rbufWindow().height()
    let size = width * height * (self.mBpp div 8)

    if self.mSpecific.mBufImg[idx].len == 0:
      self.mSpecific.mBufImg[idx] = newSeq[ValueT](size)
    else:
      self.mSpecific.mBufImg[idx].setLen(size)

    let stride = width * (self.mBpp div 8)
    self.mRBufImage[idx].attach(self.mSpecific.mBufImg[idx][0].addr,
      width, height, if self.mFlipY: stride else: -stride)

    return true

  result = false

proc imgExt[T,R](self: GenericPlatform[T,R]): string = ".bmp"

proc rawDisplayHandler[T,R](self: GenericPlatform[T,R]): pointer =
  result = nil

proc message[T,R](self: GenericPlatform[T,R], msg: string) =
  stderr.write msg & "\n"

proc startTimer[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mSwStart = getTicks()

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  result = float64(getTicks() - self.mSpecific.mSwStart) / 1000_000.0

proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName

proc waitMode*[T,R](self: GenericPlatform[T,R], waitMode: bool) =
  self.mWaitMode = waitMode
  self.mSpecific.mFFI.waitMode = cint(waitMode)
