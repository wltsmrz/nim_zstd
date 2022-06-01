import std/streams
import ./common

when not defined(useExternalZstd):
  {.passC: "-I" & joinPathHost(dep_lib_dir, "compress").}
  {.compile: joinPathHost(dep_lib_dir, "compress/fse_compress.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/hist.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/huf_compress.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_compress.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_compress_literals.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_compress_sequences.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_compress_superblock.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_double_fast.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_fast.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_lazy.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_ldm.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstdmt_compress.c").}
  {.compile: joinPathHost(dep_lib_dir, "compress/zstd_opt.c").}

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}

proc ZSTD_minCLevel*(): cint {.c_dep_proc.}
proc ZSTD_maxCLevel*(): cint {.c_dep_proc.}
proc ZSTD_compressBound*(a: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_compress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t, e: cint): csize_t {.c_dep_proc.}

type ZSTD_CCtx* {.c_dep_type.} = object
proc ZSTD_createCCtx*(): ptr ZSTD_CCtx {.c_dep_proc.}
proc ZSTD_freeCCtx*(a: ptr ZSTD_CCtx): csize_t {.c_dep_proc.}
proc ZSTD_compressCCtx*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: cint): csize_t {.c_dep_proc.}
proc ZSTD_compress_usingDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t, h: cint): csize_t {.c_dep_proc.}

type ZSTD_CDict* {.c_dep_type.} = object
proc ZSTD_createCDict*(a: ptr byte, b: csize_t, c: cint): ptr ZSTD_CDict {.c_dep_proc.}
proc ZSTD_freeCDict*(a: ptr ZSTD_CDict): csize_t {.c_dep_proc.}
proc ZSTD_compressUsingCDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_CDict): csize_t {.c_dep_proc.}

type ZSTD_CStream* {.c_dep_type.} = object
proc ZSTD_createCStream*(): ptr ZSTD_CStream {.c_dep_proc.}
proc ZSTD_freeCStream*(a: ptr ZSTD_CStream): csize_t {.c_dep_proc.}
proc ZSTD_CStreamInSize*(): csize_t {.c_dep_proc.}
proc ZSTD_CStreamOutSize*(): csize_t {.c_dep_proc.}
proc ZSTD_initCStream*(a: ptr ZSTD_CStream, b: cint): csize_t {.c_dep_proc.}
proc ZSTD_compressStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer): csize_t {.c_dep_proc.}
proc ZSTD_flushStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer): csize_t {.c_dep_proc.}
proc ZSTD_endStream*(a: ptr ZSTD_CStream, b: ptr ZSTD_outBuffer): csize_t {.c_dep_proc.}
# proc ZSTD_compressStream2*(a: ptr ZSTD_CCtx, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer, d: ZSTD_EndDirective): csize_t {.importc: "ZSTD_compressStream2", header: "zstd.h".}

proc new_compress_context*(): ptr ZSTD_CCtx =
  ZSTD_createCCtx()
proc free_context*(ctx: ptr ZSTD_CCtx): csize_t =
  ZSTD_freeCCtx(ctx)

proc new_compress_stream*(): ptr ZSTD_CStream =
  ZSTD_createCStream()
proc free_compress_stream*(strm: ptr ZSTD_CStream): csize_t =
  ZSTD_freeCStream(strm)

proc compress*(src: sink openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress(addr(dst_buf[0]), dst_cap, src_ptr, src_cap, level.cint)
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  dst_buf.setLen(res)
  return dst_buf

proc compress*(ctx: ptr ZSTD_CCtx, src: sink openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compressCCtx(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, level.cint)
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  dst_buf.setLen(res)
  return dst_buf

proc compress*(ctx: ptr ZSTD_CCtx, src: sink openArray[byte], dict: openArray[byte], level: int = 3): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_compressBound(src_cap)
  var dst_buf = newSeq[byte](dst_cap.uint)
  let res: uint = ZSTD_compress_usingDict(ctx, addr(dst_buf[0]), dst_cap, src_ptr, src_cap, unsafeAddr(dict[0]), cast[csize_t](dict.len), level.cint)
  if ZSTD_isError(res):
    assert(false, $ZSTD_getErrorName(res))
  dst_buf.setLen(res)
  return dst_buf
  
proc compress*(in_stream: Stream, out_stream: Stream, level: int = 3) =
  assert(not isNil(in_stream), "zstd compress in stream is nil")
  assert(not isNil(out_stream), "zstd compress out stream is nil")
  var cstream = ZSTD_createCStream()
  var init_res = ZSTD_initCStream(cstream, level.cint)
  if (ZSTD_isError(init_res)):
    assert(false, $ZSTD_getErrorName(init_res))
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
        assert(false, $ZSTD_getErrorName(to_read))
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

proc compress*(src: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(toOpenArrayByte(src, 0, len(src)-1), level)

proc compress*(ctx: ptr ZSTD_CCtx, src: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(ctx, toOpenArrayByte(src, 0, len(src)-1), level)

proc compress*(ctx: ptr ZSTD_CCtx, src: sink string, dict: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(ctx, toOpenArrayByte(src, 0, len(src)-1), toOpenArrayByte(dict, 0, len(dict)-1), level)

