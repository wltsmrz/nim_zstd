version = "0.4.0"
author = "wltsmrz"
description = "Nim bindings for zstd"
license = "MIT"
skipDirs = @["examples"]
skipFiles = @["README.md"]
installDirs = @["zstd"]
requires "nim >= 1.2.0"

before install:
  exec("git submodule update --init --depth 1")

