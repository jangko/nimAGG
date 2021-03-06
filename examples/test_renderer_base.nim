import agg/[renderer_base, pixfmt_rgb, rendering_buffer, color_rgba]

const
  frameWidth = 255
  frameHeight = frameWidth

proc testRendererBase[ColorT]() =
  type
    ValueT = getValueT(ColorT)
  const
    pixWidth = sizeof(ValueT) * 3
  var
    buffer = newString(frameWidth * frameHeight * pixWidth)
    rbuf = initRenderingBuffer(cast[ptr ValueT](buffer[0].addr), frameWidth, frameHeight, frameWidth * pixWidth)
    pixf = initPixFmtRgb24(rbuf)
    ren = initRendererBase(pixf)

  var px = ren.pixel(10, 10)


testRendererBase[Rgba8]()