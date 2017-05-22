@echo off
nim c -d:release --verbosity:0 --hints:off gen_color_conv
gen_color_conv > gen_color_conv.cpp
g++ -o gen_color_conv_cpp.exe -I../agg-2.5/include gen_color_conv.cpp
gen_color_conv_cpp > test_color_conv_inc.nim
nim c -d:release --verbosity:0 --hints:off test_color_conv_test
test_color_conv_test

del gen_color_conv.exe
del gen_color_conv.cpp
del gen_color_conv_cpp.exe
del test_color_conv_inc.nim
del test_color_conv_test.exe