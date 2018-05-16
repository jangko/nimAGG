import agg/[rendering_buffer, basics]
import nimBMP

const
  frame_width = 320
  frame_height = 200

# Draw a black frame around the rendering buffer, assuming it has
# RGB-structure, one byte per color component
proc draw_black_frame(rbuf: var RenderingBuffer) =
  let h = rbuf.height()
  for i in 0..<h:
    var p = rbuf.rowPtr(i)
    p[] = 0; p.inc
    p[] = 0; p.inc
    p[] = 0; p.inc
    p += (rbuf.width() - 2) * 3
    p[] = 0; p.inc
    p[] = 0; p.inc
    p[] = 0; p.inc

  let w = rbuf.width() * 3
  zeroMem(rbuf.rowPtr(0), w)
  zeroMem(rbuf.rowPtr(rbuf.height() - 1), w)

proc main() =
  var buffer = newString(frame_width * frame_height * 3)
  for i in 0..<buffer.len: buffer[i] = 255.chr
  var rbuf = initRenderingBuffer(cast[ptr uint8](buffer[0].addr), frame_width, frame_height, frame_width * 3)

  # Draw the outer black frame
  draw_black_frame(rbuf)

  # Attach to the part of the buffer,
  # with 20 pixel margins at each side.
  var p = cast[ptr uint8](buffer[0].addr)
  rbuf.attach(p + frame_width * 3 * 20 +  # initial Y-offset
              3 * 20,                     # initial X-offset
              frame_width - 40,
              frame_height - 40,
              frame_width * 3             # Note that the stride
              )                           # remains the same


  # draw diagonal line
  let h = rbuf.height() div 2
  for i in 0..<h:
    # Get the pointer to the beginning of the i-th row (Y-coordinate)
    # and shift it to the i-th position, that is, X-coordinate.
    var row = rbuf.rowPtr(i) + i * 3

    # PutPixel, very sophisticated, huh? :)
    row[] = 127; row.inc # R
    row[] = 200; row.inc # G
    row[] = 98;  row.inc # B

  # draw inner frame
  draw_black_frame(rbuf)
  saveBMP24("tut02.bmp", buffer, frame_width, frame_height)

main()