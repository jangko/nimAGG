import sdl2.sdl as SDL, strutils

type
  PlatformSpecific[T] = ref object
    mFormat: PixFormat
    mSysFormat: PixFormat
    mFlipY: bool
    mBpp: int
    mSysBpp: int
    mRMask: uint
    mGMask: uint
    mBMask: uint
    mAMask: uint
    mUpdateFlag: bool
    mResizeFlag: bool
    mInitialized: bool
    mSurface: SDL.Surface
    mWindow: SDL.Window
    mRenderer: SDL.Renderer
    mSurfImg: array[maxImages, SDL.Surface]
    mCurX: int
    mCurY: int
    mSwFreq: uint64
    mSwStart: uint64

proc finalizer[T](self: PlatformSpecific[T]) =
  for x in self.mSurfImg:
    if x != nil:
      SDL.freeSurface(x)

  if self.mSurface != nil:
    SDL.freeSurface(self.mSurface)

  if self.mRenderer != nil:
    SDL.destroyRenderer(self.mRenderer)

  if self.mWindow != nil:
    SDL.destroyWindow(self.mWindow)

proc initPlatformSpecific[T](format: PixFormat, flipY: bool): PlatformSpecific[T] =
  new(result, finalizer[T])
  result.mFormat = format
  result.mSysFormat = pix_format_undefined
  result.mFlipY = flipY
  result.mBpp = 0
  result.mSysBpp = 0
  result.mUpdateFlag = true
  result.mResizeFlag = true
  result.mInitialized = false
  result.mSurface = nil
  result.mWindow = nil
  result.mRenderer = nil
  result.mCurX = 0
  result.mCurY = 0

  case result.mFormat
  of pix_format_gray8: result.mBpp = 8
  of pix_format_rgb565:
    result.mRMask = 0xF800
    result.mGMask = 0x7E0
    result.mBMask = 0x1F
    result.mAMask = 0
    result.mBpp = 16
  of pix_format_rgb555:
    result.mRMask = 0x7C00
    result.mGMask = 0x3E0
    result.mBMask = 0x1F
    result.mAMask = 0
    result.mBpp = 16
  of pix_format_rgb24:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF
      result.mGMask = 0xFF00
      result.mBMask = 0xFF0000
      result.mAMask = 0
    else:
      result.mRMask = 0xFF0000
      result.mGMask = 0xFF00
      result.mBMask = 0xFF
      result.mAMask = 0
    result.mBpp = 24
  of pix_format_bgr24:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF0000
      result.mGMask = 0xFF00
      result.mBMask = 0xFF
      result.mAMask = 0
    else:
      result.mRMask = 0xFF
      result.mGMask = 0xFF00
      result.mBMask = 0xFF0000
      result.mAMask = 0
    result.mBpp = 24
  of pix_format_bgra32:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF0000
      result.mGMask = 0xFF00
      result.mBMask = 0xFF
      result.mAMask = 0xFF000000'u
    else:
      result.mRMask = 0xFF00
      result.mGMask = 0xFF0000
      result.mBMask = 0xFF000000'u
      result.mAMask = 0xFF
    result.mBpp = 32
  of pix_format_abgr32:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF000000'u
      result.mGMask = 0xFF0000
      result.mBMask = 0xFF00
      result.mAMask = 0xFF
    else:
      result.mRMask = 0xFF
      result.mGMask = 0xFF00
      result.mBMask = 0xFF0000
      result.mAMask = 0xFF000000'u
    result.mBpp = 32
  of pix_format_argb32:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF00
      result.mGMask = 0xFF0000
      result.mBMask = 0xFF000000'u
      result.mAMask = 0xFF
    else:
      result.mRMask = 0xFF0000
      result.mGMask = 0xFF00
      result.mBMask = 0xFF
      result.mAMask = 0xFF000000'u
    result.mBpp = 32
  of pix_format_rgba32:
    when system.cpuEndian == littleEndian:
      result.mRMask = 0xFF
      result.mGMask = 0xFF00
      result.mBMask = 0xFF0000
      result.mAMask = 0xFF000000'u
    else:
      result.mRMask = 0xFF000000'u
      result.mGMask = 0xFF0000
      result.mBMask = 0xFF00
      result.mAMask = 0xFF
    result.mBpp = 32
  else:
    discard

  result.mSwFreq = SDL.getPerformanceFrequency()
  result.mSwStart = SDL.getPerformanceCounter()

proc init[T,R](self: GenericPlatform[T,R], format: PixFormat, flipY: bool) =
  type ValueT = getValueT(R)
  self.mSpecific = initPlatformSpecific[ValueT](format, flipY)
  self.mFormat   = format
  self.mBpp      = self.mSpecific.mBpp
  self.mWindowFlags = {}
  self.mWaitMode = true
  self.mFlipY    = flipY
  discard SDL.init(SDL.INIT_VIDEO)
  self.mCaption  = "Anti-Grain Geometry Application"

proc caption*[T,R](self: GenericPlatform[T,R], cap: string) =
  self.mCaption = cap
  if self.mSpecific.mInitialized:
    SDL.setWindowTitle(self.mSpecific.mWindow, cap)

proc resizeSurface[T,R](self: GenericPlatform[T,R], width, height: int): bool =
  type ValueT = getValueT(R)
  if self.mSpecific.mSurface != nil:
    SDL.freeSurface(self.mSpecific.mSurface)

  self.mSpecific.mSurface = SDL.createRGBSurface(
    0.cuint, width.cint, height.cint, self.mBpp.cint,
    self.mSpecific.mRMask.cuint,
    self.mSpecific.mGMask.cuint,
    self.mSpecific.mBMask.cuint,
    self.mSpecific.mAMask.cuint)

  if self.mSpecific.mSurface == nil:
    echo "cannot create surface"
    return false

  var s = self.mSpecific.mSurface

  discard SDL.lockSurface(s)
  self.mRBufWindow.attach(cast[ptr ValueT](s.pixels), s.w, s.h,
    if self.mFlipY: -s.pitch else: s.pitch)

  if not self.mSpecific.mInitialized:
    self.mInitialWidth = width
    self.mInitialHeight = height
    self.onInit()
    self.mSpecific.mInitialized = true

  self.onResize(self.mRBufWindow.width(), self.mRBufWindow.height())
  self.mSpecific.mUpdateFlag = true
  SDL.unlockSurface(s)
  result = true

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags): bool =
  self.mWindowFlags = flags

  var wflags: uint32 = 0

  if window_hidden notin flags:
    wflags = wflags or SDL.WINDOW_SHOWN

  if window_resize in flags:
    wflags = wflags or SDL.WINDOW_RESIZABLE

  if self.mSpecific.mWindow != nil:
    SDL.destroyWindow(self.mSpecific.mWindow)

  self.mSpecific.mWindow = SDL.createWindow(self.mCaption,
    WINDOWPOS_CENTERED.cint,
    WINDOWPOS_CENTERED.cint,
    width.cint, height.cint, wflags)

  if self.mSpecific.mWindow == nil:
    echo "SDL_CreateWindow Error: ", $SDL.getError()
    return false

  if self.mSpecific.mRenderer != nil:
    SDL.destroyRenderer(self.mSpecific.mRenderer)

  self.mSpecific.mRenderer = SDL.createRenderer(self.mSpecific.mWindow,
    -1, SDL.RENDERER_ACCELERATED or SDL.RENDERER_PRESENTVSYNC)

  if self.mSpecific.mRenderer == nil:
    return false

  result = self.resizeSurface(width, height)

proc init*[T,R](self: GenericPlatform[T,R], width, height: int, flags: WindowFlags, fileName: string): bool =
  if paramCount() > 0:
    if paramStr(1) == "-v":
      if self.init(width, height, {window_hidden}):
        self.mResizeMtx = initTransAffine()
        self.onDraw()
        self.copyWindowToImg(maxImages - 1)
        discard self.saveImg(maxImages - 1, fileName)
        return false
  result = self.init(width, height, flags)

proc updateWindow[T,R](self: GenericPlatform[T,R]) =
  var surface = self.mSpecific.mSurface
  var renderer = self.mSpecific.mRenderer

  var rect = SDL.Rect(x: 0, y: 0, w: surface.w, h: surface.h)

  # Convert to texture
  var texture = SDL.createTextureFromSurface(renderer, surface)
  if texture == nil: return

  # Render texture
  if renderer.renderCopy(texture, nil, addr(rect)) != 0:
    echo "renderer failed"

  # Clean
  SDL.destroyTexture(texture)

proc run[T,R](self: GenericPlatform[T,R]): int =
  var
    event: SDL.Event
    evFlag = false

  while true:
    if self.mSpecific.mUpdateFlag:
      self.onDraw()
      self.updateWindow()
      self.mSpecific.mRenderer.renderPresent()
      self.mSpecific.mUpdateFlag = false

    evFlag = false
    if self.mWaitMode:
      discard SDL.waitEvent(event.addr)
      evFlag = true
    else:
      if SDL.pollEvent(event.addr) != 0:
        evFlag = true
      else:
        self.onIdle()

    if evFlag:
      if event.kind == SDL.QUIT:
        break

      case event.kind
      of WINDOWEVENT:
        if event.window.event == WINDOWEVENT_RESIZED:
          if not self.resizeSurface(event.window.data1, event.window.data2):
            return -1

          self.onResize(self.mRBufwindow.width(), self.mRBufwindow.height())
          self.transAffineResizing(event.window.data1, event.window.data2)
          self.mSpecific.mUpdateFlag = true

      of KEYDOWN:
        var flags: InputFlags
        if (event.key.keysym.mods and KMOD_SHIFT.ord) != 0: flags.incl kbdShift
        if (event.key.keysym.mods and KMOD_CTRL.ord)  != 0: flags.incl kbdCtrl

        var
          left  = false
          up    = false
          right = false
          down  = false

        case event.key.keysym.sym
        of SDL.K_LEFT: left = true
        of SDL.K_UP: up = true
        of SDL.K_RIGHT: right = true
        of SDL.K_DOWN: down = true
        else: discard

        if self.mCtrls.onArrowKeys(left, right, down, up):
          self.onCtrlChange()
          self.forceRedraw()
        else:
          self.onKey(self.mSpecific.mCurX,
                     self.mSpecific.mCurY,
                     event.key.keysym.sym.int,
                     flags)
      of SDL.MOUSEMOTION:
        var y = int(event.motion.y)
        if self.mFlipY:
          y = self.mRBufwindow.height() - event.motion.y

        self.mSpecific.mCurX = event.motion.x
        self.mSpecific.mCurY = y

        var flags: InputFlags
        if (event.motion.state and SDL.BUTTON_LMASK) != 0: flags.incl mouseLeft
        if (event.motion.state and SDL.BUTTON_RMASK) != 0: flags.incl mouseRight

        let mouseLeftPressed = mouseLeft in flags
        if self.mCtrls.onMouseMove(
          self.mSpecific.mCurX.float64,
          self.mSpecific.mCurY.float64, mouseLeftPressed):
          self.onCtrlChange()
          self.forceRedraw()
        else:
          self.onMouseMove(self.mSpecific.mCurX,
                           self.mSpecific.mCurY, flags)

        var eventtrash: SDL.Event
        while SDL.peepEvents(eventtrash.addr, 1, SDL.GETEVENT, SDL.MOUSEMOTION, SDL.MOUSEMOTION) != 0:
          discard

      of SDL.MOUSEBUTTONDOWN:
        var y = int(event.button.y)
        if self.mFlipY:
          y = self.mRBufwindow.height() - event.button.y

        self.mSpecific.mCurX = event.button.x
        self.mSpecific.mCurY = y
        var flags: InputFlags

        case event.button.button
        of SDL.BUTTON_LEFT:
          flags.incl mouseLeft
          discard self.mCtrls.setCur(self.mSpecific.mCurX.float64, self.mSpecific.mCurY.float64)

          if self.mCtrls.onMouseButtonDown(self.mSpecific.mCurX.float64, self.mSpecific.mCurY.float64):
            self.onCtrlChange()
            self.forceRedraw()
          else:
            if self.mCtrls.inRect(self.mSpecific.mCurX.float64, self.mSpecific.mCurY.float64):
              if self.mCtrls.setCur(self.mSpecific.mCurX.float64, self.mSpecific.mCurY.float64):
                self.onCtrlChange()
                self.forceRedraw()
            else:
              self.onMouseButtonDown(self.mSpecific.mCurX, self.mSpecific.mCurY, flags)
        of SDL.BUTTON_RIGHT:
          flags.incl mouseRight
          self.onMouseButtonDown(self.mSpecific.mCurX, self.mSpecific.mCurY, flags)
        else: discard

      of SDL.MOUSEBUTTONUP:
        var y = int(event.button.y)
        if self.mFlipY:
          y = self.mRBufwindow.height() - event.button.y

        self.mSpecific.mCurX = event.button.x
        self.mSpecific.mCurY = y
        var flags: InputFlags

        if self.mCtrls.onMouseButtonUp(self.mSpecific.mCurX.float64, self.mSpecific.mCurY.float64):
          self.onCtrlChange()
          self.forceRedraw()

        self.onMouseButtonUp(self.mSpecific.mCurX, self.mSpecific.mCurY, flags)
      else:
        discard

  result = 0

proc imgExt[T,R](self: GenericPlatform[T,R]): string = ".bmp"

proc fullFileName[T,R](self: GenericPlatform[T,R], fileName: string): string =
  result = fileName

proc loadImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  type ValueT = getValueT(R)
  if idx < maxImages:
    if self.mSpecific.mSurfImg[idx] != nil:
      SDL.freeSurface(self.mSpecific.mSurfImg[idx])

    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"

    var tmp = SDL.loadBMP(fileName)
    if tmp == nil:
      echo "Couldn't load $1: $2" % [fileName, $SDL.getError()]
      return false

    var format: SDL.PixelFormat

    format.palette = nil
    format.BitsPerPixel = uint8(self.mBpp)
    format.BytesPerPixel = uint8(self.mBpp shr 8)
    format.Rmask = self.mSpecific.mRMask.cuint
    format.Gmask = self.mSpecific.mGMask.cuint
    format.Bmask = self.mSpecific.mBMask.cuint
    format.Amask = self.mSpecific.mAMask.cuint
    format.Rshift = 0
    format.Gshift = 0
    format.Bshift = 0
    format.Ashift = 0
    format.Rloss = 0
    format.Gloss = 0
    format.Bloss = 0
    format.Aloss = 0

    self.mSpecific.mSurfImg[idx] = SDL.convertSurface(tmp,
      format.addr, 0)

    SDL.freeSurface(tmp)

    if self.mSpecific.mSurfImg[idx] == nil:
      echo "failed to convert surface"
      return false

    var s = self.mSpecific.mSurfImg[idx]
    self.mRbufImage[idx].attach(cast[ptr ValueT](s.pixels),
      s.w, s.h, if self.mFlipY: -s.pitch else: s.pitch)

    return true

  result = false

proc saveImg[T,R](self: GenericPlatform[T,R], idx: int, file: string): bool =
  if idx < maxImages and self.mSpecific.mSurfImg[idx] != nil:
    var fileName = toLowerAscii(file)
    if rfind(fileName, ".bmp") == -1:
      fileName.add ".bmp"
    return SDL.saveBMP(self.mSpecific.mSurfImg[idx], fileName) == 0
  result = false;

proc createImg[T,R](self: GenericPlatform[T,R], idx: int, w = 0, h = 0): bool =
  type ValueT = getValueT(R)

  if idx < maxImages:
    if self.mSpecific.mSurfImg[idx] != nil:
      SDL.freeSurface(self.mSpecific.mSurfImg[idx])

    self.mSpecific.mSurfImg[idx] = SDL.createRGBSurface(
      0.cuint, w.cint, h.cint, self.mBpp.cint,
      self.mSpecific.mRMask.cuint,
      self.mSpecific.mGMask.cuint,
      self.mSpecific.mBMask.cuint,
      self.mSpecific.mAMask.cuint)

    if self.mSpecific.mSurfImg[idx] == nil:
      echo "Couldn't create image: ", SDL.getError()
      return false

    var s = self.mSpecific.mSurfImg[idx]
    self.mRBufImage[idx].attach(cast[ptr ValueT](s.pixels),
      s.w, s.h, if self.mFlipY: -s.pitch else: s.pitch)

    return true

  result = false

proc rawDisplayHandler[T,R](self: GenericPlatform[T,R]): pointer =
  cast[pointer](self.mSpecific.mRenderer)

proc startTimer[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mSwStart = SDL.getPerformanceCounter()

proc elapsedTime[T,R](self: GenericPlatform[T,R]): float64 =
  let stop = SDL.getPerformanceCounter()
  result = float64(stop - self.mSpecific.mSwStart) * 1000.0 /
    float64(self.mSpecific.mSwFreq)

proc message[T,R](self: GenericPlatform[T,R], msg: string) =
  echo msg

proc forceRedraw[T,R](self: GenericPlatform[T,R]) =
  self.mSpecific.mUpdateFlag = true