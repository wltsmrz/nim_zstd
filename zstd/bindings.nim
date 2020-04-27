import std/os
import std/strutils

let cur_src_path {.compileTime.} = currentSourcePath.rsplit(DirSep, 1)[0]
let dep_dir {.compileTime.} = joinPath(cur_src_path, "deps/zstd")
let dep_lib_dir {.compileTime.} = joinPath(dep_dir, "lib")
let dep_incl_dir {.compileTime.} = joinPath(dep_dir, "lib")
let dep_lib_name {.compileTime.} = "zstd"
let dep_header_name {.compileTime.} = "zstd.h"

{.passC: "-I" & dep_incl_dir.}
{.passL: "-L" & dep_lib_dir & " -l" & dep_lib_name.}

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}

const ZSTD_CONTENTSIZE_UNKNOWN* = clonglong(-1)
const ZSTD_CONTENTSIZE_ERROR* = clonglong(-2)

proc ZSTD_versionNumber*(): cuint {.c_dep_proc.}
proc ZSTD_versionString*(): cstring {.c_dep_proc.}
proc ZSTD_isError*(a: csize_t): bool {.c_dep_proc.}
proc ZSTD_getErrorName*(a: csize_t): cstring {.c_dep_proc.}
proc ZSTD_minCLevel*(): cint {.c_dep_proc.}
proc ZSTD_maxCLevel*(): cint {.c_dep_proc.}
proc ZSTD_compressBound*(a: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_compress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t, e: cint): csize_t {.c_dep_proc.}
proc ZSTD_getDecompressedSize*(a: ptr byte, b: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_getFrameContentSize*(a: ptr byte, b: csize_t): clonglong {.c_dep_proc.}
proc ZSTD_decompress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t): csize_t {.c_dep_proc.}

type ZSTD_strategy* {.c_dep_type, c_dep_enum.} = enum
  ZSTD_fast = 1,
  ZSTD_dfast = 2,
  ZSTD_greedy = 3,
  ZSTD_lazy = 4,
  ZSTD_lazy2 = 5,
  ZSTD_btlazy2 = 6,
  ZSTD_btopt = 7,
  ZSTD_btultra = 8,
  ZSTD_btultra2 = 9

type ZSTD_CCtx* {.c_dep_type.} = object
proc ZSTD_createCCtx*(): ptr ZSTD_CCtx {.c_dep_proc.}
proc ZSTD_freeCCtx*(a: ptr ZSTD_CCtx): csize_t {.c_dep_proc.}
proc ZSTD_compressCCtx*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: cint): csize_t {.c_dep_proc.}
proc ZSTD_compress_usingDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t, h: cint): csize_t {.c_dep_proc.}

type ZSTD_DCtx* {.c_dep_type.} = object
proc ZSTD_createDCtx*(): ptr ZSTD_DCtx {.c_dep_proc.}
proc ZSTD_freeDCtx*(a: ptr ZSTD_DCtx): csize_t {.c_dep_proc.}
proc ZSTD_decompressDCtx*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_decompress_usingDict*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t): csize_t {.c_dep_proc.}

type ZSTD_CDict* {.c_dep_type.} = object
proc ZSTD_createCDict*(a: ptr byte, b: csize_t, c: cint): ptr ZSTD_CDict {.c_dep_proc.}
proc ZSTD_freeCDict*(a: ptr ZSTD_CDict): csize_t {.c_dep_proc.}
proc ZSTD_compressUsingCDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_CDict): csize_t {.c_dep_proc.}

type ZSTD_DDict* {.c_dep_type.} = object
proc ZSTD_createDDict*(a: ptr byte, b: csize_t): ptr ZSTD_DDict {.c_dep_proc.}
proc ZSTD_freeDDict*(a: ptr ZSTD_DDict): csize_t {.c_dep_proc.}
proc ZSTD_decompressUsingDDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_DDict): csize_t {.c_dep_proc.}

type ZSTD_inBuffer* {.c_dep_type.} = object
  src* {.importc.}: ptr byte
  size* {.importc.}: csize_t
  pos* {.importc.}: csize_t

type ZSTD_outBuffer* {.c_dep_type.} = object
  dst* {.importc.}: ptr byte
  size* {.importc.}: csize_t
  pos* {.importc.}: csize_t

type ZSTD_CStream* {.c_dep_type.} = object

proc ZSTD_createCStream*(): ptr ZSTD_CStream {.c_dep_proc.}
proc ZSTD_freeCStream*(a: ptr ZSTD_CStream): csize_t {.c_dep_proc.}
proc ZSTD_CStreamInSize*(): csize_t {.c_dep_proc.}
proc ZSTD_CStreamOutSize*(): csize_t {.c_dep_proc.}
proc ZSTD_initCStream*(a: ptr ZSTD_CStream, b: cint): csize_t {.c_dep_proc.}
proc ZSTD_compressStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer): csize_t {.c_dep_proc.}
proc ZSTD_flushStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer): csize_t {.c_dep_proc.}
proc ZSTD_endStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer): csize_t {.c_dep_proc.}

type ZSTD_DStream* {.c_dep_type.} = object
proc ZSTD_createDStream*(): ptr ZSTD_DStream {.c_dep_proc.}
proc ZSTD_freeDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_DStreamInSize*(): csize_t {.c_dep_proc.}
proc ZSTD_DStreamOutSize*(): csize_t {.c_dep_proc.}
proc ZSTD_initDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_decompressStream*(a: ptr ZSTD_DStream, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer): csize_t {.c_dep_proc.}

# proc ZSTD_compressStream2*(a: ptr ZSTD_CCtx, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer, d: ZSTD_EndDirective): csize_t {.importc: "ZSTD_compressStream2", header: "zstd.h".}

