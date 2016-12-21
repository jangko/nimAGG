import agg_rendering_buffer, nimBMP

const
  frame_width = 320
  frame_height = 200

# Draw a black frame around the rendering buffer, assuming it has 
# RGB-structure, one byte per color component
#--------------------------------------------------
proc draw_black_frame(rbuf: rendering_buffer) =
  unsigned i;
  for(i = 0; i < rbuf.height(); ++i)
    unsigned char* p = rbuf.row_ptr(i);
      *p++ = 0; *p++ = 0; *p++ = 0;
      p += (rbuf.width() - 2) * 3;
      *p++ = 0; *p++ = 0; *p++ = 0;
    memset(rbuf.row_ptr(0), 0, rbuf.width() * 3);
    memset(rbuf.row_ptr(rbuf.height() - 1), 0, rbuf.width() * 3);

proc main() =
  var buffer = newSeqWith[uint8](frame_width * frame_height * 3, 255)

    memset(buffer, 255, frame_width * frame_height * 3)

    agg::rendering_buffer rbuf(buffer, 
                               frame_width, 
                               frame_height, 
                               frame_width * 3);

    unsigned i;
    for(i = 0; i < rbuf.height()/2; ++i)
    {
        // Get the pointer to the beginning of the i-th row (Y-coordinate)
        // and shift it to the i-th position, that is, X-coordinate.
        //---------------
        unsigned char* ptr = rbuf.row_ptr(i) + i * 3;
        
        // PutPixel, very sophisticated, huh? :)
        //-------------
        *ptr++ = 127; // R
        *ptr++ = 200; // G
        *ptr++ = 98;  // B
    }

    draw_black_frame(rbuf);
    write_ppm(buffer, frame_width, frame_height, "agg_test.ppm");

    delete [] buffer;
    return 0;