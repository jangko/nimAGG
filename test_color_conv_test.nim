import agg_basics, agg_color_conv_rgb8, agg_color_conv_rgb16

proc compare(title: string, a, b: ptr uint8, width: int) =
  echo title
  for i in 0.. <width:
    if a[i] != b[i]:
      echo title, " failed at ", i, ", ", int(a[i]), " : ", int(b[i])
      quit(1)
      break
    
include test_color_conv_inc

