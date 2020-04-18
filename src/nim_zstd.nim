# {.passC: "-I/usr/include".}
{.passL: "-lzstd".}

import bindings/zstd

proc compress*(src: openArray[byte], lvl: int): seq[byte] =
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
  let dst_cap = ZSTD_getDecompressedSize(src_ptr, src_cap)
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompress(addr(dst_buf[0]), dst_cap, src_ptr, src_cap)
  if ZSTD_isError(res):
    raise newException(AssertionError, $ZSTD_getErrorName(res))
  return dst_buf

