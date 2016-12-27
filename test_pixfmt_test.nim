import agg_rendering_buffer, agg_basics, agg_pixfmt_rgb, agg_color_rgba, agg_gamma_lut

{.passC: "-I./agg-2.5/include".}
{.compile: "test_pixfmt.cpp".}
{.passL: "-lstdc++".}

type
  agg_rbuf = distinct pointer
  agg_pixfmt_rgb24 = distinct pointer
  GammaLUT8 = distinct pointer
  #GammaLUT16 = distinct pointer

proc create_rbuf(buffer: cstring, frame_width, frame_height: cint): agg_rbuf {.importc.}
proc create_pixfmt_rgb24(rbuf: agg_rbuf): agg_pixfmt_rgb24 {.importc.}
proc pixf_rgb24_blend_pixel(pixf: agg_pixfmt_rgb24, x, y: cint, c: var Rgba8, cover: uint8) {.importc.}
proc pixf_rgb24_blend_color_hspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc.}
proc pixf_rgb24_blend_color_vspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, colors: ptr Rgba8, covers: ptr uint8, cover: uint8) {.importc.}
proc pixf_rgb24_blend_hline(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc.}
proc pixf_rgb24_blend_vline(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, cover: uint8) {.importc.}
proc pixf_rgb24_blend_solid_hspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc.}
proc pixf_rgb24_blend_solid_vspan(pixf: agg_pixfmt_rgb24, x, y: cint, len: cuint, c: var Rgba8, covers: ptr uint8) {.importc.}
proc pixf_rgb24_apply_gamma_inv(pixf: agg_pixfmt_rgb24, g: GammaLUT8) {.importc.}
proc pixf_rgb24_apply_gamma_dir(pixf: agg_pixfmt_rgb24, g: GammaLUT8) {.importc.}

proc create_gamma_lut8(): GammaLUT8 {.importc.}
#proc create_gamma_lut8_a(a: cdouble): GammaLUT8 {.importc.}
#proc create_gamma_lut16(): GammaLUT16 {.importc.}
#proc create_gamma_lut16_a(a: cdouble): GammaLUT16 {.importc.}

const
  frame_width = 255
  frame_height = frame_width

proc main() =
  type
    OrderType = getOrderType(PixFmtRgb24)
    ValueType = getValueType(Rgba8)
  const
    pixWidth = 3
    baseMask = getBaseMask(Rgba8)

  var buffer = newString(frame_width * frame_height * pixWidth)
  for i in 0.. <buffer.len: buffer[i] = 0.chr
  var rbuf = newRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frame_width, frame_height, frame_width * pixWidth)
  var pixf = initPixFmtRgb24(rbuf)

  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      pixf.copyPixel(x, y, initRgba8((x mod baseMask).uint, (y mod baseMask).uint, (x mod baseMask).uint, baseMask.uint))

  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      let a = initRgba8((x mod baseMask).uint, (y mod baseMask).uint, (x mod baseMask).uint, baseMask.uint)
      let b = pixf.pixel(x, y)
      doAssert(a == b)

  var color = initRgba8(1,2,3)
  makePix(PixFmtRgb24, cast[ptr ValueType](buffer[0].addr), color)
  doAssert(buffer[OrderType.R.ord] == color.r.chr)
  doAssert(buffer[OrderType.G.ord] == color.g.chr)
  doAssert(buffer[OrderType.B.ord] == color.b.chr)

  pixf.copyHLine(0, 0, frame_width, color)
  pixf.copyVLine(0, 0, frame_height, color)

  var
    start = cast[ptr ValueType](buffer[0].addr)
    p = start
    span: array[frame_width, Rgba8]
    covers: array[frame_width, ValueType]

  for x in 0.. <frame_width:
    doAssert(p[OrderType.R] == color.r)
    doAssert(p[OrderType.G] == color.g)
    doAssert(p[OrderType.B] == color.b)
    inc(p, 3)

  for y in 0.. <frame_height:
    p = start + y * (frame_width * pixWidth)
    doAssert(p[OrderType.R] == color.r)
    doAssert(p[OrderType.G] == color.g)
    doAssert(p[OrderType.B] == color.b)

  for i in 0.. <frame_width:
    span[i].r = (i.uint mod baseMask.uint).ValueType
    span[i].g = (i.uint mod baseMask.uint).ValueType
    span[i].b = (i.uint mod baseMask.uint).ValueType
    covers[i] = (i.uint mod baseMask.uint).ValueType

  pixf.copyColorHspan(0, 0, frame_width, span[0].addr)
  pixf.copyColorVspan(0, 0, frame_width, span[0].addr)

  p = start
  for x in 0.. <frame_width:
    doAssert(p[OrderType.R] == span[x].r)
    doAssert(p[OrderType.G] == span[x].g)
    doAssert(p[OrderType.B] == span[x].b)
    inc(p, 3)

  for y in 0.. <frame_height:
    p = start + y * (frame_width * pixWidth)
    doAssert(p[OrderType.R] == span[y].r)
    doAssert(p[OrderType.G] == span[y].g)
    doAssert(p[OrderType.B] == span[y].b)

  var
    cbuf = newString(frame_width * frame_height * pixWidth)
    crbuf = create_rbuf(cbuf, frame_width.cint, frame_height.cint)
    cpixf = create_pixfmt_rgb24(crbuf)

  for i in 0.. <buffer.len: buffer[i] = 0.chr
  for i in 0.. <cbuf.len: cbuf[i] = 0.chr

  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      let
        xx = (x mod baseMask).uint
        yy = (y mod baseMask).uint
      var c = initRgba8(xx, yy, xx, yy)
      cpixf.pixf_rgb24_blend_pixel(x.cint, y.cint, c, xx.uint8)
      pixf.blendPixel(x, y, c, xx.uint8)

  doAssert(buffer == cbuf)

  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      let
        xx = (x mod baseMask).uint
      cpixf.pixf_rgb24_blend_color_hspan(0, y.cint, frame_width.cuint, span[0].addr, nil, xx.uint8)
      cpixf.pixf_rgb24_blend_color_vspan(x.cint, 0, frame_height.cuint, span[0].addr, nil, xx.uint8)
      pixf.blendColorHspan(0, y, frame_width, span[0].addr, nil, xx.uint8)
      pixf.blendColorVspan(x, 0, frame_height, span[0].addr, nil, xx.uint8)

  doAssert(buffer == cbuf)
  
  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      let
        xx = (x mod baseMask).uint
        yy = (y mod baseMask).uint
      var c = initRgba8(xx, yy, xx, yy)
      cpixf.pixf_rgb24_blend_hline(0, y.cint, frame_width.cuint, c, xx.uint8)
      cpixf.pixf_rgb24_blend_vline(x.cint, 0, frame_height.cuint, c, xx.uint8)
      pixf.blendHline(0, y, frame_width, c, xx.uint8)
      pixf.blendVline(x, 0, frame_height, c, xx.uint8)

  doAssert(buffer == cbuf)

  for x in 0.. <frame_width:
    for y in 0.. <frame_height:
      let
        xx = (x mod baseMask).uint
        yy = (y mod baseMask).uint
      var c = initRgba8(xx, yy, xx, yy)
      cpixf.pixf_rgb24_blend_solid_hspan(0, y.cint, frame_width.cuint, c, covers[0].addr)
      cpixf.pixf_rgb24_blend_solid_vspan(x.cint, 0, frame_height.cuint, c, covers[0].addr)
      pixf.blendSolidHspan(0, y, frame_width, c, covers[0].addr)
      pixf.blendSolidVspan(x, 0, frame_height, c, covers[0].addr)

  doAssert(buffer == cbuf)
  
  var clut = create_gamma_lut8()
  var lut = newGammaLut()
  
  cpixf.pixf_rgb24_apply_gamma_inv(clut)
  cpixf.pixf_rgb24_apply_gamma_dir(clut)
  
  pixf.applyGammaInv(lut)
  pixf.applyGammaDir(lut)
  doAssert(buffer == cbuf)

  var 
    tempbuf = newString(frame_width * frame_height * pixWidth)
    temprbuf = newRenderingBuffer(cast[ptr ValueType](tempbuf[0].addr), frame_width, frame_height, frame_width * pixWidth)
    temppixf = initPixFmtRgb24(temprbuf)
  
  temppixf.copyFrom(rbuf, 0, 0, 0, 0, frame_width)
  var pixptr = pixf.pixPtr(1, 1)
main()