# zstd

Nim bindings for [zstd](https://github.com/facebook/zstd)

```bash
$ nimble install zstd
```

## Simple API

```nim
  import zstd/compress
  import zstd/decompress

  var source = readFile("tests/files/nixon.bmp")
  var compressed = compress(source, level=3)
  var decompressed = decompress(compressed)
  check equalmem(decompressed[0].addr, source[0].addr, source.len)
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

  var source = readFile("tests/files/nixon.bmp")

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed)
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
```

**With dictionary**

```nim
  import zstd/common # for bytes()
  import zstd/compress
  import zstd/decompress

  var source = bytes(readFile("tests/files/nixon.bmp"))
  var dict = bytes(readFile("tests/files/nixon.dict"))

  var cctx = new_compress_context()
  var compressed = compress(cctx, source, dict, level=3)
  discard free_context(cctx)

  var dctx = new_decompress_context()
  var decompressed = decompress(dctx, compressed, dict)
  discard free_context(dctx)

  check equalmem(decompressed[0].addr, source[0].addr, source.len)
```

## Streaming

```nim
  var c_in_stream = newFileStream("tests/files/nixon.bmp", fmRead)
  var c_out_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmWrite)

  # compress nixon.bmp to nixon-copy.bmp.zst with level 3
  compress(c_in_stream, c_out_stream, level=3)

  var d_in_stream = newFileStream("tests/files/nixon-copy.bmp.zst", fmRead)
  var d_out_stream = newFileStream("tests/files/nixon-copy.bmp", fmWrite)

  # decompress nixon-copy.bmp.zst to nixon-copy.bmp
  decompress(d_in_stream, d_out_stream)

  var original = bytes(readFile("tests/files/nixon.bmp"))
  var cycled = bytes(readFile("tests/files/nixon-copy.bmp"))

  check equalmem(cycled[0].addr, original[0].addr, original.len)
```

# Compile flags

`-d:useExternalZstd` to skip compiling with zstd and use system zstd instead (not default behavior)

`-d:zstdPath=/home/zstd` specify path to custom zstd

