const rgb8_color = ["rgb24", "bgr24", "rgba32","abgr32","argb32","bgra32","rgb555","rgb565"]
const rgb8_width = [3,3,4,4,4,4,2,2]

const special_color_src = ["rgb24", "bgr24"]
const special_width_src = [3, 3]

const special_color_dst = ["gray8"]
const special_width_dst = [1]

const rgb16 = [
  ("gray16","gray8",2,1 ),
  ("rgb24","rgb48",3,6  ),
  ("bgr24","bgr48",3,6  ),
  ("rgb24","bgr48",3,6  ),
  ("bgr24","rgb48",3,6  ),
  ("rgb48","rgb24",6,3  ),
  ("bgr48","bgr24",6,3  ),
  ("rgb48","bgr24",6,3  ),
  ("bgr48","rgb24",6,3  ),
  ("rgbAAA","rgb24",4,3 ),
  ("rgbAAA","bgr24",4,3 ),
  ("bgrAAA","rgb24",4,3 ),
  ("bgrAAA","bgr24",4,3 ),
  ("rgbBBA","rgb24",4,3 ),
  ("rgbBBA","bgr24",4,3 ),
  ("bgrABB","rgb24",4,3 ),
  ("bgrABB","bgr24",4,3 ),
  ("rgba64","rgba32",8,4),
  ("argb64","argb32",8,4),
  ("bgra64","bgra32",8,4),
  ("abgr64","abgr32",8,4),
  ("argb64","abgr32",8,4),
  ("argb64","bgra32",8,4),
  ("argb64","rgba32",8,4),
  ("bgra64","abgr32",8,4),
  ("bgra64","argb32",8,4),
  ("bgra64","rgba32",8,4),
  ("rgba64","abgr32",8,4),
  ("rgba64","argb32",8,4),
  ("rgba64","bgra32",8,4),
  ("abgr64","argb32",8,4),
  ("abgr64","bgra32",8,4),
  ("abgr64","rgba32",8,4),
  ("rgb24","argb64",3,8 ),
  ("rgb24","abgr64",3,8 ),
  ("rgb24","bgra64",3,8 ),
  ("rgb24","rgba64",3,8 ),
  ("bgr24","argb64",3,8 ),
  ("bgr24","abgr64",3,8 ),
  ("bgr24","bgra64",3,8 ),
  ("bgr24","rgba64",3,8 ),
  ("rgb24","gray16",3,2 ),
  ("bgr24","gray16",3,2 )
  ]

const test_width = 100

echo "#include <agg_basics.h>"
echo "#include <util/agg_color_conv.h>"
echo "#include <util/agg_color_conv_rgb8.h>"
echo "#include <util/agg_color_conv_rgb16.h>"
echo "#include <stdio.h>"
echo "#define test_width ", test_width
echo "typedef agg::int8u int8u;"

echo "void print_arr(int8u* arr, int width, const char* title) {"
echo "  printf(\"  let dst_%s = [\", title);"
echo "  for(int i=0; i<width;i++) {"
echo "    printf(\"%d'u8\", (int)arr[i]);"
echo "    if (i < (width - 1)) = printf(\", \"); }"
echo "  }"
echo "  printf(\"]\\n\");"
echo "}"

echo "void test_color_conv_rgb8() {"
echo "  int8u src[test_width];"
echo "  int8u dst[test_width];"
echo "  int width, i;"
echo "  for(i=0; i<test_width; i++) {"
echo "    src[i] = i;"
echo "  }"

echo "  printf(\"proc test_color_conv_rgb8() =\\n\");"
echo "  printf(\"  const test_width = ",test_width,"\\n\");"
echo "  printf(\"  var src: array[test_width, uint8]\\n\");"
echo "  printf(\"  var dst: array[test_width, uint8]\\n\");"
echo "  printf(\"\\n\");"
echo "  printf(\"  for i in 0.. <test_width:\\n\");"
echo "  printf(\"    src[i] = i.uint8\\n\");"

proc output(src_color, dst_color: string, src_width, dst_width, dst_width_long: int) =
  echo "  width = ", min(src_width, dst_width), ";"
  echo "  agg::color_conv_row(dst, src, width, agg::color_conv_", src_color, "_to_", dst_color, "());"
  echo "  print_arr(dst, ", dst_width_long, ", \"", src_color, "_to_", dst_color, "\");"
  echo "  printf(\"  color_conv_",src_color,"_to_",dst_color,"(dst[0].addr, src[0].addr, %d)\\n\", width);"
  echo "  printf(\"  compare(\\\"",src_color,"_to_",dst_color,"\\\", dst[0].addr, dst_",src_color,"_to_",dst_color,"[0].unsafeAddr, ", dst_width_long, ")\\n\");"

proc output(color_src, color_dst: openArray[string], width_src, width_dst: openArray[int]) =
  for x in 0.. <color_src.len:
    for y in 0.. <color_dst.len:
      let src_color = color_src[x]
      let dst_color = color_dst[y]
      let src_width = test_width div width_src[x]
      let dst_width = test_width div width_dst[y]
      let dst_width_long = dst_width * width_dst[y]
      output(src_color, dst_color, src_width, dst_width, dst_width_long)

output(rgb8_color, rgb8_color, rgb8_width, rgb8_width)
output(special_color_src, special_color_dst, special_width_src, special_width_dst)

for i in 0.. <rgb16.len:
  let src_color = rgb16[i][0]
  let dst_color = rgb16[i][1]
  let src_width = test_width div rgb16[i][2]
  let dst_width = test_width div rgb16[i][3]
  let dst_width_long = dst_width * rgb16[i][3]
  output(src_color, dst_color, src_width, dst_width, dst_width_long)

echo "  printf(\"test_color_conv_rgb8()\\n\");"
echo "}"

echo "int main() {"
echo "  test_color_conv_rgb8();"
echo "  return 0;"
echo "}"


