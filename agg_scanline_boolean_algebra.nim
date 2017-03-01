import agg_basics, agg_scanline_storage_aa

template sbool_combine_spans_bin(name: untyped, Span1, Span2, Scanline: typed) =
  proc name(span1: var Span1, span2: var Span2, x, len: int, sl: var Scanline) =
    sl.addSpan(x, len, coverFull)

template sbool_combine_spans_empty(name: untyped, Span1, Span2, Scanline: typed) =
  proc name(span1: var Span1, span2: var Span2, x, len: int, sl: var Scanline) =
    discard

template sbool_add_span_empty(name: untyped, Span, Scanline: typed) =
  proc name(span: var Span, x, len: int, sl: var Scanline) =
    discard

template sbool_add_span_bin(name: untyped, Span, Scanline: typed): untyped =
  proc sbool_add_span_bin_impl(span: var Span, x, len: int, sl: var Scanline) =
    sl.addSpan(x, len, coverFull)
  sbool_add_span_bin_impl

template sbool_add_span_aa(Span, Scanline: typed): untyped =
  proc sbool_add_span_aa_impl(span: var Span, x, len: int, sl: var Scanline) =
    if span.len < 0:
      sl.addSpan(x, len, span.covers[])
    elif span.len > 0:
      var covers = span.covers
      if span.x < x: covers += x - span.x
      sl.addCells(x, len, covers)
  sbool_add_span_aa_impl

template sbool_intersect_spans_aa(Span1, Span2, Scanline: typed, CoverShift: int = coverShift): untyped =
  proc sbool_intersect_spans_aa_impl(span1: var Span1, span2: var Span2,  x, len: int, sl: var Scanline) =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1
      coverFull  = coverMask

    var
      cover: uint
      covers1: getCoverT(Span1)
      covers2: getCoverT(Span2)

    # Calculate the operation code and choose the
    # proper combination algorithm.
    # 0 = Both spans are of AA type
    # 1 = span1 is solid, span2 is AA
    # 2 = span1 is AA, span2 is solid
    # 3 = Both spans are of solid type
    #-----------------
    case (span1.len < 0).ord or ((span2.len < 0) shl 1).ord
    of 0:      # Both are AA spans
      covers1 = span1.covers
      covers2 = span2.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = covers1[] * covers2[]
        inc covers1
        inc covers2
        if cover == coverFull * coverFull:
          sl.addCell(x, coverFull)
        else:
          sl.addCell(x, cover shr coverShift)
        inc x
        dec len
    of 1:      # span1 is solid, span2 is AA
      covers2 = span2.covers
      if span2.x < x: covers2 += x - span2.x
      if span1.covers[] == coverFull:
        sl.addCells(x, len, covers2)
      else:
        doWhile len != 0:
          cover = span1.covers[] * covers2[]
          inc covers2
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
          inc x
          dec len
    of 2:      # span1 is AA, span2 is solid
      covers1 = span1.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.covers: == coverFull:
        sl.addCells(x, len, covers1)
      else:
        doWhile len != 0:
          cover = covers1[] * span2.covers[]
          inc covers1
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
          inc x
          dec len
    of 3:      # Both are solid spans
      cover = span1.covers[] * span2.covers[]
      if cover == coverFull * coverFull:
        sl.addCell(x, coverFull)
      else:
        sl.addCell(x, cover shr coverShift)

  sbool_intersect_spans_aa_impl

template sbool_unite_spans_aa(Span1, Span2, Scanline: typed, CoverShift: int = coverShift): untyped =
  proc sbool_unite_spans_aa_impl(span1: var Span1, span2: var Span2, x, len: int, sl: var Scanline) =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1
      coverFull  = coverMask

    var
      cover: uint
      covers1: getCoverT(Span1)
      covers2: getCoverT(Span2)

    # Calculate the operation code and choose the
    # proper combination algorithm.
    # 0 = Both spans are of AA type
    # 1 = span1 is solid, span2 is AA
    # 2 = span1 is AA, span2 is solid
    # 3 = Both spans are of solid type
    #-----------------
    case (span1.len < 0).ord or ((span2.len < 0) shl 1).ord
    of 0:      # Both are AA spans
      covers1 = span1.covers
      covers2 = span2.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = coverMask * coverMask -
               (coverMask - covers1[]) *
               (coverMask - covers2[])
        inc covers1
        inc covers2
        if cover == coverFull * coverFull:
          sl.addCell(x, coverFull)
        else:
          sl.addCell(x, cover shr coverShift)
        inc x
        dec len
    of 1:      # span1 is solid, span2 is AA
      covers2 = span2.covers
      if span2.x < x: covers2 += x - span2.x
      if span1.covers[] == coverFull:
        sl.addSpan(x, len, coverFull)
      else:
        doWhile len != 0:
          cover = coverMask * coverMask -
                 (coverMask - span1.covers[]) *
                 (coverMask - covers2[])
          inc covers2
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
          inc x
          dec len
    of 2:      # span1 is AA, span2 is solid
      covers1 = span1.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.covers[] == coverFull:
        sl.addSpan(x, len, coverFull)
      else:
        doWhile len != 0:
          cover = coverMask * coverMask -
                 (coverMask - covers1[]) *
                 (coverMask - span2.covers[])
          inc covers1
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
          inc x
          dec len
    of 3:      # Both are solid spans
      cover = coverMask * coverMask -
             (coverMask - span1.covers[]) *
             (coverMask - span2.covers[])
      if cover == coverFull * coverFull:
        sl.addCell(x, coverFull)
      else:
        sl.addCell(x, cover shr coverShift)
  sbool_unite_spans_aa_impl

template sbool_xor_formula_linear(name: untyped, CoverShift: int = coverShift) =
  proc name(a, b: uint): uint =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1

    var cover = a + b
    if cover > coverMask: cover = coverMask + coverMask - cover
    result = cover

template sbool_xor_formula_saddle(name: untyped, CoverShift: int = coverShift) =
  proc name(a, b: uint): uint =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1

    var k = a * b
    if k == coverMask * coverMask: return 0
    let
      a = (coverMask * coverMask - (a shl coverShift) + k) shr coverShift
      b = (coverMask * coverMask - (b shl coverShift) + k) shr coverShift
    result = coverMask - ((a * b) shr coverShift)

template sbool_xor_formula_abs_diff(name: untyped) =
  proc name(a, b: uint): uint =
    result = uint(abs(int(a) - int(b)))

template sbool_xor_spans_aa(Span1, Span2, Scanline, XorFormula: typed, CoverShift: int = coverShift): untyped =
  proc sbool_xor_spans_aa_impl(span1: var Span1, span2: var Span2, x, len: int, sl: var Scanline) =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1
      coverFull  = coverMask

    var
      cover: uint
      covers1: getCoverT(Span1)
      covers2: getCoverT(Span2)

    # Calculate the operation code and choose the
    # proper combination algorithm.
    # 0 = Both spans are of AA type
    # 1 = span1 is solid, span2 is AA
    # 2 = span1 is AA, span2 is solid
    # 3 = Both spans are of solid type
    case (span1.len < 0).ord or ((span2.len < 0) shl 1).ord
    of 0:      # Both are AA spans
      covers1 = span1.covers
      covers2 = span2.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = XorFormula(covers1[], covers2[])
        inc covers1
        inc covers2
        if cover != 0: sl.addCell(x, cover)
        inc x
        dec len
    of 1:      # span1 is solid, span2 is AA
      covers2 = span2.covers
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = XorFormula(span1.covers[], covers2[])
        inc covers2
        if cover != 0: sl.addCell(x, cover)
        inc x
        dec len
    of 2:      # span1 is AA, span2 is solid
      covers1 = span1.covers
      if span1.x < x: covers1 += x - span1.x
      doWhile len != 0:
        cover = XorFormula(covers1[], span2.covers[])
        inc covers1
        if cover != 0: sl.addCell(x, cover)
        inc x
        dec len
    of 3:      # Both are solid spans
      cover = XorFormula(span1.covers[], span2.covers[])
      if cover != 0: sl.addSpan(x, len, cover)
    else:
      discard
  sbool_xor_spans_aa


template sbool_subtract_spans_aa(Span1, Span2, Scanline: typed, CoverShift: int = coverShift): untyped =
  proc sbool_subtract_spans_aa_impl(span1: var Span1, span2: var Span2, x, len: int, sl: var Scanline) =
    const
      coverShift = CoverShift
      coverSize  = 1 shl coverShift
      coverMask  = coverSize - 1
      coverFull  = coverMask

    var
      cover: uint
      covers1: getCoverT(Span1)
      covers2: getCoverT(Span2)

    # Calculate the operation code and choose the
    # proper combination algorithm.
    # 0 = Both spans are of AA type
    # 1 = span1 is solid, span2 is AA
    # 2 = span1 is AA, span2 is solid
    # 3 = Both spans are of solid type
    case (span1.len < 0).ord or ((span2.len < 0) shl 1).ord
    of 0:      # Both are AA spans
      covers1 = span1.covers
      covers2 = span2.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = covers1[] * (coverMask - covers2[])
        inc covers1
        inc covers2
        if cover != 0:
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
        inc x
        dec len
    of 1:      # span1 is solid, span2 is AA
      covers2 = span2.covers
      if span2.x < x: covers2 += x - span2.x
      doWhile len != 0:
        cover = span1.covers[] * (coverMask - covers2[])
        inc covers2
        if cover != 0:
          if cover == coverFull * coverFull:
            sl.addCell(x, coverFull)
          else:
            sl.addCell(x, cover shr coverShift)
        inc x
        dec len
    of 2:      # span1 is AA, span2 is solid
      covers1 = span1.covers
      if span1.x < x: covers1 += x - span1.x
      if span2.covers[] != coverFull:
        doWhile len != 0:
          cover = covers1[] * (coverMask - span2.covers[])
          inc covers1
          if cover != 0:
            if cover == coverFull * coverFull:
              sl.addCell(x, coverFull)
            else:
              sl.addCell(x, cover shr coverShift)
          inc x
          dec len
    of 3:      # Both are solid spans
      cover = span1.covers[] * (coverMask - span2.covers[])
      if cover != 0:
        if cover == coverFull * coverFull:
          sl.addCell(x, coverFull)
        else:
          sl.addCell(x, cover shr coverShift)
    else:
      discard

  sbool_subtract_spans_aa_impl

proc sbool_add_spans_and_render[Scanline1, Scanline, Renderer, AddSpanFunctor](sl1: var Scanline1,
  sl: var Scanline, ren: var Renderer, addSpan: AddSpanFunctor) =

  sl.resetSpans()
  var
    span = sl1.begin()
    numSpans = sl1.numSpans()
  while true:
    addSpan(span, span.x, abs(span.len), sl)
    dec numSpans
    if numSpans == 0: break
    inc span

  sl.finalize(sl1.y())
  ren.render(sl)

proc sbool_intersect_scanlines[Scanline1, Scanline2, Scanline, CombineSpansFunctor](sl1: var Scanline1,
  sl2: var Scanline2, sl: var Scanline, combineSpans: CombineSpansFunctor) =

  sl.resetSpans()

  var num1 = sl1.numSpans()
  if num1 == 0: return

  var num2 = sl2.numSpans()
  if num2 == 0: return

  var
    span1 = sl1.begin()
    span2 = sl2.begin()

  while num1 != 0 and num2 != 0:
    var
      xb1 = span1.x
      xb2 = span2.x
      xe1 = xb1 + abs(span1.len) - 1
      xe2 = xb2 + abs(span2.len) - 1

      # Determine what spans we should advance in the next step
      # The span with the least ending X should be advanced
      # advance_both is just an optimization when we ending
      # coordinates are the same and we can advance both
      advance_span1 = xe1 <  xe2
      advance_both  = xe1 == xe2

    # Find the intersection of the spans
    # and check if they intersect
    if xb1 < xb2: xb1 = xb2
    if xe1 > xe2: xe1 = xe2
    if xb1 <= xe1:
      combineSpans(span1, span2, xb1, xe1 - xb1 + 1, sl)

    # Advance the spans
    if advance_both:
      dec num1
      dec num2
      if num1 != 0: inc span1
      if num2 != 0: inc span2
    else:
      if advance_span1:
        dec num1
        if num1 != 0: inc span1
      else:
        dec num2
        if num2 != 0: inc span2

proc sbool_intersect_shapes[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer, CombineSpansFunctor](sg1: var ScanlineGen1,
  sg2: var ScanlineGen2, sl1: var Scanline1, sl2: var Scanline2,
  sl: var Scanline, ren: var Renderer, combineSpans: CombineSpansFunctor) =

  # Prepare the scanline generators.
  # If anyone of them doesn't contain
  # any scanlines, then return.

  if not sg1.rewindScanlines(): return
  if not sg2.rewindScanlines(): return

  # Get the bounding boxes
  var
    r1 = initRectI(sg1.minX(), sg1.minY(), sg1.maxX(), sg1.maxY())
    r2 = initRectI(sg2.minX(), sg2.minY(), sg2.maxX(), sg2.maxY())

    # Calculate the intersection of the bounding
    # boxes and return if they don't intersect.
    ir = intersectRectangles(r1, r2)

  if not ir.isValid(): return

  # Reset the scanlines and get two first ones
  sl.reset(ir.x1, ir.x2)
  sl1.reset(sg1.minX(), sg1.maxX())
  sl2.reset(sg2.minX(), sg2.maxX())
  if not sg1.sweepScanline(sl1): return
  if not sg2.sweepScanline(sl2): return

  ren.prepare()

  # The main loop
  # Here we synchronize the scanlines with
  # the same Y coordinate, ignoring all other ones.
  # Only scanlines having the same Y-coordinate
  # are to be combined.
  while true:
    while sl1.y() < sl2.y():
      if not sg1.sweepScanline(sl1): return
    while sl2.y() < sl1.y():
      if not sg2.sweepScanline(sl2): return

    if sl1.y() == sl2.y():
      # The Y coordinates are the same.
      # Combine the scanlines, render if they contain any spans,
      # and advance both generators to the next scanlines
      sbool_intersect_scanlines(sl1, sl2, sl, combineSpans)
      if sl.numSpans() != 0:
        sl.finalize(sl1.y())
        ren.render(sl)

      if not sg1.sweepScanline(sl1): return
      if not sg2.sweepScanline(sl2): return

proc sbool_unite_scanlines[Scanline1, Scanline2, Scanline,
  AddSpanFunctor1, AddSpanFunctor2, CombineSpansFunctor](sl1: var Scanline1,
  sl2: var Scanline2, sl: var Scanline, addSpan1: AddSpanFunctor1,
  addSpan2: AddSpanFunctor2, combineSpans: CombineSpansFunctor) =

  sl.resetSpans()

  var
    num1 = sl1.numSpans()
    num2 = sl2.numSpans()
    span1: getIterT(Scanline1)
    span2: getIterT(Scanline2)

  const
    invalid_b = 0xFFFFFFF
    invalid_e = invalid_b - 1

  # Initialize the spans as invalid
  var
    xb1 = invalid_b
    xb2 = invalid_b
    xe1 = invalid_e
    xe2 = invalid_e

  # Initialize span1 if there are spans
  if num1 != 0:
    span1 = sl1.begin()
    xb1 = span1.x
    xe1 = xb1 + abs(span1.len) - 1
    dec num1

  # Initialize span2 if there are spans
  if num2 != 0:
    span2 = sl2.begin()
    xb2 = span2.x
    xe2 = xb2 + abs(span2.len) - 1
    dec num2

  while true:
    # Retrieve a new span1 if it's invalid
    if num1 != 0 and xb1 > xe1:
      dec num1
      inc span1
      xb1 = span1.x
      xe1 = xb1 + abs(span1.len) - 1

    # Retrieve a new span2 if it's invalid
    if num2 != 0 and xb2 > xe2:
      dec num2
      inc span2
      xb2 = span2.x
      xe2 = xb2 + abs(span2.len) - 1

    if xb1 > xe1 and xb2 > xe2: break

    # Calculate the intersection
    var
      xb = xb1
      xe = xe1
    if xb < xb2: xb = xb2
    if xe > xe2: xe = xe2
    var len = xe - xb + 1 # The length of the intersection
    if len > 0:
      # The spans intersect,
      # add the beginning of the span
      #----------------
      if xb1 < xb2:
        addSpan1(span1, xb1, xb2 - xb1, sl)
        xb1 = xb2
      elif xb2 < xb1:
        addSpan2(span2, xb2, xb1 - xb2, sl)
        xb2 = xb1

      # Add the combination part of the spans
      combineSpans(span1, span2, xb, len, sl)

      # Invalidate the fully processed span or both
      if xe1 < xe2:
        # Invalidate span1 and eat
        # the processed part of span2
        xb1 = invalid_b
        xe1 = invalid_e
        xb2 += len
      elif xe2 < xe1:
        # Invalidate span2 and eat
        # the processed part of span1
        xb2 = invalid_b
        xe2 = invalid_e
        xb1 += len
      else:
        xb1 = invalid_b  # Invalidate both
        xb2 = invalid_b
        xe1 = invalid_e
        xe2 = invalid_e
    else:
      # The spans doWhile len != 0: not intersect
      if xb1 < xb2:
        # Advance span1
        if xb1 <= xe1:
          addSpan1(span1, xb1, xe1 - xb1 + 1, sl)
        xb1 = invalid_b # Invalidate
        xe1 = invalid_e
      else:
        # Advance span2
        if xb2 <= xe2:
          addSpan2(span2, xb2, xe2 - xb2 + 1, sl)
        xb2 = invalid_b # Invalidate
        xe2 = invalid_e

proc sbool_unite_shapes[ScanlineGen1, ScanlineGen2, Scanline1, Scanline2,
  Scanline, Renderer, AddSpanFunctor1, AddSpanFunctor2,
  CombineSpansFunctor](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer,
  addSpan1: AddSpanFunctor1, addSpan2: AddSpanFunctor2, combineSpans: CombineSpansFunctor) =

  # Prepare the scanline generators.
  # If anyone of them doesn't contain
  # any scanlines, then return.
  var
    flag1 = sg1.rewindScanlines()
    flag2 = sg2.rewindScanlines()

  if not flag1 and not flag2: return

  # Get the bounding boxes
  var
    r1 = initRectI(sg1.minX(), sg1.minY(), sg1.maxX(), sg1.maxY())
    r2 = initRectI(sg2.minX(), sg2.minY(), sg2.maxX(), sg2.maxY())

    # Calculate the union of the bounding boxes
    ur = initRectI(1,1,0,0)

  if flag1 and flag2: ur = uniteRectangles(r1, r2)
  elif flag1:         ur = r1
  elif flag2:         ur = r2

  if not ur.isValid(): return

  ren.prepare()

  # Reset the scanlines and get two first ones
  sl.reset(ur.x1, ur.x2)
  if flag1:
    sl1.reset(sg1.minX(), sg1.maxX())
    flag1 = sg1.sweepScanline(sl1)

  if flag2:
    sl2.reset(sg2.minX(), sg2.maxX())
    flag2 = sg2.sweepScanline(sl2)

  # The main loop
  # Here we synchronize the scanlines with
  # the same Y coordinate.
  while flag1 or flag2:
    if flag1 and flag2:
      if sl1.y() == sl2.y():
        # The Y coordinates are the same.
        # Combine the scanlines, render if they contain any spans,
        # and advance both generators to the next scanlines
        #----------------------
        sbool_unite_scanlines(sl1, sl2, sl, addSpan1, addSpan2, combineSpans)
        if sl.numSpans():
          sl.finalize(sl1.y())
          ren.render(sl)
        flag1 = sg1.sweepScanline(sl1)
        flag2 = sg2.sweepScanline(sl2)
      else:
        if sl1.y() < sl2.y():
          sbool_add_spans_and_render(sl1, sl, ren, addSpan1)
          flag1 = sg1.sweepScanline(sl1)
        else:
          sbool_add_spans_and_render(sl2, sl, ren, addSpan2)
          flag2 = sg2.sweepScanline(sl2)
    else:
      if flag1:
        sbool_add_spans_and_render(sl1, sl, ren, addSpan1)
        flag1 = sg1.sweepScanline(sl1)
      if flag2:
        sbool_add_spans_and_render(sl2, sl, ren, addSpan2)
        flag2 = sg2.sweepScanline(sl2)

proc sbool_subtract_shapes[ScanlineGen1, ScanlineGen2, Scanline1, Scanline2,
  Scanline, Renderer, AddSpanFunctor1, CombineSpansFunctor](sg1: var ScanlineGen1,
  sg2: var ScanlineGen2, sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline,
  ren: var Renderer, addSpan1: AddSpanFunctor1, combineSpans: CombineSpansFunctor) =

  # Prepare the scanline generators.
  # Here "sg1" is master, "sg2" is slave.
  if not sg1.rewindScanlines(): return
  var
    flag2 = sg2.rewindScanlines()
    # Get the bounding box
    r1 = initRectI(sg1.minX(), sg1.minY(), sg1.maxX(), sg1.maxY())

  # Reset the scanlines and get two first ones
  sl.reset(sg1.minX(), sg1.maxX())
  sl1.reset(sg1.minX(), sg1.maxX())
  sl2.reset(sg2.minX(), sg2.maxX())
  if not sg1.sweepScanline(sl1): return

  if flag2: flag2 = sg2.sweepScanline(sl2)

  ren.prepare()

  # A fake span2 processor
  sbool_add_span_empty(addSpan2, Scanline2, Scanline)

  # The main loop
  # Here we synchronize the scanlines with
  # the same Y coordinate, ignoring all other ones.
  # Only scanlines having the same Y-coordinate
  # are to be combined.
  #-----------------
  var flag1 = true
  doWhile flag1:
    # Synchronize "slave" with "master"
    while flag2 and sl2.y() < sl1.y():
      flag2 = sg2.sweepScanline(sl2)

    if flag2 and sl2.y() == sl1.y():
      # The Y coordinates are the same.
      # Combine the scanlines and render if they contain any spans.
      sbool_unite_scanlines(sl1, sl2, sl, addSpan1, addSpan2, combineSpans)
      if sl.numSpans():
        sl.finalize(sl1.y())
        ren.render(sl)
    else:
      sbool_add_spans_and_render(sl1, sl, ren, addSpan1)

    # Advance the "master"
    flag1 = sg1.sweepScanline(sl1)

proc sbool_intersect_shapes_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var combine_functor = sbool_intersect_spans_aa(getIterT(Scanline1), getIterT(Scanline2), Scanline)
  sbool_intersect_shapes(sg1, sg2, sl1, sl2, sl, ren, combine_functor)

proc sbool_intersect_shapes_bin[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var combine_functor = sbool_combine_spans_bin(getIterT(Scanline1), getIterT(Scanline2), Scanline)
  sbool_intersect_shapes(sg1, sg2, sl1, sl2, sl, ren, combine_functor)

proc sbool_unite_shapes_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var
    add_functor1 = sbool_add_span_aa(Scanline1, Scanline)
    add_functor2 = sbool_add_span_aa(Scanline2, Scanline)
    combine_functor = sbool_unite_spans_aa(Scanline1, Scanline2, Scanline)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_unite_shapes_bin[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var
    add_functor1 = sbool_add_span_bin(Scanline1, Scanline)
    add_functor2 = sbool_add_span_bin(Scanline2, Scanline)
    combine_functor = sbool_combine_spans_bin(Scanline1, Scanline2, Scanline)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_xor_shapes_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  sbool_xor_formula_linear(xor_formula)

  var
    add_functor1 = sbool_add_span_aa(Scanline1, Scanline)
    add_functor2 = sbool_add_span_aa(Scanline2, Scanline)
    combine_functor = sbool_xor_spans_aa(Scanline1, Scanline2, Scanline, xor_formula)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_xor_shapes_saddle_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  sbool_xor_formula_saddle(xor_formula)

  var
    add_functor1 = sbool_add_span_aa(Scanline1, Scanline)
    add_functor2 = sbool_add_span_aa(Scanline2, Scanline)
    combine_functor = sbool_xor_spans_aa(Scanline1, Scanline2, Scanline, xor_formula)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_xor_shapes_abs_diff_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  sbool_xor_formula_abs_diff(xor_formula)

  var
    add_functor1 = sbool_add_span_aa(Scanline1, Scanline)
    add_functor2 = sbool_add_span_aa(Scanline2, Scanline)
    combine_functor = sbool_xor_spans_aa(Scanline1, Scanline2, Scanline, xor_formula)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_xor_shapes_bin[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var
    add_functor1 = sbool_add_span_bin(Scanline1, Scanline)
    add_functor2 = sbool_add_span_bin(Scanline2, Scanline)
    combine_functor = sbool_combineSpans_empty(Scanline1, Scanline2, Scanline)

  sbool_unite_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor1, add_functor2, combine_functor)

proc sbool_subtract_shapes_aa[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var
    add_functor = sbool_add_span_aa(Scanline1, Scanline)
    combine_functor = sbool_subtract_spans_aa(Scanline1, Scanline2, Scanline)

  sbool_subtract_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor, combine_functor)

proc sbool_subtract_shapes_bin[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  var
    add_functor = sbool_add_span_bin(Scanline1, Scanline)
    combine_functor = sbool_combineSpans_empty(Scanline1, Scanline2, Scanline)

  sbool_subtract_shapes(sg1, sg2, sl1, sl2, sl, ren, add_functor, combine_functor)

type
  SboolOp = enum
    sbool_or
    sbool_and
    sbool_xor
    sbool_xor_saddle
    sbool_xor_abs_diff
    sbool_a_minus_b
    sbool_b_minus_a

proc sbool_combine_shapes_bin*[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](op: SboolOp, sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  case op
  of sbool_or          : sbool_unite_shapes_bin(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_and         : sbool_intersect_shapes_bin(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_xor, sbool_xor_saddle, sbool_xor_abs_diff:
    sbool_xor_shapes_bin(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_a_minus_b   : sbool_subtract_shapes_bin(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_b_minus_a   : sbool_subtract_shapes_bin(sg2, sg1, sl2, sl1, sl, ren)

proc sbool_combine_shapes_aa*[ScanlineGen1, ScanlineGen2, Scanline1,
  Scanline2, Scanline, Renderer](op: SboolOp, sg1: var ScanlineGen1, sg2: var ScanlineGen2,
  sl1: var Scanline1, sl2: var Scanline2, sl: var Scanline, ren: var Renderer) =

  case op
  of sbool_or          : sbool_unite_shapes_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_and         : sbool_intersect_shapes_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_xor         : sbool_xor_shapes_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_xor_saddle  : sbool_xor_shapes_saddle_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_xor_abs_diff: sbool_xor_shapes_abs_diff_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_a_minus_b   : sbool_subtract_shapes_aa(sg1, sg2, sl1, sl2, sl, ren)
  of sbool_b_minus_a   : sbool_subtract_shapes_aa(sg2, sg1, sl2, sl1, sl, ren)
