import scanline_storage_aa, scanline_storage_bin, scanline_u
import scanline_bin, path_storage_integer, rasterizer_scanline_aa
import conv_curve, font_types, trans_affine, basics
import strutils, bitset_iterator, math, renderer_scanline
import freetype / [freetype, ftimage, ftoutln, fttypes, fterrdef]
include freetype.ftimport

type
  FontEngineFreetypeBase* = ref object of RootObj
    mFlag32: bool
    mChangeStamp: int
    mLastError: FT_Error
    mName: string
    mFaceIndex: int
    mSignature: string
    mHeight: FT_F26Dot6
    mWidth: FT_F26Dot6
    mHinting: bool
    mFlipY: bool
    mLibraryInitialized: bool

    mCharMap: FT_Encoding
    mLibrary: FT_Library    # handle to library
    mFaces: seq[FT_Face]      # A pool of font faces
    mCurFace: FT_Face  # handle to the current face object

    mFaceNames: seq[string]
    mNumFaces: int
    mMaxFaces: int
    mResolution: FT_UInt
    mGlyphRendering: GlyphRendering
    mGlyphIndex: FT_UInt
    mDataSize:int
    mDataType: GlyphDataType

    mBounds: RectI
    mAdvanceX: float64
    mAdvanceY: float64
    mAffine: TransAffine

    mPath16: PathStorageInteger[int16]
    mPath32: PathStorageInteger[int32]
    mCurves16: ConvCurve[PathStorageInteger[int16]]
    mCurves32: ConvCurve[PathStorageInteger[int32]]
    mScanlineAA: ScanlineU8
    mScanlineBin: ScanlineBin
    mScanlinesAA: ScanlineStorageAA8
    mScanlinesBin: ScanlineStorageBin
    mRasterizer: RasterizerScanlineAA
    msg: FT_Error_Msg

proc crc32[T](crc: uint32, buf: T): uint32 =
  const kcrc32 = [ 0'u32, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190,
    0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320'u32, 0xf00f9344'u32, 0xd6d6a3e8'u32,
    0xcb61b38c'u32, 0x9b64c2b0'u32, 0x86d3d2d4'u32, 0xa00ae278'u32, 0xbdbdf21c'u32]

  var crcu32 = not crc
  for b in buf:
    crcu32 = (crcu32 shr 4) xor kcrc32[(crcu32.int and 0xF) xor (int(b) and 0xF)]
    crcu32 = (crcu32 shr 4) xor kcrc32[(crcu32.int and 0xF) xor (int(b) shr 4)]

  result = not crcu32

proc dbl_to_plain_fx(d: float64): int {.inline.} =
  result = int(d * 65536.0)

proc dbl_to_int26p6(p: float64): int {.inline.} =
  result = int(p * 64.0 + 0.5)

proc int26p6_to_dbl(p: int): float64 {.inline.} =
  result = float64(p) / 64.0

type
  Decomposer[T] = object
    mtx: TransAffine
    path: ptr T
    flipY: bool
    firstTime: bool

proc initDecomposer[T](mtx: TransAffine, path: var T, flipY: bool): Decomposer[T] =
  result.mtx = mtx
  result.path = path.addr
  result.flipY = flipY
  result.firstTime = true

proc decomp_moveTo[T](to: var FT_Vector; user: pointer): cint {.ftcallback.} =
  type ValueT = getValueT(T)
  var self = cast[ptr Decomposer[T]](user)
  if not self.firstTime: self.path[].closePolygon()
  self.firstTime = false

  var
    x1 = int26p6_to_dbl(to.x)
    y1 = int26p6_to_dbl(to.y)

  if self.flipY: y1 = -y1
  self.mtx.transform(x1, y1)
  self.path[].moveTo(ValueT(dbl_to_int26p6(x1)), ValueT(dbl_to_int26p6(y1)))

proc decomp_lineTo[T](to: var FT_Vector; user: pointer): cint {.ftcallback.} =
  type ValueT = getValueT(T)
  var self = cast[ptr Decomposer[T]](user)
  var
    x1 = int26p6_to_dbl(to.x)
    y1 = int26p6_to_dbl(to.y)

  if self.flipY:
    y1 = -y1

  self.mtx.transform(x1, y1)
  self.path[].lineTo(ValueT(dbl_to_int26p6(x1)), ValueT(dbl_to_int26p6(y1)))

proc decomp_conicTo[T](control, to: var FT_Vector; user: pointer): cint {.ftcallback.} =
  type ValueT = getValueT(T)
  var self = cast[ptr Decomposer[T]](user)

  var
    x1 = int26p6_to_dbl(control.x)
    y1 = int26p6_to_dbl(control.y)
    x2 = int26p6_to_dbl(to.x)
    y2 = int26p6_to_dbl(to.y)

  if self.flipY:
    y1 = -y1
    y2 = -y2

  self.mtx.transform(x1, y1)
  self.mtx.transform(x2, y2)
  self.path[].curve3(ValueT(dbl_to_int26p6(x1)),
                     ValueT(dbl_to_int26p6(y1)),
                     ValueT(dbl_to_int26p6(x2)),
                     ValueT(dbl_to_int26p6(y2)))

proc decomp_cubicTo[T](control1, control2, to: var FT_Vector; user: pointer): cint {.ftcallback.} =
  type ValueT = getValueT(T)
  var self = cast[ptr Decomposer[T]](user)

  var
    x1 = int26p6_to_dbl(control1.x)
    y1 = int26p6_to_dbl(control1.y)
    x2 = int26p6_to_dbl(control2.x)
    y2 = int26p6_to_dbl(control2.y)
    x3 = int26p6_to_dbl(to.x)
    y3 = int26p6_to_dbl(to.y)

  if self.flipY:
    y1 = -y1
    y2 = -y2
    y3 = -y3

  self.mtx.transform(x1, y1)
  self.mtx.transform(x2, y2)
  self.mtx.transform(x3, y3)
  self.path[].curve4(ValueT(dbl_to_int26p6(x1)),
                     ValueT(dbl_to_int26p6(y1)),
                     ValueT(dbl_to_int26p6(x2)),
                     ValueT(dbl_to_int26p6(y2)),
                     ValueT(dbl_to_int26p6(x3)),
                     ValueT(dbl_to_int26p6(y3)))

proc decompose_ft_outline[PathStorageT](outline: var FT_Outline, flipY: bool,
  mtx: TransAffine, path: var PathStorageT): bool =

  var decomp = initDecomposer(mtx, path, flipY)
  var funcs: FT_Outline_Funcs

  funcs.moveTo  = decomp_moveTo[PathStorageT]
  funcs.lineTo  = decomp_lineTo[PathStorageT]
  funcs.conicTo = decomp_conicTo[PathStorageT]
  funcs.cubicTo = decomp_cubicTo[PathStorageT]
  funcs.shift   = 0
  funcs.delta   = 0

  var error = outline.decompose(funcs, decomp.addr)
  if error != 0:
    echo "decompose error"
    return false
  if not decomp.firstTime: path.closePolygon()

  result = true

proc decompose_ft_bitmap_mono[Scanline, ScanlineStorage](bitmap: FT_Bitmap,
  x, y: int, flipY: bool, sl: var Scanline, storage: var ScanlineStorage) =

  var
    buf = cast[ptr uint8](bitmap.buffer)
    pitch = int(bitmap.pitch)
    y = y

  sl.reset(x, x + int(bitmap.width))
  storage.prepare()

  if flipY:
    inc(buf, int(bitmap.pitch) * int(bitmap.rows - 1))
    inc(y, int(bitmap.rows))
    pitch = -pitch

  for i in 0..<int(bitmap.rows):
    sl.resetSpans()
    var bits = initBitsetIterator(buf, 0)

    for j in 0..<int(bitmap.width):
      if bits.bit() != 0:
        sl.addCell(x + j, coverFull)
      inc bits

    inc(buf, pitch)
    if sl.numSpans() != 0:
      sl.finalize(y - i - 1)
      storage.render(sl)

proc decompose_ft_bitmap_gray8[Rasterizer, Scanline, ScanlineStorage](bitmap: var FT_Bitmap,
  x, y: int, flipY: bool, ras: var Rasterizer, sl: var Scanline, storage: var ScanlineStorage) =

  var
    buf = cast[ptr uint8](bitmap.buffer)
    pitch = int(bitmap.pitch)
    y = y

  sl.reset(x, x + int(bitmap.width))
  storage.prepare()

  if flipY:
    inc(buf, int(bitmap.pitch) * int(bitmap.rows - 1))
    inc(y, int(bitmap.rows))
    pitch = -pitch

  for i in 0..<int(bitmap.rows):
    sl.resetSpans()
    var p = buf
    for j in 0..<int(bitmap.width):
      let k = int(p[])
      if k != 0: sl.addCell(x + j, uint(ras.applyGamma(k)))
      inc p

    inc(buf, pitch)
    if sl.numSpans() != 0:
      sl.finalize(y - i - 1)
      storage.render(sl)

template gray8AdaptorT*(x: typedesc[FontEngineFreetypeBase]): typedesc =
  SerializedScanlinesAdaptorAA[uint8]

template monoAdaptorT*(x: typedesc[FontEngineFreetypeBase]): typedesc =
  SerializedScanlinesAdaptorBin

template scanlinesAAT*(x: typedesc[FontEngineFreetypeBase]): typedesc =
  ScanlineStorageAA8

template geScanlinesBinT*(x: typedesc[FontEngineFreetypeBase]): typedesc =
  ScanlineStorageBin

proc deinit(self: FontEngineFreetypeBase) =
  for i in 0..<self.mNumFaces:
    discard FT_Done_Face(self.mFaces[i])

  if self.mLibraryInitialized:
    discard FT_Done_FreeType(self.mLibrary)

proc init(self: FontEngineFreetypeBase, flag32: bool, maxFaces = 32) =
  self.mFlag32 = flag32
  self.mChangeStamp = 0
  self.mLastError = 0
  self.mName = nil
  self.mFaceIndex = 0
  self.mCharMap = FT_ENCODING_NONE
  self.mSignature = nil
  self.mHeight = 0
  self.mWidth = 0
  self.mHinting = true
  self.mFlipY = false
  self.mLibraryInitialized = false
  self.mLibrary = nil
  self.mFaces = newSeq[FT_Face](maxFaces)
  self.mFaceNames = newSeq[string](maxFaces)
  self.mNumFaces = 0
  self.mMaxFaces = maxFaces
  self.mCurFace = nil
  self.mResolution = 0
  self.mGlyphRendering = glyph_ren_native_gray8
  self.mGlyphIndex = 0
  self.mDataSize = 0
  self.mDataType = glyph_data_invalid
  self.mBounds = initRectI(1,1,0,0)
  self.mAdvanceX = 0.0
  self.mAdvanceY = 0.0

  self.mPath16   = initPathStorageInteger[int16]()
  self.mPath32   = initPathStorageInteger[int32]()
  self.mCurves16 = initConvCurve(self.mPath16)
  self.mCurves32 = initConvCurve(self.mPath32)

  self.mScanlineAA   = initScanlineU8()
  self.mScanlineBin  = initScanlineBin()
  self.mScanlinesAA  = initScanlineStorageAA8()
  self.mScanlinesBin = initScanlineStorageBin()
  self.mRasterizer   = initRasterizerScanlineAA()

  self.mCurves16.approximationScale(4.0)
  self.mCurves32.approximationScale(4.0)

  self.mLastError = FT_Init_FreeType(self.mLibrary)
  if self.mLastError == 0: self.mLibraryInitialized = true
  self.msg = newErrorMsg()
  self.mAffine = initTransAffine()

proc toFxHex(x: float64): string =
  let y = dbl_to_plain_fx(x)
  result = y.toHex(8)

proc updateSignature(self: FontEngineFreetypeBase) =
  if not self.mCurFace.isNil and self.mName != nil:
    var gammaHash = 0
    if self.mGlyphRendering in {glyph_ren_native_gray8, glyph_ren_mono, glyph_ren_gray8}:
      var gammaTable = newSeq[uint8](getAAScale(self.mRasterizer.type))
      for i in 0..<gammaTable.len:
        gammaTable[i] = self.mRasterizer.applyGamma(i).uint8
      gammaHash = int(crc32(0, gammaTable))

    self.mSignature = "$1,$2,$3,$4,$5:$6x$7,$8,$9,$10" % [
      self.mName, $int(self.mCharMap), $self.mFaceIndex,
      $int(self.mGlyphRendering), $self.mResolution,
      $self.mHeight, $self.mWidth, $int(self.mHinting),
      $int(self.mFlipY), gammaHash.toHex(8)]

    if self.mGlyphRendering in {glyph_ren_outline, glyph_ren_mono, glyph_ren_gray8}:
      var mtx: array[6, float64]
      self.mAffine.storeTo(mtx)
      var buf = ",$1$2$3$4$5$6" % [
        toFxHex(mtx[0]), toFxHex(mtx[1]), toFxHex(mtx[2]),
        toFxHex(mtx[3]), toFxHex(mtx[4]), toFxHex(mtx[5])]
      self.mSignature.add buf
    inc self.mChangeStamp

proc updateCharSize(self: FontEngineFreetypeBase) =
  if not self.mCurFace.isNil:
    if self.mResolution != 0:
      discard FT_Set_Char_Size(self.mCurFace,
                       self.mWidth,       # char_width in 1/64th of points
                       self.mHeight,      # char_height in 1/64th of points
                       self.mResolution,  # horizontal device resolution
                       self.mResolution)  # vertical device resolution
    else:
      discard FT_Set_Pixel_Sizes(self.mCurFace,
                         FT_UInt(self.mWidth shr 6),   # pixel_width
                         FT_UInt(self.mHeight shr 6))  # pixel_height
    self.updateSignature()

# Set font parameters
proc resolution*(self: FontEngineFreetypeBase, dpi: int) =
  self.mResolution = FT_UInt(dpi)
  self.updateCharSize()

proc findFace*(self: FontEngineFreetypeBase, faceName: string): int =
  for i in 0..<self.mNumFaces:
    if faceName == self.mFaceNames[i]:
      return i
  result = -1

proc loadFont*(self: FontEngineFreetypeBase, fontName: string, faceIndex: int,
  renType: GlyphRendering, fontMem: cstring = nil,  fontMemSize = 0): bool =
  result = false

  if self.mLibraryInitialized:
    self.mLastError = 0

    let idx = self.findFace(fontName)
    if idx >= 0:
      self.mCurFace = self.mFaces[idx]
      self.mName    = self.mFaceNames[idx]
    else:
      if self.mNumFaces >= self.mMaxFaces:
        discard FT_Done_Face(self.mFaces[0])
        for i in 0..<self.mNumFaces-1:
          shallowCopy(self.mFaceNames[i], self.mFaceNames[i+1])
          shallowCopy(self.mFaces[i], self.mFaces[i+1])
        self.mNumFaces = self.mMaxFaces - 1

      if fontMem != nil and fontMemSize != 0:
        self.mLastError = FT_New_Memory_Face(self.mLibrary,
          cast[ptr FT_Byte](fontMem), FT_Long(fontMemSize),
          FT_Long(faceIndex), self.mFaces[self.mNumFaces])
      else:
        self.mLastError = FT_New_Face(self.mLibrary,
          fontName, FT_Long(faceIndex), self.mFaces[self.mNumFaces])

      if self.mLastError == 0:
        self.mFaceNames[self.mNumFaces] = fontName
        self.mCurFace = self.mFaces[self.mNumFaces]
        self.mName    = self.mFaceNames[self.mNumFaces]
        inc self.mNumFaces
      else:
        self.mFaceNames[self.mNumFaces] = nil
        self.mCurFace = nil
        self.mName = nil

    if self.mLastError == 0:
      result = true

      case renType
      of glyph_ren_native_mono: self.mGlyphRendering = glyph_ren_native_mono
      of glyph_ren_native_gray8: self.mGlyphRendering = glyph_ren_native_gray8
      of glyph_ren_outline:
        if FT_IS_SCALABLE(self.mCurFace): self.mGlyphRendering = glyph_ren_outline
        else: self.mGlyphRendering = glyph_ren_native_gray8
      of glyph_ren_mono:
        if FT_IS_SCALABLE(self.mCurFace): self.mGlyphRendering = glyph_ren_mono
        else: self.mGlyphRendering = glyph_ren_native_mono
      of glyph_ren_gray8:
        if FT_IS_SCALABLE(self.mCurFace): self.mGlyphRendering = glyph_ren_gray8
        else: self.mGlyphRendering = glyph_ren_native_gray8

      self.updateSignature()

proc attach*(self: FontEngineFreetypeBase, fileName: string): bool =
  if not self.mCurFace.isNil:
    self.mLastError = FT_Attach_File(self.mCurFace, fileName)
    return self.mLastError == 0
  result = false

proc charMap*(self: FontEngineFreetypeBase, map: FT_Encoding): bool =
  if not self.mCurFace.isNil:
    self.mLastError = FT_Select_Charmap(self.mCurFace, self.mCharMap)
    if self.mLastError == 0:
      self.updateSignature()
      return true
  result = false

proc height*(self: FontEngineFreetypeBase, h: float64): bool {.discardable.} =
  self.mHeight = FT_F26Dot6(h * 64.0)
  if not self.mCurFace.isNil:
    self.updateCharSize()
    return true
  result = false

proc width*(self: FontEngineFreetypeBase, w: float64): bool {.discardable.} =
  self.mWidth = FT_F26Dot6(w * 64.0)
  if not self.mCurFace.isNil:
    self.updateCharSize()
    return true
  result = false

proc hinting*(self: FontEngineFreetypeBase, h: bool) =
  self.mHinting = h
  if not self.mCurFace.isNil:
    self.updateSignature()

proc flipY*(self: FontEngineFreetypeBase, f: bool) =
  self.mFlipY = f
  if not self.mCurFace.isNil:
    self.updateSignature()

proc transform*(self: FontEngineFreetypeBase, affine: TransAffine) =
  self.mAffine = affine
  if not self.mCurFace.isNil:
    self.updateSignature()

# Set Gamma
proc gamma*[GammaF](self: FontEngineFreetypeBase, f: GammaF) =
  self.mRasterizer.gamma(f)

# Accessors
proc lastError*(self: FontEngineFreetypeBase): FT_error =
  self.mLastError

proc resolution*(self: FontEngineFreetypeBase): FT_Uint =
  self.mResolution

proc name*(self: FontEngineFreetypeBase): string =
  self.mName

proc numFaces*(self: FontEngineFreetypeBase): int =
  if not self.mCurFace.isNil:
    return self.mCurFace.numFaces
  result = 0

proc charMap*(self: FontEngineFreetypeBase): FT_Encoding =
  self.mCharMap

proc height*(self: FontEngineFreetypeBase): float64 =
  result = float64(self.mHeight) / 64.0

proc width*(self: FontEngineFreetypeBase): float64 =
  result = float64(self.mWidth) / 64.0

proc ascender*(self: FontEngineFreetypeBase): float64 =
  if not self.mCurFace.isNil:
    return float64(self.mCurFace.ascender) * self.height() / float64(self.mCurFace.height)
  result = 0.0

proc descender*(self: FontEngineFreetypeBase): float64 =
  if not self.mCurFace.isNil:
    return float64(self.mCurFace.descender) * self.height() / float64(self.mCurFace.height)
  result = 0.0

proc hinting*(self: FontEngineFreetypeBase): bool =
  self.mHinting

proc flipY*(self: FontEngineFreetypeBase): bool =
  self.mFlipY

# Interface mandatory to implement for font_cache_manager
proc fontSignature*(self: FontEngineFreetypeBase): string =
  self.mSignature

proc changeStamp*(self: FontEngineFreetypeBase): int =
  self.mChangeStamp

proc prepareNativeMono(self: FontEngineFreetypeBase): bool =
  self.mLastError = FT_Render_Glyph(self.mCurFace.glyph, FT_RENDER_MODE_MONO)
  if self.mLastError != 0: return false

  var top = self.mCurFace.glyph.bitmap_top
  if self.mFlipY: top = -top

  decompose_ft_bitmap_mono(self.mCurFace.glyph.bitmap,
    self.mCurFace.glyph.bitmap_left, top, self.mFlipY,
    self.mScanlineBin, self.mScanlinesBin)

  self.mBounds.x1 = self.mScanlinesBin.minX()
  self.mBounds.y1 = self.mScanlinesBin.minY()
  self.mBounds.x2 = self.mScanlinesBin.maxX() + 1
  self.mBounds.y2 = self.mScanlinesBin.maxY() + 1

  self.mDataSize = self.mScanlinesBin.byteSize()
  self.mDataType = glyph_data_mono
  self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
  self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
  return true

proc prepareNativeGray8(self: FontEngineFreetypeBase): bool =
  self.mLastError = FT_Render_Glyph(self.mCurFace.glyph, FT_RENDER_MODE_NORMAL)
  if self.mLastError != 0: return false

  var top = self.mCurFace.glyph.bitmap_top
  if self.mFlipY: top = -top
  decompose_ft_bitmap_gray8(self.mCurFace.glyph.bitmap,
    self.mCurFace.glyph.bitmap_left, top, self.mFlipY,
    self.mRasterizer, self.mScanlineAA, self.mScanlinesAA)

  self.mBounds.x1 = self.mScanlinesAA.minX()
  self.mBounds.y1 = self.mScanlinesAA.minY()
  self.mBounds.x2 = self.mScanlinesAA.maxX() + 1
  self.mBounds.y2 = self.mScanlinesAA.maxY() + 1
  self.mDataSize = self.mScanlinesAA.byteSize()
  self.mDataType = glyph_data_gray8
  self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
  self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
  return true

proc prepareOutline(self: FontEngineFreetypeBase): bool =
  if self.mLastError != 0: return false

  if self.mFlag32:
    self.mPath32.removeAll()
    if decompose_ft_outline(self.mCurFace.glyph.outline,
       self.mFlipY, self.mAffine, self.mPath32):
      var bnd  = self.mPath32.boundingRect()
      self.mDataSize = self.mPath32.byteSize()
      self.mDataType = glyph_data_outline
      self.mBounds.x1 = int(floor(bnd.x1))
      self.mBounds.y1 = int(floor(bnd.y1))
      self.mBounds.x2 = int(ceil(bnd.x2))
      self.mBounds.y2 = int(ceil(bnd.y2))
      self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
      self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
      self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
      return true
  else:
    self.mPath16.removeAll()
    if decompose_ft_outline(self.mCurFace.glyph.outline,
      self.mFlipY, self.mAffine, self.mPath16):
     var bnd  = self.mPath16.boundingRect()
     self.mDataSize = self.mPath16.byteSize()
     self.mDataType = glyph_data_outline
     self.mBounds.x1 = int(floor(bnd.x1))
     self.mBounds.y1 = int(floor(bnd.y1))
     self.mBounds.x2 = int(ceil(bnd.x2))
     self.mBounds.y2 = int(ceil(bnd.y2))
     self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
     self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
     self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
     return true

proc prepareMono(self: FontEngineFreetypeBase): bool =
  if self.mLastError != 0: return false

  self.mRasterizer.reset()
  if self.mFlag32:
    self.mPath32.removeAll()
    discard decompose_ft_outline(self.mCurFace.glyph.outline,
      self.mFlipY, self.mAffine, self.mPath32)
    self.mRasterizer.addPath(self.mCurves32)
  else:
    self.mPath16.removeAll()
    discard decompose_ft_outline(self.mCurFace.glyph.outline,
      self.mFlipY, self.mAffine, self.mPath16)
    self.mRasterizer.addPath(self.mCurves16)

  self.mScanlinesBin.prepare() # Remove all
  renderScanlines(self.mRasterizer, self.mScanlineBin, self.mScanlinesBin)
  self.mBounds.x1 = self.mScanlinesBin.minX()
  self.mBounds.y1 = self.mScanlinesBin.minY()
  self.mBounds.x2 = self.mScanlinesBin.maxX() + 1
  self.mBounds.y2 = self.mScanlinesBin.maxY() + 1
  self.mDataSize = self.mScanlinesBin.byteSize()
  self.mDataType = glyph_data_mono
  self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
  self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
  self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
  return true

proc prepareGray8(self: FontEngineFreetypeBase): bool =
  if self.mLastError != 0: return false

  self.mRasterizer.reset()
  if self.mFlag32:
    self.mPath32.removeAll()
    discard decompose_ft_outline(self.mCurFace.glyph.outline,
      self.mFlipY, self.mAffine, self.mPath32)
    self.mRasterizer.addPath(self.mCurves32)
  else:
    self.mPath16.removeAll()
    discard decompose_ft_outline(self.mCurFace.glyph.outline,
      self.mFlipY, self.mAffine, self.mPath16)
    self.mRasterizer.addPath(self.mCurves16)

  self.mScanlinesAA.prepare() # Remove all
  renderScanlines(self.mRasterizer, self.mScanlineAA, self.mScanlinesAA)
  self.mBounds.x1 = self.mScanlinesAA.minX()
  self.mBounds.y1 = self.mScanlinesAA.minY()
  self.mBounds.x2 = self.mScanlinesAA.maxX() + 1
  self.mBounds.y2 = self.mScanlinesAA.maxY() + 1
  self.mDataSize = self.mScanlinesAA.byteSize()
  self.mDataType = glyph_data_gray8
  self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
  self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
  self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
  return true

proc prepareGlyph*(self: FontEngineFreetypeBase, glyphCode: int): bool =
  self.mGlyphIndex = FT_Get_Char_Index(self.mCurFace, FT_Ulong(glyphCode))
  self.mLastError  = FT_Load_Glyph(self.mCurFace, self.mGlyphIndex,
                     if self.mHinting: FT_LOAD_DEFAULT else: FT_LOAD_NO_HINTING)
  if self.mLastError != 0: return false

  case self.mGlyphRendering
  of glyph_ren_native_mono: result = self.prepareNativeMono()
  of glyph_ren_native_gray8: result = self.prepareNativeGray8()
  of glyph_ren_outline: result = self.prepareOutline()
  of glyph_ren_mono: result = self.prepareMono()
  of glyph_ren_gray8: result = self.prepareGray8()
  else: return false

proc glyphIndex*(self: FontEngineFreetypeBase): int =
  int(self.mGlyphIndex)

proc dataSize*(self: FontEngineFreetypeBase): int =
  self.mDataSize

proc dataType*(self: FontEngineFreetypeBase): GlyphDataType =
  self.mDataType

proc bounds*(self: FontEngineFreetypeBase): RectI =
  self.mBounds

proc advanceX*(self: FontEngineFreetypeBase): float64 =
  self.mAdvanceX

proc advanceY*(self: FontEngineFreetypeBase): float64 =
  self.mAdvanceY

proc writeGlyphTo*(self: FontEngineFreetypeBase, data: ptr uint8) =
  if data != nil and self.mDataSize != 0:
    case self.mDataType
    of glyph_data_mono: self.mScanlinesBin.serialize(data)
    of glyph_data_gray8: self.mScanlinesAA.serialize(data)
    of glyph_data_outline:
      if self.mFlag32: self.mPath32.serialize(data)
      else: self.mPath16.serialize(data)
    else: discard

proc addKerning*(self: FontEngineFreetypeBase, first, second: int, x, y: var float64): bool =
  const renType = {glyph_ren_outline, glyph_ren_mono, glyph_ren_gray8}
  let cond = not self.mCurFace.isNil and first != 0 and second != 0

  if cond and FT_HAS_KERNING(self.mCurFace):
    var delta: FT_Vector
    discard FT_Get_Kerning(self.mCurFace, FT_UInt(first), FT_UInt(second), FT_UInt(FT_KERNING_DEFAULT), delta)
    var
      dx = int26p6_to_dbl(delta.x)
      dy = int26p6_to_dbl(delta.y)
    if self.mGlyphRendering in renType:
      self.mAffine.transform2x2(dx, dy)
    x += dx
    y += dy
    return true
  result = false

# This class uses values of type int16 (10.6 format) for the vector cache.
# The vector cache is compact, but when rendering glyphs of height
# more that 200 there integer overflow can occur.

type
  FontEngineFreetype16* = ref object of FontEngineFreetypeBase

template pathAdaptorT*(x: typedesc[FontEngineFreetype16]): typedesc =
  SerializedIntegerPathAdaptor[int16]

template gray8AdaptorT*(x: typedesc[FontEngineFreetype16]): typedesc =
  gray8AdaptorT(FontEngineFreetypeBase)

template monoAdaptorT*(x: typedesc[FontEngineFreetype16]): typedesc =
  monoAdaptorT(FontEngineFreetypeBase)

template scanlinesAAT*(x: typedesc[FontEngineFreetype16]): typedesc =
  scanlinesAAT(FontEngineFreetypeBase)

template scanlinesBinT*(x: typedesc[FontEngineFreetype16]): typedesc =
  scanlinesBinT(FontEngineFreetypeBase)

template gray8ScanlineT*(x: typedesc[FontEngineFreetype16]): typedesc =
  embeddedScanlineT(gray8AdaptorT(FontEngineFreetypeBase))

template monoScanlineT*(x: typedesc[FontEngineFreetype16]): typedesc =
  embeddedScanlineT(monoAdaptorT(FontEngineFreetypeBase))

proc finalizer(self: FontEngineFreetype16) =
  deinit(self)

proc newFontEngineFreetype16*(maxFaces = 32): FontEngineFreetype16 =
  new(result, finalizer)
  result.init(false, maxFaces)

# This class uses values of type int32 (26.6 format) for the vector cache.
# The vector cache is twice larger than in font_engine_win32_tt_int16,
# but it allows you to render glyphs of very large sizes.

type
  FontEngineFreetype32* = ref object of FontEngineFreetypeBase

template pathAdaptorT*(x: typedesc[FontEngineFreetype32]): typedesc =
  SerializedIntegerPathAdaptor[int32]

template gray8AdaptorT*(x: typedesc[FontEngineFreetype32]): typedesc =
  gray8AdaptorT(FontEngineFreetypeBase)

template monoAdaptorT*(x: typedesc[FontEngineFreetype32]): typedesc =
  monoAdaptorT(FontEngineFreetypeBase)

template scanlinesAAT*(x: typedesc[FontEngineFreetype32]): typedesc =
  scanlinesAAT(FontEngineFreetypeBase)

template scanlinesBinT*(x: typedesc[FontEngineFreetype32]): typedesc =
  scanlinesBinT(FontEngineFreetypeBase)

template gray8ScanlineT*(x: typedesc[FontEngineFreetype32]): typedesc =
  embeddedScanlineT(gray8AdaptorT(FontEngineFreetypeBase))

template monoScanlineT*(x: typedesc[FontEngineFreetype32]): typedesc =
  embeddedScanlineT(monoAdaptorT(FontEngineFreetypeBase))

proc finalizer(self: FontEngineFreetype32) =
  deinit(self)

proc newFontEngineFreetype32*(maxFaces = 32): FontEngineFreetype32 =
  new(result, finalizer)
  result.init(true, maxFaces)
