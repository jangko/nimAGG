import agg_basics, agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_scanline_u
import agg_renderer_scanline, agg_pixfmt_rgb, agg_color_rgba
import agg_gamma_functions, agg_renderer_base, nimBMP

type
  Square = object
    size: float64

proc initSquare(size: float64): Square =
  result.size = size

proc draw[Rasterizer, Scanline, Renderer, ColorT](self: Square, ras : Rasterizer,
  sl: var Scanline, ren: Renderer, color: ColorT, x, y: float64) =
  ras.reset()
  let size = self.size
  ras.moveToD(x*size,      y*size)
  ras.lineToD(x*size+size, y*size)
  ras.lineToD(x*size+size, y*size+size)
  ras.lineToD(x*size,      y*size+size)
  renderScanlinesAAsolid(ras, sl, ren, color)


type
  RendererEnlarge[Renderer] = object
    ras: RasterizerScanlineAA
    sl: ScanlineU8
    ren: Renderer
    square: Square
    color: Rgba8
    size: float64

proc initRendererEnlarged[Renderer](ren: Renderer, size: float64): RendererEnlarge[Renderer] =
  result.ren = ren
  result.square = initSquare(size)
  result.size = size
  result.sl = initScanlineU8()
  result.ras = newRasterizerScanlineAA()

proc setColor[Renderer](self: var RendererEnlarge[Renderer], c: Rgba8) =
  self.color = c
  
proc prepare[Renderer](self: RendererEnlarge[Renderer]) = discard

proc render[Renderer, Scanline](self: var RendererEnlarge[Renderer], sl: var Scanline) =
  let y = sl.getY()
  var
    numSpans = sl.numSpans()
    span = sl.begin()

  doWhile numSpans != 0:
    var
      x = span.x
      covers = span.covers
      numPix = span.len

    doWhile numPix != 0:
      let a = (covers[].uint32 * uint32(self.color.a)) shr 8
      inc covers
      self.square.draw(self.ras, self.sl, self.ren,
        initRgba8(self.color.r, self.color.g, self.color.b, a), x.float64, y.float64)
      inc x
      dec numPix

    dec numSpans

const
  frameWidth = 600
  frameHeight = 400
  pixWidth = 3
  
type
  ValueType = uint8
  
proc onDraw() =
  var
    mx: array[3, float64]
    my: array[3, float64]
    mdx: float64
    mdy: float64
    midx: int

  midx = -1
  mx[0] = 57;    my[0] = 100
  mx[1] = 369;   my[1] = 170
  mx[2] = 143;   my[2] = 310

  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = newRenderingBuffer(cast[ptr ValueType](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pf     = initPixFmtBgr24(rbuf)
    ren    = initRendererBase(pf)
    sl     = initScanlineU8()
    ras    = newRasterizerScanlineAA()
    
  let sizeMul = 32.float64
  ras.setGamma(initGammaPower(1.0))
  var renEn = initRendererEnlarged(ren, sizeMul)
  
  var bkg = initRgba(1,1,1)
  ren.clear(initRgba8(bkg))
  
  ras.reset()
  ras.moveToD(mx[0]/sizeMul, my[0]/sizeMul)
  ras.lineToD(mx[1]/sizeMul, my[1]/sizeMul)
  ras.lineToD(mx[2]/sizeMul, my[2]/sizeMul)
  renEn.setColor(initRgba8(0,0,0, 255))
  renderScanlines(ras, sl, renEn)
  
  saveBMP24("aa_demo.bmp", buffer, frameWidth, frameHeight)

#[
        agg::render_scanlines_aa_solid(ras, sl, ren, agg::rgba8(0,0,0));

        ras.gamma(agg::gamma_none());

        agg::path_storage ps;
        agg::conv_stroke<agg::path_storage> pg(ps);
        pg.width(2.0);

        ps.remove_all();
        ps.move_to(m_x[0], m_y[0]);
        ps.line_to(m_x[1], m_y[1]);
        ras.add_path(pg);
        agg::render_scanlines_aa_solid(ras, sl, ren, agg::rgba8(0,150,160, 200));

        ps.remove_all();
        ps.move_to(m_x[1], m_y[1]);
        ps.line_to(m_x[2], m_y[2]);
        ras.add_path(pg);
        agg::render_scanlines_aa_solid(ras, sl, ren, agg::rgba8(0,150,160, 200));

        ps.remove_all();
        ps.move_to(m_x[2], m_y[2]);
        ps.line_to(m_x[0], m_y[0]);
        ras.add_path(pg);
        agg::render_scanlines_aa_solid(ras, sl, ren, agg::rgba8(0,150,160, 200));]#
    
onDraw()