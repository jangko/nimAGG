import agg_basics, agg_math, math

const
  gradientSubpixelShift = 4
  gradientSubpixelScale = 1 shl gradientSubpixelShift
  gradientSubpixelMask  = gradientSubpixelScale - 1

template spanGradient*(name: untyped, ColorT, Interpolator, GradientF, ColorF: typed) =
  type
    name* = object
      mInterpolator: ptr Interpolator
      mGradientF: ptr GradientF
      mColorF: ptr ColorF
      mD1, mD2: int

  template getDownscaleShift*(x: typedesc[name]): int = (getSubPixelShift(Interpolator) - gradientSubpixelShift)
    
  proc `init name`*(inter: var Interpolator, gradientF: var GradientF,
    colorF: var ColorF, d1, d2: float64): name =
    
    result.mInterpolator = inter.addr
    result.mGradientF = gradientF.addr
    result.mColorF = colorF.addr
    result.mD1 = iround(d1 * gradientSubpixelScale)
    result.mD2 = iround(d2 * gradientSubpixelScale)

  proc interpolator*(self: name): var Interpolator = self.mInterpolator[]
  proc gradientFunction*(self: name): var GradientF = self.mGradientF[]
  proc colorFunction*(self: name): var ColorF = self.mColorF[]
  proc d1*(self: name): float64 = float64(self.mD1) / gradientSubpixelScale
  proc d2*(self: name): float64 = float64(self.mD2) / gradientSubpixelScale

  proc interpolator*(self: var name, i: var Interpolator) = self.mInterpolator = i.addr
  proc gradientFunction*(self: var name, gf: var GradientF) = self.mGradientF = gf.addr
  proc colorFunction*(self: var name, cf: var ColorF) = self.mColorF = cf.addr
  proc d1*(self: var name, v: float64) = self.mD1 = iround(v * gradientSubpixelScale)
  proc d2*(self: var name, v: float64) = self.mD2 = iround(v * gradientSubpixelScale)

  proc prepare*(self: name) = discard

  proc generate*(self: var name, spanx: ptr ColorT, xx, yy, lenx: int) =
    const downScaleShift = getDownscaleShift(name)
    var 
      dd = self.mD2 - self.mD1
      x = xx
      y = yy
      span = spanx
      len = lenx
      
    if dd < 1: dd = 1
    self.mInterpolator[].begin(x.float64+0.5, y.float64+0.5, len)
    
    doWhile len != 0:
      self.mInterpolator[].coordinates(x, y)
      var d = self.mGradientF[].calculate(x shr downScaleShift, y shr downScaleShift, self.mD2)
      d = ((d - self.mD1) * self.mColorF[].len) div dd
      if d < 0: d = 0
      if d >= self.mColorF[].len: d = self.mColorF[].len - 1
      span[] = self.mColorF[][d]
      inc span
      inc self.mInterpolator[]
      dec len

#[    



[ColorT> 
struct gradient_linear_color
    typedef ColorT ColorT;

    gradient_linear_color() {}
    gradient_linear_color(c: ColorT1, c: ColorT2, 
                          unsigned size = 256) :
        m_c1(c1), m_c2(c2), m_size(size) {}

    unsigned size(): float64 = m_size
    ColorT operator [] (unsigned v) const 
    {
        return m_c1.gradient(m_c2, double(v) / double(m_size - 1))
    }

proc colors(c: ColorT1, c: ColorT2, unsigned size = 256)
    {
        m_c1 = c1;
        m_c2 = c2;
        m_size = size;
    }

    ColorT m_c1;
    ColorT m_c2;
    unsigned m_size;






class gradient_circle
    # Actually the same as radial. Just for compatibility
    static AGG_INLINE int calculate(x, y: int, int)
    {
        return int(fast_sqrt(x*x + y*y))
    }


class gradient_radial
    static AGG_INLINE int calculate(x, y: int, int)
    {
        return int(fast_sqrt(x*x + y*y))
    }

class gradient_radial_d
    static AGG_INLINE int calculate(x, y: int, int)
    {
        return uround(sqrt(double(x)*double(x) + double(y)*double(y)))
    }

class gradient_radial_focus
    #---------------------------------------------------------------------
    gradient_radial_focus() : 
        m_r(100 * gradientSubpixelScale), 
        m_fx(0), 
        m_fy(0)
    {
        update_values()
    }

    #---------------------------------------------------------------------
    gradient_radial_focus(double r, double fx, double fy) : 
        m_r (iround(r  * gradientSubpixelScale)), 
        m_fx(iround(fx * gradientSubpixelScale)), 
        m_fy(iround(fy * gradientSubpixelScale))
    {
        update_values()
    }

    #---------------------------------------------------------------------
proc init(double r, double fx, double fy)
    {
        m_r  = iround(r  * gradientSubpixelScale)
        m_fx = iround(fx * gradientSubpixelScale)
        m_fy = iround(fy * gradientSubpixelScale)
        update_values()
    }

    #---------------------------------------------------------------------
    double radius()  const { return double(m_r)  / gradientSubpixelScale
    double focus_x(): float64 = double(m_fx) / gradientSubpixelScale
    double focus_y(): float64 = double(m_fy) / gradientSubpixelScale

    #---------------------------------------------------------------------
    int calculate(x, y: int, int) const
    {
        double dx = x - m_fx;
        double dy = y - m_fy;
        double d2 = dx * m_fy - dy * m_fx;
        double d3 = m_r2 * (dx * dx + dy * dy) - d2 * d2;
        return iround((dx * m_fx + dy * m_fy + sqrt(abs(d3))) * m_mul)
    }

private:
    #---------------------------------------------------------------------
proc update_values()
    {
        # Calculate the invariant values. In of the focal center
        # lies exactly on the gradient circle the divisor degenerates
        # into zero. In this of we just move the focal center by
        # one subpixel unit possibly in the direction to the origin (0,0)
        # and calculate the values again.
        #-------------------------
        m_r2  = double(m_r)  * double(m_r)
        m_fx2 = double(m_fx) * double(m_fx)
        m_fy2 = double(m_fy) * double(m_fy)
        double d = (m_r2 - (m_fx2 + m_fy2))
        if d == 0:
        {
            if m_fx) { if m_fx < 0) ++m_fx; else --m_fx
            if m_fy) { if m_fy < 0) ++m_fy; else --m_fy
            m_fx2 = double(m_fx) * double(m_fx)
            m_fy2 = double(m_fy) * double(m_fy)
            d = (m_r2 - (m_fx2 + m_fy2))
        }
        m_mul = m_r / d;
    }

    int    m_r;
    int    m_fx;
    int    m_fy;
    double m_r2;
    double m_fx2;
    double m_fy2;
    double m_mul;
]#

type
  GradientX* = object
  
proc initGradientX*(): GradientX = discard
proc calculate*(self: GradientX, x, y, d: int): int = x

#[
class gradient_y
    static int calculate(int, int y, int) { return y

class gradient_diamond
    static AGG_INLINE int calculate(x, y: int, int) 
    { 
        int ax = abs(x)
        int ay = abs(y)
        return ax > ay ? ax : ay; 
    }

class gradient_xy
    static AGG_INLINE int calculate(x, y: int, int d) 
    { 
        return abs(x) * abs(y) / d; 
    }

class gradient_sqrt_xy
    static AGG_INLINE int calculate(x, y: int, int) 
    { 
        return fast_sqrt(abs(x) * abs(y)) 
    }

class gradient_conic
    static AGG_INLINE int calculate(x, y: int, int d) 
    { 
        return uround(abs(atan2(double(y), double(x))) * double(d) / pi)
    }

[GradientF> class gradient_repeat_adaptor
    gradient_repeat_adaptor(const GradientF& gradient) : 
        m_gradient(&gradient) {}

    AGG_INLINE int calculate(x, y: int, int d) const
    {
        int ret = m_gradient->calculate(x, y, d) % d;
        if ret < 0) ret += d;
        return ret;
    }

private:
    const GradientF* m_gradient;

[GradientF> class gradient_reflect_adaptor

const GradientF* m_gradient;
    gradient_reflect_adaptor(const GradientF& gradient) : 
        m_gradient(&gradient) {}

    AGG_INLINE int calculate(x, y: int, int d) const
    {
        int d2 = d shl 1;
        int ret = m_gradient->calculate(x, y, d) % d2;
        if ret <  0) ret += d2;
        if ret >= d) ret  = d2 - ret;
        return ret;
    }
]#




