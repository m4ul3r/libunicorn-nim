# Package

version       = "0.1.0"
author        = "m4ul3r"
description   = "Futhark wrapper for unicorn-engine"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"


# Tasks

# Maintainer task; see tools/gen.nim for the toolchain it needs.
taskRequires "regen", "futhark == 0.16.1"

task regen, "Regenerate the bindings from the Unicorn headers pkg-config points at":
  exec "nim c tools/gen.nim"
