## The Unicorn C API.
##
## The declarations come from a Futhark-generated module (`gen_v2`, generated
## from the headers of the newest supported Unicorn). This module re-exports
## them under their C names and corrects what a generator cannot get right:
##
## * `uc_mode`, `uc_prot` and `uc_hook_type` are bit sets that combine with
##   `or`.
##
## Error codes are values that must be used: nothing is `discardable`.

import std/strutils

{.passl: "`pkg-config --libs unicorn`".}

import gen_v2 as gen
export gen

# --- flags -----------------------------------------------------------------

# `dirty` so that the parameters keep their names in the documentation.
template flagOps(T: typedesc) {.dirty.} =
  func `or`*(a, b: T): T =
    ## The bits of both.
    T(uint32(a) or uint32(b))
  func `and`*(a, b: T): T =
    ## The bits `a` and `b` have in common.
    T(uint32(a) and uint32(b))
  func `==`*(a, b: T): bool =
    ## Whether both are the same bits.
    uint32(a) == uint32(b)
  func `$`*(x: T): string =
    ## The bits in hex. A combination has no single name, and the same bit of
    ## `uc_mode` means different things on different architectures.
    "0x" & toHex(uint32(x))
  func contains*(a, b: T): bool =
    ## Whether `a` has every bit of `b`: `UC_PROT_WRITE in perms`.
    (uint32(a) and uint32(b)) == uint32(b)

flagOps(uc_mode)
flagOps(uc_prot)
flagOps(uc_hook_type)
