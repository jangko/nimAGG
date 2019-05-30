import basics, font_types, scanline_storage_bin
import scanline_storage_aa, path_storage_integer, strutils

const windowsTTEngine* = (defined(windows) or defined(use_windows_tt)) and not defined(use_freetype)
const freeTypeEngine*  = defined(use_freetype)

when windowsTTEngine:
  import font_win32_tt
else:
  import font_freetype

#const
#  blockSize = 16384-16

type
  GlyphRow = seq[GlyphCache]

  FontCache* = ref object
    mGlyphs: array[256, GlyphRow]
    mFontSignature: string

proc newFontCache*(): FontCache =
  new(result)
  result.mFontSignature = ""

proc signature*(self: var FontCache, fontSignature: string) =
  self.mFontSignature = fontSignature

proc fontIs*(self: var FontCache, fontSignature: string): bool =
  result = fontSignature == self.mFontSignature

proc findGlyph*(self: var FontCache, glyphCode: int): GlyphCache =
  let msb = (glyphCode shr 8) and 0xFF
  if self.mGlyphs[msb].len > 0:
    return self.mGlyphs[msb][glyphCode and 0xFF]
  result = nil

proc cacheGlyph*(self: var FontCache, glyphCode, glyphIndex, dataSize: int,
  dataType: GlyphDataType, bounds: RectI, advanceX, advanceY: float64): GlyphCache =

  let msb = (glyphCode shr 8) and 0xFF
  if self.mGlyphs[msb].len == 0:
    self.mGlyphs[msb] = newSeq[GlyphCache](256)

  let lsb = glyphCode and 0xFF
  if self.mGlyphs[msb][lsb] != nil:
    return nil # Already exists, do not overwrite

  var glyph = new(GlyphCache)
  glyph.glyphIndex       = glyphIndex
  glyph.data             = newSeq[uint8](dataSize)
  glyph.dataSize         = dataSize
  glyph.dataType         = dataType
  glyph.bounds           = bounds
  glyph.advanceX         = advanceX
  glyph.advanceY         = advanceY
  self.mGlyphs[msb][lsb] = glyph
  result = glyph

type
  FontCachePool* = ref object
    mFonts: seq[FontCache]
    mMaxFonts: int
    mNumFonts: int
    mCurFont: FontCache

proc newFontCachePool*(maxFonts = 32): FontCachePool =
  new(result)
  result.mFonts = newSeq[FontCache](maxFonts)
  result.mMaxFonts = maxFonts
  result.mNumFonts = 0
  result.mCurFont = nil

proc findFont(self: FontCachePool, fontSignature: string): int =
  for i in 0..<self.mNumFonts:
    if self.mFonts[i].fontIs(fontSignature):
      return i
  result = -1

proc font*(self: FontCachePool, fontSignature: string, resetCache = false) =
  let idx = self.findFont(fontSignature)
  if idx >= 0:
    if resetCache:
      self.mFonts[idx] = newFontCache()
      self.mFonts[idx].signature(fontSignature)
    self.mCurFont = self.mFonts[idx]
  else:
    if self.mNumFonts >= self.mMaxFonts:
      for i in 0..<self.mFonts.len-1:
        shallowCopy(self.mFonts[i], self.mFonts[i+1])
      self.mNumFonts = self.mMaxFonts - 1

    self.mFonts[self.mNumFonts] = newFontCache()
    self.mFonts[self.mNumFonts].signature(fontSignature)
    self.mCurFont = self.mFonts[self.mNumFonts]
    inc self.mNumFonts

proc font*(self: FontCachePool): FontCache =
  self.mCurFont

proc findGlyph*(self: FontCachePool, glyphCode: int): GlyphCache =
  if self.mCurFont != nil:
    return self.mCurFont.findGlyph(glyphCode)
  result = nil

proc cacheGlyph*(self: FontCachePool, glyphCode, glyphIndex, dataSize: int,
  dataType: GlyphDataType, bounds: RectI, advanceX, advanceY: float64): GlyphCache =

  if self.mCurFont != nil:
    return self.mCurFont.cacheGlyph(glyphCode, glyphIndex, dataSize,
      dataType, bounds, advanceX, advanceY)
  result = nil

template fontCacheManager(name: untyped, FontEngine: typedesc) =
  type
    name* = ref object
      mFonts: FontCachePool
      mEngine: FontEngine
      mChangeStamp: int
      mDx, mDy: float64
      mPrevGlyph, mLastGlyph: GlyphCache
      mPathAdaptor: pathAdaptorT(FontEngine)
      mGray8Adaptor: gray8AdaptorT(FontEngine)
      mGray8Scanline: gray8ScanlineT(FontEngine)
      mMonoAdaptor: monoAdaptorT(FontEngine)
      mMonoScanline: monoScanlineT(FontEngine)

  template fontEngineT*(x: typedesc[name]): typedesc = FontEngine
  template pathAdaptorT*(x: typedesc[name]): typedesc = pathAdaptorT(FontEngine)
  template gray8AdaptorT*(x: typedesc[name]): typedesc = gray8AdaptorT(FontEngine)
  template gray8ScanlineT*(x: typedesc[name]): typedesc = gray8ScanlineT(FontEngine)
  template monoAdaptorT*(x: typedesc[name]): typedesc = monoAdaptorT(FontEngine)
  template monoScanlineT*(x: typedesc[name]): typedesc = monoScanlineT(FontEngine)

  proc `new name`*(engine: FontEngine, maxFonts = 32): name =
    new(result)
    result.mFonts = newFontCachePool(maxFonts)
    result.mEngine = engine
    result.mChangeStamp = -1
    result.mPrevGlyph = nil
    result.mLastGlyph = nil

  proc resetLastGlyph*(self: name) =
    self.mPrevGlyph = nil
    self.mLastGlyph = nil

  proc synchronize*(self: name) =
    if self.mChangeStamp != self.mEngine.changeStamp():
      self.mFonts.font(self.mEngine.fontSignature())
      self.mChangeStamp = self.mEngine.changeStamp()
      self.mPrevGlyph = nil
      self.mLastGlyph = nil

  proc glyph*(self: name, glyphCode: int): GlyphCache =
    self.synchronize()
    let gl = self.mFonts.findGlyph(glyphCode)
    if gl != nil:
      self.mPrevGlyph = self.mLastGlyph
      self.mLastGlyph = gl
      return gl
    else:
      if self.mEngine.prepareGlyph(glyphCode):
        self.mPrevGlyph = self.mLastGlyph

        self.mLastGlyph = self.mFonts.cacheGlyph(glyphCode,
          self.mEngine.glyphIndex(), self.mEngine.dataSize(),
          self.mEngine.dataType(), self.mEngine.bounds(),
          self.mEngine.advanceX(), self.mEngine.advanceY())

        if self.mLastGlyph.data.len > 0:
          self.mEngine.writeGlyphTo(self.mLastGlyph.data[0].addr)
        return self.mLastGlyph
    result = nil

  proc initEmbeddedAdaptors*(self: name, gl: GlyphCache, x, y: float64, scale = 1.0) =
    if gl != nil:
      var
        data: ptr uint8 = if gl.data.len == 0: nil else: gl.data[0].addr
      case gl.dataType
      of glyph_data_mono:
        self.mMonoAdaptor.init(data, gl.dataSize, x, y)
      of glyph_data_gray8:
        self.mGray8Adaptor.init(data, gl.dataSize, x, y)
      of glyph_data_outline:
        self.mPathAdaptor.init(data, gl.dataSize, x, y, scale)

  proc pathAdaptor*(self: name): var pathAdaptorT(FontEngine) = self.mPathAdaptor
  proc gray8Adaptor*(self: name): var gray8AdaptorT(FontEngine) = self.mGray8Adaptor
  proc gray8Scanline*(self: name): var gray8ScanlineT(FontEngine) = self.mGray8Scanline
  proc monoAdaptor*(self: name): var monoAdaptorT(FontEngine) = self.mMonoAdaptor
  proc monoScanline*(self: name): var monoScanlineT(FontEngine) = self.mMonoScanline

  proc prevGlyph*(self: name): GlyphCache = self.mPrevGlyph
  proc lastGlyph*(self: name): GlyphCache = self.mLastGlyph

  proc addKerning*(self: name; x, y: var float64): bool =
    if self.mPrevGlyph != nil and self.mLastGlyph != nil:
      result = self.mEngine.addKerning(self.mPrevGlyph.glyphIndex,
        self.mLastGlyph.glyphIndex, x, y)
      return result
    result = false

  proc preCache*(self: name, start, stop: int) =
    for x in start..stop:
      discard self.glyph(x)

  proc resetCache*(self: name) =
    self.mFonts.font(self.mEngine.fontSignature(), true)
    self.mChangeStamp = self.mEngine.changeStamp()
    self.mPrevGlyph = nil
    self.mLastGlyph = nil

when windowsTTEngine:
  fontCacheManager(FontCacheManagerWin16, FontEngineWin32TTInt16)
  fontCacheManager(FontCacheManagerWin32, FontEngineWin32TTInt32)
else:
  fontCacheManager(FontCacheManagerFreeType16, FontEngineFreeType16)
  fontCacheManager(FontCacheManagerFreeType32, FontEngineFreeType32)

