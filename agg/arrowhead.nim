import basics

type
  Arrowhead* = object
    mHeadD1, mHeadD2, mHeadD3, mHeadD4: float64
    mTailD1, mTailD2, mTailD3, mTailD4: float64
    mHeadFlag, mTailFlag: bool
    mCoord: array[16, float64]
    mCmd: array[8, uint]
    mCurrId, mCurCoord: int

proc initArrowhead*(): Arrowhead =
  result.mHeadD1 = 1.0
  result.mHeadD2 = 1.0
  result.mHeadD3 = 1.0
  result.mHeadD4 = 0.0
  result.mTailD1 = 1.0
  result.mTailD2 = 1.0
  result.mTailD3 = 1.0
  result.mTailD4 = 0.0
  result.mHeadFlag = false
  result.mTailFlag = false
  result.mCurrId = 0
  result.mCurCoord = 0

proc head*(self: var Arrowhead, d1, d2, d3, d4: float64) =
  self.mHeadD1 = d1
  self.mHeadD2 = d2
  self.mHeadD3 = d3
  self.mHeadD4 = d4
  self.mHeadFlag = true

proc head*(self: var Arrowhead) = self.mHeadFlag = true
proc noHead*(self: var Arrowhead) =  self.mHeadFlag = false

proc tail*(self: var Arrowhead, d1, d2, d3, d4: float64) =
  self.mTailD1 = d1
  self.mTailD2 = d2
  self.mTailD3 = d3
  self.mTailD4 = d4
  self.mTailFlag = true

proc tail*(self: var Arrowhead) = self.mTailFlag = true
proc noTail*(self: var Arrowhead) = self.mTailFlag = false

proc rewind*(self: var Arrowhead, pathId: int) =
  self.mCurrId = pathId
  self.mCurCoord = 0
  if pathId == 0:
    if not self.mTailFlag:
      self.mCmd[0] = pathCmdStop
      return

    self.mCoord[0]  =  self.mTailD1
    self.mCoord[1]  =  0.0
    self.mCoord[2]  =  self.mTailD1 - self.mTailD4
    self.mCoord[3]  =  self.mTailD3
    self.mCoord[4]  = -self.mTailD2 - self.mTailD4
    self.mCoord[5]  =  self.mTailD3
    self.mCoord[6]  = -self.mTailD2
    self.mCoord[7]  =  0.0
    self.mCoord[8]  = -self.mTailD2 - self.mTailD4
    self.mCoord[9]  = -self.mTailD3
    self.mCoord[10] =  self.mTailD1 - self.mTailD4
    self.mCoord[11] = -self.mTailD3

    self.mCmd[0] = pathCmdMoveTo
    self.mCmd[1] = pathCmdLineto
    self.mCmd[2] = pathCmdLineto
    self.mCmd[3] = pathCmdLineto
    self.mCmd[4] = pathCmdLineto
    self.mCmd[5] = pathCmdLineto
    self.mCmd[7] = pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
    self.mCmd[6] = pathCmdStop
    return


  if pathId == 1:
    if not self.mHeadFlag:
      self.mCmd[0] = pathCmdStop
      return

    self.mCoord[0]  = -self.mHeadD1
    self.mCoord[1]  = 0.0
    self.mCoord[2]  = self.mHeadD2 + self.mHeadD4
    self.mCoord[3]  = -self.mHeadD3
    self.mCoord[4]  = self.mHeadD2
    self.mCoord[5]  = 0.0
    self.mCoord[6]  = self.mHeadD2 + self.mHeadD4
    self.mCoord[7]  = self.mHeadD3

    self.mCmd[0] = pathCmdMoveTo
    self.mCmd[1] = pathCmdLineto
    self.mCmd[2] = pathCmdLineto
    self.mCmd[3] = pathCmdLineto
    self.mCmd[4] = pathCmdEndPoly or pathFlagsClose or pathFlagsCcw
    self.mCmd[5] = pathCmdStop
    return

proc vertex*(self: var Arrowhead, x, y: var float64): uint =
  if self.mCurrId < 2:
    let currIdx = self.mCurCoord * 2
    x = self.mCoord[currIdx]
    y = self.mCoord[currIdx + 1]
    result = self.mCmd[self.mCurCoord]
    inc self.mCurCoord
    return result
  return pathCmdStop
