import basics, path_storage, bounding_rect, math, pixfmt_gray
import conv_curve, rendering_buffer, rasterizer_outline
import renderer_primitives, renderer_base, trans_affine
import conv_transform, color_gray, span_gradient, color_rgba
import pixfmt_rgb

let Infinity = 1E20

type
  GradientContour* = object
    mBuffer: seq[uint8]
    mWidth, mHeight, mFrame: int
    mD1, mD2: float64

proc initGradientContour*(d1 = 0.0; d2 = 100.0): GradientContour =
  result.mWidth = 0
  result.mHeight = 0
  result.mFrame = 10
  result.mD1 = d1
  result.mD2 = d2

template construct*(x: typedesc[GradientContour]): untyped = initGradientContour()
template construct*(x: typedesc[GradientContour], d1, d2): untyped = initGradientContour(d1, d2)

proc frame*(self: var GradientContour, f: int) = self.mFrame = f
proc frame*(self: GradientContour): int = self.mFrame
proc d1*(self: var GradientContour, d: float64) = self.mD1 = d
proc d2*(self: var GradientContour, d: float64) = self.mD2 = d
proc d1*(self: GradientContour): float64 = self.mD1
proc d2*(self: GradientContour): float64 = self.mD2
proc width*(self: GradientContour): int = self.mWidth
proc height*(self: GradientContour): int = self.mHeight

proc square(x: int): float32 = float32(x * x)

# DT algorithm by: Pedro Felzenszwalb
proc dt(spanf, spang, spanr: var openArray[float32]; spann: var openArray[int]; len: int) =
  var
    k = 0
    s: float32

  spann[0] = 0
  spang[0] = -Infinity
  spang[1] = Infinity

  for q in 1..len-1:
    s = ((spanf[q] + square(q)) - (spanf[spann[k]] + square(spann[k]))) / float32(2 * q - 2 * spann[k])

    while s <= spang[k]:
      dec k
      s = ((spanf[q] + square(q)) - (spanf[spann[k]] + square(spann[k]))) / float32(2 * q - 2 * spann[k])

    inc k
    spann[k] = q
    spang[k] = s
    spang[k + 1] = Infinity

  k = 0
  for q in 0..len-1:
    while spang[k + 1] < q.float32:
      inc k
    spanr[q] = square(q - spann[k]) + spanf[spann[k]]

proc contourCreate*(self: var GradientContour, ps: var PathStorage) =
  # I. Render Black And White NonAA Stroke of the Path
  # Path Bounding Box + Some GetFrame Space Around [configurable]
  var
    conv = initConvCurve(ps)
    bb = boundingRectD(conv)
    width  = ceil(bb.x2 - bb.x1).int + self.mFrame * 2 + 1
    height = ceil(bb.y2 - bb.y1).int + self.mFrame * 2 + 1

  self.mBuffer = newSeq[uint8](width*height)
  var
    rb = initRenderingBuffer(self.mBuffer[0].addr, width, height, width)
    pf = initPixFmtGray8(rb)
    renb = initRendererBase(pf)
    prim = initRendererPrimitives(renb)
    ras  = initRasterizerOutline(prim)
    mtx  = initTransAffine()
    trans = initConvTransform(conv, mtx)

  renb.clear(initRgba(1,1,1))
  mtx *= transAffineTranslation(-bb.x1 + self.mFrame.float64, -bb.y1 + self.mFrame.float64)
  prim.lineColor(initRgba8(0, 0, 0, 255))
  ras.addPath(trans)

  # II. Distance Transform
  # Create Float Buffer + 0 vs CInfinity (1e20) assignment
  var image = newSeq[float32](width*height)

  var k = 0
  for y in 0..<height:
    for x in 0..<width:
      if self.mBuffer[k] == 0: image[k] = 0.0
      else: image[k] = Infinity
      inc k

  # DT of 2d

  let len = max(width, height)

  var
    spanf = newSeq[float32](len)
    spang = newSeq[float32](len+1)
    spanr = newSeq[float32](len)
    spann = newSeq[int](len)

  # Transform along columns
  for x in 0..<width:
    for y in 0..<height:
      spanf[y] = image[y * width + x]

    # DT of 1d
    dt(spanf, spang, spanr, spann, height)

    for y in 0..<height:
      image[y * width + x] = spanr[y]

  # Transform along rows
  for y in 0..<height:
    for x in 0..<width:
      spanf[x] = image[y * width + x]

    # DT of 1d
    dt(spanf, spang, spanr, spann, width)

    for x in 0..<width:
      image[y * width + x] = spanr[x]

  # Take Square Roots, Min & Max
  var
    min = sqrt(image[0])
    max = min

  k = 0
  for y in 0..<height:
    for x in 0..<width:
      image[k] = sqrt(image[k])
      if min > image[k]: min = image[k]
      if max < image[k]: max = image[k]
      inc k

  # III. Convert To Grayscale
  if min == max:
    zeroMem(self.mBuffer[0].addr, width * height)
  else:
    var scale = 255.0 / (max - min)

    k = 0
    for y in 0..<height:
      for x in 0..<width:
        self.mBuffer[k] = uint8(iround((image[k] - min) * scale))
        inc k

  # OK
  self.mWidth = width
  self.mHeight = height

proc calculate*(self: var GradientContour, x, y, d: int): int =
  if self.mBuffer.len > 0:
    var
      px = sar(x, gradientSubpixelShift)
      py = sar(y, gradientSubpixelShift)

    px = px mod self.mWidth
    if px < 0: px = self.mWidth + px

    py = py mod self.mHeight
    if py < 0: py = self.mHeight + py

    let pixel = self.mBuffer[py * self.mWidth + px]
    result = round(pixel.float * (self.mD2 / 256) + self.mD1).int shl gradientSubpixelShift
  else:
    result = 0