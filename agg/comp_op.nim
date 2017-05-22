import color_rgba, basics, math

proc RgbaClear_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  if cover < 255:
    let cover = 255'u - cover
    p[OrderT.R] = ValueT((p[OrderT.R].uint * cover + 255) shr 8)
    p[OrderT.G] = ValueT((p[OrderT.G].uint * cover + 255) shr 8)
    p[OrderT.B] = ValueT((p[OrderT.B].uint * cover + 255) shr 8)
    p[OrderT.A] = ValueT((p[OrderT.A].uint * cover + 255) shr 8)
  else:
    p[0] = 0
    p[1] = 0
    p[2] = 0
    p[3] = 0


proc RgbaSrc_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  if cover < 255:
    let alpha = 255'u - cover
    p[OrderT.R] = ValueT(((p[OrderT.R].uint * alpha + 255) shr 8) + ((sr * cover + 255) shr 8))
    p[OrderT.G] = ValueT(((p[OrderT.G].uint * alpha + 255) shr 8) + ((sg * cover + 255) shr 8))
    p[OrderT.B] = ValueT(((p[OrderT.B].uint * alpha + 255) shr 8) + ((sb * cover + 255) shr 8))
    p[OrderT.A] = ValueT(((p[OrderT.A].uint * alpha + 255) shr 8) + ((sa * cover + 255) shr 8))
  else:
    p[OrderT.R] = ValueT(sr)
    p[OrderT.G] = ValueT(sg)
    p[OrderT.B] = ValueT(sb)
    p[OrderT.A] = ValueT(sa)

proc RgbaDst_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  discard

#   Dca' = Sca + Dca.(1 - Sa)
#   Da'  = Sa + Da - Sa.Da
proc RgbaSrcOver_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  var s1a = baseMask - CalcT(sa)
  p[OrderT.R] = ValueT(sr + ((p[OrderT.R].CalcT * s1a + baseMask) shr baseShift))
  p[OrderT.G] = ValueT(sg + ((p[OrderT.G].CalcT * s1a + baseMask) shr baseShift))
  p[OrderT.B] = ValueT(sb + ((p[OrderT.B].CalcT * s1a + baseMask) shr baseShift))
  p[OrderT.A] = ValueT(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))


# Dca' = Dca + Sca.(1 - Da)
# Da'  = Sa + Da - Sa.Da
proc RgbaDstOver_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  var d1a = baseMask - CalcT(p[OrderT.A])
  p[OrderT.R] = ValueT(p[OrderT.R].CalcT + ((sr.CalcT * d1a + baseMask) shr baseShift))
  p[OrderT.G] = ValueT(p[OrderT.G].CalcT + ((sg.CalcT * d1a + baseMask) shr baseShift))
  p[OrderT.B] = ValueT(p[OrderT.B].CalcT + ((sb.CalcT * d1a + baseMask) shr baseShift))
  p[OrderT.A] = ValueT(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))

# Dca' = Sca.Da
# Da'  = Sa.Da
proc RgbaSrcIn_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))

  let da = CalcT(p[OrderT.A])
  if cover < 255:
    let alpha = 255'u - cover
    p[OrderT.R] = ValueT(((p[OrderT.R].uint * alpha + 255) shr 8) + ((((sr * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.G] = ValueT(((p[OrderT.G].uint * alpha + 255) shr 8) + ((((sg * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.B] = ValueT(((p[OrderT.B].uint * alpha + 255) shr 8) + ((((sb * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.A] = ValueT(((p[OrderT.A].uint * alpha + 255) shr 8) + ((((sa * da + baseMask) shr baseShift) * cover + 255) shr 8))
  else:
    p[OrderT.R] = ValueT((sr * da + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((sg * da + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((sb * da + baseMask) shr baseShift)
    p[OrderT.A] = ValueT((sa * da + baseMask) shr baseShift)

# Dca' = Dca.Sa
# Da'  = Sa.Da
proc RgbaDstIn_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  const
    baseMask = getBaseMask(ColorT).uint
    baseShift = getBaseShift(ColorT).uint
  var sa = sa
  if cover < 255:
    sa = baseMask - ((cover * (baseMask - sa) + 255'u) shr 8'u)

  p[OrderT.R] = ValueT((p[OrderT.R].uint * sa + baseMask) shr baseShift)
  p[OrderT.G] = ValueT((p[OrderT.G].uint * sa + baseMask) shr baseShift)
  p[OrderT.B] = ValueT((p[OrderT.B].uint * sa + baseMask) shr baseShift)
  p[OrderT.A] = ValueT((p[OrderT.A].uint * sa + baseMask) shr baseShift)

# Dca' = Sca.(1 - Da)
# Da'  = Sa.(1 - Da)
proc RgbaSrcOut_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))

  let da = baseMask - CalcT(p[OrderT.A])
  if cover < 255:
    let alpha = 255'u - cover
    p[OrderT.R] = ValueT(((p[OrderT.R].uint * alpha + 255) shr 8) + ((((sr * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.G] = ValueT(((p[OrderT.G].uint * alpha + 255) shr 8) + ((((sg * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.B] = ValueT(((p[OrderT.B].uint * alpha + 255) shr 8) + ((((sb * da + baseMask) shr baseShift) * cover + 255) shr 8))
    p[OrderT.A] = ValueT(((p[OrderT.A].uint * alpha + 255) shr 8) + ((((sa * da + baseMask) shr baseShift) * cover + 255) shr 8))
  else:
    p[OrderT.R] = ValueT((sr * da + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((sg * da + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((sb * da + baseMask) shr baseShift)
    p[OrderT.A] = ValueT((sa * da + baseMask) shr baseShift)

# Dca' = Dca.(1 - Sa)
# Da'  = Da.(1 - Sa)
proc RgbaDstOut_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  const
    baseMask = getBaseMask(ColorT).uint
    baseShift = getBaseShift(ColorT).uint
  var sa = sa
  if cover < 255:
    sa = (sa * cover + 255) shr 8

  sa = baseMask - sa
  p[OrderT.R] = ValueT((p[OrderT.R].uint * sa + baseShift) shr baseShift)
  p[OrderT.G] = ValueT((p[OrderT.G].uint * sa + baseShift) shr baseShift)
  p[OrderT.B] = ValueT((p[OrderT.B].uint * sa + baseShift) shr baseShift)
  p[OrderT.A] = ValueT((p[OrderT.A].uint * sa + baseShift) shr baseShift)

# Dca' = Sca.Da + Dca.(1 - Sa)
# Da'  = Da
proc RgbaSrcAtop_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  var da = CalcT(p[OrderT.A])
  sa = baseMask - sa.CalcT
  p[OrderT.R] = ValueT((sr.CalcT * da + p[OrderT.R].CalcT * sa.CalcT + baseMask) shr baseShift)
  p[OrderT.G] = ValueT((sg.CalcT * da + p[OrderT.G].CalcT * sa.CalcT + baseMask) shr baseShift)
  p[OrderT.B] = ValueT((sb.CalcT * da + p[OrderT.B].CalcT * sa.CalcT + baseMask) shr baseShift)

# Dca' = Dca.Sa + Sca.(1 - Da)
# Da'  = Sa
proc RgbaDstAtop_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa

  let da = baseMask - CalcT(p[OrderT.A])
  if cover < 255:
    let alpha = 255'u - cover
    sr = (p[OrderT.R].uint * sa + sr * da + baseMask) shr baseShift
    sg = (p[OrderT.G].uint * sa + sg * da + baseMask) shr baseShift
    sb = (p[OrderT.B].uint * sa + sb * da + baseMask) shr baseShift
    p[OrderT.R] = ValueT(((p[OrderT.R].uint * alpha + 255) shr 8) + ((sr * cover + 255) shr 8))
    p[OrderT.G] = ValueT(((p[OrderT.G].uint * alpha + 255) shr 8) + ((sg * cover + 255) shr 8))
    p[OrderT.B] = ValueT(((p[OrderT.B].uint * alpha + 255) shr 8) + ((sb * cover + 255) shr 8))
    p[OrderT.A] = ValueT(((p[OrderT.A].uint * alpha + 255) shr 8) + ((sa * cover + 255) shr 8))
  else:
    p[OrderT.R] = ValueT((p[OrderT.R].uint * sa + sr * da + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((p[OrderT.G].uint * sa + sg * da + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((p[OrderT.B].uint * sa + sb * da + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa)

# Dca' = Sca.(1 - Da) + Dca.(1 - Sa)
# Da'  = Sa + Da - 2.Sa.Da
proc RgbaXor_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      s1a = baseMask - CalcT(sa)
      d1a = baseMask - CalcT(p[OrderT.A])
    p[OrderT.R] = ValueT((p[OrderT.R].CalcT * s1a + sr.CalcT * d1a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((p[OrderT.G].CalcT * s1a + sg.CalcT * d1a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((p[OrderT.B].CalcT * s1a + sb.CalcT * d1a + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask div 2) shr (baseShift - 1)))

# Dca' = Sca + Dca
# Da'  = Sa + Da
proc RgbaPlus_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8
  if sa != 0:
    var
      dr = CalcT(p[OrderT.R]) + sr.CalcT
      dg = CalcT(p[OrderT.G]) + sg.CalcT
      db = CalcT(p[OrderT.B]) + sb.CalcT
      da = CalcT(p[OrderT.A]) + sa.CalcT
    p[OrderT.R] = ValueT(if dr > baseMask: baseMask else: dr)
    p[OrderT.G] = ValueT(if dg > baseMask: baseMask else: dg)
    p[OrderT.B] = ValueT(if db > baseMask: baseMask else: db)
    p[OrderT.A] = ValueT(if da > baseMask: baseMask else: da)

# Dca' = Dca - Sca
# Da' = 1 - (1 - Sa).(1 - Da)
proc RgbaMinus_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa

  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      dr = CalcT(p[OrderT.R]) - sr.CalcT
      dg = CalcT(p[OrderT.G]) - sg.CalcT
      db = CalcT(p[OrderT.B]) - sb.CalcT
    p[OrderT.R] = ValueT(if dr > baseMask: 0.CalcT else: dr)
    p[OrderT.G] = ValueT(if dg > baseMask: 0.CalcT else: dg)
    p[OrderT.B] = ValueT(if db > baseMask: 0.CalcT else: db)
    p[OrderT.A] = ValueT(sa + CalcT(p[OrderT.A]) - ((sa * CalcT(p[OrderT.A]) + baseMask) shr baseShift))

# Dca' = Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaMultiply_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      s1a = baseMask - sa.CalcT
      d1a = baseMask - CalcT(p[OrderT.A])
      dr = CalcT(p[OrderT.R])
      dg = CalcT(p[OrderT.G])
      db = CalcT(p[OrderT.B])
    p[OrderT.R] = ValueT((sr * dr + sr * d1a + dr * s1a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((sg * dg + sg * d1a + dg * s1a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((sb * db + sb * d1a + db * s1a + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa + p[OrderT.A] - ((sa * p[OrderT.A] + baseMask) shr baseShift))

# Dca' = Sca + Dca - Sca.Dca
# Da'  = Sa + Da - Sa.Da
proc RgbaScreen_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8
  if sa != 0:
    var
      dr = CalcT(p[OrderT.R])
      dg = CalcT(p[OrderT.G])
      db = CalcT(p[OrderT.B])
      da = CalcT(p[OrderT.A])
    p[OrderT.R] = ValueT(sr + dr - ((sr * dr + baseMask) shr baseShift))
    p[OrderT.G] = ValueT(sg + dg - ((sg * dg + baseMask) shr baseShift))
    p[OrderT.B] = ValueT(sb + db - ((sb * db + baseMask) shr baseShift))
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# if 2.Dca < Da
#   Dca' = 2.Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise
#   Dca' = Sa.Da - 2.(Da - Dca).(Sa - Sca) + Sca.(1 - Da) + Dca.(1 - Sa)
#
# Da' = Sa + Da - Sa.Da
proc RgbaOverlay_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8
  if sa != 0:
    var
      d1a  = baseMask - CalcT(p[OrderT.A])
      s1a  = baseMask - sa.CalcT
      dr   = CalcT(p[OrderT.R])
      dg   = CalcT(p[OrderT.G])
      db   = CalcT(p[OrderT.B])
      da   = CalcT(p[OrderT.A])
      sada = sa.CalcT * CalcT(p[OrderT.A])

    p[OrderT.R] = ValueT((if 2.CalcT*dr < da:
        2.CalcT*sr.CalcT*dr + sr.CalcT*d1a + dr*s1a else:
        sada - 2.CalcT*(da - dr)*CalcT(sa - sr) + sr.CalcT*d1a + dr*s1a + baseMask) shr baseShift)

    p[OrderT.G] = ValueT((if 2.CalcT*dg < da:
        2.CalcT*sg.CalcT*dg + sg.CalcT*d1a + dg*s1a else:
        sada - 2.CalcT*(da - dg)*CalcT(sa - sg) + sg.CalcT*d1a + dg*s1a + baseMask) shr baseShift)

    p[OrderT.B] = ValueT((if 2.CalcT*db < da:
        2.CalcT*sb.CalcT*db + sb.CalcT*d1a + db*s1a else:
        sada - 2.CalcT*(da - db)*CalcT(sa - sb) + sb.CalcT*d1a + db*s1a + baseMask) shr baseShift)

    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# Dca' = min(Sca.Da, Dca.Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaDarken_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      d1a = baseMask - CalcT(p[OrderT.A])
      s1a = baseMask - sa.CalcT
      dr  = CalcT(p[OrderT.R])
      dg  = CalcT(p[OrderT.G])
      db  = CalcT(p[OrderT.B])
      da  = CalcT(p[OrderT.A])

    p[OrderT.R] = ValueT((min(sr.CalcT * da, dr * sa.CalcT) + sr.CalcT * d1a + dr * s1a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((min(sg.CalcT * da, dg * sa.CalcT) + sg.CalcT * d1a + dg * s1a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((min(sb.CalcT * da, db * sa.CalcT) + sb.CalcT * d1a + db * s1a + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# Dca' = max(Sca.Da, Dca.Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaLighten_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa

  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      d1a = baseMask - CalcT(p[OrderT.A])
      s1a = baseMask - sa.CalcT
      dr  = CalcT(p[OrderT.R])
      dg  = CalcT(p[OrderT.G])
      db  = CalcT(p[OrderT.B])
      da  = CalcT(p[OrderT.A])

    p[OrderT.R] = ValueT((max(sr.CalcT * da, dr * sa.CalcT) + sr.CalcT * d1a + dr * s1a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((max(sg.CalcT * da, dg * sa.CalcT) + sg.CalcT * d1a + dg * s1a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((max(sb.CalcT * da, db * sa.CalcT) + sb.CalcT * d1a + db * s1a + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# if Sca.Da + Dca.Sa >= Sa.Da
#   Dca' = Sa.Da + Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise
#   Dca' = Dca.Sa/(1-Sca/Sa) + Sca.(1 - Da) + Dca.(1 - Sa)
#
# Da'  = Sa + Da - Sa.Da
proc RgbaColorDodge_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
    LongT = getLongT(ColorT)
  const
    baseMask = LongT(getBaseMask(ColorT))
    baseShift = LongT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa

  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      d1a  = baseMask - LongT(p[OrderT.A])
      s1a  = baseMask - sa.LongT
      dr   = LongT(p[OrderT.R]) #CalcT(p[OrderT.R])
      dg   = LongT(p[OrderT.G]) #CalcT(p[OrderT.G])
      db   = LongT(p[OrderT.B]) #CalcT(p[OrderT.B])
      da   = LongT(p[OrderT.A]) #CalcT(p[OrderT.A])
      drsa = LongT(dr * sa.LongT)
      dgsa = LongT(dg * sa.LongT)
      dbsa = LongT(db * sa.LongT)
      srda = LongT(sr.LongT * da)
      sgda = LongT(sg.LongT * da)
      sbda = LongT(sb.LongT * da)
      sada = LongT(sa.LongT * da)

    p[OrderT.R] = ValueT(if srda + drsa >= sada:
        (sada + sr.LongT * d1a + dr * s1a + baseMask) shr baseShift else:
        drsa div (baseMask - (sr.LongT shl baseShift) div sa.LongT) + ((sr.LongT * d1a + dr * s1a + baseMask) shr baseShift))

    p[OrderT.G] = ValueT(if sgda + dgsa >= sada:
        (sada + sg.LongT * d1a + dg * s1a + baseMask) shr baseShift else:
        dgsa div (baseMask - (sg.LongT shl baseShift) div sa.LongT) + ((sg.LongT * d1a + dg * s1a + baseMask) shr baseShift))

    p[OrderT.B] = ValueT(if sbda + dbsa >= sada:
        (sada + sb.LongT * d1a + db * s1a + baseMask) shr baseShift else:
        dbsa div (baseMask - (sb.LongT shl baseShift) div sa.LongT) + ((sb.LongT * d1a + db * s1a + baseMask) shr baseShift))

    p[OrderT.A] = ValueT(sa.LongT + da - ((sa.LongT * da + baseMask) shr baseShift))

# if Sca.Da + Dca.Sa <= Sa.Da
#   Dca' = Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise
#   Dca' = Sa.(Sca.Da + Dca.Sa - Sa.Da)/Sca + Sca.(1 - Da) + Dca.(1 - Sa)
#
# Da'  = Sa + Da - Sa.Da
proc RgbaColorBurn_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
    LongT = getLongT(ColorT)
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  var
    sr = sr.LongT
    sg = sg.LongT
    sb = sb.LongT
    sa = sa.LongT
    cover = cover.LongT

  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      d1a  = baseMask - LongT(p[OrderT.A])
      s1a  = baseMask - sa
      dr   = LongT(p[OrderT.R])
      dg   = LongT(p[OrderT.G])
      db   = LongT(p[OrderT.B])
      da   = LongT(p[OrderT.A])
      drsa = dr * sa
      dgsa = dg * sa
      dbsa = db * sa
      srda = sr * da
      sgda = sg * da
      sbda = sb * da
      sada = sa * da

    p[OrderT.R] = ValueT((if srda + drsa <= sada:
        sr * d1a + dr * s1a else:
        sa * (srda + drsa - sada) div sr + sr * d1a + dr * s1a + baseMask) shr baseShift)

    p[OrderT.G] = ValueT((if sgda + dgsa <= sada:
        sg * d1a + dg * s1a else:
        sa * (sgda + dgsa - sada) div sg + sg * d1a + dg * s1a + baseMask) shr baseShift)

    p[OrderT.B] = ValueT((if sbda + dbsa <= sada:
        sb * d1a + db * s1a else:
        sa * (sbda + dbsa - sada) div sb + sb * d1a + db * s1a + baseMask) shr baseShift)

    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# if 2.Sca < Sa
#    Dca' = 2.Sca.Dca + Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise
#    Dca' = Sa.Da - 2.(Da - Dca).(Sa - Sca) + Sca.(1 - Da) + Dca.(1 - Sa)
#
# Da'  = Sa + Da - Sa.Da
proc RgbaHardLight_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr.CalcT
    sg = sg.CalcT
    sb = sb.CalcT
    sa = sa.CalcT

  if cover < 255:
    sr = (sr * cover.CalcT + 255) shr 8
    sg = (sg * cover.CalcT + 255) shr 8
    sb = (sb * cover.CalcT + 255) shr 8
    sa = (sa * cover.CalcT + 255) shr 8
  if sa != 0:
    var
      d1a  = baseMask - CalcT(p[OrderT.A])
      s1a  = baseMask - sa.CalcT
      dr   = CalcT(p[OrderT.R])
      dg   = CalcT(p[OrderT.G])
      db   = CalcT(p[OrderT.B])
      da   = CalcT(p[OrderT.A])
      sada = CalcT(sa * da)

    p[OrderT.R] = ValueT((if 2'u*sr < sa:
        2'u*sr*dr + sr*d1a + dr*s1a else:
        sada - 2.CalcT*(da - dr)*(sa - sr) + sr*d1a + dr*s1a + baseMask) shr baseShift)

    p[OrderT.G] = ValueT((if 2'u*sg < sa:
        2'u*sg*dg + sg*d1a + dg*s1a else:
        sada - 2.CalcT*(da - dg)*(sa - sg) + sg*d1a + dg*s1a + baseMask) shr baseShift)

    p[OrderT.B] = ValueT((if 2'u*sb < sa:
        2'u*sb*db + sb*d1a + db*s1a else:
        sada - 2.CalcT*(da - db)*(sa - sb) + sb*d1a + db*s1a + baseMask) shr baseShift)

    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# if 2.Sca < Sa
#   Dca' = Dca.(Sa + (1 - Dca/Da).(2.Sca - Sa)) + Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise if 8.Dca <= Da
#   Dca' = Dca.(Sa + (1 - Dca/Da).(2.Sca - Sa).(3 - 8.Dca/Da)) + Sca.(1 - Da) + Dca.(1 - Sa)
# otherwise
#   Dca' = (Dca.Sa + ((Dca/Da)^(0.5).Da - Dca).(2.Sca - Sa)) + Sca.(1 - Da) + Dca.(1 - Sa)
#
# Da'  = Sa + Da - Sa.Da
proc RgbaSoftLight_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, r, g, b, a, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = float64(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    a = a
    sr = float64(r * cover) / (baseMask * 255.0)
    sg = float64(g * cover) / (baseMask * 255.0)
    sb = float64(b * cover) / (baseMask * 255.0)
    sa = float64(a * cover) / (baseMask * 255.0)

  if sa > 0:
    var
      dr = float64(p[OrderT.R]) / baseMask
      dg = float64(p[OrderT.G]) / baseMask
      db = float64(p[OrderT.B]) / baseMask
      da = float64(if p[OrderT.A] != 0: p[OrderT.A] else: 1) / baseMask

    if cover < 255:
      a = (a * cover + 255) shr 8

    if 2*sr < sa:    dr = dr*(sa + (1 - dr/da)*(2*sr - sa)) + sr*(1 - da) + dr*(1 - sa)
    elif 8*dr <= da: dr = dr*(sa + (1 - dr/da)*(2*sr - sa)*(3 - 8*dr/da)) + sr*(1 - da) + dr*(1 - sa)
    else:            dr = (dr*sa + (sqrt(dr/da)*da - dr)*(2*sr - sa)) + sr*(1 - da) + dr*(1 - sa)

    if 2*sg < sa:    dg = dg*(sa + (1 - dg/da)*(2*sg - sa)) + sg*(1 - da) + dg*(1 - sa)
    elif 8*dg <= da: dg = dg*(sa + (1 - dg/da)*(2*sg - sa)*(3 - 8*dg/da)) + sg*(1 - da) + dg*(1 - sa)
    else:            dg = (dg*sa + (sqrt(dg/da)*da - dg)*(2*sg - sa)) + sg*(1 - da) + dg*(1 - sa)

    if 2*sb < sa:    db = db*(sa + (1 - db/da)*(2*sb - sa)) + sb*(1 - da) + db*(1 - sa)
    elif 8*db <= da: db = db*(sa + (1 - db/da)*(2*sb - sa)*(3 - 8*db/da)) + sb*(1 - da) + db*(1 - sa)
    else:            db = (db*sa + (sqrt(db/da)*da - db)*(2*sb - sa)) + sb*(1 - da) + db*(1 - sa)

    p[OrderT.R] = ValueT(uround(dr * baseMask))
    p[OrderT.G] = ValueT(uround(dg * baseMask))
    p[OrderT.B] = ValueT(uround(db * baseMask))
    p[OrderT.A] = ValueT(a + CalcT(p[OrderT.A]) - ((a * CalcT(p[OrderT.A]) + baseMask.CalcT) shr baseShift))

# Dca' = Sca + Dca - 2.min(Sca.Da, Dca.Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaDifference_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8
  if sa != 0:
    var
      dr = CalcT(p[OrderT.R])
      dg = CalcT(p[OrderT.G])
      db = CalcT(p[OrderT.B])
      da = CalcT(p[OrderT.A])
    p[OrderT.R] = ValueT(sr + dr - ((2.CalcT * min(sr.CalcT*da, dr*sa.CalcT) + baseMask) shr baseShift))
    p[OrderT.G] = ValueT(sg + dg - ((2.CalcT * min(sg.CalcT*da, dg*sa.CalcT) + baseMask) shr baseShift))
    p[OrderT.B] = ValueT(sb + db - ((2.CalcT * min(sb.CalcT*da, db*sa.CalcT) + baseMask) shr baseShift))
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# Dca' = (Sca.Da + Dca.Sa - 2.Sca.Dca) + Sca.(1 - Da) + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaExclusion_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      d1a = baseMask - CalcT(p[OrderT.A])
      s1a = baseMask - sa.CalcT
      dr = CalcT(p[OrderT.R])
      dg = CalcT(p[OrderT.G])
      db = CalcT(p[OrderT.B])
      da = CalcT(p[OrderT.A])
    p[OrderT.R] = ValueT((sr.CalcT*da + dr*sa.CalcT - 2.CalcT*sr.CalcT*dr + sr.CalcT*d1a + dr*s1a + baseMask) shr baseShift)
    p[OrderT.G] = ValueT((sg.CalcT*da + dg*sa.CalcT - 2.CalcT*sg.CalcT*dg + sg.CalcT*d1a + dg*s1a + baseMask) shr baseShift)
    p[OrderT.B] = ValueT((sb.CalcT*da + db*sa.CalcT - 2.CalcT*sb.CalcT*db + sb.CalcT*d1a + db*s1a + baseMask) shr baseShift)
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

proc RgbaContrast_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
    LongT = getLongT(ColorT)
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8

  var
    dr = LongT(p[OrderT.R])
    dg = LongT(p[OrderT.G])
    db = LongT(p[OrderT.B])
    da = p[OrderT.A].int
    d2a = LongT(da shr 1)
    s2a = LongT(sa shr 1)
    r = int(sar(((dr - d2a) * int((sr.LongT - s2a)*2 + baseMask)), baseShift) + d2a)
    g = int(sar(((dg - d2a) * int((sg.LongT - s2a)*2 + baseMask)), baseShift) + d2a)
    b = int(sar(((db - d2a) * int((sb.LongT - s2a)*2 + baseMask)), baseShift) + d2a)

  r = if r < 0: 0 else: r
  g = if g < 0: 0 else: g
  b = if b < 0: 0 else: b

  p[OrderT.R] = ValueT(if r > da: da else: r)
  p[OrderT.G] = ValueT(if g > da: da else: g)
  p[OrderT.B] = ValueT(if b > da: da else: b)

# Dca' = (Da - Dca) * Sa + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaInvert_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sa = (sa * cover + 255) shr 8

  if sa != 0:
    var
      da = CalcT(p[OrderT.A])
      dr = CalcT(((da - p[OrderT.R]) * sa.CalcT + baseMask) shr baseShift)
      dg = CalcT(((da - p[OrderT.G]) * sa.CalcT + baseMask) shr baseShift)
      db = CalcT(((da - p[OrderT.B]) * sa.CalcT + baseMask) shr baseShift)
      s1a = baseMask - sa.CalcT
    p[OrderT.R] = ValueT(dr + ((p[OrderT.R].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.G] = ValueT(dg + ((p[OrderT.G].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.B] = ValueT(db + ((p[OrderT.B].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

# Dca' = (Da - Dca) * Sca + Dca.(1 - Sa)
# Da'  = Sa + Da - Sa.Da
proc RgbaInvertRgb_BlendPix[ColorT, OrderT, ValueT](p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.} =
  type
    CalcT = getCalcT(ColorT)
  const
    baseMask = CalcT(getBaseMask(ColorT))
    baseShift = CalcT(getBaseShift(ColorT))
  var
    sr = sr
    sg = sg
    sb = sb
    sa = sa
  if cover < 255:
    sr = (sr * cover + 255) shr 8
    sg = (sg * cover + 255) shr 8
    sb = (sb * cover + 255) shr 8
    sa = (sa * cover + 255) shr 8
  if sa != 0:
    var
      da = CalcT(p[OrderT.A])
      dr = CalcT(((da - p[OrderT.R]) * sr.CalcT + baseMask) shr baseShift)
      dg = CalcT(((da - p[OrderT.G]) * sg.CalcT + baseMask) shr baseShift)
      db = CalcT(((da - p[OrderT.B]) * sb.CalcT + baseMask) shr baseShift)
      s1a = baseMask - sa.CalcT
    p[OrderT.R] = ValueT(dr + ((p[OrderT.R].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.G] = ValueT(dg + ((p[OrderT.G].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.B] = ValueT(db + ((p[OrderT.B].CalcT * s1a + baseMask) shr baseShift))
    p[OrderT.A] = ValueT(sa + da - ((sa * da + baseMask) shr baseShift))

type
  CompOpFunc[ValueT] = proc(p: ptr ValueT, sr, sg, sb, sa, cover: uint) {.cdecl.}
  CompOpTable[ValueT] = array[28, CompOpFunc[ValueT]]

proc compOpTable*[ColorT, OrderT, ValueT](): CompOpTable[ValueT] =
  result = [
    RgbaClear_blendPix[ColorT, OrderT, ValueT],
    RgbaSrc_blendPix[ColorT, OrderT, ValueT],
    RgbaDst_blendPix[ColorT, OrderT, ValueT],
    RgbaSrcOver_blendPix[ColorT, OrderT, ValueT],
    RgbaDstOver_blendPix[ColorT, OrderT, ValueT],
    RgbaSrcIn_blendPix[ColorT, OrderT, ValueT],
    RgbaDstIn_blendPix[ColorT, OrderT, ValueT],
    RgbaSrcOut_blendPix[ColorT, OrderT, ValueT],
    RgbaDstOut_blendPix[ColorT, OrderT, ValueT],
    RgbaSrcAtop_blendPix[ColorT, OrderT, ValueT],
    RgbaDstAtop_blendPix[ColorT, OrderT, ValueT],
    RgbaXor_blendPix[ColorT, OrderT, ValueT],
    RgbaPlus_blendPix[ColorT, OrderT, ValueT],
    RgbaMinus_blendPix[ColorT, OrderT, ValueT],
    RgbaMultiply_blendPix[ColorT, OrderT, ValueT],
    RgbaScreen_blendPix[ColorT, OrderT, ValueT],
    RgbaOverlay_blendPix[ColorT, OrderT, ValueT],
    RgbaDarken_blendPix[ColorT, OrderT, ValueT],
    RgbaLighten_blendPix[ColorT, OrderT, ValueT],
    RgbaColorDodge_blendPix[ColorT, OrderT, ValueT],
    RgbaColorBurn_blendPix[ColorT, OrderT, ValueT],
    RgbaHardLight_blendPix[ColorT, OrderT, ValueT],
    RgbaSoftLight_blendPix[ColorT, OrderT, ValueT],
    RgbaDifference_blendPix[ColorT, OrderT, ValueT],
    RgbaExclusion_blendPix[ColorT, OrderT, ValueT],
    RgbaContrast_blendPix[ColorT, OrderT, ValueT],
    RgbaInvert_blendPix[ColorT, OrderT, ValueT],
    RgbaInvertRgb_blendPix[ColorT, OrderT, ValueT]]

type
  CompOp* = enum
    CompOpClear
    CompOpSrc
    CompOpDst
    CompOpSrcOver
    CompOpDstOver
    CompOpSrcIn
    CompOpDstIn
    CompOpSrcOut
    CompOpDstOut
    CompOpSrcAtop
    CompOpDstAtop
    CompOpXor
    CompOpPlus
    CompOpMinus
    CompOpMultiply
    CompOpScreen
    CompOpOverlay
    CompOpDarken
    CompOpLighten
    CompOpColorDodge
    CompOpColorBurn
    CompOpHardLight
    CompOpSoftLight
    CompOpDifference
    CompOpExclusion
    CompOpContrast
    CompOpInvert
    CompOpInvertRgb

type
  CompOpAdaptorRgba*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[CompOpAdaptorRgba[C,O]]): typedesc = O
template getColorT*[C,O](x: typedesc[CompOpAdaptorRgba[C,O]]): typedesc = C
template getValueT*[C,O](x: typedesc[CompOpAdaptorRgba[C,O]]): typedesc = getValueT(C.type)

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[CompOpAdaptorRgba[ColorT, OrderT]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  cast[CompOpFunc[ValueT]](f)(p,
    (cr * ca + baseMask) shr baseShift,
    (cg * ca + baseMask) shr baseShift,
    (cb * ca + baseMask) shr baseShift,
    ca, cover)

type
  CompOpAdaptorClipToDstRgba*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgba[C,O]]): typedesc = O
template getColorT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgba[C,O]]): typedesc = C
template getValueT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgba[C,O]]): typedesc = getValueT(C.type)

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[CompOpAdaptorClipToDstRgba[ColorT, OrderT]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)

  var
    cr = (cr * ca + baseMask) shr baseShift
    cg = (cg * ca + baseMask) shr baseShift
    cb = (cb * ca + baseMask) shr baseShift
    da = p[OrderT.A].uint

  cast[CompOpFunc[ValueT]](f)(p,
    (cr * da + baseMask) shr baseShift,
    (cg * da + baseMask) shr baseShift,
    (cb * da + baseMask) shr baseShift,
    (ca * da + baseMask) shr baseShift,
    cover)

type
  CompOpAdaptorRgbaPre*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[CompOpAdaptorRgbaPre[C,O]]): typedesc = O
template getColorT*[C,O](x: typedesc[CompOpAdaptorRgbaPre[C,O]]): typedesc = C
template getValueT*[C,O](x: typedesc[CompOpAdaptorRgbaPre[C,O]]): typedesc = getValueT(C.type)

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[CompOpAdaptorRgbaPre[ColorT, OrderT]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  cast[CompOpFunc[ValueT]](f)(p, cr, cg, cb, ca, cover)

type
  CompOpAdaptorClipToDstRgbaPre*[ColorT, OrderT] = object

template getOrderT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgbaPre[C,O]]): typedesc = O
template getColorT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgbaPre[C,O]]): typedesc = C
template getValueT*[C,O](x: typedesc[CompOpAdaptorClipToDstRgbaPre[C,O]]): typedesc = getValueT(C.type)

proc blendPix*[ColorT, OrderT, ValueT](x: typedesc[CompOpAdaptorClipToDstRgbaPre[ColorT, OrderT]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)

  var da = p[OrderT.A].uint
  cast[CompOpFunc[ValueT]](f)(p,
    (cr * da + baseMask) shr baseShift,
    (cg * da + baseMask) shr baseShift,
    (cb * da + baseMask) shr baseShift,
    (ca * da + baseMask) shr baseShift,
    cover)

type
  CompAdaptorRgba*[BlenderPre] = object

template getOrderT*[B](x: typedesc[CompAdaptorRgba[B]]): typedesc = getOrderT(B.type)
template getColorT*[B](x: typedesc[CompAdaptorRgba[B]]): typedesc = getColorT(B.type)
template getValueT*[B](x: typedesc[CompAdaptorRgba[B]]): typedesc = getValueT(getColorT(B.type))

proc blendPix*[BlenderPre, ValueT](x: typedesc[CompAdaptorRgba[BlenderPre]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  type ColorT = getColorT(BlenderPre)
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  BlenderPre.blendPix(p,
    (cr * ca + baseMask) shr baseShift,
    (cg * ca + baseMask) shr baseShift,
    (cb * ca + baseMask) shr baseShift,
    ca, cover)

type
  CompAdaptorClipToDstRgba*[BlenderPre] = object

template getOrderT*[B](x: typedesc[CompAdaptorClipToDstRgba[B]]): typedesc = getOrderT(B.type)
template getColorT*[B](x: typedesc[CompAdaptorClipToDstRgba[B]]): typedesc = getColorT(B.type)
template getValueT*[B](x: typedesc[CompAdaptorClipToDstRgba[B]]): typedesc = getValueT(getColorT(B.type))

proc blendPix*[BlenderPre, ValueT](x: typedesc[CompAdaptorClipToDstRgba[BlenderPre]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  type
    ColorT = getColorT(BlenderPre)
    OrderT = getOrderT(BlenderPre)
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  var
    cr = (cr * ca + baseMask) shr baseShift
    cg = (cg * ca + baseMask) shr baseShift
    cb = (cb * ca + baseMask) shr baseShift
    da = p[OrderT.A].uint
  BlenderPre.blendPix(p,
    (cr * da + baseMask) shr baseShift,
    (cg * da + baseMask) shr baseShift,
    (cb * da + baseMask) shr baseShift,
    (ca * da + baseMask) shr baseShift,
    cover)

type
  CompAdaptorClipToDstRgbaPre*[BlenderPre] = object

template getOrderT*[B](x: typedesc[CompAdaptorClipToDstRgbaPre[B]]): typedesc = getOrderT(B.type)
template getColorT*[B](x: typedesc[CompAdaptorClipToDstRgbaPre[B]]): typedesc = getColorT(B.type)
template getValueT*[B](x: typedesc[CompAdaptorClipToDstRgbaPre[B]]): typedesc = getValueT(getColorT(B.type))

proc blendPix*[BlenderPre, ValueT](x: typedesc[CompAdaptorClipToDstRgbaPre[BlenderPre]],
  f: pointer, p: ptr ValueT, cr, cg, cb, ca, cover: uint) {.cdecl.} =
  type
    ColorT = getColorT(BlenderPre)
    OrderT = getOrderT(BlenderPre)
  const
    baseMask = getBaseMask(ColorT)
    baseShift = getBaseShift(ColorT)
  let da = p[OrderT.A].uint
  BlenderPre.blendPix(p,
    (cr * da + baseMask) shr baseShift,
    (cg * da + baseMask) shr baseShift,
    (cb * da + baseMask) shr baseShift,
    (ca * da + baseMask) shr baseShift,
    cover)
