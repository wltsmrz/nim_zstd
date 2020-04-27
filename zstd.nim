import std/os
import std/strutils
import std/streams

let cur_src_path {.compileTime.} = currentSourcePath.rsplit(DirSep, 1)[0]
let dep_dir {.compileTime.} = joinPath(cur_src_path, "zstd/deps/zstd")
let dep_lib_dir {.compileTime.} = joinPath(dep_dir, "lib")
let dep_incl_dir {.compileTime.} = joinPath(dep_dir, "lib")
let dep_lib_name {.compileTime.} = "zstd"
let dep_header_name {.compileTime.} = "zstd.h"

{.passC: "-I" & dep_incl_dir.}
{.passL: "-L" & dep_lib_dir & " -l" & dep_lib_name.}

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}

include zstd/bindings

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

proc new_compress_stream*(): ptr ZSTD_CStream =
  ZSTD_createCStream()
proc new_decompress_stream*(): ptr ZSTD_DStream =
  ZSTD_createDStream()
proc free_compress_stream*(strm: ptr ZSTD_CStream): csize_t =
  ZSTD_freeCStream(strm)
proc free_decompress_stream*(strm: ptr ZSTD_DStream): csize_t =
  ZSTD_freeDStream(strm)

proc compress*(src: openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress(addr(dst_buf[0]), dst_cap, src_ptr, src_cap, level.cint)
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

proc compress*(ctx: ptr ZSTD_CCtx, src: openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compressCCtx(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, level.cint)
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

proc compress*(ctx: ptr ZSTD_CCtx, src: openArray[byte], dict: openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress_usingDict(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, unsafeAddr(dict[0]), cast[csize_t](dict.len), level.cint)
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

proc compress*(in_stream: Stream, out_stream: Stream, level: int = 3) =
  if isNil(in_stream):
    raise newException(AssertionError, "zstd compress in stream is nil")
  if isNil(out_stream):
    raise newException(AssertionError, "zstd compress out stream is nil")

  var cstream = ZSTD_createCStream()
  var init_res = ZSTD_initCStream(cstream, level.cint)
  if ZSTD_isError(init_res):
    raise newException(AssertionError, $ZSTD_getErrorName(init_res))
  let in_size = ZSTD_CStreamInSize()
  let out_size = ZSTD_CStreamOutSize()
  var src_buf = newSeq[byte](in_size.int)
  var dst_buf = newSeq[byte](out_size.int)
  var to_read = in_size

  while not in_stream.atEnd():
    var bytes_read = in_stream.readData(src_buf[0].addr, to_read.int)
    var cmp_input = ZSTD_inBuffer(src: src_buf[0].addr, size: cast[csize_t](bytes_read), pos: cast[csize_t](0))
    while cmp_input.pos < cmp_input.size:
      var cmp_output = ZSTD_outBuffer(dst: dst_buf[0].addr, size: out_size, pos: cast[csize_t](0))
      to_read = ZSTD_compressStream(cstream, cmp_output.addr, cmp_input.addr)
      if ZSTD_isError(to_read):
        raise newException(AssertionError, $ZSTD_getErrorName(to_read))
      to_read = min(in_size, to_read)
      out_stream.writeData(dst_buf[0].addr, cmp_output.pos.int)

  var cmp_output = ZSTD_outBuffer(dst: dst_buf[0].addr, size: out_size, pos: cast[csize_t](0))
  # according to docs,  endStream might have non-zero return value and expect to be
  # called multiple times for lingering data, but haven't seen other libraries
  # account for this and haven't broken a test yet
  discard ZSTD_endStream(cstream, cmp_output.addr)
  out_stream.writeData(dst_buf[0].addr, cmp_output.pos.int)
  out_stream.flush()
  discard ZSTD_freeCStream(cstream)
  in_stream.close()
  out_stream.close()

proc decompress*(in_stream: Stream, out_stream: Stream) =
  if isNil(in_stream):
    raise newException(AssertionError, "zstd compress in stream is nil")
  if isNil(out_stream):
    raise newException(AssertionError, "zstd compress out stream is nil")

  var dstream = ZSTD_createDStream()
  var init_res = ZSTD_initDStream(dstream)
  if ZSTD_isError(init_res):
    raise newException(AssertionError, $ZSTD_getErrorName(init_res))

  let in_size = ZSTD_DStreamInSize()
  let out_size = ZSTD_DStreamOutSize()
  var src_buf = newSeq[byte](in_size.int)
  var dst_buf = newSeq[byte](out_size.int)
  var to_read = init_res
  while not in_stream.atEnd():
    var bytes_read = in_stream.readData(src_buf[0].addr, to_read.int)
    var cmp_input = ZSTD_inBuffer(src: src_buf[0].addr, size: cast[csize_t](bytes_read), pos: cast[csize_t](0))
    while cmp_input.pos < cmp_input.size:
      var cmp_output = ZSTD_outBuffer(dst: dst_buf[0].addr, size: out_size, pos: cast[csize_t](0))
      to_read = ZSTD_decompressStream(dstream, cmp_output.addr, cmp_input.addr)
      if ZSTD_isError(to_read):
        raise newException(AssertionError, $ZSTD_getErrorName(to_read))
      out_stream.writeData(dst_buf[0].addr, cmp_output.pos.int)

  out_stream.flush()
  discard ZSTD_freeDStream(dstream)
  in_stream.close()
  out_stream.close()

