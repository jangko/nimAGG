import agg_basics, agg_color_gray, agg_span_image_filter, agg_image_filters
import agg_span_interpolator_linear

type
  SpanImageFilterGrayNN*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterGrayNN*[S,I](src: var S, inter: var I): SpanImageFilterGrayNN[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterGrayNN[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  var
    len = len
    x = x
    y = y

  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    span.v = cast[ptr ValueType](base(self).source().span(x shr imageSubpixelShift,
                             y shr imageSubpixelShift, 1))[]
    span.a = baseMask
    inc span
    inc base(self).interpolator()
    dec len


type
  SpanImageFilterGrayBilinear*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterGrayBilinear*[S,I](src: var S, inter: var I): SpanImageFilterGrayBilinear[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter, 0)

proc generate*[S,I,ColorT](self: var SpanImageFilterGrayBilinear[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  var
    fg: CalcType
    fgPtr: ptr ValueType

  doWhile len != 0:
    var
      xHr, yHr: int

    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = xHr shr imageSubpixelShift
      yLr = yHr shr imageSubpixelShift

    fg = imageSubpixelScale * imageSubpixelScale / 2

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, 2))
    fg   += fgPtr[] * (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    fg   += fgPtr[] * xHr * (imageSubpixelScale - yHr)

    fgPtr = cast[ptr ValueType](base(self).source().nextY())
    fg   += fgPtr[] * (imageSubpixelScale - xHr) * yHr

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    fg   += fgPtr[] * xHr * yHr

    span.v = ValueType(fg shr (imageSubpixelShift * 2))
    span.a = baseMask
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterGrayBilinearClip*[Source, Interpolator, ColorT] = object of SpanImageFilter[Source, Interpolator]
    mBackColor: ColorT

proc initSpanImageFilterGrayBilinearClip*[S,I,ColorT](src: var S,
  backColor: ColorT, inter: var I): SpanImageFilterGrayBilinearClip[S, I, ColorT] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)
  result.mBackColor = backColor

proc backgroundColor*[S,I,ColorT](self: SpanImageFilterGrayBilinearClip[S, I, ColorT]): ColorT =
  self.mBackColor

proc backgroundColor*[S,I,ColorT](self: var SpanImageFilterGrayBilinearClip[S, I, ColorT], v: ColorT) =
  self.mBackColor = v

proc generate*[S,I,ColorT](self: var SpanImageFilterGrayBilinearClip[S, I, ColorT],
  span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  var
    fg, srcAlpha: CalcType
    fgPtr: ptr ValueType
    backV = self.mBackColor.v
    backA = self.mBackColor.a
    maxx = base(self).source().width() - 1
    maxy = base(self).source().height() - 1

  doWhile len != 0:
    var  xHr, yHr: int

    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)

    if xLr >= 0 and yLr >= 0 and xLr <  maxx and yLr <  maxy:
      fg = imageSubpixelScale * imageSubpixelScale div 2

      xHr = xHr and imageSubpixelMask
      yHr = yHr and imageSubpixelMask
      fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)

      fg += fgPtr[] * (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)
      inc fgPtr
      fg += fgPtr[] * (imageSubpixelScale - yHr) * xHr
      inc fgPtr

      inc yLr
      fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)

      fg += fgPtr[] * (imageSubpixelScale - xHr) * yHr
      inc fgPtr
      fg += fgPtr[] * xHr * yHr
      inc fgPtr

      fg = fg shr (imageSubpixelShift * 2)
      srcAlpha = baseMask
    else:
      if xLr < -1 or yLr < -1 or xLr > maxx or yLr > maxy:
        fg       = backV
        srcAlpha = backA
      else:
        srcAlpha = imageSubpixelScale * imageSubpixelScale div 2
        fg = srcAlpha

        xHr = xHr and imageSubpixelMask
        yHr = yHr and imageSubpixelMask

        var weight = (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fg += weight * cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)[]
          srcAlpha += weight * baseMask
        else:
          fg       += backV * weight
          srcAlpha += backA * weight

        inc xLr
        weight = xHr * (imageSubpixelScale - yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fg += weight * cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)[]
          srcAlpha += weight * baseMask
        else:
          fg       += backV * weight
          srcAlpha += backA * weight

        dec xLr
        inc yLr

        weight = (imageSubpixelScale - xHr) * yHr
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fg += weight * cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)[]
          srcAlpha += weight * baseMask
        else:
          fg       += backV * weight
          srcAlpha += backA * weight

        inc xLr
        weight = xHr * yHr
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fg += weight * cast[ptr ValueType](base(self).source().rowPtr(yLr) + xLr)[]
          srcAlpha += weight * baseMask
        else:
          fg       += backV * weight
          srcAlpha += backA * weight

        fg       = fg shr (imageSubpixelShift * 2)
        srcAlpha = srcAlpha shr (imageSubpixelShift * 2)

    span.v = ValueType(fg)
    span.a = ValueType(srcAlpha)
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterGray2x2*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterGray2x2*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageFilterGray2x2[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFilterGray2x2[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  var
    fg: CalcType
    fgPtr: ptr ValueType
    weightArray = base(self).filter().weightArray() +
                  ((base(self).filter().diameter() div 2 - 1) shl imageSubpixelShift)

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)

    fg = imageFilterScale div 2

    xHr = xHr and imageSubpixelMaskv
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, 2))
    weight = (weightArray[xHr + imageSubpixelScale] *
              weightArray[yHr + imageSubpixelScale] +
              imageFilterScale div 2) shr imageFilterShift
    fg += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = (weightArray[xHr] *
              weightArray[yHr + imageSubpixelScale] +
              imageFilterScale div 2) shr imageFilterShift
    fg += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextY())
    weight = (weightArray[xHr + imageSubpixelScale] *
              weightArray[yHr] +
              imageFilterScale div 2) shr imageFilterShift
    fg += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = (weightArray[xHr] *
              weightArray[yHr] +
              imageFilterScale div 2) shr imageFilterShift
    fg += weight * fgPtr[]

    fg = fg shr imageFilterShift
    if fg > baseMask: fg = baseMask

    span.v = ValueType(fg)
    span.a = baseMask
    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFiltergray*[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterGray*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageFiltergray[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageFiltergray[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: int
    fgPtr: ptr ValueType
    diameter     = base(self).filter().diameter()
    start        = base(self).filter().start()
    weightArray  = base(self).filter().weightArray()
    xCount, weightY: int

  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)

    x -= base(self).filterDxInt()
    y -= base(self).filterDyInt()

    var
      xHr = x
      yHr = y
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr, imageSubpixelShift)
      xFract = xHr and imageSubpixelMask
      yCount = diameter

    fg = imageFilterScale div 2

    yHr = imageSubpixelMask - (yHr and imageSubpixelMask)
    fgPtr = cast[ptr ValueType](base(self).source().span(xLr + start, yLr + start, diameter))

    while true:
      xCount  = diameter
      weightY = weightArray[yHr]
      xHr = imageSubpixelMask - xFract
      while true:
        fg += fgPtr[] * sar((weightY * weightArray[xHr] + imageFilterScale div 2), imageFilterShift)
        dec xCount
        if xCount == 0: break
        xHr  += imageSubpixelScale
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      dec yCount
      if yCount == 0: break
      yHr  += imageSubpixelScale
      fgPtr = cast[ptr ValueType](base(self).source().nextY())

    fg = sar(fg, imageFilterShift)
    if fg < 0: fg = 0
    if fg > baseMask: fg = baseMask
    span.v = ValueType(fg)
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageResampleGrayAffine[Source] = object of SpanImageResampleAffine[Source]

proc initSpanImageResampleGrayAffine*[S](src: var S,
  inter: var SpanInterpolatorLinear, filter: var ImageFilterLut): SpanImageResampleGrayAffine[S] =
  type base = SpanImageResampleAffine[S]
  base(result).init(src, inter, filter)

proc generate*[S,ColorT](self: var SpanImageResampleGrayAffine[S], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResampleAffine[S]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)
    LongType = getLongType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: LongType
    diameter    = base(self).filter().diameter()
    filterScale = diameter shl imageSubpixelShift
    radiusX     = sar((diameter * base(self).mRx), 1)
    radiusY     = sar((diameter * base(self).mRy), 1)
    lenXlr      = sar((diameter * base(self).mRx + imageSubpixelMask), imageSubpixelShift)
    weightArray = base(self).filter().weightArray()

  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)

    x += base(self).filterDxInt() - radiusX
    y += base(self).filterDyInt() - radiusY

    fg = imageFilterScale div 2

    var
      yLr = sar(y, imageSubpixelShift)
      yHr = sar(((imageSubpixelMask - (y and imageSubpixelMask)) * base(self).mRyInv), imageSubpixelShift)
      totalWeight = 0
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * base(self).mRxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, lenXlr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2
      while true:
        var weight = sar((weightY * weightArray[xHr] + imageFilterScale / 2), downScaleShift)

        fg += fgPtr[] * weight
        totalWeight += weight
        xHr  += base(self).mRxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      yHr += base(self).mRyInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueType](base(self).source().nextY())


    fg = fg div totalWeight
    if fg < 0: fg = 0
    if fg > baseMask: fg = baseMask

    span.v = ValueType(fg)
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageResampleGray[Source, Interpolator] = object of SpanImageResample[Source, Interpolator]

proc initSpanImageResampleGray*[S,I](src: var S,
  inter: var I, filter: var ImageFilterLut): SpanImageResampleGray[S,I] =
  type base = SpanImageResample[S, I]
  base(result).init(src, inter, filter)

proc generate*[S,I,ColorT](self: var SpanImageResampleGray[S,I], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResample[S, I]
    ValueType = getValueType(ColorT)
    LongType = getLongType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: LongType
    diameter = base(self).filter().diameter()
    filterScale = diameter shl imageSubpixelShift
    weightArray = base(self).filter().weightArray()

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
      lenXlr  = sar((diameter * rx + imageSubpixelMask), imageSubpixelShift)

    x += base(self).filterDxInt() - radiusX
    y += base(self).filterDyInt() - radiusY

    fg = imageFilterScale div 2

    var
      yLr = sar(y, imageSubpixelShift)
      yHr = sar(((imageSubpixelMask - (y and imageSubpixelMask)) * ryInv), imageSubpixelShift)
      totalWeight = 0
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * rxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, lenXlr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2

      while true:
        var weight = sar((weightY * weightArray[xHr] + imageFilterScale div 2), downScaleShift)
        fg += fgPtr[] * weight
        totalWeight += weight
        xHr  += rxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      yHr += ryInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueType](base(self).source().nextY())

    fg = fg div totalWeight
    if fg < 0: fg = 0
    if fg > baseMask: fg = baseMask

    span.v = ValueType(fg)
    span.a = baseMask

    inc span
    inc base(self).interpolator()
    dec len
