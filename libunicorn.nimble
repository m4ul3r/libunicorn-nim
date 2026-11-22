# Package

version       = "0.1.0"
author        = "m4ul3r"
description   = "Futhark wrapper for unicorn-engine"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"


# Tasks

task examples, "Build and run the examples":
  for name in ["basic", "hooks", "raw_api"]:
    exec "nim c -r --hints:off -p:src examples/" & name & ".nim"

# The example that disassembles what it emulates needs the sibling package.
taskRequires "trace", "libcapstone >= 0.2.0"

task trace, "Build and run the example that uses libcapstone":
  exec "nim c -r --hints:off -p:src examples/trace.nim"

# Maintainer task; see tools/gen.nim for the toolchain it needs.
taskRequires "regen", "futhark == 0.16.1"

task regen, "Regenerate the bindings from the Unicorn headers pkg-config points at":
  exec "nim c tools/gen.nim"
