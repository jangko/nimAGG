import agg_basics, agg_pixfmt_rgb, agg_color_rgba, agg_renderer_base
import agg_rasterizer_scanline_aa, agg_rendering_buffer, agg_scanline_u
import agg_trans_affine, agg_span_interpolator_linear, agg_span_allocator
import agg_image_accessors, agg_span_image_filter_rgb, agg_renderer_scanline
import agg_image_filters, agg_gamma_lut, agg_path_storage, agg_conv_stroke
import nimBMP, strutils

const
  frameWidth = 500
  frameHeight = 340
  pixWidth = 3

type
  ValueT = uint8

const
  V = 255

#let
#  image = [0'u8,V,0,V,  0,0,V,V,  V,V,V,V,  V,0,0,V,
#           V,0,0,V,  0,0,0,V,  V,V,V,V,  V,V,V,V,
#           V,V,V,V,  V,V,V,V,  0,0,V,V,  V,0,0,V,
#           0,0,V,V,  V,V,V,V,  0,0,0,V,  0,V,0,V]

let
  image = [0'u8,V,0, 0,0,V, V,V,V, V,0,0,
           V,0,0,    0,0,0, V,V,V, V,V,V,
           V,V,V,    V,V,V, 0,0,V, V,0,0,
           0,0,V,    V,V,V, 0,0,0, 0,V,0,]

proc calcLut(filter: var ImageFilterLut, nb: int, norm: bool, radius: float64) =
  case nb
  of 1:  filter.calculate(construct(ImageFilterBilinear),       norm) 
  of 2:  filter.calculate(construct(ImageFilterBicubic),        norm) 
  of 3:  filter.calculate(construct(ImageFilterSpline16),       norm) 
  of 4:  filter.calculate(construct(ImageFilterSpline36),       norm) 
  of 5:  filter.calculate(construct(ImageFilterHanning),        norm) 
  of 6:  filter.calculate(construct(ImageFilterHamming),        norm) 
  of 7:  filter.calculate(construct(ImageFilterHermite),        norm) 
  of 8:  filter.calculate(construct(ImageFilterKaiser),         norm) 
  of 9:  filter.calculate(construct(ImageFilterQuadric),        norm) 
  of 10: filter.calculate(construct(ImageFilterCatrom),         norm) 
  of 11: filter.calculate(construct(ImageFilterGaussian),       norm) 
  of 12: filter.calculate(construct(ImageFilterBessel),         norm) 
  of 13: filter.calculate(construct(ImageFilterMitchell),       norm) 
  of 14: filter.calculate(construct(ImageFilterSinc, radius),     norm) 
  of 15: filter.calculate(construct(ImageFilterLanczos, radius),  norm) 
  of 16: filter.calculate(construct(ImageFilterBlackman, radius), norm) 
  else: discard
                
proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)    
    sl     = initScanlineU8()
    ras    = initRasterizerScanlineAA()
    
    img    = initRenderingBuffer(cast[ptr ValueT](image[0].unsafeAddr), 4, 4, 4*3)
    para   = [200.0, 40.0, 200.0+300.0, 40.0, 200.0+300.0, 40.0+300.0, 200.0, 40.0+300.0]
    mtx    = initTransAffine(para, 0, 0, 4, 4)
    inter  = initSpanInterpolatorLinear(mtx)
    sa     = initSpanAllocator[Rgba8]()
    pixf   = initPixFmtRgb24(img)
    source = initImageAccessorClone(pixf)    
    filter = initImageFilterLut()
    norm   = true
    radius = 4.0
    mGamma = 1.0
    gamma  = initGammaLut8(mGamma)
    
  for i in 0..16:
    ras.reset()
    ras.moveToD(para[0], para[1])
    ras.lineToD(para[2], para[3])
    ras.lineToD(para[4], para[5])
    ras.lineToD(para[6], para[7])
    rb.clear(initRgba(1, 1, 1))
  
    if i == 0:
      var sg = initSpanImageFilterRgbNN(source, inter)
      renderScanlinesAA(ras, sl, rb, sa, sg)
    else:
      filter.calcLut(i, norm, radius)
      var sg = initSpanImageFilterRgb(source, inter, filter)
      renderScanlinesAA(ras, sl, rb, sa, sg)
      
      var 
        x_start = 5.0
        x_end   = 195.0
        y_start = 235.0
        y_end   = frameHeight.float64 - 5.0
        #x_center = (x_start + x_end) / 2
        p = initPathStorage()
        stroke = initConvStroke(p)
        
      stroke.width(0.8)      
      pf.applyGammaInv(gamma)
      
      for i in 0..16:
        let x = x_start + (x_end - x_start) * i.float64 / 16.0
        p.removeAll()
        p.moveTo(x+0.5, y_start)
        p.lineTo(x+0.5, y_end)
        ras.addPath(stroke)
        renderScanlinesAAsolid(ras, sl, rb, initRgba8(0, 0, 0, if i == 8: 255 else: 100))
      
      let ys = y_start + (y_end - y_start) / 6.0
      p.removeAll()
      p.moveTo(x_start, ys)
      p.lineTo(x_end,   ys)
      ras.addPath(stroke)
      renderScanlinesAAsolid(ras, sl, rb, initRgba8(0, 0, 0))

      var 
        radius = filter.radius()
        n = uint(radius * 256 * 2)
        dx = (x_end - x_start) * radius / 8.0
        dy = y_end - ys
        weights = filter.weightArray()
        xs = (x_end + x_start)/2.0 - (filter.diameter().float64 * (x_end - x_start) / 32.0)
        nn = filter.diameter() * 256
        
      p.removeAll()
      p.moveTo(xs+0.5, ys + dy * weights[0].float64 / imageFilterScale.float64)
      for i in 1.. <nn:
        p.lineTo(xs + dx * i.float64 / n.float64 + 0.5, ys + dy * weights[i].float64 / imageFilterScale.float64)

      ras.addPath(stroke)
      renderScanlinesAAsolid(ras, sl, rb, initRgba8(100, 0, 0))
                
    saveBMP24("image_filters_$1.bmp" % [$i], buffer, frameWidth, frameHeight)

onDraw()