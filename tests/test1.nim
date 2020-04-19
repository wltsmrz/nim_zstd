import unittest
import ../zstd

# proc read_file(file_path: string): seq[byte] =
#   var f: File
#   discard open(f, file_path, fmRead)
#   var size = getFileSize(f)
#   var buf = newSeq[byte](size)
#   discard readBytes(f, buf, 0, size)
#   close(f)
#   return buf

test "Simple: original == decompress(compress(original))":
  var source = bytes(readFile("tests/test-file.json"))
  var compressed = compress(source, 3)
  var decompressed = decompress(compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)

test "Simple: original == decompress(compress(original)) - default compression level":
  var source = bytes(readFile("tests/test-file.json"))
  var compressed = compress(source)
  var decompressed = decompress(compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)

test "Context: original == decompress(ctx, compress(ctx, original))":
  var source = bytes(readFile("tests/test-file.json"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, lvl=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  discard free_context(dctx)


test "Dict: original == decompress(ctx, compress(ctx, original, dict), dict)":
  var source = bytes(readFile("tests/test-file.json"))
  var dict = bytes(readFile("tests/test-file.dict"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, lvl=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  discard free_context(dctx)

