import agg_basics, agg_color_conv_rgb8, agg_color_conv_rgb16, agg_color_conv, agg_rendering_buffer

proc compare(title: string, a, b: ptr uint8, width: int) =
  echo title
  for i in 0.. <width:
    if a[i] != b[i]:
      echo title, " failed at ", i, ", ", int(a[i]), " : ", int(b[i])
      quit(1)
      break

#this include generated by gen_color_conv
include test_color_conv_inc

template test_rendering_buffer(renbuf, tester: untyped) =
  proc tester() =
    const
      frame_width = 100
      frame_height = 100

    var src = newString(frame_width * frame_height * 4)
    for i in 0.. <src.len: src[i] = (i mod 255).chr
    var srcbuf = renbuf(cast[ptr uint8](src[0].addr), frame_width, frame_height, frame_width * 4)

    var dst = newString(frame_width * frame_height * 4)
    var dstbuf = renbuf(cast[ptr uint8](dst[0].addr), frame_width, frame_height, frame_width * 4)

    var ori = newString(frame_width * frame_height * 4)
    var oribuf = renbuf(cast[ptr uint8](ori[0].addr), frame_width, frame_height, frame_width * 4)

    colorConv(dstbuf, srcbuf, color_conv_argb32_to_rgba32)
    colorConv(oribuf, dstbuf, color_conv_rgba32_to_argb32)

    if src != ori:
      echo "colorConv failed"

    dstbuf.copyFrom(oribuf)

    if dst != ori:
      echo "copyFrom failed"

    oribuf.clear(255)

    for c in ori:
      if c != 255.chr:
        echo "clear failed"
        break

test_rendering_buffer(initRenderingBuffer, test_renbuf1)
test_rendering_buffer(initRenderingBufferCached, test_renbuf2)

test_renbuf1()
test_renbuf2()