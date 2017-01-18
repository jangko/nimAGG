import agg_basics, agg_rendering_buffer, agg_scanline_p, agg_renderer_base
import agg_pixfmt_rgb, agg_gamma_lut, agg_ellipse, agg_rounded_rect, agg_color_rgba
import agg_conv_stroke, agg_rasterizer_scanline_aa, agg_renderer_scanline, nimBMP

#{.passC: "-I./agg-2.5/include".}
#{.compile: "test_gamma.cpp".}
#{.compile: "agg_arc2.cpp".}
#{.compile: "agg_rounded_rect2.cpp".}
#{.compile: "agg_trans_affine2.cpp".}
#{.compile: "agg_vcgen_stroke2.cpp".}
#
#{.passL: "-lstdc++"}
#
#
#proc test_gamma() {.importc.}

const
  frameWidth = 600
  frameHeight = 400
  pixWidth = 3
  
pixfmtRgb24Gamma(PixFmt, GammaLut8)

const
  mGamma = 1.8
  mWhiteOnBlack = false
  mOffset = 1.25
  mRadius = 25.0
  
type
  ValueType = uint8  
  
var
  mx, my: array[2, float64] 
  gamma  = newGammaLut8(mGamma)
  buffer = newString(frameWidth * frameHeight * pixWidth)
  rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
  pixf   = initPixFmt(rbuf, gamma)
  rb     = initRendererBase(pixf)
  ren    = initRendererScanlineAASolid(rb)
  ras    = initRasterizerScanlineAA()
  sl     = initScanlineP8()
  e: Ellipse
  
rb.clear(if mWhiteOnBlack: initRgba(0,0,0) else: initRgba(1,1,1))
  
mx[0] = 100
my[0] = 100
mx[1] = 500
my[1] = 350

# Render two "control" circles
ren.color(initRgba8(127,127,127))
e.init(mx[0], my[0], 3, 3, 16)
ras.addPath(e)
renderScanlines(ras, sl, ren)

e.init(mx[1], my[1], 3, 3, 16)
ras.addPath(e)
renderScanlines(ras, sl, ren)

# Creating a rounded rectangle
var d = mOffset
var r = initRoundedRect(mx[0]+d, my[0]+d, mx[1]+d, my[1]+d, mRadius)
r.normalizeRadius()

#test_gamma()
#echo "----"

# Drawing as an outline
var p = initConvStroke(r)
p.width(1.0)
ras.addPath(p)
ren.color(if mWhiteOnBlack: initRgba(1,1,1) else: initRgba(0,0,0))
renderScanlines(ras, sl, ren)
        
saveBMP24("rounded_rect.bmp", buffer, frameWidth, frameHeight)