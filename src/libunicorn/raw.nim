## The Unicorn C API.
##
## The declarations come from a Futhark-generated module (`gen_v2`, generated
## from the headers of the newest supported Unicorn). This module re-exports
## them under their C names and corrects what a generator cannot get right:
##
## * `uc_mode`, `uc_prot` and `uc_hook_type` are bit sets that combine with
##   `or`;
## * `uc_hook_add`, variadic and untyped in C, is a set of overloads that take
##   the callback with its real type and refuse a hook kind the callback does
##   not belong to;
## * the callback types carry the parameter names of the header and
##   `raises: []`;
## * the function-like macros of the header (`uc_ctl_*`, `UC_CTL`, ...) are
##   procs;
## * memory functions take Nim buffers, register functions take the register
##   enums.
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
  # replaced below by typed overloads
  uc_hook_add, uc_ctl,
  # callback types, declared below with parameter names and `raises: []`
  uc_cb_hookcode_t, uc_cb_hookintr_t, uc_cb_hookinsn_invalid_t, uc_cb_insn_in_t,
  uc_cb_insn_out_t, uc_cb_insn_syscall_t, uc_cb_insn_cpuid_t, uc_cb_insn_sys_t,
  uc_cb_tlbevent_t, uc_hook_edge_gen_t, uc_hook_tcg_op_2, uc_hook_tcg_sub_t,
  uc_cb_mmio_read_t, uc_cb_mmio_write_t, uc_cb_hookmem_t, uc_cb_eventmem_t,
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
template unavailable(name: untyped; since: string; note = "") {.dirty, used.} =
  template name*(args: varargs[untyped]): untyped =
    ## Not in the Unicorn this program is built against; using it is a
    ## compile-time error that names the version it needs.
    {.error: astToStr(name) & " needs Unicorn " & since &
             " or later; this build is against Unicorn " & libVersionText & "." &
             (if note.len > 0: " " & note else: "").}

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

# --- flags and error codes -------------------------------------------------

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

func `$`*(code: uc_err): string =
  ## The C name of the error code (`UC_ERR_OK`), or `uc_err(<number>)` for a
  ## code of a Unicorn newer than the bindings. For a description use
  ## `uc_strerror`.
  let number = cast[int32](code)
  if number in int32(ord(low(uc_err))) .. int32(ord(high(uc_err))): system.`$`(code)
  else: "uc_err(" & $number & ")"

# --- callback types --------------------------------------------------------
#
# Declared by hand: the generator names the parameters a0, a1, ... and cannot
# say that a callback must not raise. Unicorn calls these from the middle of
# its own C frames and of the code it generated, where a Nim exception cannot
# pass; `raises: []` makes the compiler refuse a callback that could let one
# out.

type
  uc_cb_hookcode_t* = proc (uc: ptr uc_engine; address: uint64; size: uint32;
                            user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_CODE` (before every instruction) and `UC_HOOK_BLOCK` (on entry
    ## to a basic block): address and size in bytes of the instruction or block.
  uc_cb_hookintr_t* = proc (uc: ptr uc_engine; intno: uint32;
                            user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_INTR`: an interrupt or exception of the emulated CPU.
  uc_cb_hookinsn_invalid_t* = proc (uc: ptr uc_engine;
                                    user_data: pointer): bool {.cdecl, raises: [].}
    ## `UC_HOOK_INSN_INVALID`; false stops the emulation with
    ## `UC_ERR_INSN_INVALID`, true says that the callback dealt with the
    ## instruction (it has moved the program counter past it). Unicorn 2.1.2
    ## and later then go on; older ones end the run there, 2.0.x with
    ## `UC_ERR_OK` and 2.1.0 and 2.1.1 with `UC_ERR_EXCEPTION`.
  uc_cb_insn_in_t* = proc (uc: ptr uc_engine; port: uint32; size: cint;
                           user_data: pointer): uint32 {.cdecl, raises: [].}
    ## `UC_HOOK_INSN` with `UC_X86_INS_IN`; returns what the port delivers.
    ## `size` is 1, 2 or 4 bytes.
  uc_cb_insn_out_t* = proc (uc: ptr uc_engine; port: uint32; size: cint; value: uint32;
                            user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_INSN` with `UC_X86_INS_OUT`. `size` is 1, 2 or 4 bytes.
  uc_cb_insn_syscall_t* = proc (uc: ptr uc_engine; user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_INSN` with `UC_X86_INS_SYSCALL` or `UC_X86_INS_SYSENTER`.
  uc_cb_insn_cpuid_t* = proc (uc: ptr uc_engine; user_data: pointer): cint {.cdecl, raises: [].}
    ## `UC_HOOK_INSN` with `UC_X86_INS_CPUID` and, from Unicorn 2.1.2 on,
    ## `UC_X86_INS_RDTSC` or `UC_X86_INS_RDTSCP`; non-zero skips the
    ## instruction (the callback has set the registers itself).
  uc_cb_insn_sys_t* = proc (uc: ptr uc_engine; reg: uc_arm64_reg; cp_reg: ptr uc_arm64_cp_reg;
                            user_data: pointer): uint32 {.cdecl, raises: [].}
    ## `UC_HOOK_INSN` with `UC_ARM64_INS_MRS`, `_MSR`, `_SYS` or `_SYSL`;
    ## non-zero skips the instruction.
  uc_cb_tlbevent_t* = proc (uc: ptr uc_engine; vaddr: uint64; kind: uc_mem_type;
                            entry: ptr uc_tlb_entry; user_data: pointer): bool {.cdecl, raises: [].}
    ## `UC_HOOK_TLB_FILL` (Unicorn 2.1, with `uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL)`):
    ## translate `vaddr` into `entry`; false means the address is not mapped.
  uc_hook_edge_gen_t* = proc (uc: ptr uc_engine; cur_tb, prev_tb: ptr uc_tb;
                              user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_EDGE_GENERATED`: a jump from the block `prev_tb` to the block
    ## `cur_tb` was translated for the first time.
  uc_hook_tcg_op_2* = proc (uc: ptr uc_engine; address, arg1, arg2: uint64; size: uint32;
                            user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_TCG_OPCODE`: the two operands of the operation at `address`
    ## as they are after the instruction (for an x86 `sub`, the difference and
    ## the subtrahend); `size` is their width in bits.
  uc_hook_tcg_sub_t* = uc_hook_tcg_op_2
    ## The same under the name the header gives it for `UC_TCG_OP_SUB`.
  uc_cb_mmio_read_t* = proc (uc: ptr uc_engine; offset: uint64; size: cuint;
                             user_data: pointer): uint64 {.cdecl, raises: [].}
    ## `uc_mmio_map`: the emulated code reads `size` bytes at `offset` from the
    ## start of the region; returns the value.
  uc_cb_mmio_write_t* = proc (uc: ptr uc_engine; offset: uint64; size: cuint; value: uint64;
                              user_data: pointer) {.cdecl, raises: [].}
    ## `uc_mmio_map`: the emulated code writes `size` bytes at `offset` from
    ## the start of the region.
  uc_cb_hookmem_t* = proc (uc: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint;
                           value: int64; user_data: pointer) {.cdecl, raises: [].}
    ## `UC_HOOK_MEM_READ`, `_WRITE`, `_READ_AFTER`: accesses that succeed.
    ## `value` is what is being written, or what was read for
    ## `UC_MEM_READ_AFTER`. (`UC_HOOK_MEM_FETCH` is accepted with this type as
    ## well, but Unicorn 2.0 and 2.1 never call such a hook.)
  uc_cb_eventmem_t* = proc (uc: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint;
                            value: int64; user_data: pointer): bool {.cdecl, raises: [].}
    ## `UC_HOOK_MEM_*_UNMAPPED`, `UC_HOOK_MEM_*_PROT`: accesses that fail; true
    ## when the callback repaired the fault (mapped the page, changed the
    ## protection) and the access is to be tried again, false to stop with the
    ## error. The same callback can also hook the accesses that succeed; for
    ## those Unicorn ignores the result.

# --- macros ----------------------------------------------------------------

include cmacros

# --- memory ----------------------------------------------------------------

# Unicorn 2.1.4 widened the sizes from size_t to uint64_t. On 64-bit targets
# that is the same thing; on 32-bit targets the declaration has to follow the
# library that is linked.
#
# The size of a mapping is a size in the emulated address space and has the
# type `uc_size`, like an address; only the length of a host buffer
# (`uc_mem_read`, `uc_mem_write`) can also be given as the `int` that `len`
# and `sizeof` return.
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
  ## `UC_QUERY_PAGE_SIZE` or `uc_ctl_get_page_size` tell it).
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

proc uc_mem_map*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uc_prot): uc_err =
  ## `uc_mem_map` with the protection as `UC_PROT_*` flags.
  uc_mem_map(uc, address, size, uint32(perms))

proc uc_mem_map_ptr*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uc_prot;
                     host: pointer): uc_err =
  ## `uc_mem_map_ptr` with the protection as `UC_PROT_*` flags.
  uc_mem_map_ptr(uc, address, size, uint32(perms), host)

proc uc_mem_protect*(uc: ptr uc_engine; address: uint64; size: uc_size; perms: uc_prot): uc_err =
  ## `uc_mem_protect` with the protection as `UC_PROT_*` flags.
  uc_mem_protect(uc, address, size, uint32(perms))

proc uc_mem_write*(uc: ptr uc_engine; address: uint64; data: openArray[byte]): uc_err =
  ## `uc_mem_write` of a Nim buffer; an empty one writes nothing. For a string
  ## use `text.toOpenArrayByte(0, text.high)`.
  if data.len == 0: return UC_ERR_OK
  uc_mem_write(uc, address, unsafeAddr data[0], uc_size(data.len))

proc uc_mem_read*(uc: ptr uc_engine; address: uint64; data: var openArray[byte]): uc_err =
  ## Fills `data` from emulated memory; an empty buffer reads nothing.
  if data.len == 0: return UC_ERR_OK
  uc_mem_read(uc, address, addr data[0], uc_size(data.len))

proc uc_mem_write*(uc: ptr uc_engine; address: uint64; bytes: pointer; size: int): uc_err =
  ## `uc_mem_write` with the length as a Nim `int`, as `len` and `sizeof` give
  ## it; a negative one is `UC_ERR_ARG`.
  if size < 0: return UC_ERR_ARG
  uc_mem_write(uc, address, bytes, uc_size(size))

proc uc_mem_read*(uc: ptr uc_engine; address: uint64; bytes: pointer; size: int): uc_err =
  ## `uc_mem_read` with the length as a Nim `int`; a negative one is
  ## `UC_ERR_ARG`.
  if size < 0: return UC_ERR_ARG
  uc_mem_read(uc, address, bytes, uc_size(size))

template regions*(first: ptr uc_mem_region; count: uint32): untyped =
  ## The array `uc_mem_regions` returns, as something to iterate:
  ## `for region in regions(first, count)`. `region.last` is the last address
  ## of the region (`end` in C), `uc_prot(region.perms)` its protection. The
  ## array belongs to the caller: release it with `uc_free(first)`.
  toOpenArray(cast[ptr UncheckedArray[uc_mem_region]](first), 0, int(count) - 1)

template PTR*(s: untyped): pointer {.
    deprecated: "pass the buffer itself: uc_mem_write(uc, address, data)".} =
  ## Address of the first element of `s`.
  cast[pointer](s[0].addr)

# --- registers -------------------------------------------------------------
#
# The C API takes register ids as plain `int`; these accept the register enum
# of any architecture (`uc_x86_reg`, `uc_arm_reg`, ...). As in C, nothing says
# how wide a register is: the library reads or writes as many bytes at `value`
# as the register has (8 for a 64-bit register, 16 for XMM0, 32 for YMM0), so
# the variable must be at least that large. The `*2` functions of Unicorn 2.1
# take the size of the variable and answer `UC_ERR_OVERFLOW` instead.

proc uc_reg_read*[Reg: enum](uc: ptr uc_engine; regid: Reg; value: pointer): uc_err =
  ## `uc_reg_read` for a register enum. The library writes as many bytes to
  ## `value` as the register is wide.
  gen.uc_reg_read(uc, cint(ord(regid)), value)

proc uc_reg_write*[Reg: enum](uc: ptr uc_engine; regid: Reg; value: pointer): uc_err =
  ## `uc_reg_write` for a register enum. The library reads as many bytes from
  ## `value` as the register is wide.
  gen.uc_reg_write(uc, cint(ord(regid)), value)

proc uc_context_reg_read*[Reg: enum](ctx: ptr uc_context; regid: Reg; value: pointer): uc_err =
  ## `uc_context_reg_read` for a register enum: a register as a saved context
  ## holds it.
  gen.uc_context_reg_read(ctx, cint(ord(regid)), value)

proc uc_context_reg_write*[Reg: enum](ctx: ptr uc_context; regid: Reg; value: pointer): uc_err =
  ## `uc_context_reg_write` for a register enum: changes a register in a saved
  ## context.
  gen.uc_context_reg_write(ctx, cint(ord(regid)), value)

when libVersion >= (2, 1, 0):
  proc uc_reg_read2*[Reg: enum](uc: ptr uc_engine; regid: Reg; value: pointer;
                                size: ptr csize_t): uc_err =
    ## `uc_reg_read2` for a register enum: `size` holds the room at `value` on
    ## entry and the size of the register on return; `UC_ERR_OVERFLOW` when it
    ## does not fit.
    gen.uc_reg_read2(uc, cint(ord(regid)), value, size)

  proc uc_reg_write2*[Reg: enum](uc: ptr uc_engine; regid: Reg; value: pointer;
                                 size: ptr csize_t): uc_err =
    ## `uc_reg_write2` for a register enum: `size` holds the number of bytes
    ## at `value` on entry and the size of the register on return;
    ## `UC_ERR_OVERFLOW` when there are too few.
    gen.uc_reg_write2(uc, cint(ord(regid)), value, size)

  proc uc_context_reg_read2*[Reg: enum](ctx: ptr uc_context; regid: Reg; value: pointer;
                                        size: ptr csize_t): uc_err =
    ## `uc_context_reg_read2` for a register enum; `size` as in `uc_reg_read2`.
    gen.uc_context_reg_read2(ctx, cint(ord(regid)), value, size)

  proc uc_context_reg_write2*[Reg: enum](ctx: ptr uc_context; regid: Reg; value: pointer;
                                         size: ptr csize_t): uc_err =
    ## `uc_context_reg_write2` for a register enum; `size` as in
    ## `uc_reg_write2`.
    gen.uc_context_reg_write2(ctx, cint(ord(regid)), value, size)

# Batch access: C takes an array of ids, an array of pointers and a count.
# The register enums are declared with the size of a C `int` (4 bytes), so an
# array of them is the array of `int` the library expects.

template batchGuard(Reg: typedesc; regs, vals: untyped) =
  ## Leaves the calling proc when there is nothing to pass on to Unicorn.
  when sizeof(Reg) != sizeof(cint):
    {.error: $Reg & " is not a Unicorn register enum (those have the size of a C int)".}
  if regs.len != vals.len: return UC_ERR_ARG
  if regs.len == 0: return UC_ERR_OK

template regIds(regs: untyped): ptr cint = cast[ptr cint](unsafeAddr regs[0])
template valuePointers(vals: untyped): ptr pointer = cast[ptr pointer](unsafeAddr vals[0])

proc uc_reg_read_batch*[Reg: enum](uc: ptr uc_engine; regs: openArray[Reg];
                                   vals: openArray[pointer]): uc_err =
  ## Reads several registers in one call: `vals[i]` points to the variable for
  ## `regs[i]`. `UC_ERR_ARG` when the two differ in length; nothing to do and
  ## `UC_ERR_OK` when they are empty.
  batchGuard(Reg, regs, vals)
  gen.uc_reg_read_batch(uc, regIds(regs), valuePointers(vals), cint(regs.len))

proc uc_reg_write_batch*[Reg: enum](uc: ptr uc_engine; regs: openArray[Reg];
                                    vals: openArray[pointer]): uc_err =
  ## Writes several registers in one call: `vals[i]` points to the value for
  ## `regs[i]`. `UC_ERR_ARG` when the two differ in length; nothing to do and
  ## `UC_ERR_OK` when they are empty.
  batchGuard(Reg, regs, vals)
  gen.uc_reg_write_batch(uc, regIds(regs), valuePointers(vals), cint(regs.len))

proc uc_context_reg_read_batch*[Reg: enum](ctx: ptr uc_context; regs: openArray[Reg];
                                           vals: openArray[pointer]): uc_err =
  ## `uc_reg_read_batch` on a saved context.
  batchGuard(Reg, regs, vals)
  gen.uc_context_reg_read_batch(ctx, regIds(regs), valuePointers(vals), cint(regs.len))

proc uc_context_reg_write_batch*[Reg: enum](ctx: ptr uc_context; regs: openArray[Reg];
                                            vals: openArray[pointer]): uc_err =
  ## `uc_reg_write_batch` on a saved context.
  batchGuard(Reg, regs, vals)
  gen.uc_context_reg_write_batch(ctx, regIds(regs), valuePointers(vals), cint(regs.len))

when libVersion >= (2, 1, 0):
  proc uc_reg_read_batch2*[Reg: enum](uc: ptr uc_engine; regs: openArray[Reg];
                                      vals: openArray[pointer];
                                      sizes: var openArray[csize_t]): uc_err =
    ## `uc_reg_read_batch` with sizes: `sizes[i]` holds the room at `vals[i]`
    ## on entry and the size of the register on return. `UC_ERR_ARG` when the
    ## three differ in length, `UC_ERR_OVERFLOW` when a register does not fit.
    if sizes.len != regs.len: return UC_ERR_ARG
    batchGuard(Reg, regs, vals)
    gen.uc_reg_read_batch2(uc, regIds(regs), valuePointers(vals), addr sizes[0], cint(regs.len))

  proc uc_reg_write_batch2*[Reg: enum](uc: ptr uc_engine; regs: openArray[Reg];
                                       vals: openArray[pointer];
                                       sizes: var openArray[csize_t]): uc_err =
    ## `uc_reg_write_batch` with sizes: `sizes[i]` holds the number of bytes at
    ## `vals[i]` on entry and the size of the register on return. `UC_ERR_ARG`
    ## when the three differ in length, `UC_ERR_OVERFLOW` when a value is too
    ## short.
    if sizes.len != regs.len: return UC_ERR_ARG
    batchGuard(Reg, regs, vals)
    gen.uc_reg_write_batch2(uc, regIds(regs), valuePointers(vals), addr sizes[0], cint(regs.len))

  proc uc_context_reg_read_batch2*[Reg: enum](ctx: ptr uc_context; regs: openArray[Reg];
                                              vals: openArray[pointer];
                                              sizes: var openArray[csize_t]): uc_err =
    ## `uc_reg_read_batch2` on a saved context.
    if sizes.len != regs.len: return UC_ERR_ARG
    batchGuard(Reg, regs, vals)
    gen.uc_context_reg_read_batch2(ctx, regIds(regs),
      valuePointers(vals), addr sizes[0], cint(regs.len))

  proc uc_context_reg_write_batch2*[Reg: enum](ctx: ptr uc_context; regs: openArray[Reg];
                                               vals: openArray[pointer];
                                               sizes: var openArray[csize_t]): uc_err =
    ## `uc_reg_write_batch2` on a saved context.
    if sizes.len != regs.len: return UC_ERR_ARG
    batchGuard(Reg, regs, vals)
    gen.uc_context_reg_write_batch2(ctx, regIds(regs),
      valuePointers(vals), addr sizes[0], cint(regs.len))

# --- queries ---------------------------------------------------------------

proc uc_query*(uc: ptr uc_engine; kind: uc_query_type; value: var int): uc_err =
  ## `uc_query` into a Nim `int`: the page size, the architecture
  ## (`uc_arch(value)`), the mode (`uc_mode(value)`), or whether the last
  ## `uc_emu_start` ended by its timeout (`UC_QUERY_TIMEOUT`, 0 or 1).
  var answer: csize_t
  result = gen.uc_query(uc, kind, addr answer)
  if result == UC_ERR_OK: value = cast[int](answer)

# --- hooks -----------------------------------------------------------------
#
# C: uc_hook_add(uc, &hh, int type, void *callback, void *user_data, begin, end, ...)
# Nothing in that signature ties the callback to the hook type, and some hook
# types need extra variadic arguments. These overloads take the callback with
# its real type, so a callback of the wrong shape, a closure or a proc without
# `{.cdecl.}` does not compile, and they make the extra arguments parameters.
#
# The hook kind is a run-time value, so the pairing of kind and callback type
# is checked when the hook is added: a kind whose callbacks have another
# signature is refused with `UC_ERR_HOOK` before Unicorn sees it. Which
# signature each kind and instruction gets is what Unicorn's call sites cast
# `hook->callback` to (uc.c, qemu/softmmu, qemu/target/*).
#
# The range: the hook fires for addresses in `begin .. last`; `begin > last`
# (for example `1, 0`) means everywhere.

proc uc_hook_add_unchecked*(uc: ptr uc_engine; hh: ptr uc_hook; kind: cint; callback: pointer;
                            user_data: pointer; begin: uint64; last: uint64): uc_err {.
  cdecl, varargs, importc: "uc_hook_add".}
  ## The C `uc_hook_add` as it is: any pointer as callback and a variadic
  ## tail, which Unicorn reads as one C `int` (the instruction id) for
  ## `UC_HOOK_INSN` and two (opcode, flags) for `UC_HOOK_TCG_OPCODE`. Nothing
  ## is checked; prefer the `uc_hook_add` overloads.

func fits(kind, allowed: uc_hook_type): bool =
  ## Whether `kind` names at least one hook type and none outside `allowed`.
  uint32(kind) != 0 and (uint32(kind) and not uint32(allowed)) == 0

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_hookcode_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks instructions (`UC_HOOK_CODE`) or basic blocks (`UC_HOOK_BLOCK`), or
  ## both with one callback. Any other kind is `UC_ERR_HOOK`. (On 32-bit hosts
  ## add two hooks instead of one for both kinds: Unicorn up to 2.1.4 aborts
  ## there when it translates code under such a hook.)
  if not kind.fits(UC_HOOK_CODE or UC_HOOK_BLOCK): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_hookintr_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks interrupts and exceptions (`UC_HOOK_INTR`). Any other kind is
  ## `UC_ERR_HOOK`.
  if not kind.fits(UC_HOOK_INTR): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_hookmem_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks memory accesses that succeed: any combination of `UC_HOOK_MEM_READ`,
  ## `UC_HOOK_MEM_WRITE`, `UC_HOOK_MEM_FETCH` and `UC_HOOK_MEM_READ_AFTER`
  ## (`UC_HOOK_MEM_VALID` is the first three; Unicorn 2.0 and 2.1 take
  ## `UC_HOOK_MEM_FETCH` and never call the hook). Any other kind is
  ## `UC_ERR_HOOK`: for an access that fails Unicorn asks the callback whether
  ## to go on, and this type of callback has no answer. Those kinds take a
  ## `uc_cb_eventmem_t`.
  if not kind.fits(UC_HOOK_MEM_VALID or UC_HOOK_MEM_READ_AFTER): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_eventmem_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks memory accesses: any combination of the kinds for accesses that
  ## fail, `UC_HOOK_MEM_*_UNMAPPED` and `UC_HOOK_MEM_*_PROT`
  ## (`UC_HOOK_MEM_INVALID` is all six), and of those for accesses that
  ## succeed, `UC_HOOK_MEM_READ`, `_WRITE`, `_FETCH` and `_READ_AFTER`. So one
  ## callback can watch everything, as with
  ## `UC_HOOK_MEM_VALID or UC_HOOK_MEM_INVALID`; its result counts for the
  ## failing accesses only. Any other kind is `UC_ERR_HOOK`.
  if not kind.fits(UC_HOOK_MEM_INVALID or UC_HOOK_MEM_VALID or UC_HOOK_MEM_READ_AFTER):
    return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_hookinsn_invalid_t; user_data: pointer;
                  begin, last: uint64): uc_err =
  ## Hooks instructions the CPU does not know (`UC_HOOK_INSN_INVALID`). Any
  ## other kind is `UC_ERR_HOOK`.
  if not kind.fits(UC_HOOK_INSN_INVALID): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_hook_edge_gen_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks newly translated jumps between blocks (`UC_HOOK_EDGE_GENERATED`).
  ## Any other kind is `UC_ERR_HOOK`.
  if not kind.fits(UC_HOOK_EDGE_GENERATED): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_tlbevent_t; user_data: pointer; begin, last: uint64): uc_err =
  ## Hooks address translation (`UC_HOOK_TLB_FILL`); it is used once
  ## `uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL)` is set. Any other kind is
  ## `UC_ERR_HOOK`, and so is this one with a library older than Unicorn 2.1.0,
  ## which would accept the hook and never call it.
  if not kind.fits(UC_HOOK_TLB_FILL): return UC_ERR_HOOK
  let v = uc_version()
  if (v.major, v.minor) < (2, 1): return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last)

# `UC_HOOK_INSN`: the instruction id is the variadic argument in C. Unicorn
# looks at this bit first and then ignores every other bit of the kind, so the
# kind has to be `UC_HOOK_INSN` alone. Each instruction has its own callback
# signature; the id decides which.

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_insn_syscall_t; user_data: pointer; begin, last: uint64;
                  insn: uc_x86_insn): uc_err =
  ## Hooks the x86 instructions `UC_X86_INS_SYSCALL` or `UC_X86_INS_SYSENTER`
  ## (`kind` is `UC_HOOK_INSN`). Anything else is `UC_ERR_HOOK`.
  if kind != UC_HOOK_INSN or (insn != UC_X86_INS_SYSCALL and insn != UC_X86_INS_SYSENTER):
    return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(insn)))

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_insn_in_t; user_data: pointer; begin, last: uint64;
                  insn: uc_x86_insn): uc_err =
  ## Hooks the x86 instruction `UC_X86_INS_IN` (`kind` is `UC_HOOK_INSN`).
  ## Anything else is `UC_ERR_HOOK`.
  if kind != UC_HOOK_INSN or insn != UC_X86_INS_IN: return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(insn)))

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_insn_out_t; user_data: pointer; begin, last: uint64;
                  insn: uc_x86_insn): uc_err =
  ## Hooks the x86 instruction `UC_X86_INS_OUT` (`kind` is `UC_HOOK_INSN`).
  ## Anything else is `UC_ERR_HOOK`.
  if kind != UC_HOOK_INSN or insn != UC_X86_INS_OUT: return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(insn)))

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_insn_cpuid_t; user_data: pointer; begin, last: uint64;
                  insn: uc_x86_insn): uc_err =
  ## Hooks the x86 instruction `UC_X86_INS_CPUID` (`kind` is `UC_HOOK_INSN`).
  ## From Unicorn 2.1.2 on the same kind of callback serves `UC_X86_INS_RDTSC`
  ## and `UC_X86_INS_RDTSCP`; with an older library those two are
  ## `UC_ERR_HOOK`. Anything else is `UC_ERR_HOOK`.
  if kind != UC_HOOK_INSN: return UC_ERR_HOOK
  if insn == UC_X86_INS_RDTSC or insn == UC_X86_INS_RDTSCP:
    # Unicorn's own refusal would be the same code, but leaks the hook.
    let v = uc_version()
    if (v.major, v.minor, v.patch) < (2, 1, 2): return UC_ERR_HOOK
  elif insn != UC_X86_INS_CPUID:
    return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(insn)))

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_cb_insn_sys_t; user_data: pointer; begin, last: uint64;
                  insn: uc_arm64_insn): uc_err =
  ## Hooks the ARM64 system instructions `UC_ARM64_INS_MRS`, `_MSR`, `_SYS` or
  ## `_SYSL` (`kind` is `UC_HOOK_INSN`). Anything else is `UC_ERR_HOOK`.
  if kind != UC_HOOK_INSN or
      (insn != UC_ARM64_INS_MRS and insn != UC_ARM64_INS_MSR and insn != UC_ARM64_INS_SYS and
       insn != UC_ARM64_INS_SYSL):
    return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(insn)))

# `UC_HOOK_TCG_OPCODE`: opcode and flags are the variadic arguments in C. As
# with `UC_HOOK_INSN`, the kind has to be this bit alone.

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_hook_tcg_op_2; user_data: pointer; begin, last: uint64;
                  opcode: uc_tcg_op_code; flags: uint32): uc_err =
  ## Hooks an operation of the intermediate code (`UC_HOOK_TCG_OPCODE`), for
  ## example every subtraction with `UC_TCG_OP_SUB`. `flags` is 0 or
  ## `UC_TCG_OP_FLAG_*` values (`uint32(ord(UC_TCG_OP_FLAG_CMP))`); which
  ## combinations there are depends on the architecture, and x86 answers
  ## `UC_ERR_HOOK` for both flags together. Any other kind is `UC_ERR_HOOK`.
  if kind != UC_HOOK_TCG_OPCODE: return UC_ERR_HOOK
  uc_hook_add_unchecked(uc, hh, cast[cint](kind), cast[pointer](callback), user_data, begin, last,
                        cint(ord(opcode)), cast[cint](flags))

proc uc_hook_add*(uc: ptr uc_engine; hh: ptr uc_hook; kind: uc_hook_type;
                  callback: uc_hook_tcg_op_2; user_data: pointer; begin, last: uint64;
                  opcode: uc_tcg_op_code; flags: uc_tcg_op_flag): uc_err =
  ## `UC_HOOK_TCG_OPCODE` with a single flag: `UC_TCG_OP_FLAG_CMP` (only
  ## operations that set the condition codes, such as the subtraction of a
  ## `cmp`) or `UC_TCG_OP_FLAG_DIRECT` (only operations an instruction
  ## translates to directly, such as that of a `sub`).
  uc_hook_add(uc, hh, kind, callback, user_data, begin, last, opcode, uint32(ord(flags)))
