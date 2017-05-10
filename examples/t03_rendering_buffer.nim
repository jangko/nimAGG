import agg/[rendering_buffer, basics, pixfmt_rgb, color_rgba]
import platform.nimBMP

const
  frame_width = 320
  frame_height = 200

proc draw_black_frame[T](ren: var  T) =
  let c = initRgba8(0,0,0)
  let w = ren.width()
  let h = ren.height()

  for i in 0.. <h:
    ren.copyPixel(0,     i, c)
    ren.copyPixel(w - 1, i, c)

  for i in 0.. <w:
    ren.copyPixel(i,     0, c)
    ren.copyPixel(i, h - 1, c)

proc main() =
  var buffer = newString(frame_width * frame_height * 3)
  for i in 0.. <buffer.len: buffer[i] = 255.chr
  var rbuf = initRenderingBuffer(cast[ptr uint8](buffer[0].addr), frame_width, frame_height, frame_width * 3)
  var pixf = initPixFmtRgb24(rbuf)

  let h = pixf.height() div 2

  for i in 0.. <h:
    pixf.copyPixel(i, i, initRgba8(255, 0, 127))

  draw_black_frame(pixf)
  saveBMP24("tut03.bmp", buffer, frame_width, frame_height)

main()