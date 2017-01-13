import agg_rendering_buffer, agg_basics, agg_pixfmt_rgb, agg_color_rgba, agg_gamma_lut
import agg_color_gray, agg_pixfmt_gray

{.passC: "-I./agg-2.5/include".}
{.compile: "test_pixfmt.cpp".}
{.passL: "-lstdc++".}

type
  agg_rbuf = distinct pointer
  agg_pixfmt_rgb24 = distinct pointer
  agg_pixfmt_rgb48 = distinct pointer
  agg_pixfmt_gray8 = distinct pointer
  agg_pixfmt_gray16 = distinct pointer
  GammaLUT8 = distinct pointer
  GammaLUT16 = distinct pointer

proc create_rbuf(buffer: cstring, frameWidth, frameHeight, stride: cint): agg_rbuf {.importc.}
proc create_pixf_rgb24(rbuf: agg_rbuf): agg_pixfmt_rgb24 {.importc.}
proc blend_pixel(pixf: agg_pixfmt_rgb24, x, y: cint, c: var Rgba8, cover: uint8) {.importc: "pixf_rgb24_blend_pixel".}
proc blend_color_hspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc: "pixf_rgb24_blend_color_hspan".}
proc blend_color_vspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc: "pixf_rgb24_blend_color_vspan".}
proc blend_hline(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc: "pixf_rgb24_blend_hline".}
proc blend_vline(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc: "pixf_rgb24_blend_vline".}
proc blend_solid_hspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc: "pixf_rgb24_blend_solid_hspan".}
proc blend_solid_vspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc: "pixf_rgb24_blend_solid_vspan".}
proc apply_gamma_inv(pixf: agg_pixfmt_rgb24, g: GammaLUT8) {.importc: "pixf_rgb24_apply_gamma_inv".}
proc apply_gamma_dir(pixf: agg_pixfmt_rgb24, g: GammaLUT8) {.importc: "pixf_rgb24_apply_gamma_dir".}

proc create_pixf_rgb48(rbuf: agg_rbuf): agg_pixfmt_rgb48 {.importc.}
proc blend_pixel(pixf: agg_pixfmt_rgb48, x, y: cint, c: var Rgba16, cover: uint8) {.importc: "pixf_rgb48_blend_pixel".}
proc blend_color_hspan(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) {.importc: "pixf_rgb48_blend_color_hspan".}
proc blend_color_vspan(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, colors: ptr Rgba16, covers: ptr uint8, cover: uint8) {.importc: "pixf_rgb48_blend_color_vspan".}
proc blend_hline(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, c: var Rgba16, cover: uint8) {.importc: "pixf_rgb48_blend_hline".}
proc blend_vline(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, c: var Rgba16, cover: uint8) {.importc: "pixf_rgb48_blend_vline".}
proc blend_solid_hspan(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, c: var Rgba16, covers: ptr uint8) {.importc: "pixf_rgb48_blend_solid_hspan".}
proc blend_solid_vspan(pixf: agg_pixfmt_rgb48, x, y: cint, len: cuint, c: var Rgba16, covers: ptr uint8) {.importc: "pixf_rgb48_blend_solid_vspan".}
proc apply_gamma_inv(pixf: agg_pixfmt_rgb48, g: GammaLUT16) {.importc: "pixf_rgb48_apply_gamma_inv".}
proc apply_gamma_dir(pixf: agg_pixfmt_rgb48, g: GammaLUT16) {.importc: "pixf_rgb48_apply_gamma_dir".}

proc create_pixf_gray8(rbuf: agg_rbuf): agg_pixfmt_gray8 {.importc.}
proc blend_pixel(pixf: agg_pixfmt_gray8, x, y: cint, c: var Gray8, cover: uint8) {.importc: "pixf_gray8_blend_pixel".}
proc blend_color_hspan(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, colors: ptr Gray8, covers: ptr uint8, cover: uint8) {.importc: "pixf_gray8_blend_color_hspan".}
proc blend_color_vspan(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, colors: ptr Gray8, covers: ptr uint8, cover: uint8) {.importc: "pixf_gray8_blend_color_vspan".}
proc blend_hline(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, c: var Gray8, cover: uint8) {.importc: "pixf_gray8_blend_hline".}
proc blend_vline(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, c: var Gray8, cover: uint8) {.importc: "pixf_gray8_blend_vline".}
proc blend_solid_hspan(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, c: var Gray8, covers: ptr uint8) {.importc: "pixf_gray8_blend_solid_hspan".}
proc blend_solid_vspan(pixf: agg_pixfmt_gray8, x, y: cint, len: cuint, c: var Gray8, covers: ptr uint8) {.importc: "pixf_gray8_blend_solid_vspan".}
proc apply_gamma_inv(pixf: agg_pixfmt_gray8, g: GammaLUT8) {.importc: "pixf_gray8_apply_gamma_inv".}
proc apply_gamma_dir(pixf: agg_pixfmt_gray8, g: GammaLUT8) {.importc: "pixf_gray8_apply_gamma_dir".}

proc create_pixf_gray16(rbuf: agg_rbuf): agg_pixfmt_gray16 {.importc.}
proc blend_pixel(pixf: agg_pixfmt_gray16, x, y: cint, c: var Gray16, cover: uint8) {.importc: "pixf_gray16_blend_pixel".}
proc blend_color_hspan(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, colors: ptr Gray16, covers: ptr uint8, cover: uint8) {.importc: "pixf_gray16_blend_color_hspan".}
proc blend_color_vspan(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, colors: ptr Gray16, covers: ptr uint8, cover: uint8) {.importc: "pixf_gray16_blend_color_vspan".}
proc blend_hline(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, c: var Gray16, cover: uint8) {.importc: "pixf_gray16_blend_hline".}
proc blend_vline(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, c: var Gray16, cover: uint8) {.importc: "pixf_gray16_blend_vline".}
proc blend_solid_hspan(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, c: var Gray16, covers: ptr uint8) {.importc: "pixf_gray16_blend_solid_hspan".}
proc blend_solid_vspan(pixf: agg_pixfmt_gray16, x, y: cint, len: cuint, c: var Gray16, covers: ptr uint8) {.importc: "pixf_gray16_blend_solid_vspan".}
proc apply_gamma_inv(pixf: agg_pixfmt_gray16, g: GammaLUT16) {.importc: "pixf_gray16_apply_gamma_inv".}
proc apply_gamma_dir(pixf: agg_pixfmt_gray16, g: GammaLUT16) {.importc: "pixf_gray16_apply_gamma_dir".}

proc create_gamma_lut8(): GammaLUT8 {.importc.}
#proc create_gamma_lut8_a(a: cdouble): GammaLUT8 {.importc.}
proc create_gamma_lut16(): GammaLUT16 {.importc.}
#proc create_gamma_lut16_a(a: cdouble): GammaLUT16 {.importc.}

const
  frameWidth = 255
  frameHeight = frameWidth

template genTest(name, PixFmt, ColorT, cname, nbit, RenBuf: untyped) =
  proc `test name`() =
    type
      OrderType = getOrderType(PixFmt)
      ValueType = getValueType(ColorT)
    const
      pixWidth = sizeof(ValueType) * 3
      baseMask = getBaseMask(ColorT)

    var buffer = newString(frameWidth * frameHeight * pixWidth)
    for i in 0.. <buffer.len: buffer[i] = 0.chr
    var rbuf = RenBuf(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    var pixf = `init PixFmt`(rbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        pixf.copyPixel(x, y, `init ColorT`((x and baseMask).uint, (y and baseMask).uint, (x and baseMask).uint, baseMask.uint))

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let a = `init ColorT`((x and baseMask).uint, (y and baseMask).uint, (x and baseMask).uint, baseMask.uint)
        let b = pixf.pixel(x, y)
        doAssert(a == b)

    var color = `init ColorT`(1,2,3)
    var p = cast[ptr ValueType](buffer[0].addr)
    makePix(PixFmt, p, color)
    doAssert(p[OrderType.R.ord] == color.r)
    doAssert(p[OrderType.G.ord] == color.g)
    doAssert(p[OrderType.B.ord] == color.b)

    pixf.copyHLine(0, 0, frameWidth, color)
    pixf.copyVLine(0, 0, frameHeight, color)

    var
      start = cast[ptr ValueType](buffer[0].addr)
      span: array[frameWidth, ColorT]
      covers: array[frameWidth, uint8]

    p = start
    for x in 0.. <frameWidth:
      doAssert(p[OrderType.R] == color.r)
      doAssert(p[OrderType.G] == color.g)
      doAssert(p[OrderType.B] == color.b)
      inc(p, 3)

    for y in 0.. <frameHeight:
      p = cast[ptr ValueType](cast[ByteAddress](start) + y * (frameWidth * pixWidth))
      doAssert(p[OrderType.R] == color.r)
      doAssert(p[OrderType.G] == color.g)
      doAssert(p[OrderType.B] == color.b)

    for i in 0.. <frameWidth:
      span[i].r = ValueType(i.uint and baseMask.uint)
      span[i].g = ValueType(i.uint and baseMask.uint)
      span[i].b = ValueType(i.uint and baseMask.uint)
      covers[i] = uint8(i.uint and baseMask.uint)

    pixf.copyColorHspan(0, 0, frameWidth, span[0].addr)
    pixf.copyColorVspan(0, 0, frameWidth, span[0].addr)

    p = start
    for x in 0.. <frameWidth:
      doAssert(p[OrderType.R] == span[x].r)
      doAssert(p[OrderType.G] == span[x].g)
      doAssert(p[OrderType.B] == span[x].b)
      inc(p, 3)

    for y in 0.. <frameHeight:
      p = cast[ptr ValueType](cast[ByteAddress](start) + y * (frameWidth * pixWidth))
      doAssert(p[OrderType.R] == span[y].r)
      doAssert(p[OrderType.G] == span[y].g)
      doAssert(p[OrderType.B] == span[y].b)

    var
      cbuf = newString(frameWidth * frameHeight * pixWidth)
      crbuf = create_rbuf(cbuf, frameWidth.cint, frameHeight.cint, (frameHeight * pixWidth).cint)
      cpixf = `create cname`(crbuf)

    for i in 0.. <buffer.len: buffer[i] = 0.chr
    for i in 0.. <cbuf.len: cbuf[i] = 0.chr

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy, xx, yy)
        cpixf.blend_pixel(x.cint, y.cint, c, xx.uint8)
        pixf.blendPixel(x, y, c, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
        cpixf.blend_color_hspan(0, y.cint, frameWidth.cuint, span[0].addr, nil, xx.uint8)
        cpixf.blend_color_vspan(x.cint, 0, frameHeight.cuint, span[0].addr, nil, xx.uint8)
        pixf.blendColorHspan(0, y, frameWidth, span[0].addr, nil, xx.uint8)
        pixf.blendColorVspan(x, 0, frameHeight, span[0].addr, nil, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy, xx, yy)
        cpixf.blend_hline(0, y.cint, frameWidth.cuint, c, xx.uint8)
        cpixf.blend_vline(x.cint, 0, frameHeight.cuint, c, xx.uint8)
        pixf.blendHline(0, y, frameWidth, c, xx.uint8)
        pixf.blendVline(x, 0, frameHeight, c, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy, xx, yy)
        cpixf.blend_solid_hspan(0, y.cint, frameWidth.cuint, c, covers[0].addr)
        cpixf.blend_solid_vspan(x.cint, 0, frameHeight.cuint, c, covers[0].addr)
        pixf.blendSolidHspan(0, y, frameWidth, c, covers[0].addr)
        pixf.blendSolidVspan(x, 0, frameHeight, c, covers[0].addr)

    doAssert(buffer == cbuf)

    var clut = `create_gamma nbit`()
    var lut = `newGamma nbit`()

    cpixf.apply_gamma_inv(clut)
    cpixf.apply_gamma_dir(clut)

    pixf.applyGammaInv(lut)
    pixf.applyGammaDir(lut)
    doAssert(buffer == cbuf)

    var
      tempbuf = newString(frameWidth * frameHeight * pixWidth)
      temprbuf = RenBuf(cast[ptr ValueType](tempbuf[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
      temppixf = `init PixFmt`(temprbuf)

    temppixf.copyFrom(rbuf, 0, 0, 0, 0, frameWidth)
    discard pixf.pixPtr(1, 1)

genTest(test1, PixFmtRgb24, Rgba8, pixf_rgb24, lut8, initRenderingBuffer)
genTest(test2, PixFmtRgb48, Rgba16, pixf_rgb48, lut16, initRenderingBuffer)

testtest1()
testtest2()

template genTestGray(name, PixFmt, ColorT, nbit, RenBuf: untyped) =
  proc `test name`() =
    type
      ValueType = getValueType(ColorT)
    const
      pixWidth = sizeof(ValueType) * 2
      baseMask = getBaseMask(ColorT)

    var buffer = newString(frameWidth * frameHeight * pixWidth)
    for i in 0.. <buffer.len: buffer[i] = 0.chr
    var rbuf = RenBuf(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    var pixf = `init PixFmt`(rbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        pixf.copyPixel(x, y, `init ColorT`((x and baseMask).uint, baseMask.uint))

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let a = `init ColorT`((x and baseMask).uint, baseMask.uint)
        let b = pixf.pixel(x, y)
        doAssert(a == b)

    var color = `init ColorT`(33, 77)
    var p = cast[ptr ValueType](buffer[0].addr)
    makePix(PixFmt, p, color)
    doAssert(p[] == color.v)

    pixf.copyHLine(0, 0, frameWidth, color)
    pixf.copyVLine(0, 0, frameHeight, color)

    var
      start = cast[ptr ValueType](buffer[0].addr)
      span: array[frameWidth, ColorT]
      covers: array[frameWidth, uint8]

    p = start
    for x in 0.. <frameWidth:
      doAssert(p[] == color.v)
      inc p

    for y in 0.. <frameHeight:
      p = cast[ptr ValueType](cast[ByteAddress](start) + y * (frameWidth * pixWidth))
      doAssert(p[] == color.v)


    for i in 0.. <frameWidth:
      span[i].v = ValueType(i.uint and baseMask.uint)
      covers[i] = uint8(i.uint and baseMask.uint)

    pixf.copyColorHspan(0, 0, frameWidth, span[0].addr)
    pixf.copyColorVspan(0, 0, frameWidth, span[0].addr)

    p = start
    for x in 0.. <frameWidth:
      doAssert(p[] == span[x].v)
      inc p

    for y in 0.. <frameHeight:
      p = cast[ptr ValueType](cast[ByteAddress](start) + y * (frameWidth * pixWidth))
      doAssert(p[] == span[y].v)

    var
      cbuf = newString(frameWidth * frameHeight * pixWidth)
      crbuf = create_rbuf(cbuf, frameWidth.cint, frameHeight.cint, (frameHeight * pixWidth).cint)
      cpixf = `create_pixf ColorT`(crbuf)

    for i in 0.. <buffer.len: buffer[i] = 0.chr
    for i in 0.. <cbuf.len: cbuf[i] = 0.chr

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy)
        cpixf.blend_pixel(x.cint, y.cint, c, xx.uint8)
        pixf.blendPixel(x, y, c, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
        cpixf.blend_color_hspan(0, y.cint, frameWidth.cuint, span[0].addr, nil, xx.uint8)
        cpixf.blend_color_vspan(x.cint, 0, frameHeight.cuint, span[0].addr, nil, xx.uint8)
        pixf.blendColorHspan(0, y, frameWidth, span[0].addr, nil, xx.uint8)
        pixf.blendColorVspan(x, 0, frameHeight, span[0].addr, nil, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy)
        cpixf.blend_hline(0, y.cint, frameWidth.cuint, c, xx.uint8)
        cpixf.blend_vline(x.cint, 0, frameHeight.cuint, c, xx.uint8)
        pixf.blendHline(0, y, frameWidth, c, xx.uint8)
        pixf.blendVline(x, 0, frameHeight, c, xx.uint8)

    doAssert(buffer == cbuf)

    for x in 0.. <frameWidth:
      for y in 0.. <frameHeight:
        let
          xx = (x and baseMask).uint
          yy = (y and baseMask).uint
        var c = `init ColorT`(xx, yy)
        cpixf.blend_solid_hspan(0, y.cint, frameWidth.cuint, c, covers[0].addr)
        cpixf.blend_solid_vspan(x.cint, 0, frameHeight.cuint, c, covers[0].addr)
        pixf.blendSolidHspan(0, y, frameWidth, c, covers[0].addr)
        pixf.blendSolidVspan(x, 0, frameHeight, c, covers[0].addr)

    doAssert(buffer == cbuf)

    var clut = `create_gamma nbit`()
    var lut = `newGamma nbit`()

    cpixf.apply_gamma_inv(clut)
    cpixf.apply_gamma_dir(clut)

    pixf.applyGammaInv(lut)
    pixf.applyGammaDir(lut)
    doAssert(buffer == cbuf)

    var
      tempbuf = newString(frameWidth * frameHeight * pixWidth)
      temprbuf = RenBuf(cast[ptr ValueType](tempbuf[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
      temppixf = `init PixFmt`(temprbuf)

    temppixf.copyFrom(rbuf, 0, 0, 0, 0, frameWidth)
    discard pixf.pixPtr(1, 1)

genTestGray(test5, PixFmtGray8, Gray8, lut8, initRenderingBuffer)
genTestGray(test6, PixFmtGray16, Gray16, lut16, initRenderingBuffer)

testtest5()
testtest6()

proc testRenderingBuffer[ColorT]() =
  type
    ValueType = getValueType(ColorT)
  const
    pixWidth = sizeof(ValueType) * 3
    baseMask = getBaseMask(ColorT)
  var
    buf1 = newString(frameWidth * frameHeight * pixWidth)
    buf2 = newString(frameWidth * frameHeight * pixWidth)
    rbuf1 = initRenderingBuffer(cast[ptr ValueType](buf1[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    rbuf2 = initRenderingBuffer(cast[ptr ValueType](buf2[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    rbufc1 = initRenderingBufferCached(cast[ptr ValueType](buf1[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    rbufc2 = initRenderingBufferCached(cast[ptr ValueType](buf2[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)

  for i in 0.. <buf1.len:
    buf1[i] = 0.chr
    buf2[i] = 255.chr

  rbuf1.copyFrom(rbuf2)
  doAssert(buf1 == buf2)

  for i in 0.. <buf1.len:
    buf1[i] = 0.chr
    buf2[i] = 255.chr

  rbufc1.copyFrom(rbufc2)
  doAssert(buf1 == buf2)

  var
    byteWidth = sizeof(ColorT) * 3
    dn1 = initDynaRow[ValueType](100, 120, byteWidth)
    dn2 = initDynaRow[ValueType](100, 120, byteWidth)

  for i in 0.. <dn1.height():
    zeroMem(dn1.rowPtr(i), byteWidth)
    var p = dn2.rowPtr(i)
    for x in 0.. <3:
      p[] = baseMask
      inc p

  dn1.copyFrom(dn2)

  for i in 0.. <dn1.height():
    var
      p1 = dn1.rowPtr(i)
      p2 = dn2.rowPtr(i)
    for x in 0.. <3:
      if p1[] != p2[]:
        doAssert(false)
      inc p1
      inc p2

testRenderingBuffer[Rgba8]()
testRenderingBuffer[Rgba16]()