import std/streams
import ./common

{.pragma: c_dep_type, header: dep_header_name, bycopy.}
{.pragma: c_dep_proc, importc, header: dep_header_name, cdecl.}
{.pragma: c_dep_enum, size: sizeof(cint).}
{.pragma: c_dep_opaque, header: dep_header_name, incompleteStruct.}

proc ZSTD_getDecompressedSize*(a: ptr byte, b: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_getFrameContentSize*(a: ptr byte, b: csize_t): clonglong {.c_dep_proc.}
proc ZSTD_decompress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t): csize_t {.c_dep_proc.}

type ZSTD_DCtx* {.c_dep_opaque.} = object
proc ZSTD_createDCtx*(): ptr ZSTD_DCtx {.c_dep_proc.}
proc ZSTD_freeDCtx*(a: ptr ZSTD_DCtx): csize_t {.c_dep_proc.}
proc ZSTD_decompressDCtx*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t): csize_t {.c_dep_proc.}

type ZSTD_DDict* {.c_dep_opaque.} = object
proc ZSTD_createDDict*(a: ptr byte, b: csize_t): ptr ZSTD_DDict {.c_dep_proc.}
proc ZSTD_freeDDict*(a: ptr ZSTD_DDict): csize_t {.c_dep_proc.}
proc ZSTD_decompress_usingDict*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr byte, g: csize_t): csize_t {.c_dep_proc.}
proc ZSTD_decompressUsingDDict*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: ptr ZSTD_DDict): csize_t {.c_dep_proc.}

type ZSTD_DStream* {.c_dep_opaque.} = object
proc ZSTD_createDStream*(): ptr ZSTD_DStream {.c_dep_proc.}
proc ZSTD_freeDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_DStreamInSize*(): csize_t {.c_dep_proc.}
proc ZSTD_DStreamOutSize*(): csize_t {.c_dep_proc.}
proc ZSTD_initDStream*(a: ptr ZSTD_DStream): csize_t {.c_dep_proc.}
proc ZSTD_decompressStream*(a: ptr ZSTD_DStream, b: ptr ZSTD_outBuffer, c: ptr ZSTD_inBuffer): csize_t {.c_dep_proc.}

proc newDecompressContext*(): ptr ZSTD_DCtx =
  ZSTD_createDCtx()
proc freeContext*(ctx: ptr ZSTD_DCtx): csize_t =
  ZSTD_freeDCtx(ctx)

proc decompress*(src: sink openArray[byte]): seq[byte] =
  let src_ptr = unsafeAddr(src[0])
  let src_cap = cast[csize_t](src.len)
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
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
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
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
  let dst_cap = ZSTD_getFrameContentSize(src_ptr, src_cap)
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

type DecompressStream* = object
  dstream: ptr ZSTD_DStream
  in_stream: Stream
  src_buf: seq[byte]
  in_buf: ZSTD_inBuffer
  frame_progress: csize_t

proc close*(strm: var DecompressStream) =
  ## Releases the decompression stream. Safe to call more than once.
  if strm.dstream != nil:
    discard ZSTD_freeDStream(strm.dstream)
    strm.dstream = nil

proc `=destroy`*(strm: var DecompressStream) =
  close(strm)
  `=destroy`(strm.in_stream)
  `=destroy`(strm.src_buf)

when (NimMajor, NimMinor) >= (1, 6):
  proc `=copy`*(dest: var DecompressStream, src: DecompressStream) {.error.}
else:
  proc `=`*(dest: var DecompressStream, src: DecompressStream) {.error.}

proc newDecompressStream*(in_stream: Stream): DecompressStream =
  ## Creates a decompression stream that reads compressed data from
  ## `in_stream` on demand. Decompressed data is pulled out of it using
  ## `read`. `close` releases the stream; if it isn't called manually it is
  ## called by the destructor when the object goes out of scope.
  assert(not isNil(in_stream), "zstd decompress in stream is nil")
  result.in_stream = in_stream
  result.src_buf = newSeq[byte](ZSTD_DStreamInSize().int)
  result.dstream = ZSTD_createDStream()
  let init_res = ZSTD_initDStream(result.dstream)
  if ZSTD_isError(init_res):
    assert(false, $ZSTD_getErrorName(init_res))

proc atEnd*(strm: var DecompressStream): bool =
  ## True once all compressed input has been consumed and decompressed.
  strm.in_buf.pos >= strm.in_buf.size and strm.in_stream.atEnd()

proc read*(strm: var DecompressStream, n: int): seq[byte] =
  ## Decompresses and returns up to `n` bytes. The result is only shorter
  ## than `n` if the end of the input was reached.
  assert(strm.dstream != nil, "zstd decompress stream is closed")
  result = newSeq[byte](n)
  if n <= 0:
    return
  var cmp_output = ZSTD_outBuffer(dst: result[0].addr, size: cast[csize_t](n), pos: cast[csize_t](0))
  while cmp_output.pos < cmp_output.size:
    if strm.in_buf.pos >= strm.in_buf.size:
      if strm.in_stream.atEnd():
        break
      let bytes_read = strm.in_stream.readData(strm.src_buf[0].addr, strm.src_buf.len)
      strm.in_buf = ZSTD_inBuffer(src: strm.src_buf[0].addr, size: cast[csize_t](bytes_read), pos: cast[csize_t](0))
    let res = ZSTD_decompressStream(strm.dstream, cmp_output.addr, strm.in_buf.addr)
    if ZSTD_isError(res):
      assert(false, $ZSTD_getErrorName(res))
    strm.frame_progress = res
  if strm.atEnd():
    assert(strm.frame_progress == 0, "zstd decompress input ended mid-frame, input is truncated")
  result.setLen(cmp_output.pos.int)

proc readStr*(strm: var DecompressStream, n: int): string =
  ## Decompresses and returns up to `n` bytes as a string. The result is
  ## only shorter than `n` if the end of the input was reached.
  let data = strm.read(n)
  result = newString(data.len)
  if data.len > 0:
    copyMem(result[0].addr, data[0].unsafeAddr, data.len)

proc decompress*(in_stream: Stream, out_stream: Stream) =
  assert(not isNil(out_stream), "zstd decompress out stream is nil")
  var strm = newDecompressStream(in_stream)
  let chunk_size = ZSTD_DStreamOutSize().int
  while not strm.atEnd():
    let data = strm.read(chunk_size)
    if data.len > 0:
      out_stream.writeData(data[0].unsafeAddr, data.len)
  strm.close()
  out_stream.flush()
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
