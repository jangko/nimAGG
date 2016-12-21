import agg_rendering_buffer, nimBMP, agg_basics

const
  frame_width = 320
  frame_height = 200

# Draw a black frame around the rendering buffer, assuming it has 
# RGB-structure, one byte per color component
proc draw_black_frame(rbuf: var RenderingBuffer) =
  let h = rbuf.height()
  for i in 0.. <h:
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
  for i in 0.. <buffer.len: buffer[i] = 255.chr
  var rbuf = initRowAccessor(cast[ptr uint8](buffer[0].addr), frame_width, frame_height, frame_width * 3)

  let h = rbuf.height() div 2
  for i in 0.. <h:
    # Get the pointer to the beginning of the i-th row (Y-coordinate)
    # and shift it to the i-th position, that is, X-coordinate.
    var row = rbuf.rowPtr(i) + i * 3
        
    # PutPixel, very sophisticated, huh? :)
    row[] = 127; row.inc # R
    row[] = 200; row.inc # G
    row[] = 98;  row.inc # B
    
  draw_black_frame(rbuf)
  saveBMP24("test.bmp", buffer, frame_width, frame_height)

main()