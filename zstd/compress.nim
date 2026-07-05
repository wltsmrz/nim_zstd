import std/streams
import ./common

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}
{.pragma: c_dep_opaque, header: dep_header_name, incompleteStruct.}

proc ZSTD_minCLevel*(): cint {.c_dep_proc.}
proc ZSTD_maxCLevel*(): cint {.c_dep_proc.}
proc ZSTD_compressBound*(a: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_compress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t, e: cint): csize_t {.c_dep_proc.}

type ZSTD_CCtx* {.c_dep_opaque.} = object
proc ZSTD_createCCtx*(): ptr ZSTD_CCtx {.c_dep_proc.}
proc ZSTD_freeCCtx*(a: ptr ZSTD_CCtx): csize_t {.c_dep_proc.}
proc ZSTD_compressCCtx*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: cint): csize_t {.c_dep_proc.}
proc ZSTD_compress_usingDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t, h: cint): csize_t {.c_dep_proc.}

type ZSTD_CDict* {.c_dep_opaque.} = object
proc ZSTD_createCDict*(a: ptr byte, b: csize_t, c: cint): ptr ZSTD_CDict {.c_dep_proc.}
proc ZSTD_freeCDict*(a: ptr ZSTD_CDict): csize_t {.c_dep_proc.}
proc ZSTD_compressUsingCDict*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_CDict): csize_t {.c_dep_proc.}

type ZSTD_CStream* {.c_dep_opaque.} = object
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
  
type CompressStream* = object
  cstream: ptr ZSTD_CStream
  out_stream: Stream
  dst_buf: seq[byte]

proc close*(strm: var CompressStream) =
  ## Finishes the zstd frame, writes any lingering compressed data to the
  ## output stream and releases the compression stream. Safe to call more
  ## than once.
  if strm.cstream != nil:
    let out_size = cast[csize_t](strm.dst_buf.len)
    while true:
      var cmp_output = ZSTD_outBuffer(dst: strm.dst_buf[0].addr, size: out_size, pos: cast[csize_t](0))
      let remaining = ZSTD_endStream(strm.cstream, cmp_output.addr)
      if ZSTD_isError(remaining):
        assert(false, $ZSTD_getErrorName(remaining))
      strm.out_stream.writeData(strm.dst_buf[0].addr, cmp_output.pos.int)
      if remaining == 0:
        break
    strm.out_stream.flush()
    discard ZSTD_freeCStream(strm.cstream)
    strm.cstream = nil

proc `=destroy`*(strm: var CompressStream) =
  if strm.cstream != nil:
    try:
      close(strm)
    except Exception:
      discard ZSTD_freeCStream(strm.cstream)
      strm.cstream = nil
  `=destroy`(strm.out_stream)
  `=destroy`(strm.dst_buf)

when (NimMajor, NimMinor) >= (1, 6):
  proc `=copy`*(dest: var CompressStream, src: CompressStream) {.error.}
else:
  proc `=`*(dest: var CompressStream, src: CompressStream) {.error.}

proc new_compress_stream*(out_stream: Stream, level: int = 3): CompressStream =
  ## Creates a compression stream that compressed data can be added to
  ## manually using `compress`. Compressed output is written to `out_stream`.
  ## `close` finishes the frame; if it isn't called manually it is called by
  ## the destructor when the object goes out of scope.
  assert(not isNil(out_stream), "zstd compress out stream is nil")
  result.out_stream = out_stream
  result.dst_buf = newSeq[byte](ZSTD_CStreamOutSize().int)
  result.cstream = ZSTD_createCStream()
  let init_res = ZSTD_initCStream(result.cstream, level.cint)
  if ZSTD_isError(init_res):
    assert(false, $ZSTD_getErrorName(init_res))

proc compress*(strm: var CompressStream, src: openArray[byte]) =
  ## Adds `src` as input to the compression stream, writing compressed data
  ## to the output stream as it becomes available.
  assert(strm.cstream != nil, "zstd compress stream is closed")
  if src.len == 0:
    return
  let out_size = cast[csize_t](strm.dst_buf.len)
  var cmp_input = ZSTD_inBuffer(src: unsafeAddr(src[0]), size: cast[csize_t](src.len), pos: cast[csize_t](0))
  while cmp_input.pos < cmp_input.size:
    var cmp_output = ZSTD_outBuffer(dst: strm.dst_buf[0].addr, size: out_size, pos: cast[csize_t](0))
    let res = ZSTD_compressStream(strm.cstream, cmp_output.addr, cmp_input.addr)
    if ZSTD_isError(res):
      assert(false, $ZSTD_getErrorName(res))
    strm.out_stream.writeData(strm.dst_buf[0].addr, cmp_output.pos.int)

proc compress*(strm: var CompressStream, src: string) {.inline.} =
  compress(strm, toOpenArrayByte(src, 0, len(src)-1))

proc compress*(in_stream: Stream, out_stream: Stream, level: int = 3) =
  assert(not isNil(in_stream), "zstd compress in stream is nil")
  var strm = new_compress_stream(out_stream, level)
  var src_buf = newSeq[byte](ZSTD_CStreamInSize().int)
  while not in_stream.atEnd():
    let bytes_read = in_stream.readData(src_buf[0].addr, src_buf.len)
    strm.compress(src_buf.toOpenArray(0, bytes_read - 1))
  strm.close()
  in_stream.close()
  out_stream.close()

proc compress*(src: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(toOpenArrayByte(src, 0, len(src)-1), level)

proc compress*(ctx: ptr ZSTD_CCtx, src: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(ctx, toOpenArrayByte(src, 0, len(src)-1), level)

proc compress*(ctx: ptr ZSTD_CCtx, src: sink string, dict: sink string, level: int = 3): seq[byte] {.inline.} =
  compress(ctx, toOpenArrayByte(src, 0, len(src)-1), toOpenArrayByte(dict, 0, len(dict)-1), level)
