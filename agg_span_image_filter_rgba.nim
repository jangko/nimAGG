import agg_basics, agg_color_rgba, agg_span_image_filter
import agg_span_interpolator_linear, agg_image_filters

type
  SpanImageFilterRgbaNN[Source, Interpolator] = object of SpanImageFilter[Source, Interpolator]

proc initSpanImageFilterRgbaNN*[S,I](src: var S, inter: var I): SpanImageFilterRgbaNN[S,I] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbaNN[S,I], span: ptr ColorT, x, y, len: int) =
  type base = SpanImageFilter[S,I]
  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  doWhile len != 0:
    base(self).interpolator().coordinates(x, y)
    var fgPtr = cast[ptr ValueType](base(self).source().span(sar(x, imageSubpixelShift),
                                sar(y, imageSubpixelShift), 1))
    span.r = fgPtr[OrderType.R.ord]
    span.g = fgPtr[OrderType.G.ord]
    span.b = fgPtr[OrderType.B.ord]
    span.a = fgPtr[OrderType.A.ord]
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
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcType]
    fgPtr: ptr ValueType

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)
    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr,  imageSubpixelShift)
      weight: int

    fg[0] = imageSubpixelScale * imageSubpixelScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, 2))
    weight = (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = xHr * (imageSubpixelScale - yHr)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextY())
    weight = (imageSubpixelScale - xHr) * yHr
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = xHr * yHr
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    span.r = ValueType(fg[OrderType.R.ord] shr (imageSubpixelShift * 2))
    span.g = ValueType(fg[OrderType.G.ord] shr (imageSubpixelShift * 2))
    span.b = ValueType(fg[OrderType.B.ord] shr (imageSubpixelShift * 2))
    span.a = ValueType(fg[OrderType.A.ord] shr (imageSubpixelShift * 2))

    inc span
    inc base(self).interpolator()
    dec len

type
  SpanImageFilterRgbaBilinearClip*[Source, Interpolator, ColorT] = object of SpanImageFilter[Source, Interpolator]
    mBackColor: ColorT

proc initSpanImageFilterRgbaBilinearClip*[S,I,ColorT](src: var S,
  backColor: ColorT, inter: var I): SpanImageFilterRgbaBilinearClip[S,I,ColorT] =
  type base = SpanImageFilter[S,I]
  base(result).init(src, inter)
  result.mBackColor = backColor

proc backgroundColor*[S,I,ColorT](self: SpanImageFilterRgbaBilinearClip[S,I,ColorT]): ColorT = self.mBackColor
proc backgroundColor*[S,I,ColorT](self: var SpanImageFilterRgbaBilinearClip[S,I,ColorT], v: ColorT) = self.mBackColor = v

proc generate*[S,I,ColorT](self: var SpanImageFilterRgbaBilinearClip[S,I,ColorT],
  span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageFilter[S,I]
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcType]
    backR = self.mBackColor.r
    backG = self.mBackColor.g
    backB = self.mBackColor.b
    backA = self.mBackColor.a
    fgPtr: ptr ValueType
    maxx = base(self).source().width() - 1
    maxy = base(self).source().height() - 1

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)
    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr,  imageSubpixelShift)
      weight: int

    if xLr >= 0 and yLr >= 0 and xLr < maxx and yLr < maxy:

      fg[0] = imageSubpixelScale * imageSubpixelScale div 2
      fg[1] = fg[0]
      fg[2] = fg[0]
      fg[3] = fg[0]

      xHr = xHr and imageSubpixelMask
      yHr = yHr and imageSubpixelMask
      fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))

      weight = (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)
      fg[0] += weight * fgPtr[]; inc fgPtr
      fg[1] += weight * fgPtr[]; inc fgPtr
      fg[2] += weight * fgPtr[]; inc fgPtr
      fg[3] += weight * fgPtr[]; inc fgPtr

      weight = xHr * (imageSubpixelScale - yHr)
      fg[0] += weight * fgPtr[]; inc fgPtr
      fg[1] += weight * fgPtr[]; inc fgPtr
      fg[2] += weight * fgPtr[]; inc fgPtr
      fg[3] += weight * fgPtr[]; inc fgPtr

      inc yLr
      fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))

      weight = (imageSubpixelScale - xHr) * yHr
      fg[0] += weight * fgPtr[]; inc fgPtr
      fg[1] += weight * fgPtr[]; inc fgPtr
      fg[2] += weight * fgPtr[]; inc fgPtr
      fg[3] += weight * fgPtr[]; inc fgPtr

      weight = xHr * yHr
      fg[0] += weight * fgPtr[]; inc fgPtr
      fg[1] += weight * fgPtr[]; inc fgPtr
      fg[2] += weight * fgPtr[]; inc fgPtr
      fg[3] += weight * fgPtr[]; inc fgPtr

      fg[0] = fg[0] shr (imageSubpixelShift * 2)
      fg[1] = fg[1] shr (imageSubpixelShift * 2)
      fg[2] = fg[2] shr (imageSubpixelShift * 2)
      fg[3] = fg[3] shr (imageSubpixelShift * 2)
    else:
      if xLr < -1 or yLr < -1 or xLr > maxx or yLr > maxy:
        fg[OrderType.R.ord] = backR
        fg[OrderType.G.ord] = backG
        fg[OrderType.B.ord] = backB
        fg[OrderType.A.ord] = backA
      else:
        fg[0] = imageSubpixelScale * imageSubpixelScale div 2
        fg[1] = fg[0]
        fg[2] = fg[0]
        fg[3] = fg[0]

        xHr = xHr and imageSubpixelMask
        yHr = yHr and imageSubpixelMask

        weight = (imageSubpixelScale - xHr) * (imageSubpixelScale - yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))
          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderType.R.ord] += backR * weight
          fg[OrderType.G.ord] += backG * weight
          fg[OrderType.B.ord] += backB * weight
          fg[OrderType.A.ord] += backA * weight

        inc xLr
        weight = xHr * (imageSubpixelScale - yHr)
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))

          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderType.R] += backR * weight
          fg[OrderType.G] += backG * weight
          fg[OrderType.B] += backB * weight
          fg[OrderType.A] += backA * weight

        dec xLr
        inc yLr

        weight = (imageSubpixelScale - xHr) * yHr
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))
          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderType.R.ord] += backR * weight
          fg[OrderType.G.ord] += backG * weight
          fg[OrderType.B.ord] += backB * weight
          fg[OrderType.A.ord] += backA * weight

        inc xLr
        weight = xHr * yHr
        if xLr >= 0 and yLr >= 0 and xLr <= maxx and yLr <= maxy:
          fgPtr = cast[ptr ValueType](base(self).source().rowPtr(yLr) + (xLr shl 2))

          fg[0] += weight * fgPtr[]; inc fgPtr
          fg[1] += weight * fgPtr[]; inc fgPtr
          fg[2] += weight * fgPtr[]; inc fgPtr
          fg[3] += weight * fgPtr[]; inc fgPtr
        else:
          fg[OrderType.R.ord] += backR * weight
          fg[OrderType.G.ord] += backG * weight
          fg[OrderType.B.ord] += backB * weight
          fg[OrderType.A.ord] += backA * weight

        fg[0] = fg[0] shr (imageSubpixelShift * 2)
        fg[1] = fg[1] shr (imageSubpixelShift * 2)
        fg[2] = fg[2] shr (imageSubpixelShift * 2)
        fg[3] = fg[3] shr (imageSubpixelShift * 2)

    span.r = ValueType(fg[OrderType.R.ord])
    span.g = ValueType(fg[OrderType.G.ord])
    span.b = ValueType(fg[OrderType.B.ord])
    span.a = ValueType(fg[OrderType.A.ord])
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
    CalcType = getCalcType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: array[4, CalcType]
    fgPtr: ptr ValueType
    weightArray = base(self).filter().weightArray() +
                  ((base(self).filter().diameter()/2 - 1) shl imageSubpixelShift)

  doWhile len != 0:
    var xHr, yHr: int
    base(self).interpolator().coordinates(xHr, yHr)

    xHr -= base(self).filterDxInt()
    yHr -= base(self).filterDyInt()

    var
      xLr = sar(xHr, imageSubpixelShift)
      yLr = sar(yHr,  imageSubpixelShift)
      weight: int

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    xHr = xHr and imageSubpixelMask
    yHr = yHr and imageSubpixelMask

    fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, 2))
    weight = sar((weightArray[xHr + imageSubpixelScale].int *
                  weightArray[yHr + imageSubpixelScale].int +
                  imageFilterScale div 2), imageFilterShift)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = sar((weightArray[xHr].int *
                  weightArray[yHr + imageSubpixelScale].int +
                  imageFilterScale div 2), imageFilterShift)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextY())
    weight = sar((weightArray[xHr + imageSubpixelScale].int *
                  weightArray[yHr].int + imageFilterScale div 2), imageFilterShift)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fgPtr = cast[ptr ValueType](base(self).source().nextX())
    weight = sar((weightArray[xHr].int *
                  weightArray[yHr].int +
                  imageFilterScale div 2), imageFilterShift)
    fg[0] += weight * fgPtr[]; inc fgPtr
    fg[1] += weight * fgPtr[]; inc fgPtr
    fg[2] += weight * fgPtr[]; inc fgPtr
    fg[3] += weight * fgPtr[]

    fg[0] = fg[0] shr imageFilterShift
    fg[1] = fg[1] shr imageFilterShift
    fg[2] = fg[2] shr imageFilterShift
    fg[3] = fg[3] shr imageFilterShift

    if fg[OrderType.A.ord] > baseMask:            fg[OrderType.A.ord] = baseMask
    if fg[OrderType.R.ord] > fg[OrderType.A.ord]: fg[OrderType.R.ord] = fg[OrderType.A.ord]
    if fg[OrderType.G.ord] > fg[OrderType.A.ord]: fg[OrderType.G.ord] = fg[OrderType.A.ord]
    if fg[OrderType.B.ord] > fg[OrderType.A.ord]: fg[OrderType.B.ord] = fg[OrderType.A.ord]

    span.r = ValueType(fg[OrderType.R.ord])
    span.g = ValueType(fg[OrderType.G.ord])
    span.b = ValueType(fg[OrderType.B.ord])
    span.a = ValueType(fg[OrderType.A.ord])
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
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: array[4, int]
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

    fg[0] = imageFilterScale div 2
    fg[1] = fg[0]
    fg[2] = fg[0]
    fg[3] = fg[0]

    var
      xFract = xHr and imageSubpixelMask
      yCount = diameter

    yHr = imageSubpixelMask - (yHr and imageSubpixelMask)
    fgPtr = cast[ptr ValueType](base(self).source().span(xLr + start, yLr + start, diameter))

    while true:
      xCount  = diameter
      weightY = weightArray[yHr]
      xHr = imageSubpixelMask - xFract

      while true:
        var weight = sar((weightY * weightArray[xHr] + imageFilterScale div 2), imageFilterShift)
        fg[0] += weight * fgPtr[]; inc fgPtr
        fg[1] += weight * fgPtr[]; inc fgPtr
        fg[2] += weight * fgPtr[]; inc fgPtr
        fg[3] += weight * fgPtr[]

        dec xCount
        if xCount == 0: break
        xHr  += imageSubpixelScale
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      dec yCount
      if yCount == 0: break
      yHr  += imageSubpixelScale
      fgPtr = cast[ptr ValueType](base(self).source().nextY())

    fg[0] = fg[0] shr imageFilterShift
    fg[1] = fg[1] shr imageFilterShift
    fg[2] = fg[2] shr imageFilterShift
    fg[3] = fg[3] shr imageFilterShift

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderType.A.ord] > baseMask:            fg[OrderType.A.ord] = baseMask
    if fg[OrderType.R.ord] > fg[OrderType.A.ord]: fg[OrderType.R.ord] = fg[OrderType.A.ord]
    if fg[OrderType.G.ord] > fg[OrderType.A.ord]: fg[OrderType.G.ord] = fg[OrderType.A.ord]
    if fg[OrderType.B.ord] > fg[OrderType.A.ord]: fg[OrderType.B.ord] = fg[OrderType.A.ord]

    span.r = ValueType(fg[OrderType.R.ord])
    span.g = ValueType(fg[OrderType.G.ord])
    span.b = ValueType(fg[OrderType.B.ord])
    span.a = ValueType(fg[OrderType.A.ord])
    inc span
    inc base(self).interpolator()
    dec len


type
  SpanImageResampleRgbaAffine*[Source] = object of SpanImageResampleAffine[Source]

proc initSpanImageResampleRgbaAffine*[S](src: var S,
  inter: var SpanInterpolatorLinear, filter: var ImageFilterLut): SpanImageResampleRgbaAffine[S] =
  type base = SpanImageResampleAffine[S]
  base(result).init(src, inter, filter)

proc generate*[S,ColorT](self: var SpanImageResampleRgbaAffine[S], span: ptr ColorT, x, y, len: int) =
  type
    base = SpanImageResampleAffine[S]
    LongType = getLongType(ColorT)
    ValueType = getValueType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)

  var
    fg: array[4, LongType]
    diameter     = base(self).filter().diameter()
    filterScale = diameter shl imageSubpixelShift
    radiusX     = sar((diameter * base(self).mRx), 1)
    radiusY     = sar((diameter * base(self).mRy), 1)
    lenXLr      = sar((diameter * base(self).mRx + imageSubpixelMask), imageSubpixelShift)
    weightArray = base(self).filter().weightArray()

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
      totalWeight = 0
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * base(self).mRxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, lenXLr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2

      while true:
        var weight = sar((weightY * weightArray[xHr] + imageFilterScale div 2), downscaleShift)
        fg[0] += fgPtr[] * weight; inc fgPtr
        fg[1] += fgPtr[] * weight; inc fgPtr
        fg[2] += fgPtr[] * weight; inc fgPtr
        fg[3] += fgPtr[] * weight; inc fgPtr
        totalWeight += weight
        xHr  += base(self).mRxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      yHr += base(self).mRyInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueType](base(self).source().nextY())

    fg[0] = fg[0] div totalWeight
    fg[1] = fg[1] div totalWeight
    fg[2] = fg[2] div totalWeight
    fg[3] = fg[3] div totalWeight

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderType.A.ord] > baseMask:            fg[OrderType.A.ord] = baseMask
    if fg[OrderType.R.ord] > fg[OrderType.A.ord]: fg[OrderType.R.ord] = fg[OrderType.A.ord]
    if fg[OrderType.G.ord] > fg[OrderType.A.ord]: fg[OrderType.G.ord] = fg[OrderType.A.ord]
    if fg[OrderType.B.ord] > fg[OrderType.A.ord]: fg[OrderType.B.ord] = fg[OrderType.A.ord]

    span.r = ValueType(fg[OrderType.R.ord])
    span.g = ValueType(fg[OrderType.G.ord])
    span.b = ValueType(fg[OrderType.B.ord])
    span.a = ValueType(fg[OrderType.A.ord])

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
    LongType = getLongType(ColorT)

  base(self).interpolator().begin(x + base(self).filterDxDbl(),
                                  y + base(self).filterDyDbl(), len)
  var
    fg: array[4, LongType]
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
      totalWeight = 0
      xLr = sar(x, imageSubpixelShift)
      xHr = sar(((imageSubpixelMask - (x and imageSubpixelMask)) * rxInv), imageSubpixelShift)
      xHr2 = xHr
      fgPtr = cast[ptr ValueType](base(self).source().span(xLr, yLr, lenXLr))

    while true:
      var weightY = weightArray[yHr]
      xHr = xHr2

      while true:
        var weight = sar((weightY * weightArray[xHr].int + imageFilterScale div 2), downscaleShift)
        fg[0] += fgPtr[] * weight; inc fgPtr
        fg[1] += fgPtr[] * weight; inc fgPtr
        fg[2] += fgPtr[] * weight; inc fgPtr
        fg[3] += fgPtr[] * weight; inc fgPtr
        totalWeight += weight
        xHr  += rxInv
        if xHr >= filterScale: break
        fgPtr = cast[ptr ValueType](base(self).source().nextX())

      yHr += ryInv
      if yHr >= filterScale: break
      fgPtr = cast[ptr ValueType](base(self).source().nextY())

    fg[0] = fg[0] div totalWeight
    fg[1] = fg[1] div totalWeight
    fg[2] = fg[2] div totalWeight
    fg[3] = fg[3] div totalWeight

    if fg[0] < 0: fg[0] = 0
    if fg[1] < 0: fg[1] = 0
    if fg[2] < 0: fg[2] = 0
    if fg[3] < 0: fg[3] = 0

    if fg[OrderType.A.ord] > baseMask:            fg[OrderType.A.ord] = baseMask
    if fg[OrderType.R.ord] > fg[OrderType.R.ord]: fg[OrderType.R.ord] = fg[OrderType.R.ord]
    if fg[OrderType.G.ord] > fg[OrderType.G.ord]: fg[OrderType.G.ord] = fg[OrderType.G.ord]
    if fg[OrderType.B.ord] > fg[OrderType.B.ord]: fg[OrderType.B.ord] = fg[OrderType.B.ord]

    span.r = ValueType(fg[OrderType.R.ord])
    span.g = ValueType(fg[OrderType.G.ord])
    span.b = ValueType(fg[OrderType.B.ord])
    span.a = ValueType(fg[OrderType.A.ord])

    inc span
    inc base(self).interpolator()
    dec len
