import agg_basics, agg_rendering_buffer

proc oneComponentMaskU8*(p: ptr uint8): uint = p[]

template rgbToGrayMaskU8(R,G,B: int, name: untyped) =
  proc name(p: ptr uint8): uint =
    result = (p[R].uint*77 + p[G].uint*150 + p[B].uint*29) shr 8

template alphaMaskU8*(Step: int, Offset: int, name: untyped, MaskF: typed = oneComponentMaskU8) =
  type
    name* = object
      rbuf: ptr RenderingBuffer

  template coverShift*(x: typedesc[name]): uint = 8
  template coverNone* (x: typedesc[name]): uint = 0
  template coverFull* (x: typedesc[name]): uint = 255

  proc `init name`*(rbuf: var RenderingBuffer): name =
    result.rbuf = rbuf.addr

  proc attach*(self: var name, rbuf: var RenderingBuffer) =
    self.rbuf = rbuf.addr

  proc pixel*(self: var name, x, y: int): CoverType =
    if x >= 0 and y >= 0 and x < self.rbuf[].width() and y < self.rbuf[].height():
      result = MaskF(self.rbuf[].rowPtr(y) + x * Step + Offset).CoverType
    result = 0

  proc combinePixel*(self: var name, x, y: int, val: CoverType): CoverType =
    if x >= 0 and y >= 0 and x < self.rbuf[].width() and y < self.rbuf[].height():
      result = ((name.coverFull + val.uint * MaskF(self.rbuf[].rowPtr(y) + x * Step + Offset)) shr name.coverShift).CoverType
    result = 0

  proc fillHspan*(self: var name; xx, y: int, dst: ptr CoverType, numPix: int) =
    var
      xmax = self.rbuf[].width() - 1
      ymax = self.rbuf[].height() - 1
      count = numPix
      covers = dst
      x = xx

    if y < 0 or y > ymax:
      setMem(dst, 0, numPix * sizeof(CoverType))
      return

    if x < 0:
      count += x
      if count <= 0:
        setMem(dst, 0, numPix * sizeof(CoverType))
        return
      setMem(covers, 0, -x * sizeof(CoverType))
      covers -= x
      x = 0

    if x + count > xmax:
      var rest = x + count - xmax - 1
      count -= rest
      if count <= 0:
        setMem(dst, 0, numPix * sizeof(CoverType))
        return
      setMem(covers + count, 0, rest * sizeof(CoverType))

    var mask = self.rbuf[].rowPtr(y) + x * Step + Offset
    doWhile count != 0:
      covers[] = CoverType(MaskF(mask))
      inc covers
      inc(mask, Step)
      dec count

  proc combineHspan*(self: var name, xx, y: int, dst: ptr CoverType, numPix: int) =
    var
      xmax = self.rbuf[].width() - 1
      ymax = self.rbuf[].height() - 1
      count = numPix
      covers = dst
      x = xx

    if y < 0 or y > ymax:
      setMem(dst, 0, numPix * sizeof(CoverType))
      return

    if x < 0:
      count += x
      if count <= 0:
         setMem(dst, 0, numPix * sizeof(CoverType))
         return
      setMem(covers, 0, -x * sizeof(CoverType))
      covers -= x
      x = 0

    if x + count > xmax:
      var rest = x + count - xmax - 1
      count -= rest
      if count <= 0:
        setMem(dst, 0, numPix * sizeof(CoverType))
        return
      setMem(covers + count, 0, rest * sizeof(CoverType))

    var mask = self.rbuf[].rowPtr(y) + x * Step + Offset
    doWhile count != 0:
      covers[] = CoverType((name.coverFull + covers[].uint * MaskF(mask)) shr name.coverShift)
      inc covers
      inc(mask, Step)
      dec count

  proc fillVspan*(self: var name, x, yy: int, dst: ptr CoverType, numPix: int) =
    var
      xmax = self.rbuf[].width() - 1
      ymax = self.rbuf[].height() - 1
      count = numPix
      covers = dst
      y = yy

    if x < 0 or x > xmax:
      setMem(dst, 0, numPix * sizeof(CoverType))
      return

    if y < 0:
     count += y
     if count <= 0:
       setMem(dst, 0, numPix * sizeof(CoverType))
       return
     setMem(covers, 0, -y * sizeof(CoverType))
     covers -= y
     y = 0

    if y + count > ymax:
     var rest = y + count - ymax - 1
     count -= rest
     if count <= 0:
       setMem(dst, 0, numPix * sizeof(CoverType))
       return
     setMem(covers + count, 0, rest * sizeof(CoverType))

    var mask = self.rbuf[].rowPtr(y) + x * Step + Offset
    doWhile count != 0:
      covers[] = CoverType(MaskF(mask))
      inc covers
      mask += self.rbuf[].stride()
      dec count

  proc combine_vspan*(self: var name, x, yy: int, dst: ptr CoverType, numPix: int) =
    var
      xmax = self.rbuf[].width() - 1
      ymax = self.rbuf[].height() - 1
      count = numPix
      covers = dst
      y = yy

    if x < 0 or x > xmax:
      setMem(dst, 0, numPix * sizeof(CoverType))
      return

    if y < 0:
      count += y
      if count <= 0:
        setMem(dst, 0, numPix * sizeof(CoverType))
        return
      setMem(covers, 0, -y * sizeof(CoverType))
      covers -= y
      y = 0

    if y + count > ymax:
      var rest = y + count - ymax - 1
      count -= rest
      if count <= 0:
        setMem(dst, 0, numPix * sizeof(CoverType))
        return
      setMem(covers + count, 0, rest * sizeof(CoverType))

    var mask = self.rbuf[].rowPtr(y) + x * Step + Offset;
    doWhile count != 0:
      covers[] = CoverType((name.coverFull + covers[].uint * MaskF(mask)) shr name.coverShift)
      inc covers
      mask += self.rbuf[].stride()
      dec count

alphaMaskU8(1, 0, AlphaMaskGray8)
alphaMaskU8(3, 0, AlphaMaskRgb24r)
alphaMaskU8(3, 1, AlphaMaskRgb24g)
alphaMaskU8(3, 2, AlphaMaskRgb24b)

alphaMaskU8(3, 2, AlphaMaskBgr24r)
alphaMaskU8(3, 1, AlphaMaskBgr24g)
alphaMaskU8(3, 0, AlphaMaskBgr24b)

alphaMaskU8(4, 0, AlphaMaskRgba32r)
alphaMaskU8(4, 1, AlphaMaskRgba32g)
alphaMaskU8(4, 2, AlphaMaskRgba32b)
alphaMaskU8(4, 3, AlphaMaskRgba32a)

alphaMaskU8(4, 1, AlphaMaskArgb32r)
alphaMaskU8(4, 2, AlphaMaskArgb32g)
alphaMaskU8(4, 3, AlphaMaskArgb32b)
alphaMaskU8(4, 0, AlphaMaskArgb32a)

alphaMaskU8(4, 2, AlphaMaskBgra32r)
alphaMaskU8(4, 1, AlphaMaskBgra32g)
alphaMaskU8(4, 0, AlphaMaskBgra32b)
alphaMaskU8(4, 3, AlphaMaskBgra32a)

alphaMaskU8(4, 3, AlphaMaskAbgr32r)
alphaMaskU8(4, 2, AlphaMaskAbgr32g)
alphaMaskU8(4, 1, AlphaMaskAbgr32b)
alphaMaskU8(4, 0, AlphaMaskAbgr32a)

rgbToGrayMaskU8(0, 1, 2, rgbToGrayMask012)
rgbToGrayMaskU8(2, 1, 0, rgbToGrayMask210)

alphaMaskU8(3, 0, AlphaMaskRgb24Gray , rgbToGrayMask012)
alphaMaskU8(3, 0, AlphaMaskBgr24Gray , rgbToGrayMask210)
alphaMaskU8(4, 0, AlphaMaskRgba32Gray, rgbToGrayMask012)
alphaMaskU8(4, 1, AlphaMaskArgb32Gray, rgbToGrayMask012)
alphaMaskU8(4, 0, AlphaMaskBgra32Gray, rgbToGrayMask210)
alphaMaskU8(4, 1, AlphaMaskAbgr32Gray, rgbToGrayMask210)

template amaskNoClipU8*(Step: int, Offset: int, name: untyped, MaskF: typed = oneComponentMaskU8) =
  type
    name* = object
      rbuf: ptr RenderingBuffer

  template coverShift*(x: typedesc[name]): uint = 8
  template coverNone* (x: typedesc[name]): uint = 0
  template coverFull* (x: typedesc[name]): uint = 255

  proc `init name`*(rbuf: var RenderingBuffer): name =
    result.rbuf = rbuf.addr

  proc attach*(self: var name, rbuf: var RenderingBuffer) =
    self.rbuf = rbuf.addr

  proc pixel*(self: var name, x, y: int): CoverType =
    result = CoverType(MaskF(self.rbuf[].rowPtr(y) + x * Step + Offset))

  proc combinePixel*(self: var name, x, y: int, val: CoverType): CoverType =
    result = CoverType((name.coverFull + val.uint * MaskF(self.rbuf[].rowPtr(y) + x * Step + Offset)) shr name.coverShift)

  proc fillHspan*(self: var name, x, y: int, dstx: ptr CoverType, numPixx: int) =
    var
      mask = self.rbuf[].rowPtr(y) + x * Step + Offset
      numPix = numPixx
      dst = dstx

    doWhile numPix != 0:
      dst[] = CoverType(MaskF(mask))
      inc dst
      inc(mask, Step)
      dec numPix

  proc combineHspan*(self: var name, x, y: int, dstx: ptr CoverType, numPixx: int) =
    var
      mask = self.rbuf[].rowPtr(y) + x * Step + Offset
      dst = dstx
      numPix = numPixx

    doWhile numPix != 0:
      dst[] = CoverType((name.coverFull + dst[].uint * MaskF(mask)) shr name.coverShift)
      inc dst
      inc(mask, Step)
      dec numPix

  proc fillVspan*(self: var name, x, y: int, dstx: ptr CoverType, numPixx: int) =
    var
      mask = self.rbuf[].rowPtr(y) + x * Step + Offset
      dst = dstx
      numPix = numPixx

    doWhile numPix != 0:
      dst[] = CoverType(MaskF(mask))
      inc dst
      inc(mask, self.rbuf[].stride())
      dec numPix

  proc combineVspan*(self: var name, x, y: int, dstx: ptr CoverType, numPixx: int) =
    var
      mask = self.rbuf[].rowPtr(y) + x * Step + Offset
      dst = dstx
      numPix = numPixx

    doWhile numPix != 0:
      dst[] = CoverType((name.coverFull + dst[].uint * MaskF(mask)) shr name.coverShift)
      inc dst
      inc(mask, self.rbuf[].stride())
      dec numPix

amaskNoClipU8(1, 0, AmaskNoClipGray8)
amaskNoClipU8(3, 0, AmaskNoClipRgb24r)
amaskNoClipU8(3, 1, AmaskNoClipRgb24g)
amaskNoClipU8(3, 2, AmaskNoClipRgb24b)

amaskNoClipU8(3, 2, AmaskNoClipBgr24r)
amaskNoClipU8(3, 1, AmaskNoClipBgr24g)
amaskNoClipU8(3, 0, AmaskNoClipBgr24b)

amaskNoClipU8(4, 0, AmaskNoClipRgba32r)
amaskNoClipU8(4, 1, AmaskNoClipRgba32g)
amaskNoClipU8(4, 2, AmaskNoClipRgba32b)
amaskNoClipU8(4, 3, AmaskNoClipRgba32a)

amaskNoClipU8(4, 1, AmaskNoClipaRgb32r)
amaskNoClipU8(4, 2, AmaskNoClipaRgb32g)
amaskNoClipU8(4, 3, AmaskNoClipaRgb32b)
amaskNoClipU8(4, 0, AmaskNoClipaRgb32a)

amaskNoClipU8(4, 2, AmaskNoClipbgRa32r)
amaskNoClipU8(4, 1, AmaskNoClipbgRa32g)
amaskNoClipU8(4, 0, AmaskNoClipbgRa32b)
amaskNoClipU8(4, 3, AmaskNoClipbgRa32a)

amaskNoClipU8(4, 3, AmaskNoClipAbgr32r)
amaskNoClipU8(4, 2, AmaskNoClipAbgr32g)
amaskNoClipU8(4, 1, AmaskNoClipAbgr32b)
amaskNoClipU8(4, 0, AmaskNoClipAbgr32a)

amaskNoClipU8(3, 0, AmaskNoClipRgb24gray , rgbToGrayMask012)
amaskNoClipU8(3, 0, AmaskNoClipBgr24gray , rgbToGrayMask210)
amaskNoClipU8(4, 0, AmaskNoClipRgba32gray, rgbToGrayMask012)
amaskNoClipU8(4, 1, AmaskNoClipArgb32gray, rgbToGrayMask012)
amaskNoClipU8(4, 0, AmaskNoClipBgra32gray, rgbToGrayMask210)
amaskNoClipU8(4, 1, AmaskNoClipAbgr32gray, rgbToGrayMask210)