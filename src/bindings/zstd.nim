proc ZSTD_versionNumber*(): cuint {.importc: "ZSTD_versionNumber", header: "zstd.h".}
proc ZSTD_isError*(a: csize_t): bool {.importc: "ZSTD_isError", header: "zstd.h".}
proc ZSTD_getErrorName*(a: csize_t): cstring {.importc: "ZSTD_getErrorName", header: "zstd.h".}
proc ZSTD_compressBound*(a: csize_t): csize_t {.importc: "ZSTD_compressBound", header: "zstd.h".}
proc ZSTD_compress*(a: pointer, b: csize_t, c: pointer, d: csize_t, e: cint): csize_t {.importc: "ZSTD_compress", header: "zstd.h".}
proc ZSTD_getDecompressedSize*(a: pointer, b: csize_t): csize_t {.importc: "ZSTD_getDecompressedSize", header: "zstd.h".}
proc ZSTD_decompress*(a: pointer, b: csize_t, c: pointer, d: csize_t): csize_t {.importc: "ZSTD_decompress", header: "zstd.h".}

