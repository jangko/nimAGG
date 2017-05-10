import basics

type
  BitsetIterator* = object
    mBits: ptr uint8
    mMask: uint8

proc initBitsetIterator*(bits: ptr uint8, offset = 0): BitsetIterator =
  result.mBits = bits + (offset shr 3)
  result.mMask = (0x80 shr (offset and 7)).uint8

proc inc*(self: var BitsetIterator) =
  self.mMask = self.mMask shr 1
  if self.mMask == 0:
    inc self.mBits
    self.mMask = 0x80

proc bit*(self: BitsetIterator): int = (self.mBits[] and self.mMask).int
