import agg_basics, agg_color_rgba, agg_span_image_filter, agg_pixfmt_rgb
import agg_span_interpolator_linear, agg_image_filters, strutils

export agg_span_image_filter

type
  SpanImageFilterRgbNN*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgbNN*[S,I](src: var S, inter: var I): SpanImageFilterRgbNN[S,I] =
  type base = SpanImageFilter[S, I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbNN[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S, I]
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = getBaseMask(ColorT)

  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
                                  
  var
    x = x
    y = y
    len = len
    span = span
    
  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    var fgPtr = cast[ptr ValueT](base(self).source().span(sar(x, imageSubpixelShift),
                                                             sar(y, imageSubpixelShift), 1))
    span.r = fgPtr[OrderT.R]
    span.g = fgPtr[OrderT.G]
    span.b = fgPtr[OrderT.B]
    span.a = baseMask
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgbBilinear*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgbBilinear*[S,I](src: var S, inter: var I): SpanImageFilterRgbBilinear[S,I] =
  type base = SpanImageFilter[S, I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbBilinear[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S, I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
  var
    fg: array[3, CalcT]
    fgPtr: ptr ValueT
    span = span
    len = len

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)
      
    fg[0] = imageSubpixelScale * imageSubpixelScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, 2))
    var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(xHr * (imageSubpixelScale - yHr))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextY())
    weight = CalcT((imageSubpixelScale - xHr) * yHr)
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(xHr * yHr)
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT

    span.r = ValueT(fg[OrderT.R.ord] shr (imageSubpixelShift * 2))
    span.g = ValueT(fg[OrderT.G.ord] shr (imageSubpixelShift * 2))
    span.b = ValueT(fg[OrderT.B.ord] shr (imageSubpixelShift * 2))
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgbBilinearClip*[Source, Interpolator, ColorT] = object of SpanImageFilter[Source, Interpolator]
    mBackColor: ColorT

proc initSpanImageFilterRgbBilinearClip*[S,I,ColorT](src: var S,
  backColor: ColorT, inter: var I): SpanImageFilterRgbBilinearClip[S,I,ColorT] =
  type base = SpanImageFilter[S, I]
  base(result).init(src, inter)
  result.mBackColor = backColor

proc backgroundColor*[S,I,ColorT](self: SpanImageFilterRgbBilinearClip[S,I,ColorT]): ColorT = self.mBackColor
proc backgroundColor*[S,I,ColorT](self: var SpanImageFilterRgbBilinearClip[S,I,ColorT], v: ColorT) = self.mBackColor = v

proc prepare*[S,I,ColorT](self: SpanImageFilterRgbBilinearClip[S,I,ColorT]) =
  type base = SpanImageFilter[S, I]
  base(self).prepare()
  
proc generate*[S,I,ColorT](self: var SpanImageFilterRgbBilinearClip[S,I,ColorT],
  span: ptr ColorT, x, y, len: int) =
  
  type
    base = SpanImageFilter[S, I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[3, CalcT]
    srcAlpha: CalcT
    backR = CalcT(self.mBackColor.r)
    backG = CalcT(self.mBackColor.g)
    backB = CalcT(self.mBackColor.b)
    backA = CalcT(self.mBackColor.a)
    fgPtr: ptr ValueT
    maxx = base(self).source().width() - 1
    maxy = base(self).source().height() - 1
    span = span
    len = len

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

      xHr = xHr and imageSubpixelMask
      yHr = yHr and imageSubpixelMask

      fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
      var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr

      weight = CalcT(xHr * (imageSubpixelScale - yHr))
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr

      inc yLr
      fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
      weight = CalcT((imageSubpixelScale - xHr) * yHr)
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr

      weight = CalcT(xHr * yHr)
      fg[0] += weight * fgPtr[].CalcT; inc fgPtr
      fg[1] += weight * fgPtr[].CalcT; inc fgPtr
      fg[2] += weight * fgPtr[].CalcT; inc fgPtr

      fg[0] = fg[0] shr (imageSubpixelShift * 2)
      fg[1] = fg[1] shr (imageSubpixelShift * 2)
      fg[2] = fg[2] shr (imageSubpixelShift * 2)
      srcAlpha = baseMask
    else:
      if xLr < -1 or yLr < -1 or xLr > maxx or yLr > maxy:
        fg[OrderT.R.ord] = backR
        fg[OrderT.G.ord] = backG
        fg[OrderT.B.ord] = backB
        srcAlpha            = backA
      else:
        fg[0] = imageSubpixelScale * imageSubpixelScale div 2
        fg[1] = fg[0]
        fg[2] = fg[0]
        srcAlpha = fg[0]

        xHr = xHr and imageSubpixelMask
        yHr = yHr and imageSubpixelMask

        var weight = CalcT((imageSubpixelScale - xHr) * (imageSubpixelScale - yHr))
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
          fg[0] += weight * fgPtr[].CalcT; inc fgPtr
          fg[1] += weight * fgPtr[].CalcT; inc fgPtr
          fg[2] += weight * fgPtr[].CalcT; inc fgPtr
          srcAlpha += weight * baseMask
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          srcAlpha            += backA * weight

        inc xLr

        weight = CalcT(xHr * (imageSubpixelScale - yHr))
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
          fg[0]    += weight * fgPtr[].CalcT; inc fgPtr
          fg[1]    += weight * fgPtr[].CalcT; inc fgPtr
          fg[2]    += weight * fgPtr[].CalcT; inc fgPtr
          srcAlpha += weight * baseMask
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          srcAlpha            += backA * weight

        dec xLr
        inc yLr

        weight = CalcT((imageSubpixelScale - xHr) * yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
          fg[0] += weight * fgPtr[].CalcT; inc fgPtr
          fg[1] += weight * fgPtr[].CalcT; inc fgPtr
          fg[2] += weight * fgPtr[].CalcT; inc fgPtr
          srcAlpha += weight * baseMask
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          srcAlpha            += backA * weight

        inc xLr
        weight = CalcT(xHr * yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueT](base(self).source().rowPtr(yLr) + xLr + xLr + xLr)
          fg[0] += weight * fgPtr[].CalcT; inc fgPtr
          fg[1] += weight * fgPtr[].CalcT; inc fgPtr
          fg[2] += weight * fgPtr[].CalcT; inc fgPtr
          srcAlpha += weight * baseMask
        else:
          fg[OrderT.R.ord] += backR * weight
          fg[OrderT.G.ord] += backG * weight
          fg[OrderT.B.ord] += backB * weight
          srcAlpha            += backA * weight

        fg[0] = fg[0] shr (imageSubpixelShift * 2)
        fg[1] = fg[1] shr (imageSubpixelShift * 2)
        fg[2] = fg[2] shr (imageSubpixelShift * 2)
        srcAlpha = srcAlpha shr (imageSubpixelShift * 2)

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(srcAlpha)
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgb2x2*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgb2x2*[S,I](src: var S, inter: var I, filter: var ImageFilterLut): SpanImageFilterRgb2x2[S,I] =
  type base = SpanImageFilter[S, I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgb2x2[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S, I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = CalcT(getBaseMask(ColorT))
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[3, CalcT]
    fgPtr: ptr ValueT
    weightArray = base(self).filter().weightArray()    
    span = span
    len = len
    
  weightArray += ((base(self).filter().diameter() div 2 - 1) shl imageSubpixelShift)
  
  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]

    #echo "$1 $2 $3 $4" % [$xHr , $yHr, $xLr, $yLr]
    
    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueT](base(self).source().span(xLr, yLr, 2))
    var weight = CalcT(sar((weightArray[xHr + imageSubpixelScale].int *
                  weightArray[yHr + imageSubpixelScale].int +
                  imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT        

    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(sar((weightArray[xHr].int * weightArray[yHr + imageSubpixelScale].int + 
      imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT
        
    fgPtr = cast[ptr ValueT](base(self).source().nextY())
    weight = CalcT(sar((weightArray[xHr + imageSubpixelScale].int * weightArray[yHr].int + 
      imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT
        
    fgPtr = cast[ptr ValueT](base(self).source().nextX())
    weight = CalcT(sar((weightArray[xHr].int * weightArray[yHr].int + 
      imageFilterScale div 2), imageFilterShift))
    fg[0] += weight * fgPtr[].CalcT; inc fgPtr
    fg[1] += weight * fgPtr[].CalcT; inc fgPtr
    fg[2] += weight * fgPtr[].CalcT
    
    #echo "$1 $2 $3 $4" % [$weight, $fg[0], $fg[1], $fg[2]]

    fg[0] = fg[0] shr imageFilterShift
    fg[1] = fg[1] shr imageFilterShift
    fg[2] = fg[2] shr imageFilterShift

    #echo "$1 $2 $3 $4" % [$weight, $fg[0], $fg[1], $fg[2]]
    
    if fg[OrderT.R.ord] > baseMask: fg[OrderT.R.ord] = baseMask
    if fg[OrderT.G.ord] > baseMask: fg[OrderT.G.ord] = baseMask
    if fg[OrderT.B.ord] > baseMask: fg[OrderT.B.ord] = baseMask

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = ValueT(baseMask)
    
    #echo "$1 $2 $3" % [ $span.r.int, $span.g.int, $span.b.int]

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgb*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgb*[S,I](src: var S, inter: var I, filter: var ImageFilterLut): SpanImageFilterRgb[S,I] =
  type base= SpanImageFilter[S, I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgb[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S, I]
    CalcT = getCalcT(ColorT)
    ValueT = getValueT(ColorT)
    OrderT = getOrderT(S)
    
  const
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
  var
    fg: array[3, int]
    fgPtr: ptr ValueT
    diameter     = base(self).filter().diameter()
    start        = base(self).filter().start()
    weightArray  = base(self).filter().weightArray()
    xCount, weightY: int
    x = x
    y = y
    span = span
    len = len

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
        var weight = sar((weightY * weightArray[xHr].int + imageFilterScale div 2), imageFilterShift)
        fg[0] += weight * fgPtr[].int; inc fgPtr
        fg[1] += weight * fgPtr[].int; inc fgPtr
        fg[2] += weight * fgPtr[].int

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

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0

    if fg[OrderT.R.ord] > baseMask: fg[OrderT.R.ord] = baseMask
    if fg[OrderT.G.ord] > baseMask: fg[OrderT.G.ord] = baseMask
    if fg[OrderT.B.ord] > baseMask: fg[OrderT.B.ord] = baseMask

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageResampleRgbAffine*[Source] = object of SpanImageResampleAffine[Source]

proc initSpanImageResampleRgbAffine*[S](src: var S,
  inter: var SpanInterpolatorLinear, filter: var ImageFilterLut): SpanImageResampleRgbAffine[S] =
  type base = SpanImageResampleAffine[S]
  base(result).init(src, inter, filter)

proc generate*[S,ColorT](self: var SpanImageResampleRgbAffine[S], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResampleAffine[S]
    LongT = getLongT(ColorT)
    OrderT = getOrderT(S)
    
  const
    downscaleShift = imageFilterShift
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)

  var
    fg: array[3, LongT]
    diameter     = base(self).filter().diameter()
    filterScale  = diameter shl imageSubpixelShift
    radiusX      = sar((diameter * base(self).mRx), 1)
    radiusY      = sar((diameter * base(self).mRy), 1)
    lenXLr       = sar((diameter * base(self).mRx + imageSubpixelMask), imageSubpixelShift)
    weightArray  = base(self).filter().weightArray()
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
        fg[2] += fgPtr[].LongT * weight

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

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0

    if fg[OrderT.R.ord] > baseMask: fg[OrderT.R.ord] = baseMask
    if fg[OrderT.G.ord] > baseMask: fg[OrderT.G.ord] = baseMask
    if fg[OrderT.B.ord] > baseMask: fg[OrderT.B.ord] = baseMask

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageResampleRgb[Source, Interpolator] = object of SpanImageResample[Source, Interpolator]

proc initSpanImageResampleRgb*[S,I](src: var S, inter: var I, filter: var ImageFilterLut): SpanImageResampleRgb[S,I] =
  type base = SpanImageResample[S, I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageResampleRgb[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResample[S, I]
    LongT = getLongT(ColorT)
    OrderT = getOrderT(S)
    
  const
    downscaleShift = imageFilterShift
    baseMask  = getBaseMask(ColorT)
    
  base(self).interpolator().begin(x.float64 + base(self).filterDxDbl(),
                                  y.float64 + base(self).filterDyDbl(), len)
  var
    fg: array[3, LongT]
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
    fg[2] = fg[1]

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
        fg[2] += fgPtr[].LongT * weight
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

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0

    if fg[OrderT.R.ord] > baseMask: fg[OrderT.R.ord] = baseMask
    if fg[OrderT.G.ord] > baseMask: fg[OrderT.G.ord] = baseMask
    if fg[OrderT.B.ord] > baseMask: fg[OrderT.B.ord] = baseMask

    span.r = ValueT(fg[OrderT.R.ord])
    span.g = ValueT(fg[OrderT.G.ord])
    span.b = ValueT(fg[OrderT.B.ord])
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len
