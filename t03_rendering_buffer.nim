import agg_rendering_buffer, nimBMP, agg_basics, agg_pixfmt_rgb, agg_color_rgba

const
  frame_width = 320
  frame_height = 200
  
proc draw_black_frame[T](ren: var  T) =
  let c = initRgba8(0,0,0)
  let w = ren.width()
  let h = ren.height()
  
  for i in 0.. <h:
    ren.copy_pixel(0,     i, c)
    ren.copy_pixel(w - 1, i, c)
    
  for i in 0.. <w:
    ren.copy_pixel(i,     0, c)
    ren.copy_pixel(i, h - 1, c)
    
proc main() =
  var buffer = newString(frame_width * frame_height * 3)
  for i in 0.. <buffer.len: buffer[i] = 255.chr
  var rbuf = initRowAccessor(cast[ptr uint8](buffer[0].addr), frame_width, frame_height, frame_width * 3)
  var pixf = initPixFmtRgb24(rbuf)
  
  let h = pixf.height() div 2
  
  for i in 0.. <h:
    pixf.copy_pixel(i, i, initRgba8(255, 0, 127))

  draw_black_frame(pixf)
  saveBMP24("test.bmp", buffer, frame_width, frame_height)
  
main()