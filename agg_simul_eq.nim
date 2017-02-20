import agg_basics, math

proc swapArrays[T](a1, a2: ptr T, n: int) =
  var
    a1 = a1
    a2 = a2
  for i in 0.. <n:
    let tmp = a1[]
    a1[] = a2[]
    a2[] = tmp
    inc a1
    inc a2

template matrixPivot*(name: untyped, Rows, Cols: int) =
  proc name(m: ptr float64, row: int): int =
    var
      k = row
      maxVal = -1.0

    for i in row.. <Rows:
      let tmp = abs(m[i * Cols + row])
      if tmp > maxVal and tmp != 0.0:
         maxVal = tmp
         k = i

    if m[k * Cols + row] == 0.0:
      return -1

    if k != row:
      swapArrays(m[k * Cols].addr, m[row * Cols].addr, Cols)
      return k

    result = 0

template simulEq*(name: untyped, Size, RightCols: int) =
  matrixPivot(`name pivot`, Size, (Size + RightCols))

  proc name(left: array[Size*Size, float64], 
    right: array[Size * RightCols, float64], res: var array[Size * RightCols, float64]): bool =
    
    const Cols = Size + RightCols
    var tmp: array[Size * Cols, float64]

    for i in 0.. <Size:
      for j in 0.. <Size:
         tmp[i * Cols + j] = left[i * Size + j]
      for j in 0.. <RightCols:
         tmp[i * Cols + (Size + j)] = right[i * RightCols + j]

    for k in 0.. <Size:
      if `name pivot`(tmp[0].addr, k) < 0:
        return false # Singularity....

      var a1 = tmp[k * Cols + k]

      for j in k.. <Size + RightCols:
        tmp[k * Cols + j] = tmp[k * Cols + j] / a1

      for i in k + 1.. <Size:
        a1 = tmp[i * Cols + k]
        for j in k.. <Size + RightCols:
          tmp[i * Cols + j] -= a1 * tmp[k * Cols + j]


    for k in 0.. <RightCols:
      for m in countdown(Size - 1, 0):
        res[m * RightCols + k] = tmp[m * Cols + (Size + k)]
        for j in m + 1.. <Size:
          res[m * RightCols + k] -= tmp[m * Cols + j] * res[j * RightCols + k]

    result = true
