import os
import streams
import unittest
import ../zstd/compress
import ../zstd/decompress

test "Simple":
  var source = readFile("tests/files/gdp.json")
  var compressed = compress(source, level=3)
  var decompressed = decompress(compressed)
  var compressed_s = compress(readFile("tests/files/gdp.json"), level=3)
  var decompressed_s = decompress(readFile("tests/files/gdp.zst"))
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "Simple - default compression level":
  var source = readFile("tests/files/gdp.json")
  var compressed = compress(source)
  var decompressed = decompress(compressed)
  var compressed_s = compress(readFile("tests/files/gdp.json"))
  var decompressed_s = decompress(readFile("tests/files/gdp.zst"))
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "With context":
  var source = readFile("tests/files/gdp.json")
  var cctx = new_compress_context()

  var compressed = compress(cctx, source, level=3)
  var compressed_s = compress(cctx, readFile("tests/files/gdp.json"), level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  var decompressed_s = decompress(dctx, readFile("tests/files/gdp.zst"))
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "With dict":
  var source = readFile("tests/files/gdp.json")
  var dict = readFile("tests/files/gdp.dict")

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, level=3)
  var compressed_s = compress(cctx, readFile("tests/files/gdp.json"), readFile("tests/files/gdp.dict"), level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  var decompressed_s = decompress(dctx, readFile("tests/files/gdp.zst"), readFile("tests/files/gdp.dict"))
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
  check equalmem(compressed_s[0].addr, compressed[0].addr, compressed.len)
  check equalmem(decompressed_s[0].addr, decompressed[0].addr, decompressed.len)

test "Stream":
  removeFile("tests/files/gdp-copy.json")
  removeFile("tests/files/gdp-copy.json.zst")

  var c_in_stream = newFileStream("tests/files/gdp.json", fmRead)
  var c_out_stream = newFileStream("tests/files/gdp-copy.json.zst", fmWrite)
  compress(c_in_stream, c_out_stream, level=3)

  var d_in_stream = newFileStream("tests/files/gdp-copy.json.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/gdp-copy.json", fmWrite)
  decompress(d_in_stream, d_out_stream)

  var original = readFile("tests/files/gdp.json")
  var cycled = readFile("tests/files/gdp-copy.json")

  check equalmem(cycled[0].addr, original[0].addr, original.len)

