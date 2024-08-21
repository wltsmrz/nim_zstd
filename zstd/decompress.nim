import std/streams
import ./common

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_proc_noheader, importc, cdecl.} # skips the need for ZSTD_STATIC_LINKING_ONLY
{.pragma: c_dep_enum, size: sizeof(cint).}

proc ZSTD_getDecompressedSize*(a: ptr byte, b: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_findDecompressedSize*(a: ptr byte, b: csize_t): clonglong {.c_dep_proc_noheader.}
proc ZSTD_getFrameContentSize*(a: ptr byte, b: csize_t): clonglong {.c_dep_proc.}
proc ZSTD_decompress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t): csize_t {.c_dep_proc.}

type ZSTD_DCtx* {.c_dep_type.} = object
proc ZSTD_createDCtx*(): ptr ZSTD_DCtx {.c_dep_proc.}
proc ZSTD_freeDCtx*(a: ptr ZSTD_DCtx): csize_t {.c_dep_proc.}
proc ZSTD_decompressDCtx*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t): csize_t {.c_dep_proc.}

type ZSTD_DDict* {.c_dep_type.} = object
proc ZSTD_createDDict*(a: ptr byte, b: csize_t): ptr ZSTD_DDict {.c_dep_proc.}
proc ZSTD_freeDDict*(a: ptr ZSTD_DDict): csize_t {.c_dep_proc.}
proc ZSTD_decompress_usingDict*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_decompressUsingDDict*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_DDict): csize_t {.c_dep_proc.}

type ZSTD_DStream* {.c_dep_type.} = object
proc ZSTD_createDStream*(): ptr ZSTD_DStream {.c_dep_proc.}
proc ZSTD_freeDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_DStreamInSize*(): csize_t {.c_dep_proc.}
proc ZSTD_DStreamOutSize*(): csize_t {.c_dep_proc.}
proc ZSTD_initDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_decompressStream*(a: ptr ZSTD_DStream, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer): csize_t {.c_dep_proc.}

proc new_decompress_context*(): ptr ZSTD_DCtx =
  ZSTD_createDCtx()
proc free_context*(ctx: ptr ZSTD_DCtx): csize_t =
  ZSTD_freeDCtx(ctx)

proc new_decompress_stream*(): ptr ZSTD_DStream =
  ZSTD_createDStream()
proc free_decompress_stream*(strm: ptr ZSTD_DStream): csize_t =
  ZSTD_freeDStream(strm)

proc decompress*(src: sink openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_findDecompressedSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      assert(false, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      assert(false, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompress(addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap)
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  return dst_buf

proc decompress*(ctx: ptr ZSTD_DCtx, src: sink openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_findDecompressedSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      assert(false, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      assert(false, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompressDCtx(ctx, addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap)
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  return dst_buf

proc decompress*(ctx: ptr ZSTD_DCtx, src: openArray[byte], dict: openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_findDecompressedSize(src_ptr, src_cap)
  case dst_cap:
    of ZSTD_CONTENTSIZE_UNKNOWN:
      assert(false, "ZSTD_CONTENTSIZE_UNKNOWN")
    of ZSTD_CONTENTSIZE_ERROR:
      assert(false, "ZSTD_CONTENTSIZE_ERROR")
    else: discard
  var dst_buf = newSeq[byte](dst_cap)
  let res = ZSTD_decompress_usingDict(ctx, addr(dst_buf[0]), cast[csize_t](dst_cap), src_ptr, src_cap, unsafeAddr(dict[0]), cast[csize_t](dict.len))
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  return dst_buf

proc decompress*(in_stream: Stream, out_stream: Stream) =
  assert(not isNil(in_stream), "zstd decompress in stream is nil")
  assert(not isNil(out_stream), "zstd decompress out stream is nil")

  var dstream = ZSTD_createDStream()
  var init_res = ZSTD_initDStream(dstream)
  if ZSTD_isError(init_res):
    assert(false, $ZSTD_getErrorName(init_res))

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
        assert(false, $ZSTD_getErrorName(to_read))
      out_stream.writeData(dst_buf[0].addr, cmp_output.pos.int)

  out_stream.flush()
  discard ZSTD_freeDStream(dstream)
  in_stream.close()
  out_stream.close()

proc decompress*(src: sink string): seq[byte] {.inline.} =
  decompress(toOpenArrayByte(src, 0, len(src)-1))

proc decompress*(ctx: ptr ZSTD_DCtx, src: sink string): seq[byte] {.inline.} =
  decompress(ctx, toOpenArrayByte(src, 0, len(src)-1))

proc decompress*(ctx: ptr ZSTD_DCtx, src: sink seq[byte], dict: sink string): seq[byte] {.inline.} =
  decompress(ctx, src, toOpenArrayByte(dict, 0, len(dict)-1))

proc decompress*(ctx: ptr ZSTD_DCtx, src: sink string, dict: sink string): seq[byte] {.inline.} =
  decompress(ctx, toOpenArrayByte(src, 0, len(src)-1), toOpenArrayByte(dict, 0, len(dict)-1))
  
