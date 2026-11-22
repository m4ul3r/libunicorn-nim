# TODO

State on 2026-11-22, after working through the audit of 2026-11-21. Everything under "Done" is in `v0.2.0`, which was merged as a stack of eight pull requests ([stack 9](https://github.com/m4ul3r/libunicorn-nim/stack/9), #1 to #8, each based on the one before) on top of `v0.1.0`, the head before this work. It was verified as listed under "Verification". The ids are those of the audit.

## Open

None of these blocks a release.

- [ ] **L5. macOS and native Windows are untested.** Windows was verified by cross-compiling with MinGW for 64-bit and 32-bit targets against a static Unicorn 2.1.4 and running under Wine. Closing it needs a run of `nimble test` on each.
- [ ] **Windows with Unicorn 2.0.x crashes, and the cause is Unicorn's.** On Windows Unicorn 2.0.x allocates with `__mingw_aligned_malloc` in `qemu_memalign` and frees with `VirtualFree` in `qemu_vfree` (`qemu/util/oslib-posix.c` of 2.0.1.post1, lines 75 and 132); 2.1.0 fixed it (upstream commit a5fa5480). Closing an engine damages the heap, and whether a later allocation faults depends on the layout of the program: the 32-bit test binaries built against 2.0.1.post1 crash under Wine at the first `uc_mem_map` of the second engine, a twelve-line program with the C API alone does so as a debug build and not with `-d:release`, and plain C programs run. The same tests pass on 32-bit Linux against 2.0.1 and on Windows against 2.1.4. 64-bit Windows with 2.0.x was not tried. No distribution ships the combination (MSYS2 has 2.1.4); the README says to use 2.1.0 or later there. What is left to decide is whether the build should refuse it.
- [ ] **Hosts other than x86 are untested**, big-endian ones in particular. `regRead(reg)` reads into a `uint64`; on a big-endian host a narrower register would land in the wrong half, and the form that takes a type of the register's size has to be used there (H4). Closing it needs a run on such a host and, for big-endian, a `regRead` that places the bytes.
- [ ] **Any enum is accepted where a register enum is expected.** The register overloads are generic over `enum`, so `uc_reg_read(uc, UC_ARCH_X86, addr value)` compiles and reads register 4, and the Nim API takes `uc.regRead(UC_ARCH_X86)` and `uc.cpuModel = UC_X86_REG_RAX` the same way. Only the batch functions of the C API refuse an enum of another size. Closing it needs a type class that lists the ten register enums (and the model enums for `cpuModel=`), kept in step with the generated file.
- [ ] **A stress program that nests `start` at random segfaulted inside Unicorn 2.0.1 for some seeds.** It was not minimised, and it is not known whether the API or Unicorn is at fault. The nesting tests of `tests/thooks.nim` pass on 2.0.1, also under valgrind. Closing it needs the failing seed reduced to a program, then run against the C API alone.
- [ ] **Three crashes of Unicorn are documented, not guarded:** reading `UC_SPARC_REG_PSR` of a fresh 32-bit SPARC engine with 2.1.4 (the condition is state the API cannot see; refusing the read until the register was written would be a blunt guard), loading an x86 segment register with the descriptor table in unmapped memory with 2.0, and `requestCache` for a block that runs off its mapping with 2.0.1. The doc comments of `regRead`, `regWrite` and `requestCache` and the README say so.
- [ ] **Limits of going through `uc.handle`,** documented there and in the README: a hook that calls `start` under a `uc_emu_start` with an instruction count cannot be refused; an engine that loses its last owner inside a hook under a direct `uc_emu_start` is parked and never closed, a leak by design; an `onTcgOpcode` or `onSys` hook removed inside a hook under a direct `uc_emu_start` stays in the translated code until the next call through the object, and another direct `uc_emu_start` before that makes Unicorn read its freed record of the hook (deferring Unicorn's deletion of such a hook until the code is discarded would close this one); and `start` keeps track of whether Unicorn's instruction counter is installed, which a direct `uc_emu_start` can change unseen, so that the next counted `start` may again run old code uncounted.
- [ ] **No CI.** The suite is run by hand against Unicorn 2.0.1 and 2.1.4 before a release (T7). A workflow would need both versions; Ubuntu 24.04 packages 2.0.1, 2.1.4 has to be built.
- [ ] **V7. Unicorn 2.2, once released.** Its development branch only adds so far: `uc_hook_set_user_data`, three error codes, `UC_HOOK_BLOCK_ICOUNT`, five `UC_CTL_*`, a register, two instruction ids. Run `nimble regen` against it, add the new functions to the guards in `raw.nim` and the new `uc_ctl_*` macros to `cmacros.nim` (`tests/tmacros.nim` lists the ones that are missing), raise the version the generator asks for. 2.2 is announced to answer `UC_ERR_ARG` for register ids an architecture does not have. Until then a 2.2 library builds with a hint and without what it added.
- [ ] **Y7. Publish the docs.** `nimble docs` builds them into `htmldocs/`; GitHub Pages needs to be switched on in the repository settings and something has to deploy them.
- [ ] **H11. `stop` from another thread is documented, not tested.** Unicorn's own timeout thread calls `uc_emu_stop` that way, and a program that stops a run from a second thread returned in ten of ten rounds against 2.0.1 and 2.1.4. A test in the suite needs `--threads:on` and a run that only the other thread ends.
- [ ] **32-bit hosts: one hook for `UC_HOOK_CODE or UC_HOOK_BLOCK` makes Unicorn abort** when it translates code under it, up to 2.1.4. This is Unicorn's; `uc_hook_add` says so, and the Nim API always adds one hook per kind. Report it upstream.
- [ ] **Not in the Nim API:** hooks for `rdtsc` and `rdtscp` (Unicorn 2.1.2), `uc_vmem_read`, `uc_vmem_write` and `uc_vmem_translate` (2.1.4), batch access and `pc` for a `Context`. The C API has them, through `uc.handle` and `ctx.handle`.
- [ ] **H3b. Optional: a mapping that owns its buffer.** `memMapPtr` takes a pointer that the caller keeps alive and in place. An overload that takes a `seq[byte]` and keeps it with the engine would remove that duty.
- [ ] **L6. Optional: a `dynlib` mode** for users without the development package (`libunicorn.so.2`, `unicorn.dll`). Without pkg-config the version would have to be given.
- [ ] **L7. Not planned: a vendored build.** 586 C files, about 4 minutes with four jobs, 20 MB per binary, and GPLv2.

## Done

### Decisions

- [x] **D1.** Unicorn 2.0.0 to 2.1.x; 1.x and 3.x are refused at build time.
- [x] **D2.** One generated file, from the newest release (2.1.4), for every Unicorn 2; what an older library lacks is guarded in `libunicorn/raw`.
- [x] **D3.** No hand edits in the generated file and nothing `discardable`: an error code is a value that must be used. Convenience is in overloads in `libunicorn/raw` and in the Nim API, which raises.
- [x] **D4.** C spelling (`uc_open`, `UC_ARCH_X86`). `uc_mode`, `uc_prot` and `uc_hook_type` are distinct types that combine with `or`. The field `uc_mem_region.end` is `last`; the parameters `type`, `end`, `ptr` are `kind`, `last`, `host`.
- [x] **D5.** `Unicorn` is a value object that closes itself and cannot be copied; its state lives behind a traced `ref`, so that hooks find it after a move and the cycle collector can reclaim an engine captured by its own hook.
- [x] **D6.** The callback types of the C API are declared by hand with `{.cdecl, raises: [].}`.
- [x] **D7.** 32-bit targets are supported.
- [x] **D8.** MIT for the bindings; the README says that Unicorn is GPLv2; static linking is opt-in.
- [x] **D9.** Nim API on ORC or ARC only; under `--mm:refc` `initUnicorn` fails to compile with the reason, and the C API works. The generated file is checked in and rewritten by `nimble regen`. Version 0.2.0.

### P0: correctness and safety

- [x] **P0-1. Register access cannot overrun the variable** in the Nim API. Every access says how much room it has: in a build against Unicorn 2.1 through `uc_reg_read2` and `uc_reg_write2`, which answer `UC_ERR_OVERFLOW`, against 2.0 through `uc_reg_read` and `uc_reg_write`. Either way Unicorn reads into a 64-byte buffer, never into the variable, because 2.1.0 and 2.1.1 ignore the size for some registers (`readRegister`, `writeRegister` in `src/libunicorn.nim`). A register value type that is a pointer, a `cstring` or a proc, or that holds a `ref`, a `string` or a `seq`, does not compile; a pointer inside an object or an array is not caught. Tests in `tests/tapi.nim`, for engines and contexts: "a type smaller than the register is never overrun" and its neighbours, "a register that Unicorn writes without looking at the size overruns nothing", "a register value is plain data without pointers". The C API stays as in C and says so next to the declarations; the examples use `uint64`.
- [x] **P0-2. A hook callback is checked.** `uc_hook_add` exists only as overloads that take the callback with its real type; a proc without `{.cdecl.}`, a closure, wrong parameter types and a callback that can raise do not compile, and a hook type or instruction that belongs to another callback type is `UC_ERR_HOOK` (`tests/traw.nim`, suite "hooks"). The C signature is `uc_hook_add_unchecked`.
- [x] **P0-3. An exception raised in a hook** is caught by the trampoline of the Nim API, stops the emulation and is raised again by the call that ran the hook: `start`, also a nested one, `memRead` and `memWrite` that reach the closures of `mmioMap`, and `regWrite` of an x86 segment register, which reads the descriptor table through the memory hooks. The same for a `Defect`. The exception stays with the run it stops whatever later hooks do, and the first one wins (`tests/thooks.nim`, suites "exceptions in hooks", "callbacks outside start", "start inside a hook", "memory-mapped I/O"). In the C API such a callback does not compile (D6).
- [x] **P0-4.** `uc_mem_read` and `uc_mem_write` are plain `importc` declarations plus Nim overloads; `int`, `csize_t` and `uc_size` lengths in one module build (`tests/traw.nim`, "pointer and length").
- [x] **P0-5.** Nothing is `discardable`: 32 calls of the C API layer each compile with `discard` and not as a bare statement (`tests/traw.nim`, suite "error codes"). The examples look at every result and exit with a status.
- [x] **P0-6. `uc_size`** is the type of the seven size parameters that Unicorn 2.1.4 changed from `size_t` to `uint64_t`: `uint64` from 2.1.4 on and on 64-bit targets, `csize_t` otherwise. The Nim API refuses a size that does not fit instead of truncating it. Because the change came without a new library name, the run-time guard keeps a 32-bit program from a library on the other side of 2.1.4 (V4).
- [x] **P0-7. Build configuration** in `private/config.nim`: pkg-config is asked at compile time, and a failure stops the build with pkg-config's own words and an install hint (`tests/tguards.nim`).

### Versions

- [x] **V1.** `gen_v2.nim` is generated from the 2.1.4 headers; the suite passes against every release from 2.0.0 to 2.1.4.
- [x] **V2.** The build-time version comes from `pkg-config --modversion` (`libVersion`, `libVersionText`). A major version other than 2 stops the build; a 2.x newer than the bindings builds with a hint, also when its headers declare more registers than the bindings know. The releases 2.0.1 and 2.1.2 install a `unicorn.pc` one patch level behind their `unicorn.h` (2.0.0 and 2.1.1); the header check accepts exactly these two pairs, and `libVersion` is then one patch level behind, which nothing depends on (`tests/tguards.nim`; `tests/tmacros.nim`, suite "header check").
- [x] **V3.** The eleven functions added after 2.0.0 and the five `uc_ctl_*` procs of 2.1.0 exist only in a build against a Unicorn that has them; otherwise using one is a compile-time error that names both versions. The same for `onTlbFill`, `tlbMode=`, `flushTlb`, `contextMode=` and `tcgBufferSize` of the Nim API. Tests: "what the library is too old for does not compile" (`traw`), "a function newer than the library is refused with both versions" (`tguards`).
- [x] **V4.** Run-time guard: `uc_open` returns `UC_ERR_VERSION` and a nil handle when the loaded library has another major version, is older than the one of the build or, on a 32-bit target, is on the other side of Unicorn 2.1.4; a newer library is accepted otherwise. `initUnicorn` raises with both versions in the message; `libraryMatchesBindings()` asks without opening, `libraryVersionFits(version)` is the rule itself (`tguards`, suite "run-time guard"; `traw`, "which library versions this build accepts"). `uc_version()` returns major, minor, patch and extra.
- [x] **V5.** Version table in the README.
- [x] **V6.** The behaviour that differs between versions is in the README, and the tests that meet it branch on `uc_version()` or `libVersion` with the reason in a comment.

### C API (`libunicorn/raw`)

| ID | Was | Now |
|---|---|---|
| R1 | `cast[uc_mode](UC_MODE_ARM.uint32 or UC_MODE_BIG_ENDIAN.uint32)` | `UC_MODE_ARM or UC_MODE_BIG_ENDIAN`; `uc_mem_map`, `uc_mem_map_ptr` and `uc_mem_protect` take `uc_prot` or a number |
| R2 | `uc_ctl_get_page_size` undeclared, `uc_ctl` needed a hand-built code | one proc per `uc_ctl_*` macro with the exact C argument types, plus overloads for Nim types; each is run by `tests/tmacros.nim` |
| R3 | `uc_reg_write(uc, UC_ARM_REG_R0.cint, addr r0)` | every function that takes a register id takes any register enum, the context, `*2` and batch functions included |
| R4 | `uc_hook_add` without the instruction id compiled | the id, and the opcode and flags of `UC_HOOK_TCG_OPCODE`, are parameters of the overloads (P0-2). A memory callback that returns `bool` is taken for every memory hook type, as in Unicorn's own sample |
| R5 | `uc_mem_write(uc, a, PTR(code), code.len)`; `uc_mem_map` rejected an `int` size | `uc_mem_write(uc, a, data)` and `uc_mem_read(uc, a, buffer)` over `openArray[byte]`, empty included; pointer and length with an `int` length. The size of a mapping stays a `uc_size`, like an address: a literal is taken, an `int` variable needs a conversion |
| R6 | `cast[ptr UncheckedArray[uc_mem_region]](regions)[i].endfield` | `for region in regions(first, count)`, `region.last`, `uc_prot(region.perms)` |
| R7 | `$UC_ERR_OK` was `Ucerrok`, `$UC_MODE_64` was `Ucmodemips64` | C spelling; flags print their bits in hex |
| R8 | 34 macros missing | `cmacros.nim`; `tests/tmacros.nim` compares the values with what the C compiler computes from the installed headers and fails for a macro without a counterpart |
| R9 | `--styleCheck:usages` unusable | the tests and the examples build with `nim c --styleCheck:usages --styleCheck:error` |
| R10 | `uc_query` wanted `ptr csize_t`, the batch calls arrays of `cint` and `pointer` | `uc_query(uc, kind, value)` into an `int`; the batch functions take `openArray`s and check their lengths |
| R11 | `$cast[uc_err](22)` was an empty string: 22 was beyond the codes 0.1.0 knew | a code the bindings do not know prints as its number, `uc_err(99)`; `UnicornError` takes its message from `uc_strerror` |
| R12 | callback parameters `a0` to `a5` | the callback types are declared by hand with the names of the header (D6) |
| R13 | `MSC_VER_*` constants, `PTR`, `CPTR` | the constants and `CPTR` are gone, `PTR` is deprecated |

### Nim API (`libunicorn`)

- [x] **H1.** `Unicorn`: closes itself, cannot be copied, can be moved, returned and kept in a `seq` with its hooks intact; `initUnicorn(arch, mode)`, `arch`, `mode`, `handle` (`tests/tapi.nim`, suites "engine" and "moving the engine"). An engine that loses its last owner inside one of its hooks is closed when the call that ran the hook returns (`tests/thooks.nim`).
- [x] **H2.** `UnicornError` with Unicorn's code in `code` and the text of `uc_strerror`. It is also raised where Unicorn itself would crash or hang: `flushTb` inside a hook, a `pageSize=` that is not a power of two from 1024 to 2^26, `requestCache` outside mapped executable memory, a CPSR write with mode bits that are no mode on an ARM CPU in user mode, the 64th nested `start`, an empty address range. Each has a test in `tapi` or `thooks`.
- [x] **H3.** Memory: `memMap`, `memMapPtr`, `memUnmap`, `memProtect`, `memWrite` (bytes or string), `memRead` (into a buffer or as a `seq[byte]`), `memRegions`, `mmioMap` with closures.
- [x] **H4.** Registers: `regRead(reg): uint64`, `regWrite(reg, value)` for any integer, `regRead(reg, T)` and `regWrite(reg, value: T)` for wide ones (XMM, YMM, ZMM, the 10-byte x87 registers, `uc_x86_mmr`), `regRead(reg, value)` for the registers selected by a struct (`uc_x86_msr`, the ARM coprocessor registers), `msrRead` and `msrWrite`, `regReadBatch` and `regWriteBatch`. Every form takes the register enum or, for ids computed at run time, the number as a `cint` ("a register is also named by its number, in every form").
- [x] **H5.** Hooks as closures, kept alive by the engine, with the callback last and the range as a `Slice[uint64]`: `onCode`, `onBlock`, `onMem`, `onMemFault`, `onInterrupt`, `onInvalidInsn`, `onSyscall`, `onSysenter`, `onPortIn`, `onPortOut`, `onCpuid`, `onSys` (ARM64), `onEdgeGenerated`, `onTcgOpcode`, `onTlbFill` (2.1), `removeHook`. An empty range is refused instead of meaning everywhere. A hook added after code has run is called for that code, from the next `start` on when it is added inside a hook; removing a TCG opcode or ARM64 system instruction hook discards the translated code that calls it. Every kind, its range and its removal are in `tests/thooks.nim` (91 tests).
- [x] **H6.** Exceptions in hooks (P0-3). A hook may call `start`, up to 63 runs inside one another and not together with an instruction count; both limits raise `UnicornError` ("start nests 63 deep and refuses the 64th", "start inside a hook and an instruction count exclude each other").
- [x] **H7.** Hook lifetime: a hook removed while callbacks run, under `start`, under `regWrite` or under a `uc_emu_start` called through the handle, is let go only when nothing runs any more; a hook that captures its own engine is collected with it by ORC's cycle collector; the README and the module documentation say to use the callback's first parameter (`tests/thooks.nim`, suites "removing hooks", "callbacks outside start" and "lifetime of the closures").
- [x] **H8.** `Context`: owning, not copyable; `saveContext`, `save`, `restore`, `regRead`, `regWrite` by enum or number, `handle`. It may outlive its engine and is refused by another one. The registers Unicorn cannot reach without the engine are refused instead of passed on (the list is in the working notes; `tests/tapi.nim` sweeps every register of every architecture). With `contextMode=` (2.1) it holds the memory too: a context is restored under the mode it was saved with, contexts with memory form a stack, and one saved without the registers refuses `regRead` and `regWrite` ("contexts with memory are a stack: restoring one ends those saved after it", "a context is restored under the contextMode it was saved with", "whatever restore accepts brings back exactly what was saved"). With Unicorn 2.1.2 loaded, which cannot restore memory, `contextMode=` refuses `UC_CTL_CONTEXT_MEMORY` ("Unicorn 2.1.2 cannot restore memory, so contextMode refuses it there"), and the tests that use such contexts are skipped.
- [x] **H9.** Control and query: `pageSize`, `pageSize=`, `cpuModel`, `cpuModel=` (a model enum or its number), `exits`, `exits=`, `clearExits`, `flushTb`, `removeCache`, `requestCache`, `timedOut`, and with 2.1 `tlbMode=`, `flushTlb`, `contextMode=`, `tcgBufferSize`. `start` takes its timeout in microseconds or as a `Duration`, and its instruction count holds for code that ran before without one.
- [x] **H10.** `--mm:refc` refuses `initUnicorn` with the reason (`tests/tguards.nim`).
- [x] **H12.** `pc` and `pc=` for every architecture and mode; `tests/tarch.nim` checks on each architecture that `pc` is the program counter register and ends where the run ends.

### Generation

- [x] **G1.** `nimble regen` runs `tools/gen.nim` (switches in `tools/gen.nims`); byte-reproducible. The `-d:useFuthark` branch, which regenerated nothing, is gone.
- [x] **G2.** Futhark 0.16.1 with `-d:nodeclguards`: C spelling, no numeric suffixes, no guards. 130 KB and 2238 lines from the 2.1.4 headers (was 166 KB and 3709 lines from 2.0.1).
- [x] **G3.** The seven hand-edited procs are regenerated as they are in C; what was worth keeping is in `raw.nim` as overloads.
- [x] **G4.** Header directory from `pkg-config --variable=includedir`.
- [x] **G5.** The flag enums as distinct types through an opir callback, with the two opaque structs declared in the prelude. Regenerating therefore needs Nim 2.4; the generated file builds with 2.0.16.
- [x] **G6.** Rename callback for `end`, `type`, `ptr`.
- [x] **G7.** `tests/tlayout.nim`: size, alignment and every field of every struct against clang's record layout and the C compiler, and the value of every enumerator of the installed headers.
- [x] **G8.** The generated file names the Unicorn version it came from (read from the header, not from pkg-config); Futhark is pinned in the nimble file; header paths are normalised; `.gitattributes` marks the file as generated; the toolchain is in the README.
- [x] **G9.** What comes from `platform.h` is dropped.

The generator refuses headers older than 2.1.4, because `raw.nim` refers to declarations up to that version.

### Linking and platforms

- [x] **L1.** Build configuration module (P0-7), with `-d:unicornLibs`, `-d:unicornVersion`, `-d:unicornCflags`, `-d:unicornNoHeaderCheck`; the header check is `private/abi_check.c`.
- [x] **L2.** `-d:unicornStatic`: the archive from pkg-config's library directory plus the libraries it needs; with `-d:unicornLibs` the archive is named there. `tests/tguards.nim`, suite "static linking", builds both and checks with `ldd` that the program does not need the shared library; it is skipped where `libunicorn.a` is not installed.
- [x] **L3.** Cross compilation through `-d:unicornLibs`, `-d:unicornVersion`, `-d:unicornCflags`; MinGW recipe in the README. The tests that need no host tools pass under Wine as 64-bit and 32-bit Windows programs against Unicorn 2.1.4.
- [x] **L4.** i386 Linux, against Unicorn 2.0.1 and 2.1.4: `tapi`, `thooks`, `tarch`, `traw` and `tmacros` pass there. `tests/tlayout.nim` and `tests/tmacros.nim` compile their C side with `-m32` when they are built for i386.

### Tests

- [x] **T1.** `tests/` with 303 tests in seven files; `nimble test` runs them.
- [x] **T2.** `tests/tarch.nim`: x86 16 and 32 bit, ARM and Thumb in both byte orders, Cortex-M, ARM64, MIPS 32 and 64 in both byte orders, SPARC, PowerPC, m68k, RISC-V 32 and 64, S390x, TriCore, each with its program counter; what the library was built without is skipped.
- [x] **T3.** `tests/thooks.nim`: every kind, ranges, hooks and translated code, removal, removal from inside, exceptions, callbacks outside `start`, nested `start`, the capture cycle of H7, memory-mapped I/O.
- [x] **T4.** `tests/tguards.nim`: with a fake pkg-config, a missing Unicorn, 1.0.3, 3.0.0, explicit flags without a version, a version that contradicts pkg-config; with doctored headers, another version, another layout, a `unicorn.pc` one patch level behind for the two releases that ship so and for any other, headers of a later 2.x with and without a changed layout; a function newer than the library; the `--mm:refc` refusal; at run time an older library refused and a newer one opened; static linking.
- [x] **T5.** Layout, enum values and hand-written macros against the installed headers (G7, R8).
- [x] **T6.** The suite and the examples are clean under valgrind and under ASan with UBSan. This is a manual check; valgrind needs `-d:useMalloc`, and `--leak-check=full --errors-for-leak-kinds=definite --error-exitcode=9` makes a leak fail the run.
- [x] **T7.** The README says to run the suite against 2.0.1 and 2.1.4 before a release.

### Repository

- [x] **Y1.** README, with the GPLv2 note. `LICENSE` is MIT, "Copyright (c) 2024 m4ul3r": check the holder and year.
- [x] **Y2.** Tags: `v0.1.0` on the head before this work, `v0.2.0` on the merged result. 0.2.0 breaks source compatibility with 0.1.0: nothing is `discardable`; `uc_mode`, `uc_prot` and `uc_hook_type` are distinct types that combine with `or`, and the type names `enum_uc_mode`, `enum_uc_prot` and `enum_uc_hook_type` are gone; the field `endfield` is `last`, and the parameters `type`, `end` and `ptr` are `kind`, `last` and `host`; `uc_hook_add` takes a callback of the type that belongs to the hook type; every C callback type is `raises: []`, so a callback that can raise does not compile, also for `uc_mmio_map`; the enums are those of Unicorn 2.1.4, so a `case` that named every member of an enum in 0.1.0 misses the new ones (`UC_ERR_OVERFLOW`, registers, CPU models, controls); `CPTR` and the `MSC_VER_*` constants are gone and `PTR` is deprecated; `$` prints C names; the module `libunicorn_generated` is `libunicorn/gen_v2`. Two changes show only at run time: `uc_hook_add` answers `UC_ERR_HOOK` for a hook type that does not belong to the callback type, which 0.1.0 accepted (a memory callback without a result on `UC_HOOK_MEM_READ_UNMAPPED`, for example), and `uc_open` answers `UC_ERR_VERSION` for a library older than the one the program was built against.
- [x] **Y3.** Layout as in libcapstone-nim.
- [x] **Y4.** Nimble file: tasks `examples`, `trace`, `docs`, `regen`; `foreignDep` hints; version 0.2.0.
- [x] **Y5.** `.gitignore`.
- [x] **Y6.** The stray `os` import and the generated file's own imports and warning switches went with the old generated file.

### Examples

- [x] **X1 to X5.** `sample_x86.nim` and `sample_arm64.nim` are replaced by `basic.nim` (fourteen architectures and modes through the Nim API, one table), `hooks.nim` (closures, a fault handler that maps memory, system calls, an exception out of a hook), `raw_api.nim` (Unicorn's x86-64 and ARM64 samples through the C API, with `{.cdecl.}` callbacks of the right types, `uint64` registers, every result checked and an exit status; a part whose architecture the library lacks is skipped) and `trace.nim` (single-stepping with libcapstone 0.2.0 disassembling). The bugs listed in the audit went with the rewrite.

## Verification

Last full run, on the final tree. The rows down to the one that fails are one run of 43 configurations, of which 42 pass. Each builds and runs the seven test files (303 tests) and the four examples; where Unicorn is built with every architecture, the output of the examples is compared byte for byte with reference output. A test is skipped where the library lacks what it needs. Against 2.0.1 the 15 are the tests of what Unicorn 2.1 added, those of 64-bit MIPS, which stops at its first instruction before 2.1.3, and the one for a missing architecture; that last one is the single skip against 2.1.4. A reduced build of Unicorn skips more.

| Configuration | Tests | Examples |
|---|---|---|
| Nim 2.4.2, Unicorn 2.0.1 (Ubuntu 24.04's package): default, `--mm:arc`, `-d:release`, `-d:danger`, `nim cpp`, clang, `-d:unicornStatic` | 288 pass, 15 skipped; one more is skipped with `--mm:arc` (it needs the cycle collector) and with `-d:danger` (it needs bounds checks) | same output in every configuration |
| Nim 2.2.10 (`nim c`, `nim cpp`) and 2.0.16 (`nim c`, `nim cpp`, `--mm:arc -d:release`), Unicorn 2.0.1 | 288; 287 with `--mm:arc` | same |
| Nim 2.4.2, Unicorn 2.1.4 built from source: the same seven configurations | 302 pass, 1 skipped; 301 with `--mm:arc` and with `-d:danger` | same as on 2.0.1 |
| Nim 2.2.10 (`nim c`) and 2.0.16 (`nim c`, `nim cpp`), Unicorn 2.1.4 | 302 | same |
| `--mm:refc`, Nim 2.4.2, Unicorn 2.0.1 and 2.1.4 | the C API tests (`traw`, `tmacros`, `tlayout`, `tguards`): 112 and 115 | `raw_api` |
| Nim 2.4.2, Unicorn 2.0.0, 2.0.1.post1, 2.1.0, 2.1.1 and 2.1.3 built from source | 288, 288, 299, 299, 302 | same |
| Nim 2.4.2, the releases 2.0.1 and 2.1.2 as tagged, whose pkg-config file is one patch level behind (builds with x86, ARM, ARM64 and MIPS only) | 280 and 286 | run, not compared |
| 32-bit x86 Linux against x86-only builds: Nim 2.4.2 with Unicorn 2.0.1 and 2.1.4, Nim 2.0.16 with 2.1.4 | `tapi`, `thooks`, `tarch`, `traw`: 211, 222, 222 | `basic`, `hooks`, `raw_api` |
| `tmacros` on 32-bit x86 Linux, Nim 2.4.2, Unicorn 2.0.1 and 2.1.4 | 24 pass, 1 skipped (the ARM page size; these builds have x86 only) | |
| valgrind: Nim 2.4.2 with Unicorn 2.0.1 and 2.1.4 (ORC, and ARC with 2.1.4), Nim 2.0.16 with 2.0.1 | clean | clean |
| ASan with UBSan: Nim 2.4.2 with Unicorn 2.0.1 and 2.1.4 | clean | clean |
| MinGW cross build for 64-bit and 32-bit Windows against a static Unicorn 2.1.4, under Wine | `tapi`, `thooks`, `tarch`, `traw`: 239 and 222 | `basic`, `hooks`, `raw_api` |
| MinGW cross build for 32-bit Windows against Unicorn 2.0.1.post1, under Wine | **fails**: the four test programs crash when they open their second engine. Unicorn 2.0.x on Windows frees aligned memory with `VirtualFree`; 2.1.0 fixed it (see "Open") | run |
| `nimble check`, `nimble test`, `nimble examples`, `nimble trace`, `nimble docs`, `nimble install` then use from another project, in an isolated nimble directory, against Unicorn 2.0.1 and 2.1.4 | pass | same output against both |
| `nimble regen` against Unicorn 2.1.4 | reproduces `gen_v2.nim` byte for byte; against the 2.0.1 headers it refuses, as it should | |
| The four Nim programs of the README, their output compared with the comments: Nim 2.4.2, 2.2.10 and 2.0.16 against Unicorn 2.0.1 and 2.1.4, Nim 2.4.2 against every other release from 2.0.0 to 2.1.3 | | as printed in the README |
| Each of the eight states of the pull-request stack on its own: built and tested with Nim 2.4.2, Nim 2.0.16 and `nim cpp`, and `nimble test`, against Unicorn 2.0.1 and 2.1.4 | pass | |

Checked once during the work, on the files as they then were, and not repeated on the final tree: all 45 function declarations and the 15 callback types against the headers of every release from 2.0.0 to 2.1.4 and against the places where Unicorn calls them; every register of every architecture read and written at 28 sizes under valgrind, through engines and through contexts, on Unicorn 2.0.0, 2.0.1, 2.1.0, 2.1.1, 2.1.3 and 2.1.4; 29 deliberate faults put into the Nim API, each caught by a test.

Not covered by any run: macOS, native Windows (Wine only), hosts other than x86, big-endian hosts, 64-bit Windows with Unicorn 2.0.x, `nim cpp` for 32-bit targets.

## Working notes

- To test against another Unicorn: `PKG_CONFIG_PATH=<prefix>/lib/pkgconfig LD_LIBRARY_PATH=<prefix>/lib nimble test`.
- pkg-config reports 2.0.1 for Unicorn 2.0.1.post1, and so does `uc_version()`. The tags 2.0.1 and 2.1.2 report 2.0.0 and 2.1.1 through pkg-config and their real version through `uc_version()`.
- Ubuntu's `unicorn.pc` prints nothing for `--cflags-only-I`, because `/usr/include` is a default directory. The generator therefore asks for `--variable=includedir`.
- Binaries on Ubuntu are linked with immediate binding. A program that refers to `uc_reg_read2` and meets a 2.0 library is stopped by the loader (`undefined symbol`) before `uc_open` can refuse; linked with `-Wl,-z,lazy` it starts and gets `UC_ERR_VERSION` from `uc_open`. Both are safe.
- Unicorn finishes setting an engine up the first time it is used, and reading the CPU model counts. `cpuModel=`, `pageSize=` and `tcgBufferSize=` have to come directly after `initUnicorn`.
- The ARM mode bits `UC_MODE_MCLASS`, `UC_MODE_ARM926`, `UC_MODE_ARM946` and `UC_MODE_ARM1176` each select a CPU model and win over `cpuModel=`: an engine opened with `UC_MODE_MCLASS` is a Cortex-M33 whatever was set.
- The default page size is 1 KiB on ARM and ARM64 and 16 KiB on TriCore, 4 KiB elsewhere.
- `uc_ctl_set_page_size` sets twice the size it is given before Unicorn 2.1.2; `pageSize=` corrects for that, the C API does not. ARM64 takes a page size from 2.1.2 on.
- Unicorn 2.0.0 refuses CPU model 0, the first member of every model enum, in `uc_ctl_set_cpu_model`.
- Unicorn compiles the call of a lone code or block hook into the translated block and goes on calling it after `uc_hook_del` until the block ends (2.0.1, 2.1.4). The Nim API marks a removed hook and ignores such calls.
- Translated code keeps the hooks it was translated with. A code, block, TCG opcode or system instruction hook added later is not called for code that has run before, with the C API alone; the Nim API discards the translations at the next `start`. For TCG opcode and ARM64 system instruction hooks the translated code holds the address of Unicorn's own record of the hook, which Unicorn frees at the end of the next run after `uc_hook_del`: later runs then read freed memory (valgrind, 2.0.1 and 2.1.4, also with the C API alone). The Nim API therefore flushes all translations when such a hook is removed, which costs 184 ms on 2.0.1 and 69 microseconds on 2.1.4; code and memory hooks cost 1 microsecond.
- `uc_ctl_flush_tb` from inside a hook hangs Unicorn 2.1.4 and segfaults 2.0.1; `uc_ctl_remove_cache` works there. `flushTb` raises inside a hook.
- A run with an instruction count ignores the count for code that ran before without one: Unicorn installs its counter without discarding the old translations (C API alone, 2.0.0, 2.0.1, 2.1.0, 2.1.4). `start` discards them when a counted run follows an uncounted one.
- `uc_emu_start` nests 63 deep; the 64th call segfaults (2.0.1, 2.1.4, also with the C API alone). Unicorn has one instruction counter for all the runs and discards the translated code under an outer run when an inner one has no count, so that the outer run ends in the wrong place or crashes. `start` refuses the 64th level and any nesting together with a count.
- Contexts with memory (`UC_CTL_CONTEXT_MEMORY`, Unicorn 2.1) are kept by Unicorn as a stack of snapshots. Restoring one saved before a later one and then the later one writes into freed memory and segfaults on 2.1.3 and 2.1.4 and brings back wrong memory on 2.1.0 and 2.1.1; restoring a context saved before memory was asked for segfaults on 2.1.3 and 2.1.4; with memory alone the registers of a context are uninitialised. The Nim API keeps the stack itself and refuses what does not fit.
- Unicorn 2.1.2 cannot restore a context with memory at all: `uc_context_restore` first drops the pages written since the save and then copies a memory map that still names them (valgrind, C API alone: an invalid read in `address_space_dispatch_clear` under `flatview_copy`, of a block freed by `memory_region_filter_subregions` in the same call). A single restore brings back the right bytes by luck; one after another ends in a double free. 2.1.3 turned the two steps around, 2.1.0 and 2.1.1 have no such copy. Both steps are inside one call, so there is no way around it through the C API; `contextMode=` refuses memory when the loaded library is exactly 2.1.2.
- Reading `UC_SPARC_REG_PSR` of a fresh 32-bit SPARC engine segfaults Unicorn 2.1.4. Writing an x86 segment register with the descriptor table in unmapped memory segfaults 2.0.1 (2.1.4 answers `UC_ERR_EXCEPTION`), and through a context it segfaults both. Writing mode bits that are no mode to the CPSR of an ARM CPU in user mode aborts (2.0.1, 2.1.4). `uc_ctl_request_cache` for an address that is unmapped, not executable or whose block runs off the mapping segfaults 2.0.1 and returns nonsense elsewhere.
- Unicorn 2.1.0 and 2.1.1 answer `UC_ERR_ARG` for the SPARC registers `%i0` to `%i7` and still write four bytes at the variable, whatever size `uc_reg_read2` was given.
- `uc_ctl_set_page_size` takes sizes that kill the process later (ARM): 2 aborts in `uc_mem_map` on 2.0.1 and segfaults in `uc_emu_start` on 2.1.4; 2^27 and more abort on 2.0.1 and leave mapped memory unreadable on 2.1.4; 1 becomes 1024. `pageSize=` takes powers of two from 1024 to 2^26.
- Setting the program counter inside a hook makes the emulation go on there, except for 16-bit x86 with Unicorn 2.0, which goes on where it was.
- A `uc_hook_add` that Unicorn refuses with `UC_ERR_HOOK` (an instruction of another architecture, both TCG opcode flags on x86) leaks memory in Unicorn (2.0.1, 2.1.4), and on ARM64 Unicorn accepts x86 instruction hooks without a word. The Nim API checks the architecture and the flags first; the typed `uc_hook_add` checks hook type and instruction, not the architecture. ARM, ARM64 and MIPS accept the two TCG opcode flags together.
- `uc_reg_write2` of Unicorn 2.1.4 loses a program counter written from inside a hook: the emulation then loops on the same instruction. The batch write has the same fault. Inside a callback the Nim API therefore follows the `uc_reg_write2` of a program counter register, which checks the size, with a `uc_reg_write`, and its batch access loops over the single one.
- A `UC_HOOK_MEM_FETCH` hook is accepted and never called: 2.0.1 and 2.1.4 have no call site for it.
- Before Unicorn 2.1.2 a `UC_HOOK_MEM_READ_AFTER` hook without a `UC_HOOK_MEM_READ` hook for the same addresses is called only for the first access to a page: a read that follows another read or a write there is missed (measured on 2.0.0, 2.0.1, 2.1.0, 2.1.1; 2.1.2 to 2.1.4 report every read). `tests/traw.nim` reads a page once, which every version reports; `tests/thooks.nim` has the test that branches on the version.
- After a hook repairs a write-protection fault the emulation goes on, but whether the write that faulted is carried out is not dependable: one test program saw 2.0.x perform it and 2.1.x drop it, and another (C API, a hook that calls `uc_mem_protect`) saw it dropped by every version from 2.0.0 to 2.1.4.
- `uc_mem_write` does not discard translated code; after patching code that has run, call `uc_ctl_remove_cache` or `removeCache`.
- Memory-mapped I/O: an 8-byte access arrives as two of 4 bytes. A region without a callback lacks that permission. Restoring a context that holds memory maps an unmapped MMIO range again, callbacks included, which is why the Nim API keeps the closures of `mmioMap` until the engine closes.
- For some registers `uc_context_reg_read` and `uc_context_reg_write` reach for the engine, not the context, and touch memory that is not the context's (seen under valgrind on 2.0.0 to 2.1.4 by reading and writing every register of every architecture). The Nim API refuses those on a `Context`; the C API passes them through as C does. The list: x86 MSR, and for writing CR0, CR3, CR4 and the six segment registers, which are loaded from the descriptor table in the engine's memory; ARM CP_REG, and PC, FPSCR, CONTROL for writing; ARM64 CP_REG, and FPCR, FPSR for writing; M68K SR and CR_CACR for writing; PowerPC FPSCR for writing; every RISC-V CSR; the SPARC window registers, PSR for reading, and on SPARC64 also G0 to G7 and PC.
- A timeout that runs out before the CPU loop has started is lost: 1 microsecond on an endless loop hung under valgrind (2.0.1).
- After `stop` or an exception in a hook, a code hook ends the run at once; after other kinds (a port hook was seen) the rest of the block still runs.
- A `UC_ARM64_INS_SYSL` hook that returns non-zero on an unallocated encoding is called without end (2.0.1, 2.1.4).
- TCG opcode hooks report an operand size of 32 on 32-bit hosts.
- The ZMM registers exist from Unicorn 2.1.2 on.
- Leaks that are Unicorn's, seen under valgrind: SPARC64 engines leak on close in every version, 2.0.0 also for TriCore and PowerPC, and 2.1.0 and 2.1.1 leak an array per engine.
- The compiler's message for a forbidden copy of a `Unicorn` or `Context` is Nim's own ("'=copy' is not available for type <Unicorn>; requires a copy because it's not the last read of ..."), not the text of the `{.error.}` pragma.
- `gorgeEx` and `staticExec` return nothing under `nim check` and nimsuggest; `nim c --compileOnly` does run them. Hence the branch for those two in `private/config.nim`.
- A `{.compileTime.}` proc called with literal arguments inside another proc is evaluated when that proc is defined, called or not. A pkg-config query hidden in a helper therefore runs in every build.
- An explicit `` `=destroy`(x.table) `` on a `Table` field does not compile. The C handle has a small owning type of its own and the rest is destroyed by default.
- `compiles(...)` cannot see a copy that `=copy {.error.}` forbids, so no test can assert that a `Unicorn` is not copyable.
- `cast[SomeRef](pointer)` assigned to a variable makes a counted copy; the trampolines rely on it.
- Under `nim cpp`, ASan reports a 30-byte leak for a caught `IndexDefect`. A six-line program without Unicorn does the same; it is Nim's.
- ORC keeps one 16 KB block in use at exit under valgrind; that is not a leak.
- `nimble --version` already rewrites `nimbledata2.json` in the nimble directory, and `--nimbleDir` does not isolate nimble. For an isolated run set `XDG_CONFIG_HOME=<scratch>/xdg` with `<scratch>/xdg/nimble/nimble.ini` containing `nimbleDir = r"<scratch>/nimble"` before the first nimble call of any kind.
- Futhark's `opir` writes `imports-<pid>.h` into the temp directory and leaves it there when parsing fails; set `TMPDIR`.
- Regenerating with Nim 2.2.10 or 2.0.16 fails in Futhark with "cannot get child of node kind: nnkSym".
- Unicorn's CMake detects the host from the compiler's predefined macros and ignores `-m32` in `CMAKE_C_FLAGS`; a 32-bit build needs a wrapper compiler.
- Building a Unicorn release to test against needs no root: `git worktree add --detach <dir> <tag>` in a clone of Unicorn, then `cmake -S <dir> -B <build> -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=<prefix> -DCMAKE_INSTALL_LIBDIR=lib -DUNICORN_BUILD_TESTS=OFF` and `ninja -C <build> install`. Ubuntu's packages can be unpacked into a prefix with `apt-get download libunicorn-dev libunicorn2t64` and `dpkg -x`.
