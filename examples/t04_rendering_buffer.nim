import agg/[rendering_buffer, basics, pixfmt_rgb, color_rgba]
import platform.nimBMP

const
  frame_width = 320
  frame_height = 200

proc main() =
  var buffer = newString(frame_width * frame_height * 3)
  for i in 0.. <buffer.len: buffer[i] = 255.chr
  var rbuf = initRenderingBuffer(cast[ptr uint8](buffer[0].addr), frame_width, frame_height, frame_width * 3)
  var pixf = initPixFmtRgb24(rbuf)
  var span: array[frame_width, Rgba8]

  let f = frame_width.float
  for i in 0.. <frame_width:
    let c = initRgba(380.0 + 400.0 * i.float / f, 0.8)
    span[i] = initRgba8(c)

  for i in 0.. <frame_height:
    pixf.blendColorHspan(0, i, frame_width, span[0].addr, nil, 255)

  saveBMP24("tut04.bmp", buffer, frame_width, frame_height)

main()