import os
import random
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

test "Manual compress stream":
  removeFile("tests/files/gdp-manual.json")
  removeFile("tests/files/gdp-manual.json.zst")

  var original = readFile("tests/files/gdp.json")

  for half_point in 0..10:  
    block: # explicit close
      var c_out_stream = newFileStream("tests/files/gdp-manual.json.zst", fmWrite)
      var cmp_strm = new_compress_stream(c_out_stream, level=3)
      let half = (original.len * half_point) div 10
      cmp_strm.compress(original[0..<half])
      cmp_strm.compress(original[half..^1])
      cmp_strm.close()
      c_out_stream.close()
  
    var d_in_stream = newFileStream("tests/files/gdp-manual.json.zst", fmRead)
    var d_out_stream = newFileStream("tests/files/gdp-manual.json", fmWrite)
    decompress(d_in_stream, d_out_stream)
  
    var cycled = readFile("tests/files/gdp-manual.json")
    check cycled.len == original.len
    check equalmem(cycled[0].addr, original[0].addr, original.len)
  
    removeFile("tests/files/gdp-manual.json")
    removeFile("tests/files/gdp-manual.json.zst")

  block: # close via destructor
    var c_out_stream = newFileStream("tests/files/gdp-manual.json.zst", fmWrite)
    block:
      var cmp_strm = new_compress_stream(c_out_stream, level=3)
      cmp_strm.compress(original)
    c_out_stream.close()

  var d_in_stream = newFileStream("tests/files/gdp-manual.json.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/gdp-manual.json", fmWrite)
  decompress(d_in_stream, d_out_stream)

  var cycled = readFile("tests/files/gdp-manual.json")
  check cycled.len == original.len
  check equalmem(cycled[0].addr, original[0].addr, original.len)

test "Large synthetic data":
  # ~32 MiB spanning hundreds of internal 128 KiB blocks: first half random
  # (incompressible, compressed output larger than input), second half
  # repetitive (highly compressible). Seeded so failures are reproducible.
  var rng = initRand(20260705)
  var original = newString(32 * 1024 * 1024)
  let half = original.len div 2
  for i in 0..<half:
    original[i] = char(rng.rand(255))
  for i in half..<original.len:
    original[i] = char(i mod 251)

  removeFile("tests/files/synthetic.bin")
  removeFile("tests/files/synthetic.bin.zst")

  block: # via CompressStream, in uneven chunks
    var c_out_stream = newFileStream("tests/files/synthetic.bin.zst", fmWrite)
    var cmp_strm = new_compress_stream(c_out_stream, level=3)
    var pos = 0
    var chunk = 1
    while pos < original.len:
      let until = min(pos + chunk, original.len)
      cmp_strm.compress(original[pos..<until])
      pos = until
      chunk = chunk * 7 + 1
    cmp_strm.close()
    c_out_stream.close()

  var d_in_stream = newFileStream("tests/files/synthetic.bin.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/synthetic.bin", fmWrite)
  decompress(d_in_stream, d_out_stream)

  var cycled = readFile("tests/files/synthetic.bin")
  check cycled.len == original.len
  check equalmem(cycled[0].addr, original[0].addr, original.len)

  removeFile("tests/files/synthetic.bin")
  removeFile("tests/files/synthetic.bin.zst")

  block: # via the Stream proc
    var c_in_stream = newStringStream(original)
    var c_out_stream = newFileStream("tests/files/synthetic.bin.zst", fmWrite)
    compress(c_in_stream, c_out_stream, level=3)

  d_in_stream = newFileStream("tests/files/synthetic.bin.zst", fmRead)
  d_out_stream = newFileStream("tests/files/synthetic.bin", fmWrite)
  decompress(d_in_stream, d_out_stream)

  cycled = readFile("tests/files/synthetic.bin")
  check cycled.len == original.len
  check equalmem(cycled[0].addr, original[0].addr, original.len)

  removeFile("tests/files/synthetic.bin")
  removeFile("tests/files/synthetic.bin.zst")
