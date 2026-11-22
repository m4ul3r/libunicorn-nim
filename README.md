# libunicorn-nim

Nim bindings for the [Unicorn](https://www.unicorn-engine.org) CPU emulator, versions 2.0.x and 2.1.x:

- the C API under its C names, generated with [Futhark](https://github.com/PMunch/futhark);
- a small Nim API on top: an emulator object that closes itself, memory through Nim buffers, registers by value with their size checked, hooks as closures, exceptions instead of error codes.

```nim
import std/strutils
import libunicorn

let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
uc.memMap(0x1000, 0x1000)
uc.memWrite(0x1000, "\x48\xff\xc0\x48\x01\xc3")    # inc rax; add rbx, rax
uc.regWrite(UC_X86_REG_RAX, 41)

discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
  echo "at 0x", address.toHex(4), ": rax = ", uc.regRead(UC_X86_REG_RAX)   # at 0x1000: rax = 41
                                                                          # at 0x1003: rax = 42
uc.start(0x1000, 0x1006)
echo "rbx = ", uc.regRead(UC_X86_REG_RBX)                                  # rbx = 42
```

## Install

Unicorn itself comes from the system:

| System | Package |
|---|---|
| Debian, Ubuntu | `libunicorn-dev` |
| Fedora | `unicorn-devel` |
| Alpine | `unicorn-dev` |
| Arch, Homebrew | `unicorn` |
| MSYS2 | `mingw-w64-x86_64-unicorn` |

Then `nimble install libunicorn`. The build finds Unicorn through `pkg-config`; see [Build options](#build-options) for the other cases.

Needs Nim 2.0 or later. Tested on Linux x86-64 with Nim 2.0.16, 2.2.10 and 2.4.2 against Unicorn 2.0.1 (the package of Ubuntu 24.04) and 2.1.4, and with Nim 2.4.2 against every other release from 2.0.0 to 2.1.3; on 32-bit x86 Linux against 2.0.1 and 2.1.4; and cross-compiled with MinGW to 64-bit and 32-bit Windows against 2.1.4, run under Wine. macOS, native Windows and hosts other than x86 are untested. On Windows use Unicorn 2.1.0 or later (see [Supported Unicorn versions](#supported-unicorn-versions)).

## The Nim API

Needs `--mm:orc` or `--mm:arc`, the defaults. `nimble docs` builds the full reference. `examples/basic.nim` runs a few instructions on fourteen architectures and modes, `examples/hooks.nim` traces a program that prints through emulated Linux system calls, with hooks for instructions, memory accesses, missing memory and system calls, and `examples/trace.nim` single-steps code and disassembles it with the sibling package [libcapstone](https://github.com/m4ul3r/libcapstone-nim):

```
$ nim c -r -p:src examples/hooks.nim
```

```nim
import std/times
import libunicorn

const code = "\x48\xff\xc0\x48\x89\x03\x0f\x05\xeb\xfe"   # inc rax; mov [rbx], rax; syscall; jmp $

let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)

# Memory. Addresses and sizes of mappings are multiples of `uc.pageSize`.
uc.memMap(0x1000, 0x1000, UC_PROT_READ or UC_PROT_EXEC)
uc.memWrite(0x1000, code)                  # a string or an openArray[byte]
echo uc.memRead(0x1000, 3)                 # @[72, 255, 192]
for region in uc.memRegions: echo region   # (first: 4096, last: 8191, perms: 0x00000005)

# Registers go in and out by value.
uc.regWrite(UC_X86_REG_RAX, 41)
uc.regWrite(UC_X86_REG_RBX, 0x200000)
echo uc.regRead(UC_X86_REG_RAX)                         # 41
echo uc.regRead(UC_X86_REG_XMM0, array[16, byte])[0]    # 0
echo uc.msrRead(0xC0000080'u32)                         # 1280
uc.pc = 0x1000

# Hooks are closures. The callback comes last, and its first parameter is the engine.
var trace: seq[uint64]
let tracing = uc.onCode(0x1000'u64 .. 0x1fff'u64) do (uc: Unicorn; address: uint64; size: int):
  trace.add address

discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED) do (
    uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
  echo kind, " at ", address               # UC_MEM_WRITE_UNMAPPED at 2097152
  uc.memMap(address and not 0xfff'u64, 0x1000)
  true                                     # repaired: the access is tried again

discard uc.onSyscall do (uc: Unicorn):
  uc.stop()

# Running. Without an end address the run lasts until something stops it.
let saved = uc.saveContext()               # the registers as they are now
uc.start(uc.pc, 0)
echo trace                                 # @[4096, 4099, 4102]
echo uc.pc, " ", uc.memRead(0x200000, 1)   # 4104 @[42]

uc.removeHook(tracing)
uc.start(uc.pc, 0, initDuration(milliseconds = 20))     # `jmp $` never ends by itself
echo uc.timedOut                           # true

uc.restore(saved)
echo uc.regRead(UC_X86_REG_RAX)            # 41

# Errors are exceptions that carry Unicorn's code.
try:
  uc.memMap(0x1000, 0x1000)
except UnicornError as e:
  echo e.code, ": ", e.msg                 # UC_ERR_MAP: Invalid memory mapping (UC_ERR_MAP)

# Modes combine with `or`. The CPU model is chosen before anything else is done.
let mips = initUnicorn(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN)
let arm = initUnicorn(UC_ARCH_ARM, UC_MODE_THUMB)
arm.cpuModel = UC_CPU_ARM_CORTEX_M4
echo mips.mode, " ", arm.cpuModel(uc_cpu_arm)           # 0x40000004 UC_CPU_ARM_CORTEX_M4
```

- **Lifetime.** A `Unicorn` closes its engine when it goes out of scope. It cannot be copied, only moved: it can be returned from a proc or kept in a `seq`, and its hooks go with it. A `Context` behaves the same way. An engine that loses its last owner inside one of its own hooks is closed when the call that ran the hook returns.
- **Hooks.** A hook is a callback that Unicorn calls when the emulated code does something: runs an instruction (`onCode`), enters a basic block (`onBlock`), accesses memory (`onMem`), accesses memory that is not there or is protected (`onMemFault`), raises an interrupt (`onInterrupt`), executes `syscall` (`onSyscall`), and so on; the reference lists them all. An address range is a `Slice[uint64]` with both ends included; an empty one raises. Each `on...` proc returns a `HookId` for `removeHook`, and a hook may remove itself or others while it runs. A hook added after code has run is called for that code too; one added inside a hook, from the next `start` on. The engine keeps the closure alive. Inside the closure use its first parameter, not the engine variable from outside: a closure that captures its own engine forms a cycle, and the engine is then closed whenever ORC collects cycles, and never under `--mm:arc`.
- **Exceptions in hooks.** An exception raised in a hook, a `Defect` such as an index error included, stops the emulation and is raised again by the `start` that ran the hook. The engine stays usable. After a code hook no further instruction runs; after other kinds Unicorn may finish the current basic block. Hooks also run outside `start`: `memRead` and `memWrite` call the closures of `mmioMap`, and loading an x86 segment register reads the descriptor table through the memory hooks. The exception then comes out of that call. With `--panics:on` a `Defect` ends the program, in a hook as anywhere else.
- **Registers.** `regRead(reg)` gives a `uint64`; narrower registers are zero-extended. `regWrite(reg, value)` takes any integer; a signed one is sign-extended. Registers that are not a number of up to 64 bits are read as a type of their size, which must be plain data without pointers: `uc.regRead(UC_X86_REG_XMM0, array[16, byte])`, `array[10, byte]` for the x87 registers, `uc_x86_mmr` for `UC_X86_REG_GDTR`. The variable is never overrun, which the C function cannot promise: reading a wider register into something smaller raises `UnicornError` with `UC_ERR_OVERFLOW` in a program built against Unicorn 2.1, and gives the low bytes with Unicorn 2.0. Wherever a register enum is taken, so is the number of the register as a `cint`, for ids computed at run time: `uc.regRead(cint(ord(UC_X86_REG_RAX)))`. `msrRead` and `msrWrite` access the x86 model-specific registers by number, `regRead(reg, value)` with a `uc_arm_cp_reg` or `uc_arm64_cp_reg` the ARM coprocessor registers, `regReadBatch` and `regWriteBatch` several registers at once. `uc.pc` is the program counter of every architecture.
- **Errors.** `UnicornError` carries Unicorn's error code in `code` and its description as the message. It is also raised for what would make Unicorn crash or hang instead of failing: `flushTb` inside a hook (`removeCache` works there), a page size for `pageSize=` that is not a power of two from 1024 bytes to 64 MB, `requestCache` for an address outside mapped executable memory, mode bits that are no mode written to the CPSR of an ARM CPU in user mode.
- **Running.** `start(begin, until, timeout, count)` ends at the address `until`, after `timeout` (microseconds as a number, or a `Duration` of `std/times`) or after `count` instructions; 0 is no limit. `uc.timedOut` tells whether the last run ended by its timeout. `uc.exits = [0x1004'u64, 0x1010]` sets several end addresses in place of `until`. A hook may call `start` itself, up to 63 runs inside one another, but not together with `count`: a `start` inside a hook raises when it has a count or a run around it has one.
- **Contexts.** A context is a saved CPU state. `uc.saveContext()` returns one, `uc.restore(ctx)` puts it back, `ctx.regRead` and `ctx.regWrite` look into it and change it, by enum or by number. It can only be restored into the engine it was saved from, and it may outlive that engine. Some registers Unicorn cannot reach in a context without the engine; those raise `UnicornError` instead of touching memory that is not the context's: model-specific and coprocessor registers, the RISC-V CSRs, the SPARC window registers, and for writing also the x86 control and segment registers and a few floating-point control registers. With `uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}` (Unicorn 2.1) a context holds the memory as well. A context is then restored under the mode it was saved with, and contexts with memory form a stack: restoring one ends those saved after it, and restoring one of them raises. Unicorn 2.1.2 cannot restore memory, so with that release loaded `contextMode=` raises for `UC_CTL_CONTEXT_MEMORY`.
- **Threads.** One engine belongs to one thread at a time. The exception is `stop`, which Unicorn allows from another thread while `start` runs; no test here covers that.
- **Mixing in the C API.** `uc.handle` gives the C handle and `ctx.handle` the C context; do not close or free them. What is done through the handle is not known to the object: hooks added with `uc_hook_add`, a context mode set with `uc_ctl_context_mode`. The object's hooks do run during a `uc_emu_start` called directly. An exception one of them raises stops that emulation and is raised by the next call that goes through the object; a hook must not call `start` when that `uc_emu_start` has an instruction count; and an engine that loses its last owner inside such a hook is never closed. An `onTcgOpcode` or `onSys` hook removed inside a hook during such a run stays in the translated code until the next call through the object: make one (for example `uc.pc`) before calling `uc_emu_start` again, or Unicorn runs code that refers to its freed record of the hook.
- **Crashes in Unicorn that are not guarded.** Unicorn 2.1.4 crashes when `UC_SPARC_REG_PSR` of a 32-bit SPARC engine is read before the engine has computed condition codes or the register was written. Unicorn 2.0 crashes when an x86 segment register is loaded and the descriptor table is not in mapped memory. `requestCache` for a block that runs off the end of its mapping gives numbers without meaning and crashes Unicorn 2.0.1.
- **Unicorn 2.1.** `onTlbFill`, `tlbMode=`, `flushTlb`, `contextMode=` and `tcgBufferSize` exist only in a build against Unicorn 2.1.0 or later; see [Supported Unicorn versions](#supported-unicorn-versions).

## The C API

`import libunicorn` (or only `import libunicorn/raw`) gives Unicorn's own names and signatures, so C code and the Unicorn documentation carry over. `examples/raw_api.nim` is a complete program: Unicorn's x86-64 and ARM64 samples, call for call; a part whose architecture the library was built without is skipped. It works with every memory manager.

```nim
import libunicorn/raw

proc onCode(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  inc cast[ptr int](user_data)[]

var
  uc: ptr uc_engine
  hook: uc_hook
  count = 0
  rax = 41'u64
doAssert uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
doAssert uc_mem_map(uc, 0x1000, 0x1000, UC_PROT_READ or UC_PROT_EXEC) == UC_ERR_OK
doAssert uc_mem_write(uc, 0x1000, [0x48'u8, 0xff, 0xc0, 0x48, 0x01, 0xc3]) == UC_ERR_OK
doAssert uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
doAssert uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, addr count, 1, 0) == UC_ERR_OK

let err = uc_emu_start(uc, 0x1000, 0x1006, 0, 0)
echo err, ": ", uc_strerror(err)                # UC_ERR_OK: OK (UC_ERR_OK)
doAssert uc_reg_read(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
echo rax, " after ", count, " instructions"     # 42 after 2 instructions
doAssert uc_close(uc) == UC_ERR_OK
```

Where it differs from C:

| C | Here | Why |
|---|---|---|
| `uc_open` | returns `UC_ERR_VERSION` if the loaded library cannot be used by this build: another major version, older than the one the program was built against, or, on 32-bit targets, on the other side of Unicorn 2.1.4 | such a library lacks functions the build assumed, or takes other arguments; see below |
| `uc_mode`, `uc_prot`, `uc_hook_type` enums | `distinct uint32`; combine with `or`, test with `in` | a Nim enum cannot hold `UC_PROT_READ \| UC_PROT_EXEC` |
| `uc_hook_add(uc, &hh, type, void *callback, user_data, begin, end, ...)` | one overload per callback type; the instruction id of `UC_HOOK_INSN` and the opcode and flags of `UC_HOOK_TCG_OPCODE` are parameters; a hook type the callback does not belong to is `UC_ERR_HOOK` | C checks neither the callback nor the variadic arguments |
| one memory callback for every `UC_HOOK_MEM_*` type | the callback that returns `bool` (`uc_cb_eventmem_t`) is accepted for all of them, the one without a result (`uc_cb_hookmem_t`) only for accesses that succeed | for an access that fails Unicorn asks the callback whether to go on |
| callback typedefs | declared `{.cdecl, raises: [].}`, with the parameter names of the header | an exception cannot pass through Unicorn's frames, so a callback that could raise does not compile |
| `uc_ctl(uc, UC_CTL_READ(...), ...)` and the `uc_ctl_*` macros | one proc per macro: `uc_ctl_get_page_size(uc, addr size)` | the generator cannot translate macros, and C reads the arguments with `va_arg`, which needs their exact types |
| `size_t size` of `uc_mem_map`, `uc_mem_map_ptr`, `uc_mmio_map`, `uc_mem_unmap`, `uc_mem_protect`, `uc_mem_read`, `uc_mem_write` | `uc_size` | Unicorn 2.1.4 made these `uint64_t`, which is another type on 32-bit targets |
| field `end` of `uc_mem_region` | `last` | `end` is a keyword in Nim, and the address is that of the last byte |
| parameters `type`, `end`, `ptr` | `kind`, `last`, `host`; the `end` of `uc_ctl_remove_cache` is `until` | keywords in Nim. A range of `uc_hook_add` includes its last address; that of `uc_ctl_remove_cache` ends before `until` |
| an ignored return value | does not compile without `discard` | an error code is a value that must be used |
| functions added after Unicorn 2.0.0 | exist only in a build against a Unicorn that has them | otherwise the linker or the loader would report it; see below |
| `uc_ctl_flush_tlb` | empties the TLB (the cache of address translations), as in the 2.1 headers; `uc_ctl_flush_tb` drops the translated code with every Unicorn 2 | the 2.0 headers use the first name for the second thing |
| `UC_MAKE_VERSION` | the definition of the 2.1 headers | the one of the 2.0 headers does not give what `uc_version` returns |
| the `MSC_VER_*` constants of `platform.h` | not exported | compiler plumbing, not part of the API |

Three things are as in C and easy to get wrong:

- `uc_reg_read` and `uc_reg_write` do not know how large the variable is: the library reads or writes as many bytes as the register is wide, 16 for `UC_X86_REG_XMM0`. The `uc_reg_read2` family of Unicorn 2.1 takes the size.
- `uc_mmio_map` with a nil callback maps a region without that permission: reading it ends the emulation with `UC_ERR_READ_PROT`, writing it with `UC_ERR_WRITE_PROT`.
- Addresses and sizes of mappings are multiples of the page size, which is 4 KiB on most architectures, 1 KiB on ARM and ARM64 and 16 KiB on TriCore; `uc_ctl_get_page_size` tells.

Added on top, because C takes plain integers and pointers:

- `uc_mem_write(uc, address, data)` and `uc_mem_read(uc, address, buffer)` take an `openArray[byte]`, also an empty one; the forms with pointer and length accept an `int` length.
- `uc_mem_map`, `uc_mem_map_ptr` and `uc_mem_protect` take `uc_prot` flags as well as a number.
- `for region in regions(first, count)` iterates what `uc_mem_regions` returned.
- Every function that takes a register id accepts the register enums: `uc_reg_read(uc, UC_ARM_REG_R0, addr value)`, likewise the `uc_context_reg_*` functions and their `*2` variants. The batch functions take an `openArray` of registers and one of pointers.
- `uc_query(uc, UC_QUERY_PAGE_SIZE, value)` answers into an `int`.
- `uc_version()` returns the version of the loaded library as a tuple `(major, minor, patch, extra)`; `libVersion` is the version the program was built against, `bindingsVersion` the one the declarations were generated from.
- `$` gives C names: `UC_ERR_OK`, `UC_X86_REG_RAX`. An error code the bindings do not know prints as `uc_err(<number>)`, flags print their bits in hex.
- The macros the generator cannot translate are written by hand: `UC_HOOK_MEM_UNMAPPED` and its six siblings, `UC_CTL_IO_READ_WRITE`, `UC_MAKE_VERSION`, `UC_CTL` and its four variants, and the `uc_ctl_*` family, with overloads for Nim types such as `uc_ctl_set_exits(uc, [0x1004'u64])` and `uc_ctl_set_cpu_model(uc, UC_CPU_X86_HASWELL)`.
- `uc_hook_add_unchecked` is the C `uc_hook_add` as it is, and `uc_ctl` the C function, for what the overloads and procs do not cover.

## Supported Unicorn versions

| Unicorn | Status | Shipped by (late 2026) |
|---|---|---|
| 2.0.0, 2.0.1 | supported | Ubuntu 24.04, Debian 12, Fedora 39 to 41 (2.0.1.post1) |
| 2.1.0 to 2.1.4 | supported | 2.1.1: Debian 13, Ubuntu 25.04 and 25.10, Fedora 42. 2.1.4: Arch, Alpine 3.24, Fedora 43 and later, Ubuntu 26.04 and later, Debian 14, Homebrew, MacPorts, MSYS2, vcpkg, FreeBSD |
| a later 2.x | builds with a hint; what it added is not available | none |
| 1.0.x | refused | Void Linux |
| 3.x | refused | none |

One set of declarations, generated from the 2.1.4 headers, serves every Unicorn 2: from 2.0.0 to 2.1.4 the API only grows. No enum member changes its value, apart from the `*_ENDING` markers that follow the last register of each architecture, and no struct changes; the one signature that changes is the size of seven memory functions (`uc_size` in the table above). The test suite passes against every release from 2.0.0 to 2.1.4.

Two releases, 2.0.1 and 2.1.2, install a pkg-config file that is one patch level behind their header: it says 2.0.0 and 2.1.1. The build accepts exactly these two pairs, and `libVersion` is then one patch level behind the library, which changes nothing in what is available. Ubuntu's 2.0.1.post1 reports 2.0.1.

On Windows use Unicorn 2.1.0 or later. Unicorn 2.0.x frees memory there with another allocator than it took it from, and a program that closes an engine and goes on can crash later; the 32-bit test programs built against 2.0.1.post1 do so under Wine.

What was added:

| Unicorn | Added |
|---|---|
| 2.0.1 | `UC_ARM64_REG_FPCR`, `UC_ARM64_REG_FPSR` |
| 2.1.0 | `uc_reg_read2`, `uc_reg_write2`, their batch and context variants (eight functions); `UC_ERR_OVERFLOW`; `UC_HOOK_TLB_FILL` and `uc_tlb_entry`; `uc_ctl_flush_tlb`, `uc_ctl_tlb_mode`, `uc_ctl_get_tcg_buffer_size`, `uc_ctl_set_tcg_buffer_size`, `uc_ctl_context_mode` |
| 2.1.2, 2.1.3 | one RISC-V and two MIPS registers |
| 2.1.4 | `uc_vmem_read`, `uc_vmem_write`, `uc_vmem_translate`; 66 registers |

A function that the Unicorn of the build is too old for is a compile-time error:

```
Error: uc_reg_read2 needs Unicorn 2.1.0 or later; this build is against Unicorn 2.0.1.
```

Code that wants such a function where it exists tests the version, not `declared(...)`:

```nim
import libunicorn

let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
when libVersion >= (2, 1, 0):          # the Unicorn this program is built against
  uc.tlbMode = UC_TLB_VIRTUAL
let v = uc_version()                   # the Unicorn library in this process
echo (v.major, v.minor, v.patch) >= libVersion      # true
```

Constants and enum members are always declared, also those newer than the library. What an older library does with one differs: a control it does not know is `UC_ERR_ARG`; `UC_HOOK_TLB_FILL` is refused by the typed `uc_hook_add` with `UC_ERR_HOOK`, because Unicorn 2.0 would accept the hook and never call it; a register is not refused at all, see the list below.

Behaviour that differs between versions:

- The default x86 CPU model is `UC_CPU_X86_QEMU64` up to 2.1.2 and `UC_CPU_X86_HASWELL` from 2.1.3 on.
- Unicorn 2.0.0 refuses `uc_ctl_set_cpu_model` for the first member of each model enum, such as `UC_CPU_X86_QEMU64`, with `UC_ERR_ARG`.
- Reading or writing a register the library does not know, or the architecture does not have, returns `UC_ERR_OK` and leaves the variable alone in 2.0.x, returns `UC_ERR_ARG` in 2.1.0 and 2.1.1, and returns `UC_ERR_OK` with a warning on standard error from 2.1.2 on. That includes registers newer than the library, such as `UC_ARM_REG_ESR` (2.1.4) and the ZMM registers (2.1.2).
- After a `UC_HOOK_INSN_INVALID` callback that returns true, Unicorn 2.1.2 and later go on; older versions end the run, 2.0.x without an error and 2.1.0 and 2.1.1 with `UC_ERR_EXCEPTION`.
- A `UC_HOOK_MEM_FETCH` hook is accepted and never called, in every version. Before 2.1.2 a `UC_HOOK_MEM_READ_AFTER` hook without a `UC_HOOK_MEM_READ` hook next to it is called only for the first access to a page: a read that follows another read or a write there is missed.
- Unicorn 2.1.2 cannot restore a context that holds memory (`UC_CTL_CONTEXT_MEMORY`): `uc_context_restore` reads memory it has just freed, and restoring one such context after another ends the process. 2.1.0, 2.1.1 and 2.1.3 on do not have this fault. The Nim API refuses that mode with 2.1.2; the C API passes it through.
- 64-bit MIPS stops with a CPU exception at the first instruction before 2.1.3.
- A Unicorn can be built with only some architectures; `uc_arch_supported(arch)` tells, and `initUnicorn` raises `UC_ERR_ARCH` for the others.

Bindings used with a library they do not fit call functions that are not there, so this package checks three times:

1. **Build time, pkg-config.** The reported version decides which functions exist; a major version other than 2 stops the build.
2. **Build time, headers.** A small C file compares `unicorn.h` with pkg-config's version and with the bindings (struct sizes, enum numbering). Headers that declare more than the bindings know, as those of a later 2.x do, pass.
3. **Run time.** All of Unicorn 2 has the same library name, `libunicorn.so.2`, so a program can meet another version than it was built against. `uc_open` and `initUnicorn` fail with `UC_ERR_VERSION` when the loaded library is of another major version or older than the one of the build; `libraryMatchesBindings()` tells without opening anything. A newer library is accepted, with one exception on 32-bit targets: Unicorn 2.1.4 changed the type of seven size parameters there, so a program built against an older Unicorn is refused by 2.1.4 and later. A program that uses a function the older library lacks may not get as far as `uc_open`: where programs are linked with immediate binding, as on Ubuntu, the dynamic loader stops it at start (`undefined symbol: uc_reg_read2`). The Nim API built against Unicorn 2.1 is such a program.

## Build options

| Define | Effect |
|---|---|
| `-d:unicornStatic` | link `libunicorn.a` from pkg-config's library directory, with the libraries it needs, instead of the shared library |
| `-d:unicornLibs="..."` | linker flags to use, as they are; pkg-config is not consulted at all, also not for `unicornStatic` |
| `-d:unicornVersion=2.1.4` | version of that library; required with `unicornLibs`. On its own it states the version pkg-config is expected to report, and the build stops when it reports another |
| `-d:unicornCflags="..."` | where the headers are. With `unicornLibs` and without this, the header check is skipped; on its own it replaces pkg-config's C flags |
| `-d:unicornNoHeaderCheck` | skip the header check |

Static linking adds about 20 MB to a binary, and it makes Unicorn's license apply to that binary; see [License](#license). It needs the distribution to ship `libunicorn.a`; Ubuntu's `libunicorn-dev` does.

Cross-compiling uses `unicornLibs`, `unicornVersion` and `unicornCflags`, because pkg-config describes the host. For Windows from Linux, with a Unicorn built by MinGW in `$UC`:

```
nim c -d:mingw --cpu:amd64 \
  -d:unicornLibs="$UC/lib/libunicorn.a" -d:unicornVersion=2.1.4 \
  -d:unicornCflags="-I$UC/include" app.nim
```

`nim check` and nimsuggest cannot run pkg-config; there the code is checked against Unicorn 2.1.4, the version of the bindings, unless `-d:unicornVersion` says otherwise.

## Development

```
nimble test        # needs pkg-config and a C compiler; the layout test also uses clang
nimble examples
nimble trace       # the example with libcapstone; installs that package and needs Capstone
nimble docs        # into htmldocs/
```

To test against another Unicorn than the system one:

```
PKG_CONFIG_PATH=<prefix>/lib/pkgconfig LD_LIBRARY_PATH=<prefix>/lib nimble test
```

Run the tests against Unicorn 2.0.1 and 2.1.4 before a release: several of them take another path with each.

Layout:

| Path | Content |
|---|---|
| `src/libunicorn.nim` | the Nim API; re-exports the C API |
| `src/libunicorn/raw.nim` | the C API: version checks, corrections and overloads |
| `src/libunicorn/gen_v2.nim` | generated bindings; do not edit |
| `src/libunicorn/cmacros.nim` | hand-written C macros |
| `src/libunicorn/private/` | build configuration, header check |
| `tools/gen.nim` | the generator |
| `tests/` | `traw`, `tmacros`, `tlayout` (the C API and the declarations), `tapi`, `thooks`, `tarch` (the Nim API), `tguards` (the version checks) |
| `examples/` | `basic`, `hooks`, `trace` (the Nim API), `raw_api` (the C API) |

### Regenerating the bindings

`nimble regen` rewrites `src/libunicorn/gen_v2.nim` from the headers pkg-config points at, which must be those of Unicorn 2.1.4 or later; set `PKG_CONFIG_PATH` to generate from another Unicorn than the system one. It takes about ten seconds and its output is reproducible. Do it when a new Unicorn is released, then add the functions it brought to the version guards in `raw.nim` and its macros to `cmacros.nim`. Run the tests afterwards: `tests/tlayout.nim` compares every struct and every enum member with the installed headers, `tests/tmacros.nim` reports macros that have no counterpart.

`tools/gen.nim` hands `unicorn.h` to Futhark and adjusts what comes back: the three flag enums become constants of distinct types, the names Nim cannot spell (`end`, `type`, `ptr`) are replaced, the contents of `platform.h` are dropped, and the paths recorded in the output are made independent of where the headers are installed.

It needs:

- Nim 2.4 or later (the generated file itself builds with Nim 2.0);
- Futhark 0.16.1 (the nimble task pins it) with its `opir` helper on the `PATH`;
- a `clang` on the `PATH` whose major version matches the libclang `opir` was linked against.

Installing Futhark needs an unversioned `libclang.so`. On Debian and Ubuntu that comes with `libclang-dev`; without it:

```
ln -s /usr/lib/llvm-18/lib/libclang.so.1 <dir>/libclang.so
nimble install --passL:"-L<dir>" futhark@0.16.1
```

## License

MIT, see `LICENSE`. That covers the bindings only. Unicorn itself is licensed under the GNU General Public License, version 2, and a program that links it, statically or as a shared library, has to respect that license when it is distributed.
