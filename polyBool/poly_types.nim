import strutils

type
  PointT* = object
    x*, y*: float64

  EdgeFill* = object
    above*, below*: bool
  
  Edge* = ref object
    id*: int
    start*, stop*: PointT
    myFill*: EdgeFill
    otherFill*: EdgeFill

  Edges*   = seq[Edge]
  Region*  = seq[PointT]
  Regions* = seq[Region]
  
proc debug*(seg: Edge) =
  var x = "(id: -1, start: (x: " & seg.start.x.formatFloat(ffDecimal, 3)
  x.add ", y: " & seg.start.y.formatFloat(ffDecimal, 3) & "), stop: (x: " & seg.stop.x.formatFloat(ffDecimal, 3)
  x.add ", y: " & seg.stop.y.formatFloat(ffDecimal, 3) & "), myFill: (above: " & $seg.myFill.above
  x.add ", below: " & $seg.myFill.below & "), otherFill: "
  x.add "(above: " & $seg.otherFill.above
  x.add ", below: " & $seg.otherFill.below & "))"
  echo x
  
proc debug*(p: PointT): string =
  result = "(x: " & p.x.formatFloat(ffDecimal, 3)
  result.add ", y: " & p.y.formatFloat(ffDecimal, 3) & ")"
    