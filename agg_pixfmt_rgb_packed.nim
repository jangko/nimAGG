import agg_basics, agg_color_rgba, agg_rendering_buffer

type
  BlenderRgb555* = object

template getColorT*(x: typedesc[BlenderRgb555]): typedesc = Rgba8
template getValueT*(x: typedesc[BlenderRgb555]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgb555]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgb555]): typedesc = uint16

proc BlenderRgb555_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgb555)
  var
    rgb = p[]
    r = CalcT(rgb shr 7) and 0xF8
    g = CalcT(rgb shr 2) and 0xF8
    b = CalcT(rgb shl 3) and 0xF8
  p[] = PixelT(((((cr - r) * alpha + (r shl 8)) shr 1)  and 0x7C00) or
               ((((cg - g) * alpha + (g shl 8)) shr 6)  and 0x03E0) or
                (((cb - b) * alpha + (b shl 8)) shr 11) or 0x8000)

template blendPix*(self: BlenderRgb555, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgb555_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgb555], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 7) or ((g and 0xF8) shl 2) or (b shr 3) or 0x8000)

proc makeColor*[PixelT](x: typedesc[BlenderRgb555], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 7) and 0xF8, (p shr 2) and 0xF8, (p shl 3) and 0xF8)

type
  BlenderRgb555Pre* = object

template getColorT*(x: typedesc[BlenderRgb555Pre]): typedesc = Rgba8
template getValueT*(x: typedesc[BlenderRgb555Pre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgb555Pre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgb555Pre]): typedesc = uint16

proc BlenderRgb555Pre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgb555Pre)
  const
    baseMask = uint(getBaseMask(getColorT(BlenderRgb555Pre)))
  var
    alpha = baseMask - alpha
    rgb = p[]
    r = CalcT(rgb shr 7) and 0xF8
    g = CalcT(rgb shr 2) and 0xF8
    b = CalcT(rgb shl 3) and 0xF8
  p[] = PixelT((((r.uint * alpha + cr * cover) shr 1)  and 0x7C00) or
               (((g.uint * alpha + cg * cover) shr 6)  and 0x03E0) or
                ((b.uint * alpha + cb * cover) shr 11) or 0x8000)

template blendPix*(self: BlenderRgb555Pre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgb555Pre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgb555Pre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 7) or ((g and 0xF8) shl 2) or (b shr 3) or 0x8000)

proc makeColor*[PixelT](x: typedesc[BlenderRgb555Pre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 7) and 0xF8, (p shr 2) and 0xF8, (p shl 3) and 0xF8)

type
  BlenderRgb555Gamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderRgb555Gamma[G]]): typedesc = Rgba8
template getValueT*[G](x: typedesc[BlenderRgb555Gamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderRgb555Gamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderRgb555Gamma[G]]): typedesc = uint16
template getGammaT*[G](x: typedesc[BlenderRgb555Gamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderRgb555Gamma[G], g: var G) =
  self.mGamma = g.addr

proc blendPix*[G, PixelT](self: BlenderRgb555Gamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    rgb = p[]
    r = CalcT(self.mGamma[].dir((rgb shr 7) and 0xF8))
    g = CalcT(self.mGamma[].dir((rgb shr 2) and 0xF8))
    b = CalcT(self.mGamma[].dir((rgb shl 3) and 0xF8))
  p[] = PixelT(((self.mGamma[].inv(((self.mGamma[].dir(cr).CalcT - r) * alpha.CalcT + (r shl 8)) shr 8).CalcT shl 7) and 0x7C00) or
               ((self.mGamma[].inv(((self.mGamma[].dir(cg).CalcT - g) * alpha.CalcT + (g shl 8)) shr 8).CalcT shl 2) and 0x03E0) or
                (self.mGamma[].inv(((self.mGamma[].dir(cb).CalcT - b) * alpha.CalcT + (b shl 8)) shr 8).CalcT shr 3) or 0x8000)

proc makePix*[G](x: typedesc[BlenderRgb555Gamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 7) or ((g and 0xF8) shl 2) or (b shr 3) or 0x8000)

proc makeColor*[G, PixelT](x: typedesc[BlenderRgb555Gamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 7) and 0xF8, (p shr 2) and 0xF8, (p shl 3) and 0xF8)

type
  BlenderRgb565* =  object

template getColorT*(x: typedesc[BlenderRgb565]): typedesc = Rgba8
template getValueT*(x: typedesc[BlenderRgb565]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgb565]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgb565]): typedesc = uint16

proc BlenderRgb565_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgb565)
  var
    rgb = p[]
    r = CalcT(rgb shr 8) and 0xF8
    g = CalcT(rgb shr 3) and 0xFC
    b = CalcT(rgb shl 3) and 0xF8
  p[] = PixelT(((((cr - r) * alpha + (r shl 8))       ) and 0xF800) or
               ((((cg - g) * alpha + (g shl 8)) shr 5 ) and 0x07E0) or
                (((cb - b) * alpha + (b shl 8)) shr 11))

template blendPix*(self: BlenderRgb565, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgb565_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgb565], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 8) or ((g and 0xFC) shl 3) or (b shr 3))

proc makeColor*[PixelT](x: typedesc[BlenderRgb565], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 8) and 0xF8, (p shr 3) and 0xFC, (p shl 3) and 0xF8)

type
  BlenderRgb565Pre* = object

template getColorT*(x: typedesc[BlenderRgb565Pre]): typedesc = Rgba8
template getValueT*(x: typedesc[BlenderRgb565Pre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgb565Pre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgb565Pre]): typedesc = uint16

proc BlenderRgb565Pre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgb565Pre)
  const
    baseMask = uint(getBaseMask(getColorT(BlenderRgb565Pre)))
  var
    alpha = baseMask - alpha
    rgb = p[]
    r = CalcT(rgb shr 8) and 0xF8
    g = CalcT(rgb shr 3) and 0xFC
    b = CalcT(rgb shl 3) and 0xF8
  p[] = PixelT((((r.uint * alpha + cr * cover)       ) and 0xF800) or
               (((g.uint * alpha + cg * cover) shr 5 ) and 0x07E0) or
                ((b.uint * alpha + cb * cover) shr 11))

template blendPix*(self: BlenderRgb565Pre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgb565Pre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgb565Pre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 8) or ((g and 0xFC) shl 3) or (b shr 3))

proc makeColor*[PixelT](x: typedesc[BlenderRgb565Pre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 8) and 0xF8, (p shr 3) and 0xFC, (p shl 3) and 0xF8)

type
  BlenderRgb565Gamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderRgb565Gamma[G]]): typedesc = Rgba8
template getValueT*[G](x: typedesc[BlenderRgb565Gamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderRgb565Gamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderRgb565Gamma[G]]): typedesc = uint16
template getGammaT*[G](x: typedesc[BlenderRgb565Gamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderRgb565Gamma[G], g: var G) =
  self.mGamma = g.addr

proc blendPix*[G, PixelT](self: BlenderRgb565Gamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    rgb = p[]
    r = CalcT(self.mGamma[].dir((rgb shr 8) and 0xF8))
    g = CalcT(self.mGamma[].dir((rgb shr 3) and 0xFC))
    b = CalcT(self.mGamma[].dir((rgb shl 3) and 0xF8))
  p[] = PixelT(((self.mGamma[].inv(((self.mGamma[].dir(cr).CalcT - r) * alpha.CalcT + (r shl 8)) shr 8).CalcT shl 8) and 0xF800) or
               ((self.mGamma[].inv(((self.mGamma[].dir(cg).CalcT - g) * alpha.CalcT + (g shl 8)) shr 8).CalcT shl 3) and 0x07E0) or
                (self.mGamma[].inv(((self.mGamma[].dir(cb).CalcT - b) * alpha.CalcT + (b shl 8)) shr 8).CalcT shr 3))

proc makePix*[G](x: typedesc[BlenderRgb565Gamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xF8) shl 8) or ((g and 0xFC) shl 3) or (b shr 3))

proc makeColor*[PixelT, G](x: typedesc[BlenderRgb565Gamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 8) and 0xF8, (p shr 3) and 0xFC, (p shl 3) and 0xF8)

type
  BlenderRgbAAA* = object

template getColorT*(x: typedesc[BlenderRgbAAA]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderRgbAAA]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgbAAA]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgbAAA]): typedesc = uint32

proc BlenderRgbAAA_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgbAAA)
  var
    rgb = p[]
    r = CalcT((rgb shr 14) and 0xFFC0)
    g = CalcT((rgb shr 4)  and 0xFFC0)
    b = CalcT((rgb shl 6)  and 0xFFC0)
  p[] = PixelT(((((cr - r) * alpha + (r shl 16)) shr 2)  and 0x3FF00000'u) or
               ((((cg - g) * alpha + (g shl 16)) shr 12) and 0x000FFC00'u) or
                (((cb - b) * alpha + (b shl 16)) shr 22) or 0xC0000000'u)

template blendPix*(self: BlenderRgbAAA, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgbAAA_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgbAAA], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (b shr 6) or 0xC0000000'u)

proc makeColor*[PixelT](x: typedesc[BlenderRgbAAA], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 14) and 0xFFC0, (p shr 4)  and 0xFFC0, (p shl 6)  and 0xFFC0)

type
  BlenderRgbAAAPre* = object

template getColorT*(x: typedesc[BlenderRgbAAAPre]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderRgbAAAPre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgbAAAPre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgbAAAPre]): typedesc = uint32

proc BlenderRgbAAAPre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgbAAAPre)
  const
    baseMask = getBaseMask(getColorT(BlenderRgbAAAPre))
    baseShift = getBaseShift(getColorT(BlenderRgbAAAPre))
  var
    alpha = baseMask - alpha
    cover = (cover + 1) shl (baseShift - 8)
    rgb = p[]
    r = CalcT((rgb shr 14) and 0xFFC0)
    g = CalcT((rgb shr 4)  and 0xFFC0)
    b = CalcT((rgb shl 6)  and 0xFFC0)
  p[] = PixelT((((r * alpha + cr * cover) shr 2)  and 0x3FF00000) or
               (((g * alpha + cg * cover) shr 12) and 0x000FFC00) or
                ((b * alpha + cb * cover) shr 22) or 0xC0000000)

template blendPix*(self: BlenderRgbAAAPre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgbAAAPre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgbAAAPre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (b shr 6) or 0xC0000000)

proc makeColor*[PixelT](x: typedesc[BlenderRgbAAAPre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 14) and 0xFFC0, (p shr 4)  and 0xFFC0, (p shl 6)  and 0xFFC0)

type
  BlenderRgbAAAGamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderRgbAAAGamma[G]]): typedesc = Rgba16
template getValueT*[G](x: typedesc[BlenderRgbAAAGamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderRgbAAAGamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderRgbAAAGamma[G]]): typedesc = uint32
template getGammaT*[G](x: typedesc[BlenderRgbAAAGamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderRgbAAAGamma[G], g: var G) =
  self.mGamma = g.addr

proc blendPix*[G, PixelT](self: BlenderRgbAAAGamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    rgb = p[]
    r = CalcT(self.mGamma[].dir((rgb shr 14) and 0xFFC0))
    g = CalcT(self.mGamma[].dir((rgb shr 4)  and 0xFFC0))
    b = CalcT(self.mGamma[].dir((rgb shl 6)  and 0xFFC0))
  p[] = PixelT(((self.mGamma[].inv(((self.mGamma[].dir(cr).CalcT - r) * alpha.CalcT + (r shl 16)) shr 16).CalcT shl 14) and 0x3FF00000.CalcT) or
               ((self.mGamma[].inv(((self.mGamma[].dir(cg).CalcT - g) * alpha.CalcT + (g shl 16)) shr 16).CalcT shl 4 ) and 0x000FFC00.CalcT) or
                (self.mGamma[].inv(((self.mGamma[].dir(cb).CalcT - b) * alpha.CalcT + (b shl 16)) shr 16).CalcT shr 6 ) or 0xC0000000.CalcT)

proc makePix*[G](x: typedesc[BlenderRgbAAAGamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (b shr 6) or 0xC0000000'u)

proc makeColor*[G,PixelT](x: typedesc[BlenderRgbAAAGamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 14) and 0xFFC0, (p shr 4)  and 0xFFC0, (p shl 6)  and 0xFFC0)

type
  BlenderBgrAAA* = object

template getColorT*(x: typedesc[BlenderBgrAAA]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderBgrAAA]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderBgrAAA]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderBgrAAA]): typedesc = uint32

proc BlenderBgrAAA_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderBgrAAA)
  var
    bgr = p[]
    b = CalcT((bgr shr 14) and 0xFFC0)
    g = CalcT((bgr shr 4)  and 0xFFC0)
    r = CalcT((bgr shl 6)  and 0xFFC0)
  p[] = PixelT(((((cb - b) * alpha + (b shl 16)) shr 2)  and 0x3FF00000'u) or
               ((((cg - g) * alpha + (g shl 16)) shr 12) and 0x000FFC00'u) or
                (((cr - r) * alpha + (r shl 16)) shr 22) or 0xC0000000'u)

template blendPix*(self: BlenderBgrAAA, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderBgrAAA_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderBgrAAA], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (r shr 6) or 0xC0000000'u)

proc makeColor*[PixelT](x: typedesc[BlenderBgrAAA], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 6)  and 0xFFC0, (p shr 4)  and 0xFFC0, (p shr 14) and 0xFFC0)

type
  BlenderBgrAAAPre* = object

template getColorT*(x: typedesc[BlenderBgrAAAPre]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderBgrAAAPre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderBgrAAAPre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderBgrAAAPre]): typedesc = uint32

proc BlenderBgrAAAPre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderBgrAAAPre)
  const
    baseMask = getBaseMask(getColorT(BlenderBgrAAAPre))
    baseShift = getBaseShift(getColorT(BlenderBgrAAAPre))
  var
    alpha = baseMask - alpha
    cover = (cover + 1) shl (baseShift - 8)
    bgr = p[]
    b = CalcT((bgr shr 14) and 0xFFC0)
    g = CalcT((bgr shr 4)  and 0xFFC0)
    r = CalcT((bgr shl 6)  and 0xFFC0)
  p[] = PixelT((((b * alpha + cb * cover) shr 2)  and 0x3FF00000) or
               (((g * alpha + cg * cover) shr 12) and 0x000FFC00) or
                ((r * alpha + cr * cover) shr 22) or 0xC0000000)

template blendPix*(self: BlenderBgrAAAPre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderBgrAAAPre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderBgrAAAPre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (r shr 6) or 0xC0000000)

proc makeColor*[PixelT](x: typedesc[BlenderBgrAAAPre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 6)  and 0xFFC0, (p shr 4)  and 0xFFC0, (p shr 14) and 0xFFC0)

type
  BlenderBgrAAAGamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderBgrAAAGamma[G]]): typedesc = Rgba16
template getValueT*[G](x: typedesc[BlenderBgrAAAGamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderBgrAAAGamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderBgrAAAGamma[G]]): typedesc = uint32
template getGammaT*[G](x: typedesc[BlenderBgrAAAGamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderBgrAAAGamma[G], g: var G) = self.mGamma = g.addr

proc blendPix*[G, PixelT](self: BlenderBgrAAAGamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    bgr = p[]
    b = CalcT(self.mGamma[].dir((bgr shr 14) and 0xFFC0))
    g = CalcT(self.mGamma[].dir((bgr shr 4)  and 0xFFC0))
    r = CalcT(self.mGamma[].dir((bgr shl 6)  and 0xFFC0))
  p[] = PixelT(((self.mGamma[].inv(((self.mGamma[].dir(cb).CalcT - b) * alpha.CalcT + (b shl 16)) shr 16).CalcT shl 14) and 0x3FF00000.CalcT) or
               ((self.mGamma[].inv(((self.mGamma[].dir(cg).CalcT - g) * alpha.CalcT + (g shl 16)) shr 16).CalcT shl 4 ) and 0x000FFC00.CalcT) or
                (self.mGamma[].inv(((self.mGamma[].dir(cr).CalcT - r) * alpha.CalcT + (r shl 16)) shr 16).CalcT shr 6 )  or 0xC0000000.CalcT)

proc makePix*[G](x: typedesc[BlenderBgrAAAGamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 14) or ((g and 0xFFC0) shl 4) or (r shr 6) or 0xC0000000'u)

proc makeColor*[G, PixelT](x: typedesc[BlenderBgrAAAGamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 6)  and 0xFFC0, (p shr 4)  and 0xFFC0, (p shr 14) and 0xFFC0)

type
  BlenderRgbBBA* = object

template getColorT*(x: typedesc[BlenderRgbBBA]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderRgbBBA]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgbBBA]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgbBBA]): typedesc = uint32

proc BlenderRgbBBA_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgbBBA)
  var
    rgb = p[]
    r = CalcT((rgb shr 16) and 0xFFE0)
    g = CalcT((rgb shr 5)  and 0xFFE0)
    b = CalcT((rgb shl 6)  and 0xFFC0)
  p[] = PixelT(((((cr - r) * alpha + (r shl 16))       ) and 0xFFE00000'u) or
               ((((cg - g) * alpha + (g shl 16)) shr 11) and 0x001FFC00'u) or
                (((cb - b) * alpha + (b shl 16)) shr 22))

template blendPix*(self: BlenderRgbBBA, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgbBBA_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgbBBA], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFE0) shl 16) or ((g and 0xFFE0) shl 5) or (b shr 6))

proc makeColor*[PixelT](x: typedesc[BlenderRgbBBA], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 16) and 0xFFE0, (p shr 5)  and 0xFFE0, (p shl 6)  and 0xFFC0)

type
  BlenderRgbBBAPre* = object

template getColorT*(x: typedesc[BlenderRgbBBAPre]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderRgbBBAPre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderRgbBBAPre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderRgbBBAPre]): typedesc = uint32

proc BlenderRgbBBAPre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderRgbBBAPre)
  const
    baseShift = getBaseShift(getColorT(BlenderRgbBBAPre))
    baseMask = getBaseMask(getColorT(BlenderRgbBBAPre))
  var
    alpha = baseMask - alpha
    cover = (cover + 1) shl (baseShift - 8)
    rgb = p[]
    r = CalcT((rgb shr 16) and 0xFFE0)
    g = CalcT((rgb shr 5)  and 0xFFE0)
    b = CalcT((rgb shl 6)  and 0xFFC0)
  p[] = PixelT((((r * alpha + cr * cover)      ) and 0xFFE00000) or
               (((g * alpha + cg * cover) shr 11) and 0x001FFC00) or
                ((b * alpha + cb * cover) shr 22))

template blendPix*(self: BlenderRgbBBAPre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderRgbBBAPre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderRgbBBAPre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFE0) shl 16) or ((g and 0xFFE0) shl 5) or (b shr 6))

proc makeColor*[PixelT](x: typedesc[BlenderRgbBBAPre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 16) and 0xFFE0, (p shr 5)  and 0xFFE0, (p shl 6)  and 0xFFC0)

type
  BlenderRgbBBAGamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderRgbBBAGamma[G]]): typedesc = Rgba16
template getValueT*[G](x: typedesc[BlenderRgbBBAGamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderRgbBBAGamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderRgbBBAGamma[G]]): typedesc = uint32
template getGammaT*[G](x: typedesc[BlenderRgbBBAGamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderRgbBBAGamma[G], g: var G) = self.mGamma = g.addr

proc blendPix*[G, PixelT](self: BlenderRgbBBAGamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    rgb = p[]
    r = CalcT(self.mGamma[].dir((rgb shr 16) and 0xFFE0))
    g = CalcT(self.mGamma[].dir((rgb shr 5)  and 0xFFE0))
    b = CalcT(self.mGamma[].dir((rgb shl 6)  and 0xFFC0))
  p[] = PixelT(((self.mGamma[].inv(((self.mGamma[].dir(cr).CalcT - r) * alpha.CalcT + (r shl 16)) shr 16).CalcT shl 16) and 0xFFE00000.CalcT) or
               ((self.mGamma[].inv(((self.mGamma[].dir(cg).CalcT - g) * alpha.CalcT + (g shl 16)) shr 16).CalcT shl 5 ) and 0x001FFC00.CalcT) or
                (self.mGamma[].inv(((self.mGamma[].dir(cb).CalcT - b) * alpha.CalcT + (b shl 16)) shr 16).CalcT shr 6 ))

proc makePix*[G](x: typedesc[BlenderRgbBBAGamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((r and 0xFFE0) shl 16) or ((g and 0xFFE0) shl 5) or (b shr 6))

proc makeColor*[G,PixelT](x: typedesc[BlenderRgbBBAGamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shr 16) and 0xFFE0, (p shr 5)  and 0xFFE0, (p shl 6)  and 0xFFC0)

type
  BlenderBgrABB* = object

template getColorT*(x: typedesc[BlenderBgrABB]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderBgrABB]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderBgrABB]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderBgrABB]): typedesc = uint32

proc BlenderBgrABB_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderBgrABB)
  var
    bgr = p[]
    b = CalcT((bgr shr 16) and 0xFFC0)
    g = CalcT((bgr shr 6)  and 0xFFE0)
    r = CalcT((bgr shl 5)  and 0xFFE0)
  p[] = PixelT(((((cb - b) * alpha + (b shl 16))      ) and 0xFFC00000'u) or
               ((((cg - g) * alpha + (g shl 16)) shr 10) and 0x003FF800'u) or
                (((cr - r) * alpha + (r shl 16)) shr 21))

template blendPix*(self: BlenderBgrABB, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderBgrABB_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderBgrABB], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 16) or ((g and 0xFFE0) shl 6) or (r shr 5))

proc makeColor*[PixelT](x: typedesc[BlenderBgrABB], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 5)  and 0xFFE0, (p shr 6)  and 0xFFE0, (p shr 16) and 0xFFC0)

type
  BlenderBgrABBPre* = object

template getColorT*(x: typedesc[BlenderBgrABBPre]): typedesc = Rgba16
template getValueT*(x: typedesc[BlenderBgrABBPre]): typedesc = getValueT(getColorT(x))
template getCalcT* (x: typedesc[BlenderBgrABBPre]): typedesc = getCalcT(getColorT(x))
template getPixelT*(x: typedesc[BlenderBgrABBPre]): typedesc = uint32

proc BlenderBgrABBPre_blendPix*[PixelT](p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(BlenderBgrABBPre)
  const
    baseMask = getBaseMask(getColorT(BlenderBgrABBPre))
    baseShift = getBaseShift(getColorT(BlenderBgrABBPre))
  var
    alpha = baseMask - alpha
    cover = (cover + 1) shl (baseShift - 8)
    bgr = p[]
    b = CalcT((bgr shr 16) and 0xFFC0)
    g = CalcT((bgr shr 6)  and 0xFFE0)
    r = CalcT((bgr shl 5)  and 0xFFE0)
  p[] = PixelT((((b * alpha + cb * cover)       ) and 0xFFC00000) or
               (((g * alpha + cg * cover) shr 10) and 0x003FF800) or
                ((r * alpha + cr * cover) shr 21))

template blendPix*(self: BlenderBgrABBPre, p, cr, cg, cb, alpha, cover: typed): untyped =
  BlenderBgrABBPre_blendPix[getPixelT(self.type)](p, cr, cg, cb, alpha, cover)

proc makePix*(x: typedesc[BlenderBgrABBPre], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 16) or ((g and 0xFFE0) shl 6) or (r shr 5))

proc makeColor*[PixelT](x: typedesc[BlenderBgrABBPre], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 5)  and 0xFFE0, (p shr 6)  and 0xFFE0, (p shr 16) and 0xFFC0)

type
  BlenderBgrABBGamma*[Gamma] = object
    mGamma: ptr Gamma

template getColorT*[G](x: typedesc[BlenderBgrABBGamma[G]]): typedesc = Rgba16
template getValueT*[G](x: typedesc[BlenderBgrABBGamma[G]]): typedesc = getValueT(getColorT(x))
template getCalcT* [G](x: typedesc[BlenderBgrABBGamma[G]]): typedesc = getCalcT(getColorT(x))
template getPixelT*[G](x: typedesc[BlenderBgrABBGamma[G]]): typedesc = uint32
template getGammaT*[G](x: typedesc[BlenderBgrABBGamma[G]]): typedesc = G

proc gamma*[G](self: var BlenderBgrABBGamma[G], g: var G) = self.mGamma = g.addr

proc blendPix*[G,PixelT](self: BlenderBgrABBGamma[G], p: ptr PixelT, cr, cg, cb, alpha, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(self.type)
  var
    bgr = p[]
    b = CalcT(self.mGamma[].dir((bgr shr 16) and 0xFFC0))
    g = CalcT(self.mGamma[].dir((bgr shr 6)  and 0xFFE0))
    r = CalcT(self.mGamma[].dir((bgr shl 5)  and 0xFFE0))
  p[] = PixelT(((CalcT(self.mGamma[].inv(((CalcT(self.mGamma[].dir(cb)) - b) * CalcT(alpha) + (b shl 16)) shr 16)) shl 16) and CalcT(0xFFC00000)) or
               ((CalcT(self.mGamma[].inv(((CalcT(self.mGamma[].dir(cg)) - g) * CalcT(alpha) + (g shl 16)) shr 16)) shl 6 ) and CalcT(0x003FF800)) or
                (CalcT(self.mGamma[].inv(((CalcT(self.mGamma[].dir(cr)) - r) * CalcT(alpha) + (r shl 16)) shr 16)) shr 5 ))

proc makePix*[G](x: typedesc[BlenderBgrABBGamma[G]], r, g, b: uint): auto {.inline.} =
  type PixelT = getPixelT(x)
  result = PixelT(((b and 0xFFC0) shl 16) or ((g and 0xFFE0) shl 6) or (r shr 5))

proc makeColor*[G,PixelT](x: typedesc[BlenderBgrABBGamma[G]], p: PixelT): auto {.inline.} =
  result = construct(getColorT(x), (p shl 5)  and 0xFFE0, (p shr 6)  and 0xFFE0, (p shr 16) and 0xFFC0)

type
  PixfmtAlphaBlendRgbPacked*[Blender, RenBuf] = object
    mRbuf: ptr RenBuf
    mBlender: Blender

template getOrderT  *[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]]): typedesc = int # a fake one
template getColorT  *[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]]): typedesc = getColorT(B.type)
template getValueT  *[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]]): typedesc = getValueT(B.type)
template getPixWidth*[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]]): int = sizeof(getPixelT(B.type))
template getPixElem *[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]]): int = 2

proc copyOrBlendPix*[Blender, RenBuf, PixelT, ColorT](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  p: ptr PixelT, c: ColorT, cover: uint) {.inline.} =
  type
    CalcT = getCalcT(Blender)
  const
    baseMask = getBaseMask(ColorT)
  if c.a == 0: return
  var alpha = (CalcT(c.a) * (cover.CalcT + 1)) shr 8
  if alpha == baseMask:
    p[] = makePix(Blender, c.r, c.g, c.b)
  else:
    self.mBlender.blendPix(p, c.r, c.g, c.b, alpha, cover)

proc initPixfmtAlphaBlendRgbPacked*[Blender, RenBuf](rb: var RenBuf): PixfmtAlphaBlendRgbPacked[Blender, RenBuf] =
  result.mRbuf = rb.addr

template construct*[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]], rbuf: typed): untyped =
  initPixfmtAlphaBlendRgbPacked[B,R](rbuf)

proc init*[Blender, RenBuf](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf], rb: var RenBuf) =
  self.mRbuf = rb.addr

proc attach*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf], rb: var RenBuf) =
  self.mRbuf = rb.addr

proc attach*[PixFmt, Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  pixf: PixFmt, x1, y1, x2, y2: int): bool =
  var r = initRectI(x1, y1, x2, y2)
  if r.clip(initRectI(0, 0, pixf.width()-1, pixf.height()-1)):
    let  stride = pixf.stride()
    self.mRbuf[].attach(pixf.pixPtr(r.x1, if stride < 0: r.y2 else: r.y1),
       (r.x2 - r.x1) + 1, (r.y2 - r.y1) + 1, stride)
    return true
  result = false

proc blender*[Blender, RenBuf](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf]): var Blender {.inline.} =
  self.mBlender

proc width*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].width()

proc height*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].height()

proc stride*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf]): int {.inline.} =
  self.mRbuf[].stride()

proc rowPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf], y: int): ptr uint8 {.inline.} =
  self.mRbuf[].rowPtr(y)

proc row*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf], y: int): auto {.inline.} =
  self.mRbuf[].row(y)

proc pixPtr*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf], x, y: int): auto {.inline.} =
  const pixElem = getPixElem(self.type)
  return self.mRbuf[].rowPtr(y) + x * pixElem

proc makePix*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  p: ptr uint8, c: ColorT) {.inline.} =
  type PixelT = getPixelT(Blender)
  cast[ptr PixelT](p)[] = Blender.makePix(c.r, c.g, c.b)

proc pixel*[Blender, RenBuf](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf], x, y: int): auto {.inline.} =
  type PixelT = getPixelT(Blender)
  makeColor(Blender, cast[ptr PixelT](self.mRbuf[].rowPtr(y))[x])

proc copyPixel*[Blender, RenBuf, ColorT](self: PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y: int, c: ColorT) {.inline.} =
  type PixelT = getPixelT(Blender)
  cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1))[x] = Blender.makePix(c.r, c.g, c.b)

proc blendPixel*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y: int, c: ColorT, cover: uint8) =
  type PixelT = getPixelT(Blender)
  self.copyOrBlendPix(cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x, c, cover)

proc copyHline*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT) {.inline.} =
  type PixelT = getPixelT(Blender)
  var
    p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, len)) + x
    v = makePix(Blender, c.r, c.g, c.b)
    len = len
  doWhile len != 0:
    p[] = v
    inc p
    dec len

proc copyVline*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT) {.inline.} =
  type PixelT = getPixelT(Blender)
  var
    v = makePix(Blender, c.r, c.g, c.b)
    len = len
    y = y
  doWhile len != 0:
    var p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x
    inc y
    p[] = v
    dec len

proc blendHline*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =
  type
    CalcT = getCalcT(Blender)
    PixelT = getPixelT(Blender)
  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return
  var
    p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, len)) + x
    alpha = (CalcT(c.a) * (cover.CalcT + 1)) shr 8
    len = len
  if alpha == baseMask:
    var v = makePix(Blender, c.r, c.g, c.b)
    doWhile len != 0:
      p[] = v
      inc p
      dec len
  else:
    doWhile len != 0:
      self.mBlender.blendPix(p, c.r, c.g, c.b, alpha, cover)
      inc p
      dec len

proc blendVline*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT, cover: uint8) =
  type
    PixelT = getPixelT(Blender)
    CalcT = getCalcT(Blender)
  const baseMask = getBaseMask(ColorT)
  if c.a == 0: return
  var
    alpha = (CalcT(c.a) * (cover.CalcT + 1)) shr 8
    len = len
    y = y
  if alpha == baseMask:
    var v = makePix(Blender, c.r, c.g, c.b)
    doWhile len != 0:
      cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1))[x] = v
      inc y
      dec len
  else:
    doWhile len != 0:
      self.mBlender.blendPix(cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x, c.r, c.g, c.b, alpha, cover)
      inc y
      dec len

proc blendSolidHspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type PixelT = getPixelT(Blender)
  var
    p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, len)) + x
    len = len
    covers = covers
  doWhile len != 0:
    self.copyOrBlendPix(p, c, covers[])
    inc covers
    inc p
    dec len

proc blendSolidVspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, c: ColorT, covers: ptr uint8) =
  type PixelT = getPixelT(Blender)
  var
    len = len
    y = y
    covers = covers
  doWhile len != 0:
    self.copyOrBlendPix(cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x, c, covers[])
    inc y
    inc covers
    dec len

proc copyColorHspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT) =
  type PixelT = getPixelT(Blender)
  var
    p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, len)) + x
    len = len
    colors = colors
  doWhile len != 0:
    p[] = makePix(Blender, colors.r, colors.g, colors.b)
    inc p
    inc colors
    dec len

proc copyColorVspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT) =
  type PixelT = getPixelT(Blender)
  var
    len = len
    colors = colors
    y = y
  doWhile len != 0:
    var p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x
    inc y
    p[] = makePix(Blender, colors.r, colors.g, colors.b)
    inc colors
    dec len

proc blendColorHspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type PixelT = getPixelT(Blender)
  var
    p = cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, len)) + x
    len = len
    colors = colors
    covers = covers
  doWhile len != 0:
    if covers != nil:
      self.copyOrBlendPix(p, colors[], covers[])
      inc covers
    else:
      self.copyOrBlendPix(p, colors[], cover)
    inc p
    inc colors
    dec len

proc blendColorVspan*[Blender, RenBuf, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  x, y, len: int, colors: ptr ColorT, covers: ptr uint8, cover: uint8) =
  type PixelT = getPixelT(Blender)
  var
    len = len
    y = y
    colors = colors
    covers = covers
  doWhile len != 0:
    if covers != nil:
      self.copyOrBlendPix(cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x, colors[], covers[])
      inc covers
    else:
      self.copyOrBlendPix(cast[ptr PixelT](self.mRbuf[].rowPtr(x, y, 1)) + x, colors[], cover)
    inc colors
    inc y
    dec len

proc copyFrom*[Blender, RenBuf, RenBuf2](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  src: RenBuf, xdst, ydst, xsrc, ysrc, len: int) =
  const
    pixWidth = getPixWidth(self.type)
    pixElem  = getPixElem(self.type)
  var p = src.rowPtr(ysrc)
  if p != nil:
    moveMem(self.mRbuf[].rowPtr(xdst, ydst, len) + xdst * pixElem,
            p + xsrc * pixElem, len * pixWidth)

proc blendFrom*[Blender, RenBuf, SrcPixelFormatRenderer](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  src: SrcPixelFormatRenderer, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcOrder = getOrderT(SrcPixelFormatRenderer)
    ValueT = getValueT(getColorT(self.type))
    PixelT = getPixelT(Blender)

  var
    psrc = cast[ptr ValueT](src.rowPtr(ysrc))

  if psrc != nil:
    psrc += xsrc * 4
    var pdst = cast[ptr PixelT](self.mRbuf[].rowPtr(xdst, ydst, len)) + xdst
    doWhile len != 0:
      var alpha = psrc[SrcOrder.A]
      if alpha != 0:
        if alpha == baseMask and cover == 255:
          pdst[] = makePix(Blender, psrc[SrcOrder.R], psrc[SrcOrder.G], psrc[SrcOrder.B])
        else:
          self.mBlender.blendPix(pdst, psrc[SrcOrder.R], psrc[SrcOrder.G],
                                    psrc[SrcOrder.B], alpha, cover)
      psrc += 4
      inc pdst
      dec len

proc blendFromColor*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  src: SrcPixelFormatRenderer, color: ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    PixelT = getPixelT(Blender)

  var psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))
  if psrc != nil:
    var pdst = cast[ptr PixelT](self.mRbuf[].rowPtr(xdst, ydst, len)) + xdst
    doWhile len != 0:
      self.mBlender.blendPix(pdst, color.r, color.g, color.b, color.a, cover)
      inc psrc
      inc pdst
      dec len

proc blendFromLut*[Blender, RenBuf, SrcPixelFormatRenderer, ColorT](self: var PixfmtAlphaBlendRgbPacked[Blender, RenBuf],
  src: SrcPixelFormatRenderer, colorLut: ptr ColorT, xdst, ydst, xsrc, ysrc, len: int, cover: uint8) =

  type
    SrcValueT = getValueT(SrcPixelFormatRenderer)
    PixelT = getPixelT(Blender)

  var psrc = cast[ptr SrcValueT](src.rowPtr(ysrc))
  if psrc != nil:
    var pdst = cast[ptr PixelT](self.mRbuf[].rowPtr(xdst, ydst, len)) + xdst
    doWhile len != 0:
      var color = colorLut[psrc[]]
      self.mBlender.blendPix(pdst, color.r, color.g, color.b, color.a, cover)
      inc psrc
      inc pdst
      dec len

type
  PixFmtRgb555* = PixfmtAlphaBlendRgbPacked[BlenderRgb555, RenderingBuffer]
  PixFmtRgb565* = PixfmtAlphaBlendRgbPacked[BlenderRgb565, RenderingBuffer]

  PixFmtRgb555Pre* = PixfmtAlphaBlendRgbPacked[BlenderRgb555Pre, RenderingBuffer]
  PixFmtRgb565Pre* = PixfmtAlphaBlendRgbPacked[BlenderRgb565Pre, RenderingBuffer]

  PixFmtRgbAAA* = PixfmtAlphaBlendRgbPacked[BlenderRgbAAA, RenderingBuffer16]
  PixFmtBgrAAA* = PixfmtAlphaBlendRgbPacked[BlenderBgrAAA, RenderingBuffer16]
  PixFmtRgbBBA* = PixfmtAlphaBlendRgbPacked[BlenderRgbBBA, RenderingBuffer16]
  PixFmtBgrABB* = PixfmtAlphaBlendRgbPacked[BlenderBgrABB, RenderingBuffer16]

  PixFmtRgbAAAPre* = PixfmtAlphaBlendRgbPacked[BlenderRgbAAAPre, RenderingBuffer16]
  PixFmtBgrAAAPre* = PixfmtAlphaBlendRgbPacked[BlenderBgrAAAPre, RenderingBuffer16]
  PixFmtRgbBBAPre* = PixfmtAlphaBlendRgbPacked[BlenderRgbBBAPre, RenderingBuffer16]
  PixFmtBgrABBPre* = PixfmtAlphaBlendRgbPacked[BlenderBgrABBPre, RenderingBuffer16]

type
  PixFmtRgb555Gamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderRgb555Gamma[Gamma], RenderingBuffer]
  PixFmtRgb565Gamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderRgb565Gamma[Gamma], RenderingBuffer]
  PixFmtRgbAAAGamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderRgbAAAGamma[Gamma], RenderingBuffer16]
  PixFmtBgrAAAGamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderBgrAAAGamma[Gamma], RenderingBuffer16]
  PixFmtRgbBBAGamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderRgbBBAGamma[Gamma], RenderingBuffer16]
  PixFmtBgrABBGamma*[Gamma] = PixfmtAlphaBlendRgbPacked[BlenderBgrABBGamma[Gamma], RenderingBuffer16]

proc initPixFmtRgb555Gamma*[Gamma](rbuf: var RenderingBuffer, gamma: var Gamma): PixFmtRgb555Gamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixFmtRgb565Gamma*[Gamma](rbuf: var RenderingBuffer, gamma: var Gamma): PixFmtRgb565Gamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixFmtRgbAAAGamma*[Gamma](rbuf: var RenderingBuffer16, gamma: var Gamma): PixFmtRgbAAAGamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixFmtBgrAAAGamma*[Gamma](rbuf: var RenderingBuffer16, gamma: var Gamma): PixFmtBgrAAAGamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixFmtRgbBBAGamma*[Gamma](rbuf: var RenderingBuffer16, gamma: var Gamma): PixFmtRgbBBAGamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixFmtBgrABBGamma*[Gamma](rbuf: var RenderingBuffer16, gamma: var Gamma): PixFmtBgrABBGamma[Gamma] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

proc initPixfmtAlphaBlendRgbPacked*[B,R,G](rbuf: var R, gamma: var G): PixfmtAlphaBlendRgbPacked[B,R] =
  result.mRbuf = rbuf.addr
  result.blender().gamma(gamma)

template construct*[B,R](x: typedesc[PixfmtAlphaBlendRgbPacked[B,R]], rbuf, gamma: typed): untyped =
  initPixfmtAlphaBlendRgbPacked[B,R,gamma.type](rbuf, gamma)
