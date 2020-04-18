import unittest
import nim_zstd

proc read_file(file_path: string): seq[byte] =
  var f: File
  discard open(f, file_path, fmRead)
  var size = getFileSize(f)
  var buf = newSeq[byte](size)
  discard readBytes(f, buf, 0, size)
  close(f)
  return buf

proc read_json_file(): seq[byte] =
  return read_file("tests/large-file.json")

test "original == decompress(compressed)":
  check 1 == 1
  let json_file = read_json_file()
  let compressed = compress(json_file, 3)
  check compressed.len < json_file.len
  let decompressed = decompress(compressed)
  check decompressed.len == json_file.len
  check decompressed == json_file
