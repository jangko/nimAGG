import agg_basics, agg_color_rgba, agg_rendering_buffer


proc multiplier_rgba_premultiply[ColorT, OrderT, ValueT](p: ptr ValueT) =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
    
  let a = CalcT(p[OrderT.A])
  if a < baseMask:
    if a == 0:
      p[OrderT.R] = 0
      p[OrderT.G] = 0
      p[OrderT.B] = 0
      return

    p[OrderT.R] = ValueT((p[OrderT.R].CalcT * a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((p[OrderT.G].CalcT * a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((p[OrderT.B].CalcT * a + baseMask) shr baseShift)

proc multiplier_rgba_demultiply[ColorT, OrderT, ValueT](p: ptr ValueT) =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = getBaseShift(ColorT)
  
  let a = CalcT(p[OrderT.A])
  if a < baseMask:
    if a == 0:
      p[OrderT.R] = 0
      p[OrderT.G] = 0
      p[OrderT.B] = 0
      return

    let r = (CalcT(p[OrderT.R]) * baseMask) div a
    let g = (CalcT(p[OrderT.G]) * baseMask) div a
    let b = (CalcT(p[OrderT.B]) * baseMask) div a
    p[OrderT.R] = ValueT(if r > baseMask: baseMask else: r)
    p[OrderT.G] = ValueT(if g > baseMask: baseMask else: g)
    p[OrderT.B] = ValueT(if b > baseMask: baseMask else: b)
    
  
#[

[ColorT, class OrderT, class GammaLut> class apply_gamma_dir_rgba
    typedef typename ColorT::ValueT ValueT;

    apply_gamma_dir_rgba(const GammaLut& gamma) : self.mGamma(gamma) {}

    AGG_INLINE void operator () (ValueT* p)
    {
        p[OrderT.R] = self.mGamma.dir(p[OrderT.R])
        p[OrderT.G] = self.mGamma.dir(p[OrderT.G])
        p[OrderT.B] = self.mGamma.dir(p[OrderT.B])
    }

private:
    const GammaLut& self.mGamma;

[ColorT, class OrderT, class GammaLut> class apply_gamma_inv_rgba
    typedef typename ColorT::ValueT ValueT;

    apply_gamma_inv_rgba(const GammaLut& gamma) : self.mGamma(gamma) {}

    AGG_INLINE void operator () (ValueT* p)
    {
        p[OrderT.R] = self.mGamma.inv(p[OrderT.R])
        p[OrderT.G] = self.mGamma.inv(p[OrderT.G])
        p[OrderT.B] = self.mGamma.inv(p[OrderT.B])
    }

private:
    const GammaLut& self.mGamma;


[ColorT, OrderT] struct blender_rgba
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    #--------------------------------------------------------------------
    static AGG_INLINE void blendPix(ValueT* p,
                                     cr, cg, cb: uint,
                                     alpha: uint,
                                     cover: uint=0)
    {
        CalcT r = p[OrderT.R];
        CalcT g = p[OrderT.G];
        CalcT b = p[OrderT.B];
        CalcT a = p[OrderT.A];
        p[OrderT.R] = (ValueT)(((cr - r) * alpha + (r shl baseShift)) shr baseShift)
        p[OrderT.G] = (ValueT)(((cg - g) * alpha + (g shl baseShift)) shr baseShift)
        p[OrderT.B] = (ValueT)(((cb - b) * alpha + (b shl baseShift)) shr baseShift)
        p[OrderT.A] = (ValueT)((alpha + a) - ((alpha * a + baseMask) shr baseShift))
    }

[ColorT, OrderT] struct blender_rgba_pre
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    #--------------------------------------------------------------------
    static AGG_INLINE void blendPix(ValueT* p,
                                     cr, cg, cb: uint,
                                     alpha: uint,
                                     cover: uint)
    {
        alpha = baseMask - alpha;
        cover = (cover + 1) shl (baseShift - 8)
        p[OrderT.R] = (ValueT)((p[OrderT.R] * alpha + cr * cover) shr baseShift)
        p[OrderT.G] = (ValueT)((p[OrderT.G] * alpha + cg * cover) shr baseShift)
        p[OrderT.B] = (ValueT)((p[OrderT.B] * alpha + cb * cover) shr baseShift)
        p[OrderT.A] = (ValueT)(baseMask - ((alpha * (baseMask - p[OrderT.A])) shr baseShift))
    }

    #--------------------------------------------------------------------
    static AGG_INLINE void blendPix(ValueT* p,
                                     cr, cg, cb: uint,
                                     alpha: uint)
    {
        alpha = baseMask - alpha;
        p[OrderT.R] = (ValueT)(((p[OrderT.R] * alpha) shr baseShift) + cr)
        p[OrderT.G] = (ValueT)(((p[OrderT.G] * alpha) shr baseShift) + cg)
        p[OrderT.B] = (ValueT)(((p[OrderT.B] * alpha) shr baseShift) + cb)
        p[OrderT.A] = (ValueT)(baseMask - ((alpha * (baseMask - p[OrderT.A])) shr baseShift))
    }

[ColorT, OrderT] struct blender_rgba_plain
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e { baseShift = baseShift };

    #--------------------------------------------------------------------
    static AGG_INLINE void blendPix(ValueT* p,
                                     cr, cg, cb: uint,
                                     alpha: uint,
                                     cover: uint=0)
    {
        if alpha == 0: return;
        CalcT a = p[OrderT.A];
        CalcT r = p[OrderT.R] * a;
        CalcT g = p[OrderT.G] * a;
        CalcT b = p[OrderT.B] * a;
        a = ((alpha + a) shl baseShift) - alpha * a;
        p[OrderT.A] = (ValueT)(a shr baseShift)
        p[OrderT.R] = (ValueT)((((cr shl baseShift) - r) * alpha + (r shl baseShift)) / a)
        p[OrderT.G] = (ValueT)((((cg shl baseShift) - g) * alpha + (g shl baseShift)) / a)
        p[OrderT.B] = (ValueT)((((cb shl baseShift) - b) * alpha + (b shl baseShift)) / a)
    }



[ColorT, OrderT] struct comp_op_rgba_clear
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(ValueT* p,
                                     unsigned, unsigned, unsigned, unsigned,
                                     cover: uint)
    {
        if cover < 255)
        {
            cover = 255 - cover;
            p[OrderT.R] = (ValueT)((p[OrderT.R] * cover + 255) shr 8)
            p[OrderT.G] = (ValueT)((p[OrderT.G] * cover + 255) shr 8)
            p[OrderT.B] = (ValueT)((p[OrderT.B] * cover + 255) shr 8)
            p[OrderT.A] = (ValueT)((p[OrderT.A] * cover + 255) shr 8)
        }
        else:
        {
            p[0] = p[1] = p[2] = p[3] = 0;
        }
    }

[ColorT, OrderT] struct comp_op_rgba_src
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;

    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            alpha: uint = 255 - cover;
            p[OrderT.R] = (ValueT)(((p[OrderT.R] * alpha + 255) shr 8) + ((sr * cover + 255) shr 8))
            p[OrderT.G] = (ValueT)(((p[OrderT.G] * alpha + 255) shr 8) + ((sg * cover + 255) shr 8))
            p[OrderT.B] = (ValueT)(((p[OrderT.B] * alpha + 255) shr 8) + ((sb * cover + 255) shr 8))
            p[OrderT.A] = (ValueT)(((p[OrderT.A] * alpha + 255) shr 8) + ((sa * cover + 255) shr 8))
        }
        else:
        {
            p[OrderT.R] = sr;
            p[OrderT.G] = sg;
            p[OrderT.B] = sb;
            p[OrderT.A] = sa;
        }
    }

[ColorT, OrderT] struct comp_op_rgba_dst
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;

    static AGG_INLINE void blendPix(ValueT*,
                                     unsigned, unsigned, unsigned,
                                     unsigned, unsigned)
    {
    }

[ColorT, OrderT] struct comp_op_rgba_src_over
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    #   Dca' = Sca + Dca.(1 - Sa)
    #   Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        CalcT s1a = baseMask - sa;
        p[OrderT.R] = (ValueT)(sr + ((p[OrderT.R] * s1a + baseMask) shr baseShift))
        p[OrderT.G] = (ValueT)(sg + ((p[OrderT.G] * s1a + baseMask) shr baseShift))
        p[OrderT.B] = (ValueT)(sb + ((p[OrderT.B] * s1a + baseMask) shr baseShift))
        p[OrderT.A] = (ValueT)(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))
    }

[ColorT, OrderT] struct comp_op_rgba_dst_over
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Dca + Sca.(1 - Da)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        CalcT d1a = baseMask - p[OrderT.A];
        p[OrderT.R] = (ValueT)(p[OrderT.R] + ((sr * d1a + baseMask) shr baseShift))
        p[OrderT.G] = (ValueT)(p[OrderT.G] + ((sg * d1a + baseMask) shr baseShift))
        p[OrderT.B] = (ValueT)(p[OrderT.B] + ((sb * d1a + baseMask) shr baseShift))
        p[OrderT.A] = (ValueT)(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))
    }

[ColorT, OrderT] struct comp_op_rgba_src_in
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca.Da
    # Da'  = Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        CalcT da = p[OrderT.A];
        if cover < 255)
        {
            alpha: uint = 255 - cover;
            p[OrderT.R] = (ValueT)(((p[OrderT.R] * alpha + 255) shr 8) + ((((sr * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.G] = (ValueT)(((p[OrderT.G] * alpha + 255) shr 8) + ((((sg * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.B] = (ValueT)(((p[OrderT.B] * alpha + 255) shr 8) + ((((sb * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.A] = (ValueT)(((p[OrderT.A] * alpha + 255) shr 8) + ((((sa * da + baseMask) shr baseShift) * cover + 255) shr 8))
        }
        else:
        {
            p[OrderT.R] = (ValueT)((sr * da + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sg * da + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sb * da + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)((sa * da + baseMask) shr baseShift)
        }
    }

[ColorT, OrderT] struct comp_op_rgba_dst_in
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Dca.Sa
    # Da'  = Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     unsigned, unsigned, unsigned,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sa = baseMask - ((cover * (baseMask - sa) + 255) shr 8)
        }
        p[OrderT.R] = (ValueT)((p[OrderT.R] * sa + baseMask) shr baseShift)
        p[OrderT.G] = (ValueT)((p[OrderT.G] * sa + baseMask) shr baseShift)
        p[OrderT.B] = (ValueT)((p[OrderT.B] * sa + baseMask) shr baseShift)
        p[OrderT.A] = (ValueT)((p[OrderT.A] * sa + baseMask) shr baseShift)
    }

[ColorT, OrderT] struct comp_op_rgba_src_out
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca.(1 - Da)
    # Da'  = Sa.(1 - Da)
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        CalcT da = baseMask - p[OrderT.A];
        if cover < 255)
        {
            alpha: uint = 255 - cover;
            p[OrderT.R] = (ValueT)(((p[OrderT.R] * alpha + 255) shr 8) + ((((sr * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.G] = (ValueT)(((p[OrderT.G] * alpha + 255) shr 8) + ((((sg * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.B] = (ValueT)(((p[OrderT.B] * alpha + 255) shr 8) + ((((sb * da + baseMask) shr baseShift) * cover + 255) shr 8))
            p[OrderT.A] = (ValueT)(((p[OrderT.A] * alpha + 255) shr 8) + ((((sa * da + baseMask) shr baseShift) * cover + 255) shr 8))
        }
        else:
        {
            p[OrderT.R] = (ValueT)((sr * da + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sg * da + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sb * da + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)((sa * da + baseMask) shr baseShift)
        }
    }

[ColorT, OrderT] struct comp_op_rgba_dst_out
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Dca.(1 - Sa)
    # Da'  = Da.(1 - Sa)
    static AGG_INLINE void blendPix(ValueT* p,
                                     unsigned, unsigned, unsigned,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sa = (sa * cover + 255) shr 8;
        }
        sa = baseMask - sa;
        p[OrderT.R] = (ValueT)((p[OrderT.R] * sa + baseShift) shr baseShift)
        p[OrderT.G] = (ValueT)((p[OrderT.G] * sa + baseShift) shr baseShift)
        p[OrderT.B] = (ValueT)((p[OrderT.B] * sa + baseShift) shr baseShift)
        p[OrderT.A] = (ValueT)((p[OrderT.A] * sa + baseShift) shr baseShift)
    }

[ColorT, OrderT] struct comp_op_rgba_src_atop
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca.Da + Dca.(1 - Sa)
    # Da'  = Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        CalcT da = p[OrderT.A];
        sa = baseMask - sa;
        p[OrderT.R] = (ValueT)((sr * da + p[OrderT.R] * sa + baseMask) shr baseShift)
        p[OrderT.G] = (ValueT)((sg * da + p[OrderT.G] * sa + baseMask) shr baseShift)
        p[OrderT.B] = (ValueT)((sb * da + p[OrderT.B] * sa + baseMask) shr baseShift)
    }

[ColorT, OrderT] struct comp_op_rgba_dst_atop
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Dca.Sa + Sca.(1 - Da)
    # Da'  = Sa
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        CalcT da = baseMask - p[OrderT.A];
        if cover < 255)
        {
            alpha: uint = 255 - cover;
            sr = (p[OrderT.R] * sa + sr * da + baseMask) shr baseShift;
            sg = (p[OrderT.G] * sa + sg * da + baseMask) shr baseShift;
            sb = (p[OrderT.B] * sa + sb * da + baseMask) shr baseShift;
            p[OrderT.R] = (ValueT)(((p[OrderT.R] * alpha + 255) shr 8) + ((sr * cover + 255) shr 8))
            p[OrderT.G] = (ValueT)(((p[OrderT.G] * alpha + 255) shr 8) + ((sg * cover + 255) shr 8))
            p[OrderT.B] = (ValueT)(((p[OrderT.B] * alpha + 255) shr 8) + ((sb * cover + 255) shr 8))
            p[OrderT.A] = (ValueT)(((p[OrderT.A] * alpha + 255) shr 8) + ((sa * cover + 255) shr 8))

        }
        else:
        {
            p[OrderT.R] = (ValueT)((p[OrderT.R] * sa + sr * da + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((p[OrderT.G] * sa + sg * da + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((p[OrderT.B] * sa + sb * da + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)sa;
        }
    }

[ColorT, OrderT] struct comp_op_rgba_xor
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca.(1 - Da) + Dca.(1 - Sa)
    # Da'  = Sa + Da - 2.Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT s1a = baseMask - sa;
            CalcT d1a = baseMask - p[OrderT.A];
            p[OrderT.R] = (ValueT)((p[OrderT.R] * s1a + sr * d1a + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((p[OrderT.G] * s1a + sg * d1a + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((p[OrderT.B] * s1a + sb * d1a + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask/2) shr (baseShift - 1)))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_plus
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca + Dca
    # Da'  = Sa + Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT dr = p[OrderT.R] + sr;
            CalcT dg = p[OrderT.G] + sg;
            CalcT db = p[OrderT.B] + sb;
            CalcT da = p[OrderT.A] + sa;
            p[OrderT.R] = (dr > baseMask: (ValueT)baseMask : dr;
            p[OrderT.G] = (dg > baseMask: (ValueT)baseMask : dg;
            p[OrderT.B] = (db > baseMask: (ValueT)baseMask : db;
            p[OrderT.A] = (da > baseMask: (ValueT)baseMask : da;
        }
    }

[ColorT, OrderT] struct comp_op_rgba_minus
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Dca - Sca
    # Da' = 1 - (1 - Sa).(1 - Da)
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT dr = p[OrderT.R] - sr;
            CalcT dg = p[OrderT.G] - sg;
            CalcT db = p[OrderT.B] - sb;
            p[OrderT.R] = (dr > baseMask: 0 : dr;
            p[OrderT.G] = (dg > baseMask: 0 : dg;
            p[OrderT.B] = (db > baseMask: 0 : db;
            p[OrderT.A] = (ValueT)(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))
            #p[OrderT.A] = (ValueT)(baseMask - (((baseMask - sa) * (baseMask - p[OrderT.A]) + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_multiply
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT s1a = baseMask - sa;
            CalcT d1a = baseMask - p[OrderT.A];
            CalcT dr = p[OrderT.R];
            CalcT dg = p[OrderT.G];
            CalcT db = p[OrderT.B];
            p[OrderT.R] = (ValueT)((sr * dr + sr * d1a + dr * s1a + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sg * dg + sg * d1a + dg * s1a + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sb * db + sb * d1a + db * s1a + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_screen
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = Sca + Dca - Sca.Dca
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT dr = p[OrderT.R];
            CalcT dg = p[OrderT.G];
            CalcT db = p[OrderT.B];
            CalcT da = p[OrderT.A];
            p[OrderT.R] = (ValueT)(sr + dr - ((sr * dr + baseMask) shr baseShift))
            p[OrderT.G] = (ValueT)(sg + dg - ((sg * dg + baseMask) shr baseShift))
            p[OrderT.B] = (ValueT)(sb + db - ((sb * db + baseMask) shr baseShift))
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_overlay
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # if 2.Dca < Da
    #   Dca' = 2.Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise
    #   Dca' = Sa.Da - 2.(Da - Dca).(Sa - Sca) + Sca.(1 - Da) + Dca.(1 - Sa)
    #
    # Da' = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a  = baseMask - p[OrderT.A];
            CalcT s1a  = baseMask - sa;
            CalcT dr   = p[OrderT.R];
            CalcT dg   = p[OrderT.G];
            CalcT db   = p[OrderT.B];
            CalcT da   = p[OrderT.A];
            CalcT sada = sa * p[OrderT.A];

            p[OrderT.R] = (ValueT)(((2*dr < da:
                2*sr*dr + sr*d1a + dr*s1a :
                sada - 2*(da - dr)*(sa - sr) + sr*d1a + dr*s1a + baseMask) shr baseShift)

            p[OrderT.G] = (ValueT)(((2*dg < da:
                2*sg*dg + sg*d1a + dg*s1a :
                sada - 2*(da - dg)*(sa - sg) + sg*d1a + dg*s1a + baseMask) shr baseShift)

            p[OrderT.B] = (ValueT)(((2*db < da:
                2*sb*db + sb*d1a + db*s1a :
                sada - 2*(da - db)*(sa - sb) + sb*d1a + db*s1a + baseMask) shr baseShift)

            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }


[T> inline T sd_min(T a, T b) = return (a < b: a : b
[T> inline T sd_max(T a, T b) = return (a > b: a : b

[ColorT, OrderT] struct comp_op_rgba_darken
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = min(Sca.Da, Dca.Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a = baseMask - p[OrderT.A];
            CalcT s1a = baseMask - sa;
            CalcT dr  = p[OrderT.R];
            CalcT dg  = p[OrderT.G];
            CalcT db  = p[OrderT.B];
            CalcT da  = p[OrderT.A];

            p[OrderT.R] = (ValueT)((sd_min(sr * da, dr * sa) + sr * d1a + dr * s1a + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sd_min(sg * da, dg * sa) + sg * d1a + dg * s1a + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sd_min(sb * da, db * sa) + sb * d1a + db * s1a + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_lighten
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = max(Sca.Da, Dca.Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a = baseMask - p[OrderT.A];
            CalcT s1a = baseMask - sa;
            CalcT dr  = p[OrderT.R];
            CalcT dg  = p[OrderT.G];
            CalcT db  = p[OrderT.B];
            CalcT da  = p[OrderT.A];

            p[OrderT.R] = (ValueT)((sd_max(sr * da, dr * sa) + sr * d1a + dr * s1a + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sd_max(sg * da, dg * sa) + sg * d1a + dg * s1a + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sd_max(sb * da, db * sa) + sb * d1a + db * s1a + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_color_dodge
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # if Sca.Da + Dca.Sa >= Sa.Da
    #   Dca' = Sa.Da + Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise
    #   Dca' = Dca.Sa/(1-Sca/Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
    #
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a  = baseMask - p[OrderT.A];
            CalcT s1a  = baseMask - sa;
            CalcT dr   = p[OrderT.R];
            CalcT dg   = p[OrderT.G];
            CalcT db   = p[OrderT.B];
            CalcT da   = p[OrderT.A];
            long_type drsa = dr * sa;
            long_type dgsa = dg * sa;
            long_type dbsa = db * sa;
            long_type srda = sr * da;
            long_type sgda = sg * da;
            long_type sbda = sb * da;
            long_type sada = sa * da;

            p[OrderT.R] = (ValueT)((srda + drsa >= sada:
                (sada + sr * d1a + dr * s1a + baseMask) shr baseShift :
                drsa / (baseMask - (sr shl baseShift) / sa) + ((sr * d1a + dr * s1a + baseMask) shr baseShift))

            p[OrderT.G] = (ValueT)((sgda + dgsa >= sada:
                (sada + sg * d1a + dg * s1a + baseMask) shr baseShift :
                dgsa / (baseMask - (sg shl baseShift) / sa) + ((sg * d1a + dg * s1a + baseMask) shr baseShift))

            p[OrderT.B] = (ValueT)((sbda + dbsa >= sada:
                (sada + sb * d1a + db * s1a + baseMask) shr baseShift :
                dbsa / (baseMask - (sb shl baseShift) / sa) + ((sb * d1a + db * s1a + baseMask) shr baseShift))

            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_color_burn
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # if Sca.Da + Dca.Sa <= Sa.Da
    #   Dca' = Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise
    #   Dca' = Sa.(Sca.Da + Dca.Sa - Sa.Da)/Sca + Sca.(1 - Da) + Dca.(1 - Sa)
    #
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a  = baseMask - p[OrderT.A];
            CalcT s1a  = baseMask - sa;
            CalcT dr   = p[OrderT.R];
            CalcT dg   = p[OrderT.G];
            CalcT db   = p[OrderT.B];
            CalcT da   = p[OrderT.A];
            long_type drsa = dr * sa;
            long_type dgsa = dg * sa;
            long_type dbsa = db * sa;
            long_type srda = sr * da;
            long_type sgda = sg * da;
            long_type sbda = sb * da;
            long_type sada = sa * da;

            p[OrderT.R] = (ValueT)(((srda + drsa <= sada:
                sr * d1a + dr * s1a :
                sa * (srda + drsa - sada) / sr + sr * d1a + dr * s1a + baseMask) shr baseShift)

            p[OrderT.G] = (ValueT)(((sgda + dgsa <= sada:
                sg * d1a + dg * s1a :
                sa * (sgda + dgsa - sada) / sg + sg * d1a + dg * s1a + baseMask) shr baseShift)

            p[OrderT.B] = (ValueT)(((sbda + dbsa <= sada:
                sb * d1a + db * s1a :
                sa * (sbda + dbsa - sada) / sb + sb * d1a + db * s1a + baseMask) shr baseShift)

            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_hard_light
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # if 2.Sca < Sa
    #    Dca' = 2.Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise
    #    Dca' = Sa.Da - 2.(Da - Dca).(Sa - Sca) + Sca.(1 - Da) + Dca.(1 - Sa)
    #
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a  = baseMask - p[OrderT.A];
            CalcT s1a  = baseMask - sa;
            CalcT dr   = p[OrderT.R];
            CalcT dg   = p[OrderT.G];
            CalcT db   = p[OrderT.B];
            CalcT da   = p[OrderT.A];
            CalcT sada = sa * da;

            p[OrderT.R] = (ValueT)(((2*sr < sa:
                2*sr*dr + sr*d1a + dr*s1a :
                sada - 2*(da - dr)*(sa - sr) + sr*d1a + dr*s1a + baseMask) shr baseShift)

            p[OrderT.G] = (ValueT)(((2*sg < sa:
                2*sg*dg + sg*d1a + dg*s1a :
                sada - 2*(da - dg)*(sa - sg) + sg*d1a + dg*s1a + baseMask) shr baseShift)

            p[OrderT.B] = (ValueT)(((2*sb < sa:
                2*sb*db + sb*d1a + db*s1a :
                sada - 2*(da - db)*(sa - sb) + sb*d1a + db*s1a + baseMask) shr baseShift)

            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_soft_light
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # if 2.Sca < Sa
    #   Dca' = Dca.(Sa + (1 - Dca/Da).(2.Sca - Sa)) + Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise if 8.Dca <= Da
    #   Dca' = Dca.(Sa + (1 - Dca/Da).(2.Sca - Sa).(3 - 8.Dca/Da)) + Sca.(1 - Da) + Dca.(1 - Sa)
    # otherwise
    #   Dca' = (Dca.Sa + ((Dca/Da)^(0.5).Da - Dca).(2.Sca - Sa)) + Sca.(1 - Da) + Dca.(1 - Sa)
    #
    # Da'  = Sa + Da - Sa.Da

    static AGG_INLINE void blendPix(ValueT* p,
                                     unsigned r, unsigned g, unsigned b,
                                     unsigned a, cover: uint)
    {
        double sr = double(r * cover) / (baseMask * 255)
        double sg = double(g * cover) / (baseMask * 255)
        double sb = double(b * cover) / (baseMask * 255)
        double sa = double(a * cover) / (baseMask * 255)
        if sa > 0)
        {
            double dr = double(p[OrderT.R]) / baseMask;
            double dg = double(p[OrderT.G]) / baseMask;
            double db = double(p[OrderT.B]) / baseMask;
            double da = double(p[OrderT.A] ? p[OrderT.A] : 1) / baseMask;
            if cover < 255)
            {
                a = (a * cover + 255) shr 8;
            }

            if 2*sr < sa)       dr = dr*(sa + (1 - dr/da)*(2*sr - sa)) + sr*(1 - da) + dr*(1 - sa)
            else if 8*dr <= da) dr = dr*(sa + (1 - dr/da)*(2*sr - sa)*(3 - 8*dr/da)) + sr*(1 - da) + dr*(1 - sa)
            else                dr = (dr*sa + (sqrt(dr/da)*da - dr)*(2*sr - sa)) + sr*(1 - da) + dr*(1 - sa)

            if 2*sg < sa)       dg = dg*(sa + (1 - dg/da)*(2*sg - sa)) + sg*(1 - da) + dg*(1 - sa)
            else if 8*dg <= da) dg = dg*(sa + (1 - dg/da)*(2*sg - sa)*(3 - 8*dg/da)) + sg*(1 - da) + dg*(1 - sa)
            else                dg = (dg*sa + (sqrt(dg/da)*da - dg)*(2*sg - sa)) + sg*(1 - da) + dg*(1 - sa)

            if 2*sb < sa)       db = db*(sa + (1 - db/da)*(2*sb - sa)) + sb*(1 - da) + db*(1 - sa)
            else if 8*db <= da) db = db*(sa + (1 - db/da)*(2*sb - sa)*(3 - 8*db/da)) + sb*(1 - da) + db*(1 - sa)
            else                db = (db*sa + (sqrt(db/da)*da - db)*(2*sb - sa)) + sb*(1 - da) + db*(1 - sa)

            p[OrderT.R] = (ValueT)uround(dr * baseMask)
            p[OrderT.G] = (ValueT)uround(dg * baseMask)
            p[OrderT.B] = (ValueT)uround(db * baseMask)
            p[OrderT.A] = (ValueT)(a + p[OrderT.A] - ((a * p[OrderT.A] + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_difference
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        base_scale = ColorT::base_scale,
        baseMask  = baseMask
    };

    # Dca' = Sca + Dca - 2.min(Sca.Da, Dca.Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT dr = p[OrderT.R];
            CalcT dg = p[OrderT.G];
            CalcT db = p[OrderT.B];
            CalcT da = p[OrderT.A];
            p[OrderT.R] = (ValueT)(sr + dr - ((2 * sd_min(sr*da, dr*sa) + baseMask) shr baseShift))
            p[OrderT.G] = (ValueT)(sg + dg - ((2 * sd_min(sg*da, dg*sa) + baseMask) shr baseShift))
            p[OrderT.B] = (ValueT)(sb + db - ((2 * sd_min(sb*da, db*sa) + baseMask) shr baseShift))
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_exclusion
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = (Sca.Da + Dca.Sa - 2.Sca.Dca) + Sca.(1 - Da) + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT d1a = baseMask - p[OrderT.A];
            CalcT s1a = baseMask - sa;
            CalcT dr = p[OrderT.R];
            CalcT dg = p[OrderT.G];
            CalcT db = p[OrderT.B];
            CalcT da = p[OrderT.A];
            p[OrderT.R] = (ValueT)((sr*da + dr*sa - 2*sr*dr + sr*d1a + dr*s1a + baseMask) shr baseShift)
            p[OrderT.G] = (ValueT)((sg*da + dg*sa - 2*sg*dg + sg*d1a + dg*s1a + baseMask) shr baseShift)
            p[OrderT.B] = (ValueT)((sb*da + db*sa - 2*sb*db + sb*d1a + db*s1a + baseMask) shr baseShift)
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_contrast
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };


    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        long_type dr = p[OrderT.R];
        long_type dg = p[OrderT.G];
        long_type db = p[OrderT.B];
        int       da = p[OrderT.A];
        long_type d2a = da shr 1;
        unsigned s2a = sa shr 1;

        int r = (int)((((dr - d2a) * int((sr - s2a)*2 + baseMask)) shr baseShift) + d2a)
        int g = (int)((((dg - d2a) * int((sg - s2a)*2 + baseMask)) shr baseShift) + d2a)
        int b = (int)((((db - d2a) * int((sb - s2a)*2 + baseMask)) shr baseShift) + d2a)

        r = (r < 0: 0 : r;
        g = (g < 0: 0 : g;
        b = (b < 0: 0 : b;

        p[OrderT.R] = (ValueT)((r > da: da : r)
        p[OrderT.G] = (ValueT)((g > da: da : g)
        p[OrderT.B] = (ValueT)((b > da: da : b)
    }

[ColorT, OrderT] struct comp_op_rgba_invert
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = (Da - Dca) * Sa + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        sa = (sa * cover + 255) shr 8;
        if sa)
        {
            CalcT da = p[OrderT.A];
            CalcT dr = ((da - p[OrderT.R]) * sa + baseMask) shr baseShift;
            CalcT dg = ((da - p[OrderT.G]) * sa + baseMask) shr baseShift;
            CalcT db = ((da - p[OrderT.B]) * sa + baseMask) shr baseShift;
            CalcT s1a = baseMask - sa;
            p[OrderT.R] = (ValueT)(dr + ((p[OrderT.R] * s1a + baseMask) shr baseShift))
            p[OrderT.G] = (ValueT)(dg + ((p[OrderT.G] * s1a + baseMask) shr baseShift))
            p[OrderT.B] = (ValueT)(db + ((p[OrderT.B] * s1a + baseMask) shr baseShift))
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }

[ColorT, OrderT] struct comp_op_rgba_invert_rgb
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef typename ColorT::long_type long_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    # Dca' = (Da - Dca) * Sca + Dca.(1 - Sa)
    # Da'  = Sa + Da - Sa.Da
    static AGG_INLINE void blendPix(ValueT* p,
                                     sr, sg, sb: uint,
                                     sa: uint, cover: uint)
    {
        if cover < 255)
        {
            sr = (sr * cover + 255) shr 8;
            sg = (sg * cover + 255) shr 8;
            sb = (sb * cover + 255) shr 8;
            sa = (sa * cover + 255) shr 8;
        }
        if sa)
        {
            CalcT da = p[OrderT.A];
            CalcT dr = ((da - p[OrderT.R]) * sr + baseMask) shr baseShift;
            CalcT dg = ((da - p[OrderT.G]) * sg + baseMask) shr baseShift;
            CalcT db = ((da - p[OrderT.B]) * sb + baseMask) shr baseShift;
            CalcT s1a = baseMask - sa;
            p[OrderT.R] = (ValueT)(dr + ((p[OrderT.R] * s1a + baseMask) shr baseShift))
            p[OrderT.G] = (ValueT)(dg + ((p[OrderT.G] * s1a + baseMask) shr baseShift))
            p[OrderT.B] = (ValueT)(db + ((p[OrderT.B] * s1a + baseMask) shr baseShift))
            p[OrderT.A] = (ValueT)(sa + da - ((sa * da + baseMask) shr baseShift))
        }
    }





[ColorT, OrderT] struct comp_op_table_rgba
    typedef typename ColorT::ValueT ValueT;
    typedef void (*comp_op_func_type)(ValueT* p,
                                      unsigned cr,
                                      unsigned cg,
                                      unsigned cb,
                                      unsigned ca,
                                      cover: uint)
    static comp_op_func_type g_comp_op_func[];

[ColorT, OrderT]
typename comp_op_table_rgba<ColorT, OrderT>::comp_op_func_type
comp_op_table_rgba<ColorT, OrderT>::g_comp_op_func[] =
    comp_op_rgba_clear      <ColorT,OrderT>::blendPix,
    comp_op_rgba_src        <ColorT,OrderT>::blendPix,
    comp_op_rgba_dst        <ColorT,OrderT>::blendPix,
    comp_op_rgba_src_over   <ColorT,OrderT>::blendPix,
    comp_op_rgba_dst_over   <ColorT,OrderT>::blendPix,
    comp_op_rgba_src_in     <ColorT,OrderT>::blendPix,
    comp_op_rgba_dst_in     <ColorT,OrderT>::blendPix,
    comp_op_rgba_src_out    <ColorT,OrderT>::blendPix,
    comp_op_rgba_dst_out    <ColorT,OrderT>::blendPix,
    comp_op_rgba_src_atop   <ColorT,OrderT>::blendPix,
    comp_op_rgba_dst_atop   <ColorT,OrderT>::blendPix,
    comp_op_rgba_xor        <ColorT,OrderT>::blendPix,
    comp_op_rgba_plus       <ColorT,OrderT>::blendPix,
    comp_op_rgba_minus      <ColorT,OrderT>::blendPix,
    comp_op_rgba_multiply   <ColorT,OrderT>::blendPix,
    comp_op_rgba_screen     <ColorT,OrderT>::blendPix,
    comp_op_rgba_overlay    <ColorT,OrderT>::blendPix,
    comp_op_rgba_darken     <ColorT,OrderT>::blendPix,
    comp_op_rgba_lighten    <ColorT,OrderT>::blendPix,
    comp_op_rgba_color_dodge<ColorT,OrderT>::blendPix,
    comp_op_rgba_color_burn <ColorT,OrderT>::blendPix,
    comp_op_rgba_hard_light <ColorT,OrderT>::blendPix,
    comp_op_rgba_soft_light <ColorT,OrderT>::blendPix,
    comp_op_rgba_difference <ColorT,OrderT>::blendPix,
    comp_op_rgba_exclusion  <ColorT,OrderT>::blendPix,
    comp_op_rgba_contrast   <ColorT,OrderT>::blendPix,
    comp_op_rgba_invert     <ColorT,OrderT>::blendPix,
    comp_op_rgba_invert_rgb <ColorT,OrderT>::blendPix,
    0


enum comp_op_e
    comp_op_clear,         #----comp_op_clear
    comp_op_src,           #----comp_op_src
    comp_op_dst,           #----comp_op_dst
    comp_op_src_over,      #----comp_op_src_over
    comp_op_dst_over,      #----comp_op_dst_over
    comp_op_src_in,        #----comp_op_src_in
    comp_op_dst_in,        #----comp_op_dst_in
    comp_op_src_out,       #----comp_op_src_out
    comp_op_dst_out,       #----comp_op_dst_out
    comp_op_src_atop,      #----comp_op_src_atop
    comp_op_dst_atop,      #----comp_op_dst_atop
    comp_op_xor,           #----comp_op_xor
    comp_op_plus,          #----comp_op_plus
    comp_op_minus,         #----comp_op_minus
    comp_op_multiply,      #----comp_op_multiply
    comp_op_screen,        #----comp_op_screen
    comp_op_overlay,       #----comp_op_overlay
    comp_op_darken,        #----comp_op_darken
    comp_op_lighten,       #----comp_op_lighten
    comp_op_color_dodge,   #----comp_op_color_dodge
    comp_op_color_burn,    #----comp_op_color_burn
    comp_op_hard_light,    #----comp_op_hard_light
    comp_op_soft_light,    #----comp_op_soft_light
    comp_op_difference,    #----comp_op_difference
    comp_op_exclusion,     #----comp_op_exclusion
    comp_op_contrast,      #----comp_op_contrast
    comp_op_invert,        #----comp_op_invert
    comp_op_invert_rgb,    #----comp_op_invert_rgb

    end_of_comp_op_e







[ColorT, OrderT] struct comp_op_adaptor_rgba
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        comp_op_table_rgba<ColorT, OrderT>::g_comp_op_func[op]
            (p, (cr * ca + baseMask) shr baseShift,
                (cg * ca + baseMask) shr baseShift,
                (cb * ca + baseMask) shr baseShift,
                 ca, cover)
    }

[ColorT, OrderT] struct comp_op_adaptor_clip_to_dst_rgba
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        cr = (cr * ca + baseMask) shr baseShift;
        cg = (cg * ca + baseMask) shr baseShift;
        cb = (cb * ca + baseMask) shr baseShift;
        unsigned da = p[OrderT.A];
        comp_op_table_rgba<ColorT, OrderT>::g_comp_op_func[op]
            (p, (cr * da + baseMask) shr baseShift,
                (cg * da + baseMask) shr baseShift,
                (cb * da + baseMask) shr baseShift,
                (ca * da + baseMask) shr baseShift,
                cover)
    }

[ColorT, OrderT] struct comp_op_adaptor_rgba_pre
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        comp_op_table_rgba<ColorT, OrderT>::g_comp_op_func[op](p, cr, cg, cb, ca, cover)
    }

[ColorT, OrderT] struct comp_op_adaptor_clip_to_dst_rgba_pre
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        unsigned da = p[OrderT.A];
        comp_op_table_rgba<ColorT, OrderT>::g_comp_op_func[op]
            (p, (cr * da + baseMask) shr baseShift,
                (cg * da + baseMask) shr baseShift,
                (cb * da + baseMask) shr baseShift,
                (ca * da + baseMask) shr baseShift,
                cover)
    }

[BlenderPre> struct comp_adaptor_rgba
    typedef typename BlenderPre::order_type order_type;
    typedef typename BlenderPre::ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        BlenderPre::blendPix(p,
                              (cr * ca + baseMask) shr baseShift,
                              (cg * ca + baseMask) shr baseShift,
                              (cb * ca + baseMask) shr baseShift,
                              ca, cover)
    }

[BlenderPre> struct comp_adaptor_clip_to_dst_rgba
    typedef typename BlenderPre::order_type order_type;
    typedef typename BlenderPre::ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        cr = (cr * ca + baseMask) shr baseShift;
        cg = (cg * ca + baseMask) shr baseShift;
        cb = (cb * ca + baseMask) shr baseShift;
        unsigned da = p[OrderT.A];
        BlenderPre::blendPix(p,
                              (cr * da + baseMask) shr baseShift,
                              (cg * da + baseMask) shr baseShift,
                              (cb * da + baseMask) shr baseShift,
                              (ca * da + baseMask) shr baseShift,
                              cover)
    }

[BlenderPre> struct comp_adaptor_clip_to_dst_rgba_pre
    typedef typename BlenderPre::order_type order_type;
    typedef typename BlenderPre::ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(unsigned op, ValueT* p,
                                     cr, cg, cb: uint,
                                     unsigned ca,
                                     cover: uint)
    {
        unsigned da = p[OrderT.A];
        BlenderPre::blendPix(p,
                              (cr * da + baseMask) shr baseShift,
                              (cg * da + baseMask) shr baseShift,
                              (cb * da + baseMask) shr baseShift,
                              (ca * da + baseMask) shr baseShift,
                              cover)
    }






[Blender> struct copy_or_blend_rgba_wrapper
    typedef typename Blender::ColorT ColorT;
    typedef typename Blender::order_type order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        base_scale = ColorT::base_scale,
        baseMask  = baseMask
    };

    #--------------------------------------------------------------------
    static AGG_INLINE void copy_or_blendPix(ValueT* p,
                                             cr, cg, cb: uint,
                                             alpha: uint)
    {
        if alpha)
        {
            if alpha == baseMask)
            {
                p[OrderT.R] = cr;
                p[OrderT.G] = cg;
                p[OrderT.B] = cb;
                p[OrderT.A] = baseMask;
            }
            else:
            {
                Blender::blendPix(p, cr, cg, cb, alpha)
            }
        }
    }

    #--------------------------------------------------------------------
    static AGG_INLINE void copy_or_blendPix(ValueT* p,
                                             cr, cg, cb: uint,
                                             alpha: uint,
                                             cover: uint)
    {
        if cover == 255)
        {
            copy_or_blendPix(p, cr, cg, cb, alpha)
        }
        else:
        {
            if alpha)
            {
                alpha = (alpha * (cover + 1)) shr 8;
                if alpha == baseMask)
                {
                    p[OrderT.R] = cr;
                    p[OrderT.G] = cg;
                    p[OrderT.B] = cb;
                    p[OrderT.A] = baseMask;
                }
                else:
                {
                    Blender::blendPix(p, cr, cg, cb, alpha, cover)
                }
            }
        }
    }






[Blender, class RenBuf, class PixelT = int32u>
class pixfmt_alpha_blend_rgba
    typedef RenBuf   rbuf_type;
    typedef typename rbuf_type::row_data row_data;
    typedef PixelT   pixel_type;
    typedef Blender  blender_type;
    typedef typename blender_type::ColorT ColorT;
    typedef typename blender_type::order_type order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    typedef copy_or_blend_rgba_wrapper<blender_type> cob_type;
    enum base_scale_e
    {
        baseShift = baseShift,
        base_scale = ColorT::base_scale,
        baseMask  = baseMask,
        pix_width  = sizeof(pixel_type)
    };

    #--------------------------------------------------------------------
    pixfmt_alpha_blend_rgba() : m_rbuf(0) {}
    explicit pixfmt_alpha_blend_rgba(rbuf_type& rb) : m_rbuf(&rb) {}
proc attach(rbuf_type& rb) = m_rbuf = &rb

    #--------------------------------------------------------------------
    [PixFmt>
    bool attach(PixFmt& pixf, x1, y1, x2, y2: int)
    {
        rect_i r(x1, y1, x2, y2)
        if r.clip(rect_i(0, 0, pixf.width()-1, pixf.height()-1)))
        {
            int stride = pixf.stride()
            self.mRBuf[].attach(pixf.pix_ptr(r.x1, stride < 0 ? r.y2 : r.y1),
                           (r.x2 - r.x1) + 1,
                           (r.y2 - r.y1) + 1,
                           stride)
            return true;
        }
        return false;
    }

    #--------------------------------------------------------------------
    AGG_INLINE unsigned width()  const { return self.mRBuf[].width()  }
    AGG_INLINE unsigned height(): float64 = self.mRBuf[].height()
    AGG_INLINE int      stride(): float64 = self.mRBuf[].stride()

    #--------------------------------------------------------------------
    AGG_INLINE       int8u* rowPtr(int y)       { return self.mRBuf[].rowPtr(y)
    AGG_INLINE const int8u* rowPtr(int y): float64 = self.mRBuf[].rowPtr(y)
    AGG_INLINE row_data     row(int y)     const { return self.mRBuf[].row(y)

    #--------------------------------------------------------------------
    AGG_INLINE int8u* pix_ptr(x, y: int)
    {
        return self.mRBuf[].rowPtr(y) + x * pix_width;
    }

    AGG_INLINE const int8u* pix_ptr(x, y: int) const
    {
        return self.mRBuf[].rowPtr(y) + x * pix_width;
    }


    #--------------------------------------------------------------------
    AGG_INLINE static void make_pix(int8u* p, c: ColorT)
    {
        ((ValueT*)p)[OrderT.R] = c.r;
        ((ValueT*)p)[OrderT.G] = c.g;
        ((ValueT*)p)[OrderT.B] = c.b;
        ((ValueT*)p)[OrderT.A] = c.a;
    }

    #--------------------------------------------------------------------
    AGG_INLINE ColorT pixel(x, y: int) const
    {
        const ValueT* p = (const ValueT*)self.mRBuf[].rowPtr(y)
        if p)
        {
            p += x shl 2;
            return ColorT(p[OrderT.R],
                              p[OrderT.G],
                              p[OrderT.B],
                              p[OrderT.A])
        }
        return ColorT::noColor()
    }

    #--------------------------------------------------------------------
    AGG_INLINE void copyPixel(x, y: int, c: ColorT)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, 1) + (x shl 2)
        p[OrderT.R] = c.r;
        p[OrderT.G] = c.g;
        p[OrderT.B] = c.b;
        p[OrderT.A] = c.a;
    }

    #--------------------------------------------------------------------
    AGG_INLINE void blendPixel(x, y: int, c: ColorT, int8u cover)
    {
        cob_type::copy_or_blendPix(
            (ValueT*)self.mRBuf[].rowPtr(x, y, 1) + (x shl 2),
            c.r, c.g, c.b, c.a,
            cover)
    }


    #--------------------------------------------------------------------
    AGG_INLINE void copyHline(x, y: int,
                               unsigned len,
                               c: ColorT)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        pixel_type v;
        ((ValueT*)&v)[OrderT.R] = c.r;
        ((ValueT*)&v)[OrderT.G] = c.g;
        ((ValueT*)&v)[OrderT.B] = c.b;
        ((ValueT*)&v)[OrderT.A] = c.a;
        do
        {
            *(pixel_type*)p = v;
            p += 4;
        }
        while --len)
    }


    #--------------------------------------------------------------------
    AGG_INLINE void copyVline(x, y: int,
                               unsigned len,
                               c: ColorT)
    {
        pixel_type v;
        ((ValueT*)&v)[OrderT.R] = c.r;
        ((ValueT*)&v)[OrderT.G] = c.g;
        ((ValueT*)&v)[OrderT.B] = c.b;
        ((ValueT*)&v)[OrderT.A] = c.a;
        do
        {
            ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
            *(pixel_type*)p = v;
        }
        while --len)
    }


    #--------------------------------------------------------------------
proc blendHline(x, y: int,
                     unsigned len,
                     c: ColorT,
                     int8u cover)
    {
        if (c.a)
        {
            ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
            CalcT alpha = (CalcT(c.a) * (cover + 1)) shr 8;
            if alpha == baseMask)
            {
                pixel_type v;
                ((ValueT*)&v)[OrderT.R] = c.r;
                ((ValueT*)&v)[OrderT.G] = c.g;
                ((ValueT*)&v)[OrderT.B] = c.b;
                ((ValueT*)&v)[OrderT.A] = c.a;
                do
                {
                    *(pixel_type*)p = v;
                    p += 4;
                }
                while --len)
            }
            else:
            {
                if cover == 255)
                {
                    do
                    {
                        blender_type::blendPix(p, c.r, c.g, c.b, alpha)
                        p += 4;
                    }
                    while --len)
                }
                else:
                {
                    do
                    {
                        blender_type::blendPix(p, c.r, c.g, c.b, alpha, cover)
                        p += 4;
                    }
                    while --len)
                }
            }
        }
    }


    #--------------------------------------------------------------------
proc blendVline(x, y: int,
                     unsigned len,
                     c: ColorT,
                     int8u cover)
    {
        if (c.a)
        {
            ValueT* p;
            CalcT alpha = (CalcT(c.a) * (cover + 1)) shr 8;
            if alpha == baseMask)
            {
                pixel_type v;
                ((ValueT*)&v)[OrderT.R] = c.r;
                ((ValueT*)&v)[OrderT.G] = c.g;
                ((ValueT*)&v)[OrderT.B] = c.b;
                ((ValueT*)&v)[OrderT.A] = c.a;
                do
                {
                    p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                    *(pixel_type*)p = v;
                }
                while --len)
            }
            else:
            {
                if cover == 255)
                {
                    do
                    {
                        p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                        blender_type::blendPix(p, c.r, c.g, c.b, alpha)
                    }
                    while --len)
                }
                else:
                {
                    do
                    {
                        p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                        blender_type::blendPix(p, c.r, c.g, c.b, alpha, cover)
                    }
                    while --len)
                }
            }
        }
    }


    #--------------------------------------------------------------------
proc blendSolidHspan(x, y: int,
                           unsigned len,
                           c: ColorT,
                           const int8u* covers)
    {
        if (c.a)
        {
            ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
            do
            {
                CalcT alpha = (CalcT(c.a) * (CalcT(*covers) + 1)) shr 8;
                if alpha == baseMask)
                {
                    p[OrderT.R] = c.r;
                    p[OrderT.G] = c.g;
                    p[OrderT.B] = c.b;
                    p[OrderT.A] = baseMask;
                }
                else:
                {
                    blender_type::blendPix(p, c.r, c.g, c.b, alpha, *covers)
                }
                p += 4;
                ++covers;
            }
            while --len)
        }
    }


    #--------------------------------------------------------------------
proc blendSolidVspan(x, y: int,
                           unsigned len,
                           c: ColorT,
                           const int8u* covers)
    {
        if (c.a)
        {
            do
            {
                ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                CalcT alpha = (CalcT(c.a) * (CalcT(*covers) + 1)) shr 8;
                if alpha == baseMask)
                {
                    p[OrderT.R] = c.r;
                    p[OrderT.G] = c.g;
                    p[OrderT.B] = c.b;
                    p[OrderT.A] = baseMask;
                }
                else:
                {
                    blender_type::blendPix(p, c.r, c.g, c.b, alpha, *covers)
                }
                ++covers;
            }
            while --len)
        }
    }


    #--------------------------------------------------------------------
proc copyColorHspan(x, y: int,
                          unsigned len,
                          const ColorT* colors)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            p[OrderT.R] = colors.r;
            p[OrderT.G] = colors.g;
            p[OrderT.B] = colors.b;
            p[OrderT.A] = colors.a;
            inc colors
            p += 4;
        }
        while --len)
    }


    #--------------------------------------------------------------------
proc copy_color_vspan(x, y: int,
                          unsigned len,
                          const ColorT* colors)
    {
        do
        {
            ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
            p[OrderT.R] = colors.r;
            p[OrderT.G] = colors.g;
            p[OrderT.B] = colors.b;
            p[OrderT.A] = colors.a;
            inc colors
        }
        while --len)
    }


    #--------------------------------------------------------------------
proc blendColorHspan(x, y: int,
                           unsigned len,
                           const ColorT* colors,
                           const int8u* covers,
                           int8u cover)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        if covers)
        {
            do
            {
                cob_type::copy_or_blendPix(p,
                                            colors.r,
                                            colors.g,
                                            colors.b,
                                            colors.a,
                                            *covers++)
                p += 4;
                inc colors
            }
            while --len)
        }
        else:
        {
            if cover == 255)
            {
                do
                {
                    cob_type::copy_or_blendPix(p,
                                                colors.r,
                                                colors.g,
                                                colors.b,
                                                colors.a)
                    p += 4;
                    inc colors
                }
                while --len)
            }
            else:
            {
                do
                {
                    cob_type::copy_or_blendPix(p,
                                                colors.r,
                                                colors.g,
                                                colors.b,
                                                colors.a,
                                                cover)
                    p += 4;
                    inc colors
                }
                while --len)
            }
        }
    }



    #--------------------------------------------------------------------
proc blendColorVspan(x, y: int,
                           unsigned len,
                           const ColorT* colors,
                           const int8u* covers,
                           int8u cover)
    {
        ValueT* p;
        if covers)
        {
            do
            {
                p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                cob_type::copy_or_blendPix(p,
                                            colors.r,
                                            colors.g,
                                            colors.b,
                                            colors.a,
                                            *covers++)
                inc colors
            }
            while --len)
        }
        else:
        {
            if cover == 255)
            {
                do
                {
                    p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                    cob_type::copy_or_blendPix(p,
                                                colors.r,
                                                colors.g,
                                                colors.b,
                                                colors.a)
                    inc colors
                }
                while --len)
            }
            else:
            {
                do
                {
                    p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
                    cob_type::copy_or_blendPix(p,
                                                colors.r,
                                                colors.g,
                                                colors.b,
                                                colors.a,
                                                cover)
                    inc colors
                }
                while --len)
            }
        }
    }

    #--------------------------------------------------------------------
    [Function> void for_each_pixel(Function f)
    {
        unsigned y;
        for(y = 0; y < height() ++y)
        {
            row_data r = self.mRBuf[].row(y)
            if r.ptr)
            {
                unsigned len = r.x2 - r.x1 + 1;
                ValueT* p =
                    (ValueT*)self.mRBuf[].rowPtr(r.x1, y, len) + (r.x1 shl 2)
                do
                {
                    f(p)
                    p += 4;
                }
                while --len)
            }
        }
    }

    #--------------------------------------------------------------------
proc premultiply()
    {
        for_each_pixel(multiplier_rgba<ColorT, order_type>::premultiply)
    }

    #--------------------------------------------------------------------
proc demultiply()
    {
        for_each_pixel(multiplier_rgba<ColorT, order_type>::demultiply)
    }

    #--------------------------------------------------------------------
    [GammaLut> void apply_gamma_dir(const GammaLut& g)
    {
        for_each_pixel(apply_gamma_dir_rgba<ColorT, order_type, GammaLut>(g))
    }

    #--------------------------------------------------------------------
    [GammaLut> void apply_gamma_inv(const GammaLut& g)
    {
        for_each_pixel(apply_gamma_inv_rgba<ColorT, order_type, GammaLut>(g))
    }

    #--------------------------------------------------------------------
    [RenBuf2> void copyFrom(const RenBuf2& from,
                                           int xdst, int ydst,
                                           int xsrc, int ysrc,
                                           unsigned len)
    {
        const int8u* p = from.rowPtr(ysrc)
        if p)
        {
            memmove(self.mRBuf[].rowPtr(xdst, ydst, len) + xdst * pix_width,
                    p + xsrc * pix_width,
                    len * pix_width)
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blendFrom(const SrcPixelFormatRenderer& from,
                    int xdst, int ydst,
                    int xsrc, int ysrc,
                    unsigned len,
                    int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::order_type src_order;
        const ValueT* psrc = (ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            psrc += xsrc shl 2;
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)
            int incp = 4;
            if xdst > xsrc)
            {
                psrc += (len-1) shl 2;
                pdst += (len-1) shl 2;
                incp = -4;
            }

            if cover == 255)
            {
                do
                {
                    cob_type::copy_or_blendPix(pdst,
                                                psrc[src_Order.R],
                                                psrc[src_Order.G],
                                                psrc[src_Order.B],
                                                psrc[src_Order.A])
                    psrc += incp;
                    pdst += incp;
                }
                while --len)
            }
            else:
            {
                do
                {
                    cob_type::copy_or_blendPix(pdst,
                                                psrc[src_Order.R],
                                                psrc[src_Order.G],
                                                psrc[src_Order.B],
                                                psrc[src_Order.A],
                                                cover)
                    psrc += incp;
                    pdst += incp;
                }
                while --len)
            }
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blend_froself.mColor(const SrcPixelFormatRenderer& from,
                          c: ColorTolor,
                          int xdst, int ydst,
                          int xsrc, int ysrc,
                          unsigned len,
                          int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::ValueT src_ValueT;
        const src_ValueT* psrc = (src_ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)
            do
            {
                cob_type::copy_or_blendPix(pdst,
                                            color.r, color.g, color.b, color.a,
                                            (*psrc * cover + baseMask) shr baseShift)
                inc psrc
                inc(pdst, 4)
            }
            while --len)
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blendFrom_lut(const SrcPixelFormatRenderer& from,
                        const ColorT* color_lut,
                        int xdst, int ydst,
                        int xsrc, int ysrc,
                        unsigned len,
                        int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::ValueT src_ValueT;
        const src_ValueT* psrc = (src_ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)

            if cover == 255)
            {
                do
                {
                    c: ColorTolor = color_lut[*psrc];
                    cob_type::copy_or_blendPix(pdst,
                                                color.r, color.g, color.b, color.a)
                    inc psrc
                    inc(pdst, 4)
                }
                while --len)
            }
            else:
            {
                do
                {
                    c: ColorTolor = color_lut[*psrc];
                    cob_type::copy_or_blendPix(pdst,
                                                color.r, color.g, color.b, color.a,
                                                cover)
                    inc psrc
                    inc(pdst, 4)
                }
                while --len)
            }
        }
    }

private:
    rbuf_type* m_rbuf;




[Blender, class RenBuf> class pixfmt_custom_blend_rgba
    typedef RenBuf   rbuf_type;
    typedef typename rbuf_type::row_data row_data;
    typedef Blender  blender_type;
    typedef typename blender_type::ColorT ColorT;
    typedef typename blender_type::order_type order_type;
    typedef typename ColorT::ValueT ValueT;
    typedef typename ColorT::CalcT CalcT;
    enum base_scale_e
    {
        baseShift = baseShift,
        base_scale = ColorT::base_scale,
        baseMask  = baseMask,
        pix_width  = sizeof(ValueT) * 4
    };


    #--------------------------------------------------------------------
    pixfmt_custom_blend_rgba() : m_rbuf(0), m_comp_op(3) {}
    explicit pixfmt_custom_blend_rgba(rbuf_type& rb, unsigned comp_op=3) :
        m_rbuf(&rb),
        m_comp_op(comp_op)
    {}
proc attach(rbuf_type& rb) = m_rbuf = &rb

    #--------------------------------------------------------------------
    [PixFmt>
    bool attach(PixFmt& pixf, x1, y1, x2, y2: int)
    {
        rect_i r(x1, y1, x2, y2)
        if r.clip(rect_i(0, 0, pixf.width()-1, pixf.height()-1)))
        {
            int stride = pixf.stride()
            self.mRBuf[].attach(pixf.pix_ptr(r.x1, stride < 0 ? r.y2 : r.y1),
                           (r.x2 - r.x1) + 1,
                           (r.y2 - r.y1) + 1,
                           stride)
            return true;
        }
        return false;
    }

    #--------------------------------------------------------------------
    AGG_INLINE unsigned width()  const { return self.mRBuf[].width()  }
    AGG_INLINE unsigned height(): float64 = self.mRBuf[].height()
    AGG_INLINE int      stride(): float64 = self.mRBuf[].stride()

    #--------------------------------------------------------------------
    AGG_INLINE       int8u* rowPtr(int y)       { return self.mRBuf[].rowPtr(y)
    AGG_INLINE const int8u* rowPtr(int y): float64 = self.mRBuf[].rowPtr(y)
    AGG_INLINE row_data     row(int y)     const { return self.mRBuf[].row(y)

    #--------------------------------------------------------------------
    AGG_INLINE int8u* pix_ptr(x, y: int)
    {
        return self.mRBuf[].rowPtr(y) + x * pix_width;
    }

    AGG_INLINE const int8u* pix_ptr(x, y: int) const
    {
        return self.mRBuf[].rowPtr(y) + x * pix_width;
    }

    #--------------------------------------------------------------------
proc comp_op(unsigned op) = m_comp_op = op
    unsigned comp_op() const  { return m_comp_op

    #--------------------------------------------------------------------
    AGG_INLINE static void make_pix(int8u* p, c: ColorT)
    {
        ((ValueT*)p)[OrderT.R] = c.r;
        ((ValueT*)p)[OrderT.G] = c.g;
        ((ValueT*)p)[OrderT.B] = c.b;
        ((ValueT*)p)[OrderT.A] = c.a;
    }

    #--------------------------------------------------------------------
    ColorT pixel(x, y: int) const
    {
        const ValueT* p = (ValueT*)self.mRBuf[].rowPtr(y) + (x shl 2)
        return ColorT(p[OrderT.R],
                          p[OrderT.G],
                          p[OrderT.B],
                          p[OrderT.A])
    }

    #--------------------------------------------------------------------
proc copyPixel(x, y: int, c: ColorT)
    {
        blender_type::blendPix(
            m_comp_op,
            (ValueT*)self.mRBuf[].rowPtr(x, y, 1) + (x shl 2),
            c.r, c.g, c.b, c.a, 255)
    }

    #--------------------------------------------------------------------
proc blendPixel(x, y: int, c: ColorT, int8u cover)
    {
        blender_type::blendPix(
            m_comp_op,
            (ValueT*)self.mRBuf[].rowPtr(x, y, 1) + (x shl 2),
            c.r, c.g, c.b, c.a,
            cover)
    }

    #--------------------------------------------------------------------
proc copyHline(x, y, len: int, c: ColorT)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            blender_type::blendPix(m_comp_op, p, c.r, c.g, c.b, c.a, 255)
            p += 4;
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc copyVline(x, y, len: int, c: ColorT)
    {
        do
        {
            blender_type::blendPix(
                m_comp_op,
                (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2),
                c.r, c.g, c.b, c.a, 255)
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendHline(x, y, len: int,
                     c: ColorT, int8u cover)
    {

        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            blender_type::blendPix(m_comp_op, p, c.r, c.g, c.b, c.a, cover)
            p += 4;
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendVline(x, y, len: int,
                     c: ColorT, int8u cover)
    {

        do
        {
            blender_type::blendPix(
                m_comp_op,
                (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2),
                c.r, c.g, c.b, c.a,
                cover)
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendSolidHspan(x, y, len: int,
                           c: ColorT, const int8u* covers)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            blender_type::blendPix(m_comp_op,
                                    p, c.r, c.g, c.b, c.a,
                                    *covers++)
            p += 4;
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendSolidVspan(x, y, len: int,
                           c: ColorT, const int8u* covers)
    {
        do
        {
            blender_type::blendPix(
                m_comp_op,
                (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2),
                c.r, c.g, c.b, c.a,
                *covers++)
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc copyColorHspan(x, y: int,
                          unsigned len,
                          const ColorT* colors)
    {

        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            p[OrderT.R] = colors.r;
            p[OrderT.G] = colors.g;
            p[OrderT.B] = colors.b;
            p[OrderT.A] = colors.a;
            inc colors
            p += 4;
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc copy_color_vspan(x, y: int,
                          unsigned len,
                          const ColorT* colors)
    {
        do
        {
            ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2)
            p[OrderT.R] = colors.r;
            p[OrderT.G] = colors.g;
            p[OrderT.B] = colors.b;
            p[OrderT.A] = colors.a;
            inc colors
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendColorHspan(x, y, len: int,
                           const ColorT* colors,
                           const int8u* covers,
                           int8u cover)
    {
        ValueT* p = (ValueT*)self.mRBuf[].rowPtr(x, y, len) + (x shl 2)
        do
        {
            blender_type::blendPix(m_comp_op,
                                    p,
                                    colors.r,
                                    colors.g,
                                    colors.b,
                                    colors.a,
                                    covers ? *covers++ : cover)
            p += 4;
            inc colors
        }
        while --len)
    }

    #--------------------------------------------------------------------
proc blendColorVspan(x, y, len: int,
                           const ColorT* colors,
                           const int8u* covers,
                           int8u cover)
    {
        do
        {
            blender_type::blendPix(
                m_comp_op,
                (ValueT*)self.mRBuf[].rowPtr(x, y++, 1) + (x shl 2),
                colors.r,
                colors.g,
                colors.b,
                colors.a,
                covers ? *covers++ : cover)
            inc colors
        }
        while --len)

    }

    #--------------------------------------------------------------------
    [Function> void for_each_pixel(Function f)
    {
        unsigned y;
        for(y = 0; y < height() ++y)
        {
            row_data r = self.mRBuf[].row(y)
            if r.ptr)
            {
                unsigned len = r.x2 - r.x1 + 1;
                ValueT* p =
                    (ValueT*)self.mRBuf[].rowPtr(r.x1, y, len) + (r.x1 shl 2)
                do
                {
                    f(p)
                    p += 4;
                }
                while --len)
            }
        }
    }

    #--------------------------------------------------------------------
proc premultiply()
    {
        for_each_pixel(multiplier_rgba<ColorT, order_type>::premultiply)
    }

    #--------------------------------------------------------------------
proc demultiply()
    {
        for_each_pixel(multiplier_rgba<ColorT, order_type>::demultiply)
    }

    #--------------------------------------------------------------------
    [GammaLut> void apply_gamma_dir(const GammaLut& g)
    {
        for_each_pixel(apply_gamma_dir_rgba<ColorT, order_type, GammaLut>(g))
    }

    #--------------------------------------------------------------------
    [GammaLut> void apply_gamma_inv(const GammaLut& g)
    {
        for_each_pixel(apply_gamma_inv_rgba<ColorT, order_type, GammaLut>(g))
    }

    #--------------------------------------------------------------------
    [RenBuf2> void copyFrom(const RenBuf2& from,
                                           int xdst, int ydst,
                                           int xsrc, int ysrc,
                                           unsigned len)
    {
        const int8u* p = from.rowPtr(ysrc)
        if p)
        {
            memmove(self.mRBuf[].rowPtr(xdst, ydst, len) + xdst * pix_width,
                    p + xsrc * pix_width,
                    len * pix_width)
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blendFrom(const SrcPixelFormatRenderer& from,
                    int xdst, int ydst,
                    int xsrc, int ysrc,
                    unsigned len,
                    int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::order_type src_order;
        const ValueT* psrc = (const ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            psrc += xsrc shl 2;
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)

            int incp = 4;
            if xdst > xsrc)
            {
                psrc += (len-1) shl 2;
                pdst += (len-1) shl 2;
                incp = -4;
            }

            do
            {
                blender_type::blendPix(m_comp_op,
                                        pdst,
                                        psrc[src_Order.R],
                                        psrc[src_Order.G],
                                        psrc[src_Order.B],
                                        psrc[src_Order.A],
                                        cover)
                psrc += incp;
                pdst += incp;
            }
            while --len)
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blend_froself.mColor(const SrcPixelFormatRenderer& from,
                          c: ColorTolor,
                          int xdst, int ydst,
                          int xsrc, int ysrc,
                          unsigned len,
                          int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::ValueT src_ValueT;
        const src_ValueT* psrc = (src_ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)
            do
            {
                blender_type::blendPix(m_comp_op,
                                        pdst,
                                        color.r, color.g, color.b, color.a,
                                        (*psrc * cover + baseMask) shr baseShift)
                inc psrc
                inc(pdst, 4)
            }
            while --len)
        }
    }

    #--------------------------------------------------------------------
    [SrcPixelFormatRenderer>
proc blendFrom_lut(const SrcPixelFormatRenderer& from,
                        const ColorT* color_lut,
                        int xdst, int ydst,
                        int xsrc, int ysrc,
                        unsigned len,
                        int8u cover)
    {
        typedef typename SrcPixelFormatRenderer::ValueT src_ValueT;
        const src_ValueT* psrc = (src_ValueT*)from.rowPtr(ysrc)
        if psrc)
        {
            ValueT* pdst =
                (ValueT*)self.mRBuf[].rowPtr(xdst, ydst, len) + (xdst shl 2)
            do
            {
                c: ColorTolor = color_lut[*psrc];
                blender_type::blendPix(m_comp_op,
                                        pdst,
                                        color.r, color.g, color.b, color.a,
                                        cover)
                inc psrc
                inc(pdst, 4)
            }
            while --len)
        }
    }

private:
    rbuf_type* m_rbuf;
    unsigned m_comp_op;




typedef blender_rgba<rgba8, order_rgba> blender_rgba32; #----blender_rgba32
typedef blender_rgba<rgba8, order_argb> blender_argb32; #----blender_argb32
typedef blender_rgba<rgba8, order_abgr> blender_abgr32; #----blender_abgr32
typedef blender_rgba<rgba8, order_bgra> blender_bgra32; #----blender_bgra32

typedef blender_rgba_pre<rgba8, order_rgba> blender_rgba32_pre; #----blender_rgba32_pre
typedef blender_rgba_pre<rgba8, order_argb> blender_argb32_pre; #----blender_argb32_pre
typedef blender_rgba_pre<rgba8, order_abgr> blender_abgr32_pre; #----blender_abgr32_pre
typedef blender_rgba_pre<rgba8, order_bgra> blender_bgra32_pre; #----blender_bgra32_pre

typedef blender_rgba_plain<rgba8, order_rgba> blender_rgba32_plain; #----blender_rgba32_plain
typedef blender_rgba_plain<rgba8, order_argb> blender_argb32_plain; #----blender_argb32_plain
typedef blender_rgba_plain<rgba8, order_abgr> blender_abgr32_plain; #----blender_abgr32_plain
typedef blender_rgba_plain<rgba8, order_bgra> blender_bgra32_plain; #----blender_bgra32_plain

typedef blender_rgba<rgba16, order_rgba> blender_rgba64; #----blender_rgba64
typedef blender_rgba<rgba16, order_argb> blender_argb64; #----blender_argb64
typedef blender_rgba<rgba16, order_abgr> blender_abgr64; #----blender_abgr64
typedef blender_rgba<rgba16, order_bgra> blender_bgra64; #----blender_bgra64

typedef blender_rgba_pre<rgba16, order_rgba> blender_rgba64_pre; #----blender_rgba64_pre
typedef blender_rgba_pre<rgba16, order_argb> blender_argb64_pre; #----blender_argb64_pre
typedef blender_rgba_pre<rgba16, order_abgr> blender_abgr64_pre; #----blender_abgr64_pre
typedef blender_rgba_pre<rgba16, order_bgra> blender_bgra64_pre; #----blender_bgra64_pre


typedef int32u pixel32_type;
typedef pixfmt_alpha_blend_rgba<blender_rgba32, RenderingBuffer, pixel32_type> pixfmt_rgba32; #----pixfmt_rgba32
typedef pixfmt_alpha_blend_rgba<blender_argb32, RenderingBuffer, pixel32_type> pixfmt_argb32; #----pixfmt_argb32
typedef pixfmt_alpha_blend_rgba<blender_abgr32, RenderingBuffer, pixel32_type> pixfmt_abgr32; #----pixfmt_abgr32
typedef pixfmt_alpha_blend_rgba<blender_bgra32, RenderingBuffer, pixel32_type> pixfmt_bgra32; #----pixfmt_bgra32

typedef pixfmt_alpha_blend_rgba<blender_rgba32_pre, RenderingBuffer, pixel32_type> pixfmt_rgba32_pre; #----pixfmt_rgba32_pre
typedef pixfmt_alpha_blend_rgba<blender_argb32_pre, RenderingBuffer, pixel32_type> pixfmt_argb32_pre; #----pixfmt_argb32_pre
typedef pixfmt_alpha_blend_rgba<blender_abgr32_pre, RenderingBuffer, pixel32_type> pixfmt_abgr32_pre; #----pixfmt_abgr32_pre
typedef pixfmt_alpha_blend_rgba<blender_bgra32_pre, RenderingBuffer, pixel32_type> pixfmt_bgra32_pre; #----pixfmt_bgra32_pre

typedef pixfmt_alpha_blend_rgba<blender_rgba32_plain, RenderingBuffer, pixel32_type> pixfmt_rgba32_plain; #----pixfmt_rgba32_plain
typedef pixfmt_alpha_blend_rgba<blender_argb32_plain, RenderingBuffer, pixel32_type> pixfmt_argb32_plain; #----pixfmt_argb32_plain
typedef pixfmt_alpha_blend_rgba<blender_abgr32_plain, RenderingBuffer, pixel32_type> pixfmt_abgr32_plain; #----pixfmt_abgr32_plain
typedef pixfmt_alpha_blend_rgba<blender_bgra32_plain, RenderingBuffer, pixel32_type> pixfmt_bgra32_plain; #----pixfmt_bgra32_plain

struct  pixel64_type { int16u c[4];
typedef pixfmt_alpha_blend_rgba<blender_rgba64, RenderingBuffer, pixel64_type> pixfmt_rgba64; #----pixfmt_rgba64
typedef pixfmt_alpha_blend_rgba<blender_argb64, RenderingBuffer, pixel64_type> pixfmt_argb64; #----pixfmt_argb64
typedef pixfmt_alpha_blend_rgba<blender_abgr64, RenderingBuffer, pixel64_type> pixfmt_abgr64; #----pixfmt_abgr64
typedef pixfmt_alpha_blend_rgba<blender_bgra64, RenderingBuffer, pixel64_type> pixfmt_bgra64; #----pixfmt_bgra64

typedef pixfmt_alpha_blend_rgba<blender_rgba64_pre, RenderingBuffer, pixel64_type> pixfmt_rgba64_pre; #----pixfmt_rgba64_pre
typedef pixfmt_alpha_blend_rgba<blender_argb64_pre, RenderingBuffer, pixel64_type> pixfmt_argb64_pre; #----pixfmt_argb64_pre
typedef pixfmt_alpha_blend_rgba<blender_abgr64_pre, RenderingBuffer, pixel64_type> pixfmt_abgr64_pre; #----pixfmt_abgr64_pre
typedef pixfmt_alpha_blend_rgba<blender_bgra64_pre, RenderingBuffer, pixel64_type> pixfmt_bgra64_pre; #----pixfmt_bgra64_pre
]#

