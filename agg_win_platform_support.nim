import agg_win32_bmp, winapi, strutils

var
  windowsInstance = HINST(NULL)
  windowsCmdShow  = 0

type
  PlatformSpecific = object
    mFormat: PixFormat
    mSysFormat: PixFormat
    mFlipY: bool
    mBpp: int
    mSysBpp: int
    mHwnd: HWND
    mPmapWindow: PixelMap
    mPmapImage: array[maxImages, PixelMap]
    mKeyMap: array[256, KeyCode]
    mLastTranslatedKey: KeyCode
    mCurX: int
    mCurY: int
    mInputFlags: InputFlags
    mRedrawFlags: bool
    mCurrentDC: HDC
    mSwFreq: LARGE_INTEGER
    mSwStart: LARGE_INTEGER

proc initPlatformSpecific(format: PixFormat, flipY: bool): PlatformSpecific =
  if windowsInstance == NULL:
    windowsInstance = getModuleHandle(nil)

  result.mFormat = format
  result.mSysFormat = pix_format_undefined
  result.mFlipY = flipY
  result.mBpp = 0
  result.mSysBpp = 0
  result.mHwnd = NULL
  result.mLastTranslatedKey = key_none
  result.mCurX = 0
  result.mCurY = 0
  result.mInputFlags = {}
  result.mRedrawFlags = true
  result.mCurrentDC = NULL

  result.mKeyMap[VK_PAUSE]      = key_pause
  result.mKeyMap[VK_CLEAR]      = key_clear

  result.mKeyMap[VK_NUMPAD0]    = key_kp0
  result.mKeyMap[VK_NUMPAD1]    = key_kp1
  result.mKeyMap[VK_NUMPAD2]    = key_kp2
  result.mKeyMap[VK_NUMPAD3]    = key_kp3
  result.mKeyMap[VK_NUMPAD4]    = key_kp4
  result.mKeyMap[VK_NUMPAD5]    = key_kp5
  result.mKeyMap[VK_NUMPAD6]    = key_kp6
  result.mKeyMap[VK_NUMPAD7]    = key_kp7
  result.mKeyMap[VK_NUMPAD8]    = key_kp8
  result.mKeyMap[VK_NUMPAD9]    = key_kp9
  result.mKeyMap[VK_DECIMAL]    = key_kp_period
  result.mKeyMap[VK_DIVIDE]     = key_kp_divide
  result.mKeyMap[VK_MULTIPLY]   = key_kp_multiply
  result.mKeyMap[VK_SUBTRACT]   = key_kp_minus
  result.mKeyMap[VK_ADD]        = key_kp_plus

  result.mKeyMap[VK_UP]         = key_up
  result.mKeyMap[VK_DOWN]       = key_down
  result.mKeyMap[VK_RIGHT]      = key_right
  result.mKeyMap[VK_LEFT]       = key_left
  result.mKeyMap[VK_INSERT]     = key_insert
  result.mKeyMap[VK_DELETE]     = key_delete
  result.mKeyMap[VK_HOME]       = key_home
  result.mKeyMap[VK_END]        = key_end
  result.mKeyMap[VK_PRIOR]      = key_page_up
  result.mKeyMap[VK_NEXT]       = key_page_down

  result.mKeyMap[VK_F1]         = key_f1
  result.mKeyMap[VK_F2]         = key_f2
  result.mKeyMap[VK_F3]         = key_f3
  result.mKeyMap[VK_F4]         = key_f4
  result.mKeyMap[VK_F5]         = key_f5
  result.mKeyMap[VK_F6]         = key_f6
  result.mKeyMap[VK_F7]         = key_f7
  result.mKeyMap[VK_F8]         = key_f8
  result.mKeyMap[VK_F9]         = key_f9
  result.mKeyMap[VK_F10]        = key_f10
  result.mKeyMap[VK_F11]        = key_f11
  result.mKeyMap[VK_F12]        = key_f12
  result.mKeyMap[VK_F13]        = key_f13
  result.mKeyMap[VK_F14]        = key_f14
  result.mKeyMap[VK_F15]        = key_f15

  result.mKeyMap[VK_NUMLOCK]    = key_numlock
  result.mKeyMap[VK_CAPITAL]    = key_capslock
  result.mKeyMap[VK_SCROLL]     = key_scrollock

  case result.mFormat
  of pix_format_bw:
    result.mSysFormat = pix_format_bw
    result.mBpp = 1
    result.mSysBpp = 1
  of pix_format_gray8:
    result.mSysFormat = pix_format_gray8
    result.mBpp = 8
    result.mSysBpp = 8
  of pix_format_gray16:
    result.mSysFormat = pix_format_gray8
    result.mBpp = 16
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

  discard queryPerformanceFrequency(result.mSwFreq)
  discard queryPerformanceCounter(result.mSwStart)

proc createPmap(self: var PlatformSpecific, width, height: int, wnd: var RenderingBuffer) =
  self.mPmapWindow.create(width, height, self.mBpp)
  let stride = if self.mFlipY: self.mPmapWindow.stride() else: -self.mPmapWindow.stride()
  wnd.attach(self.mPmapWindow.buf(),
             self.mPmapWindow.width(),
             self.mPmapWindow.height(),
             stride)

proc convertPmap(dst, src: var RenderingBuffer, format: PixFormat) =
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

proc displayPmap(self: var PlatformSpecific, dc: HDC, src: var RenderingBuffer) =
  if self.mSysFormat == self.mFormat:
    self.mPmapWindow.draw(dc)
  else:
    var
      pmap = initPixelMap()
      rbuf = initRenderingBuffer()

    pmap.create(self.mPmapWindow.width(), self.mPmapWindow.height(), self.mSysBpp)
    rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
    convertPmap(rbuf, src, self.mFormat)
    pmap.draw(dc)

proc savePmap(self: var PlatformSpecific, fn: string, idx: int, src: var RenderingBuffer): bool =
  if self.mSysFormat == self.mFormat:
    return self.mPmapImage[idx].saveAsBmp(fn)
  else:
    var
      pmap = initPixelMap()
      rbuf = initRenderingBuffer()

    pmap.create(self.mPmapImage[idx].width(), self.mPmapImage[idx].height(), self.mSysBpp)
    rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
    convertPmap(rbuf, src, self.mFormat)
    return pmap.saveAsBmp(fn)

proc loadPmap(self: var PlatformSpecific, fn: string, idx: int, dst: var RenderingBuffer): bool =
  var
    pmap= initPixelMap()
    rbuf = initRenderingBuffer()

  if not pmap.loadFromBmp(fn): return false

  rbuf.attach(pmap.buf(), pmap.width(), pmap.height(), if self.mFlipY: pmap.stride() else: -pmap.stride())
  self.mPmapImage[idx].create(pmap.width(), pmap.height(), self.mBpp, 0)

  dst.attach(self.mPmapImage[idx].buf(),
             self.mPmapImage[idx].width(),
             self.mPmapImage[idx].height(),
             if self.mFlipY: self.mPmapImage[idx].stride() else: -self.mPmapImage[idx].stride())

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

proc translate(self: var PlatformSpecific, keyCode: int): KeyCode =
  self.mLastTranslatedKey = if keyCode > 255: key_none else: self.mKeyMap[keyCode]
  result = self.mLastTranslatedKey

proc init[T](self: PlatformSupport[T], format: PixFormat, flipY: bool) =
  self.mSpecific = initPlatformSpecific(format, flipY)
  self.mFormat = format
  self.mBpp = self.mSpecific.mBpp
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY = flipY
  self.mInitialWidth = 10
  self.mInitialHeight = 10
  self.mCaption = "Anti-Grain Geometry Application"

proc caption[T](self: PlatformSupport[T], cap: string) =
  self.mCaption = cap
  self.mSpecific.mHwnd != NULL:
   setWindowText(self.mSpecific.mHwnd, self.mCaption)

proc loadImg[T](self: PlatformSupport[T], idx: int, file: string): bool =
  if idx < maxImages:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"
    return self.mSpecific.loadPmap(fileName, idx, self.mRbufImage[idx])
  result = true

proc saveImg[T](self: PlatformSupport[T], idx: int, file: string): bool =
  if idx < maxImages:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"
    return self.mSpecific.savePmap(fileName, idx, self.mRbufImage[idx])
  result = true

proc createImg[T](self: PlatformSupport[T], idx: int, width = 0, height = 0): bool =
  var
    width = width
    height = height

  if idx < maxImages:
    var stride = self.mSpecific.mPmapImage[idx].stride()
    if width  == 0: width = self.mSpecific.mPmapWindow.width()
    if height == 0: height = self.mSpecific.mPmapWindow.height()

    self.mSpecific.mPmapImage[idx].create(width, height, self.mSpecific.mBpp)
    self.mRbufImage[idx].attach(self.mSpecific.mPmapImage[idx].buf(),
                                self.mSpecific.mPmapImage[idx].width(),
                                self.mSpecific.mPmapImage[idx].height(),
                                if self.mFlipY: stride else: - stride)
    return true
  result = false

proc getKeyFlags(wflags: int): InputFlags =
  if (wflags and MK_LBUTTON) != 0: result.incl mouse_left
  if (wflags and MK_RBUTTON) != 0: result.incl mouse_right
  if (wflags and MK_SHIFT  ) != 0: result.incl kbd_shift
  if (wflags and MK_CONTROL) != 0: result.incl kbd_ctrl

proc windowProc[T](hWnd: HWND, iMsg: WINUINT, wParam: WPARAM, lParam: LPARAM): LPARAM {.stdcall.} =
  var
    ps: PAINTSTRUCT
    paintDC: HDC
    app: PlatformSupport[T]
    cs = cast[LPCREATESTRUCT](lParam)

  if iMsg == WM_CREATE:
    app = cast[PlatformSupport[T]](cs.lpCreateParams)
  else:
    app = cast[PlatformSupport[T]](getWindowLongPtr(hWnd, GWLP_USER_DATA))

  if app == nil:
    if iMsg == WM_DESTROY:
      postQuitMessage(0)
      return 0
    defWindowProc(hWnd, msg, wParam, lParam)

  var dc = getDC(app.self.mSpecific.mHwnd)
  app.self.mSpecific.mCurrentDC = dc

  var ret = LRESULT(0)

  case iMsg
  of WM_CREATE: discard
  of WM_SIZE:
    app.self.mSpecific.createPmap(LOWORD(lParam), HIWORD(lParam), app.rbufWindow())
    app.transAffineResizing(LOWORD(lParam), HIWORD(lParam))
    app.onResize(LOWORD(lParam), HIWORD(lParam))
    app.forceRedraw()
  of WM_ERASEBKGND: discard
  of WM_LBUTTONDOWN:
    setCapture(app.self.mSpecific.mHwnd)
    app.self.mSpecific.mCurX = int(LOWORD(lParam))
    if app.flipY():
      app.self.mSpecific.mCurY = app.rbufWindow().height() - int(HIWORD(lParam))
    else:
      app.self.mSpecific.mCurY = int(HIWORD(lParam))
    app.self.mSpecific.mInputFlags.incl mouse_left
    app.self.mSpecific.mInputFlags.incl getKeyFlags(wParam)
    app.mCtrls.setCur(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY)
    if app.mCtrls.onMouseButtonDown(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY):
      app.onCtrlChange()
      app.forceRedraw()
    else:
      if app.mCtrls.inRect(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY):
        if app.mCtrls.setCur(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY):
          app.onCtrlChange()
          app.forceRedraw()
      else:
        app.onMouseButtonDown(app.self.mSpecific.mCurX,
                              app.self.mSpecific.mCurY,
                              app.self.mSpecific.mInputFlags)
  of WM_LBUTTONUP:
    releaseCapture()
    app.self.mSpecific.mCurX = int(LOWORD(lParam))
    if app.flipY():
      app.self.mSpecific.mCurY = app.rbufWindow().height() - int(HIWORD(lParam))
    else:
      app.self.mSpecific.mCurY = int(HIWORD(lParam))

    app.self.mSpecific.mInputFlags.incl mouse_left
    app.self.mSpecific.mInputFlags.incl getKeyFlags(wParam)

    if app.mCtrls.onMouseButtonUp(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY):
      app.onCtrlChange()
      app.forceRedraw()
    app.onMouseButtonUp(app.self.mSpecific.mCurX,
                        app.self.mSpecific.mCurY,
                        app.self.mSpecific.mInputFlags)
  of WM_RBUTTONDOWN:
    setCapture(app.self.mSpecific.mHwnd)
    app.self.mSpecific.mCurX = int(LOWORD(lParam))
    if app.flipY():
      app.self.mSpecific.mCurY = app.rbufWindow().height() - int(HIWORD(lParam))
    else:
      app.self.mSpecific.mCurY = int(HIWORD(lParam))

    app.self.mSpecific.mInputFlags.incl mouse_right
    app.self.mSpecific.mInputFlags.incl getKeyFlags(wParam)

    app.onMouseButtonDown(app.self.mSpecific.mCurX,
                          app.self.mSpecific.mCurY,
                          app.self.mSpecific.mInputFlags)
  of WM_RBUTTONUP:
    releaseCapture()
    app.self.mSpecific.mCurX = int(LOWORD(lParam))
    if app.flipY():
      app.self.mSpecific.mCurY = app.rbufWindow().height() - int(HIWORD(lParam))
    else:
      app.self.mSpecific.mCurY = int(HIWORD(lParam))

    app.self.mSpecific.mInputFlags.incl mouse_right
    app.self.mSpecific.mInputFlags.incl getKeyFlags(wParam)

    app.onMouseButtonUp(app.self.mSpecific.mCurX,
                        app.self.mSpecific.mCurY,
                        app.self.mSpecific.mInputFlags)
  of WM_MOUSEMOVE:
    app.self.mSpecific.mCurX = int(LOWORD(lParam))
    if app.flipY():
      app.self.mSpecific.mCurY = app.rbufWindow().height() - int(HIWORD(lParam))
    else:
      app.self.mSpecific.mCurY = int(HIWORD(lParam))

    app.self.mSpecific.mInputFlags = getKeyFlags(wParam)

    let flag = mouse_left in app.self.mSpecific.mInputFlags
    if app.mCtrls.onMouseMove(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY, flag):
      app.onCtrlChange()
      app.forceRedraw()
    else:
      if not app.mCtrls.inRect(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY):
        app.onMouseMove(app.self.mSpecific.mCurX, app.self.mSpecific.mCurY, app.self.mSpecific.mInputFlags)
  of WM_SYSKEYDOWN, WM_KEYDOWN:
    app.self.mSpecific.mLastTranslatedKey = key_none
    case wParam
    of VK_CONTROL:
      app.self.mSpecific.mInputFlags.incl kbd_ctrl
    of VK_SHIFT:
      app.self.mSpecific.mInputFlags.incl kbd_shift
    else:
      app.self.mSpecific.translate(wParam)

    if app.self.mSpecific.mLastTranslatedKey != key_none:
      var
        left  = false
        up    = false
        right = false
        down  = false

      case app.self.mSpecific.mLastTranslatedKey
      of key_left: left = true
      of key_up: up = true
      of key_right: right = true
      of key_down: down = true
      of key_f2:
        app.copyWindowToImg(maxImages - 1)
        app.saveImg(maxImages - 1, "screenshot")
      else: discard

      if window_process_all_keys in app.windowFlags():
        app.onKey(app.self.mSpecific.mCurX,
                  app.self.mSpecific.mCurY,
                  app.self.mSpecific.mLastTranslatedKey,
                  app.self.mSpecific.mInputFlags)
      else:
        if app.mCtrls.onArrowKeys(left, right, down, up):
          app.onCtrlChange()
          app.forceRedraw()
        else:
          app.onKey(app.self.mSpecific.mCurX,
                    app.self.mSpecific.mCurY,
                    app.self.mSpecific.mLastTranslatedKey,
                    app.self.mSpecific.mInputFlags)
  of WM_SYSKEYUP, WM_KEYUP:
    app.self.mSpecific.mLastTranslatedKey = key_none
    case wParam
    of VK_CONTROL:
      app.self.mSpecific.mInputFlags.excl kbd_ctrl
    of VK_SHIFT:
      app.self.mSpecific.mInputFlags.excl kbd_shift
  of WM_CHAR, WM_SYSCHAR:
    if app.self.mSpecific.mLastTranslatedKey == key_none:
      app.onKey(app.self.mSpecific.mCurX,
                app.self.mSpecific.mCurY,
                wParam,
                app.self.mSpecific.mInputFlags)

  of WM_PAINT:
    paintDC = beginPaint(hWnd, ps)
    app.self.mSpecific.mCurrentDC = paintDC
    if app.self.mSpecific.mRedrawFlags:
      app.onDraw()
      app.self.mSpecific.mRedrawFlags = false

    app.self.mSpecific.displayPmap(paintDC, app.rbufWindow())
    app.onPostDraw(paintDC)
    app.self.mSpecific.mCurrentDC = NULL
    endPaint(hWnd, ps)
  of WM_COMMAND: discard
  of WM_DESTROY:
    postQuitMessage(0)
  else:
    ret = defWindowProc(hWnd, msg, wParam, lParam)

  app.self.mSpecific.mCurrentDC = NULL
  releaseDC(app.self.mSpecific.mHwnd, dc)
  result = ret

proc init[T](self: PlatformSupport[T], width, height: int, flags: WindowFlags): bool =
  if self.mSpecific.mSysFormat == pix_format_undefined:
    return false

  self.mWindowFlags = flags
  var
    wflags = CS_OWNDC or CS_VREDRAW or CS_HREDRAW
    wc: WNDCLASS

  wc.lpszClassName = "AGGAppClass"
  wc.lpfnWndProc = windowProc[T]
  wc.style = wflags
  wc.hInstance = windowsInstance
  wc.hIcon     = NULL #LoadIcon(0, IDI_APPLICATION)
  wc.hCursor   = NULL #LoadCursor(0, IDC_ARROW)
  wc.hbrBackground = HBRUSH(COLOR_WINDOW+1)
  wc.lpszMenuName = "AGGAppMenu"
  wc.cbClsExtra = 0
  wc.cbWndExtra = 0
  registerClass(wc)

  wflags = WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX

  if window_resize in self.mWindowFlags:
    wflags = wflags or WS_THICKFRAME or WS_MAXIMIZEBOX

  self.mSpecific.mHwnd = createWindow("AGGAppClass",
    self.mCaption, wflags, 100, 100, width, height,
    0, 0, windowsInstance, 0)

  if self.mSpecific.mHwnd == NULL:
    return false


  var
    rct: RECT

  getClientRect(self.mSpecific.mHwnd, rct.addr)
  moveWindow(self.mSpecific.mHwnd,   # handle to window
               100,                  # horizontal position
               100,                  # vertical position
               width + (width - (rct.right - rct.left)),
               height + (height - (rct.bottom - rct.top)),
               FALSE)

  setWindowLongPtr(self.mSpecific.mHwnd, GWL_USERDATA, cast[LONG_PTR](self))
  self.mSpecific.createPmap(width, height, self.mRBufWindow)
  self.mInitialWidth = width
  self.mInitialHeight = height
  self.onInit()
  self.mSpecific.mRedrawFlags = true
  showWindow(self.mSpecific.mHwnd, windowsCmdShow)
  result = true

proc run[T](self: PlatformSupport[T]): int =
  var
    msg: MSG

  while true:
    if self.mWaitMode:
      if getMessage(msg, 0, 0, 0) == 0: break
      translateMessage(msg)
      dispatchMessage(msg)
    else:
      if peekMessage(msg, 0, 0, 0, PM_REMOVE) != NULL:
        translateMessage(msg)
        if msg.message == WM_QUIT:  break
        dispatchMessage(msg)
      else:
        self.onIdle()
  result = int(msg.wParam)

proc forceRedraw[T](self: PlatformSupport[T]) =
  self.mSpecific.mRedrawFlags = true
  invalidateRect(self.mSpecific.mHwnd, 0, FALSE)

proc updateWindow[T](self: PlatformSupport[T]) =
  var dc = getDC(self.mSpecific.mHwnd)
  self.mSpecific.displayPmap(dc, self.mRBufWindow)
  releaseDC(self.mSpecific.mHwnd, dc)

proc imgExt[T](self: PlatformSupport[T]): string = ".bmp"

proc rawDisplayHandler[T](self: PlatformSupport[T]): pointer =
  cast[pointer](self.mSpecific.mCurrentDC)

proc message[T](self: PlatformSupport[T], msg: string) =
  messageBox(self.mSpecific.mHwnd, msg, "AGG Message", MB_OK)

proc startTimer[T](self: PlatformSupport[T]) =
  queryPerformanceCounter(self.mSpecific.mSwStart)

proc elapsedTime[T](self: PlatformSupport[T]): float64 =
  var stop: LARGE_INTEGER
  queryPerformanceCounter(stop)
  result = float64(stop.QuadPart - self.mSpecific.mSwStart.QuadPart) * 1000.0 /
    float64(self.mSpecific.mSwFreq.QuadPart)

proc fullFileName[T](self: PlatformSupport[T], fileName: string): string =
  result = fileName
