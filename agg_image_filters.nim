import agg_basics, math, agg_math

const
  imageFilterShift = 14
  imageFilterScale = 1 shl imageFilterShift
  imageFilterMask  = imageFilterScale - 1

const
  imageSubpixelShift = 8
  imageSubpixelScale = 1 shl imageSubpixelShift
  imageSubpixelMask  = imageSubpixelScale - 1


type
  ImageFilterLut* = object of RootObj
    mRadius: float64
    mDiameter: int
    mStart: int
    mWeightArray: seq[int16]

proc initImageFilterLut*(): ImageFilterLut =
  result.mRadius = 0
  result.mDiameter = 0
  result.mStart = 0
  result.mWeightArray = @[]
#[
proc normalize(self: var ImageFilterLut) =
{
    unsigned i;
    int flip = 1;

    for(i = 0; i < imageSubpixelScale; i++)
    {
        for(;;)
        {
            int sum = 0;
            unsigned j;
            for(j = 0; j < self.mDiameter; j++)
            {
                sum += self.mWeightArray[j * imageSubpixelScale + i];
            }

            if(sum == imageFilterScale) break;

            double k = double(imageFilterScale) / double(sum);
            sum = 0;
            for(j = 0; j < self.mDiameter; j++)
            {
                sum +=     self.mWeightArray[j * imageSubpixelScale + i] =
                    iround(self.mWeightArray[j * imageSubpixelScale + i] * k);
            }

            sum -= imageFilterScale;
            int inc = (sum > 0) ? -1 : 1;

            for(j = 0; j < self.mDiameter && sum; j++)
            {
                flip ^= 1;
                unsigned idx = flip ? self.mDiameter/2 + j/2 : self.mDiameter/2 - j/2;
                int v = self.mWeightArray[idx * imageSubpixelScale + i];
                if(v < imageFilterScale)
                {
                    self.mWeightArray[idx * imageSubpixelScale + i] += inc;
                    sum += inc;
                }
            }
        }
    }

    unsigned pivot = self.mDiameter shl (imageSubpixelShift - 1);

    for(i = 0; i < pivot; i++)
    {
        self.mWeightArray[pivot + i] = self.mWeightArray[pivot - i];
    }
    unsigned end = (diameter() shl imageSubpixelShift) - 1;
    self.mWeightArray[0] = self.mWeightArray[end];
}

proc reallocLut(r: float64adius)
   m_radius = radius;
   self.mDiameter = uceil(radius) * 2;
   m_start = -int(self.mDiameter / 2 - 1);
   unsigned size = self.mDiameter shl imageSubpixelShift;
   if(size > self.mWeightArray.size())
   {
       self.mWeightArray.resize(size);
   }

[FilterF> proc calculate(const FilterF& filter,
                                       bool normalization=true)
{
    r: float64 = filter.radius()
    reallocLut(r)
    unsigned i;
    unsigned pivot = diameter() shl (imageSubpixelShift - 1)
    for(i = 0; i < pivot; i++)
    {
        double x = double(i) / double(imageSubpixelScale)
        double y = filter.calcWeight(x)
        self.mWeightArray[pivot + i] =
        self.mWeightArray[pivot - i] = (int16)iround(y * imageFilterScale)
    }
    unsigned end = (diameter() shl imageSubpixelShift) - 1;
    self.mWeightArray[0] = self.mWeightArray[end];
    if normalization)
    {
        normalize()
    }
}

double       radius()       const { return self.mRadius;   }
unsigned     diameter()     const { return self.mDiameter
int          start()        const { return self.mStart;    }
const int16* weight_array(): float64 = &self.mWeightArray[0]

type
  ImageFilter*[FilterF] = object of ImageFilterLut
    mFilterF = FilterF

proc initImageFilter*[FilterF]() = ImageFilter[FilterF] =
  result.mFilterF.calculate()
]#

type
  ImageFilterBilinear* = object
  
proc radius*(self: ImageFilterBilinear): float64 = 1.0

proc calcWeight*(self: ImageFilterBilinear, x: float64): float64 =
  result = 1.0 - x

type 
  ImageFilterHanning* = object
  
proc radius*(self: ImageFilterHanning): float64 = 1.0

proc calcWeight*(self: ImageFilterHanning, x: float64): float64 =
  result = 0.5 + 0.5 * cos(pi * x)

type 
  ImageFilterHamming* = object

proc radius*(self: ImageFilterHamming): float64 = 1.0

proc calcWeight*(self: ImageFilterHamming, x: float64): float64 =
  result = 0.54 + 0.46 * cos(pi * x)

type 
  ImageFilterHermite* = object
  
proc radius*(self: ImageFilterHermite): float64 = 1.0

proc calcWeight*(self: ImageFilterHermite, x: float64): float64 =
  result = (2.0 * x - 3.0) * x * x + 1.0

type 
  ImageFilterQuadric* = object

proc radius*(self: ImageFilterQuadric): float64 = 1.5

proc calcWeight*(self: ImageFilterQuadric, x: float64): float64 =
  if x < 0.5: return 0.75 - x * x
  if x < 1.5: 
    let t = x - 1.5
    return 0.5 * t * t
  result = 0.0

type 
  ImageFilterBicubic* = object
  
proc pow3(x: float64): float64 =
  result = if x <= 0.0: 0.0 else: x * x * x

proc radius*(self: ImageFilterbicubic): float64 = 2.0

proc calcWeight*(self: ImageFilterbicubic, x: float64): float64 =
  result = (1.0/6.0) *
    (pow3(x + 2) - 4 * pow3(x + 1) + 6 * pow3(x) - 4 * pow3(x - 1))

type 
  ImageFilterKaiser* = object
    a, i0a, epsilon: float64

proc bessel_i0(self: ImageFilterKaiser, x: float64): float64 =
  var
    sum, y, t: float64

  sum = 1.0
  y = x * x / 4.0
  t = y
  
  var i = 2
  while t > self.epsilon:
    sum += t
    t *= float64(y) / (i * i).float64
    inc i
    
  result = sum
    
proc initImageFilterKaiser*(b = 6.33): ImageFilterKaiser =
  result.a = b
  result.epsilon = 1e-12
  result.i0a = 1.0 / result.bessel_i0(b)

proc radius*(self: ImageFilterKaiser): float64 = 1.0

proc calcWeight*(self: ImageFilterKaiser, x: float64): float64 =
  result = self.bessel_i0(self.a * sqrt(1.0 - x * x)) * self.i0a

type 
  ImageFilterCatrom* = object
  
proc radius*(self: ImageFilterCatrom): float64 = 2.0

proc calcWeight*(self: ImageFilterCatrom, x: float64): float64 =
  if x <  1.0: return 0.5 * (2.0 + x * x * (-5.0 + x * 3.0))
  if x <  2.0: return 0.5 * (4.0 + x * (-8.0 + x * (5.0 - x)))
  return 0.0

type 
  ImageFilterMitchell* = object
    p0, p2, p3: float64
    q0, q1, q2, q3: float64

const 
  onethird = 1.0 / 3.0
  
proc initImageFilterMitchell*(b = onethird, c = onethird): ImageFilterMitchell =
  result.p0 = (6.0 - 2.0 * b) / 6.0
  result.p2 = (-18.0 + 12.0 * b + 6.0 * c) / 6.0
  result.p3 = (12.0 - 9.0 * b - 6.0 * c) / 6.0
  result.q0 = (8.0 * b + 24.0 * c) / 6.0
  result.q1 = (-12.0 * b - 48.0 * c) / 6.0
  result.q2 = (6.0 * b + 30.0 * c) / 6.0
  result.q3 = (-b - 6.0 * c) / 6.0

proc radius*(self: ImageFilterMitchell): float64 =  2.0

proc calcWeight*(self: ImageFilterMitchell, x: float64): float64 =
  if x < 1.0: return self.p0 + x * x * (self.p2 + x * self.p3)
  if x < 2.0: return self.q0 + x * (self.q1 + x * (self.q2 + x * self.q3))
  result = 0.0

type 
  ImageFilterSpline16* = object
  
proc radius*(self: ImageFilterSpline16): float64 = 2.0

proc calcWeight*(self: ImageFilterSpline16, x: float64): float64 =
  if x < 1.0:
    return ((x - 9.0/5.0 ) * x - 1.0/5.0 ) * x + 1.0;
  
  result = ((-1.0/3.0 * (x-1) + 4.0/5.0) * (x-1) - 7.0/15.0 ) * (x-1)

type 
  ImageFilterSpline36* = object
  
proc radius*(self: ImageFilterSpline36): float64 = 3.0

proc calcWeight*(self: ImageFilterSpline36, x: float64): float64 =
  if x < 1.0:
    return ((13.0/11.0 * x - 453.0/209.0) * x - 3.0/209.0) * x + 1.0
    
  if x < 2.0:
    return ((-6.0/11.0 * (x-1) + 270.0/209.0) * (x-1) - 156.0/ 209.0) * (x-1)
  
  result = ((1.0/11.0 * (x-2) - 45.0/209.0) * (x-2) +  26.0/209.0) * (x-2)


type 
  ImageFilterGaussian* = object
  
proc radius*(self: ImageFilterGaussian): float64 = 2.0

proc calcWeight*(self: ImageFilterGaussian, x: float64): float64 =
  result = exp(-2.0 * x * x) * sqrt(2.0 / pi)

type 
  ImageFilterBessel* = object
  
proc radius*(self: ImageFilterBessel): float64 = 3.2383

proc calcWeight*(self: ImageFilterBessel, x: float64): float64 =
  result = if x == 0.0: pi / 4.0 else: besj(pi * x, 1) / (2.0 * x)

type 
  ImageFilterSinc* = object
    mRadius: float64

proc initImageFilterSinc*(r: float64): ImageFilterSinc =
  result.mRadius = if r < 2.0: 2.0 else: r
  
proc radius*(self: ImageFilterSinc): float64 = self.mRadius
proc calcWeight*(self: ImageFilterSinc, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  x *= pi
  result = sin(x) / x

type 
  ImageFilterLanczos* = object
    mRadius: float64

proc initImageFilterLanczos*(r: float64): ImageFilterLanczos =
  result.mRadius = if r < 2.0: 2.0 else: r
  
proc radius*(self: ImageFilterLanczos): float64 = self.mRadius
proc calcWeight*(self: ImageFilterLanczos, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  if x > self.mRadius: return 0.0
  x *= pi
  let xr = x / self.mRadius
  result = (sin(x) / x) * (sin(xr) / xr)

type 
  ImageFilterBlackman* = object
    mRadius: float64

proc initImageFilterBlackman*(r: float64): ImageFilterBlackman =
  result.mRadius = if r < 2.0: 2.0 else: r
  
proc radius*(self: ImageFilterBlackman): float64 = self.mRadius
proc calcWeight*(self: ImageFilterBlackman, x: float64): float64 =
  var x = x
  if x == 0.0: return 1.0
  if x > self.mRadius: return 0.0
  x *= pi
  let xr = x / self.mRadius
  result = (sin(x) / x) * (0.42 + 0.5*cos(xr) + 0.08*cos(2*xr))

proc ImageFiltersinc36*(): ImageFilterSinc =
  result = initImageFilterSinc(3.0)

proc ImageFiltersinc64*(): ImageFilterSinc =
  result = initImageFilterSinc(4.0)

proc ImageFiltersinc100*(): ImageFilterSinc =
  result = initImageFilterSinc(5.0)

proc ImageFiltersinc144*(): ImageFilterSinc =
  result = initImageFilterSinc(6.0)

proc ImageFiltersinc196*(): ImageFilterSinc =
  result = initImageFilterSinc(7.0)

proc ImageFiltersinc256*(): ImageFilterSinc =
  result = initImageFilterSinc(8.0)

proc ImageFilterLanczos36*(): ImageFilterLanczos =
  result = initImageFilterLanczos(3.0)

proc ImageFilterLanczos64*(): ImageFilterLanczos =
  result = initImageFilterLanczos(4.0)

proc ImageFilterLanczos100*(): ImageFilterLanczos =
  result = initImageFilterLanczos(5.0)

proc ImageFilterLanczos144*(): ImageFilterLanczos =
  result = initImageFilterLanczos(6.0)

proc ImageFilterLanczos196*(): ImageFilterLanczos =
  result = initImageFilterLanczos(7.0)

proc ImageFilterLanczos256*(): ImageFilterLanczos =
  result = initImageFilterLanczos(8.0)

proc ImageFilterBlackman36*(): ImageFilterBlackman =
  result = initImageFilterBlackman(3.0)

proc ImageFilterBlackman64*(): ImageFilterBlackman =
  result = initImageFilterBlackman(4.0)

proc ImageFilterBlackman100*(): ImageFilterBlackman =
  result = initImageFilterBlackman(5.0)

proc ImageFilterBlackman144*(): ImageFilterBlackman =
  result = initImageFilterBlackman(6.0)

proc ImageFilterBlackman196*(): ImageFilterBlackman =
  result = initImageFilterBlackman(7.0)

proc ImageFilterBlackman256*(): ImageFilterBlackman =
  result = initImageFilterBlackman(8.0)
