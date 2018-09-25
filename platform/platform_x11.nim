import agg/[basics, color_conv_rgb8], times, nimBMP, strutils
import x11/[xlib, x, keysym, xutil]

type
  Ticks = distinct int64
  Time = clong

  Timeval {.importc: "struct timeval", header: "<sys/select.h>",
               final, pure.} = object ## struct timeval
    tv_sec: Time  ## Seconds.
    tv_usec: clong ## Microseconds.

proc posix_gettimeofday(tp: var Timeval, unused: pointer = nil) {.importc: "gettimeofday", header: "<sys/time.h>".}

proc getTicks(): Ticks =
  var t: Timeval
  posix_gettimeofday(t)
  result = Ticks(int64(t.tv_sec) * 1000_000_000'i64 + int64(t.tv_usec) * 1000'i64)

type
  PlatformSpecific[T] = object
    mUpdateFlag: bool
    mResizeFlag: bool
    mInitialized: bool
    mSwStart: Ticks
    mBufWindow: seq[T]
    mBufTmp: seq[T]
    mBufImg: array[maxImages, seq[T]]
    mFormat: PixFormat
    mSysFormat: PixFormat
    mByteOrder: int
    mFlipY: bool
    mBpp: int
    mSysBpp: int
    mDisplay: PXDisplay
    mScreen: int
    mDepth: int
    mVisual: PVisual
    mWindow: TWindow
    mGC: TGC
    mXimgWindow: PXImage
    mWindowAttributes: TXSetWindowAttributes
    mCloseAtom: TAtom
    mKeyMap: array[256, KeyCode]
    mScreenShotName: string

proc initPlatformSpecific[T](format: PixFormat, flipY: bool): PlatformSpecific[T] =
  result.mFormat = format
  result.mSysFormat = pix_format_undefined
  result.mByteOrder = LSBFirst
  result.mFlipY = flipY
  result.mBpp = 0
  result.mSysBpp = 0
  result.mDisplay = nil
  result.mScreen = 0
  result.mDepth = 0
  result.mVisual = nil
  result.mWindow = 0
  result.mGC = nil
  result.mXimgWindow = nil
  result.mCloseAtom = 0

  result.mBufWindow = @[]
  result.mBufTmp = @[]
  result.mUpdateFlag = true
  result.mResizeFlag = true
  result.mInitialized = false
  zeroMem(result.mBufImg[0].addr, sizeof(result.mBufImg))

  for i in 0..255:
    result.mKeyMap[i] = KeyCode(i)

  result.mKeyMap[XK_Pause and 0xFF] = key_pause
  result.mKeyMap[XK_Clear and 0xFF] = key_clear
  result.mKeyMap[XK_KP_0 and 0xFF] = key_kp0
  result.mKeyMap[XK_KP_1 and 0xFF] = key_kp1
  result.mKeyMap[XK_KP_2 and 0xFF] = key_kp2
  result.mKeyMap[XK_KP_3 and 0xFF] = key_kp3
  result.mKeyMap[XK_KP_4 and 0xFF] = key_kp4
  result.mKeyMap[XK_KP_5 and 0xFF] = key_kp5
  result.mKeyMap[XK_KP_6 and 0xFF] = key_kp6
  result.mKeyMap[XK_KP_7 and 0xFF] = key_kp7
  result.mKeyMap[XK_KP_8 and 0xFF] = key_kp8
  result.mKeyMap[XK_KP_9 and 0xFF] = key_kp9

  result.mKeyMap[XK_KP_Insert and 0xFF]    = key_kp0
  result.mKeyMap[XK_KP_End and 0xFF]       = key_kp1
  result.mKeyMap[XK_KP_Down and 0xFF]      = key_kp2
  result.mKeyMap[XK_KP_Page_Down and 0xFF] = key_kp3
  result.mKeyMap[XK_KP_Left and 0xFF]      = key_kp4
  result.mKeyMap[XK_KP_Begin and 0xFF]     = key_kp5
  result.mKeyMap[XK_KP_Right and 0xFF]     = key_kp6
  result.mKeyMap[XK_KP_Home and 0xFF]      = key_kp7
  result.mKeyMap[XK_KP_Up and 0xFF]        = key_kp8
  result.mKeyMap[XK_KP_Page_Up and 0xFF]   = key_kp9
  result.mKeyMap[XK_KP_Delete and 0xFF]    = key_kp_period
  result.mKeyMap[XK_KP_Decimal and 0xFF]   = key_kp_period
  result.mKeyMap[XK_KP_Divide and 0xFF]    = key_kp_divide
  result.mKeyMap[XK_KP_Multiply and 0xFF]  = key_kp_multiply
  result.mKeyMap[XK_KP_Subtract and 0xFF]  = key_kp_minus
  result.mKeyMap[XK_KP_Add and 0xFF]       = key_kp_plus
  result.mKeyMap[XK_KP_Enter and 0xFF]     = key_kp_enter
  result.mKeyMap[XK_KP_Equal and 0xFF]     = key_kp_equals

  result.mKeyMap[XK_Up and 0xFF]           = key_up
  result.mKeyMap[XK_Down and 0xFF]         = key_down
  result.mKeyMap[XK_Right and 0xFF]        = key_right
  result.mKeyMap[XK_Left and 0xFF]         = key_left
  result.mKeyMap[XK_Insert and 0xFF]       = key_insert
  result.mKeyMap[XK_Home and 0xFF]         = key_delete
  result.mKeyMap[XK_End and 0xFF]          = key_end
  result.mKeyMap[XK_Page_Up and 0xFF]      = key_page_up
  result.mKeyMap[XK_Page_Down and 0xFF]    = key_page_down

  result.mKeyMap[XK_F1 and 0xFF]           = key_f1
  result.mKeyMap[XK_F2 and 0xFF]           = key_f2
  result.mKeyMap[XK_F3 and 0xFF]           = key_f3
  result.mKeyMap[XK_F4 and 0xFF]           = key_f4
  result.mKeyMap[XK_F5 and 0xFF]           = key_f5
  result.mKeyMap[XK_F6 and 0xFF]           = key_f6
  result.mKeyMap[XK_F7 and 0xFF]           = key_f7
  result.mKeyMap[XK_F8 and 0xFF]           = key_f8
  result.mKeyMap[XK_F9 and 0xFF]           = key_f9
  result.mKeyMap[XK_F10 and 0xFF]          = key_f10
  result.mKeyMap[XK_F11 and 0xFF]          = key_f11
  result.mKeyMap[XK_F12 and 0xFF]          = key_f12
  result.mKeyMap[XK_F13 and 0xFF]          = key_f13
  result.mKeyMap[XK_F14 and 0xFF]          = key_f14
  result.mKeyMap[XK_F15 and 0xFF]          = key_f15

  result.mKeyMap[XK_Num_Lock and 0xFF]     = key_numlock
  result.mKeyMap[XK_Caps_Lock and 0xFF]    = key_capslock
  result.mKeyMap[XK_Scroll_Lock and 0xFF]  = key_scrollock

  case result.mFormat
  of pix_format_gray8: result.mBpp = 8
  of pix_format_rgb565, pix_format_rgb555: result.mBpp = 16
  of pix_format_rgb24, pix_format_bgr24: result.mBpp = 24
  of pix_format_bgra32, pix_format_abgr32,
    pix_format_argb32, pix_format_rgba32:
    result.mBpp = 32
  else: discard

  result.mSwStart = getTicks()
  result.mScreenShotName = "screenshot"

proc caption[T](self: PlatformSpecific[T], cap: string) =
  discard XStoreName(self.mDisplay, self.mWindow, cap)
  discard XSetIconName(self.mDisplay, self.mWindow, cap)

proc convert[RenBuf](dst, src: var RenBuf, sysFormat, format: PixFormat) =
  case sysFormat
  of pix_format_rgb555:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_rgb555)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_rgb555)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_rgb555)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_rgb555)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_rgb555)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_rgb555)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_rgb555)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_rgb555)
    else: discard
  of pix_format_rgb565:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_rgb565)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_rgb565)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_rgb565)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_rgb565)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_rgb565)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_rgb565)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_rgb565)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_rgb565)
    else: discard
  of pix_format_rgba32:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_rgba32)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_rgba32)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_rgba32)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_rgba32)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_rgba32)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_rgba32)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_rgba32)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_rgba32)
    else: discard
  of pix_format_abgr32:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_abgr32)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_abgr32)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_abgr32)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_abgr32)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_abgr32)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_abgr32)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_abgr32)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_abgr32)
    else: discard
  of pix_format_argb32:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_argb32)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_argb32)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_argb32)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_argb32)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_argb32)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_argb32)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_argb32)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_argb32)
    else: discard
  of pix_format_bgra32:
    case format
    of pix_format_rgb555: color_conv(dst, src, color_conv_rgb555_to_bgra32)
    of pix_format_rgb565: color_conv(dst, src, color_conv_rgb565_to_bgra32)
    of pix_format_rgb24:  color_conv(dst, src, color_conv_rgb24_to_bgra32)
    of pix_format_bgr24:  color_conv(dst, src, color_conv_bgr24_to_bgra32)
    of pix_format_rgba32: color_conv(dst, src, color_conv_rgba32_to_bgra32)
    of pix_format_argb32: color_conv(dst, src, color_conv_argb32_to_bgra32)
    of pix_format_abgr32: color_conv(dst, src, color_conv_abgr32_to_bgra32)
    of pix_format_bgra32: color_conv(dst, src, color_conv_bgra32_to_bgra32)
    else: discard
  else: discard

proc putImage[T, RenBuf](self: var PlatformSpecific[T], src: var RenBuf) =
  if self.mXimgWindow == nil: return
  self.mXimgWindow.data = cast[cstring](self.mBufWindow[0].addr)

  if self.mFormat == self.mSysFormat:
    discard XPutImage(self.mDisplay, self.mWindow,
      self.mGC, self.mXimgWindow,
      0.cint, 0.cint, 0.cint, 0.cint,
      src.width().cuint,
      src.height().cuint)
  else:
    let rowLen = src.width() * self.mSysBpp div 8
    if self.mBufTmp.len < rowLen * src.height():
      self.mBufTmp.setLen(rowLen * src.height())

    var dst = construct(RenBuf)
    dst.attach(self.mBufTmp[0].addr,
      src.width(), src.height(), if self.mFlipY: -rowLen else: rowLen)

    convert(dst, src, self.mSysFormat, self.mFormat)

    self.mXimgWindow.data = cast[cstring](self.mBufTmp[0].addr)
    discard XPutImage(self.mDisplay, self.mWindow,
      self.mGC, self.mXimgWindow,
      0.cint, 0.cint, 0.cint, 0.cint, src.width().cuint, src.height().cuint)

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
  self.mCaption = "AGG Application"

proc caption[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap
  if self.mSpecific.mInitialized:
    self.mSpecific.caption(cap)


const
  xevent_mask =
    PointerMotionMask or
    ButtonPressMask or
    ButtonReleaseMask or
    ExposureMask or
    KeyPressMask or
    StructureNotifyMask

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags): bool =
  self.mWindowFlags = flags

  if window_hidden notin flags:
    self.mSpecific.mDisplay = XOpenDisplay(nil)

    if self.mSpecific.mDisplay == nil:
      echo "Unable to open DISPLAY!"
      return false

    self.mSpecific.mScreen = XDefaultScreen(self.mSpecific.mDisplay)
    self.mSpecific.mDepth  = XDefaultDepth(self.mSpecific.mDisplay, self.mSpecific.mScreen.cint)
    self.mSpecific.mVisual = XDefaultVisual(self.mSpecific.mDisplay, self.mSpecific.mScreen.cint)

    let
      r_mask = self.mSpecific.mVisual.red_mask
      g_mask = self.mSpecific.mVisual.green_mask
      b_mask = self.mSpecific.mVisual.blue_mask

    if self.mSpecific.mDepth < 15 or r_mask == 0 or g_mask == 0 or b_mask == 0:
      echo "There's no Visual compatible with minimal AGG requirements:"
      echo "At least 15-bit color depth and True- or DirectColor class."
      discard XCloseDisplay(self.mSpecific.mDisplay)
      return false

    when system.cpuEndian == bigEndian:
      const hw_byte_order = MSBFirst
    else:
      const hw_byte_order = LSBFirst

    # Perceive SYS-format by mask
    case self.mSpecific.mDepth
    of 15:
      self.mSpecific.mSysBpp = 16
      if r_mask == 0x7C00 and g_mask == 0x3E0 and b_mask == 0x1F:
        self.mSpecific.mSysFormat = pix_format_rgb555
        self.mSpecific.mByteOrder = hw_byte_order
    of 16:
      self.mSpecific.mSysBpp = 16
      if r_mask == 0xF800 and g_mask == 0x7E0 and b_mask == 0x1F:
        self.mSpecific.mSysFormat = pix_format_rgb565;
        self.mSpecific.mByteOrder = hw_byte_order;
    of 24, 32:
      self.mSpecific.mSysBpp = 32
      if g_mask == 0xFF00:
        if r_mask == 0xFF and b_mask == 0xFF0000:
          case self.mSpecific.mFormat
          of pix_format_rgba32:
            self.mSpecific.mSysFormat = pix_format_rgba32
            self.mSpecific.mByteOrder = LSBFirst
          of pix_format_abgr32:
            self.mSpecific.mSysFormat = pix_format_abgr32
            self.mSpecific.mByteOrder = MSBFirst
          else:
            self.mSpecific.mByteOrder = hw_byte_order
            self.mSpecific.mSysFormat = if hw_byte_order == LSBFirst:
              pix_format_rgba32 else: pix_format_abgr32

        if r_mask == 0xFF0000 and b_mask == 0xFF:
          case self.mSpecific.mFormat
          of pix_format_argb32:
            self.mSpecific.mSysFormat = pix_format_argb32
            self.mSpecific.mByteOrder = MSBFirst
          of pix_format_bgra32:
            self.mSpecific.mSysFormat = pix_format_bgra32
            self.mSpecific.mByteOrder = LSBFirst
          else:
            self.mSpecific.mByteOrder = hw_byte_order;
            self.mSpecific.mSysFormat = if hw_byte_order == MSBFirst:
              pix_format_argb32 else: pix_format_bgra32
    else: discard

    if self.mSpecific.mSysFormat == pix_format_undefined:
      echo "RGB masks are not compatible with AGG pixel formats:"
      echo "R=$1, R=$2, B=$3" % [$r_mask, $g_mask, $b_mask]
      discard XCloseDisplay(self.mSpecific.mDisplay)
      return false

    zeroMem(self.mSpecific.mWindowAttributes.addr,
      sizeof(self.mSpecific.mWindowAttributes))

    self.mSpecific.mWindowAttributes.border_pixel =
      XBlackPixel(self.mSpecific.mDisplay, self.mSpecific.mScreen.cint)

    self.mSpecific.mWindowAttributes.background_pixel =
      XWhitePixel(self.mSpecific.mDisplay, self.mSpecific.mScreen.cint)

    self.mSpecific.mWindowAttributes.override_redirect = 0

    let window_mask = CWBackPixel or CWBorderPixel

    self.mSpecific.mWindow =
      XCreateWindow(self.mSpecific.mDisplay,
        XDefaultRootWindow(self.mSpecific.mDisplay),
        0.cint, 0.cint,
        width.cuint,
        height.cuint,
        0.cuint,
        self.mSpecific.mDepth.cint,
        InputOutput.cuint,
        cast[PVisual](CopyFromParent),
        window_mask.culong,
        self.mSpecific.mWindowAttributes.addr)

    self.mSpecific.mGC = XCreateGC(self.mSpecific.mDisplay,
      self.mSpecific.mWindow, 0.culong, nil)

  self.mSpecific.mBufWindow.setLen(width * height * (self.mBpp div 8))
  setMem(self.mSpecific.mBufWindow[0].addr, 255, width * height * (self.mBpp div 8))

  self.mRBufWindow.attach(self.mSpecific.mBufWindow[0].addr,
    width, height, if self.mFlipY: -width * (self.mBpp div 8) else: width * (self.mBpp div 8))

  if window_hidden notin flags:
    self.mSpecific.mXimgWindow = XCreateImage(self.mSpecific.mDisplay,
      self.mSpecific.mVisual, #CopyFromParent,
      self.mSpecific.mDepth.cuint,
      ZPixmap.cint,
      0.cint,
      cast[cstring](self.mSpecific.mBufWindow[0].addr),
      width.cuint,
      height.cuint,
      self.mSpecific.mSysBpp.cint,
      cint(width * (self.mSpecific.mSysBpp div 8)))

    self.mSpecific.mXimgWindow.byte_order = cint(self.mSpecific.mByteOrder)

    self.mSpecific.caption(self.mCaption)

  self.mInitialWidth  = width
  self.mInitialHeight = height

  if not self.mSpecific.mInitialized:
    self.onInit()
    self.mSpecific.mInitialized = true

  self.transAffineResizing(width, height)
  self.onResize(width, height)
  self.mSpecific.mUpdateFlag = true

  if window_hidden notin flags:
    let hints = XAllocSizeHints()
    if hints != nil:
      if window_resize in flags:
        hints.min_width  = 32
        hints.min_height = 32
        hints.max_width  = 4096
        hints.max_height = 4096
      else:
        hints.min_width  = width.cint
        hints.min_height = height.cint
        hints.max_width  = width.cint
        hints.max_height = height.cint
      hints.flags = PMaxSize or PMinSize

      XSetWMNormalHints(self.mSpecific.mDisplay,
        self.mSpecific.mWindow, hints)
      discard XFree(hints)

    discard XMapWindow(self.mSpecific.mDisplay, self.mSpecific.mWindow)
    discard XSelectInput(self.mSpecific.mDisplay, self.mSpecific.mWindow, xevent_mask)

    self.mSpecific.mCloseAtom = XInternAtom(self.mSpecific.mDisplay,
      "WM_DELETE_WINDOW".cstring, TBool(false))

    discard XSetWMProtocols(self.mSpecific.mDisplay, self.mSpecific.mWindow,
      self.mSpecific.mCloseAtom.addr, 1)

  result = true

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

proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.putImage(self.mRbufWindow)

  # When self.mWaitMode is true we can discard all the events
  # came while the image is being drawn. In this of
  # the X server does not accumulate mouse motion events.
  # When self.mWaitMode is false, i.e. we have some idle drawing
  # we cannot afford to miss any events
  discard XSync(self.mSpecific.mDisplay, TBool(self.mWaitMode))

proc run[T,R](self: GenericPlatform[T,R]): int =
  if window_hidden in self.mWindowFlags:
    return 0

  discard XFlush(self.mSpecific.mDisplay)

  var
    quit = false
    cur_x, cur_y: int

  while not quit:
    if self.mSpecific.mUpdateFlag:
      self.onDraw()
      self.updateWindow()
      self.mSpecific.mUpdateFlag = false

    if not self.mWaitMode:
      if XPending(self.mSpecific.mDisplay) == 0:
        self.onIdle()
        continue

    var x_event: TXEvent
    discard XNextEvent(self.mSpecific.mDisplay, x_event.addr)

    # In the Idle mode discard all intermediate MotionNotify events
    if not self.mWaitMode and x_event.theType == MotionNotify:
      var te = x_event
      while true:
        if XPending(self.mSpecific.mDisplay) == 0: break
        discard XNextEvent(self.mSpecific.mDisplay, te.addr)
        if te.theType != MotionNotify: break
      x_event = te

    case x_event.theType
    of ConfigureNotify:
      if x_event.xconfigure.width != cint(self.mRbufWindow.width()) or
        x_event.xconfigure.height != cint(self.mRbufWindow.height()):

        var
          width  = x_event.xconfigure.width
          height = x_event.xconfigure.height

        self.mSpecific.mXimgWindow.data = nil
        discard XDestroyImage(self.mSpecific.mXimgWindow)

        self.mSpecific.mBufWindow.setLen(width * height * (self.mBpp div 8))
        self.mRbufWindow.attach(self.mSpecific.mBufWindow[0].addr,
          width, height, if self.mFlipY: -width * (self.mBpp div 8) else: width * (self.mBpp div 8))

        self.mSpecific.mXimgWindow = XCreateImage(self.mSpecific.mDisplay,
          self.mSpecific.mVisual, #CopyFromParent,
          self.mSpecific.mDepth.cuint,
          ZPixmap.cint,
          0.cint,
          cast[cstring](self.mSpecific.mBufWindow[0].addr),
          width.cuint,
          height.cuint,
          self.mSpecific.mSysBpp.cint,
          cint(width * (self.mSpecific.mSysBpp div 8)))
        self.mSpecific.mXimgWindow.byte_order = self.mSpecific.mByteOrder.cint

        self.transAffineResizing(width, height)
        self.onResize(width, height)
        self.onDraw()
        self.updateWindow()
    of Expose:
      self.mSpecific.putImage(self.mRbufWindow)
      discard XFlush(self.mSpecific.mDisplay)
      discard XSync(self.mSpecific.mDisplay, TBool(false))
    of KeyPress:
      var key = XLookupKeysym(x_event.xkey.addr, 0)
      var flags: InputFlags
      if (x_event.xkey.state and Button1Mask) != 0: flags.incl mouse_left
      if (x_event.xkey.state and Button3Mask) != 0: flags.incl mouse_right
      if (x_event.xkey.state and ShiftMask) != 0: flags.incl kbd_shift
      if (x_event.xkey.state and ControlMask) != 0: flags.incl kbd_ctrl

      var
        left  = false
        up    = false
        right = false
        down  = false

      case self.mSpecific.mKeyMap[key and 0xFF]
      of key_left:  left = true
      of key_up:    up = true
      of key_right: right = true
      of key_down:  down = true
      of key_f2:
        self.copyWindowToImg(maxImages - 1)
        discard self.saveImg(maxImages - 1, self.mSpecific.mScreenShotName)
      of key_f3:
        echo "occupied: $1, free: $2, total: $3" % [
          $getOccupiedMem(),
          $getFreeMem(),
          $getTotalMem()]
        echo GC_getStatistics()
      else: discard

      if self.mCtrls.onArrowKeys(left, right, down, up):
        self.onCtrlChange()
        self.forceRedraw()
      else:
        self.onKey(int(x_event.xkey.x),
          if self.mFlipY: self.mRbufWindow.height() - int(x_event.xkey.y) else: int(x_event.xkey.y),
          self.mSpecific.mKeyMap[key and 0xFF].int, flags)
    of ButtonPress:
      var flags: InputFlags
      if (x_event.xbutton.state and ShiftMask) != 0:   flags.incl kbd_shift
      if (x_event.xbutton.state and ControlMask) != 0: flags.incl kbd_ctrl
      if x_event.xbutton.button == Button1:     flags.incl mouse_left
      if x_event.xbutton.button == Button3:     flags.incl mouse_right

      cur_x = int(x_event.xbutton.x)
      if self.mFlipY:
        cur_y = self.mRbufWindow.height() - int(x_event.xbutton.y)
      else:
        cur_y = int(x_event.xbutton.y)

      if mouse_left in flags:
        if self.mCtrls.onMouseButtonDown(cur_x.float64, cur_y.float64):
          discard self.mCtrls.setCur(cur_x.float64, cur_y.float64)
          self.onCtrlChange()
          self.forceRedraw()
        else:
          if self.mCtrls.inRect(cur_x.float64, cur_y.float64):
            if self.mCtrls.setCur(cur_x.float64, cur_y.float64):
              self.onCtrlChange()
              self.forceRedraw()
          else:
            self.onMouseButtonDown(cur_x, cur_y, flags)

      if mouse_right in flags:
        self.onMouseButtonDown(cur_x, cur_y, flags)
    of MotionNotify:
      var flags: InputFlags
      if (x_event.xmotion.state and Button1Mask) != 0: flags.incl mouse_left
      if (x_event.xmotion.state and Button3Mask) != 0: flags.incl mouse_right
      if (x_event.xmotion.state and ShiftMask) != 0: flags.incl kbd_shift
      if (x_event.xmotion.state and ControlMask) != 0: flags.incl kbd_ctrl

      cur_x = int(x_event.xbutton.x)

      if self.mFlipY:
        cur_y = self.mRbufWindow.height() - int(x_event.xbutton.y)
      else:
        cur_y = int(x_event.xbutton.y)

      if self.mCtrls.onMouseMove(cur_x.float64, cur_y.float64, mouse_left in flags):
        self.onCtrlChange()
        self.forceRedraw()
      else:
        if not self.mCtrls.inRect(cur_x.float64, cur_y.float64):
          self.onMouseMove(cur_x, cur_y, flags)
    of ButtonRelease:
      var flags: InputFlags
      if (x_event.xbutton.state and ShiftMask) != 0: flags.incl kbd_shift
      if (x_event.xbutton.state and ControlMask) != 0: flags.incl kbd_ctrl
      if x_event.xbutton.button == Button1: flags.incl mouse_left
      if x_event.xbutton.button == Button3: flags.incl mouse_right

      cur_x = int(x_event.xbutton.x)
      if self.mFlipY:
        cur_y = self.mRbufWindow.height() - int(x_event.xbutton.y)
      else:
        cur_y = int(x_event.xbutton.y)

      if mouse_left in flags:
        if self.mCtrls.onMouseButtonUp(cur_x.float64, cur_y.float64):
          self.onCtrlChange()
          self.forceRedraw()

      if mouse_left in flags or mouse_right in flags:
        self.onMouseButtonUp(cur_x, cur_y, flags)
    of ClientMessage:
      if (x_event.xclient.format == 32) and
         (x_event.xclient.data.long[0] == cint(self.mSpecific.mCloseAtom)):
        quit = true
    else: discard

  self.mSpecific.mXimgWindow.data = nil
  discard XDestroyImage(self.mSpecific.mXimgWindow)
  discard XFreeGC(self.mSpecific.mDisplay, self.mSpecific.mGC)
  discard XDestroyWindow(self.mSpecific.mDisplay, self.mSpecific.mWindow)
  discard XCloseDisplay(self.mSpecific.mDisplay)

  result = 0

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
      width, height, if self.mFlipY: -stride else: stride)

    return true

  result = false

proc imgExt[T,R](self: GenericPlatform[T,R]): string = ".bmp"

proc rawDisplayHandler[T,R](self: GenericPlatform[T,R]): pointer =
  result = nil

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mUpdateFlag = true

proc message[T,R](self: GenericPlatform[T,R], msg: string) =
  stderr.write msg & "\n"

proc startTimer[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mSwStart = getTicks()

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  result = (float64(getTicks()) - float64(self.mSpecific.mSwStart)) / 1000_000.0

proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName

proc waitMode*[T,R](self: GenericPlatform[T,R], waitMode: bool) =
  self.mWaitMode = waitMode
