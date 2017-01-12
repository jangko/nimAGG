import agg_basics, agg_trans_affine, strutils

type
  ConvTransform*[VertexSource, Transformer] = object
    source: VertexSource
    trans: Transformer

proc initConvTransform*[V, T](vs: V, tr: T): ConvTransform[V,T] =
  result.source = vs
  result.trans = tr
  
proc attach*[V,T](self: ConvTransform[V,T], source: V) =
  self.source = source

proc rewind*[V,T](self: var ConvTransform[V,T], pathId: int) =
  mixin rewind
  self.source.rewind(pathId)

proc vertex*[V,T](self: var ConvTransform[V,T], x, y: var float64): uint =
  mixin vertex, transform
  let cmd = self.source.vertex(x, y)
  if isVertex(cmd):
    self.trans.transform(x, y)
  result = cmd
  
proc transformer*[V,T](self: ConvTransform[V,T], tr: T) =
  self.trans = tr
