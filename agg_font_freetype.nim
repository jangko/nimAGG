import agg_scanline_storage_aa, agg_scanline_storage_bin, agg_scanline_u
import agg_scanline_bin, agg_path_storage_integer, agg_rasterizer_scanline_aa
import agg_conv_curve, agg_font_types, agg_trans_affine, agg_basics, freetype
import strutils

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
    mGlyphIndex: int
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

proc crc32[T](crc: uint32, buf: T): uint32 =
  const kcrc32 = [ 0'u32, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190,
    0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320'u32, 0xf00f9344'u32, 0xd6d6a3e8'u32,
    0xcb61b38c'u32, 0x9b64c2b0'u32, 0x86d3d2d4'u32, 0xa00ae278'u32, 0xbdbdf21c'u32]

  var crcu32 = not crc
  for b in buf:
    crcu32 = (crcu32 shr 4) xor kcrc32[(crcu32 and 0xF) xor (int(b) and 0xF)]
    crcu32 = (crcu32 shr 4) xor kcrc32[(crcu32 and 0xF) xor (int(b) shr 4)]

  result = not crcu32

proc dbl_to_plain_fx(d: float64): int {.inline.} =
  result = int(d * 65536.0)

proc dbl_to_int26p6(p: float64): int {.inline.} =
  result = int(p * 64.0 + 0.5)

proc int26p6_to_dbl(p: int): float64 {.inline.} =
  result = float64(p) / 64.0
#[
template<class PathStorage>
bool decompose_ft_outline(const FT_Outline& outline,  bool flip_y, const trans_affine& mtx, PathStorage& path)
  typedef typename PathStorage::value_type value_type;

  FT_Vector   v_last;
  FT_Vector   v_control;
  FT_Vector   v_start;
  float64 x1, y1, x2, y2, x3, y3;

  FT_Vector*  point;
  FT_Vector*  limit;
  char*       tags;

  int   n;         # index of contour in outline
  int   first;     # index of first point in contour
  char  tag;       # current point's state

  first = 0;

  for(n = 0; n < outline.n_contours; n++)
  {
      int  last;  # index of last point in contour

      last  = outline.contours[n];
      limit = outline.points + last;

      v_start = outline.points[first];
      v_last  = outline.points[last];

      v_control = v_start;

      point = outline.points + first;
      tags  = outline.tags  + first;
      tag   = FT_CURVE_TAG(tags[0])

      # A contour cannot start with a cubic control point!
      if(tag == FT_CURVE_TAG_CUBIC) return false;

      # check first point to determine origin
      if( tag == FT_CURVE_TAG_CONIC)
      {
          # first point is conic control.  Yes, this happens.
          if(FT_CURVE_TAG(outline.tags[last]) == FT_CURVE_TAG_ON)
          {
              # start at last point if it is on the curve
              v_start = v_last;
              limit--;
          }
          else
          {
              # if both first and last points are conic,
              # start at their middle and record its position
              # for closure
              v_start.x = (v_start.x + v_last.x) / 2;
              v_start.y = (v_start.y + v_last.y) / 2;

              v_last = v_start;
          }
          point--;
          tags--;
      }

      x1 = int26p6_to_dbl(v_start.x)
      y1 = int26p6_to_dbl(v_start.y)
      if(flip_y) y1 = -y1;
      mtx.transform(&x1, &y1)
      path.move_to(value_type(dbl_to_int26p6(x1)),
                  value_type(dbl_to_int26p6(y1)))

      while(point < limit)
      {
          point++;
          tags++;

          tag = FT_CURVE_TAG(tags[0])
          case(tag)
          {
              of FT_CURVE_TAG_ON:  # emit a single line_to
              {
                  x1 = int26p6_to_dbl(point.x)
                  y1 = int26p6_to_dbl(point.y)
                  if(flip_y) y1 = -y1;
                  mtx.transform(&x1, &y1)
                  path.line_to(value_type(dbl_to_int26p6(x1)),
                              value_type(dbl_to_int26p6(y1)))
                  #path.line_to(conv(point.x), flip_y ? -conv(point.y) : conv(point.y))
                  continue;
              }

              of FT_CURVE_TAG_CONIC:  # consume conic arcs
              {
                  v_control.x = point.x;
                  v_control.y = point.y;

              Do_Conic:
                  if(point < limit)
                  {
                      FT_Vector vec;
                      FT_Vector v_middle;

                      point++;
                      tags++;
                      tag = FT_CURVE_TAG(tags[0])

                      vec.x = point.x;
                      vec.y = point.y;

                      if(tag == FT_CURVE_TAG_ON)
                      {
                          x1 = int26p6_to_dbl(v_control.x)
                          y1 = int26p6_to_dbl(v_control.y)
                          x2 = int26p6_to_dbl(vec.x)
                          y2 = int26p6_to_dbl(vec.y)
                          if(flip_y) { y1 = -y1; y2 = -y2; }
                          mtx.transform(&x1, &y1)
                          mtx.transform(&x2, &y2)
                          path.curve3(value_type(dbl_to_int26p6(x1)),
                                      value_type(dbl_to_int26p6(y1)),
                                      value_type(dbl_to_int26p6(x2)),
                                      value_type(dbl_to_int26p6(y2)))
                          continue;
                      }

                      if(tag != FT_CURVE_TAG_CONIC) return false;

                      v_middle.x = (v_control.x + vec.x) / 2;
                      v_middle.y = (v_control.y + vec.y) / 2;

                      x1 = int26p6_to_dbl(v_control.x)
                      y1 = int26p6_to_dbl(v_control.y)
                      x2 = int26p6_to_dbl(v_middle.x)
                      y2 = int26p6_to_dbl(v_middle.y)
                      if(flip_y) { y1 = -y1; y2 = -y2; }
                      mtx.transform(&x1, &y1)
                      mtx.transform(&x2, &y2)
                      path.curve3(value_type(dbl_to_int26p6(x1)),
                                  value_type(dbl_to_int26p6(y1)),
                                  value_type(dbl_to_int26p6(x2)),
                                  value_type(dbl_to_int26p6(y2)))

                      #path.curve3(conv(v_control.x),
                      #            flip_y ? -conv(v_control.y) : conv(v_control.y),
                      #            conv(v_middle.x),
                      #            flip_y ? -conv(v_middle.y) : conv(v_middle.y))

                      v_control = vec;
                      goto Do_Conic;
                  }

                  x1 = int26p6_to_dbl(v_control.x)
                  y1 = int26p6_to_dbl(v_control.y)
                  x2 = int26p6_to_dbl(v_start.x)
                  y2 = int26p6_to_dbl(v_start.y)
                  if(flip_y) { y1 = -y1; y2 = -y2; }
                  mtx.transform(&x1, &y1)
                  mtx.transform(&x2, &y2)
                  path.curve3(value_type(dbl_to_int26p6(x1)),
                              value_type(dbl_to_int26p6(y1)),
                              value_type(dbl_to_int26p6(x2)),
                              value_type(dbl_to_int26p6(y2)))

                  #path.curve3(conv(v_control.x),
                  #            flip_y ? -conv(v_control.y) : conv(v_control.y),
                  #            conv(v_start.x),
                  #            flip_y ? -conv(v_start.y) : conv(v_start.y))
                  goto Close;
              }

              default:  # FT_CURVE_TAG_CUBIC
              {
                  FT_Vector vec1, vec2;

                  if(point + 1 > limit || FT_CURVE_TAG(tags[1]) != FT_CURVE_TAG_CUBIC)
                  {
                      return false;
                  }

                  vec1.x = point[0].x;
                  vec1.y = point[0].y;
                  vec2.x = point[1].x;
                  vec2.y = point[1].y;

                  point += 2;
                  tags  += 2;

                  if(point <= limit)
                  {
                      FT_Vector vec;

                      vec.x = point.x;
                      vec.y = point.y;

                      x1 = int26p6_to_dbl(vec1.x)
                      y1 = int26p6_to_dbl(vec1.y)
                      x2 = int26p6_to_dbl(vec2.x)
                      y2 = int26p6_to_dbl(vec2.y)
                      x3 = int26p6_to_dbl(vec.x)
                      y3 = int26p6_to_dbl(vec.y)
                      if(flip_y) { y1 = -y1; y2 = -y2; y3 = -y3; }
                      mtx.transform(&x1, &y1)
                      mtx.transform(&x2, &y2)
                      mtx.transform(&x3, &y3)
                      path.curve4(value_type(dbl_to_int26p6(x1)),
                                  value_type(dbl_to_int26p6(y1)),
                                  value_type(dbl_to_int26p6(x2)),
                                  value_type(dbl_to_int26p6(y2)),
                                  value_type(dbl_to_int26p6(x3)),
                                  value_type(dbl_to_int26p6(y3)))

                      #path.curve4(conv(vec1.x),
                      #            flip_y ? -conv(vec1.y) : conv(vec1.y),
                      #            conv(vec2.x),
                      #            flip_y ? -conv(vec2.y) : conv(vec2.y),
                      #            conv(vec.x),
                      #            flip_y ? -conv(vec.y) : conv(vec.y))
                      continue;
                  }

                  x1 = int26p6_to_dbl(vec1.x)
                  y1 = int26p6_to_dbl(vec1.y)
                  x2 = int26p6_to_dbl(vec2.x)
                  y2 = int26p6_to_dbl(vec2.y)
                  x3 = int26p6_to_dbl(v_start.x)
                  y3 = int26p6_to_dbl(v_start.y)
                  if(flip_y) { y1 = -y1; y2 = -y2; y3 = -y3; }
                  mtx.transform(&x1, &y1)
                  mtx.transform(&x2, &y2)
                  mtx.transform(&x3, &y3)
                  path.curve4(value_type(dbl_to_int26p6(x1)),
                              value_type(dbl_to_int26p6(y1)),
                              value_type(dbl_to_int26p6(x2)),
                              value_type(dbl_to_int26p6(y2)),
                              value_type(dbl_to_int26p6(x3)),
                              value_type(dbl_to_int26p6(y3)))

                  #path.curve4(conv(vec1.x),
                  #            flip_y ? -conv(vec1.y) : conv(vec1.y),
                  #            conv(vec2.x),
                  #            flip_y ? -conv(vec2.y) : conv(vec2.y),
                  #            conv(v_start.x),
                  #            flip_y ? -conv(v_start.y) : conv(v_start.y))
                  goto Close;
              }
          }
      }

      path.close_polygon()

  Close:
      first = last + 1;
  }

  return true;

template<class Scanline, class ScanlineStorage>
proc decompose_ft_bitmap_mono(const FT_Bitmap& bitmap,
  int x, int y, bool flip_y, Scanline& sl, ScanlineStorage& storage)

  int i;
  const int8u* buf = (const int8u*)bitmap.buffer;
  int pitch = bitmap.pitch;
  sl.reset(x, x + bitmap.width)
  storage.prepare()
  if(flip_y)
  {
      buf += bitmap.pitch * (bitmap.rows - 1)
      y += bitmap.rows;
      pitch = -pitch;
  }
  for(i = 0; i < bitmap.rows; i++)
  {
      sl.reset_spans()
      bitset_iterator bits(buf, 0)
      int j;
      for(j = 0; j < bitmap.width; j++)
      {
          if(bits.bit()) sl.add_cell(x + j, cover_full)
          ++bits;
      }
      buf += pitch;
      if(sl.num_spans())
      {
          sl.finalize(y - i - 1)
          storage.render(sl)
      }

template<class Rasterizer, class Scanline, class ScanlineStorage>
proc decompose_ft_bitmap_gray8(const FT_Bitmap& bitmap,
  int x, int y, bool flip_y, Rasterizer& ras,
  Scanline& sl, ScanlineStorage& storage)

  int i, j;
  const int8u* buf = (const int8u*)bitmap.buffer;
  int pitch = bitmap.pitch;
  sl.reset(x, x + bitmap.width)
  storage.prepare()
  if(flip_y)
  {
      buf += bitmap.pitch * (bitmap.rows - 1)
      y += bitmap.rows;
      pitch = -pitch;
  }
  for(i = 0; i < bitmap.rows; i++)
  {
      sl.reset_spans()
      const int8u* p = buf;
      for(j = 0; j < bitmap.width; j++)
      {
          if(*p) sl.add_cell(x + j, ras.apply_gamma(*p))
          ++p;
      }
      buf += pitch;
      if(sl.num_spans())
      {
          sl.finalize(y - i - 1)
          storage.render(sl)
      }

typedef serialized_scanlines_adaptor_aa<int8u>    gray8_adaptor_type;
typedef serialized_scanlines_adaptor_bin          mono_adaptor_type;
typedef scanline_storage_aa8                      scanlines_aa_type;
typedef scanline_storage_bin                      scanlines_bin_type;
]#

proc deinit(self: FontEngineFreetypeBase) =
  for i in 0.. <self.mNumFaces:
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

proc toFxHex(x: float64): string =
  let y = dbl_to_plain_fx(x)
  result = y.toHex(8)

proc updateSignature(self: FontEngineFreetypeBase) =
  if not self.mCurFace.isNil and self.mName != nil:
    var gammaHash = 0
    if self.mGlyphRendering in {glyph_ren_native_gray8, glyph_ren_agg_mono, glyph_ren_agg_gray8}:
      var gammaTable = newSeq[uint8](getAAScale(self.mRasterizer.type))
      for i in 0.. <gammaTable.len:
        gammaTable[i] = self.mRasterizer.applyGamma(i).uint8
      gammaHash = int(crc32(0, gammaTable))

    self.mSignature = "$1,$2,$3,$4,$5:$6x$7,$8,$9,$10" % [
      self.mName, $int(self.mCharMap), $self.mFaceIndex,
      $int(self.mGlyphRendering), $self.mResolution,
      $self.mHeight, $self.mWidth, $int(self.mHinting),
      $int(self.mFlipY), gammaHash.toHex(8)]

    if self.mGlyphRendering in {glyph_ren_outline, glyph_ren_agg_mono, glyph_ren_agg_gray8}:
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
#[
bool load_font(self: FontEngineFreetypeBase, const char* font_name, unsigned face_index, glyph_rendering ren_type,
               const char* font_mem = 0, const long font_mem_size = 0)
  bool ret = false;

  if(self.mLibraryInitialized)
    self.mLastError = 0;

    int idx = find_face(font_name)
    if(idx >= 0)
      self.mCurFace = self.mFaces[idx];
      self.mName     = self.mFaceNames[idx];
    else
      if(self.mNumFaces >= self.mMaxFaces)
        delete [] self.mFaceNames[0];
        FT_Done_Face(self.mFaces[0])
        memcpy(self.mFaces,
              self.mFaces + 1,
              (self.mMaxFaces - 1) * sizeof(FT_Face))
        memcpy(self.mFaceNames,
              self.mFaceNames + 1,
              (self.mMaxFaces - 1) * sizeof(char*))
        self.mNumFaces = self.mMaxFaces - 1;

      if (font_mem and font_mem_size)
        self.mLastError = FT_New_Memory_Face(self.mLibrary,
                                          (const FT_Byte*)font_mem,
                                          font_mem_size,
                                          face_index,
                                          &self.mFaces[self.mNumFaces])
      else
        self.mLastError = FT_New_Face(self.mLibrary,
                                  font_name,
                                  face_index,
                                  &self.mFaces[self.mNumFaces])

      if(self.mLastError == 0)
        self.mFaceNames[self.mNumFaces] = new char [strlen(font_name) + 1];
        strcpy(self.mFaceNames[self.mNumFaces], font_name)
        self.mCurFace = self.mFaces[self.mNumFaces];
        self.mName     = self.mFaceNames[self.mNumFaces];
        ++self.mNumFaces;
      else
        self.mFaceNames[self.mNumFaces] = 0;
        self.mCurFace = 0;
        self.mName = 0;

    if(self.mLastError == 0)
      ret = true;

      case(ren_type)
      of glyph_ren_native_mono:
        self.mGlyphRendering = glyph_ren_native_mono;
        break;

      of glyph_ren_native_gray8:
        self.mGlyphRendering = glyph_ren_native_gray8;
        break;

      of glyph_ren_outline:
        if(FT_IS_SCALABLE(self.mCurFace))
            self.mGlyphRendering = glyph_ren_outline;
        else
            self.mGlyphRendering = glyph_ren_native_gray8;
        break;

      of glyph_ren_agg_mono:
        if(FT_IS_SCALABLE(self.mCurFace))
            self.mGlyphRendering = glyph_ren_agg_mono;
        else
            self.mGlyphRendering = glyph_ren_native_mono;
        break;

      of glyph_ren_agg_gray8:
        if(FT_IS_SCALABLE(self.mCurFace))
            self.mGlyphRendering = glyph_ren_agg_gray8;
        else
            self.mGlyphRendering = glyph_ren_native_gray8;
        break;
      updateSignature()
  return ret;
]#
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

proc height*(self: FontEngineFreetypeBase, h: float64): bool =
  self.mHeight = FT_F26Dot6(h * 64.0)
  if not self.mCurFace.isNil:
    self.updateCharSize()
    return true
  result = false

proc width*(self: FontEngineFreetypeBase, w: float64): bool =
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

#[
proc prepareGlyph(self: FontEngineFreetypeBase, glyphCode: int): bool =
  self.mGlyphIndex = FT_Get_Char_Index(self.mCurFace, glyph_code)
  self.mLastError = FT_Load_Glyph(self.mCurFace,
                              self.mGlyphIndex,
                              self.mHinting ? FT_LOAD_DEFAULT : FT_LOAD_NO_HINTING)
                              # self.mHinting ? FT_LOAD_FORCE_AUTOHINT : FT_LOAD_NO_HINTING)
  if(self.mLastError == 0)
  {
      case(self.mGlyphRendering)
      {
      of glyph_ren_native_mono:
          self.mLastError = FT_Render_Glyph(self.mCurFace.glyph, FT_RENDER_MODE_MONO)
          if(self.mLastError == 0)
          {
              decompose_ft_bitmap_mono(self.mCurFace.glyph.bitmap,
                                      self.mCurFace.glyph.bitmap_left,
                                      self.mFlipY ? -self.mCurFace.glyph.bitmap_top :
                                                  self.mCurFace.glyph.bitmap_top,
                                      self.mFlipY,
                                      self.mScanlineBin,
                                      self.mScanlinesBin)
              self.mBounds.x1 = self.mScanlinesBin.min_x()
              self.mBounds.y1 = self.mScanlinesBin.min_y()
              self.mBounds.x2 = self.mScanlinesBin.max_x() + 1;
              self.mBounds.y2 = self.mScanlinesBin.max_y() + 1;
              self.mDataSize = self.mScanlinesBin.byte_size()
              self.mDataType = glyph_data_mono;
              self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
              self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
              return true;
          }
          break;


      of glyph_ren_native_gray8:
          self.mLastError = FT_Render_Glyph(self.mCurFace.glyph, FT_RENDER_MODE_NORMAL)
          if(self.mLastError == 0)
          {
              decompose_ft_bitmap_gray8(self.mCurFace.glyph.bitmap,
                                        self.mCurFace.glyph.bitmap_left,
                                        self.mFlipY ? -self.mCurFace.glyph.bitmap_top :
                                                    self.mCurFace.glyph.bitmap_top,
                                        self.mFlipY,
                                        self.mRasterizer,
                                        self.mScanlineAA,
                                        self.mScanlinesAA)
              self.mBounds.x1 = self.mScanlinesAA.min_x()
              self.mBounds.y1 = self.mScanlinesAA.min_y()
              self.mBounds.x2 = self.mScanlinesAA.max_x() + 1;
              self.mBounds.y2 = self.mScanlinesAA.max_y() + 1;
              self.mDataSize = self.mScanlinesAA.byte_size()
              self.mDataType = glyph_data_gray8;
              self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
              self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
              return true;
          }
          break;


      of glyph_ren_outline:
          if(self.mLastError == 0)
          {
              if(self.mFlag32)
              {
                  self.mPath32.remove_all()
                  if(decompose_ft_outline(self.mCurFace.glyph.outline,
                                          self.mFlipY,
                                          self.mAffine,
                                          self.mPath32))
                  {
                      rect_d bnd  = self.mPath32.bounding_rect()
                      self.mDataSize = self.mPath32.byte_size()
                      self.mDataType = glyph_data_outline;
                      self.mBounds.x1 = int(floor(bnd.x1))
                      self.mBounds.y1 = int(floor(bnd.y1))
                      self.mBounds.x2 = int(ceil(bnd.x2))
                      self.mBounds.y2 = int(ceil(bnd.y2))
                      self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
                      self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
                      self.mAffine.transform(&self.mAdvanceX, &self.mAdvanceY)
                      return true;
                  }
              }
              else
              {
                  self.mPath16.remove_all()
                  if(decompose_ft_outline(self.mCurFace.glyph.outline,
                                          self.mFlipY,
                                          self.mAffine,
                                          self.mPath16))
                  {
                      rect_d bnd  = self.mPath16.bounding_rect()
                      self.mDataSize = self.mPath16.byte_size()
                      self.mDataType = glyph_data_outline;
                      self.mBounds.x1 = int(floor(bnd.x1))
                      self.mBounds.y1 = int(floor(bnd.y1))
                      self.mBounds.x2 = int(ceil(bnd.x2))
                      self.mBounds.y2 = int(ceil(bnd.y2))
                      self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
                      self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
                      self.mAffine.transform(&self.mAdvanceX, &self.mAdvanceY)
                      return true;
                  }
              }
          }
          return false;

      of glyph_ren_agg_mono:
          if(self.mLastError == 0)
          {
              self.mRasterizer.reset()
              if(self.mFlag32)
              {
                  self.mPath32.remove_all()
                  decompose_ft_outline(self.mCurFace.glyph.outline,
                                      self.mFlipY,
                                      self.mAffine,
                                      self.mPath32)
                  self.mRasterizer.add_path(self.mCurves32)
              }
              else
              {
                  self.mPath16.remove_all()
                  decompose_ft_outline(self.mCurFace.glyph.outline,
                                      self.mFlipY,
                                      self.mAffine,
                                      self.mPath16)
                  self.mRasterizer.add_path(self.mCurves16)
              }
              self.mScanlinesBin.prepare() # Remove all
              render_scanlines(self.mRasterizer, self.mScanlineBin, self.mScanlinesBin)
              self.mBounds.x1 = self.mScanlinesBin.min_x()
              self.mBounds.y1 = self.mScanlinesBin.min_y()
              self.mBounds.x2 = self.mScanlinesBin.max_x() + 1;
              self.mBounds.y2 = self.mScanlinesBin.max_y() + 1;
              self.mDataSize = self.mScanlinesBin.byte_size()
              self.mDataType = glyph_data_mono;
              self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
              self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
              self.mAffine.transform(&self.mAdvanceX, &self.mAdvanceY)
              return true;
          }
          return false;


      of glyph_ren_agg_gray8:
          if(self.mLastError == 0)
          {
              self.mRasterizer.reset()
              if(self.mFlag32)
              {
                  self.mPath32.remove_all()
                  decompose_ft_outline(self.mCurFace.glyph.outline,
                                      self.mFlipY,
                                      self.mAffine,
                                      self.mPath32)
                  self.mRasterizer.add_path(self.mCurves32)
              }
              else
              {
                  self.mPath16.remove_all()
                  decompose_ft_outline(self.mCurFace.glyph.outline,
                                      self.mFlipY,
                                      self.mAffine,
                                      self.mPath16)
                  self.mRasterizer.add_path(self.mCurves16)
              }
              self.mScanlinesAA.prepare() # Remove all
              render_scanlines(self.mRasterizer, self.mScanlineAA, self.mScanlinesAA)
              self.mBounds.x1 = self.mScanlinesAA.min_x()
              self.mBounds.y1 = self.mScanlinesAA.min_y()
              self.mBounds.x2 = self.mScanlinesAA.max_x() + 1;
              self.mBounds.y2 = self.mScanlinesAA.max_y() + 1;
              self.mDataSize = self.mScanlinesAA.byte_size()
              self.mDataType = glyph_data_gray8;
              self.mAdvanceX = int26p6_to_dbl(self.mCurFace.glyph.advance.x)
              self.mAdvanceY = int26p6_to_dbl(self.mCurFace.glyph.advance.y)
              self.mAffine.transform(&self.mAdvanceX, &self.mAdvanceY)
              return true;
          }
          return false;
      }
  }
  return false;
]#

proc glyphIndex*(self: FontEngineFreetypeBase): int =
  self.mGlyphIndex

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

proc addKerning*(self: FontEngineFreetypeBase, first, second: FT_UInt, x, y: var float64): bool =
  const renType = {glyph_ren_outline, glyph_ren_agg_mono, glyph_ren_agg_gray8}
  let cond = not self.mCurFace.isNil and first != 0 and second != 0

  if cond and FT_HAS_KERNING(self.mCurFace):
    var delta: FT_Vector
    discard FT_Get_Kerning(self.mCurFace, first, second, FT_KERNING_DEFAULT, delta)
    var
      dx = int26p6_to_dbl(delta.x)
      dy = int26p6_to_dbl(delta.y)
    if self.mGlyphRendering in renType:
      self.mAffine.transform2x2(dx, dy)
    x += dx
    y += dy
    return true
  result = false

proc findFace*(self: FontEngineFreetypeBase, faceName: string): int =
  for i in 0.. <self.mNumFaces:
    if faceName == self.mFaceNames[i]:
      return i
  result = -1

#[
# This class uses values of type int16 (10.6 format) for the vector cache.
# The vector cache is compact, but when rendering glyphs of height
# more that 200 there integer overflow can occur.
#
class font_engine_freetype_int16 : public font_engine_freetype_base
{
public:
    typedef serialized_integer_path_adaptor<int16, 6>     path_adaptor_type;
    typedef font_engine_freetype_base::gray8_adaptor_type gray8_adaptor_type;
    typedef font_engine_freetype_base::mono_adaptor_type  mono_adaptor_type;
    typedef font_engine_freetype_base::scanlines_aa_type  scanlines_aa_type;
    typedef font_engine_freetype_base::scanlines_bin_type scanlines_bin_type;

    font_engine_freetype_int16(unsigned maxFaces = 32) :
        font_engine_freetype_base(false, maxFaces) {}

# This class uses values of type int32 (26.6 format) for the vector cache.
# The vector cache is twice larger than in font_engine_freetype_int16,
# but it allows you to render glyphs of very large sizes.
#
class font_engine_freetype_int32 : public font_engine_freetype_base
{
public:
    typedef serialized_integer_path_adaptor<int32, 6>     path_adaptor_type;
    typedef font_engine_freetype_base::gray8_adaptor_type gray8_adaptor_type;
    typedef font_engine_freetype_base::mono_adaptor_type  mono_adaptor_type;
    typedef font_engine_freetype_base::scanlines_aa_type  scanlines_aa_type;
    typedef font_engine_freetype_base::scanlines_bin_type scanlines_bin_type;

    font_engine_freetype_int32(unsigned maxFaces = 32) :
        font_engine_freetype_base(true, maxFaces) {}
]#