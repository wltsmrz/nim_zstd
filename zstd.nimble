version = "0.2.0"
author = "wltsmrz"
description = "Nim bindings for zstd"
license = "MIT"
skipDirs = @["tests", "examples"]
skipFiles = @["README.md"]
installDirs = @["zstd"]
installFiles = @["zstd.nim"]
requires "nim >= 1.2.0"

before install:
  exec("git submodule update --init --depth 1")
  exec("make -j$(nproc) -C zstd/deps/zstd lib-release")

