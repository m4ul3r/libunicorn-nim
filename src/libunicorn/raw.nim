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
##
## The Unicorn version is checked twice:
##
## * at build time, the version pkg-config reports (`libVersion`) selects what
##   is available, and the headers the C compiler sees are checked against the
##   bindings. A function that the library is too old for is a compile-time
##   error that names the version it needs; test `when libVersion >= (2, 1, 0)`
##   before using one.
## * at run time, `uc_open` returns `UC_ERR_VERSION` when the loaded library
##   cannot be used with this build: another major version, an older one than
##   the program was built against or, on 32-bit targets, one from the other
##   side of Unicorn 2.1.4, which changed the type of the size parameters.

import std/strutils
import private/config

{.passl: linkFlags.}

when libMajor != 2:
  {.error: "libunicorn: Unicorn " & libVersionText & " is not supported. " &
           "Bindings exist for Unicorn 2.0.x and 2.1.x.".}

export libVersion, libVersionText

import gen_v2 as gen
export gen except
  # replaced below by declarations that follow the library version
  uc_open, uc_mem_map, uc_mem_map_ptr, uc_mmio_map, uc_mem_unmap, uc_mem_protect,
  uc_mem_read, uc_mem_write,
  # added after Unicorn 2.0.0; exported below when the library has them
  uc_reg_read2, uc_reg_write2, uc_reg_read_batch2, uc_reg_write_batch2,
  uc_context_reg_read2, uc_context_reg_write2, uc_context_reg_read_batch2,
  uc_context_reg_write_batch2, uc_vmem_read, uc_vmem_write, uc_vmem_translate

# --- versions --------------------------------------------------------------

const
  bindingsVersion* = (int(UC_API_MAJOR), int(UC_API_MINOR), int(UC_API_PATCH))
    ## The Unicorn version the declarations were generated from. A library
    ## older than this lacks some functions (see `libVersion`); a newer one
    ## works, without what it added.

when libVersion > bindingsVersion:
  {.hint: "libunicorn: Unicorn " & libVersionText & " is newer than these bindings (" &
          $UC_API_MAJOR & "." & $UC_API_MINOR & "." & $UC_API_PATCH &
          "); what it added is not available.".}

when headersKnown and not defined(unicornNoHeaderCheck):
  {.compile("private/abi_check.c", headerFlags &
    " -DLUN_LIB_MAJOR=" & $libMajor & " -DLUN_LIB_MINOR=" & $libMinor &
    " -DLUN_LIB_PATCH=" & $libPatch &
    " -DLUN_SIZEOF_MEM_REGION=" & $sizeof(uc_mem_region) &
    " -DLUN_SIZEOF_X86_MMR=" & $sizeof(uc_x86_mmr) &
    " -DLUN_SIZEOF_X86_MSR=" & $sizeof(uc_x86_msr) &
    " -DLUN_SIZEOF_ARM_CP_REG=" & $sizeof(uc_arm_cp_reg) &
    " -DLUN_SIZEOF_ARM64_CP_REG=" & $sizeof(uc_arm64_cp_reg) &
    " -DLUN_SIZEOF_TB=" & $sizeof(uc_tb) &
    " -DLUN_SIZEOF_TLB_ENTRY=" & $sizeof(uc_tlb_entry) &
    " -DLUN_OFFSETOF_TLB_ENTRY_PERMS=" & $offsetOf(uc_tlb_entry, perms) &
    " -DLUN_ERR_EXCEPTION=" & $ord(UC_ERR_EXCEPTION) &
    " -DLUN_HOOK_TCG_OPCODE=" & $uint32(UC_HOOK_TCG_OPCODE) &
    " -DLUN_MEM_READ_AFTER=" & $ord(UC_MEM_READ_AFTER)).}

type UcVersion* = tuple[major, minor, patch, extra: int]
  ## A Unicorn version as `uc_version()` reports it. `extra` is 255 for a
  ## release and the number of the release candidate otherwise.

proc uc_version*(): UcVersion =
  ## The version of the Unicorn library in this process, which need not be the
  ## one the program was built against (`libVersion`). Unicorn 2 packs
  ## major.minor.patch.extra into the combined number; Unicorn 1 only
  ## major.minor.
  var major, minor: cuint
  let combined = uc_version(addr major, addr minor)
  if major >= 2: (int(major), int(minor), int((combined shr 8) and 0xff), int(combined and 0xff))
  else: (int(major), int(minor), 0, 0)

func libraryVersionFits*(v: UcVersion): bool =
  ## Whether a Unicorn library of version `v` can be used through this build:
  ##
  ## * it has the same major version;
  ## * it is not older than the library the program was built against (an
  ##   older one lacks functions and constants the build assumed); a newer one
  ##   is fine;
  ## * on targets where `size_t` has less than 64 bits, it is on the same side
  ##   of Unicorn 2.1.4 as that library. 2.1.4 changed the `size` parameters of
  ##   seven memory functions from `size_t` to `uint64_t` (see `uc_size`)
  ##   without a new library name, so there a program built against an older
  ##   Unicorn passes its arguments in a way 2.1.4 and later do not expect.
  let loaded = (v.major, v.minor, v.patch)
  result = v.major == libMajor and loaded >= libVersion
  when sizeof(csize_t) < 8:
    result = result and (loaded >= (2, 1, 4)) == (libVersion >= (2, 1, 4))

proc libraryMatchesBindings*(): bool =
  ## Whether the Unicorn library in this process can be used through this
  ## build: `libraryVersionFits(uc_version())`. A newer library than the one
  ## the program was built against is accepted, except across Unicorn 2.1.4 on
  ## 32-bit targets.
  libraryVersionFits(uc_version())

proc uc_open*(arch: uc_arch; mode: uc_mode; uc: ptr ptr uc_engine): uc_err =
  ## C `uc_open`, except that it fails with `UC_ERR_VERSION` (and a nil
  ## handle) when `libraryMatchesBindings()` is false: the loaded library has
  ## another major version, is older than the one the program was built
  ## against, or has, on a 32-bit target, other size parameters. Every other
  ## call needs an engine, so this keeps a library that does not fit from
  ## being used at all.
  if not libraryMatchesBindings():
    if uc != nil: uc[] = nil
    return UC_ERR_VERSION
  gen.uc_open(arch, mode, uc)

# What Unicorn added after 2.0.0. The bindings declare all of it; a library
# that lacks a function would only be noticed by the linker, or by the loader
# when the program starts. So such a function exists only when the library the
# program is built against has it, and is a compile-time error otherwise.

# `dirty` so that the parameter keeps its name in the documentation.
template unavailable(name: untyped; since: string) {.dirty, used.} =
  template name*(args: varargs[untyped]): untyped =
    ## Not in the Unicorn this program is built against; using it is a
    ## compile-time error that names the version it needs.
    {.error: astToStr(name) & " needs Unicorn " & since &
             " or later; this build is against Unicorn " & libVersionText & ".".}

when libVersion >= (2, 1, 0):
  export gen.uc_reg_read2, gen.uc_reg_write2, gen.uc_reg_read_batch2, gen.uc_reg_write_batch2,
    gen.uc_context_reg_read2, gen.uc_context_reg_write2, gen.uc_context_reg_read_batch2,
    gen.uc_context_reg_write_batch2
else:
  unavailable(uc_reg_read2, "2.1.0")
  unavailable(uc_reg_write2, "2.1.0")
  unavailable(uc_reg_read_batch2, "2.1.0")
  unavailable(uc_reg_write_batch2, "2.1.0")
  unavailable(uc_context_reg_read2, "2.1.0")
  unavailable(uc_context_reg_write2, "2.1.0")
  unavailable(uc_context_reg_read_batch2, "2.1.0")
  unavailable(uc_context_reg_write_batch2, "2.1.0")

when libVersion >= (2, 1, 4):
  export gen.uc_vmem_read, gen.uc_vmem_write, gen.uc_vmem_translate
else:
  unavailable(uc_vmem_read, "2.1.4")
  unavailable(uc_vmem_write, "2.1.4")
  unavailable(uc_vmem_translate, "2.1.4")

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

# --- memory ----------------------------------------------------------------

# Unicorn 2.1.4 widened the sizes from size_t to uint64_t. On 64-bit targets
# that is the same thing; on 32-bit targets the declaration has to follow the
# library that is linked.
when libVersion >= (2, 1, 4) or sizeof(csize_t) == 8:
  type uc_size* = uint64
    ## The type of the `size` parameter of `uc_mem_map`, `uc_mem_map_ptr`,
    ## `uc_mmio_map`, `uc_mem_unmap`, `uc_mem_protect`, `uc_mem_read` and
    ## `uc_mem_write`: `uint64_t` from Unicorn 2.1.4 on, `size_t` before, which
    ## differ on 32-bit targets.
else:
  type uc_size* = csize_t
    ## The type of the `size` parameter of `uc_mem_map`, `uc_mem_map_ptr`,
    ## `uc_mmio_map`, `uc_mem_unmap`, `uc_mem_protect`, `uc_mem_read` and
    ## `uc_mem_write`: `uint64_t` from Unicorn 2.1.4 on, `size_t` before, which
    ## differ on 32-bit targets.

proc uc_mem_map*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uint32): uc_err {.
  cdecl, importc.}
  ## Maps `size` bytes of zeroed memory at `address`; both must be multiples
  ## of the page size, which depends on the architecture (`uc_query` with
  ## `UC_QUERY_PAGE_SIZE` tells it).
proc uc_mem_map_ptr*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uint32;
                     host: pointer): uc_err {.cdecl, importc.}
  ## Maps the caller's memory at `host` into the emulator. It must stay valid,
  ## and in place, for as long as the mapping exists.
proc uc_mmio_map*(uc: ptr uc_engine; address: uint64; size: uc_size;
                  read_cb: uc_cb_mmio_read_t; user_data_read: pointer;
                  write_cb: uc_cb_mmio_write_t; user_data_write: pointer): uc_err {.cdecl, importc.}
  ## Maps a region whose reads and writes go to the callbacks. Without a
  ## callback (nil) the region lacks that permission: reading it then ends the
  ## emulation with `UC_ERR_READ_PROT`, writing it with `UC_ERR_WRITE_PROT`.
proc uc_mem_unmap*(uc: ptr uc_engine; address: uint64; size: uc_size): uc_err {.cdecl, importc.}
  ## Unmaps a range of whole pages; it may be part of a mapping or span several.
proc uc_mem_protect*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uint32): uc_err {.
  cdecl, importc.}
  ## Changes the protection of a range of whole pages.
proc uc_mem_read*(uc: ptr uc_engine; address: uint64; bytes: pointer; size: uc_size): uc_err {.
  cdecl, importc.}
  ## Copies `size` bytes of emulated memory to `bytes`, whatever the protection.
proc uc_mem_write*(uc: ptr uc_engine; address: uint64; bytes: pointer; size: uc_size): uc_err {.
  cdecl, importc.}
  ## Copies `size` bytes from `bytes` into emulated memory, whatever the
  ## protection.
