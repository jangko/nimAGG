import strutils

proc SVGError*(msg: string): ref Exception =
  new(result)
  result.msg = msg

type
  PathTokenizer* = object
    mSeparatorsMask: array[32, char]
    mCommandsMask: array[32, char]
    mNumericMask: array[32, char]
    mPath: string
    mLastNumber: float64
    mLastCommand: char
    mPos: int

const
  s_commands   = "+-MmZzLlHhVvCcSsQqTtAaFfPp"
  s_numeric    = ".Ee0123456789"
  s_separators = " ,\t\n\r"

proc contains(mask: openArray[char], c: int): bool =
  result = (mask[(c shr 3) and 31].int and (1 shl (c and 7))) != 0

proc isCommand*(self: PathTokenizer, c: int): bool =
  contains(self.mCommandsMask, c)

proc isNumeric*(self: PathTokenizer, c: int): bool =
  contains(self.mNumericMask, c)

proc isSeparator*(self: PathTokenizer, c: int): bool =
  contains(self.mSeparatorsMask, c)

proc lastCommand*(self: PathTokenizer): char =
  self.mLastCommand

proc lastNumber*(self: PathTokenizer): float64 =
  self.mLastNumber

proc initCharMask(mask: var openArray[char], charSet: openArray[char]) =
  zeroMem(mask[0].addr, mask.len)

  for x in charSet:
    var c = int(x) and 0xFF
    mask[c shr 3] = chr(mask[c shr 3].int or (1 shl (c and 7)))

proc initPathTokenizer*(): PathTokenizer =
  result.mPos = 0
  result.mPath = ""
  result.mLastCommand = chr(0)
  result.mLastNumber = 0.0
  initCharMask(result.mCommandsMask,   s_commands)
  initCharMask(result.mNumericMask,    s_numeric)
  initCharMask(result.mSeparatorsMask, s_separators)

proc setPathStr*(self: var PathTokenizer, str: string) =
  self.mPath = str
  self.mLastCommand = chr(0)
  self.mLastNumber = 0.0
  self.mPos = 0

proc parseNumber(self: var PathTokenizer): bool =
  var buf = ""

  # Copy all sign characters
  while self.mPath[self.mPos] in {'-', '+'}:
    buf.add self.mPath[self.mPos]
    inc self.mPos

  # Copy all numeric characters
  while self.isNumeric(self.mPath[self.mPos].ord):
    buf.add self.mPath[self.mPos]
    inc self.mPos

  self.mLastNumber = parseFloat(buf)
  return true

proc next*(self: var PathTokenizer): bool =
  if self.mPath.len == 0: return false

  let len = self.mPath.len
  # Skip all white spaces and other garbage
  while self.mPos != len and
    not self.isCommand(self.mPath[self.mPos].ord) and
    not self.isNumeric(self.mPath[self.mPos].ord):

    if not self.isSeparator(self.mPath[self.mPos].ord):
      raise SVGError("path_tokenizer::next : Invalid Character " & $self.mPath[self.mPos])
    inc self.mPos

  if self.mPos == self.mPath.len or self.mPath[self.mPos] == chr(0):
    return false

  if self.isCommand(self.mPath[self.mPos].ord):
    # Check if the command is a numeric sign character
    if self.mPath[self.mPos] in {'-', '+'}:
      return self.parseNumber()

    self.mLastCommand = self.mPath[self.mPos]
    inc self.mPos

    while self.mPos != len and self.isSeparator(self.mPath[self.mPos].ord):
      inc self.mPos

    if self.mPos == self.mPath.len or self.mPath[self.mPos] == chr(0):
      return true

  self.parseNumber()

proc next*(self: var PathTokenizer, cmd: char): float64 =
  if not self.next():
    raise SVGError("parse_path: Unexpected end of path")

  if self.lastCommand() != cmd:
    raise SVGError("parse_path: Command $1: bad or missing parameters" % [$cmd])

  self.lastNumber()
