import agg_rendering_buffer, agg_rasterizer_scanline_aa, agg_ellipse
import agg_trans_affine, agg_conv_transform, agg_conv_stroke
import agg_pixfmt_rgb, agg_scanline_p, agg_renderer_scanline, agg_image_filters
import agg_renderer_base, agg_color_rgba, agg_path_storage, nimBMP

type
  FilterBase = ref object of RootObj
    radiusI: proc(self: FilterBase): float64
    setRadiusI: proc(self: var FilterBase, r: float64)
    calcWeightI: proc(self: var FilterBase, x: float64): float64
    
proc radius(self: FilterBase): float64 =
  self.radiusI(self)
  
proc radius(self: var FilterBase, r: float64) =
  self.setRadiusI(self, r)
  
proc calcWeight(self: var FilterBase, x: float64): float64 =
  self.calcWeightI(self, x)
  
type
  ImageFNoRadius[Filter] = ref object of FilterBase
    mFilter: Filter
    
proc FNR_Radius[Filter](self: FilterBase): float64 =
  var self = ImageFNoRadius[Filter](self)
  self.mFilter.radius()

proc FNR_SetRadius[Filter](self: var FilterBase, r: float64) =
  discard
  
proc FNR_CalcWeight[Filter](self: var FilterBase, x: float64): float64 =
  var self = ImageFNoRadius[Filter](self)
  self.mFilter.calcWeight(abs(x))

proc initImageFNoRadius[Filter](): FilterBase =
  var res = new(ImageFNoRadius[Filter])
  res.radiusI = FNR_Radius[Filter]
  res.setRadiusI = FNR_SetRadius[Filter]
  res.calcWeightI = FNR_CalcWeight[Filter]
  result = res
  
type
  ImageF[Filter] = ref object of FilterBase
    mFilter: Filter
    
proc F_Radius[Filter](self: FilterBase): float64 =
  var self = ImageF[Filter](self)
  self.mFilter.radius()

proc F_SetRadius[Filter](self: var FilterBase, r: float64) =
  var self = ImageF[Filter](self)
  self.mFilter = construct(Filter, r)
  
proc F_CalcWeight[Filter](self: var FilterBase, x: float64): float64 =
  var self = ImageF[Filter](self)
  self.mFilter.calcWeight(abs(x))

proc initImageF[Filter](): FilterBase =
  var res = new(ImageF[Filter])
  res.mFilter = construct(Filter, 2.0)
  res.radiusI = F_Radius[Filter]
  res.setRadiusI = F_SetRadius[Filter]
  res.calcWeightI = F_CalcWeight[Filter]
  result = res
  
const
  frameWidth = 780
  frameHeight = 300
  pixWidth = 3

type
  ValueType = uint8

{.passC: "-I./agg-2.5/include".}
{.compile: "test_filter.cpp".}
{.compile: "agg_vcgen_stroke2.cpp".}
{.passL: "-lstdc++".}

proc test_filter() {.importc.}

proc onDraw() =
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf   = initRenderingBuffer(cast[ptr ValueType](buffer[0]), frameWidth, frameHeight, -frameWidth * pixWidth)
    pf     = initPixFmtRgb24(rbuf)
    rb     = initRendererBase(pf)
    ren    = initRendererScanlineAASolid(rb)
    sl     = initScanlineP8()
    ras    = initRasterizerScanlineAA()
    
    initial_width = frameWidth.float64
    initial_height = frameHeight.float64
    x_start  = 125.0
    x_end    = initial_width - 15.0
    y_start  = 10.0
    y_end    = initial_height - 10.0
    x_center = (x_start + x_end) / 2
    ys = y_start + (y_end - y_start) / 6.0
    
    path   = initPathStorage()
    pl     = initConvStroke(path)
    mtx    = initTransAffine()
    tr     = initConvTransform(pl, mtx)
    
    filter1 = initImageFNoRadius[ImageFilterBilinear]
    filter2 = initImageFNoRadius[ImageFilterBicubic]
    filter3 = initImageFNoRadius[ImageFilterSpline16]
    filter4 = initImageFNoRadius[ImageFilterSpline36]
    filter5 = initImageFNoRadius[ImageFilterHanning]
    filter6 = initImageFNoRadius[ImageFilterHamming]
    filter7 = initImageFNoRadius[ImageFilterHermite]
    filter8 = initImageFNoRadius[ImageFilterKaiser]
    filter9 = initImageFNoRadius[ImageFilterQuadric]
    filter10 = initImageFNoRadius[ImageFilterCatrom]
    filter11 = initImageFNoRadius[ImageFilterGaussian]
    filter12 = initImageFNoRadius[ImageFilterBessel]
    filter13 = initImageFNoRadius[ImageFilterMitchell]
    filter14 = initImageF[ImageFilterSinc]
    filter15 = initImageF[ImageFilterLanczos]
    filter16 = initImageF[ImageFilterBlackman]
    filters = [filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8,
               filter9, filter10, filter11, filter12, filter13, filter14, filter15, filter16]
  
  test_filter()
  echo "---"
  
  for i in 0..16:
    let x = x_start + (x_end - x_start) * i.float / 16.0
    path.removeAll()
    path.moveTo(x+0.5, y_start)
    path.lineTo(x+0.5, y_end)
    ras.addPath(tr)
    ren.color(initRgba8(0, 0, 0, if i == 8: 255 else: 100))
    renderScanlines(ras, sl, ren)
  
  #path.removeAll()
  #path.moveTo(x_start, ys)
  #path.lineTo(x_end,   ys)
  #ras.addPath(tr)
  #ren.color(initRgba8(0, 0, 0))
  #renderScanlines(ras, sl, ren)
  #pl.width(1.0)


  #[
    m_filter_func[i]->set_radius(m_radius.value());
    unsigned j;

    double radius = m_filter_func[i]->radius();
    unsigned n = unsigned(radius * 256 * 2);
    double dy = y_end - ys;

    double xs = (x_end + x_start)/2.0 - (radius * (x_end - x_start) / 16.0);
    double dx = (x_end - x_start) * radius / 8.0;

    p.remove_all();
    p.move_to(xs+0.5, ys + dy * m_filter_func[i]->calc_weight(-radius));
    for(j = 1; j < n; j++)
    {
        p.line_to(xs + dx * j / n + 0.5,
                  ys + dy * m_filter_func[i]->calc_weight(j / 256.0 - radius));
    }
    ras.add_path(tr);
    rs.color(agg::rgba8(100, 0, 0));
    agg::render_scanlines(ras, sl, rs);

    p.remove_all();
    unsigned xint;
    int ir = int(ceil(radius) + 0.1);

    for(xint = 0; xint < 256; xint++)
    {
        int xfract;
        double sum = 0;
        for(xfract = -ir; xfract < ir; xfract++) 
        {
            double xf = xint/256.0 + xfract;
            if(xf >= -radius || xf <= radius)
            {
                sum += m_filter_func[i]->calc_weight(xf);
            }
        }

        double x = x_center + ((-128.0 + xint) / 128.0) * radius * (x_end - x_start) / 16.0;
        double y = ys + sum * 256 - 256;

        if(xint == 0) p.move_to(x, y);
        else          p.line_to(x, y);
    }
    ras.add_path(tr);
    rs.color(agg::rgba8(0, 100, 0));
    agg::render_scanlines(ras, sl, rs);

    agg::image_filter_lut normalized(*m_filter_func[i]);
    const agg::int16* weights = normalized.weight_array();

    xs = (x_end + x_start)/2.0 - (normalized.diameter() * (x_end - x_start) / 32.0);
    unsigned nn = normalized.diameter() * 256;
    p.remove_all();
    p.move_to(xs+0.5, ys + dy * weights[0] / agg::image_filter_scale);
    for(j = 1; j < nn; j++)
    {
        p.line_to(xs + dx * j / n + 0.5,
                  ys + dy * weights[j] / agg::image_filter_scale);
    }
    ras.add_path(tr);
    rs.color(agg::rgba8(0, 0, 100, 255));
    agg::render_scanlines(ras, sl, rs);
 ]#
  saveBMP24("image_filter_graph.bmp", buffer, frameWidth, frameHeight)
  
onDraw()