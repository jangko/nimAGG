import agg_basics

type
  PixfmtTransposer*[PixFmt] = object
    mPixf: ptr PixFmt

proc initPixfmtTransposer*[PixFmt](): PixfmtTransposer[PixFmt] =
  result.mPixf = nil

proc initPixfmtTransposer*[PixFmt](pixf: var PixFmt): PixfmtTransposer[PixFmt] =
  result.mPixf = pixf.addr

proc attach*[PixFmt](self: var PixfmtTransposer[PixFmt], pixf: var PixFmt) =
  self.mPixf = pixf.addr

proc width*[PixFmt](self: PixfmtTransposer[PixFmt]): int {.inline.} = self.mPixf[].height()

proc height*[PixFmt](self: PixfmtTransposer[PixFmt]): int {.inline.} = self.mPixf[].width()

proc pixel*[PixFmt](self: var PixfmtTransposer[PixFmt], x, y: int): auto {.inline.} =
  self.mPixf[].pixel(y, x)

proc copyPixel*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y: int, c: ColorT) {.inline.} =
  self.mPixf[].copyPixel(y, x, c)

proc blendPixel*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y: int, c: ColorT, cover: uint8) {.inline.} =
  self.mPixf[].blendPixel(y, x, c, cover)

proc copyHline*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT) {.inline.} =
  self.mPixf[].copyVline(y, x, len, c)

proc copyVline*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT) {.inline.} =
  self.mPixf[].copyHline(y, x, len, c)

proc blendHline*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT, cover: uint8) {.inline.} =
  self.mPixf[].blendVline(y, x, len, c, cover)

proc blendVline*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT, cover: uint8) {.inline.} =
  self.mPixf[].blendHline(y, x, len, c, cover)

proc blendSolidHspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT, covers: ptr uint8) {.inline.} =
  self.mPixf[].blendSolidVspan(y, x, len, c, covers)

proc blendSolidVspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, c: ColorT, covers: ptr uint8) {.inline.} =
  self.mPixf[].blendSolidHspan(y, x, len, c, covers)

proc copyColorHspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, colors: ptr ColorT) {.inline.} =
  self.mPixf[].copyColorHspan(y, x, len, colors)

proc copyColorVspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int, colors: ptr ColorT) {.inline.} =
  self.mPixf[].copyColorVspan(y, x, len, colors)

proc blendColorHspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int,
  colors: ptr ColorT, covers: ptr uint8, cover: uint8) {.inline.} =
  self.mPixf[].blendColorVspan(y, x, len, colors, covers, cover)

proc blendColorVspan*[PixFmt,ColorT](self: var PixfmtTransposer[PixFmt], x, y, len: int,
  colors: ptr ColorT, covers: ptr uint8, cover: uint8) {.inline.} =
  self.mPixf[].blendColorHspan(y, x, len, colors, covers, cover)
