import fttypes, freetype, ftsystem
include ftimport

const
  FT_VALIDATE_feat_INDEX* = 0
  FT_VALIDATE_mort_INDEX* = 1
  FT_VALIDATE_morx_INDEX* = 2
  FT_VALIDATE_bsln_INDEX* = 3
  FT_VALIDATE_just_INDEX* = 4
  FT_VALIDATE_kern_INDEX* = 5
  FT_VALIDATE_opbd_INDEX* = 6
  FT_VALIDATE_trak_INDEX* = 7
  FT_VALIDATE_prop_INDEX* = 8
  FT_VALIDATE_lcar_INDEX* = 9
  FT_VALIDATE_GX_LAST_INDEX* = FT_VALIDATE_lcar_INDEX
  FT_VALIDATE_GX_LENGTH* = (FT_VALIDATE_GX_LAST_INDEX + 1)
  FT_VALIDATE_GX_START* = 0x00004000

template FT_VALIDATE_GX_BITFIELD(tag: untyped): untyped =
  (FT_VALIDATE_GX_START shl `FT_VALIDATE tag INDEX`)

const
  FT_VALIDATE_feat* = FT_VALIDATE_GX_BITFIELD(feat)
  FT_VALIDATE_mort* = FT_VALIDATE_GX_BITFIELD(mort)
  FT_VALIDATE_morx* = FT_VALIDATE_GX_BITFIELD(morx)
  FT_VALIDATE_bsln* = FT_VALIDATE_GX_BITFIELD(bsln)
  FT_VALIDATE_just* = FT_VALIDATE_GX_BITFIELD(just)
  FT_VALIDATE_kern* = FT_VALIDATE_GX_BITFIELD(kern)
  FT_VALIDATE_opbd* = FT_VALIDATE_GX_BITFIELD(opbd)
  FT_VALIDATE_trak* = FT_VALIDATE_GX_BITFIELD(trak)
  FT_VALIDATE_prop* = FT_VALIDATE_GX_BITFIELD(prop)
  FT_VALIDATE_lcar* = FT_VALIDATE_GX_BITFIELD(lcar)
  FT_VALIDATE_GX* = (FT_VALIDATE_feat or FT_VALIDATE_mort or FT_VALIDATE_morx or
      FT_VALIDATE_bsln or FT_VALIDATE_just or FT_VALIDATE_kern or FT_VALIDATE_opbd or
      FT_VALIDATE_trak or FT_VALIDATE_prop or FT_VALIDATE_lcar)

proc FT_TrueTypeGX_Validate*(face: FT_Face; validation_flags: FT_UInt;
  tables: array[FT_VALIDATE_GX_LENGTH, FT_Bytes]; table_length: FT_UInt): FT_Error {.ftimport.}

proc FT_TrueTypeGX_Free*(face: FT_Face; table: FT_Bytes){.ftimport.}

const
  FT_VALIDATE_MS* = (FT_VALIDATE_GX_START shl 0)
  FT_VALIDATE_APPLE* = (FT_VALIDATE_GX_START shl 1)
  FT_VALIDATE_CKERN* = (FT_VALIDATE_MS or FT_VALIDATE_APPLE)

proc FT_ClassicKern_Validate*(face: FT_Face; validation_flags: FT_UInt;
  ckern_table: ptr FT_Bytes): FT_Error {.ftimport.}

proc FT_ClassicKern_Free*(face: FT_Face; table: FT_Bytes){.ftimport.}
