import pixfmt_transposer, basics, sequtils, color_rgba
import pixfmt_gray, pixfmt_rgb, math

const
  stack_blur8_mul* = [
    512'u16,512,456,512,328,456,335,512,405,328,271,456,388,335,292,512,
    454,405,364,328,298,271,496,456,420,388,360,335,312,292,273,512,
    482,454,428,405,383,364,345,328,312,298,284,271,259,496,475,456,
    437,420,404,388,374,360,347,335,323,312,302,292,282,273,265,512,
    497,482,468,454,441,428,417,405,394,383,373,364,354,345,337,328,
    320,312,305,298,291,284,278,271,265,259,507,496,485,475,465,456,
    446,437,428,420,412,404,396,388,381,374,367,360,354,347,341,335,
    329,323,318,312,307,302,297,292,287,282,278,273,269,265,261,512,
    505,497,489,482,475,468,461,454,447,441,435,428,422,417,411,405,
    399,394,389,383,378,373,368,364,359,354,350,345,341,337,332,328,
    324,320,316,312,309,305,301,298,294,291,287,284,281,278,274,271,
    268,265,262,259,257,507,501,496,491,485,480,475,470,465,460,456,
    451,446,442,437,433,428,424,420,416,412,408,404,400,396,392,388,
    385,381,377,374,370,367,363,360,357,354,350,347,344,341,338,335,
    332,329,326,323,320,318,315,312,310,307,304,302,299,297,294,292,
    289,287,285,282,280,278,275,273,271,269,267,265,263,261,259]

  stack_blur8_shr* = [
      9'u8, 11, 12, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17,
     17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19,
     19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20,
     20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21,
     21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
     21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22,
     22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
     22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23,
     23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
     23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
     23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
     23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
     24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
     24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
     24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
     24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24]

template stackBlurCalcRgba(name: untyped, T: typed = uint) =
  type
    name* = object
      r, g, b, a: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc clear*(self: var name) {.inline.} =
    self.r = 0
    self.g = 0
    self.b = 0
    self.a = 0

  proc add*[ArgT](self: var name, v: ArgT) {.inline.} =
    self.r += v.r
    self.g += v.g
    self.b += v.b
    self.a += v.a

  proc add*[ArgT](self: var name, v: ArgT, k: uint) {.inline.} =
    self.r += v.r * k
    self.g += v.g * k
    self.b += v.b * k
    self.a += v.a * k

  proc sub*[ArgT](self: var name, v: ArgT) {.inline.} =
    self.r -= v.r
    self.g -= v.g
    self.b -= v.b
    self.a -= v.a

  proc calcPix*[ArgT](self: var name, v: var ArgT, dv: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    v.r = ValueT(self.r / dv)
    v.g = ValueT(self.g / dv)
    v.b = ValueT(self.b / dv)
    v.a = ValueT(self.a / dv)

  proc calcPix*[ArgT](self: var name, v: var ArgT, mul: uint, sh: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    v.r = ValueT((self.r * mul) shr sh)
    v.g = ValueT((self.g * mul) shr sh)
    v.b = ValueT((self.b * mul) shr sh)
    v.a = ValueT((self.a * mul) shr sh)

stackBlurCalcRgba(StackBlurCalcRgba)

template stackBlurCalcRgb(name: untyped, T: typed = uint) =
  type
    name* = object
      r, g, b: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc clear*(self: var name) {.inline.} =
    self.r = 0
    self.g = 0
    self.b = 0

  proc add*[ArgT](self: var name, v: ArgT) {.inline.} =
    self.r += v.r
    self.g += v.g
    self.b += v.b

  proc add*[ArgT](self: var name, v: ArgT, k: uint) {.inline.} =
    self.r += v.r * k
    self.g += v.g * k
    self.b += v.b * k

  proc sub*[ArgT](self: var name, v: ArgT) {.inline.} =
    self.r -= v.r
    self.g -= v.g
    self.b -= v.b

  proc calcPix*[ArgT](self: var name, v: var ArgT, dv: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    v.r = ValueT(self.r / dv)
    v.g = ValueT(self.g / dv)
    v.b = ValueT(self.b / dv)

  proc calcPix*[ArgT](self: var name, v: var ArgT, mul: uint, sh: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    v.r = ValueT((self.r * mul) shr sh)
    v.g = ValueT((self.g * mul) shr sh)
    v.b = ValueT((self.b * mul) shr sh)

stackBlurCalcRgb(StackBlurCalcRgb)

template stackBlurCalcGray(name: untyped, T: typed = uint) =
  type
    name* = object
      v: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc clear*(self: var name) {.inline.} =
    self.v = 0

  proc add*[ArgT](self: var name, a: ArgT) {.inline.} =
    self.v += a.v

  proc add*[ArgT](self: var name, a: ArgT, k: uint) {.inline.} =
    self.v += a.v * k

  proc sub*[ArgT](self: var name, a: ArgT) {.inline.} =
    self.v -= a.v

  proc calcPix*[ArgT](self: var name, a: var ArgT, dv: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    a.v = ValueT(self.v / dv)

  proc calcPix*[ArgT](self: var name, a: var ArgT, mul: uint, sh: uint) {.inline.} =
    type ValueT  = getValueT(ArgT)
    a.v = ValueT((self.v * mul) shr sh)

stackBlurCalcGray(StackBlurCalcGray)

type
  StackBlur*[ColorT, CalculatorT] = object
    mBuf: seq[ColorT]
    mStack: seq[ColorT]

proc blurX*[ColorT,CalculatorT,Img](self: var StackBlur[ColorT,CalculatorT], img: var Img, radius: float64) =
  type CalcT = getValueT(CalculatorT)
  const baseMask = getBaseMask(ColorT)

  if radius < 1: return

  var
    xp: uint
    stackPtr, stackStart: uint
    pix: ColorT
    stackPix: ptr ColorT
    sum, sumIn, sumOut: CalculatorT
    w = img.width()
    h = img.height()
    wm  = w - 1
    dv = radius * 2 + 1
    divSum = (radius + 1) * (radius + 1)
    mulSum = 0
    shrSum = 0
    maxVal = baseMask

  if maxVal <= 255 and radius < 255:
    mulSum = stack_blur8_mul[radius]
    shrSum = stack_blur8_shr[radius]

  self.mBuf = newSeq[ColorT](w)
  self.mStack = newSeq[ColorT](dv)

  for y in 0.. <h:
    sum.clear()
    sumIn.clear()
    sumOut.clear()

    pix = img.pixel(0, y)
    for i in 0..radius:
      self.mStack[i] = pix
      sum.add(pix, i + 1)
      sumOut.add(pix)

    for i in 1..radius:
      pix = img.pixel(if i > wm: wm else: i, y)
      self.mStack[i + radius] = pix
      sum.add(pix, radius + 1 - i)
      sumIn.add(pix)

    stackPtr = radius
    for x in 0.. <w:
      if mulSum != 0: sum.calcPix(self.mBuf[x], mulSum, shrSum)
      else:           sum.calcPix(self.mBuf[x], divSum)

      sum.sub(sumOut)

      stackStart = stackPtr + dv - radius
      if stackStart >= dv: stackStart -= dv
      stackPix = self.mStack[stackStart].addr

      sumOut.sub(stackPix[])

      xp = x + radius + 1
      if xp > wm: xp = wm
      pix = img.pixel(xp, y)

      stackPix[] = pix

      sumIn.add(pix)
      sum.add(sumIn)

      inc stackPtr
      if stackPtr >= dv: stackPtr = 0
      stackPix = self.mStack[stackPtr].addr

      sumOut.add(stackPix[])
      sumIn.sub(stackPix[])

    img.copyColorHspan(0, y, w, self.mBuf[0].addr)

proc blurY*[C,CT,Img](self: var StackBlur[C,CT], img: var Img, radius: float64) =
  var img2 = initPixfmtTransposer(img)
  self.blurX(img2, radius)

proc blur*[C,CT,Img](self: var StackBlur[C,CT], img: var Img, radius: float64) =
  self.blurX(img, radius)
  var img2 = initPixfmtTransposer(img)
  self.blurX(img2, radius)

proc stackBlurGray8*[Img](img: var Img, rx, ry: int) =
  var
    xp, yp: int
    stackPtr, stackStart: int
    srcPixPtr, dstPixPtr: ptr uint8
    pix, stackPix, sum, sumIn, sumOut: int
    w   = img.width()
    h   = img.height()
    wm  = w - 1
    hm  = h - 1
    dv, mulSum, shrSum: int
    stack: seq[uint8]
    rx = rx
    ry = ry

  if rx > 0:
    if rx > 254: rx = 254
    dv = rx * 2 + 1
    mulSum = stack_blur8_mul[rx].int
    shrSum = stack_blur8_shr[rx].int
    stack = newSeq[uint8](dv)

    for y in 0.. <h:
      sum = 0
      sumIn = 0
      sumOut = 0

      srcPixPtr = img.pixPtr(0, y)
      pix = srcPixPtr[].int
      for i in 0..rx:
        stack[i] = pix.uint8
        sum     += pix * (i + 1)
        sumOut += pix

      for i in 1..rx:
        if i <= wm: srcPixPtr += getPixStep(Img)
        pix = srcPixPtr[].int
        stack[i + rx] = pix.uint8
        sum   += pix * (rx + 1 - i)
        sumIn += pix

      stackPtr = rx
      xp = rx
      if xp > wm: xp = wm
      srcPixPtr = img.pixPtr(xp, y)
      dstPixPtr = img.pixPtr(0, y)
      for x in 0.. <w:
        dstPixPtr[] = ((sum * mulSum) shr shrSum).uint8
        dstPixPtr  += getPixStep(Img)

        sum -= sumOut

        stackStart = stackPtr + dv - rx
        if stackStart >= dv: stackStart -= dv
        sumOut -= stack[stackStart].int

        if xp < wm:
          srcPixPtr += getPixStep(Img)
          pix = srcPixPtr[].int
          inc xp

        stack[stackStart] = pix.uint8

        sumIn += pix
        sum   += sumIn

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPix = stack[stackPtr].int

        sumOut += stackPix
        sumIn  -= stackPix

  if ry > 0:
    if ry > 254: ry = 254
    dv = ry * 2 + 1
    mulSum = stack_blur8_mul[ry].int
    shrSum = stack_blur8_shr[ry].int
    stack = newSeq[uint8](dv)

    let stride = img.stride()
    for x in 0.. <w:
      sum = 0
      sumIn = 0
      sumOut = 0

      srcPixPtr = img.pixPtr(x, 0)
      pix = srcPixPtr[].int
      for i in 0..ry:
        stack[i] = pix.uint8
        sum     += pix * (i + 1)
        sumOut  += pix

      for i in 1..ry:
        if i <= hm: srcPixPtr += stride
        pix = srcPixPtr[].int
        stack[i + ry] = pix.uint8
        sum    += pix * (ry + 1 - i)
        sumIn  += pix

      stackPtr = ry
      yp = ry
      if yp > hm: yp = hm
      srcPixPtr = img.pixPtr(x, yp)
      dstPixPtr = img.pixPtr(x, 0)
      for y in 0.. <h:
        dstPixPtr[] = ((sum * mulSum) shr shrSum).uint8
        dstPixPtr += stride
        sum -= sumOut

        stackStart = stackPtr + dv - ry
        if stackStart >= dv: stackStart -= dv
        sumOut -= stack[stackStart].int

        if yp < hm:
          srcPixPtr += stride
          pix = srcPixPtr[].int
          inc yp

        stack[stackStart] = pix.uint8
        sumIn += pix
        sum   += sumIn

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPix = stack[stackPtr].int

        sumOut += stackPix
        sumIn  -= stackPix

proc stackBlurRgb24*[Img](img: var Img, rx, ry: int) =
  type
    OrderT = getOrderT(Img)
    ColorT = getColorT(Img)
    rgb = object
      r, g, b: uint

  const
    R = OrderT.R.ord
    G = OrderT.G.ord
    B = OrderT.B.ord

  var
    xp, yp: int
    stackPtr, stackStart: int
    srcPixPtr, dstPixPtr: ptr uint8
    stackPixPtr: ptr ColorT
    sum, sumIn, sumOut: rgb
    w   = img.width()
    h   = img.height()
    wm  = w - 1
    hm  = h - 1
    dv: int
    mulSum, shrSum: uint
    stack: seq[ColorT]
    rx = rx
    ry = ry

  if rx > 0:
    if rx > 254: rx = 254
    dv = rx * 2 + 1
    mulSum = stack_blur8_mul[rx].uint
    shrSum = stack_blur8_shr[rx].uint
    stack = newSeq[ColorT](dv)

    for y in 0.. <h:
      sum.r = 0
      sum.g = 0
      sum.b = 0
      sumIn.r = 0
      sumIn.g = 0
      sumIn.b = 0
      sumOut.r = 0
      sumOut.g = 0
      sumOut.b = 0

      srcPixPtr = img.pixPtr(0, y)
      for i in 0..rx:
        stackPixPtr   = stack[i].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        sum.r        += srcPixPtr[R].uint * (i + 1).uint
        sum.g        += srcPixPtr[G].uint * (i + 1).uint
        sum.b        += srcPixPtr[B].uint * (i + 1).uint
        sumOut.r     += srcPixPtr[R]
        sumOut.g     += srcPixPtr[G]
        sumOut.b     += srcPixPtr[B]

      for i in 1..rx:

        if i <= wm: srcPixPtr += getPixWidth(Img)
        stackPixPtr   = stack[i + rx].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        sum.r        += srcPixPtr[R].uint * (rx + 1 - i).uint
        sum.g        += srcPixPtr[G].uint * (rx + 1 - i).uint
        sum.b        += srcPixPtr[B].uint * (rx + 1 - i).uint
        sumIn.r      += srcPixPtr[R]
        sumIn.g      += srcPixPtr[G]
        sumIn.b      += srcPixPtr[B]

      stackPtr = rx
      xp = rx
      if xp > wm: xp = wm
      srcPixPtr = img.pixPtr(xp, y)
      dstPixPtr = img.pixPtr(0, y)
      for x in 0.. <w:
        dstPixPtr[R] = ((sum.r * mulSum) shr shrSum).uint8
        dstPixPtr[G] = ((sum.g * mulSum) shr shrSum).uint8
        dstPixPtr[B] = ((sum.b * mulSum) shr shrSum).uint8
        dstPixPtr   += getPixWidth(Img)

        sum.r -= sumOut.r
        sum.g -= sumOut.g
        sum.b -= sumOut.b

        stackStart = stackPtr + dv - rx
        if stackStart >= dv: stackStart -= dv
        stackPixPtr = stack[stackStart].addr

        sumOut.r -= stackPixPtr.r
        sumOut.g -= stackPixPtr.g
        sumOut.b -= stackPixPtr.b

        if xp < wm:
          srcPixPtr += getPixWidth(Img)
          inc xp

        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]

        sumIn.r += srcPixPtr[R]
        sumIn.g += srcPixPtr[G]
        sumIn.b += srcPixPtr[B]
        sum.r   += sumIn.r
        sum.g   += sumIn.g
        sum.b   += sumIn.b

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPixPtr = stack[stackPtr].addr

        sumOut.r += stackPixPtr.r
        sumOut.g += stackPixPtr.g
        sumOut.b += stackPixPtr.b
        sumIn.r  -= stackPixPtr.r
        sumIn.g  -= stackPixPtr.g
        sumIn.b  -= stackPixPtr.b

  if ry > 0:
    if ry > 254: ry = 254
    dv = ry * 2 + 1
    mulSum = stack_blur8_mul[ry].uint
    shrSum = stack_blur8_shr[ry].uint
    stack = newSeq[ColorT](dv)

    let stride = img.stride()
    for x in 0.. <w:
      sum.r = 0
      sum.g = 0
      sum.b = 0
      sumIn.r = 0
      sumIn.g = 0
      sumIn.b = 0
      sumOut.r = 0
      sumOut.g = 0
      sumOut.b = 0

      srcPixPtr = img.pixPtr(x, 0)
      for i in 0..ry:
        stackPixPtr   = stack[i].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        sum.r        += srcPixPtr[R].uint * (i + 1).uint
        sum.g        += srcPixPtr[G].uint * (i + 1).uint
        sum.b        += srcPixPtr[B].uint * (i + 1).uint
        sumOut.r     += srcPixPtr[R]
        sumOut.g     += srcPixPtr[G]
        sumOut.b     += srcPixPtr[B]

      for i in 1..ry:

        if i <= hm: srcPixPtr += stride
        stackPixPtr = stack[i + ry].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        sum.r        += srcPixPtr[R].uint * (ry + 1 - i).uint
        sum.g        += srcPixPtr[G].uint * (ry + 1 - i).uint
        sum.b        += srcPixPtr[B].uint * (ry + 1 - i).uint
        sumIn.r      += srcPixPtr[R]
        sumIn.g      += srcPixPtr[G]
        sumIn.b      += srcPixPtr[B]

      stackPtr = ry
      yp = ry
      if yp > hm: yp = hm
      srcPixPtr = img.pixPtr(x, yp)
      dstPixPtr = img.pixPtr(x, 0)
      for y in 0.. <h:
        dstPixPtr[R] = uint8((sum.r * mulSum) shr shrSum)
        dstPixPtr[G] = uint8((sum.g * mulSum) shr shrSum)
        dstPixPtr[B] = uint8((sum.b * mulSum) shr shrSum)
        dstPixPtr += stride

        sum.r -= sumOut.r
        sum.g -= sumOut.g
        sum.b -= sumOut.b

        stackStart = stackPtr + dv - ry
        if stackStart >= dv: stackStart -= dv

        stackPixPtr = stack[stackStart].addr
        sumOut.r -= stackPixPtr.r
        sumOut.g -= stackPixPtr.g
        sumOut.b -= stackPixPtr.b

        if yp < hm:
          srcPixPtr += stride
          inc yp

        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]

        sumIn.r += srcPixPtr[R]
        sumIn.g += srcPixPtr[G]
        sumIn.b += srcPixPtr[B]
        sum.r   += sumIn.r
        sum.g   += sumIn.g
        sum.b   += sumIn.b

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPixPtr = stack[stackPtr].addr

        sumOut.r += stackPixPtr.r
        sumOut.g += stackPixPtr.g
        sumOut.b += stackPixPtr.b
        sumIn.r  -= stackPixPtr.r
        sumIn.g  -= stackPixPtr.g
        sumIn.b  -= stackPixPtr.b

proc stackBlurRgba32*[Img](img: var Img, rx, ry: int) =
  type
    OrderT = getOrderT(Img)
    ColorT = getColorT(Img)
    rgba = object
      r, g, b, a: uint

  const
    R = OrderT.R.ord
    G = OrderT.G.ord
    B = OrderT.B.ord
    A = OrderT.A.ord

  var
    xp, yp: int
    stackPtr, stackStart: int
    srcPixPtr, dstPixPtr: ptr uint8
    stackPixPtr: ptr ColorT
    sum, sumIn, sumOut: rgba
    w   = img.width()
    h   = img.height()
    wm  = w - 1
    hm  = h - 1
    dv: int
    mulSum, shrSum: uint
    stack: seq[ColorT]
    rx = rx
    ry = ry

  if rx > 0:

    if rx > 254: rx = 254
    dv = rx * 2 + 1
    mulSum = stack_blur8_mul[rx].uint
    shrSum = stack_blur8_shr[rx].uint
    stack = newSeq[ColorT](dv)

    for y in 0.. <h:
      sum.r = 0
      sum.g = 0
      sum.b = 0
      sum.a = 0
      sumIn.r = 0
      sumIn.g = 0
      sumIn.b = 0
      sumIn.a = 0
      sumOut.r = 0
      sumOut.g = 0
      sumOut.b = 0
      sumOut.a = 0

      srcPixPtr = img.pixPtr(0, y)
      for i in 0..rx:
        stackPixPtr   = stack[i].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]
        sum.r        += srcPixPtr[R].uint * (i + 1).uint
        sum.g        += srcPixPtr[G].uint * (i + 1).uint
        sum.b        += srcPixPtr[B].uint * (i + 1).uint
        sum.a        += srcPixPtr[A].uint * (i + 1).uint
        sumOut.r     += srcPixPtr[R]
        sumOut.g     += srcPixPtr[G]
        sumOut.b     += srcPixPtr[B]
        sumOut.a     += srcPixPtr[A]

      for i in 1..rx:
        if i <= wm: srcPixPtr += getPixWidth(Img)
        stackPixPtr   = stack[i + rx].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]
        sum.r        += srcPixPtr[R].uint * (rx + 1 - i).uint
        sum.g        += srcPixPtr[G].uint * (rx + 1 - i).uint
        sum.b        += srcPixPtr[B].uint * (rx + 1 - i).uint
        sum.a        += srcPixPtr[A].uint * (rx + 1 - i).uint
        sumIn.r      += srcPixPtr[R]
        sumIn.g      += srcPixPtr[G]
        sumIn.b      += srcPixPtr[B]
        sumIn.a      += srcPixPtr[A]


      stackPtr = rx
      xp = rx
      if xp > wm: xp = wm
      srcPixPtr = img.pixPtr(xp, y)
      dstPixPtr = img.pixPtr(0, y)
      for x in 0.. <w:
        dstPixPtr[R] = uint8((sum.r * mulSum) shr shrSum)
        dstPixPtr[G] = uint8((sum.g * mulSum) shr shrSum)
        dstPixPtr[B] = uint8((sum.b * mulSum) shr shrSum)
        dstPixPtr[A] = uint8((sum.a * mulSum) shr shrSum)
        dstPixPtr += getPixWidth(Img)

        sum.r -= sumOut.r
        sum.g -= sumOut.g
        sum.b -= sumOut.b
        sum.a -= sumOut.a

        stackStart = stackPtr + dv - rx
        if stackStart >= dv: stackStart -= dv
        stackPixPtr = stack[stackStart].addr

        sumOut.r -= stackPixPtr.r
        sumOut.g -= stackPixPtr.g
        sumOut.b -= stackPixPtr.b
        sumOut.a -= stackPixPtr.a

        if xp < wm:
          srcPixPtr += getPixWidth(Img)
          inc xp

        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]

        sumIn.r += srcPixPtr[R]
        sumIn.g += srcPixPtr[G]
        sumIn.b += srcPixPtr[B]
        sumIn.a += srcPixPtr[A]
        sum.r   += sumIn.r
        sum.g   += sumIn.g
        sum.b   += sumIn.b
        sum.a   += sumIn.a

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPixPtr = stack[stackPtr].addr

        sumOut.r += stackPixPtr.r
        sumOut.g += stackPixPtr.g
        sumOut.b += stackPixPtr.b
        sumOut.a += stackPixPtr.a
        sumIn.r  -= stackPixPtr.r
        sumIn.g  -= stackPixPtr.g
        sumIn.b  -= stackPixPtr.b
        sumIn.a  -= stackPixPtr.a

  if ry > 0:

    if ry > 254: ry = 254
    dv = ry * 2 + 1
    mulSum = stack_blur8_mul[ry].uint
    shrSum = stack_blur8_shr[ry].uint
    stack = newSeq[ColorT](dv)

    let stride = img.stride()
    for x in 0.. <w:
      sum.r = 0
      sum.g = 0
      sum.b = 0
      sum.a = 0
      sumIn.r = 0
      sumIn.g = 0
      sumIn.b = 0
      sumIn.a = 0
      sumOut.r = 0
      sumOut.g = 0
      sumOut.b = 0
      sumOut.a = 0

      srcPixPtr = img.pixPtr(x, 0)
      for i in 0..ry:
        stackPixPtr   = stack[i].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]
        sum.r        += srcPixPtr[R].uint * (i + 1).uint
        sum.g        += srcPixPtr[G].uint * (i + 1).uint
        sum.b        += srcPixPtr[B].uint * (i + 1).uint
        sum.a        += srcPixPtr[A].uint * (i + 1).uint
        sumOut.r     += srcPixPtr[R]
        sumOut.g     += srcPixPtr[G]
        sumOut.b     += srcPixPtr[B]
        sumOut.a     += srcPixPtr[A]

      for i in 1..ry:
        if i <= hm: srcPixPtr += stride
        stackPixPtr   = stack[i + ry].addr
        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]
        sum.r        += srcPixPtr[R].uint * (ry + 1 - i).uint
        sum.g        += srcPixPtr[G].uint * (ry + 1 - i).uint
        sum.b        += srcPixPtr[B].uint * (ry + 1 - i).uint
        sum.a        += srcPixPtr[A].uint * (ry + 1 - i).uint
        sumIn.r      += srcPixPtr[R]
        sumIn.g      += srcPixPtr[G]
        sumIn.b      += srcPixPtr[B]
        sumIn.a      += srcPixPtr[A]

      stackPtr = ry
      yp = ry
      if yp > hm: yp = hm
      srcPixPtr = img.pixPtr(x, yp)
      dstPixPtr = img.pixPtr(x, 0)
      for y in 0.. <h:
        dstPixPtr[R] = uint8((sum.r * mulSum) shr shrSum)
        dstPixPtr[G] = uint8((sum.g * mulSum) shr shrSum)
        dstPixPtr[B] = uint8((sum.b * mulSum) shr shrSum)
        dstPixPtr[A] = uint8((sum.a * mulSum) shr shrSum)
        dstPixPtr += stride

        sum.r -= sumOut.r
        sum.g -= sumOut.g
        sum.b -= sumOut.b
        sum.a -= sumOut.a

        stackStart = stackPtr + dv - ry
        if stackStart >= dv: stackStart -= dv

        stackPixPtr = stack[stackStart].addr
        sumOut.r -= stackPixPtr.r
        sumOut.g -= stackPixPtr.g
        sumOut.b -= stackPixPtr.b
        sumOut.a -= stackPixPtr.a

        if yp < hm:
          srcPixPtr += stride
          inc yp

        stackPixPtr.r = srcPixPtr[R]
        stackPixPtr.g = srcPixPtr[G]
        stackPixPtr.b = srcPixPtr[B]
        stackPixPtr.a = srcPixPtr[A]

        sumIn.r += srcPixPtr[R]
        sumIn.g += srcPixPtr[G]
        sumIn.b += srcPixPtr[B]
        sumIn.a += srcPixPtr[A]
        sum.r   += sumIn.r
        sum.g   += sumIn.g
        sum.b   += sumIn.b
        sum.a   += sumIn.a

        inc stackPtr
        if stackPtr >= dv: stackPtr = 0
        stackPixPtr = stack[stackPtr].addr

        sumOut.r += stackPixPtr.r
        sumOut.g += stackPixPtr.g
        sumOut.b += stackPixPtr.b
        sumOut.a += stackPixPtr.a
        sumIn.r  -= stackPixPtr.r
        sumIn.g  -= stackPixPtr.g
        sumIn.b  -= stackPixPtr.b
        sumIn.a  -= stackPixPtr.a

template recursiveBlurCalcRgba(name: untyped, T: typed = float64) =
  type
    name* = object
      r, g, b, a: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc fromPix*[ColorT](self: var name, c: ColorT) {.inline.} =
    self.r = T(c.r)
    self.g = T(c.g)
    self.b = T(c.b)
    self.a = T(c.a)

  proc calc*(self: var name, b1, b2, b3, b4: T; c1, c2, c3, c4: name) {.inline.} =
    self.r = b1*c1.r + b2*c2.r + b3*c3.r + b4*c4.r
    self.g = b1*c1.g + b2*c2.g + b3*c3.g + b4*c4.g
    self.b = b1*c1.b + b2*c2.b + b3*c3.b + b4*c4.b
    self.a = b1*c1.a + b2*c2.a + b3*c3.a + b4*c4.a

  proc toPix*[ColorT](self: name, c: var ColorT) {.inline.} =
    type ValueT = getValueT(ColorT)
    c.r = ValueT(uround(self.r))
    c.g = ValueT(uround(self.g))
    c.b = ValueT(uround(self.b))
    c.a = ValueT(uround(self.a))

recursiveBlurCalcRgba(RecursiveBlurCalcRgba)

template recursiveBlurCalcRgb(name: untyped, T: typed = float64) =
  type
    name* = object
      r, g, b: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc fromPix*[ColorT](self: var name, c: ColorT) {.inline.} =
    self.r = T(c.r)
    self.g = T(c.g)
    self.b = T(c.b)

  proc calc*(self: var name, b1, b2, b3, b4: T; c1, c2, c3, c4: name) {.inline.} =
    self.r = b1*c1.r + b2*c2.r + b3*c3.r + b4*c4.r
    self.g = b1*c1.g + b2*c2.g + b3*c3.g + b4*c4.g
    self.b = b1*c1.b + b2*c2.b + b3*c3.b + b4*c4.b

  proc toPix*[ColorT](self: name, c: var ColorT) {.inline.} =
    type ValueT = getValueT(ColorT)
    c.r = ValueT(uround(self.r))
    c.g = ValueT(uround(self.g))
    c.b = ValueT(uround(self.b))

recursiveBlurCalcRgb(RecursiveBlurCalcRgb)

template recursiveBlurCalcGray(name: untyped, T: typed = float64) =
  type
    name* = object
      v: T

  template getValueT*(x: typedesc[name]): typedesc = T

  proc fromPix*[ColorT](self: var name, c: ColorT) {.inline.} =
    self.v = T(c.v)

  proc calc*(self: var name, b1, b2, b3, b4: T; c1, c2, c3, c4: name) {.inline.} =
    self.v = b1*c1.v + b2*c2.v + b3*c3.v + b4*c4.v

  proc toPix*[ColorT](self: name, c: var ColorT) {.inline.} =
    type ValueT = getValueT(ColorT)
    c.v = ValueT(uround(self.v))

recursiveBlurCalcGray(RecursiveBlurCalcGray)

type
  RecursiveBlur*[ColorT, CalculatorT] = object
    mSum1, mSum2: seq[CalculatorT]
    mBuf: seq[ColorT]

proc blurX*[ColorT,CalculatorT,Img](self: var RecursiveBlur[ColorT,CalculatorT], img: var Img, radius: float64) =
  type CalcT = getValueT(CalculatorT)

  if radius < 0.62: return
  if img.width() < 3: return

  var
    s = CalcT(radius * 0.5)
    q = CalcT(if s < 2.5: 3.97156 - 4.14554 * sqrt(1 - 0.26891 * s) else: 0.98711 * s - 0.96330)
    q2 = CalcT(q * q)
    q3 = CalcT(q2 * q)
    b0 = CalcT(1.0 / (1.578250 +  2.444130 * q + 1.428100 * q2 + 0.422205 * q3))
    b1 = CalcT( 2.44413 * q + 2.85619 * q2 + 1.26661 * q3)
    b2 = CalcT(-1.42810 * q2 + -1.26661 * q3)
    b3 = CalcT(0.422205 * q3)
    b  = CalcT(1 - (b1 + b2 + b3) * b0)

  b1 *= b0
  b2 *= b0
  b3 *= b0

  var
    w = img.width()
    h = img.height()
    wm = w-1

  self.mSum1 = newSeq[CalculatorT](w)
  self.mSum2 = newSeq[CalculatorT](w)
  self.mBuf  = newSeq[ColorT](w)

  for y in 0.. <h:
    var c: CalculatorT
    c.fromPix(img.pixel(0, y))
    self.mSum1[0].calc(b, b1, b2, b3, c, c, c, c)
    c.fromPix(img.pixel(1, y))
    self.mSum1[1].calc(b, b1, b2, b3, c, self.mSum1[0], self.mSum1[0], self.mSum1[0])
    c.fromPix(img.pixel(2, y))
    self.mSum1[2].calc(b, b1, b2, b3, c, self.mSum1[1], self.mSum1[0], self.mSum1[0])

    for x in 3.. <w:
      c.fromPix(img.pixel(x, y))
      self.mSum1[x].calc(b, b1, b2, b3, c, self.mSum1[x-1], self.mSum1[x-2], self.mSum1[x-3])

    self.mSum2[wm  ].calc(b, b1, b2, b3, self.mSum1[wm  ], self.mSum1[wm  ], self.mSum1[wm], self.mSum1[wm])
    self.mSum2[wm-1].calc(b, b1, b2, b3, self.mSum1[wm-1], self.mSum2[wm  ], self.mSum2[wm], self.mSum2[wm])
    self.mSum2[wm-2].calc(b, b1, b2, b3, self.mSum1[wm-2], self.mSum2[wm-1], self.mSum2[wm], self.mSum2[wm])
    self.mSum2[wm  ].toPix(self.mBuf[wm  ])
    self.mSum2[wm-1].toPix(self.mBuf[wm-1])
    self.mSum2[wm-2].toPix(self.mBuf[wm-2])

    for x in countdown(wm-3, 0):
      self.mSum2[x].calc(b, b1, b2, b3, self.mSum1[x], self.mSum2[x+1], self.mSum2[x+2], self.mSum2[x+3])
      self.mSum2[x].toPix(self.mBuf[x])

    img.copyColorHspan(0, y, w, self.mBuf[0].addr)

proc blurY*[C,CT,Img](self: var RecursiveBlur[C,CT], img: var Img, radius: float64) =
  var img2 = initPixfmtTransposer(img)
  self.blurX(img2, radius)

proc blur*[C,CT,Img](self: var RecursiveBlur[C,CT], img: var Img, radius: float64) =
  self.blurX(img, radius)
  var img2 = initPixfmtTransposer(img)
  self.blurX(img2, radius)

