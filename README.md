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

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  discard free_context(dctx)

  assert equalmem(decompressed[0].addr, source[0].addr, source.len)
```

**With dictionary**

```nim
  import zstd/common # for bytes()
  import zstd/compress
  import zstd/decompress

  var source = bytes(readFile("tests/files/gdp.json"))
  var dict = bytes(readFile("tests/files/gdp.dict"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  discard free_context(dctx)

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

# Compile flags

`-d:useExternalZstd` to skip compiling with zstd and use system zstd instead (not default behavior)

`-d:zstdPath=/home/zstd` specify path to custom zstd

