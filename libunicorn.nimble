# Package

version       = "0.2.0"
author        = "m4ul3r"
description   = "Bindings for the Unicorn CPU emulator: the C API and a small Nim API on top"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 2.0.0"

# Unicorn itself comes from the system; say how to get it after an install.
when defined(nimdistros):
  import distros
  if detectOs(Ubuntu) or detectOs(Debian):
    foreignDep "libunicorn-dev"
  elif detectOs(Fedora) or detectOs(CentOS) or detectOs(RedHat):
    foreignDep "unicorn-devel"
  elif detectOs(Alpine):
    foreignDep "unicorn-dev"
  else:
    foreignDep "unicorn"


# Tasks

task examples, "Build and run the examples":
  for name in ["basic", "hooks", "raw_api"]:
    exec "nim c -r --hints:off -p:src examples/" & name & ".nim"

# The example that disassembles what it emulates needs the sibling package.
taskRequires "trace", "libcapstone >= 0.2.0"

task trace, "Build and run the example that uses libcapstone":
  exec "nim c -r --hints:off -p:src examples/trace.nim"

task docs, "Generate the API documentation into htmldocs/":
  exec "nim doc --project --index:on --outdir:htmldocs src/libunicorn.nim"

# Maintainer task; see the README for the toolchain it needs.
taskRequires "regen", "futhark == 0.16.1"

task regen, "Regenerate the bindings from the Unicorn headers pkg-config points at":
  exec "nim c tools/gen.nim"
