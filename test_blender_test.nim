import agg_comp_op, agg_pixfmt_rgba, agg_pixfmt_gray, agg_pixfmt_rgb
import agg_color_rgba, agg_color_gray, agg_rendering_buffer
import agg_gamma_lut

{.passC: "-I./agg-2.5/include".}
{.compile: "test_blender.cpp".}
{.passL: "-lstdc++".}

proc rgb24_blendpix1(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc rgb24_blendpix2(p: cstring, cr, cg, cb, alpha: cuint) {.importc.}
proc gray8_blendpix1(p: cstring, cv, alpha, cover: cuint) {.importc.}
proc gray8_blendpix2(p: cstring, cv, alpha: cuint) {.importc.}
proc pre32_blendpix1(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc pre32_blendpix2(p: cstring, cr, cg, cb, alpha: cuint) {.importc.}
proc plain32_blendpix1(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc car_blendpix(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc carctd_blendpix(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc carctdpre_blendpix(p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}

proc t_blendpix(op: cuint, p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc u_blendpix(op: cuint, p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc v_blendpix(op: cuint, p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}
proc w_blendpix(op: cuint, p: cstring, cr, cg, cb, alpha, cover: cuint) {.importc.}

type
  BlenderRgbPre24 = BlenderRgbPre[Rgba8, OrderRgb]
  BlenderRgbaPre32 = BlenderRgbaPre[Rgba8, OrderRgba]
  BlenderRgbaPlain32 = BlenderRgbaPlain[Rgba8, OrderRgba]

proc testBlenderRgb() =
  var
    z: BlenderRgbPre24
    x: Rgba8
    y: Rgba8

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      z.blendPix(cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      rgb24_blendpix1(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      z.blendPix(cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint)
      rgb24_blendpix2(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint)
      doAssert(x == y)

echo "blender rgb"
testBlenderRgb()

proc testBlenderGray() =
  var
    x: Gray8
    y: Gray8
  for r in 0..255:
    for g in 0..255:
      x = initGray8(r.uint, g.uint)
      y = initGray8(r.uint, g.uint)
      BlenderGrayPreBlendPix[Gray8, uint8](cast[ptr uint8](x.addr), r.uint, g.uint, r.uint)
      gray8_blendpix1(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initGray8(r.uint, g.uint)
      y = initGray8(r.uint, g.uint)
      BlenderGrayPreBlendPix[Gray8, uint8](cast[ptr uint8](x.addr), r.uint, g.uint)
      gray8_blendpix2(cast[cstring](y.addr), r.cuint, g.cuint)
      doAssert(x == y)

echo "blender gray"
testBlenderGray()

proc testBlenderRgba() =
  type
    z = BlenderRgbaPre32
    w = BlenderRgbaPlain32
    h = CompAdaptorRgba[BlenderRgbaPre32]
    i = CompAdaptorClipToDstRgba[BlenderRgbaPre32]
    j = CompAdaptorClipToDstRgbaPre[BlenderRgbaPre32]
  var
    x: Rgba8
    y: Rgba8

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      z.blendPix(cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      pre32_blendpix1(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      z.blendPix(cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint)
      pre32_blendpix2(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      w.blendPix(cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      plain32_blendpix1(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      h.blendPix(nil, cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      car_blendpix(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      i.blendPix(nil, cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      carctd_blendpix(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

  for r in 0..255:
    for g in 0..255:
      x = initRgba8(r.uint, g.uint, g.uint, r.uint)
      y = initRgba8(r.uint, g.uint, g.uint, r.uint)
      j.blendPix(nil, cast[ptr uint8](x.addr), r.uint, g.uint, r.uint, g.uint, r.uint)
      carctdpre_blendpix(cast[cstring](y.addr), r.cuint, g.cuint, r.cuint, g.cuint, r.cuint)
      doAssert(x == y)

echo "blender rgba"
testBlenderRgba()

proc testCompOpBlend() =
  type
    t = CompOpAdaptorRgba[Rgba8, OrderRgba]
    u = CompOpAdaptorClipToDstRgba[Rgba8, OrderRgba]
    v = CompOpAdaptorRgbaPre[Rgba8, OrderRgba]
    w = CompOpAdaptorClipToDstRgbaPre[Rgba8, OrderRgba]

  var
    table = cast[CustomBlendTable](compOpTable[Rgba8, OrderRgba, getValueT(Rgba8)]())
    x: Rgba8
    y: Rgba8

  const len = high(CompOp).ord

  for c in 0.. <len:
    var p = table[c]
    for a in 0..255:
      for b in 0..255:
        x = initRgba8(a.uint, b.uint, a.uint, b.uint)
        y = initRgba8(a.uint, b.uint, a.uint, b.uint)
        t.blendPix(p, cast[ptr uint8](x.addr), a.uint, b.uint, a.uint, b.uint, a.uint)
        t_blendpix(c.cuint, cast[cstring](y.addr), a.cuint, b.cuint, a.cuint, b.cuint, a.cuint)
        if x != y:
          let op = CompOp(c)
          echo x, " ", y, " ", op
          quit(-1)

  for c in 0.. <len:
    var p = table[c]
    for a in 0..255:
      for b in 0..255:
        x = initRgba8(a.uint, b.uint, a.uint, b.uint)
        y = initRgba8(a.uint, b.uint, a.uint, b.uint)
        u.blendPix(p, cast[ptr uint8](x.addr), a.uint, b.uint, a.uint, b.uint, a.uint)
        u_blendpix(c.cuint, cast[cstring](y.addr), a.cuint, b.cuint, a.cuint, b.cuint, a.cuint)
        if x != y:
          let op = CompOp(c)
          echo x, " ", y, " ", op
          quit(-1)

  for c in 0.. <len:
    var p = table[c]
    for a in 0..255:
      for b in 0..255:
        x = initRgba8(a.uint, b.uint, a.uint, b.uint)
        y = initRgba8(a.uint, b.uint, a.uint, b.uint)
        v.blendPix(p, cast[ptr uint8](x.addr), a.uint, b.uint, a.uint, b.uint, a.uint)
        v_blendpix(c.cuint, cast[cstring](y.addr), a.cuint, b.cuint, a.cuint, b.cuint, a.cuint)
        if x != y:
          let op = CompOp(c)
          echo x, " ", y, " ", op
          quit(-1)

  for c in 0.. <len:
    var p = table[c]
    for a in 0..255:
      for b in 0..255:
        x = initRgba8(a.uint, b.uint, a.uint, b.uint)
        y = initRgba8(a.uint, b.uint, a.uint, b.uint)
        w.blendPix(p, cast[ptr uint8](x.addr), a.uint, b.uint, a.uint, b.uint, a.uint)
        w_blendpix(c.cuint, cast[cstring](y.addr), a.cuint, b.cuint, a.cuint, b.cuint, a.cuint)
        if x != y:
          let op = CompOp(c)
          echo x, " ", y, " ", op
          quit(-1)

echo "comp op blend"
testCompOpBlend()

type
  agg_rbuf = distinct pointer
  agg_pixfmt = distinct pointer
  GammaLUT8 = distinct pointer

proc create_rbuf(buffer: cstring, frameWidth, frameHeight, stride: cint): agg_rbuf {.importc.}
proc create_pixf(rbuf: agg_rbuf): agg_pixfmt {.importc.}
proc blend_pixel(pixf: agg_pixfmt, x, y: cint, c: var Rgba8, cover: uint8) {.importc: "pixf_blend_pixel".}
proc blend_color_hspan(pixf: agg_pixfmt, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc: "pixf_blend_color_hspan".}
proc blend_color_vspan(pixf: agg_pixfmt, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc: "pixf_blend_color_vspan".}
proc blend_hline(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc: "pixf_blend_hline".}
proc blend_vline(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc: "pixf_blend_vline".}
proc blend_solid_hspan(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc: "pixf_blend_solid_hspan".}
proc blend_solid_vspan(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc: "pixf_blend_solid_vspan".}
proc apply_gamma_inv(pixf: agg_pixfmt, g: GammaLUT8) {.importc: "pixf_apply_gamma_inv".}
proc apply_gamma_dir(pixf: agg_pixfmt, g: GammaLUT8) {.importc: "pixf_apply_gamma_dir".}
proc create_gamma_lut8(): GammaLUT8 {.importc.}
proc copy_pixel(pixf: agg_pixfmt, x, y: cint, c: var Rgba8) {.importc: "pixf_copy_pixel".}
proc pixel(pixf: agg_pixfmt, x, y: cint): Rgba8 {.importc: "pixf_pixel".}
proc copy_vline(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8) {.importc: "pixf_copy_vline".}
proc copy_hline(pixf: agg_pixfmt, x, y: cint, len: cuint, c: var Rgba8) {.importc: "pixf_copy_hline".}
proc copy_color_hspan(pixf: agg_pixfmt, x, y: cint, len: cuint, c: ptr Rgba8) {.importc: "pixf_copy_color_hspan".}
proc copy_color_vspan(pixf: agg_pixfmt, x, y: cint, len: cuint, c: ptr Rgba8) {.importc: "pixf_copy_color_vspan".}

proc testCustomBlend() =
  type
    ColorT = Rgba8
    CompOpAdaptor = CompOpAdaptorRgba[ColorT, OrderRgba]
    ValueT = getValueT(ColorT)

  const
    pixWidth = getPixWidth(PixfmtCustomBlendRgba[CompOpAdaptor, RenderingBuffer])
    baseMask = getBaseMask(ColorT)
    frameWidth = 255
    frameHeight = 255

  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pixf = initPixfmtCustomBlendRgba[CompOpAdaptor, RenderingBuffer](rbuf)

  var
    cbuf = newString(frameWidth * frameHeight * pixWidth)
    crbuf = create_rbuf(cbuf, frameWidth.cint, frameHeight.cint, (frameHeight * pixWidth).cint)
    cpixf = create_pixf(crbuf)

  echo "copy pixel"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      var c = construct(ColorT, (x and baseMask).uint, (y and baseMask).uint, (x and baseMask).uint, baseMask.uint)
      pixf.copyPixel(x, y, c)
      cpixf.copyPixel(x.cint, y.cint, c)

  echo "pixel"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      var
        a = pixf.pixel(x, y)
        b = cpixf.pixel(x.cint, y.cint)
      doAssert(a == b)

  var color = construct(ColorT, 1,2,3)

  echo "copy hline vline"
  pixf.copyHLine(0, 0, frameWidth, color)
  pixf.copyVLine(0, 0, frameHeight, color)

  cpixf.copyHLine(0, 0, frameWidth, color)
  cpixf.copyVLine(0, 0, frameHeight, color)

  doAssert(buffer == cbuf)

  var
    span: array[frameWidth, ColorT]
    covers: array[frameWidth, uint8]

  for i in 0.. <frameWidth:
    span[i].r = ValueT(i.uint and baseMask.uint)
    span[i].g = ValueT(i.uint and baseMask.uint)
    span[i].b = ValueT(i.uint and baseMask.uint)
    covers[i] = uint8(i.uint and baseMask.uint)

  echo "copy color vspan hspan"
  pixf.copyColorHspan(0, 0, frameWidth, span[0].addr)
  pixf.copyColorVspan(0, 0, frameWidth, span[0].addr)
  cpixf.copyColorHspan(0, 0, frameWidth, span[0].addr)
  cpixf.copyColorVspan(0, 0, frameWidth, span[0].addr)

  doAssert(buffer == cbuf)

  echo "blend pixel"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      let
        xx = (x and baseMask).uint
        yy = (y and baseMask).uint
      var c = construct(ColorT, xx, yy, xx, yy)
      cpixf.blend_pixel(x.cint, y.cint, c, xx.uint8)
      pixf.blendPixel(x, y, c, xx.uint8)

  doAssert(buffer == cbuf)

  echo "blend color hspan vspan"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      let
        xx = (x and baseMask).uint
      cpixf.blend_color_hspan(0, y.cint, frameWidth.cuint, span[0].addr, nil, xx.uint8)
      cpixf.blend_color_vspan(x.cint, 0, frameHeight.cuint, span[0].addr, nil, xx.uint8)
      pixf.blendColorHspan(0, y, frameWidth, span[0].addr, nil, xx.uint8)
      pixf.blendColorVspan(x, 0, frameHeight, span[0].addr, nil, xx.uint8)

  doAssert(buffer == cbuf)

  echo "blend hline vline"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      let
        xx = (x and baseMask).uint
        yy = (y and baseMask).uint
      var c = construct(ColorT, xx, yy, xx, yy)
      cpixf.blend_hline(0, y.cint, frameWidth.cuint, c, xx.uint8)
      cpixf.blend_vline(x.cint, 0, frameHeight.cuint, c, xx.uint8)
      pixf.blendHline(0, y, frameWidth, c, xx.uint8)
      pixf.blendVline(x, 0, frameHeight, c, xx.uint8)

  doAssert(buffer == cbuf)

  echo "blend solid hspan vspan"
  for x in 0.. <frameWidth:
    for y in 0.. <frameHeight:
      let
        xx = (x and baseMask).uint
        yy = (y and baseMask).uint
      var c = construct(ColorT, xx, yy, xx, yy)
      cpixf.blend_solid_hspan(0, y.cint, frameWidth.cuint, c, covers[0].addr)
      cpixf.blend_solid_vspan(x.cint, 0, frameHeight.cuint, c, covers[0].addr)
      pixf.blendSolidHspan(0, y, frameWidth, c, covers[0].addr)
      pixf.blendSolidVspan(x, 0, frameHeight, c, covers[0].addr)

  doAssert(buffer == cbuf)

  var clut = create_gamma_lut8()
  var lut = initGammaLut8()

  echo "gamm inv gamma dir"
  cpixf.apply_gamma_inv(clut)
  cpixf.apply_gamma_dir(clut)

  pixf.applyGammaInv(lut)
  pixf.applyGammaDir(lut)
  doAssert(buffer == cbuf)

  echo "copy from"
  var
    tempbuf = newString(frameWidth * frameHeight * pixWidth)
    temprbuf = initRenderingBuffer(cast[ptr ValueT](tempbuf[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    temppixf = initPixfmtCustomBlendRgba[CompOpAdaptor, RenderingBuffer](temprbuf)

  temppixf.copyFrom(rbuf, 0, 0, 0, 0, frameWidth)
  discard pixf.pixPtr(1, 1)


echo "custom blend"
testCustomBlend()