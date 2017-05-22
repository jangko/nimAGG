import vertex_sequence

proc shortenPath*[VertexSequence](vs: var VertexSequence, s: float64, closed = 0'u) =
  if s > 0.0 and vs.len() > 1:
    var
      d: float64
      n = int(vs.len() - 2)
      s = s

    while n != 0:
      d = vs[n].dist
      if d > s: break
      vs.removeLast()
      s -= d
      dec n

    if vs.len() < 2:
      vs.removeAll()
    else:
      n = vs.len() - 1
      var prev = vs[n-1]
      var last = vs[n]
      d = (prev.dist - s) / prev.dist
      var x = prev.x + (last.x - prev.x) * d
      var y = prev.y + (last.y - prev.y) * d
      last.x = x
      last.y = y
      if not prev.cmp(last): vs.removeLast()
      var closed = closed != 0
      vs.close(closed)
