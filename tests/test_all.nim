import os
import streams
import unittest
import ../zstd

test "Simple":
  var source = bytes(readFile("tests/files/nixon.bmp"))
  var compressed = compress(source, 3)
  var decompressed = decompress(compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)

test "Simple - default compression level":
  var source = bytes(readFile("tests/files/nixon.bmp"))
  var compressed = compress(source)
  var decompressed = decompress(compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)

test "With context":
  var source = bytes(readFile("tests/files/nixon.bmp"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  discard free_context(dctx)

test "With dict":
  var source = bytes(readFile("tests/files/nixon.bmp"))
  var dict = bytes(readFile("tests/files/nixon.dict"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  discard free_context(dctx)

test "Stream":
  removeFile("tests/files/nixon-copy.bmp")
  removeFile("tests/files/nixon-copy.bmp.zst")

  var c_in_stream = newFileStream("tests/files/nixon.bmp", fmRead)
  var c_out_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmWrite)
  compress(c_in_stream, c_out_stream, level=3)

  var d_in_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/nixon-copy.bmp", fmWrite)
  decompress(d_in_stream, d_out_stream)

  var original = bytes(readFile("tests/files/nixon.bmp"))
  var cycled = bytes(readFile("tests/files/nixon-copy.bmp"))

  check equalmem(cycled[0].addr, original[0].addr, original.len)
