import agg/[path_storage, basics], math

type
  Spiral* = object
    mX, mY, mR1, mR2, mStep, mStartAngle: float64
    mAngle, mCurrR, mDa, mDr: float64
    mStart: bool

proc initSpiral*(x, y, r1, r2, step: float64, startAngle=0.0): Spiral =
  result.mX = x
  result.mY = y
  result.mR1 = r1
  result.mR2 = r2
  result.mStep = step
  result.mStartAngle = startAngle
  result.mAngle = startAngle
  result.mDa = deg2rad(4.0)
  result.mDr = result.mStep / 90.0

proc rewind*(self: var Spiral, pathId: int) =
  self.mAngle = self.mStartAngle
  self.mCurrR = self.mR1
  self.mStart = true

proc vertex*(self: var Spiral, x, y: var float64): uint =
  if self.mCurrR > self.mR2: return pathCmdStop

  x = self.mX + cos(self.mAngle) * self.mCurrR
  y = self.mY + sin(self.mAngle) * self.mCurrR
  self.mCurrR += self.mDr
  self.mAngle += self.mDa

  if self.mStart:
    self.mStart = false
    return pathCmdMoveTo

  return pathCmdLineTo

proc makeArrows*(ps: var PathStorage) =
  ps.removeAll()

  ps.moveTo(1330.599999999999909,1282.399999999999864)
  ps.lineTo(1377.400000000000091,1282.399999999999864)
  ps.lineTo(1361.799999999999955,1298.000000000000000)
  ps.lineTo(1393.000000000000000,1313.599999999999909)
  ps.lineTo(1361.799999999999955,1344.799999999999955)
  ps.lineTo(1346.200000000000045,1313.599999999999909)
  ps.lineTo(1330.599999999999909,1329.200000000000045)
  ps.closePolygon()

  ps.moveTo(1330.599999999999909,1266.799999999999955)
  ps.lineTo(1377.400000000000091,1266.799999999999955)
  ps.lineTo(1361.799999999999955,1251.200000000000045)
  ps.lineTo(1393.000000000000000,1235.599999999999909)
  ps.lineTo(1361.799999999999955,1204.399999999999864)
  ps.lineTo(1346.200000000000045,1235.599999999999909)
  ps.lineTo(1330.599999999999909,1220.000000000000000)
  ps.closePolygon()

  ps.moveTo(1315.000000000000000,1282.399999999999864)
  ps.lineTo(1315.000000000000000,1329.200000000000045)
  ps.lineTo(1299.400000000000091,1313.599999999999909)
  ps.lineTo(1283.799999999999955,1344.799999999999955)
  ps.lineTo(1252.599999999999909,1313.599999999999909)
  ps.lineTo(1283.799999999999955,1298.000000000000000)
  ps.lineTo(1268.200000000000045,1282.399999999999864)
  ps.closePolygon()

  ps.moveTo(1268.200000000000045,1266.799999999999955)
  ps.lineTo(1315.000000000000000,1266.799999999999955)
  ps.lineTo(1315.000000000000000,1220.000000000000000)
  ps.lineTo(1299.400000000000091,1235.599999999999909)
  ps.lineTo(1283.799999999999955,1204.399999999999864)
  ps.lineTo(1252.599999999999909,1235.599999999999909)
  ps.lineTo(1283.799999999999955,1251.200000000000045)
  ps.closePolygon()

proc makeSingleArrow*(ps: var PathStorage) =
  ps.removeAll()

  ps.moveTo(1330.599999999999909,1282.399999999999864)
  ps.lineTo(1377.400000000000091,1282.399999999999864)
  ps.lineTo(1361.799999999999955,1298.000000000000000)
  ps.lineTo(1393.000000000000000,1313.599999999999909)
  ps.lineTo(1361.799999999999955,1344.799999999999955)
  ps.lineTo(1346.200000000000045,1313.599999999999909)
  ps.lineTo(1330.599999999999909,1329.200000000000045)
  ps.closePolygon()