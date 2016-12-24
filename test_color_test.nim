import agg_color_rgba

{.passC: "-I./agg-2.5/include".}
{.compile: "test_color.cpp".}

proc rgba_premultiply(c: var Rgba) {.importc.}

var a = initRgba(0.1,0.2,0.3,0.4)
var b = a
a.rgba_premultiply()
b.premultiply()
doAssert(a == b)
