
const ZSTD_CONTENTSIZE_UNKNOWN* {.importc: "ZSTD_CONTENTSIZE_UNKNOWN", header: "zstd.h".} = clonglong(-1)
const ZSTD_CONTENTSIZE_ERROR* {.importc: "ZSTD_CONTENTSIZE_ERROR", header: "zstd.h".} = clonglong(-2)

type ZSTD_inBuffer {.importc: "ZSTD_inBuffer", header: "zstd.h".} = object
  src: ptr byte
  size: csize_t
  pos: csize_t

type ZSTD_outBuffer {.importc: "ZSTD_outBuffer", header: "zstd.h".} = object
  dst: ptr byte
  size: csize_t
  pos: csize_t

type ZSTD_strategy {.size: sizeof(cint), importc: "ZSTD_strategy", header: "zstd.h".} = enum
  ZSTD_fast = 1,
  ZSTD_dfast = 2,
  ZSTD_greedy = 3,
  ZSTD_lazy = 4,
  ZSTD_lazy2 = 5,
  ZSTD_btlazy2 = 6,
  ZSTD_btopt = 7,
  ZSTD_btultra = 8,
  ZSTD_btultra2 = 9

proc ZSTD_versionNumber*(): cuint {.importc: "ZSTD_versionNumber", header: "zstd.h".}
proc ZSTD_versionString*(): cstring {.importc: "ZSTD_versionString", header: "zstd.h".}
proc ZSTD_isError*(a: csize_t): bool {.importc: "ZSTD_isError", header: "zstd.h".}
proc ZSTD_getErrorName*(a: csize_t): cstring {.importc: "ZSTD_getErrorName", header: "zstd.h".}
# Not available in 1.3.3
# proc ZSTD_minCLevel*(): cint {.importc: "ZSTD_minCLevel", header: "zstd.h".}
proc ZSTD_maxCLevel*(): cint {.importc: "ZSTD_maxCLevel", header: "zstd.h".}
proc ZSTD_compressBound*(a: csize_t): csize_t {.importc: "ZSTD_compressBound", header: "zstd.h".}
proc ZSTD_compress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t, e: cint): csize_t {.importc: "ZSTD_compress", header: "zstd.h".}
proc ZSTD_getDecompressedSize*(a: ptr byte, b: csize_t): csize_t {.importc: "ZSTD_getDecompressedSize", header: "zstd.h".}
proc ZSTD_getFrameContentSize*(a: ptr byte, b: csize_t): clonglong {.importc: "ZSTD_getFrameContentSize", header: "zstd.h".}
proc ZSTD_decompress*(a: ptr byte, b: csize_t, c: ptr byte, d: csize_t): csize_t {.importc: "ZSTD_decompress", header: "zstd.h".}


type ZSTD_CCtx* {.importc: "ZSTD_CCtx", header: "zstd.h".} = object
proc ZSTD_createCCtx*(): ptr ZSTD_CCtx {.importc: "ZSTD_createCCtx", header: "zstd.h".}
proc ZSTD_freeCCtx*(a: ptr ZSTD_CCtx): csize_t {.importc: "ZSTD_freeCCtx", header: "zstd.h".}

type ZSTD_DCtx* {.importc: "ZSTD_DCtx", header: "zstd.h".} = object
proc ZSTD_createDCtx*(): ptr ZSTD_DCtx {.importc: "ZSTD_createDCtx", header: "zstd.h".}
proc ZSTD_freeDCtx*(a: ptr ZSTD_DCtx): csize_t {.importc: "ZSTD_freeDCtx", header: "zstd.h".}

proc ZSTD_compressCCtx*(a: ptr ZSTD_CCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t, f: cint): csize_t {.importc: "ZSTD_compressCCtx", header: "zstd.h".}
proc ZSTD_decompressDCtx*(a: ptr ZSTD_DCtx, b: ptr byte, c: csize_t, d: ptr byte, e: csize_t): csize_t {.importc: "ZSTD_decompressDCtx", header: "zstd.h".}

proc ZSTD_compress_usingDict*(a: ptr ZSTD_CCtx,
                            b: ptr byte, c: csize_t,
                            d: ptr byte, e: csize_t,
                            f: ptr byte, g: csize_t,
                            h: cint
                           ): csize_t {.importc: "ZSTD_compress_usingDict", header: "zstd.h".}
proc ZSTD_decompress_usingDict*(a: ptr ZSTD_DCtx,
                              b: ptr byte, c: csize_t,
                              d: ptr byte, e: csize_t,
                              f: ptr byte, g: csize_t
                            ): csize_t {.importc: "ZSTD_decompress_usingDict", header: "zstd.h".}


type ZSTD_CDict* {.importc: "ZSTD_CDict", header: "zstd.h".} = object
proc ZSTD_createCDict*(a: ptr byte, b: csize_t, c: cint): ptr ZSTD_CDict {.importc: "ZSTD_createDict", header: "zstd.h".}
proc ZSTD_freeCDict*(a: ptr ZSTD_CDict): csize_t {.importc: "ZSTD_freeCDict", header: "zstd.h".}
proc ZSTD_compressUsingCDict*(a: ptr ZSTD_CCtx,
                            b: ptr byte, c: csize_t,
                            d: ptr byte, e: csize_t,
                            f: ptr ZSTD_CDict
                           ): csize_t {.importc: "ZSTD_compressUsingCDict", header: "zstd.h".}

type ZSTD_DDict* {.importc: "ZSTD_DDict", header: "zstd.h".} = object
proc ZSTD_createDDict*(a: ptr byte, b: csize_t): ptr ZSTD_DDict {.importc: "ZSTD_createDict", header: "zstd.h".}
proc ZSTD_freeDDict*(a: ptr ZSTD_DDict): csize_t {.importc: "ZSTD_freeDDict", header: "zstd.h".}
proc ZSTD_decompressUsingDDict*(a: ptr ZSTD_CCtx,
                            b: ptr byte, c: csize_t,
                            d: ptr byte, e: csize_t,
                            f: ptr ZSTD_DDict
                           ): csize_t {.importc: "ZSTD_compressUsingCDict", header: "zstd.h".}


