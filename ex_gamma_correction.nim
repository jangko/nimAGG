import agg_trans_affine, agg_conv_stroke, agg_rasterizer_scanline_aa
import agg_rendering_buffer, agg_scanline_u, agg_renderer_scanline
import agg_gamma_lut, agg_basics, agg_gamma_lut, agg_pixfmt_rgb
import agg_renderer_base, agg_color_rgba, agg_path_storage
import nimBMP, agg_gamma_functions, agg_ellipse

const
  frameWidth = 400
  frameHeight = 320
  pixWidth = 3

type
  ValueType = uint8
  
pixfmtRgb24Gamma(PixFmt, GammaLut8)  

proc onDraw() =
  const
    thickness = 1.0
    kGamma     = 1.0
    contrast  = 1.0
    rx = frameWidth.float64 / 3.0
    ry = frameHeight.float64 / 3.0

  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    gamma  = newGammaLut8(kGamma)
    pf     = initPixFmt(rbuf, gamma)
    rb     = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    path   = initPathStorage()
  
  rb.clear(initRgba(1, 1, 1))
  
  var
    dark = 1.0 - contrast
    light = contrast
  
  rb.copyBar(0,0,frameWidth div 2, frameHeight, initRgba(dark,dark,dark))
  rb.copyBar(frameWidth div 2+1,0, frameWidth, frameHeight,  initRgba(light,light,light))
  rb.copyBar(0,frameHeight div 2+1, frameWidth, frameHeight, initRgba(1.0,dark,dark))

  var
    x = (frameWidth.float64 - 256.0) / 2.0
    y = 50.0
    gp = initGammaPower(kGamma)
    
  path.removeAll()
  for i in 0..255:
    var 
      v = float64(i) / 255.0
      gval = gp.getGammaValue(v)
      dy = gval * 255.0
      
    if i == 0: path.moveTo(x + i.float64, y + dy)
    else:      path.lineTo(x + i.float64, y + dy)

  
  var gpoly = initConvStroke(path)
  gpoly.width(2.0)
  ras.reset()
  ras.addPath(gpoly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(80,127,80))

  var 
    width2  = frameWidth.float64 / 2
    height2 = frameHeight.float64 / 2
    ell     = initEllipse(width2, height2, rx, ry, 150)
    poly    = initconvStroke(ell)

  poly.width(thickness)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(255,0,0))
  
  ell.init(width2, height2, rx-5.0, ry-5.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,255,0))
  
  ell.init(width2, height2, rx-10.0, ry-10.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,0,255))
  
  ell.init(width2, height2, rx-15.0, ry-15.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(0,0,0))
  
  ell.init(width2, height2, rx-20.0, ry-20.0, 150)
  ras.reset()
  ras.addPath(poly)
  renderScanlinesAASolid(ras, sl, rb, initRgba8(255,255,255))

  saveBMP24("gamma_correction.bmp", buffer, frameWidth, frameHeight)  
  
onDraw()