import agg_basics, agg_font_types

const
  blockSize = 16384-16

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
  if self.mGlyphs[msb] != nil:
    return self.mGlyphs[msb][glyphCode and 0xFF]
  result = nil

proc cacheGlyph*(self: var FontCache, glyphCode, glyphIndex, dataSize: int,
  dataType: GlyphDataType, bounds: RectI, advanceX, advanceY: float64): GlyphCache =

  let msb = (glyphCode shr 8) and 0xFF
  if self.mGlyphs[msb] == nil:
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
  for i in 0.. <self.mNumFonts:
    if self.mFonts[i].fontIs(fontSignature):
      return i
  result = -1

proc font*(self: FontCachePool, fontSignature: string, resetCache = false) =
  let idx = self.findFont(fontSignature)
  if idx >= 0:
    if resetCache:
      self.mFonts[idx] = new(FontCache)
      self.mFonts[idx].signature(fontSignature)
    self.mCurFont = self.mFonts[idx]
  else:
    if self.mNumFonts >= self.mMaxFonts:
      self.mFonts.del(0)
      self.mNumFonts = self.mMaxFonts - 1

    self.mFonts[self.mNumFonts] = new(FontCache)
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

type
  FontCacheManager[FontEngine] = ref object
    mFonts: FontCachePool
    mEngine: FontEngine
    mChangeStamp: int
    mDx, mDy: float64
    mPrevGlyph, mLastGlyph: GlyphCache
    
#[    
    path_adaptor_type   self.mPathAdaptor;
    gray8_adaptor_type  self.mGray8Adaptor;
    gray8_scanline_type self.mGray8Scanline;
    mono_adaptor_type   self.mMonoAdaptor;
    mono_scanline_type  self.mMonoScanline;

    typedef FontEngine font_engine_type;
    typedef font_cache_manager<FontEngine> self_type;
    typedef typename font_engine_type::path_adaptor_type   path_adaptor_type;
    typedef typename font_engine_type::gray8_adaptor_type  gray8_adaptor_type;
    typedef typename gray8_adaptor_type::embedded_scanline gray8_scanline_type;
    typedef typename font_engine_type::mono_adaptor_type   mono_adaptor_type;
    typedef typename mono_adaptor_type::embedded_scanline  mono_scanline_type;


    font_cache_manager(font_engine_type& engine, unsigned max_fonts=32) :
        self.mFonts(max_fonts),
        self.mEngine(engine),
        self.mChangeStamp(-1),
        self.mPrevGlyph(0),
        self.mLastGlyph(0)

proc reset_last_glyph()
    self.mPrevGlyph = self.mLastGlyph = 0;


const glyph_cache* glyph(unsigned glyphCode)
{
    synchronize()
    const glyph_cache* gl = self.mFonts.find_glyph(glyphCode)
    if gl)
        self.mPrevGlyph = self.mLastGlyph;
        return self.mLastGlyph = gl;
    else:
        if self.mEngine.prepare_glyph(glyphCode))
            self.mPrevGlyph = self.mLastGlyph;
            self.mLastGlyph = self.mFonts.cache_glyph(glyphCode,
                                               self.mEngine.glyphIndex(),
                                               self.mEngine.dataSize(),
                                               self.mEngine.dataType(),
                                               self.mEngine.bounds(),
                                               self.mEngine.advanceX(),
                                               self.mEngine.advanceY())
            self.mEngine.write_glyph_to(self.mLastGlyphdata)
            return self.mLastGlyph;
    return 0;

proc init_embedded_adaptors(const glyph_cache* gl,
                            x, y: float64,
                            double scale=1.0)
    if gl)
        case gldataType)
        default: return;
        of glyph_data_mono:
            self.mMonoAdaptor.init(gldata, gldataSize, x, y)
        of glyph_data_gray8:
            self.mGray8Adaptor.init(gldata, gldataSize, x, y)
        of glyph_data_outline:
            self.mPathAdaptor.init(gldata, gldataSize, x, y, scale)

path_adaptor_type&   path_adaptor()   { return self.mPathAdaptor;   }
gray8_adaptor_type&  gray8_adaptor()  { return self.mGray8Adaptor;  }
gray8_scanline_type& gray8_scanline() = return self.mGray8Scanline
mono_adaptor_type&   mono_adaptor()   { return self.mMonoAdaptor;   }
mono_scanline_type&  mono_scanline()  { return self.mMonoScanline;  }

const glyph_cache* prev_glyph(): float64 = self.mPrevGlyph
const glyph_cache* last_glyph(): float64 = self.mLastGlyph


bool addKerning(x, y: var float64)
    if self.mPrevGlyph and self.mLastGlyph)
        return self.mEngine.addKerning(self.mPrevGlyphglyphIndex,
                                    self.mLastGlyphglyphIndex,
                                    x, y)
    return false;

proc precache(unsigned from, unsigned to)
        for(; from <= to; ++from) glyph(from)

proc reset_cache()
        self.mFonts.font(self.mEngine.font_signature(), true)
        self.mChangeStamp = self.mEngine.changeStamp()
        self.mPrevGlyph = self.mLastGlyph = 0;

proc synchronize()
        if self.mChangeStamp != self.mEngine.changeStamp())
            self.mFonts.font(self.mEngine.font_signature())
            self.mChangeStamp = self.mEngine.changeStamp()
            self.mPrevGlyph = self.mLastGlyph = 0;
]#
