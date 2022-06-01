import os
import streams
import unittest
import ../zstd/compress
import ../zstd/decompress

test "Simple":
  var source = readFile("tests/files/nixon.bmp")
  var compressed = compress(source, level=3)
  var decompressed = decompress(compressed)
  var compressed_s = compress(readFile("tests/files/nixon.bmp"), level=3)
  var decompressed_s = decompress(readFile("tests/files/nixon.zst"))
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "Simple - default compression level":
  var source = readFile("tests/files/nixon.bmp")
  var compressed = compress(source)
  var decompressed = decompress(compressed)
  var compressed_s = compress(readFile("tests/files/nixon.bmp"))
  var decompressed_s = decompress(readFile("tests/files/nixon.zst"))
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "With context":
  var source = readFile("tests/files/nixon.bmp")
  var cctx = new_compress_context()

  var compressed = compress(cctx, source, level=3)
  var compressed_s = compress(cctx, readFile("tests/files/nixon.bmp"), level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  var decompressed_s = decompress(dctx, readFile("tests/files/nixon.zst"))
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "With dict":
  var source = readFile("tests/files/nixon.bmp")
  var dict = readFile("tests/files/nixon.dict")

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, level=3)
  var compressed_s = compress(cctx, readFile("tests/files/nixon.bmp"), readFile("tests/files/nixon.dict"), level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  var decompressed_s = decompress(dctx, readFile("tests/files/nixon.zst"), readFile("tests/files/nixon.dict"))
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "Stream":
  removeFile("tests/files/nixon-copy.bmp")
  removeFile("tests/files/nixon-copy.bmp.zst")

  var c_in_stream = newFileStream("tests/files/nixon.bmp", fmRead)
  var c_out_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmWrite)
  compress(c_in_stream, c_out_stream, level=3)

  var d_in_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/nixon-copy.bmp", fmWrite)
  decompress(d_in_stream, d_out_stream)

  var original = readFile("tests/files/nixon.bmp")
  var cycled = readFile("tests/files/nixon-copy.bmp")

  check equalmem(cycled[0].addr, original[0].addr, original.len)

