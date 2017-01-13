import agg_basics, agg_trans_affine, strutils

type
  ConvTransform*[VertexSource, Transformer] = object
    source: ptr VertexSource
    trans: ptr Transformer

proc initConvTransform*[V, T](vs: var V, tr: var T): ConvTransform[V,T] =
  result.source = vs.addr
  result.trans = tr.addr
  
proc attach*[V,T](self: ConvTransform[V,T], source: var V) =
  self.source = source.addr

proc rewind*[V,T](self: var ConvTransform[V,T], pathId: int) =
  mixin rewind
  self.source[].rewind(pathId)

proc vertex*[V,T](self: var ConvTransform[V,T], x, y: var float64): uint =
  mixin vertex, transform
  let cmd = self.source[].vertex(x, y)
  if isVertex(cmd):
    self.trans[].transform(x, y)
  result = cmd
  
proc transformer*[V,T](self: ConvTransform[V,T], tr: var T) =
  self.trans = tr.addr
