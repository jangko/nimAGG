type
  PointT* = object
    x*, y*: float64

  EdgeFill* = object
    above*, below*: bool

  Edge* = ref object
    id*: int
    start*, stop*: PointT
    myFill*, otherFill*: EdgeFill

  Edges*   = seq[Edge]
  Region*  = seq[PointT]
  Regions* = seq[Region]
