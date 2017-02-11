[ColorT, OrderT] type CompOpRgbaclear
typedef ColorT ColorT;
typedef OrderT order_type;
typedef typename ColorT::ValueT ValueT;
enum base_scale_e
{
    baseShift = baseShift,
    baseMask  = baseMask
};

static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbasrc
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;

    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadst
    typedef ColorT ColorT;
    typedef OrderT order_type;
    typedef typename ColorT::ValueT ValueT;

    static AGG_INLINE void blendPix(ValueT*,
                                     unsigned, unsigned, unsigned,
                                     unsigned, unsigned)
    {
    }

[ColorT, OrderT] type CompOpRgbasrc_over
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadst_over
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbasrc_in
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadst_in
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbasrc_out
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadst_out
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbasrc_atop
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadst_atop
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbaxor
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbaplus
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbaminus
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbamultiply
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbascreen
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbaoverlay
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadarken
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbalighten
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbacolor_dodge
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbacolor_burn
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbahard_light
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbasoft_light
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

    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbadifference
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbaexclusion
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbacontrast
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


    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbainvert
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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

[ColorT, OrderT] type CompOpRgbainvert_rgb
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
    static AGG_INLINE void blendPix(p: ptr ValueT,
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





[ColorT, OrderT] struct CompOptable_rgba
    typedef typename ColorT::ValueT ValueT;
    typedef void (*CompOpfunc_type)(p: ptr ValueT,
                                      unsigned cr,
                                      unsigned cg,
                                      unsigned cb,
                                      ca: uint,
                                      cover: uint)
    static CompOpfunc_type g_CompOpfunc[];

[ColorT, OrderT]
typename CompOptable_rgba<ColorT, OrderT>::CompOpfunc_type
CompOptable_rgba<ColorT, OrderT>::g_CompOpfunc[] =
    CompOpRgbaclear      <ColorT,OrderT>::blendPix,
    CompOpRgbasrc        <ColorT,OrderT>::blendPix,
    CompOpRgbadst        <ColorT,OrderT>::blendPix,
    CompOpRgbasrc_over   <ColorT,OrderT>::blendPix,
    CompOpRgbadst_over   <ColorT,OrderT>::blendPix,
    CompOpRgbasrc_in     <ColorT,OrderT>::blendPix,
    CompOpRgbadst_in     <ColorT,OrderT>::blendPix,
    CompOpRgbasrc_out    <ColorT,OrderT>::blendPix,
    CompOpRgbadst_out    <ColorT,OrderT>::blendPix,
    CompOpRgbasrc_atop   <ColorT,OrderT>::blendPix,
    CompOpRgbadst_atop   <ColorT,OrderT>::blendPix,
    CompOpRgbaxor        <ColorT,OrderT>::blendPix,
    CompOpRgbaplus       <ColorT,OrderT>::blendPix,
    CompOpRgbaminus      <ColorT,OrderT>::blendPix,
    CompOpRgbamultiply   <ColorT,OrderT>::blendPix,
    CompOpRgbascreen     <ColorT,OrderT>::blendPix,
    CompOpRgbaoverlay    <ColorT,OrderT>::blendPix,
    CompOpRgbadarken     <ColorT,OrderT>::blendPix,
    CompOpRgbalighten    <ColorT,OrderT>::blendPix,
    CompOpRgbacolor_dodge<ColorT,OrderT>::blendPix,
    CompOpRgbacolor_burn <ColorT,OrderT>::blendPix,
    CompOpRgbahard_light <ColorT,OrderT>::blendPix,
    CompOpRgbasoft_light <ColorT,OrderT>::blendPix,
    CompOpRgbadifference <ColorT,OrderT>::blendPix,
    CompOpRgbaexclusion  <ColorT,OrderT>::blendPix,
    CompOpRgbacontrast   <ColorT,OrderT>::blendPix,
    CompOpRgbainvert     <ColorT,OrderT>::blendPix,
    CompOpRgbainvert_rgb <ColorT,OrderT>::blendPix,
    0


enum CompOpe
    CompOpclear,         #----CompOpclear
    CompOpsrc,           #----CompOpsrc
    CompOpdst,           #----CompOpdst
    CompOpsrc_over,      #----CompOpsrc_over
    CompOpdst_over,      #----CompOpdst_over
    CompOpsrc_in,        #----CompOpsrc_in
    CompOpdst_in,        #----CompOpdst_in
    CompOpsrc_out,       #----CompOpsrc_out
    CompOpdst_out,       #----CompOpdst_out
    CompOpsrc_atop,      #----CompOpsrc_atop
    CompOpdst_atop,      #----CompOpdst_atop
    CompOpxor,           #----CompOpxor
    CompOpplus,          #----CompOpplus
    CompOpminus,         #----CompOpminus
    CompOpmultiply,      #----CompOpmultiply
    CompOpscreen,        #----CompOpscreen
    CompOpoverlay,       #----CompOpoverlay
    CompOpdarken,        #----CompOpdarken
    CompOplighten,       #----CompOplighten
    CompOpcolor_dodge,   #----CompOpcolor_dodge
    CompOpcolor_burn,    #----CompOpcolor_burn
    CompOphard_light,    #----CompOphard_light
    CompOpsoft_light,    #----CompOpsoft_light
    CompOpdifference,    #----CompOpdifference
    CompOpexclusion,     #----CompOpexclusion
    CompOpcontrast,      #----CompOpcontrast
    CompOpinvert,        #----CompOpinvert
    CompOpinvert_rgb,    #----CompOpinvert_rgb

    end_of_CompOpe







[ColorT, OrderT] struct CompOpadaptor_rgba
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
                                     cover: uint)
    {
        CompOptable_rgba<ColorT, OrderT>::g_CompOpfunc[op]
            (p, (cr * ca + baseMask) shr baseShift,
                (cg * ca + baseMask) shr baseShift,
                (cb * ca + baseMask) shr baseShift,
                 ca, cover)
    }

[ColorT, OrderT] struct CompOpadaptor_clip_to_dst_rgba
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
                                     cover: uint)
    {
        cr = (cr * ca + baseMask) shr baseShift;
        cg = (cg * ca + baseMask) shr baseShift;
        cb = (cb * ca + baseMask) shr baseShift;
        unsigned da = p[OrderT.A];
        CompOptable_rgba<ColorT, OrderT>::g_CompOpfunc[op]
            (p, (cr * da + baseMask) shr baseShift,
                (cg * da + baseMask) shr baseShift,
                (cb * da + baseMask) shr baseShift,
                (ca * da + baseMask) shr baseShift,
                cover)
    }

[ColorT, OrderT] struct CompOpadaptor_rgba_pre
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
                                     cover: uint)
    {
        CompOptable_rgba<ColorT, OrderT>::g_CompOpfunc[op](p, cr, cg, cb, ca, cover)
    }

[ColorT, OrderT] struct CompOpadaptor_clip_to_dst_rgba_pre
    typedef OrderT  order_type;
    typedef ColorT ColorT;
    typedef typename ColorT::ValueT ValueT;
    enum base_scale_e
    {
        baseShift = baseShift,
        baseMask  = baseMask
    };

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
                                     cover: uint)
    {
        unsigned da = p[OrderT.A];
        CompOptable_rgba<ColorT, OrderT>::g_CompOpfunc[op]
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

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
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

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
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

    static AGG_INLINE void blendPix(op: int, p: ptr ValueT,
                                     cr, cg, cb: uint,
                                     ca: uint,
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
