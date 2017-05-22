import os, strutils
import freetype / [freetype, fterrdef, ftoutln]

proc main() =
  var lib: FT_Library
  var face: FT_Face
  var error = lib.init()
  var fontFile = "resources" & DirSep & "TimesNewRoman.ttf"

  if error != 0:
    echo "failed to initialize freetype"
    return

  error = lib.newFace(fontFile, 0, face)

  if error == FT_Err_Unknown_File_Format:
    echo "unknown file format"
  elif error != 0:
    echo "new face error"

  # setting the character size to 16pt for a 300×300dpi device:
  face.setCharSize(
          0,       # char_width in 1/64th of points
          16*64,   # char_height in 1/64th of points
          300,     # horizontal device resolution
          300)     # vertical device resolution

  face.setPixelSizes(
          0,       # pixel_width
          16)      # pixel_height

  var glyphIndex = face.charIndex('a'.ord)

  error = face.loadGlyph(
          glyphIndex,      # glyph index
          FT_LOAD_DEFAULT) # load flags, see below

  if error != 0:
    echo "loadGlyph error"

  error = face.glyph.render(FT_RENDER_MODE_NORMAL)

  if error != 0:
    echo "renderGlyph error"

  face.done()
  lib.done()

main()