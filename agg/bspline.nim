import basics

type
  BSpline* = object
    mMax, mNum: int
    mX, mY: ptr float64
    mAm: seq[float64]
    mLastIdx: int

proc init*(self: var BSpline, max: int)
proc init*(self: var BSpline, num: int, x, y: ptr float64)

proc initBspline*(): BSpline =
  result.mMax = 0
  result.mNum = 0
  result.mX = nil
  result.mY = nil
  result.mAm = @[]
  result.mLastIdx = -1

proc initBspline*(num: int): BSpline =
  result.mMax = 0
  result.mNum = 0
  result.mX = nil
  result.mY = nil
  result.mAm = @[]
  result.mLastIdx = -1
  result.init(num)

proc initBspline*(num: int, x, y: ptr float64): BSpline =
  result.mMax = 0
  result.mNum = 0
  result.mX = nil
  result.mY = nil
  result.mAm = @[]
  result.mLastIdx = -1
  result.init(num, x, y)

proc init(self: var BSpline, max: int) =
  if max > 2 and max > self.mMax:
    self.mAm.setLen(max * 3)
    self.mMax = max
    self.mX   = self.mAm[self.mMax].addr
    self.mY   = self.mAm[self.mMax * 2].addr
  self.mNum = 0
  self.mLastIdx = -1

proc addPoint*(self: var BSpline, x, y: float64) =
  if self.mNum < self.mMax:
    self.mX[self.mNum] = x
    self.mY[self.mNum] = y
    inc self.mNum

proc prepare*(self: var BSpline) =
  if self.mNum > 2:
    var
      n1: int
      temp, r, s: ptr float64
      h, p, d, f, e: float64

    for k in 0.. <self.mNum:
      self.mAm[k] = 0.0

    n1 = 3 * self.mNum
    var al = newSeq[float64](n1)
    temp = al[0].addr

    for k in 0.. <n1:
      temp[k] = 0.0

    r = temp + self.mNum
    s = temp + self.mNum * 2

    n1 = self.mNum - 1
    d = self.mX[1] - self.mX[0]
    e = (self.mY[1] - self.mY[0]) / d

    for k in 1.. <n1:
      h     = d
      d     = self.mX[k + 1] - self.mX[k]
      f     = e
      e     = (self.mY[k + 1] - self.mY[k]) / d
      al[k] = d / (d + h)
      r[k]  = 1.0 - al[k]
      s[k]  = 6.0 * (e - f) / (h + d)

    for k in 1.. <n1:
      p = 1.0 / (r[k] * al[k - 1] + 2.0)
      al[k] *= -p
      s[k] = (s[k] - r[k] * s[k - 1]) * p

    self.mAm[n1]     = 0.0
    al[n1 - 1]       = s[n1 - 1]
    self.mAm[n1 - 1] = al[n1 - 1]

    var k = n1 - 2
    for i in 0.. <self.mNum - 2:
      al[k]   = al[k] * al[k + 1] + s[k]
      self.mAm[k] = al[k]
      dec k

  self.mLastIdx = -1

proc init(self: var BSpline, num: int, x, y: ptr float64) =
  var
    x = x
    y = y
  if num > 2:
    self.init(num)
    for i in 0.. <num:
      self.addPoint(x[], y[])
      inc x; inc y
    self.prepare()
  self.mLastIdx = -1

proc bsearch(n: int, x: ptr float64, x0: float64, i: var int) =
  var
    j = n - 1
    k: int

  i = 0
  while (j - i) > 1:
    k = (i + j) shr 1
    if x0 < x[k]: j = k
    else: i = k

proc extrapolationLeft(self: BSpline, x: float64): float64 =
  let d = self.mX[1] - self.mX[0]
  result = (-d * self.mAm[1] / 6 + (self.mY[1] - self.mY[0]) / d) *
           (x - self.mX[0]) + self.mY[0]

proc extrapolationRight(self: BSpline, x: float64): float64 =
  let d = self.mX[self.mNum - 1] - self.mX[self.mNum - 2]
  result = (d * self.mAm[self.mNum - 2] / 6 + (self.mY[self.mNum - 1] - self.mY[self.mNum - 2]) / d) *
           (x - self.mX[self.mNum - 1]) + self.mY[self.mNum - 1]

proc interpolation(self: var BSpline, x: float64, i: int): float64 =
  var
    j = i + 1
    d = self.mX[i] - self.mX[j]
    h = x - self.mX[j]
    r = self.mX[i] - x
    p = d * d / 6.0
  result = (self.mAm[j] * r * r * r + self.mAm[i] * h * h * h) / 6.0 / d +
           ((self.mY[j] - self.mAm[j] * p) * r + (self.mY[i] - self.mAm[i] * p) * h) / d

proc get*(self: var BSpline, x: float64): float64 =
  if self.mNum > 2:
    var i: int

    # Extrapolation on the left
    if x < self.mX[0]: return self.extrapolationLeft(x)

    # Extrapolation on the right
    if x >= self.mX[self.mNum - 1]: return self.extrapolationRight(x)

    # Interpolation
    bsearch(self.mNum, self.mX, x, i)
    return self.interpolation(x, i)
  result = 0.0

proc getStateful*(self: var BSpline, x: float64): float64 =
  if self.mNum > 2:
    # Extrapolation on the left
    if x < self.mX[0]: return self.extrapolationLeft(x)

    # Extrapolation on the right
    if x >= self.mX[self.mNum - 1]: return self.extrapolationRight(x)

    if self.mLastIdx >= 0:
      # Check if x is not in current range
      if x < self.mX[self.mLastIdx] or x > self.mX[self.mLastIdx + 1]:
        # Check if x between next points (most probably)
        if self.mLastIdx < self.mNum - 2 and
          x >= self.mX[self.mLastIdx + 1] and
          x <= self.mX[self.mLastIdx + 2]:
            inc self.mLastIdx;
        elif self.mLastIdx > 0 and
          x >= self.mX[self.mLastIdx - 1] and
          x <= self.mX[self.mLastIdx]:
            # x is between pevious points
            dec self.mLastIdx;
        else:
          # Else perform full search
          bsearch(self.mNum, self.mX, x, self.mLastIdx)

      return self. interpolation(x, self.mLastIdx)
    else:
      # Interpolation
      bsearch(self.mNum, self.mX, x, self.mLastIdx)
      return self.interpolation(x, self.mLastIdx)

  result = 0.0
