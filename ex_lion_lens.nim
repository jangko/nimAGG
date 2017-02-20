import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_p
import agg_renderer_scanline, agg_path_storage, agg_conv_transform, agg_trans_warp_magnifier
import agg_conv_segmentator, agg_bounding_rect, agg_color_rgba, agg_pixfmt_rgb
import agg_renderer_base, parse_lion, nimBMP

const
  frameWidth = 500
  frameHeight = 600
  pixWidth = 3
  mRadius = 70.0
  mMagn = 3.0
  
type
  ValueT = uint8

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    lion   = parseLion(frameWidth, frameHeight)
    x1     = 200.0
    y1     = 150.0
        
  rb.clear(initRgba(1, 1, 1))
  
  var lens = initTransWarpMagnifier()
  lens.center(x1, y1)
  lens.magnification(mMagn)
  lens.radius(mRadius / mMagn)

  var 
    segm = initConvSegmentator(lion.path)
    transMtx = initConvTransform(segm, lion.mtx)
    transLens = initConvTransform(transMtx, lens)  
        
  renderAllPaths(ras, sl, ren, transLens, lion.colors, lion.pathIdx, lion.numPaths)
  saveBMP24("lion_lens.bmp", buffer, frameWidth, frameHeight)
onDraw()