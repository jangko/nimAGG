import agg_basics

type
  SpanConverter*[SpanGenerator, SpanConverter] = object
    mSpanGen: ptr SpanGenerator
    mSpanCnv: ptr SpanConverter

proc initSpanConverter*[SG, SC](spanGen: var SG, spanCnv: var SC): SpanConverter[SG, SC] =
  result.mSpanGen = spanGen.addr
  result.mSpanCnv = spanCnv.addr

proc attachGenerator*[SG, SC](self: var SpanConverter[SG, SC], spanGen: var SG) = self.mSpanGen = spanGen.addr
proc attachConverter*[SG, SC](self: var SpanConverter[SG, SC], spanCnv: var SC) = self.mSpanCnv = spanCnv.addr

proc prepare*[SG, SC](self: var SpanConverter[SG, SC]) =
  self.mSpanGen[].prepare()
  self.mSpanCnv[].prepare()

proc generate*[SG, SC, ColorT](self: var SpanConverter[SG, SC], span: ptr ColorT, x, y, len: int) =
  self.mSpanGen[].generate(span, x, y, len)
  self.mSpanCnv[].generate(span, x, y, len)



