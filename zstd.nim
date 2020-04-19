# {.passC: "-I/usr/include".}
{.passL: "-lzstd".}

import zstd/bindings

proc bytes*(s: string): seq[byte] =
  result = newSeqOfCap[byte](s.len)
  for c in s:
    result.add(byte(c))

proc new_compress_context*(): ptr ZSTD_CCtx =
  ZSTD_createCCtx()
proc new_decompress_context*(): ptr ZSTD_DCtx =
  ZSTD_createDCtx()
proc free_context*(ctx: ptr ZSTD_CCtx): csize_t =
  ZSTD_freeCCtx(ctx)
proc free_context*(ctx: ptr ZSTD_DCtx): csize_t =
  ZSTD_freeDCtx(ctx)

proc compress*(src: openArray[byte], lvl: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress(addr(dst_buf[0]), dst_cap, src_ptr, src_cap, lvl.cint)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf[0 ..< res]

proc decompress*(src: openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompress(addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf

proc compress*(ctx: ptr ZSTD_CCtx, src: openArray[byte], lvl: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compressCCtx(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, lvl.cint)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf[0 ..< res]
  
proc decompress*(ctx: ptr ZSTD_DCtx, src: openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompressDCtx(ctx, addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf

proc compress*(ctx: ptr ZSTD_CCtx, src: openArray[byte], dict: openArray[byte], lvl: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress_usingDict(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, unsafeAddr(dict[0]), cast[csize_t](dict.len), lvl.cint)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf[0 ..< res]
  
proc decompress*(ctx: ptr ZSTD_DCtx, src: openArray[byte], dict: openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      raise newException(AssertionError, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompress_usingDict(ctx, addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap, unsafeAddr(dict[0]), cast[csize_t](dict.len))
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf
