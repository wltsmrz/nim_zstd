import std/os
from os {.all.} import parentDirPos # for parentDirHost

proc joinPathHost*(head, tail: string): string {.noSideEffect.} =
  when not defined(mingw):
    joinPath(head, tail)
  else:
    head & '/' & tail

proc joinPathHost*(parts: varargs[string]): string {.noSideEffect.} =
  when not defined(mingw):
    joinPath(parts)
  else:
    if parts.len == 1: return parts[0]
    else:
      result = parts[0]
      for part in parts:
        result.add '/' & part

proc parentDirHost*(path: string): string =
  var sepPos = parentDirPos(path)
  if sepPos >= 0:
    result = substr(path, 0, sepPos)
    normalizePathEnd(result)
  elif result == ".." or result == "." or result.len == 0 or result[^1] in {DirSep, AltSep}:
    result = ""
  else:
    result = "."

const cur_src_path = currentSourcePath.parentDirHost
const zstd_path {.strdefine.}: string = joinPathHost(cur_src_path, "deps/zstd")
const dep_lib_dir* = joinPathHost(zstd_path, "lib")

when defined(useExternalZstd):
  {.passL: "-lzstd".}
else:
  {.passC: "-I" & dep_lib_dir.}
  {.passC: "-I" & joinPathHost(dep_lib_dir, "common").}
  {.compile: joinPathHost(dep_lib_dir, "common/debug.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/entropy_common.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/error_private.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/fse_decompress.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/pool.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/threading.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/xxhash.c").}
  {.compile: joinPathHost(dep_lib_dir, "common/zstd_common.c").}

let dep_header_name* {.compileTime.} = "zstd.h"
{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}

const ZSTD_CONTENTSIZE_UNKNOWN* = clonglong(-1)
const ZSTD_CONTENTSIZE_ERROR* = clonglong(-2)

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
