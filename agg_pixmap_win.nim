import winapi, agg_basics

type
  PixelMap*[T] = object
    mBmp: ptr BITMAPINFO
    mBuf: ptr T
    mBpp: int
    mIsInternal: bool
    mImgSize: int
    mFullSize: int
    mBuffer: seq[T]

proc initPixelMap*[T](): PixelMap[T] =
  result.mBmp = nil
  result.mBuf = nil
  result.mBpp = 0
  result.mIsInternal = false
  result.mImgSize = 0
  result.mFullSize = 0
  result.mBuffer = nil

proc destroy*[T](self: var PixelMap[T]) =
  self.mBmp = nil
  self.mIsInternal = false
  self.mBuf = nil

proc calcPaletteSize(clrUsed, bitsPerPixel: int): int =
  var paletteSize = 0
  if bitsPerPixel <= 8:
    paletteSize = clrUsed

    if paletteSize == 0:
      paletteSize = 1 shl bitsPerPixel

  result = paletteSize

proc calcPaletteSize(bmp: ptr BITMAPINFO): int =
  if bmp == nil: return 0
  result = calcPaletteSize(bmp.bmiHeader.biClrUsed, bmp.bmiHeader.biBitCount)

proc calcRowLen(width, bitsPerPixel: int): int =
  var
    n = width
    k: int

  case bitsPerPixel
  of 1:
    k = n
    n = n shr 3
    if (k and 7) != 0: inc n
  of 4:
    k = n
    n = n shr 1
    if (k and 3) != 0: inc n
  of 8: discard
  of 16: n *= 2
  of 24: n *= 3
  of 32: n *= 4
  of 48: n *= 6
  of 64: n *= 8
  else: n = 0
  result = ((n + 3) shr 2) shl 2

proc createBitmapInfo*[T](self: var PixelMap[T], width, height, bitsPerPixel: int): ptr BITMAPINFO =
  var
    lineLen = calcRowLen(width, bitsPerPixel)
    imgSize = lineLen * height
    rgbSize = calcPaletteSize(0, bitsPerPixel) * sizeof(RGBQUAD)
    fullSize = sizeof(BITMAPINFOHEADER) + rgbSize + imgSize

  if self.mBuffer.isNil:
    self.mBuffer = newSeq[T](fullSize div sizeof(T))

  if self.mBuffer.len < fullSize:
    self.mBuffer.setLen(fullSize)

  var bmp = cast[ptr BITMAPINFO](self.mBuffer[0].addr)

  bmp.bmiHeader.biSize   = DWORD(sizeof(BITMAPINFOHEADER))
  bmp.bmiHeader.biWidth  = LONG(width)
  bmp.bmiHeader.biHeight = LONG(height)
  bmp.bmiHeader.biPlanes = 1
  bmp.bmiHeader.biBitCount = bitsPerPixel.int16
  bmp.bmiHeader.biCompression = 0
  bmp.bmiHeader.biSizeImage = DWORD(imgSize)
  bmp.bmiHeader.biXPelsPerMeter = 0
  bmp.bmiHeader.biYPelsPerMeter = 0
  bmp.bmiHeader.biClrUsed = 0
  bmp.bmiHeader.biClrImportant = 0
  result = bmp

proc createGrayScalePalette(bmp: ptr BITMAPINFO) =
  if bmp == nil: return

  var
    rgbSize = calcPaletteSize(bmp)
    rgb = bmp.bmiColors[0].addr
    brightness: int

  for i in 0.. <rgbSize:
    brightness   = (255 * i) div (rgbSize - 1)
    rgb.rgbBlue  = cast[int8](brightness)
    rgb.rgbGreen = cast[int8](brightness)
    rgb.rgbRed   = cast[int8](brightness)
    rgb.rgbReserved = 0
    inc rgb

proc calcFullSize(bmp: ptr BITMAPINFO): int =
  if bmp == nil: return 0
  result = sizeof(BITMAPINFOHEADER) +
    sizeof(RGBQUAD) * calcPaletteSize(bmp) +
    bmp.bmiHeader.biSizeImage

proc calcHeaderSize(bmp: ptr BITMAPINFO): int =
  if bmp == nil: return 0
  result = sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * calcPaletteSize(bmp)

proc calcImagePtr(bmp: ptr BITMAPINFO): ptr uint8 =
  if bmp == nil: return nil
  result = cast[ptr uint8](bmp) + calcHeaderSize(bmp)

proc createFromBmp[T](self: var PixelMap[T], bmp: ptr BITMAPINFO) =
  if bmp != nil:
    let stride = calcRowLen(bmp.bmiHeader.biWidth, bmp.bmiHeader.biBitCount)
    self.mImgSize   = stride * bmp.bmiHeader.biHeight
    self.mFullSize  = calcFullSize(bmp)
    self.mBmp       = bmp
    self.mBuf       = cast[ptr T](calcImagePtr(bmp))

proc create*[T](self: var PixelMap[T], width, height: int, org: int, clearVal: int = 256) =
  var
    width = width
    height = height

  self.destroy()
  if width  == 0:  width = 1
  if height == 0: height = 1
  self.mBpp = org

  self.createFromBmp(self.createBitmapInfo(width, height, self.mBpp))
  createGrayScalePalette(self.mBmp)
  self.mIsInternal = true
  if clearVal <= 255:
    setMem(self.mBuf, clearVal, self.mImgSize)

proc createDibSectionFromArgs[T](self: var PixelMap[T], hdc: HDC,
  width, height, bitsPerPixel: int): HBITMAP =
  var
    lineLen  = calcRowLen(width, bitsPerPixel)
    imgSize  = lineLen * height
    rgbSize  = calcPaletteSize(0, bitsPerPixel) * sizeof(RGBQUAD)
    fullSize = sizeof(BITMAPINFOHEADER) + rgbSize

  self.mBuffer = newSeq[T](fullSize div sizeof(T))
  var bmp = cast[ptr BITMAPINFO](self.mBuffer[0].addr)

  bmp.bmiHeader.biSize   = DWORD(sizeof(BITMAPINFOHEADER))
  bmp.bmiHeader.biWidth  = LONG(width)
  bmp.bmiHeader.biHeight = LONG(height)
  bmp.bmiHeader.biPlanes = 1
  bmp.bmiHeader.biBitCount = bitsPerPixel.int16
  bmp.bmiHeader.biCompression = 0
  bmp.bmiHeader.biSizeImage = DWORD(imgSize)
  bmp.bmiHeader.biXPelsPerMeter = 0
  bmp.bmiHeader.biYPelsPerMeter = 0
  bmp.bmiHeader.biClrUsed = 0
  bmp.bmiHeader.biClrImportant = 0

  var
    imgPtr: pointer = nil
    hBitmap = createDIBSection(hdc, bmp[], DIB_RGB_COLORS, imgPtr, NULL, 0)

  if imgPtr != nil:
    self.mImgSize  = calcRowLen(width, bitsPerPixel) * height
    self.mFullSize = 0
    self.mBmp      = bmp
    self.mBuf      = cast[ptr uint8](imgPtr)

  result = hBitmap

proc createDibSection*[T](self: var PixelMap[T], hdc: HDC, width, height: int,
  org: int, clearVal: int): HBITMAP =
  var
    width = width
    height = height

  self.destroy()

  if width == 0:  width  = 1
  if height == 0: height = 1
  self.mBpp = org

  var hBitmap = self.createDibSectionFromArgs(hdc, width, height, self.mBpp)
  createGrayScalePalette(self.mBmp)
  self.mIsInternal = true
  if clearVal <= 255:
    setMem(self.mBuf, clearVal, self.mImgSize)
  result = hBitmap

proc clear*[T](self: var PixelMap[T], clearVal: int) =
  if self.mBuf != nil:
    setMem(self.mBuf, clearVal, self.mImgSize)

proc attachToBmp*[T](self: var PixelMap[T], bmp: ptr BITMAPINFO) =
  if bmp != nil:
    self.destroy()
    self.createFromBmp(bmp)
    self.mIsInternal = false

proc draw*(self: var PixelMap, hdc: HDC, deviceRect: ptr RECT = nil, bmpRect: ptr RECT = nil) =
  if self.mBmp == nil or self.mBuf == nil: return

  var
    bmpX = 0
    bmpY = 0
    bmpWidth  = self.mBmp.bmiHeader.biWidth
    bmpHeight = self.mBmp.bmiHeader.biHeight
    deviceX = 0
    deviceY = 0
    deviceWidth  = self.mBmp.bmiHeader.biWidth
    deviceHeight = self.mBmp.bmiHeader.biHeight

  if bmpRect != nil:
    bmpX      = bmpRect.left
    bmpY      = bmpRect.top
    bmpWidth  = bmpRect.right  - bmpRect.left
    bmpHeight = bmpRect.bottom - bmpRect.top

  deviceX      = bmpX
  deviceY      = bmpY
  deviceWidth  = bmpWidth
  deviceHeight = bmpHeight

  if deviceRect != nil:
    deviceX      = deviceRect.left
    deviceY      = deviceRect.top
    deviceWidth  = deviceRect.right  - deviceRect.left
    deviceHeight = deviceRect.bottom - deviceRect.top

  if deviceWidth != bmpWidth or deviceHeight != bmpHeight:
    discard setStretchBltMode(hdc, COLORONCOLOR)
    discard stretchDIBits(
      hdc,                  # handle of device context
      int32(deviceX),       # x-coordinate of upper-left corner of source rect.
      int32(deviceY),       # y-coordinate of upper-left corner of source rect.
      int32(deviceWidth),   # width of source rectangle
      int32(deviceHeight),  # height of source rectangle
      int32(bmpX),
      int32(bmpY),          # x, y -coordinates of upper-left corner of dest. rect.
      int32(bmpWidth),      # width of destination rectangle
      int32(bmpHeight),     # height of destination rectangle
      self.mBuf,            # address of bitmap bits
      self.mBmp[],          # address of bitmap data
      DIB_RGB_COLORS,       # usage
      SRCCOPY)              # raster operation code
  else:
    discard setDIBitsToDevice(
      hdc,                  # handle to device context
      int32(deviceX),       # x-coordinate of upper-left corner of
      int32(deviceY),       # y-coordinate of upper-left corner of
      DWORD(deviceWidth),   # source rectangle width
      DWORD(deviceHeight),  # source rectangle height
      int32(bmpX),          # x-coordinate of lower-left corner of
      int32(bmpY),          # y-coordinate of lower-left corner of
      WINUINT(0),           # first scan line in array
      WINUINT(bmpHeight),   # number of scan lines
      self.mBuf,            # address of array with DIB bits
      self.mBmp[],          # address of structure with bitmap info.
      DIB_RGB_COLORS)       # RGB or palette indexes

proc draw*[T](self: var PixelMap[T], hdc: HDC, x, y: int, scale: float64) =
  if self.mBmp == nil or self.mBuf == nil: return

  var
    width  = int(self.mBmp.bmiHeader.biWidth.float64 * scale)
    height = int(self.mBmp.bmiHeader.biHeight.float64 * scale)
    rect: RECT

  rect.left   = LONG(x)
  rect.top    = LONG(y)
  rect.right  = LONG(x + width)
  rect.bottom = LONG(y + height)
  self.draw(hdc, rect.addr, nil)


proc blend[T](self: var PixelMap[T], hdc: HDC, deviceRect: ptr RECT, bmpRect: ptr RECT) =
  when not defined(AGG_BMP_ALPHA_BLEND):
    self.draw(hdc, deviceRect, bmpRect)
  else:
    if self.mBpp != 32:
      self.draw(hdc, deviceRect, bmpRect)
      return

    if self.mBmp == nil or self.mBuf == nil: return

    var
      bmpX = 0
      bmpY = 0
      bmpWidth  = self.mBmp.bmiHeader.biWidth
      bmpHeight = self.mBmp.bmiHeader.biHeight
      deviceX = 0
      deviceY = 0
      deviceWidth  = self.mBmp.bmiHeader.biWidth
      deviceHeight = self.mBmp.bmiHeader.biHeight

    if bmpRect != nil:
      bmpX      = bmpRect.left
      bmpY      = bmpRect.top
      bmpWidth  = bmpRect.right  - bmpRect.left
      bmpHeight = bmpRect.bottom - bmpRect.top

    deviceX      = bmpX;
    deviceY      = bmpY;
    deviceWidth  = bmpWidth;
    deviceHeight = bmpHeight;

    if deviceRect != nil:
      deviceX      = deviceRect.left
      deviceY      = deviceRect.top
      deviceWidth  = deviceRect.right  - deviceRect.left
      deviceHeight = deviceRect.bottom - deviceRect.top

    var
      memDC = createCompatibleDC(hdc)
      buf: ptr uint8
      bmp = createDIBSection(memDC, self.mBmp, DIB_RGB_COLORS, buf, 0, 0)

    copyMem(buf, self.mBuf, self.mBmp.bmiHeader.biSizeImage)

    var
      temp = selectObject(memDC, bmp)
      blend: BLENDFUNCTION

    blend.BlendOp = AC_SRC_OVER
    blend.BlendFlags = 0
    blend.AlphaFormat = AC_SRC_ALPHA
    blend.SourceConstantAlpha = 255

    discard alphaBlend(hdc, deviceX, deviceY, deviceWidth, deviceHeight,
      memDC, bmpX, bmpY, bmpWidth, bmpHeight, blend)

    selectObject(memDC, temp)
    deleteObject(bmp)
    deleteObject(memDC)

proc blend*[T](self: var PixelMap[T], hdc: HDC, x, y: int, scale: float64) =
  if self.mBmp == nil or self.mBuf == nil: return
  var
    width  = int(self.mBmp.bmiHeader.biWidth.float64 * scale)
    height = int(self.mBmp.bmiHeader.biHeight.float64 * scale)
    rect: RECT

  rect.left   = LONG(x)
  rect.top    = LONG(y)
  rect.right  = LONG(x + width)
  rect.bottom = LONG(y + height)
  self.blend(hdc, rect.addr, nil)

type
  BMPHeader = object
    fileSize: DWORD
    reserved1: WORD
    reserved2: WORD
    offset: DWORD

proc loadFromBmp[T](self: var PixelMap[T], fd: File): bool =
  var
    signature: WORD
    bmh: BMPHeader
    bmi: ptr BITMAPINFO
    bmpSize: int

  discard fd.readBuffer(signature.addr, sizeof(WORD))
  discard fd.readBuffer(bmh.addr, sizeof(bmh))
  if signature != 0x4D42: return false

  bmpSize = bmh.fileSize - sizeof(BITMAPFILEHEADER)
  self.mBuffer = newSeq[T](bmpSize div sizeof(T))
  bmi = cast[ptr BITMAPINFO](self.mBuffer[0].addr)

  if fd.readBuffer(bmi, bmpSize) != bmpSize: return false

  self.destroy()
  self.mBpp = bmi.bmiHeader.biBitCount
  self.createFromBmp(bmi)
  self.mIsInternal = true
  result = true

proc loadFromBmp*[T](self: var PixelMap[T], fileName: string): bool =
  var
    fd = open(fileName, fmRead)

  if fd != nil:
    result = self.loadFromBmp(fd)
    fd.close()

proc saveAsBmp[T](self: PixelMap[T], fd: File): bool =
  if self.mBmp == nil: return false

  var
    signature = WORD(0x4D42)
    bmh: BMPHeader

  bmh.offset    = DWORD(calcHeaderSize(self.mBmp) + 14)
  bmh.fileSize  = DWORD(bmh.offset + self.mImgSize)
  bmh.reserved1 = 0
  bmh.reserved2 = 0

  discard fd.writeBuffer(signature.addr, sizeof(WORD))
  discard fd.writeBuffer(bmh.addr, sizeof(bmh))
  discard fd.writeBuffer(self.mBmp, self.mFullSize)
  result = true

proc saveAsBmp*[T](self: PixelMap[T], fileName: string): bool =
  var
    fd = open(filename, fmWrite)

  if fd != nil:
    result = self.saveAsBmp(fd)
    fd.close()

proc buf*[T](self: PixelMap[T]): ptr T =
  result = self.mBuf

proc width*[T](self: PixelMap[T]): int =
  result = self.mBmp.bmiHeader.biWidth

proc height*[T](self: PixelMap[T]): int =
  result = self.mBmp.bmiHeader.biHeight

proc stride*[T](self: PixelMap[T]): int =
  result = calcRowLen(self.mBmp.bmiHeader.biWidth, self.mBmp.bmiHeader.biBitCount)
  result = result div sizeof(T)

proc bpp*[T](self: PixelMap[T]): int = self.mBpp
