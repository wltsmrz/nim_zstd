version = "0.1.0"
author = "wltsmrz"
description = "Nim bindings for zstd"
license = "MIT"
skipDirs = @["tests", "examples"]
skipFiles = @["README.md"]
installDirs = @["zstd"]
installFiles = @["zstd.nim"]
requires "nim >= 1.2.0"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libzstd-dev"

