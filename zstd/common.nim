import std/os
import std/strutils

const ZSTD_CONTENTSIZE_UNKNOWN* = clonglong(-1)
const ZSTD_CONTENTSIZE_ERROR* = clonglong(-2)

let cur_src_path* {.compileTime.} = currentSourcePath.rsplit(DirSep, 1)[0]
let dep_dir* {.compileTime.} = joinPath(cur_src_path, "deps/zstd")
let dep_lib_dir* {.compileTime.} = joinPath(dep_dir, "lib")

{.passC: "-I" & dep_lib_dir.}
{.passC: "-I" & joinPath(dep_lib_dir, "common").}

# let dep_lib_name* {.compileTime.} = "zstd"
# {.passL: "-L" & dep_lib_dir & " -l" & dep_lib_name.}

{.compile: joinPath(dep_lib_dir, "common/debug.c").}
{.compile: joinPath(dep_lib_dir, "common/entropy_common.c").}
{.compile: joinPath(dep_lib_dir, "common/error_private.c").}
{.compile: joinPath(dep_lib_dir, "common/fse_decompress.c").}
{.compile: joinPath(dep_lib_dir, "common/pool.c").}
{.compile: joinPath(dep_lib_dir, "common/threading.c").}
{.compile: joinPath(dep_lib_dir, "common/xxhash.c").}
{.compile: joinPath(dep_lib_dir, "common/zstd_common.c").}

let dep_header_name* {.compileTime.} = "zstd.h"
{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}

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

type ZSTD_inBuffer* {.c_dep_type.} = object
  src* {.importc.}: ptr byte
  size* {.importc.}: csize_t
  pos* {.importc.}: csize_t

type ZSTD_outBuffer* {.c_dep_type.} = object
  dst* {.importc.}: ptr byte
  size* {.importc.}: csize_t
  pos* {.importc.}: csize_t

proc ZSTD_versionNumber*(): cuint {.c_dep_proc.}
proc ZSTD_versionString*(): cstring {.c_dep_proc.}
proc ZSTD_isError*(a: csize_t): bool {.c_dep_proc.}
proc ZSTD_getErrorName*(a: csize_t): cstring {.c_dep_proc.}

proc bytes*(s: string): seq[byte] =
  result = newSeqOfCap[byte](s.len)
  for c in s:
    result.add(byte(c))
