import basics, font_types, platform/winapi, scanline_storage_aa
import scanline_storage_bin, scanline_u, scanline_bin
import path_storage_integer, rasterizer_scanline_aa, conv_curve
import trans_affine, bitset_iterator, strutils, algorithm
import math, renderer_scanline

const
  bufSize = 32768-32

type
  FontEngineWin32TTBase* = ref object of RootObj
    mFlag32: bool
    mDC: HDC
    mOldFont: HFONT
    mFonts: seq[HFONT]
    mMaxFonts: int
    mNumFonts: int
    mFontNames: seq[string]
    mCurFont: HFONT

    mChangeStamp: int
    mTypeFace: string
    mSignature: string
    mHeight: int
    mWidth: int
    mWeight: int
    mItalic: bool
    mCharSet: DWORD
    mPitchAndFamily: DWORD
    mHinting: bool
    mFlipY: bool

    mFontCreated: bool
    mResolution: int
    mGlyphRendering: GlyphRendering
    mGlyphIndex: int
    mDataSize: int
    mDataType: GlyphDataType
    mBounds: RectI
    mAdvanceX: float64
    mAdvanceY: float64
    mMatrix: MAT2

    mGBuf: string
    mKerningPairs: seq[KERNINGPAIR]
    mNumKerningPairs: int
    mMaxKerningPairs: int
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

template gray8AdaptorT*(x: typedesc[FontEngineWin32TTBase]): typedesc =
  SerializedScanlinesAdaptorAA[uint8]

template monoAdaptorT*(x: typedesc[FontEngineWin32TTBase]): typedesc =
  SerializedScanlinesAdaptorBin

template scanlinesAAT*(x: typedesc[FontEngineWin32TTBase]): typedesc =
  ScanlineStorageAA8

template geScanlinesBinT*(x: typedesc[FontEngineWin32TTBase]): typedesc =
  ScanlineStorageBin

proc crc32[T](crc: uint32, buf: T): uint32 =
  const kcrc32 = [ 0'u32, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190,
    0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320'u32, 0xf00f9344'u32, 0xd6d6a3e8'u32,
    0xcb61b38c'u32, 0x9b64c2b0'u32, 0x86d3d2d4'u32, 0xa00ae278'u32, 0xbdbdf21c'u32]

  var crcu32 = not crc
  for b in buf:
    #crcu32 = (crcu32 shr 4) xor kcrc32[int(crcu32 and 0xF'u32) xor (int(b) and 0xF)]
    #crcu32 = (crcu32 shr 4) xor kcrc32[int(crcu32 and 0xF'u32) xor (int(b) shr 4)]
    crcu32 = (crcu32 shr 4) xor kcrc32[int((crcu32 and 0xF) xor (uint32(b) and 0xF'u32))]
    crcu32 = (crcu32 shr 4) xor kcrc32[int((crcu32 and 0xF) xor (uint32(b) shr 4'u32))]

  result = not crcu32

#proc dbl_to_fx(d: float64): FIXED {.inline.} =
#  var k = int32(d * 65536.0)
#  result = cast[ptr FIXED](k.addr)[]

proc dbl_to_plain_fx(d: float64): int {.inline.} =
  result = int(d * 65536.0)

#proc negate_fx(fx: FIXED): FIXED {.inline.} =
#  var k = -(cast[ptr int32](fx.unsafeAddr)[])
#  result = cast[ptr FIXED](k.addr)[]

proc fx_to_dbl(p: FIXED): float64 {.inline.} =
  result = float64(p.value) + float64(p.fract.uint16) * (1.0 / 65536.0)

#proc fx_to_plain_int(fx: FIXED): int {.inline.} =
#  result = int(cast[ptr int32](fx.unsafeAddr)[])

#proc fx_to_int26p6(p: FIXED): int {.inline.} =
#  result = (int(p.value) shl 6) + (int(p.fract) shr 10)

proc dbl_to_int26p6(p: float64): int {.inline.} =
  result = int(p * 64.0 + 0.5)

proc decompose_win32_glyph_bitmap_mono[Scanline, ScanlineStorage](gbuf: string,
  w, h, x, y: int, flipY: bool, sl: var Scanline, storage: var ScanlineStorage) =

  var
    pitch = ((w + 31) shr 5) shl 2
    buf   = cast[ptr uint8](gbuf[0].unsafeAddr)
    y = y

  sl.reset(x, x + w)
  storage.prepare()

  if flipY:
    buf += pitch * (h - 1)
    y += h
    pitch = -pitch

  for i in 0..<h:
   sl.resetSpans()
   var bits = initBitsetIterator(buf, 0)
   for j in 0..<w:
     if bits.bit() != 0:
      sl.addCell(x + j, coverFull)
     inc bits
   buf += pitch

   if sl.numSpans() != 0:
     sl.finalize(y - i - 1)
     storage.render(sl)

proc decompose_win32_glyph_bitmap_gray8[Rasterizer, Scanline, ScanlineStorage](gbuf: string,
  w, h, x, y: int, flipY: bool, ras: var Rasterizer, sl: var Scanline, storage: var ScanlineStorage) =
  var
    pitch = ((w + 3) shr 2) shl 2
    buf   = cast[ptr uint8](gbuf[0].unsafeAddr)
    y = y

  sl.reset(x, x + w)
  storage.prepare()
  if flipY:
    buf += pitch * (h - 1)
    y += h
    pitch = -pitch

  for i in 0..<h:
    sl.resetSpans()
    var p = buf
    for j in 0..<w:
      var v = p[]
      if v != 0:
        if v == 64: v = 255
        else: v = v shl 2
        sl.addCell(x + j, ras.applyGamma(v.int).uint)
      inc p
    buf += pitch
    if sl.numSpans() != 0:
      sl.finalize(y - i - 1)
      storage.render(sl)

proc decompose_win32_glyph_outline[PathStorage](gbuf: string, totalSize: int,
  flipY: bool, mtx: TransAffine, path: var PathStorage): bool =

  var
    curGlyph = gbuf[0].unsafeAddr
    endGlyph = curGlyph + totalSize
    x, y: float64

  type ValueT = getValueT(PathStorage)

  while curGlyph < endGlyph:
    var
      th = cast[ptr TTPOLYGONHEADER](curGlyph)
      endPoly = curGlyph + th.cb
      curPoly = curGlyph + sizeof(TTPOLYGONHEADER)

    x = fx_to_dbl(th.pfxStart.x)
    y = fx_to_dbl(th.pfxStart.y)

    if flipY: y = -y
    mtx.transform(x, y)
    path.moveTo(ValueT(dbl_to_int26p6(x)), ValueT(dbl_to_int26p6(y)))

    while curPoly < endPoly:
      var pc = cast[ptr TTPOLYCURVE](curPoly)

      if pc.wType == TT_PRIM_LINE:
        for i in 0..<pc.cpfx:
          x = fx_to_dbl(pc.apfx[i].x)
          y = fx_to_dbl(pc.apfx[i].y)
          if flipY: y = -y
          mtx.transform(x, y)
          path.lineTo(ValueT(dbl_to_int26p6(x)), ValueT(dbl_to_int26p6(y)))

      if pc.wType == TT_PRIM_QSPLINE:
        for u in 0..<pc.cpfx - 1:    # Walk through points in spline
          var
            pnt_b = pc.apfx[u]        # B is always the current point
            pnt_c = pc.apfx[u+1]

          if u < pc.cpfx - 2:         # If not on last spline, compute C
            # midpoint (x,y)
            cast[ptr int32](pnt_c.x.addr)[] = (cast[ptr int32](pnt_b.x.addr)[] + cast[ptr int32](pnt_c.x.addr)[]) div 2
            cast[ptr int32](pnt_c.y.addr)[] = (cast[ptr int32](pnt_b.y.addr)[] + cast[ptr int32](pnt_c.y.addr)[]) div 2

          var x2, y2: float64
          x  = fx_to_dbl(pnt_b.x)
          y  = fx_to_dbl(pnt_b.y)
          x2 = fx_to_dbl(pnt_c.x)
          y2 = fx_to_dbl(pnt_c.y)
          if flipY:
            y = -y
            y2 = -y2

          mtx.transform(x,  y)
          mtx.transform(x2, y2)

          path.curve3(ValueT(dbl_to_int26p6(x)),
                      ValueT(dbl_to_int26p6(y)),
                      ValueT(dbl_to_int26p6(x2)),
                      ValueT(dbl_to_int26p6(y2)))

      curPoly += sizeof(WORD) * 2 + sizeof(POINTFX) * pc.cpfx
    curGlyph += th.cb
  result = true

# Set font parameters
proc resolution*(self: FontEngineWin32TTBase, dpi: int) =
  self.mResolution = dpi

proc height*(self: FontEngineWin32TTBase, h: float64) =
  self.mHeight = int(h)

proc width*(self: FontEngineWin32TTBase, w: float64) =
  self.mWidth = int(w)

proc weight*(self: FontEngineWin32TTBase, w: int) =
  self.mWeight = w

proc italic*(self: FontEngineWin32TTBase, it: bool) =
  self.mItalic = it

proc charSet*(self: FontEngineWin32TTBase, c: DWORD) =
  self.mCharSet = c

proc pitchAndFamily*(self: FontEngineWin32TTBase, p: DWORD) =
  self.mPitchAndFamily = p

proc flipY*(self: FontEngineWin32TTBase, flip: bool) =
  self.mFlipY = flip

proc hinting*(self: FontEngineWin32TTBase, h: bool) =
  self.mHinting = h

proc toFxHex(x: float64): string =
  let y = dbl_to_plain_fx(x)
  result = y.toHex(8)

proc updateSignature*(self: FontEngineWin32TTBase) =
  self.mSignature = ""
  if self.mDC != NULL and self.mCurFont != NULL:
    var gammaHash = 0
    if self.mGlyphRendering in {glyph_ren_native_gray8, glyph_ren_mono, glyph_ren_gray8}:
      var gammaTable = newSeq[uint8](getAAScale(self.mRasterizer.type))
      for i in 0..<gammaTable.len:
        gammaTable[i] = self.mRasterizer.applyGamma(i).uint8
      gammaHash = int(crc32(0, gammaTable))

    self.mSignature = "$1,$2,$3,$4:$5x$6,$7,$8,$9,$10,$11,$12" % [
      self.mTypeFace, $self.mCharSet, $self.mGlyphRendering.ord,
      $self.mResolution, $self.mHeight, $self.mWidth, $self.mWeight,
      $int(self.mItalic), $int(self.mHinting), $int(self.mFlipY),
      $int(self.mPitchAndFamily), gammaHash.toHex(8)]

    if self.mGlyphRendering in {glyph_ren_outline, glyph_ren_mono, glyph_ren_gray8}:
      var mtx: array[6, float64]
      self.mAffine.storeTo(mtx)
      var buf = ",$1$2$3$4$5$6" % [
        toFxHex(mtx[0]), toFxHex(mtx[1]), toFxHex(mtx[2]),
        toFxHex(mtx[3]), toFxHex(mtx[4]), toFxHex(mtx[5])]
      self.mSignature.add buf
    inc self.mChangeStamp

proc findFont*(self: FontEngineWin32TTBase, name: string): int =
  for i in 0..<self.mFontNames.len:
    if name.len == 0 or self.mFontNames[i].len == 0: continue
    if name == self.mFontNames[i]: return i
  result = -1

proc createFont*(self: FontEngineWin32TTBase, typeFace: string, renType: GlyphRendering): bool =
  if self.mDC != NULL:
    self.mTypeFace = typeFace

    var
      h = self.mHeight
      w = self.mWidth

    if self.mResolution != 0:
      h = mulDiv(self.mHeight.int32, self.mResolution.int32, 72)
      w = mulDiv(self.mWidth.int32,  self.mResolution.int32, 72)

    self.mGlyphRendering = renType
    self.updateSignature()
    let idx = self.findFont(self.mSignature)
    if idx >= 0:
      self.mCurFont = self.mFonts[idx]
      selectObject(self.mDC, self.mCurFont)
      self.mNumKerningPairs = 0
      return true
    else:
      self.mCurFont = createFont(-int32(h),                  # height of font
                                int32(w),                    # average character width
                                int32(0),                    # angle of escapement
                                int32(0),                    # base-line orientation angle
                                int32(self.mWeight),         # font weight
                                DWORD(self.mItalic),         # italic attribute option
                                DWORD(0),                    # underline attribute option
                                DWORD(0),                    # strikeout attribute option
                                DWORD(self.mCharSet),        # character set identifier
                                DWORD(OUT_DEFAULT_PRECIS),   # output precision
                                DWORD(CLIP_DEFAULT_PRECIS),  # clipping precision
                                DWORD(ANTIALIASED_QUALITY),  # output quality
                                DWORD(self.mPitchAndFamily), # pitch and family
                                self.mTypeFace)              # typeface name
      if self.mCurFont != NULL:
        if self.mNumFonts >= self.mMaxFonts:
          if self.mOldFont != NULL: selectObject(self.mDC, self.mOldFont)
          deleteObject(self.mFonts[0])
          for i in 0..<self.mNumFonts-1:
            shallowCopy(self.mFontNames[i], self.mFontNames[i+1])
            shallowCopy(self.mFonts[i], self.mFonts[i+1])
          self.mNumFonts = self.mMaxFonts - 1

        self.updateSignature()
        self.mFontNames[self.mNumFonts] = self.mSignature
        self.mFonts[self.mNumFonts] = self.mCurFont
        inc self.mNumFonts
        selectObject(self.mDC, self.mCurFont)
        self.mNumKerningPairs = 0
        return true
  return false

proc createFont*(self: FontEngineWin32TTBase, typeFace: string, renType: GlyphRendering,
  height: float64, width = 0.0, weight = FW_REGULAR, italic = false,
  charSet = DWORD(ANSI_CHARSET), pitchAndFamily = DWORD(FF_DONTCARE)): bool =

  self.mHeight  = height.int
  self.mWidth   = width.int
  self.mWeight  = weight
  self.mItalic  = italic
  self.mCharSet = charSet
  self.mPitchAndFamily = pitchAndFamily
  self.createFont(typeFace, renType)

# Set Gamma
proc gamma*[GammaF](self: FontEngineWin32TTBase, gammaF: var GammaF) =
  self.mRasterizer.gamma(gammaF)

proc transform*(self: FontEngineWin32TTBase, mtx: TransAffine) =
  self.mAffine = mtx

# Accessors
proc resolution*(self: FontEngineWin32TTBase): int =
  self.mResolution

proc typeface*(self: FontEngineWin32TTBase): string =
  self.mTypeFace

proc height*(self: FontEngineWin32TTBase): int =
  self.mHeight

proc width*(self: FontEngineWin32TTBase): int =
  self.mWidth

proc weight*(self: FontEngineWin32TTBase): int =
  self.mWeight

proc italic*(self: FontEngineWin32TTBase): bool =
  self.mItalic

proc charSet*(self: FontEngineWin32TTBase): DWORD =
  self.mCharSet

proc pitchAndFamily*(self: FontEngineWin32TTBase): DWORD =
  self.mPitchAndFamily

proc hinting*(self: FontEngineWin32TTBase): bool =
  self.mHinting

proc flipY*(self: FontEngineWin32TTBase): bool =
  self.mFlipY

# Interface mandatory to implement for font_cache_manager
proc fontSignature*(self: FontEngineWin32TTBase): string =
  self.mSignature

proc changeStamp*(self: FontEngineWin32TTBase): int =
  self.mChangeStamp

proc prepareGlyph*(self: FontEngineWin32TTBase, glyphCode: int): bool =
  # For compatibility with old SDKs.
  const GGO_UNHINTED = 0x0100

  if self.mDC != NULL and self.mCurFont != NULL:
    var format = GGO_BITMAP

    if self.mGlyphRendering == glyph_ren_native_gray8:
      format = GGO_GRAY8_BITMAP
    elif self.mGlyphRendering in {glyph_ren_outline, glyph_ren_mono, glyph_ren_gray8}:
      format = GGO_NATIVE

    if not self.mHinting: format = format or GGO_UNHINTED

    var
      gm: GLYPHMETRICS
      totalSize = getGlyphOutline(self.mDC, WINUINT(glyphCode),
        WINUINT(format), gm.addr, DWORD(bufSize), self.mGBuf[0].addr, self.mMatrix.addr)

    if totalSize < 0:
      # GetGlyphOutline() fails when being called for
      # GGO_GRAY8_BITMAP and white space (stupid Microsoft).
      # It doesn't even initialize the glyph metrics
      # structure. So, we have to query the metrics
      # separately (basically we need gmCellIncX).
      var totalSize = getGlyphOutline(self.mDC, WINUINT(glyphCode),
        WINUINT(GGO_METRICS), gm.addr, DWORD(bufSize), self.mGBuf[0].addr, self.mMatrix.addr)

      if totalSize < 0: return false
      gm.gmBlackBoxX = 0
      gm.gmBlackBoxY = 0
      totalSize = 0

    self.mGlyphIndex = glyphCode
    self.mAdvanceX   = float64(gm.gmCellIncX)
    self.mAdvanceY   = -float64(gm.gmCellIncY)

    case self.mGlyphRendering
    of glyph_ren_native_mono:
      decompose_win32_glyph_bitmap_mono(self.mGBuf, gm.gmBlackBoxX, gm.gmBlackBoxY,
        gm.gmptGlyphOrigin.x, if self.mFlipY: -gm.gmptGlyphOrigin.y else: gm.gmptGlyphOrigin.y,
        self.mFlipY, self.mScanlineBin, self.mScanlinesBin)

      self.mBounds.x1 = self.mScanlinesBin.minX()
      self.mBounds.y1 = self.mScanlinesBin.minY()
      self.mBounds.x2 = self.mScanlinesBin.maxX() + 1
      self.mBounds.y2 = self.mScanlinesBin.maxY() + 1
      self.mDataSize  = self.mScanlinesBin.byteSize()
      self.mDataType  = glyph_data_mono
      return true

    of glyph_ren_native_gray8:
      decompose_win32_glyph_bitmap_gray8(self.mGBuf, gm.gmBlackBoxX, gm.gmBlackBoxY,
        gm.gmptGlyphOrigin.x, if self.mFlipY: -gm.gmptGlyphOrigin.y else: gm.gmptGlyphOrigin.y,
        self.mFlipY, self.mRasterizer, self.mScanlineAA, self.mScanlinesAA)

      self.mBounds.x1 = self.mScanlinesAA.minX()
      self.mBounds.y1 = self.mScanlinesAA.minY()
      self.mBounds.x2 = self.mScanlinesAA.maxX() + 1
      self.mBounds.y2 = self.mScanlinesAA.maxY() + 1
      self.mDataSize  = self.mScanlinesAA.byteSize()
      self.mDataType  = glyph_data_gray8
      return true

    of glyph_ren_outline:
      self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
      if self.mFlag32:
        self.mPath32.removeAll()
        if decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath32):
          var bnd  = self.mPath32.boundingRect()
          self.mDataSize = self.mPath32.byteSize()
          self.mDataType = glyph_data_outline
          self.mBounds.x1 = int(floor(bnd.x1))
          self.mBounds.y1 = int(floor(bnd.y1))
          self.mBounds.x2 = int(ceil(bnd.x2))
          self.mBounds.y2 = int(ceil(bnd.y2))
          return true
      else:
        self.mPath16.removeAll()
        if decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath16):
          var bnd  = self.mPath16.boundingRect()
          self.mDataSize = self.mPath16.byteSize()
          self.mDataType = glyph_data_outline
          self.mBounds.x1 = int(floor(bnd.x1))
          self.mBounds.y1 = int(floor(bnd.y1))
          self.mBounds.x2 = int(ceil(bnd.x2))
          self.mBounds.y2 = int(ceil(bnd.y2))
          return true
    of glyph_ren_mono:
      self.mRasterizer.reset()
      self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
      if self.mFlag32:
        self.mPath32.removeAll()
        discard decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath32)
        self.mRasterizer.addPath(self.mCurves32)
      else:
        self.mPath16.removeAll()
        discard decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath16)
        self.mRasterizer.addPath(self.mCurves16)

      self.mScanlinesBin.prepare() # Remove all
      renderScanlines(self.mRasterizer, self.mScanlineBin, self.mScanlinesBin)
      self.mBounds.x1 = self.mScanlinesBin.minX()
      self.mBounds.y1 = self.mScanlinesBin.minY()
      self.mBounds.x2 = self.mScanlinesBin.maxX() + 1
      self.mBounds.y2 = self.mScanlinesBin.maxY() + 1
      self.mDataSize = self.mScanlinesBin.byteSize()
      self.mDataType = glyph_data_mono
      return true
    of glyph_ren_gray8:
      self.mRasterizer.reset()
      self.mAffine.transform(self.mAdvanceX, self.mAdvanceY)
      if self.mFlag32:
        self.mPath32.removeAll()
        discard decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath32)
        self.mRasterizer.addPath(self.mCurves32)
      else:
        self.mPath16.removeAll()
        discard decompose_win32_glyph_outline(self.mGBuf, totalSize, self.mFlipY, self.mAffine, self.mPath16)
        self.mRasterizer.addPath(self.mCurves16)

      self.mScanlinesAA.prepare() # Remove all
      renderScanlines(self.mRasterizer, self.mScanlineAA, self.mScanlinesAA)
      self.mBounds.x1 = self.mScanlinesAA.minX()
      self.mBounds.y1 = self.mScanlinesAA.minY()
      self.mBounds.x2 = self.mScanlinesAA.maxX() + 1
      self.mBounds.y2 = self.mScanlinesAA.maxY() + 1
      self.mDataSize = self.mScanlinesAA.byteSize()
      self.mDataType = glyph_data_gray8
      return true
    else: discard
  return false

proc glyphIndex*(self: FontEngineWin32TTBase): int =
  self.mGlyphIndex

proc dataSize*(self: FontEngineWin32TTBase): int =
  self.mDataSize

proc dataType*(self: FontEngineWin32TTBase): GlyphDataType =
  self.mDataType

proc bounds*(self: FontEngineWin32TTBase): var RectI =
  self.mBounds

proc advanceX*(self: FontEngineWin32TTBase): float64 =
  self.mAdvanceX

proc advanceY*(self: FontEngineWin32TTBase): float64 =
  self.mAdvanceY

proc writeGlyphTo*(self: FontEngineWin32TTBase, data: ptr uint8) =
  if data != nil and self.mDataSize != 0:
    case self.mDataType
    of glyph_data_mono:  self.mScanlinesBin.serialize(data)
    of glyph_data_gray8: self.mScanlinesAA.serialize(data)
    of glyph_data_outline:
     if self.mFlag32:
       self.mPath32.serialize(data)
     else:
       self.mPath16.serialize(data)
    else: discard

proc cmp(a, b: KERNINGPAIR): int =
  if a.wFirst != b.wFirst:
    return cmp(a.wFirst, b.wFirst)
  return cmp(a.wSecond, b.wSecond)

proc sortKerningPairs*(self: FontEngineWin32TTBase) =
  self.mKerningPairs.sort(cmp)

proc loadKerningPairs*(self: FontEngineWin32TTBase) =
  if self.mDC != NULL and self.mCurFont != NULL:
    if self.mKerningPairs.len == 0:
      self.mMaxKerningPairs = 16384-16
      self.mMaxKerningPairs = getKerningPairs(self.mDC, DWORD(self.mMaxKerningPairs), nil)
      self.mKerningPairs = newSeq[KERNINGPAIR](self.mMaxKerningPairs)
    self.mNumKerningPairs = getKerningPairs(self.mDC,
      DWORD(self.mMaxKerningPairs), self.mKerningPairs[0].addr)

    if self.mNumKerningPairs != 0:
      # Check to see if the kerning pairs are sorted and
      # sort them if they are not.
      for i in 1..<self.mNumKerningPairs:
        if cmp(self.mKerningPairs[i - 1], self.mKerningPairs[i]) >= 0:
          self.sortKerningPairs()
          break

proc addKerning*(self: FontEngineWin32TTBase, first, second: int, x, y: var float64): bool =
  if self.mDC != NULL and self.mCurFont != NULL:
    if self.mNumKerningPairs == 0:
      self.loadKerningPairs()

    var
      stop  = self.mNumKerningPairs - 1
      start = 0
      t: KERNINGPAIR

    t.wFirst  = (WORD)first
    t.wSecond = (WORD)second
    while start <= stop:
      let mid = (stop + start) div 2
      if self.mKerningPairs[mid].wFirst == t.wFirst and self.mKerningPairs[mid].wSecond == t.wSecond:
        var
          dx = float64(self.mKerningPairs[mid].iKernAmount)
          dy = 0.0

        if self.mGlyphRendering in {glyph_ren_outline, glyph_ren_mono, glyph_ren_gray8}:
          self.mAffine.transform2x2(dx, dy)
        x += dx
        y += dy
        return true
      elif cmp(t, self.mKerningPairs[mid]) < 0:
        stop = mid - 1
      else:
        start = mid + 1
    return false
  return false

proc deinit*(self: FontEngineWin32TTBase) =
  if self.mDC != NULL and self.mOldFont != NULL:
    selectObject(self.mDC, self.mOldFont)

  for i in 0..<self.mNumFonts:
    deleteObject(self.mFonts[i])

proc init*(self: FontEngineWin32TTBase, flag32: bool, dc: HDC, maxFonts = 32) =
  self.mFlag32    = flag32
  self.mDC        = dc
  self.mOldFont   = if self.mDC != NULL: HFONT(getCurrentObject(self.mDC, OBJ_FONT)) else: HFONT(0)
  self.mFonts     = newSeq[HFONT](maxFonts)
  self.mNumFonts  = 0
  self.mMaxFonts  = maxFonts
  self.mFontNames = newSeq[string](maxFonts)
  self.mCurFont   = NULL

  self.mChangeStamp = 0
  self.mTypeFace    = ""
  self.mSignature   = ""

  self.mHeight  = 0
  self.mWidth   = 0
  self.mWeight  = FW_REGULAR
  self.mItalic  = false
  self.mCharSet = DWORD(DEFAULT_CHARSET)
  self.mPitchAndFamily = DWORD(FF_DONTCARE)

  self.mHinting     = true
  self.mFlipY       = false
  self.mFontCreated = false
  self.mResolution  = 0
  self.mGlyphRendering = glyph_ren_native_gray8

  self.mGlyphIndex = 0
  self.mDataSize   = 0
  self.mDataType   = glyph_data_invalid

  self.mBounds   = initRectI(1,1,0,0)
  self.mAdvanceX = 0.0
  self.mAdvanceY = 0.0

  self.mGBuf = newString(bufSize)
  self.mKerningPairs = @[]
  self.mNumKerningPairs = 0
  self.mMaxKerningPairs = 0

  self.mPath16 = initPathStorageInteger[int16]()
  self.mPath32 = initPathStorageInteger[int32]()
  self.mCurves16 = initConvCurve(self.mPath16)
  self.mCurves32 = initConvCurve(self.mPath32)

  self.mScanlineAA   = initScanlineU8()
  self.mScanlineBin  = initScanlineBin()
  self.mScanlinesAA  = initScanlineStorageAA8()
  self.mScanlinesBin = initScanlineStorageBin()
  self.mRasterizer   = initRasterizerScanlineAA()

  self.mCurves16.approximationScale(4.0)
  self.mCurves32.approximationScale(4.0)

  zeroMem(self.mMatrix.addr, sizeof(self.mMatrix))
  self.mMatrix.eM11.value = 1
  self.mMatrix.eM22.value = 1
  self.mAffine = initTransAffine()

# This class uses values of type int16 (10.6 format) for the vector cache.
# The vector cache is compact, but when rendering glyphs of height
# more that 200 there integer overflow can occur.

type
  FontEngineWin32TTInt16* = ref object of FontEngineWin32TTBase

template pathAdaptorT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  SerializedIntegerPathAdaptor[int16]

template gray8AdaptorT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  gray8AdaptorT(FontEngineWin32TTBase)

template monoAdaptorT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  monoAdaptorT(FontEngineWin32TTBase)

template scanlinesAAT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  scanlinesAAT(FontEngineWin32TTBase)

template scanlinesBinT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  scanlinesBinT(FontEngineWin32TTBase)

template gray8ScanlineT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  embeddedScanlineT(gray8AdaptorT(FontEngineWin32TTBase))

template monoScanlineT*(x: typedesc[FontEngineWin32TTInt16]): typedesc =
  embeddedScanlineT(monoAdaptorT(FontEngineWin32TTBase))

proc finalizer(self: FontEngineWin32TTInt16) =
  deinit(self)

proc newFontEngineWin32TTInt16*(dc: HDC, maxFonts = 32): FontEngineWin32TTInt16 =
  new(result, finalizer)
  result.init(false, dc, maxFonts)

# This class uses values of type int32 (26.6 format) for the vector cache.
# The vector cache is twice larger than in font_engine_win32_tt_int16,
# but it allows you to render glyphs of very large sizes.

type
  FontEngineWin32TTInt32* = ref object of FontEngineWin32TTBase

template pathAdaptorT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  SerializedIntegerPathAdaptor[int32]

template gray8AdaptorT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  gray8AdaptorT(FontEngineWin32TTBase)

template monoAdaptorT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  monoAdaptorT(FontEngineWin32TTBase)

template scanlinesAAT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  scanlinesAAT(FontEngineWin32TTBase)

template scanlinesBinT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  scanlinesBinT(FontEngineWin32TTBase)

template gray8ScanlineT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  embeddedScanlineT(gray8AdaptorT(FontEngineWin32TTBase))

template monoScanlineT*(x: typedesc[FontEngineWin32TTInt32]): typedesc =
  embeddedScanlineT(monoAdaptorT(FontEngineWin32TTBase))

proc finalizer(self: FontEngineWin32TTInt32) =
  deinit(self)

proc newFontEngineWin32TTInt32*(dc: HDC, maxFonts = 32): FontEngineWin32TTInt32 =
  new(result, finalizer)
  result.init(true, dc, maxFonts)
