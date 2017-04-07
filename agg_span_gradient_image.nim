import agg_basics, agg_color_rgba, agg_span_gradient, agg_pixfmt_rgb
import agg_rendering_buffer

type
  GradientImage*[PixFmt, ColorT] = object
    mBuffer: seq[uint8]
    mAlocDeltaX, mAlocDeltaY: int
    mWidth, mHeight: int

    mRbuf: RenderingBuffer
    mPixf: PixFmt
    mColor: ptr ColorT
    mColorF: array[1, ColorT]

proc initGradientImageAux*[PixFmt,ColorT](): GradientImage[PixFmt,ColorT] =
  result.mBuffer = nil
  result.mAlocDeltaX = 0
  result.mAlocDeltaY = 0
  result.mWidth = 0
  result.mHeight = 0
  result.mRbuf = initRenderingBuffer()
  result.mColorF[0] = noColor(ColorT)
  result.mColor = result.mColorF[0].addr

proc initGradientImage*(PixFmt: typedesc): auto =
  result = initGradientImageAux[PixFmt, getColorT(PixFmt)]()

proc imageCreate*[PixFmt,ColorT](self: var GradientImage[PixFmt,ColorT], w, h: int): pointer =
  mixin getPixElem, getPixWidth
  
  const
    pixWidth = getPixWidth(PixFmt)
    pixElem = getPixElem(PixFmt)

  type
    ValueT = getValueT(PixFmt)

  if (w > self.mAlocDeltaX) or (h > self.mAlocDeltaY):
    self.mBuffer = newSeq[uint8](w * h * pixWidth)
    self.mAlocDeltaX = w
    self.mAlocDeltaY = h

  self.mWidth  = w
  self.mHeight = h

  self.mRbuf.attach(cast[ptr ValueT](self.mBuffer[0].addr), w, h, self.mAlocDeltaX * pixelem)
  self.mPixf = construct(PixFmt, self.mRbuf)
  result = self.mBuffer[0].addr

proc imageBuffer*[PixFmt,ColorT](self: var GradientImage[PixFmt,ColorT]): pointer =
  self.mBuffer[0].addr

proc stride*[PixFmt,ColorT](self: GradientImage[PixFmt,ColorT]): int =
  mixin getPixWidth
  const pixWidth = getPixWidth(PixFmt)
  self.mAlocDeltaX * pixWidth

proc calculate*[PixFmt,ColorT](self: var GradientImage[PixFmt,ColorT], x, y, d: int): int =
  mixin getPixWidth
  const pixWidth = getPixWidth(PixFmt)

  if self.mBuffer != nil:
    var
      px = sar(x, gradientSubpixelShift)
      py = sar(y, gradientSubpixelShift)

    px = px mod self.mWidth
    if px < 0: px = self.mWidth + px

    py = py mod self.mHeight
    if py < 0: py = self.mHeight + py

    let pixel = cast[ptr ColorT](self.mBuffer[py * (self.mAlocDeltaX * pixWidth) + px * pixWidth].addr)
    self.mColor[] = pixel[]
  else:
    self.mColor[] = noColor(ColorT)

proc colorFunction*[PixFmt,ColorT](self: var GradientImage[PixFmt,ColorT]): var array[1, ColorT] =
  result = self.mColorF
