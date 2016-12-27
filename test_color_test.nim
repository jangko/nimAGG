import agg_color_rgba, agg_gamma_lut

{.passC: "-I./agg-2.5/include".}
{.compile: "test_color.cpp".}
{.passL: "-lstdc++".}

type
  GammaLUT8 = distinct pointer
  GammaLUT16 = distinct pointer
  
proc rgba_premultiply(c: var Rgba) {.importc.}
proc rgba_premultiply_a(c: var Rgba, a: cdouble) {.importc.}
proc rgba_demultiply(c: var Rgba) {.importc.}
proc rgba_gradient(s: var Rgba, c: Rgba, k: cdouble): Rgba {.importc.}

proc rgba8_opacity(s: var Rgba8, a: cdouble) {.importc.}
proc rgba8_get_opacity(s: var Rgba8): cdouble {.importc.}
proc rgba8_premultiply(c: var Rgba8) {.importc.}
proc rgba8_premultiply_a(c: var Rgba8, a: cuint) {.importc.}
proc rgba8_demultiply(c: var Rgba8) {.importc.}
proc rgba8_gradient(s: var Rgba8, c: Rgba8, k: cdouble): Rgba8 {.importc.}
proc rgba8_add(s: var Rgba8, c: Rgba8, cover: cuint) {.importc.}
proc rgba8_apply_gamma_dir(s: var Rgba8, gamma: GammaLUT8) {.importc.}
proc rgba8_apply_gamma_inv(s: var Rgba8, gamma: GammaLUT8) {.importc.}

proc rgba16_opacity(s: var Rgba16, a: cdouble) {.importc.}
proc rgba16_get_opacity(s: var Rgba16): cdouble {.importc.}
proc rgba16_premultiply(c: var Rgba16) {.importc.}
proc rgba16_premultiply_a(c: var Rgba16, a: cdouble) {.importc.}
proc rgba16_demultiply(c: var Rgba16) {.importc.}
proc rgba16_gradient(s: var Rgba16, c: Rgba16, k: cdouble): Rgba16 {.importc.}
proc rgba16_add(s: var Rgba16, c: Rgba16, cover: cuint) {.importc.}
proc rgba16_apply_gamma_dir(s: var Rgba16, gamma: GammaLUT16) {.importc.}
proc rgba16_apply_gamma_inv(s: var Rgba16, gamma: GammaLUT16) {.importc.}

proc create_gamma_lut8(): GammaLUT8 {.importc.}
proc create_gamma_lut8_a(a: cdouble): GammaLUT8 {.importc.}
proc create_gamma_lut16(): GammaLUT16 {.importc.}
proc create_gamma_lut16_a(a: cdouble): GammaLUT16 {.importc.}

proc test_rgba() =
  var a = initRgba(0.1,0.2,0.3,0.4)
  var b = a
  a.rgba_premultiply()
  b.premultiply()
  doAssert(a == b)
  
  a = initRgba(0.1,0.2,0.3,0.4)
  b = a
  a.rgba_premultiply_a(0.5)
  b.premultiply(0.5)
  doAssert(a == b)
  
  a = initRgba(0.1,0.2,0.3,0.4)
  b = a
  a.rgba_demultiply()
  b.demultiply()
  doAssert(a == b)
  
  a = initRgba(0.1,0.2,0.3,0.4)
  b = a
  var c = initRgba(0.2,0.4,0.6,0.8)
  var d = a.rgba_gradient(c, 0.5)
  var e = b.gradient(c, 0.5)
  doAssert(d == e)

proc test_rgba8() =
  var a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  var b = a
  a.rgba8_opacity(cdouble(0.7))
  b.opacity(0.7)
  
  doAssert(a.rgba8_get_opacity() == b.opacity())
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_premultiply_a(100)
  b.premultiply(100)
  doAssert(a == b)

  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_premultiply()
  b.premultiply()
  doAssert(a == b)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_demultiply()
  b.demultiply()
  doAssert(a == b)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  var c = initRgba8(initRgba(0.2,0.4,0.6,0.8))
  var d = a.rgba8_gradient(c, cdouble(0.8))
  var e = b.gradient(c, 0.8)
  doAssert(d == e)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  c = initRgba8(initRgba(0.2,0.4,0.6,0.8))
  a.rgba8_add(c, 100.cuint)
  b.add(c, 100)
  doAssert(a == b)
  
  var g = create_gamma_lut8()
  var h = newGammaLut()
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_apply_gamma_dir(g)
  b.apply_gamma_dir(h)
  doAssert(a == b)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_apply_gamma_inv(g)
  b.apply_gamma_inv(h)
  doAssert(a == b)
  
  g = create_gamma_lut8_a(cdouble(0.6))
  h = newGammaLut(0.6)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_apply_gamma_dir(g)
  b.apply_gamma_dir(h)
  doAssert(a == b)
  
  a = initRgba8(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba8_apply_gamma_inv(g)
  b.apply_gamma_inv(h)
  doAssert(a == b)
 
proc test_Rgba16() =
  var a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  var b = a
  a.rgba16_opacity(cdouble(0.7))
  b.opacity(0.7)
  
  doAssert(a.rgba16_get_opacity() == b.opacity())
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_premultiply_a(100)
  b.premultiply(100)
  doAssert(a == b)

  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_premultiply()
  b.premultiply()
  doAssert(a == b)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_demultiply()
  b.demultiply()
  doAssert(a == b)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  var c = initRgba16(initRgba(0.2,0.4,0.6,0.8))
  var d = a.rgba16_gradient(c, cdouble(0.8))
  var e = b.gradient(c, 0.8)
  doAssert(d == e)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  c = initRgba16(initRgba(0.2,0.4,0.6,0.8))
  a.rgba16_add(c, 100.cuint)
  b.add(c, 100)
  doAssert(a == b)
  
  var g = create_gamma_lut16()
  var h = newGammaLut16()
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_apply_gamma_dir(g)
  b.apply_gamma_dir(h)
  doAssert(a == b)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_apply_gamma_inv(g)
  b.apply_gamma_inv(h)
  doAssert(a == b)
  
  g = create_gamma_lut16_a(cdouble(0.6))
  h = newGammaLut16(0.6)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_apply_gamma_dir(g)
  b.apply_gamma_dir(h)
  doAssert(a == b)
  
  a = initRgba16(initRgba(0.1,0.2,0.3,0.4))
  b = a
  a.rgba16_apply_gamma_inv(g)
  b.apply_gamma_inv(h)
  doAssert(a == b)
  
test_rgba()
test_rgba8()
test_rgba16()