import xmlparser, svg_path_renderer, svg_path_tokenizer, xmltree, tables
import agg_color_rgba, strutils, strtabs, agg_math_stroke, parseutils
import agg_trans_affine, agg_basics

let colors = {
  "aliceblue": (240,248,255,255),
  "antiquewhite": (250,235,215,255),
  "aqua": (0,255,255,255),
  "aquamarine": (127,255,212,255),
  "azure": (240,255,255,255),
  "beige": (245,245,220,255),
  "bisque": (255,228,196,255),
  "black": (0,0,0,255),
  "blanchedalmond": (255,235,205,255),
  "blue": (0,0,255,255),
  "blueviolet": (138,43,226,255),
  "brown": (165,42,42,255),
  "burlywood": (222,184,135,255),
  "cadetblue": (95,158,160,255),
  "chartreuse": (127,255,0,255),
  "chocolate": (210,105,30,255),
  "coral": (255,127,80,255),
  "cornflowerblue": (100,149,237,255),
  "cornsilk": (255,248,220,255),
  "crimson": (220,20,60,255),
  "cyan": (0,255,255,255),
  "darkblue": (0,0,139,255),
  "darkcyan": (0,139,139,255),
  "darkgoldenrod": (184,134,11,255),
  "darkgray": (169,169,169,255),
  "darkgreen": (0,100,0,255),
  "darkgrey": (169,169,169,255),
  "darkkhaki": (189,183,107,255),
  "darkmagenta": (139,0,139,255),
  "darkolivegreen": (85,107,47,255),
  "darkorange": (255,140,0,255),
  "darkorchid": (153,50,204,255),
  "darkred": (139,0,0,255),
  "darksalmon": (233,150,122,255),
  "darkseagreen": (143,188,143,255),
  "darkslateblue": (72,61,139,255),
  "darkslategray": (47,79,79,255),
  "darkslategrey": (47,79,79,255),
  "darkturquoise": (0,206,209,255),
  "darkviolet": (148,0,211,255),
  "deeppink": (255,20,147,255),
  "deepskyblue": (0,191,255,255),
  "dimgray": (105,105,105,255),
  "dimgrey": (105,105,105,255),
  "dodgerblue": (30,144,255,255),
  "firebrick": (178,34,34,255),
  "floralwhite": (255,250,240,255),
  "forestgreen": (34,139,34,255),
  "fuchsia": (255,0,255,255),
  "gainsboro": (220,220,220,255),
  "ghostwhite": (248,248,255,255),
  "gold": (255,215,0,255),
  "goldenrod": (218,165,32,255),
  "gray": (128,128,128,255),
  "green": (0,128,0,255),
  "greenyellow": (173,255,47,255),
  "grey": (128,128,128,255),
  "honeydew": (240,255,240,255),
  "hotpink": (255,105,180,255),
  "indianred": (205,92,92,255),
  "indigo": (75,0,130,255),
  "ivory": (255,255,240,255),
  "khaki": (240,230,140,255),
  "lavender": (230,230,250,255),
  "lavenderblush": (255,240,245,255),
  "lawngreen": (124,252,0,255),
  "lemonchiffon": (255,250,205,255),
  "lightblue": (173,216,230,255),
  "lightcoral": (240,128,128,255),
  "lightcyan": (224,255,255,255),
  "lightgoldenrodyellow": (250,250,210,255),
  "lightgray": (211,211,211,255),
  "lightgreen": (144,238,144,255),
  "lightgrey": (211,211,211,255),
  "lightpink": (255,182,193,255),
  "lightsalmon": (255,160,122,255),
  "lightseagreen": (32,178,170,255),
  "lightskyblue": (135,206,250,255),
  "lightslategray": (119,136,153,255),
  "lightslategrey": (119,136,153,255),
  "lightsteelblue": (176,196,222,255),
  "lightyellow": (255,255,224,255),
  "lime": (0,255,0,255),
  "limegreen": (50,205,50,255),
  "linen": (250,240,230,255),
  "magenta": (255,0,255,255),
  "maroon": (128,0,0,255),
  "mediumaquamarine": (102,205,170,255),
  "mediumblue": (0,0,205,255),
  "mediumorchid": (186,85,211,255),
  "mediumpurple": (147,112,219,255),
  "mediumseagreen": (60,179,113,255),
  "mediumslateblue": (123,104,238,255),
  "mediumspringgreen": (0,250,154,255),
  "mediumturquoise": (72,209,204,255),
  "mediumvioletred": (199,21,133,255),
  "midnightblue": (25,25,112,255),
  "mintcream": (245,255,250,255),
  "mistyrose": (255,228,225,255),
  "moccasin": (255,228,181,255),
  "navajowhite": (255,222,173,255),
  "navy": (0,0,128,255),
  "oldlace": (253,245,230,255),
  "olive": (128,128,0,255),
  "olivedrab": (107,142,35,255),
  "orange": (255,165,0,255),
  "orangered": (255,69,0,255),
  "orchid": (218,112,214,255),
  "palegoldenrod": (238,232,170,255),
  "palegreen": (152,251,152,255),
  "paleturquoise": (175,238,238,255),
  "palevioletred": (219,112,147,255),
  "papayawhip": (255,239,213,255),
  "peachpuff": (255,218,185,255),
  "peru": (205,133,63,255),
  "pink": (255,192,203,255),
  "plum": (221,160,221,255),
  "powderblue": (176,224,230,255),
  "purple": (128,0,128,255),
  "red": (255,0,0,255),
  "rosybrown": (188,143,143,255),
  "royalblue": (65,105,225,255),
  "saddlebrown": (139,69,19,255),
  "salmon": (250,128,114,255),
  "sandybrown": (244,164,96,255),
  "seagreen": (46,139,87,255),
  "seashell": (255,245,238,255),
  "sienna": (160,82,45,255),
  "silver": (192,192,192,255),
  "skyblue": (135,206,235,255),
  "slateblue": (106,90,205,255),
  "slategray": (112,128,144,255),
  "slategrey": (112,128,144,255),
  "snow": (255,250,250,255),
  "springgreen": (0,255,127,255),
  "steelblue": (70,130,180,255),
  "tan": (210,180,140,255),
  "teal": (0,128,128,255),
  "thistle": (216,191,216,255),
  "tomato": (255,99,71,255),
  "turquoise": (64,224,208,255),
  "violet": (238,130,238,255),
  "wheat": (245,222,179,255),
  "white": (255,255,255,255),
  "whitesmoke": (245,245,245,255),
  "yellow": (255,255,0,255),
  "yellowgreen": (154,205,50,255),
  "zzzzzzzzzzz": (0,0,0,0)}.toTable()

type
  Parser* = object
    mPath: ptr PathRenderer
    mTokenizer: PathTokenizer
    mTitle: string
    mTitleFlag: bool
    mPathFlag: bool

proc initParser*(path: var PathRenderer): Parser =
  result.mPath = path.addr
  result.mTokenizer = initPathtokenizer()
  result.mTitleFlag = false
  result.mPathFlag = false
  result.mTitle = ""

proc title*(self: Parser): string = self.mTitle
proc parseNode(self: var Parser, node: XmlNode)
proc parseAttr(self: var Parser, name, value: string): bool

proc parseDouble(val: string): float64 =
  result = parseFloat(val)

proc parseColor(val: string): Rgba8 =
  if val[0] == '#':
    let c = uint(parseHexInt(val.substr(1)))
    result = rgb8Packed(c)
  else:
    if not colors.hasKey(val):
      raise SVGError("parseColor: Invalid color name '$1'" % [val])
    var pc = colors[val]
    result = initRgba8(pc[0], pc[1], pc[2], pc[3])

const
  numSet = {'0'..'9', '-', '+', '.', 'e', 'E'}

proc isNumeric(c: char): bool =
  result = c in numSet

proc parseTransformArgs(val: string, args: var openArray[float64], pos: var int): int =
  var
    na = 0
    maxNa = args.len

  while val[pos] != chr(0) and val[pos] != '(':
    inc pos

  if val[pos] == chr(0):
    raise SVGError("parse_transform_args: Invalid syntax")

  var stop = pos

  while val[stop] != chr(0) and val[stop] != ')':
    inc stop

  if val[stop] == chr(0):
    raise SVGError("parse_transform_args: Invalid syntax")

  while pos < stop:
    if isNumeric(val[pos]):
      if na >= maxNa:
        raise SVGError("parse_transform_args: Too many arguments")

      var token: string
      pos += parseWhile(val, token, numSet, pos)
      args[na] = parseFloat(token)
      inc na
      while pos < stop and isNumeric(val[pos]):
        inc pos
    else:
      inc pos

  result = na

proc parseMatrix(self: var Parser, val: string, pos: var int) =
  var
    args: array[6, float64]
    na = parseTransformArgs(val, args, pos)

  if na != 6:
    raise SVGError("parse_matrix: Invalid number of arguments")

  var mtx = initTransAffine(args[0], args[1], args[2], args[3], args[4], args[5])
  self.mPath[].transform().premultiply(mtx)

proc parseTranslate(self: var Parser, val: string, pos: var int) =
  var
    args: array[2, float64]
    na = parseTransformArgs(val, args, pos)
  if na == 1: args[1] = 0.0

  var mtx = transAffineTranslation(args[0], args[1])
  self.mPath[].transform().premultiply(mtx)

proc parseRotate(self: var Parser, val: string, pos: var int) =
  var
    args: array[3, float64]
    na = parseTransformArgs(val, args, pos)

  if na == 1:
    var mtx = transAffineRotation(deg2rad(args[0]))
    self.mPath[].transform().premultiply(mtx)
  elif na == 3:
    var mtx = transAffineTranslation(-args[1], -args[2])
    mtx *= transAffineRotation(deg2rad(args[0]))
    mtx *= transAffineTranslation(args[1], args[2])
    self.mPath[].transform().premultiply(mtx)
  else:
    raise SVGError("parse_rotate: Invalid number of arguments")

proc parseScale(self: var Parser, val: string, pos: var int) =
  var
    args: array[2, float64]
    na = parseTransformArgs(val, args, pos)

  if na == 1: args[1] = 0.0
  var mtx = transAffineScaling(args[0], args[1])
  self.mPath[].transform().premultiply(mtx)

proc parseSkewX(self: var Parser, val: string, pos: var int) =
  var args: array[1, float64]
  discard parseTransformArgs(val, args, pos)

  var mtx = transAffineSkewing(deg2rad(args[0]), 0.0)
  self.mPath[].transform().premultiply(mtx)

proc parseSkewY(self: var Parser, val: string, pos: var int) =
  var args: array[1, float64]
  discard parseTransformArgs(val, args, pos)

  var mtx = transAffineSkewing(0.0, deg2rad(args[0]))
  self.mPath[].transform().premultiply(mtx)

proc parseTransform(self: var Parser, val: string) =
  var pos = 0
  while pos < val.len:
    if isLowerAscii(val[pos]):
      var token: string
      pos += parseUntil(val, token, {'('}, pos)
      case token
      of "matrix":    self.parseMatrix(val, pos)
      of "translate": self.parseTranslate(val, pos)
      of "rotate":    self.parseRotate(val, pos)
      of "scale":     self.parseScale(val, pos)
      of "skewX":     self.parseSkewX(val, pos)
      of "skewY":     self.parseSkewY(val, pos)
      else: discard
      inc pos
    else:
      inc pos

proc parseNameValue(self: var Parser, val: string): bool =
  let parts = val.split(':')
  assert(parts.len == 2)
  self.parseAttr(parts[0].strip(), parts[1].strip())

proc parseStyle(self: var Parser, val: string) =
  let parts = val.split(';')
  for v in parts:
    discard self.parseNameValue(v.strip())

proc parseAttr(self: var Parser, name, value: string): bool =
  case name
  of "style":
    self.parseStyle(value)
  of "fill":
    if value == "none":
      self.mPath[].fillNone()
    else:
      self.mPath[].fill(parseColor(value))
  of "fill-opacity":
    self.mPath[].fillOpacity(parseDouble(value))
  of "stroke":
    if value == "none":
      self.mPath[].strokeNone()
    else:
      self.mPath[].stroke(parseColor(value))
  of "stroke-width":
    self.mPath[].strokeWidth(parseDouble(value))
  of "stroke-linecap":
    if value == "butt":     self.mPath[].lineCap(buttCap)
    elif value == "round":  self.mPath[].lineCap(roundCap)
    elif value == "square": self.mPath[].lineCap(squareCap)
  of "stroke-linejoin":
    if value == "miter":   self.mPath[].lineJoin(miterJoin)
    elif value == "round": self.mPath[].lineJoin(roundJoin)
    elif value == "bevel": self.mPath[].lineJoin(bevelJoin)
  of "stroke-miterlimit":
    self.mPath[].miterLimit(parsedouble(value))
  of "stroke-opacity":
    self.mPath[].strokeOpacity(parseDouble(value))
  of "transform":
    self.parseTransform(value)
  else:
    return false
  result = true

proc parseAttr(self: var Parser, attrs: XmlAttributes) =
  for key, val in pairs(attrs):
    if key == "style":
      self.parseStyle(val)
    else:
      discard self.parseAttr(key, val)

proc parseChildren(self: var Parser, node: XmlNode) =
  if node.len > 0:
    for n in node:
      self.parseNode(n)

proc parsePath(self: var Parser, attrs: XmlAttributes) =
  for key, val in pairs(attrs):
    # The <path> tag can consist of the path itself ("d=")
    # as well as of other parameters like "style=", "transform=", etc.
    # In the last case we simply rely on the function of parsing
    # attributes (see 'else' branch).
    if key == "d":
      self.mTokenizer.setPathStr(val)
      self.mPath[].parsePath(self.mTokenizer)
    else:
      # Create a temporary single pair "name-value" in order
      # to aproc multiple calls for the same attribute.
      var tmp = newStringTable([key, val], modeCaseSensitive)
      self.parseAttr(tmp)

proc parseRect(self: var Parser, attrs: XmlAttributes) =
  var
    x = 0.0
    y = 0.0
    w = 0.0
    h = 0.0

  self.mPath[].beginPath()
  for key, val in pairs(attrs):
    if not self.parseAttr(key, val):
      case key
      of "x":      x = parseDouble(val)
      of "y":      y = parseDouble(val)
      of "width":  w = parseDouble(val)
      of "height": h = parseDouble(val)
      else: discard
      # rx - to be implemented
      # ry - to be implemented

  if w != 0.0 and h != 0.0:
    if w < 0.0: raise SVGError("parse_rect: Invalid width: " & $w)
    if h < 0.0: raise SVGError("parse_rect: Invalid height: " & $h)

    self.mPath[].moveTo(x,     y)
    self.mPath[].lineTo(x + w, y)
    self.mPath[].lineTo(x + w, y + h)
    self.mPath[].lineTo(x,     y + h)
    self.mPath[].closeSubpath()

  self.mPath[].endPath()

proc parseLine(self: var Parser, attrs: XmlAttributes) =
  var
    x1 = 0.0
    y1 = 0.0
    x2 = 0.0
    y2 = 0.0

  self.mPath[].beginPath()
  for key, val in pairs(attrs):
    if not self.parseAttr(key, val):
      case key
      of "x1": x1 = parseDouble(val)
      of "y1": y1 = parseDouble(val)
      of "x2": x2 = parseDouble(val)
      of "y2": y2 = parseDouble(val)
      else: discard

  self.mPath[].moveTo(x1, y1)
  self.mPath[].lineTo(x2, y2)
  self.mPath[].endPath()

proc parsePoly(self: var Parser, attrs: XmlAttributes, closeFlag: bool) =
  var
    x = 0.0
    y = 0.0

  self.mPath[].beginPath()
  for key, val in pairs(attrs):
    if not self.parseAttr(key, val):
      if key == "points":
        self.mTokenizer.setPathStr(val)
        if not self.mTokenizer.next():
          raise SVGError("parse_poly: Too few coordinates")

        x = self.mTokenizer.lastNumber()
        if not self.mTokenizer.next():
           raise SVGError("parse_poly: Too few coordinates")

        y = self.mTokenizer.lastNumber()
        self.mPath[].moveTo(x, y)
        while self.mTokenizer.next():
            x = self.mTokenizer.lastNumber()
            if not self.mTokenizer.next():
              raise SVGError("parse_poly: Odd number of coordinates")

            y = self.mTokenizer.lastNumber()
            self.mPath[].lineTo(x, y)

  if closeFlag:
    self.mPath[].closeSubpath()
  self.mPath[].endPath()

proc startElement(self: var Parser, node: XmlNode) =
  case node.tag
  of "title", "desc":
    self.mTitleFlag = true
    self.parseChildren(node)
    self.mTitleFlag = false
  of "g":
    self.mPath[].pushAttr()
    self.parseAttr(node.attrs)
    self.parseChildren(node)
    self.mPath[].popAttr()
  of "path":
    if self.mPathFlag:
      raise SVGError("start_element: Nested path")
    self.mPath[].beginPath()
    self.parsePath(node.attrs)
    self.mPath[].endPath()
    self.mPathFlag = true
    self.parseChildren(node)
    self.mPathFlag = false
  of "rect":
    self.parseRect(node.attrs)
    self.parseChildren(node)
  of "line":
    self.parseLine(node.attrs)
    self.parseChildren(node)
  of "polyline":
    self.parsePoly(node.attrs, false)
    self.parseChildren(node)
  of "polygon":
    self.parsePoly(node.attrs, true)
    self.parseChildren(node)
  else:
    self.parseChildren(node)

proc parseNode(self: var Parser, node: XmlNode) =
  case node.kind
  of xnElement:
    self.startElement(node)
  of xnText:
    if self.mTitleFlag:
      self.mTitle = strip(node.text)
  else:
    echo "KIND: ", node.kind

proc parse*(self: var Parser, fileName: string) =
  try:
    var root = loadXml(fileName)
    self.parseNode(root)
  except:
    echo getCurrentExceptionMsg()

proc main() =
  var path = initPathRenderer()
  var parser = initParser(path)
  parser.parse("resources\\lion.svg")

main()
