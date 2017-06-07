import agg/[basics, color_conv_rgb8], times, nimBMP, strutils
import objc/[objc, foundation, util], opengl, glu, math
include system/timers

type
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
    mWindow: NSWindow
    mView: NSView
    mPool: NSAutoReleasePool
    mApp: NSApplication
    mAppDelegate: Class
    mGLView: Class
    mInitialized: bool
    mFlipY: bool

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

proc glSwapAPPLE() {.importc, cdecl.}
{.passL: "-framework OpenGL".}

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
    w, h, if self.mFlipY: -w * (self.mBpp div 8) else: w * (self.mBpp div 8))

proc blitImage[T,RenBuf](self: var PlatformSpecific[T], src: var RenBuf) =
  var
    x1 = GLint(0)
    y1 = GLint(0)
    x2 = GLint(src.width())
    y2 = GLint(src.height())

  glEnable(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, self.mWindowTexID)

  if self.mFormat == self.mSysFormat:
    glTexSubImage2D(GL_TEXTURE_2D, GLint(0), x1, y1,
      x2, y2, self.mGLFormat, GL_UNSIGNED_BYTE, self.mBufWindow[0].addr)
  else:
    let rowLen = src.width() * self.mSysBpp div 8
    if self.mBufTmp.len < rowLen * src.height():
      self.mBufTmp.setLen(rowLen * src.height())

    var dst = construct(RenBuf)
    dst.attach(self.mBufTmp[0].addr,
      src.width(), src.height(), if self.mFlipY: -rowLen else: rowLen)

    convertTex(dst, src, self.mFormat)

    glTexSubImage2D(GL_TEXTURE_2D, GLint(0), x1, y1,
      x2, y2, self.mGLFormat, GL_UNSIGNED_BYTE, self.mBufTmp[0].addr)

  glColor3f(1.0f, 1.0f, 1.0f)
  glBegin(GL_POLYGON)
  glTexCoord2i(0,   0); glVertex2i(x1, y1)
  glTexCoord2i(x2,  0); glVertex2i(x2, y1)
  glTexCoord2i(x2, y2); glVertex2i(x2, y2)
  glTexCoord2i(0,  y2); glVertex2i(x1, y2)
  glEnd()

  glFlush()
  glSwapAPPLE()

proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  type ValueT = getValueT(R)
  self.mSpecific = initPlatformSpecific[ValueT](format, flipY)
  self.mFormat = format
  self.mBpp = self.mSpecific.mBpp
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY = flipY
  self.mInitialWidth = 10
  self.mInitialHeight = 10
  self.mCaption = "Anti-Grain Geometry Application"
  self.mResizeMtx = initTransAffine()

proc shouldTerminate(self: ID, cmd: SEL, notification: ID): BOOL {.cdecl.} =
  result = YES

const kPlatform = "platform"

proc makeAppDelegate(): Class =
  result = allocateClassPair(getClass("NSObject"), "AppDelegate", 0)
  discard result.addMethod($$"applicationShouldTerminateAfterLastWindowClosed:", cast[IMP](shouldTerminate), "c@:@")
  discard result.addIvar(kPlatform, sizeof(int), log2(sizeof(int).float64).int, "q")
  result.registerClassPair()

type
  # buggy Nim param passing
  NSRect* {.bycopy.} = object
    x*, y*, w*, h*: float64

proc acceptFirstResponder(self: ID, cmd: SEL): BOOL {.cdecl.} =
  result = YES

proc drawRect[T,R](self: ID, cmd: SEL, rect: NSRect) {.cdecl.} =
  var cls  = getClass(self)
  var ivar = cls.getIvar(kPlatform)
  var app  = cast[GenericPlatform[T,R]](self.getIvar(ivar))
  app.onDraw()
  app.updateWindow()

proc reshape[T,R](self: ID, cmd: SEL) {.cdecl.} =
  var cls  = getClass(self)
  var ivar = cls.getIvar(kPlatform)
  var app  = cast[GenericPlatform[T,R]](self.getIvar(ivar))
  var width  = GLsizei(app.width())
  var height = GLsizei(app.height())

  # Compute aspect ratio of the new window
  if width == 0 or height == 0:
    return                # To prevent divide by 0

  # Set the viewport to cover the new window
  glViewport(0, 0, width, height)

  # Set the aspect ratio of the clipping volume to match the viewport
  glMatrixMode(GL_PROJECTION)  # To operate on the Projection matrix
  glLoadIdentity()             # Reset
  gluOrtho2D(0.0, GLDouble(width), 0.0, GLDouble(height))

  app.mSpecific.createPmap(width, height, app.rbufWindow())
  app.transAffineResizing(width, height)
  app.onResize(width, height)
  app.forceRedraw()

proc makeGLView[T,R](): Class =
  var cls = getClass("NSOpenGLView")
  result = allocateClassPair(cls, "GLView", 0)

  var sel = $$"acceptFirstResponder"
  var im  = getInstanceMethod(cls, sel)
  var types = getTypeEncoding(im)
  discard result.addMethod(sel, cast[IMP](acceptFirstResponder), types)

  sel = $$"drawRect:"
  im  = getInstanceMethod(cls, sel)
  types = getTypeEncoding(im)
  discard result.addMethod(sel, cast[IMP](drawRect[T,R]), types)

  sel = $$"reshape"
  im  = getInstanceMethod(cls, sel)
  types = getTypeEncoding(im)
  discard result.addMethod(sel, cast[IMP](reshape[T,R]), types)

  discard result.addIvar(kPlatform, sizeof(int), log2(sizeof(int).float64).int, "q")
  result.registerClassPair()

proc init[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags): bool =
  self.mWindowFlags = flags

  self.mSpecific.mPool = newAutoReleasePool()
  self.mSpecific.mApp = newApplication()
  self.mSpecific.mApp.setActivationPolicy(NSApplicationActivationPolicyRegular)

  var windowStyle = NSTitledWindowMask or NSClosableWindowMask or
    NSMiniaturizableWindowMask or NSResizableWindowMask

  var windowRect = NSMakeRect(100,100,400,400)
  self.mSpecific.mWindow = NSWindow.init(windowRect, windowStyle, NSBackingStoreBuffered, NO)
  self.mSpecific.mWindow.autoRelease()
  self.mSpecific.mWindow.setTitle(self.mCaption)

  if window_hidden notin flags:
    self.mSpecific.mWindow.display()
    self.mSpecific.mWindow.orderFrontRegardless()

  var pf = createPixelFormat()

  self.mSpecific.mGLView = makeGLView[T,R]()
  var glView = newGLView()
  glView.initWithFrame(windowRect, pf)
  glView.setWantsBestResolutionOpenGLSurface(YES)

  self.mSpecific.mWindow.setContentView(glView)
  self.mSpecific.mWindow.makeFirstResponder(glView)
  self.mSpecific.mWindow.makeKeyWindow()

  glView.setIvar(kPlatform, self)

  self.mSpecific.mAppDelegate = makeAppDelegate()
  var appDelegate = newAppDelegate()
  appDelegate.autoRelease()
  self.mSpecific.mApp.setDelegate(appDelegate)

  self.mSpecific.createPmap(width, height, self.rbufWindow())

  self.mSpecific.mWindowTexID = 0
  glEnable(GL_TEXTURE_2D)
  glGenTextures(1, addr(self.mSpecific.mWindowTexID))
  glBindTexture(GL_TEXTURE_2D, self.mSpecific.mWindowTexID)
  glPixelStorei(GL_UNPACK_ROW_LENGTH, GLint(width))
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,  GL_LINEAR)
  glTexImage2D(GL_TEXTURE_2D,
    GLint(0), GLint(GL_RGBA8),
    GLSizei(width), GLsizei(height),
    GLint(0), self.mSpecific.mGLFormat,
    GL_UNSIGNED_BYTE, self.mSpecific.mBufWindow[0].addr)

  glMatrixMode(GL_TEXTURE)
  glLoadIdentity()
  glScalef(1.0/GLfloat(width), 1.0/GLfloat(height), 1.0)

  glClearColor(0.0, 0.0, 0.0, 1.0)                  # Set background color to black and opaque
  glClearDepth(1.0)                                 # Set background depth to farthest
  glEnable(GL_DEPTH_TEST)                           # Enable depth testing for z-culling
  glDepthFunc(GL_LEQUAL)                            # Set the type of depth-test
  glShadeModel(GL_SMOOTH)                           # Enable smooth shading
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
  glMatrixMode(GL_MODELVIEW)                          # To operate on model-view matrix
  glLoadIdentity()                                    # Reset the model-view matrix

  # trigger onInit event
  self.onInit()

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
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
    self.mSpecific.mApp.run()

  glDeleteTextures(1, addr(self.mSpecific.mWindowTexID))
  self.mSpecific.mPool.drain()
  self.mSpecific.mAppDelegate.disposeClassPair()
  self.mSpecific.mGLView.disposeClassPair()

proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  if self.mSpecific.mInitialized:
    self.mSpecific.blitImage(self.mRBufWindow)

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  if not self.mSpecific.mView.isNil():
    self.mSpecific.mView.setNeedsDisplay(YES)

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap
  if not self.mSpecific.mWindow.isNil():
    self.mSpecific.mWindow.setTitle(cap)

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

    case self.mFormat
    of pix_format_rgb555: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgb555)
    of pix_format_rgb565: color_conv(self.mRbufImage[idx], src, color_conv_rgb24_to_rgb565)
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

    if self.mSpecific.mBufImg[idx].isNil:
      self.mSpecific.mBufImg[idx] = newSeq[ValueT](size)
    else:
      self.mSpecific.mBufImg[idx].setLen(size)

    let stride = width * (self.mBpp div 8)
    self.mRBufImage[idx].attach(self.mSpecific.mBufImg[idx][0].addr,
      width, height, if self.mFlipY: -stride else: stride)

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
