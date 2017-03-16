import agg_basics, agg_color_rgba, agg_span_image_filter, agg_pixfmt_rgba
import agg_span_interpolator_linear, agg_image_filters

export agg_span_image_filter

type
  SpanImageFilterRgbaNN[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgbaNN*[S,I](src: var S, inter: var I): SpanImageFilterRgbaNN[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbaNN[S,I], span: ptr ColorT, x, y, len: int) =
  type 
    base = SpanImageFilter[S,I]
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
  var
   x = x
   y = y
   len = len
   span = span
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    var fgPtr = cast[ptr ValueT](base(self).source().span(sar(x, imageSubpixelShift),
                                sar(y, imageSubpixelShift), 1))
    span.r = fgPtr[OrderT.R.ord]
    span.g = fgPtr[OrderT.G.ord]
    span.b = fgPtr[OrderT.B.ord]
    span.a = fgPtr[OrderT.A.ord]
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgbaBilinear*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgbaBilinear*[S,I](src: var S, inter: var I): SpanImageFilterRgbaBilinear[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbaBilinear[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcT]
    fgPtr: ptr ValueT
    len = len
    span = span

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)
    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr,  imageSubpixelShift)

    fg[0] = imageSubpixelScale * imageSubpixelScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, 2))
    var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(xHr * (imageSubpixelScale - yHr))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextY())
    weight = CalcT((imageSubpixelScale - xHr) * yHr)
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(xHr * yHr)
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    span.r = ValueT(fg[OrderT.R.ord] shr (imageSubpixelShift * 2))
    span.g = ValueT(fg[OrderT.G.ord] shr (imageSubpixelShift * 2))
    span.b = ValueT(fg[OrderT.B.ord] shr (imageSubpixelShift * 2))
    span.a = ValueT(fg[OrderT.A.ord] shr (imageSubpixelShift * 2))

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgbaBilinearClip*[Source, Interpolator, ColorT] = object of SpanImageFilter[Source, Interpolator]
    mBackColor: ColorT

proc initSpanImageFilterRgbaBilinearClipAux*[S,I,ColorT](src: var S,
  backColor: ColorT, inter: var I): SpanImageFilterRgbaBilinearClip[S,I,ColorT] =
  type base = SpanImageFilter[S, I]
  base(result).init(src, inter)
  result.mBackColor = backColor
  
proc initSpanImageFilterRgbaBilinearClip*[S,I,ColorT](src: var S,
  backColor: ColorT, inter: var I): auto =
  type ColorS = getColorT(S)
  when ColorT is not ColorS:
    initSpanImageFilterRgbaBilinearClipAux[S,I,ColorS](src, construct(ColorS, backColor), inter)
  else:
    initSpanImageFilterRgbaBilinearClipAux(src, backColor, inter)
    
proc backgroundColor*[S,I,ColorT](self: SpanImageFilterRgbaBilinearClip[S,I,ColorT]): ColorT = self.mBackColor
proc backgroundColor*[S,I,ColorT](self: var SpanImageFilterRgbaBilinearClip[S,I,ColorT], v: ColorT) = self.mBackColor = v

proc prepare*[S,I,ColorT](self: SpanImageFilterRgbaBilinearClip[S,I,ColorT]) =
  type base = SpanImageFilter[S, I]
  base(self).prepare()
  
proc generate*[S,I,ColorT](self: var SpanImageFilterRgbaBilinearClip[S,I,ColorT],
  span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcT]
    backR = CalcT(self.mBackColor.r)
    backG = CalcT(self.mBackColor.g)
    backB = CalcT(self.mBackColor.b)
    backA = CalcT(self.mBackColor.a)
    fgPtr: ptr ValueT
    maxx = base(self).source().width() - 1
    maxy = base(self).source().height() - 1
    len = len
    span = span

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)
    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)

    if xLr >= 0 and yLr >= 0 and xLr < maxx and yLr < maxy:

      fg[0] = imageSubpixelScale * imageSubpixelScale div 2
      fg[1] = fg[0]
      fg[2] = fg[0]
      fg[3] = fg[0]

      xHr = xHr and imageSubpixelMask
      yHr = yHr and imageSubpixelMask
      fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))

      var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr
      fg[3] += weight * fgPtr[].CalcT; inc fgPtr

      weight = CalcT(xHr * (imageSubpixelScale - yHr))
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr
      fg[3] += weight * fgPtr[].CalcT; inc fgPtr

      inc yLr
      fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))

      weight = CalcT((imageSubpixelScale - xHr) * yHr)
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr
      fg[3] += weight * fgPtr[].CalcT; inc fgPtr

      weight = CalcT(xHr * yHr)
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr
      fg[3] += weight * fgPtr[].CalcT; inc fgPtr

      fg[0] = fg[0] shr (imageSubpixelShift * 2)
      fg[1] = fg[1] shr (imageSubpixelShift * 2)
      fg[2] = fg[2] shr (imageSubpixelShift * 2)
      fg[3] = fg[3] shr (imageSubpixelShift * 2)
    else:
      if xLr < -1 or yLr < -1 or xLr > maxx or yLr > maxy:
        fg[OrderT.R.ord] = backR
        fg[OrderT.G.ord] = backG
        fg[OrderT.B.ord] = backB
        fg[OrderT.A.ord] = backA
      else:
        fg[0] = imageSubpixelScale * imageSubpixelScale div 2
        fg[1] = fg[0]
        fg[2] = fg[0]
        fg[3] = fg[0]

        xHr = xHr and imageSubpixelMask
        yHr = yHr and imageSubpixelMask

        var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))
          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          fg[OrderT.A.ord] += backA * weight

        inc xLr
        weight = CalcT(xHr * (imageSubpixelScale - yHr))
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))

          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          fg[OrderT.A.ord] += backA * weight

        dec xLr
        inc yLr

        weight = CalcT((imageSubpixelScale - xHr) * yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))
          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          fg[OrderT.A.ord] += backA * weight

        inc xLr
        weight = CalcT(xHr * yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + (xLr shl 2))

          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          fg[OrderT.A.ord] += backA * weight

        fg[0] = fg[0] shr (imageSubpixelShift * 2)
        fg[1] = fg[1] shr (imageSubpixelShift * 2)
        fg[2] = fg[2] shr (imageSubpixelShift * 2)
        fg[3] = fg[3] shr (imageSubpixelShift * 2)

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(fg[OrderT.A.ord])
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgba2x2*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgba2x2*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageFilterRgba2x2[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgba2x2[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask = CalcT(getBaseMask(ColorT))
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcT]
    fgPtr: ptr ValueT
    weightArray = base(self).filter().weightArray()
    len = len
    span = span

  weightArray += ((base(self).filter().diameter() div 2 - 1) shl imageSubpixelShift)
  
  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr,  imageSubpixelShift)

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, 2))
    var weight = CalcT(sar((weightArray[xHr + imageSubpixelScale].int *
                  weightArray[yHr + imageSubpixelScale].int +
                  imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(sar((weightArray[xHr].int *
                  weightArray[yHr + imageSubpixelScale].int +
                  imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextY())
    weight = CalcT(sar((weightArray[xHr + imageSubpixelScale].int *
                  weightArray[yHr].int + imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(sar((weightArray[xHr].int *
                  weightArray[yHr].int +
                  imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT; inc fgPtr
    fg[3] += weight * fgPtr[].CalcT

    fg[0] = fg[0] shr imageFilterShift
    fg[1] = fg[1] shr imageFilterShift
    fg[2] = fg[2] shr imageFilterShift
    fg[3] = fg[3] shr imageFilterShift

    if fg[OrderT.A.ord] > baseMask:         fg[OrderT.A.ord] = baseMask
    if fg[OrderT.R.ord] > fg[OrderT.A.ord]: fg[OrderT.R.ord] = fg[OrderT.A.ord]
    if fg[OrderT.G.ord] > fg[OrderT.A.ord]: fg[OrderT.G.ord] = fg[OrderT.A.ord]
    if fg[OrderT.B.ord] > fg[OrderT.A.ord]: fg[OrderT.B.ord] = fg[OrderT.A.ord]

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(fg[OrderT.A.ord])
    inc span
    inc base(self).interpolator()
    dec len


type
  SpanImageFilterRgba*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgba*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageFilterRgba[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgba[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = getBaseMask(ColorT) 
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[4, int]
    fgPtr: ptr ValueT
    diameter     = base(self).filter().diameter()
    start        = base(self).filter().start()
    weightArray  = base(self).filter().weightArray()
    xCount, weightY: int
    len = len
    span = span
    x = x
    y = y

  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    x -= base(self).filterDxInt()
    y -= base(self).filterDyInt()

    var
      xHr = x
      yHr = y
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    var
      xFract = xHr and imageSubpixelMask
      yCount = diameter

    yHr = imageSubpixelMask - (yHr and imageSubpixelMask)
    fgPtr = cast[ptr ValueT](base(self).source().span(xLr + start, yLr + start, diameter))

    while true:
      xCount  = diameter
      weightY = weightArray[yHr]
      xHr = imageSubpixelMask - xFract

      while true:
        var weight = sar((weightY * weightArray[xHr] + imageFilterScale div 2), imageFilterShift)
        fg[0] += weight * fgPtr[].int; inc fgPtr
        fg[1] += weight * fgPtr[].int; inc fgPtr
        fg[2] += weight * fgPtr[].int; inc fgPtr
        fg[3] += weight * fgPtr[].int

        dec xCount
        if xCount == 0: break
        xHr  += imageSubpixelScale
        fgPtr = cast[ptr ValueT](base(self).source().nextX())

      dec yCount
      if yCount == 0: break
      yHr  += imageSubpixelScale
      fgPtr = cast[ptr ValueT](base(self).source().nextY())

    fg[0] = sar(fg[0], imageFilterShift)
    fg[1] = sar(fg[1], imageFilterShift)
    fg[2] = sar(fg[2], imageFilterShift)
    fg[3] = sar(fg[3], imageFilterShift)

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderT.A.ord] > baseMask:         fg[OrderT.A.ord] = baseMask
    if fg[OrderT.R.ord] > fg[OrderT.A.ord]: fg[OrderT.R.ord] = fg[OrderT.A.ord]
    if fg[OrderT.G.ord] > fg[OrderT.A.ord]: fg[OrderT.G.ord] = fg[OrderT.A.ord]
    if fg[OrderT.B.ord] > fg[OrderT.A.ord]: fg[OrderT.B.ord] = fg[OrderT.A.ord]

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(fg[OrderT.A.ord])
    inc span
    inc base(self).interpolator()
    dec len


type
  SpanImageResampleRgbaAffine*[Source,Interpolator] = object of SpanImageResampleAffine[Source,Interpolator]

proc initSpanImageResampleRgbaAffine*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageResampleRgbaAffine[S,I] =
  type base = SpanImageResampleAffine[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageResampleRgbaAffine[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResampleAffine[S,I]
    LongT = getLongT(ColorT)
    OrderT = getOrderT(S)
    
  const
    downscaleShift = imageFilterShift
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[4, LongT]
    diameter     = base(self).filter().diameter()
    filterScale = diameter shl imageSubpixelShift
    radiusX     = sar((diameter * base(self).mRx), 1)
    radiusY     = sar((diameter * base(self).mRy), 1)
    lenXLr      = sar((diameter * base(self).mRx + imageSubpixelMask), imageSubpixelShift)
    weightArray = base(self).filter().weightArray()
    x = x
    y = y
    span = span
    len = len
    
  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    x += base(self).filterDxInt() - radiusX
    y += base(self).filterDyInt() - radiusY

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    var
      yLr = sar(y, imageSubpixelShift)
      yHr = sar(((imageSubpixelMask - (y and imageSubpixelMask)) * base(self).mRyInv), imageSubpixelShift)
      totalWeight = LongT(0)
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * base(self).mRxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, lenXLr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2

      while true:
        var weight = LongT(sar((weightY * weightArray[xHr].int + imageFilterScale div 2), downscaleShift))
        fg[0] += fgPtr[].LongT * weight; inc fgPtr
        fg[1] += fgPtr[].LongT * weight; inc fgPtr
        fg[2] += fgPtr[].LongT * weight; inc fgPtr
        fg[3] += fgPtr[].LongT * weight; inc fgPtr
        totalWeight += weight
        xHr  += base(self).mRxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueT](base(self).source().nextX())

      yHr += base(self).mRyInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueT](base(self).source().nextY())

    fg[0] = fg[0] div totalWeight
    fg[1] = fg[1] div totalWeight
    fg[2] = fg[2] div totalWeight
    fg[3] = fg[3] div totalWeight

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderT.A.ord] > baseMask:            fg[OrderT.A.ord] = baseMask
    if fg[OrderT.R.ord] > fg[OrderT.A.ord]: fg[OrderT.R.ord] = fg[OrderT.A.ord]
    if fg[OrderT.G.ord] > fg[OrderT.A.ord]: fg[OrderT.G.ord] = fg[OrderT.A.ord]
    if fg[OrderT.B.ord] > fg[OrderT.A.ord]: fg[OrderT.B.ord] = fg[OrderT.A.ord]

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(fg[OrderT.A.ord])

    inc span
    inc base(self).interpolator()
    dec len



type
  SpanImageResampleRgba*[Source, Interpolator] = object of SpanImageResample[Source, Interpolator]

proc initSpanImageResampleRgba*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageResampleRgba[S,I] =
  type base = SpanImageResample[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageResampleRgba[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResample[S,I]
    LongT = getLongT(ColorT)
    OrderT = getOrderT(S)
    
  const
    downscaleShift = imageFilterShift
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
  var
    fg: array[4, LongT]
    diameter = base(self).filter().diameter()
    filterScale = diameter shl imageSubpixelShift
    weightArray = base(self).filter().weightArray()
    x = x
    y = y
    span = span
    len = len
    
  doWhile len != 0:
    var
      rx, ry: int
      rxInv = imageSubpixelScale
      ryInv = imageSubpixelScale

    base(self).interpolator().coordinates(x,  y)
    base(self).interpolator().localScale(rx, ry)
    base(self).adjustScale(rx, ry)

    rxInv = imageSubpixelScale * imageSubpixelScale div rx
    ryInv = imageSubpixelScale * imageSubpixelScale div ry

    var
      radiusX = sar((diameter * rx), 1)
      radiusY = sar((diameter * ry), 1)
      lenXLr  = sar((diameter * rx + imageSubpixelMask), imageSubpixelShift)

    x += base(self).filterDxInt() - radiusX
    y += base(self).filterDyInt() - radiusY

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    var
      yLr = sar(y, imageSubpixelShift)
      yHr = sar(((imageSubpixelMask - (y and imageSubpixelMask)) * ryInv), imageSubpixelShift)
      totalWeight = LongT(0)
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * rxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, lenXLr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2

      while true:
        var weight = LongT(sar((weightY * weightArray[xHr].int + imageFilterScale div 2), downscaleShift))
        fg[0] += fgPtr[].LongT * weight; inc fgPtr
        fg[1] += fgPtr[].LongT * weight; inc fgPtr
        fg[2] += fgPtr[].LongT * weight; inc fgPtr
        fg[3] += fgPtr[].LongT * weight; inc fgPtr
        totalWeight += weight
        xHr  += rxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueT](base(self).source().nextX())

      yHr += ryInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueT](base(self).source().nextY())

    fg[0] = fg[0] div totalWeight
    fg[1] = fg[1] div totalWeight
    fg[2] = fg[2] div totalWeight
    fg[3] = fg[3] div totalWeight

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderT.A.ord] > baseMask:            fg[OrderT.A.ord] = baseMask
    if fg[OrderT.R.ord] > fg[OrderT.R.ord]: fg[OrderT.R.ord] = fg[OrderT.R.ord]
    if fg[OrderT.G.ord] > fg[OrderT.G.ord]: fg[OrderT.G.ord] = fg[OrderT.G.ord]
    if fg[OrderT.B.ord] > fg[OrderT.B.ord]: fg[OrderT.B.ord] = fg[OrderT.B.ord]

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(fg[OrderT.A.ord])

    inc span
    inc base(self).interpolator()
    dec len
