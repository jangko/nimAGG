import agg_basics, math

template gamma_lut*(nameT: untyped, LoResT, HiResT: typedesc, GammaShift, HiResShift: int) =
  type
    nameT* = ref object
      gamma: float64
      dirGamma: seq[HiResT]
      invGamma: seq[LoResT]

  template getGammaShift*(x: typedesc[nameT]): int = GammaShift
  template getGammaSize*(x: typedesc[nameT]): int  = 1 shl getGammaShift(x)
  template getGammaMask*(x: typedesc[nameT]): int  = getGammaSize(x) - 1

  template getHiResShift*(x: typedesc[nameT]): int = HiResShift
  template getHiResSize*(x: typedesc[nameT]): int  = 1 shl getHiResShift(x)
  template getHiResMask*(x: typedesc[nameT]): int  = getHiResSize(x) - 1

  proc `new nameT`*(): nameT =
    const
      gammaSize  = getGammaSize(nameT)
      gammaShift = getGammaShift(nameT)
      hiResSize  = getHiResSize(nameT)
      hiResShift = getHiResShift(nameT)

    new(result)
    result.gamma = 1.0
    result.dirGamma = newSeq[HiResT](gammaSize)
    result.invGamma = newSeq[LoResT](hiResSize)

    for i in 0.. <gammaSize:
      result.dirGamma[i] = HiResT(i shl (hiResShift - gammaShift))

    for i in 0.. <hiResSize:
      result.invGamma[i] = LoResT(i shr (hiResShift - gammaShift))

  proc setGamma*(self: var nameT, g: float64) =
    const
      gammaSize = getGammaSize(nameT)
      gammaMask = getGammaMask(nameT).float64
      hiResSize = getHiResSize(nameT)
      hiResMask = getHiResMask(nameT).float64

    self.gamma = g

    for i in 0.. <gammaSize:
      self.dirGamma[i] = uround(math.pow(i.float64 / gammaMask, self.gamma) * hiResMask).HiResT

    let inv_g = 1.0 / g
    for i in 0.. <hiResSize:
      self.invGamma[i] = uround(math.pow(i.float64 / hiResMask, inv_g) * gammaMask).LoResT

  proc `new nameT`*(g: float64): nameT =
    const
      gammaSize  = getGammaSize(nameT)
      hiResSize  = getHiResSize(nameT)

    new(result)
    result.gamma = 1.0
    result.dirGamma = newSeq[HiResT](gammaSize)
    result.invGamma = newSeq[LoResT](hiResSize)
    result.setGamma(g)

  proc getGamma*(self: nameT): float64 =
    result = self.gamma

  proc dir*(self: nameT, v: LoResT): HiResT =
    result = self.dirGamma[v.int]

  proc inv*(self: nameT, v: HiResT): LoResT =
    result = self.invGamma[v.int]

gamma_lut(GammaLut, uint8, uint8, 8, 8)
gamma_lut(GammaLut16, uint16, uint16, 16, 16)