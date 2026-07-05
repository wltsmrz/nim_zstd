# zstd

Nim bindings for [zstd](https://github.com/facebook/zstd)

```bash
$ nimble install zstd
```

## Simple API

```nim
  import zstd/compress
  import zstd/decompress

  var source = readFile("tests/files/gdp.json")
  var compressed = compress(source, level=3)
  var decompressed = decompress(compressed)
  assert equalmem(decompressed[0].addr, source[0].addr, source.len)
```

## Advanced API

Uses a ZSTD context for setting options, using for multiple calls, etc.

>   When compressing many times,
>   it is recommended to allocate a context just once,
>   and re-use it for each successive compression operation.
>   This will make workload friendlier for system's memory.
>   Note : re-using context is just a speed / resource optimization.
>          It doesn't change the compression ratio, which remains identical.
>   Note 2 : In multi-threaded environments,
>          use one different context per thread for parallel execution.


```nim
  import zstd/compress
  import zstd/decompress

  var source = readFile("tests/files/gdp.json")

  var cctx = newCompressContext()
  var compressed = compress(cctx, source, level=3)
  discard freeContext(cctx)

  var dctx = newDecompressContext()
  var decompressed = decompress(dctx, compressed)
  discard freeContext(dctx)

  assert equalmem(decompressed[0].addr, source[0].addr, source.len)
```

**With dictionary**

```nim
  import zstd/common # for bytes()
  import zstd/compress
  import zstd/decompress

  var source = bytes(readFile("tests/files/gdp.json"))
  var dict = bytes(readFile("tests/files/gdp.dict"))

  var cctx = newCompressContext()
  var compressed = compress(cctx, source, dict, level=3)
  discard freeContext(cctx)

  var dctx = newDecompressContext()
  var decompressed = decompress(dctx, compressed, dict)
  discard freeContext(dctx)

  assert equalmem(decompressed[0].addr, source[0].addr, source.len)
```

## Streaming

```nim
  var c_in_stream = newFileStream("tests/files/gdp.json", fmRead)
  var c_out_stream = newFileStream("tests/files/gdp-copy.json.zst", fmWrite)

  # compress gdp.json to gdp-copy.json.zst with level 3
  compress(c_in_stream, c_out_stream, level=3)

  var d_in_stream = newFileStream("tests/files/gdp-copy.json.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/gdp-copy.json", fmWrite)

  # decompress gdp-copy.json.zst to gdp-copy.json
  decompress(d_in_stream, d_out_stream)

  var original = bytes(readFile("tests/files/gdp.json"))
  var cycled = bytes(readFile("tests/files/gdp-copy.json"))

  assert equalmem(cycled[0].addr, original[0].addr, original.len)
```

**Manual streaming**

For cases where the data isn't available all at once (or shouldn't be read all at once), `CompressStream` and `DecompressStream` give manual control over the streaming.

```nim
  var out_stream = newFileStream("data.zst", fmWrite)
  var strm = newCompressStream(out_stream, level=3)
  strm.compress("some data")            # string or openArray[byte],
  strm.compress("some more data")       # chunks may have any size
  strm.close()                          # optional, the destructor closes too
  out_stream.close()
```

```nim
  var strm = newDecompressStream(newFileStream("data.zst", fmRead))
  while not strm.atEnd():
    let chunk = strm.readStr(4096)
    # ... process chunk ...
  strm.close()                          # optional, the destructor closes too
```

Both only borrow the `Stream` they are given: closing (or dropping) them flushes and frees the zstd state, but the underlying stream stays open and is yours to close.

# Compile flags

`-d:useExternalZstd` to skip compiling with zstd and use system zstd instead (not default behavior)

`-d:zstdPath=/home/zstd` specify path to custom zstd
