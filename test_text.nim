import agg_gsv_text, strutils, agg_basics

{.passC: "-I./agg-2.5/include".}
{.compile: "agg_gsv_text2.cpp".}
{.passL: "-lstdc++".}

proc test_text(txt: cstring) {.importc.}

proc addPath[T](vs: var T, pathId = 0) =
  var x, y: float64
  vs.rewind(pathId)

  var cmd = vs.vertex(x, y)
  while not isStop(cmd):
    #echo "$1 $2 $3" % [x.formatFloat(ffDecimal, 3), y.formatFloat(ffDecimal, 3), $cmd]
    cmd = vs.vertex(x, y)

proc main() =
  var txt = initGsvText()

  var text = "abc"

  txt.size(10.0)
  txt.startPoint(0, 0)
  txt.text(text)
  txt.addPath()

  #echo "---"
  #test_text(text)

main()

