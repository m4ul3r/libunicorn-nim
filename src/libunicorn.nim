## Nim bindings for the `Unicorn <https://www.unicorn-engine.org>`_ CPU
## emulator.
##
## This module exports two layers:
##
## * the C API under its C names (`uc_open`, `uc_emu_start`, `UC_ARCH_X86`,
##   ...), from `libunicorn/raw <libunicorn/raw.html>`_;
## * a small Nim API on top of it: a `Unicorn` object that closes itself,
##   memory through `openArray[byte]`, registers by value with their size
##   checked, hooks as closures, and exceptions instead of error codes.
##
## The Nim API needs `--mm:orc` or `--mm:arc` (the default). The C API works
## with any memory manager.
##
## Hooks
## =====
##
## A hook is a closure; the engine keeps it alive until the hook is removed or
## the engine is closed. Its first parameter is the engine it runs in. Use that
## parameter rather than capturing the engine variable: a hook that captures
## its own engine forms a cycle, and the engine is then closed by ORC's cycle
## collector at some later time, and never under `--mm:arc`.
##
## An exception raised in a hook stops the emulation and is raised again by
## the `start` that ran the hook; the engine stays usable. That includes a
## `Defect`, unless the program is built with `--panics:on`, where a defect
## ends the program wherever it is raised. The emulation stops the way `stop`
## stops it: after a code hook nothing else runs, after other kinds Unicorn
## may finish the current basic block.
##
## Threads
## =======
##
## An engine belongs to one thread at a time. The exception is `stop`, which
## may be called from another thread while `start` runs.

runnableExamples:
  let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  uc.memMap(0x1000, 0x1000)
  uc.memWrite(0x1000, [0x48'u8, 0xff, 0xc0, 0x48, 0x01, 0xc3])  # inc rax; add rbx, rax
  uc.regWrite(UC_X86_REG_RAX, 41)
  var trace: seq[uint64]
  discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
    trace.add address
  uc.start(0x1000, 0x1006)
  doAssert uc.regRead(UC_X86_REG_RBX) == 42
  doAssert trace == @[0x1000'u64, 0x1003]
  doAssert uc.pc == 0x1006

import libunicorn/raw
export raw

when defined(gcDestructors):
  import std/[tables, times, typetraits]

  type
    UnicornError* = object of CatchableError
      ## A Unicorn call failed, or the Nim API was given something Unicorn
      ## would not have refused. `code` is Unicorn's error code.
      code*: uc_err

    HookId* = distinct uc_hook
      ## Names a hook for `removeHook`.

    HookObj = object of RootObj
      st: ptr EngineStateObj     # not counted: the engine owns its hooks
      removed: bool              # by `removeHook`; Unicorn may still call it for a while
      compiled: bool             # translated code holds the address of Unicorn's record of it
    Hook = ref HookObj

    HookRec[Callback] = object of HookObj
      ## What a C callback gets as `user_data`.
      cb: Callback

    Handle = object
      ## Owns the C handle; a type of its own so that the rest of the state
      ## needs no hand-written destructor.
      p: ptr uc_engine

    Identity = ref object
      ## Tells engines apart for as long as something refers to them; unlike
      ## an address it is not handed out again.

    EngineStateObj = object
      ## Lives on the heap so that its address stays put when the `Unicorn`
      ## value moves; the C callbacks point here. A traced `ref`, so that the
      ## cycle collector can still reclaim an engine that one of its own
      ## hooks has captured.
      handle: Handle             # first: closed before the closures are freed
      hooks: Table[uc_hook, Hook]
      mmio: seq[Hook]            # closures of `mmioMap`; kept until the engine closes
      retired: seq[Hook]         # removed while callbacks can run; freed afterwards
      pending: ref Exception     # raised in a callback, re-raised by the call that ran it
      busy: int                  # calls into Unicorn made here, plus callbacks that run
      callbacks: int             # callbacks that run
      runs: int                  # nesting of `start`
      counted: int               # how many of them have an instruction count
      counting: bool             # the last `start` had one: Unicorn's counter is installed
      direct: bool               # the innermost call into Unicorn is not an emulation
      stale: bool                # translated code does not match the hooks; see `settle`
      dangling: bool             # and holds the address of a record that Unicorn frees
      pcSlips: bool              # this Unicorn has the program counter defect of 2.1.4
      content: set[uc_context_content]   # what `contextMode=` asked for
      snapshots: seq[int]        # the contexts with memory that can still be restored
      lastSnapshot: int
      arch: uc_arch
      mode: uc_mode
      identity: Identity

    EngineState = ref EngineStateObj

    Unicorn* = object
      ## An emulator for one architecture and mode. It is closed when it goes
      ## out of scope, and it cannot be copied, only moved.
      st: EngineState

    ContextStore = object
      ## Owns the `uc_context`.
      p: ptr uc_context

    Context* = object
      ## A saved CPU state: the registers, and with `contextMode=` the memory
      ## as well. It owns its storage, cannot be copied, and may outlive the
      ## engine it was saved from: its registers can still be read and
      ## written then. It can only be restored into that engine.
      store: ContextStore
      engine: Identity           # of the engine that saved it
      content: set[uc_context_content]   # what it holds
      snapshot: int              # names its memory among the engine's `snapshots`
      arch: uc_arch
      mode: uc_mode

    MemRegion* = tuple[first, last: uint64; perms: uc_prot]
      ## A mapped range; `last` is the address of its last byte.

    CodeCallback* = proc (uc: Unicorn; address: uint64; size: int) {.closure.}
      ## `onCode`: the instruction at `address`, `size` bytes long, is about
      ## to run. `onBlock`: so is the basic block at `address`.
    MemCallback* = proc (uc: Unicorn; kind: uc_mem_type; address: uint64; size: int;
                         value: int64) {.closure.}
      ## `size` bytes at `address` are being accessed. `value` is what is
      ## written, or with `UC_MEM_READ_AFTER` what was read; 0 otherwise.
    MemFaultCallback* = proc (uc: Unicorn; kind: uc_mem_type; address: uint64; size: int;
                              value: int64): bool {.closure.}
      ## Returns true when the fault has been repaired (for example by mapping
      ## the page) and the access is to be tried again; false lets `start`
      ## fail.
    InterruptCallback* = proc (uc: Unicorn; number: uint32) {.closure.}
      ## An interrupt or exception with this number was raised.
    InsnCallback* = proc (uc: Unicorn) {.closure.}
      ## `onSyscall`, `onSysenter`: the instruction is being executed.
    InvalidInsnCallback* = proc (uc: Unicorn): bool {.closure.}
      ## Returns true when the callback has dealt with the instruction (for
      ## example by moving `pc` past it) and the emulation is to go on; false
      ## lets `start` fail with `UC_ERR_INSN_INVALID`.
    PortInCallback* = proc (uc: Unicorn; port: uint32; size: int): uint32 {.closure.}
      ## Returns what a read of `size` bytes (1, 2 or 4) from `port` delivers.
    PortOutCallback* = proc (uc: Unicorn; port: uint32; size: int; value: uint32) {.closure.}
      ## `value`, `size` bytes wide (1, 2 or 4), is written to `port`.
    CpuidCallback* = proc (uc: Unicorn): bool {.closure.}
      ## Returns true when the callback has set EAX, EBX, ECX and EDX itself:
      ## the instruction is then skipped. False lets Unicorn execute it.
    SysCallback* = proc (uc: Unicorn; reg: uc_arm64_reg; cpReg: uc_arm64_cp_reg): bool {.closure.}
      ## `reg` is the general register of the instruction, `cpReg` the system
      ## register it names, with the value of `reg` in `val`. Returns true to
      ## skip the instruction (the callback then does whatever it stands
      ## for); false lets Unicorn execute it.
    EdgeCallback* = proc (uc: Unicorn; current, previous: uc_tb) {.closure.}
      ## The block `current` has been translated; `previous` is the block
      ## Unicorn ran before it.
    TcgOpcodeCallback* = proc (uc: Unicorn; address, arg1, arg2: uint64; size: int) {.closure.}
      ## The instruction at `address` is about to compute with the operands
      ## `arg1` and `arg2`, `size` bits wide.
    TlbFillCallback* = proc (uc: Unicorn; address: uint64; kind: uc_mem_type;
                             entry: var uc_tlb_entry): bool {.closure.}
      ## Translates the page at the virtual `address` for an access of `kind`
      ## (`UC_MEM_READ`, `UC_MEM_WRITE` or `UC_MEM_FETCH`): sets `entry.paddr`
      ## and `entry.perms` and returns true. False means there is no such
      ## page; when no callback returns true the access faults.
    MmioReadCallback* = proc (uc: Unicorn; offset: uint64; size: int): uint64 {.closure.}
      ## Returns what a read of `size` bytes at `offset` into the range gives.
    MmioWriteCallback* = proc (uc: Unicorn; offset: uint64; size: int; value: uint64) {.closure.}
      ## `value`, `size` bytes wide, is written at `offset` into the range.

  proc raiseUnicorn(code: uc_err; message = "") {.noreturn.} =
    raise (ref UnicornError)(code: code,
                             msg: if message.len > 0: message else: $uc_strerror(code))

  template check(code: uc_err) =
    let checked = code
    if checked != UC_ERR_OK: raiseUnicorn(checked)

  func `==`*(a, b: HookId): bool =
    ## Whether both name the same hook.
    uc_hook(a) == uc_hook(b)

  # --- engine --------------------------------------------------------------

  var orphans {.threadvar.}: seq[EngineState]
    ## Engines that lost their last owner inside a callback while Unicorn was
    ## not called from here. They cannot be closed under Unicorn's feet, and
    ## nothing says when it has returned: they stay open.

  proc `=destroy`*(handle: Handle) =
    ## Closes the engine.
    if handle.p != nil: discard uc_close(handle.p)

  proc `=copy`*(dest: var Handle; source: Handle) {.error.}

  proc `=copy`*(dest: var Unicorn; source: Unicorn) {.error:
    "a Unicorn object cannot be copied; move it or pass it by reference".}

  proc initUnicorn*(arch: uc_arch; mode: uc_mode): Unicorn =
    ## Opens an emulator. Modes combine with `or`:
    ## `initUnicorn(UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_MCLASS)`.
    ##
    ## Raises `UnicornError`; with `UC_ERR_VERSION` when the Unicorn library
    ## in the process is not one this program can use (another major version,
    ## or older than the one it was built against).
    var handle: ptr uc_engine
    let err = uc_open(arch, mode, addr handle)
    let v = uc_version()
    if err == UC_ERR_VERSION and not libraryMatchesBindings():
      raiseUnicorn(err, "the loaded Unicorn library is version " & $v.major & "." & $v.minor &
        "." & $v.patch & ", but this program was built for Unicorn " & libVersionText)
    check err
    Unicorn(st: EngineState(handle: Handle(p: handle), arch: arch, mode: mode,
                            identity: Identity(), content: {UC_CTL_CONTEXT_CPU},
                            pcSlips: (v.major, v.minor, v.patch) >= (2, 1, 4)))

  func raiseNoEngine() {.noreturn, noinline.} =
    raise (ref UnicornError)(code: UC_ERR_HANDLE,
      msg: "this Unicorn object holds no engine (never opened, or moved away)")

  func state(uc: Unicorn): EngineState {.inline.} =
    ## The state, as a reference of the caller's own: an engine that loses its
    ## owner while one of its callbacks runs is closed only when the call
    ## into Unicorn has returned.
    if uc.st == nil: raiseNoEngine()
    uc.st

  func handle*(uc: Unicorn): ptr uc_engine {.inline.} =
    ## The underlying handle, for calling the C API directly. Do not close it.
    ##
    ## What is done through it is not known to the `Unicorn` object: hooks
    ## added with `uc_hook_add`, a context mode set with `uc_ctl_context_mode`.
    ## Hooks of the object do run during a `uc_emu_start` called directly; an
    ## exception one of them raises stops that emulation and is raised by the
    ## next call that goes through the object (`start`, `memRead`, `regRead`,
    ## ...). A hook must not call `start` when such a `uc_emu_start` has an
    ## instruction count: the object cannot see that and refuse it, as it
    ## does for its own runs. A hook added through the object is called for
    ## code that was translated before only after the next `start`.
    ##
    ## Three more things the object cannot see from there. An engine that
    ## loses its last owner inside one of its hooks during such a
    ## `uc_emu_start` is never closed. An `onTcgOpcode` or `onSys` hook that
    ## is removed inside a hook during such a `uc_emu_start` stays in the
    ## translated code until the next call through the object: make one (for
    ## example `uc.pc`) before the next `uc_emu_start` called directly, or
    ## Unicorn runs code that refers to its freed record of the hook. And a
    ## `start` with a count that follows such a `uc_emu_start` without one
    ## may run code that `uc_emu_start` translated without counting it.
    if uc.st == nil: raiseNoEngine()
    uc.st.handle.p

  func arch*(uc: Unicorn): uc_arch =
    ## The architecture the engine was opened for.
    uc.state.arch

  func mode*(uc: Unicorn): uc_mode =
    ## The mode the engine was opened with.
    uc.state.mode

  proc settle(st: EngineState; flush: bool) =
    ## For the moments when no callback runs and Unicorn is not on the stack:
    ## lets go of the hooks removed meanwhile, and discards translated code
    ## that does not match the hooks any more. Unicorn compiles code, block,
    ## TCG opcode and ARM64 system instruction hooks into its translations.
    ## A hook added later is not in them: they are discarded with `flush`,
    ## that is before and after a run, because `uc_ctl_flush_tb` takes a
    ## third of a second with Unicorn 2.0. A removed hook of the last two
    ## kinds stays in them as the address of a record that Unicorn frees:
    ## they are discarded at once, so that a `uc_emu_start` called directly
    ## does not run them, unless the hook was removed inside a callback;
    ## then the next call through the object does it (see `handle`). (Inside
    ## a callback `uc_ctl_flush_tb` makes Unicorn hang or crash, so all of
    ## this waits until here.)
    st.retired.setLen(0)
    if st.stale and (flush or st.dangling):
      st.stale = false
      st.dangling = false
      discard uc_ctl_flush_tb(st.handle.p)

  proc raisePending(st: EngineState; keep = false) =
    ## Raises what a callback raised. `keep`: it belongs to a call further
    ## out, which raises it again whatever the caller here does with it.
    if st.pending != nil:
      if keep: raise st.pending
      let e = move st.pending
      raise e

  template driving(uc: Unicorn; emulation: bool; call: untyped) =
    ## Makes a C call during which callbacks can run; `h` is the handle.
    ## Afterwards what a callback raised during the call is raised again.
    let st = uc.state
    let h {.inject.} = st.handle.p
    if st.busy == 0: st.settle(flush = emulation)
    # inside a callback, an exception that is still pending is the reason the
    # emulation is being stopped: every further use of the engine fails with it
    st.raisePending(keep = st.busy > 0)
    let outer = st.direct
    st.direct = not emulation
    inc st.busy
    let err = call
    dec st.busy
    st.direct = outer
    if st.busy == 0: st.settle(flush = emulation)
    st.raisePending()
    check err

  # --- memory --------------------------------------------------------------

  func toSize(size: uint64): uc_size {.inline.} =
    when sizeof(uc_size) < sizeof(uint64):
      # 32-bit target and a Unicorn older than 2.1.4: sizes are size_t there
      if size > uint64(high(uc_size)):
        raise (ref UnicornError)(code: UC_ERR_ARG,
                                 msg: "a size of " & $size & " bytes does not fit this platform")
    uc_size(size)

  proc memMap*(uc: Unicorn; address, size: uint64; perms = UC_PROT_ALL) =
    ## Maps `size` bytes of zeroed memory at `address`; both must be multiples
    ## of the page size. `pageSize` tells it: 4096 for most architectures,
    ## but for example 1024 for ARM and ARM64, 8192 for SPARC64 and 16384 for
    ## TriCore.
    check uc_mem_map(uc.handle, address, toSize(size), perms)

  proc memMapPtr*(uc: Unicorn; address, size: uint64; host: pointer; perms = UC_PROT_ALL) =
    ## Maps the `size` bytes at `host` at `address`: the emulated code works
    ## directly on that memory. Unicorn does not copy it and does not free it;
    ## the caller keeps it alive, and in place, until the range is unmapped or
    ## the engine is closed.
    check uc_mem_map_ptr(uc.handle, address, toSize(size), perms, host)

  proc memUnmap*(uc: Unicorn; address, size: uint64) =
    ## Unmaps a range, which must be mapped entirely; it may be part of a
    ## mapping or span several.
    check uc_mem_unmap(uc.handle, address, toSize(size))

  proc memProtect*(uc: Unicorn; address, size: uint64; perms: uc_prot) =
    ## Changes the permissions of a mapped range.
    check uc_mem_protect(uc.handle, address, toSize(size), perms)

  proc memWrite*(uc: Unicorn; address: uint64; data: openArray[byte]) =
    ## Copies `data` into emulated memory, whatever its permissions. Writing
    ## into a range of `mmioMap` calls its `write` closure.
    driving(uc, emulation = false): uc_mem_write(h, address, data)

  proc memWrite*(uc: Unicorn; address: uint64; data: string) =
    ## `memWrite` of the bytes of a string.
    driving(uc, emulation = false): uc_mem_write(h, address, data.toOpenArrayByte(0, data.high))

  proc memRead*(uc: Unicorn; address: uint64; into: var openArray[byte]) =
    ## Fills `into` from emulated memory. Reading a range of `mmioMap` calls
    ## its `read` closure.
    driving(uc, emulation = false): uc_mem_read(h, address, into)

  proc memRead*(uc: Unicorn; address: uint64; size: Natural): seq[byte] =
    ## `size` bytes of emulated memory.
    # A local, not `result`: Nim 2.0, and 2.2 as C++, do not free `result`
    # when the proc is left by an exception.
    var bytes = newSeq[byte](size)
    uc.memRead(address, bytes)
    bytes

  proc memRegions*(uc: Unicorn): seq[MemRegion] =
    ## The mapped ranges, in ascending order.
    var first: ptr uc_mem_region
    var count: uint32
    check uc_mem_regions(uc.handle, addr first, addr count)
    try:
      for region in regions(first, count):
        result.add (region.begin, region.last, uc_prot(region.perms))
    finally:
      discard uc_free(first)

  # --- registers -----------------------------------------------------------
  #
  # C: uc_reg_read(uc, regid, void *value) writes as many bytes as the register
  # is wide, whatever `value` points to. Here every access says how much room
  # there is. Unicorn 2.1 takes that size and answers UC_ERR_OVERFLOW; Unicorn
  # 2.0 cannot be told. Either way Unicorn only ever writes into a buffer that
  # holds any register: Unicorn 2.1.0 and 2.1.1 ignore the size for some
  # registers (SPARC %i0 to %i7).

  const maxRegisterSize = 64   # ZMM, the widest register Unicorn has

  template registerAccess(Target: typedesc; readProc, writeProc, read2, write2, read1,
                          write1: untyped) =
    proc readProc(target: Target; reg: cint; value: pointer; size: int): uc_err =
      ## Reads into the `size` bytes at `value`, and never beyond them. What
      ## is there on entry is input for the registers that take some.
      var scratch: array[maxRegisterSize, byte]
      copyMem(addr scratch, value, size)
      when libVersion >= (2, 1, 0):
        var room = csize_t(size)
        result = read2(target, reg, addr scratch, addr room)
      else:
        result = read1(target, reg, addr scratch)
      if result == UC_ERR_OK: copyMem(value, addr scratch, size)

    proc writeProc(target: Target; reg: cint; value: pointer; size: int): uc_err =
      ## Writes from the `size` bytes at `value`; nothing beyond them is read.
      when libVersion >= (2, 1, 0):
        var room = csize_t(size)
        result = write2(target, reg, value, addr room)
      else:
        var scratch: array[maxRegisterSize, byte]
        copyMem(addr scratch, value, size)
        result = write1(target, reg, addr scratch)

  registerAccess(ptr uc_engine, readRegister, writeRegister,
                 uc_reg_read2, uc_reg_write2, uc_reg_read, uc_reg_write)
  registerAccess(ptr uc_context, readRegister, writeRegister,
                 uc_context_reg_read2, uc_context_reg_write2,
                 uc_context_reg_read, uc_context_reg_write)

  template plainData(T: typedesc) =
    when not supportsCopyMem(T) or (T is ptr) or (T is pointer) or (T is cstring) or
        (T is proc):
      {.error: "a register is read and written as plain bytes; " & $T & " is not plain data".}
    when sizeof(T) > maxRegisterSize:
      {.error: "no register is as large as " & $T.}

  func widened[T: SomeInteger](value: T): uint64 {.inline.} =
    when T is SomeSignedInt: cast[uint64](int64(value))
    else: uint64(value)

  func programCounter(arch: uc_arch): cint =
    ## The register that is the program counter; for x86 the widest one.
    let reg = case arch
      of UC_ARCH_X86: ord(UC_X86_REG_RIP)
      of UC_ARCH_ARM: ord(UC_ARM_REG_PC)
      of UC_ARCH_ARM64: ord(UC_ARM64_REG_PC)
      of UC_ARCH_MIPS: ord(UC_MIPS_REG_PC)
      of UC_ARCH_PPC: ord(UC_PPC_REG_PC)
      of UC_ARCH_SPARC: ord(UC_SPARC_REG_PC)
      of UC_ARCH_M68K: ord(UC_M68K_REG_PC)
      of UC_ARCH_RISCV: ord(UC_RISCV_REG_PC)
      of UC_ARCH_S390X: ord(UC_S390X_REG_PC)
      of UC_ARCH_TRICORE: ord(UC_TRICORE_REG_PC)
      else: 0
    cint(reg)

  func setsProgramCounter(arch: uc_arch; reg: cint): bool =
    ## The registers for which Unicorn's `reg_write` reports a new program
    ## counter (`*setpc = 1` in `qemu/target/*/unicorn*.c`).
    reg == programCounter(arch) or
      (arch == UC_ARCH_X86 and
        (reg == cint(ord(UC_X86_REG_EIP)) or reg == cint(ord(UC_X86_REG_IP))))

  const armModes = {0x10, 0x11, 0x12, 0x13, 0x16, 0x17, 0x1a, 0x1b, 0x1f}

  proc checkCpsr(arch: uc_arch; reg: cint; current: uint32; value: pointer) =
    ## Unicorn aborts the process when the CPSR of an ARM CPU in user mode is
    ## given mode bits that are no mode (in other modes it ignores them).
    ## Observed with Unicorn 2.0.1 and 2.1.4, engine and context alike, also
    ## for M-profile CPUs.
    if arch == UC_ARCH_ARM and reg == cint(ord(UC_ARM_REG_CPSR)) and (current and 0x1f) == 0x10:
      let wanted = int(cast[ptr byte](value)[] and 0x1f)   # the low byte comes first
      if wanted notin armModes:
        raiseUnicorn(UC_ERR_ARG, "CPSR cannot take the mode bits " & $wanted &
          " while the CPU is in user mode: they are no ARM mode")

  proc readInto(uc: Unicorn; reg: cint; value: pointer; size: int) =
    driving(uc, emulation = false): readRegister(h, reg, value, size)

  proc writeFrom(uc: Unicorn; reg: cint; value: pointer; size: int) =
    let state = uc.state
    if state.arch == UC_ARCH_ARM and reg == cint(ord(UC_ARM_REG_CPSR)):
      var current: uint32
      if readRegister(state.handle.p, reg, addr current, sizeof(current)) == UC_ERR_OK:
        checkCpsr(state.arch, reg, current, value)
    driving(uc, emulation = false):
      block:
        var err = writeRegister(h, reg, value, size)
        when libVersion >= (2, 1, 0):
          # Unicorn 2.1.4 forgets a program counter that uc_reg_write2 sets
          # while a hook runs: at the end of the block it puts the old one
          # back, which uc_reg_write tells it not to (`skip_sync_pc_on_exit`,
          # new in 2.1.4, only there). So the write is repeated with
          # uc_reg_write: for the registers that set the program counter, in
          # a callback, with that library. Outside a callback nothing
          # executes that could put the old value back. The write above has
          # shown that the value is as large as the register.
          if err == UC_ERR_OK and state.pcSlips and state.callbacks > 0 and
              setsProgramCounter(state.arch, reg):
            err = uc_reg_write(h, reg, value)
        err

  proc regRead*[Reg: enum | cint](uc: Unicorn; reg: Reg): uint64 =
    ## A register of up to 64 bits; narrower ones are zero-extended. `reg` is
    ## a member of the architecture's register enum, or for an id computed at
    ## run time its number as a `cint`: `uc.regRead(cint(ord(UC_X86_REG_RAX)))`.
    ##
    ## A wider register is not truncated silently: a program built for
    ## Unicorn 2.1 gets `UnicornError` with `UC_ERR_OVERFLOW`. Unicorn 2.0
    ## cannot tell and yields the low 64 bits; in neither case is anything
    ## overwritten.
    ##
    ## On a big-endian host use the form with a type of exactly the
    ## register's size.
    ##
    ## Unicorn 2.1.4 crashes when `UC_SPARC_REG_PSR` of a 32-bit SPARC engine
    ## is read before the engine has computed condition codes or the
    ## register has been written.
    readInto(uc, cint(ord(reg)), addr result, sizeof(result))

  proc regRead*[Reg: enum | cint; T](uc: Unicorn; reg: Reg; _: typedesc[T]): T =
    ## The register as a `T`, for the ones that are not a number of up to 64
    ## bits: `uc.regRead(UC_X86_REG_XMM0, array[16, byte])`,
    ## `uc.regRead(UC_X86_REG_ST0, array[10, byte])`,
    ## `uc.regRead(UC_X86_REG_GDTR, uc_x86_mmr)`.
    ##
    ## A `T` smaller than the register is never overrun: see the plain form
    ## for what happens instead. A larger `T` is zero in the part the
    ## register does not fill. `T` must be plain data without pointers; one
    ## that is a pointer, a `cstring` or a proc, or that holds a `ref`, a
    ## `string` or a `seq`, does not compile.
    plainData(T)
    readInto(uc, cint(ord(reg)), addr result, sizeof(T))

  proc regRead*[Reg: enum | cint; T](uc: Unicorn; reg: Reg; value: var T) =
    ## Reads into `value`, for registers that are selected by what `value`
    ## holds on entry: `uc_x86_msr` with `rid` set (`UC_X86_REG_MSR`),
    ## `uc_arm_cp_reg` and `uc_arm64_cp_reg` with the coprocessor fields set
    ## (`UC_ARM_REG_CP_REG`, `UC_ARM64_REG_CP_REG`).
    plainData(T)
    readInto(uc, cint(ord(reg)), addr value, sizeof(T))

  proc regWrite*[Reg: enum | cint; T: SomeInteger](uc: Unicorn; reg: Reg; value: T) =
    ## Writes a register of up to 64 bits. The register takes the low bits it
    ## has room for; a signed `value` is sign-extended first, so that
    ## `uc.regWrite(UC_X86_REG_RAX, -1)` sets all 64 bits.
    ##
    ## For a wider register Unicorn 2.1 raises `UnicornError` with
    ## `UC_ERR_OVERFLOW`; Unicorn 2.0 sets its upper part to zero.
    ##
    ## Loading an x86 segment register in protected mode reads the
    ## descriptor table from emulated memory, memory hooks included; an
    ## exception one of them raises comes out of this call. With Unicorn 2.0
    ## the process crashes when the table is not in mapped memory.
    let wide = widened(value)
    writeFrom(uc, cint(ord(reg)), unsafeAddr wide, sizeof(wide))

  proc regWrite*[Reg: enum | cint; T: not SomeInteger](uc: Unicorn; reg: Reg; value: T) =
    ## Writes a register from a `T` of the register's size:
    ## `uc.regWrite(UC_X86_REG_XMM0, bytes)` with an `array[16, byte]`, or a
    ## `uc_x86_msr`, `uc_arm_cp_reg`, `uc_arm64_cp_reg` that names the
    ## register and carries the value. A `T` smaller than the register is
    ## handled as in the form for integers. `T` must be plain data without
    ## pointers, as for `regRead`.
    plainData(T)
    writeFrom(uc, cint(ord(reg)), unsafeAddr value, sizeof(T))

  proc regReadBatch*[Reg: enum | cint](uc: Unicorn; regs: openArray[Reg]): seq[uint64] =
    ## Several registers of up to 64 bits, in the order of `regs`.
    let keep {.used.} = uc.state   # for all of the loop, as in `regWriteBatch`
    var values = newSeq[uint64](regs.len)   # not `result`: see `memRead`
    for i, reg in regs:
      readInto(uc, cint(ord(reg)), addr values[i], sizeof(uint64))
    values

  proc regWriteBatch*[Reg: enum | cint](uc: Unicorn; regs: openArray[Reg];
                                        values: openArray[uint64]) =
    ## Writes `values[i]` to `regs[i]`. Stops at the first register that
    ## fails; the ones before it are written.
    # A reference for all of the loop: a callback that runs under one write
    # may drop the engine's owner, and the next write still needs the engine.
    let keep {.used.} = uc.state
    if regs.len != values.len:
      raiseUnicorn(UC_ERR_ARG, "regWriteBatch: " & $regs.len & " registers, but " &
                               $values.len & " values")
    for i, reg in regs:
      writeFrom(uc, cint(ord(reg)), unsafeAddr values[i], sizeof(uint64))

  proc requireArch(st: EngineState; arch: uc_arch; code: uc_err; what: string) =
    ## For what exists on one architecture only. Unicorn itself would take
    ## the number for one of the engine's own registers or instructions.
    if st.arch != arch:
      raiseUnicorn(code, what & " is for " & (if arch == UC_ARCH_X86: "x86" else: "ARM64") &
                         " engines; this one is " & $st.arch)

  proc msrRead*(uc: Unicorn; id: uint32): uint64 =
    ## The x86 model-specific register `id`, as RDMSR reads it:
    ## `uc.msrRead(0xC0000080'u32)` is EFER.
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_ARCH, "msrRead")
    var msr = uc_x86_msr(rid: id)
    readInto(uc, cint(ord(UC_X86_REG_MSR)), addr msr, sizeof(msr))
    msr.value

  proc msrWrite*(uc: Unicorn; id: uint32; value: uint64) =
    ## Sets the x86 model-specific register `id`, as WRMSR does.
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_ARCH, "msrWrite")
    var msr = uc_x86_msr(rid: id, value: value)
    writeFrom(uc, cint(ord(UC_X86_REG_MSR)), addr msr, sizeof(msr))

  proc pcRegister(st: EngineState): cint =
    if st.arch == UC_ARCH_X86:
      if UC_MODE_64 in st.mode: cint(ord(UC_X86_REG_RIP))
      elif UC_MODE_32 in st.mode: cint(ord(UC_X86_REG_EIP))
      else: cint(ord(UC_X86_REG_IP))
    else:
      let reg = programCounter(st.arch)
      if reg == 0: raiseUnicorn(UC_ERR_ARCH)
      reg

  proc pc*(uc: Unicorn): uint64 =
    ## The program counter, whatever the architecture calls it: RIP, EIP or
    ## IP on x86 according to the mode (in 16-bit mode that is the offset
    ## within CS, not the linear address `start` and the hooks use), the PC
    ## register elsewhere. On ARM the Thumb state is not part of it.
    readInto(uc, pcRegister(uc.state), addr result, sizeof(result))

  proc `pc=`*(uc: Unicorn; address: uint64) =
    ## Sets the program counter. On ARM an odd address selects Thumb. Inside
    ## a hook this makes the emulation continue at `address`; not so for
    ## 16-bit x86 with Unicorn 2.0, which goes on where it was.
    writeFrom(uc, pcRegister(uc.state), unsafeAddr address, sizeof(address))

  # --- running -------------------------------------------------------------

  const maxNesting = 63   # Unicorn allows 64 nested uc_emu_start and crashes in the 64th

  proc start*(uc: Unicorn; begin, until: uint64; timeout = 0'u64; count = 0) =
    ## Emulates from `begin` until `until` is reached (the instruction there
    ## is not executed), `timeout` microseconds have passed or `count`
    ## instructions have run; 0 means no limit. With `exits=` the exit
    ## addresses replace `until`.
    ##
    ## Raises `UnicornError` when the emulation fails, and whatever a hook
    ## raised: that exception stops the emulation and is raised again here.
    ##
    ## A hook may call `start` itself, up to 63 runs inside one another; one
    ## more raises `UnicornError` with `UC_ERR_RESOURCE`. The inner run
    ## raises what its hooks raise; a hook that lets that pass ends the outer
    ## run with it too. `count` and runs inside one another exclude each
    ## other: a `start` inside a hook raises `UnicornError` when it has a
    ## `count`, or when a run around it has one.
    let state = uc.state
    if state.runs >= maxNesting:
      raiseUnicorn(UC_ERR_RESOURCE, "start is nested more than " & $maxNesting & " deep")
    # Unicorn has one instruction counter for all the runs, and it discards
    # the translated code under the outer run when an inner one has no
    # count: the outer run then ends in the wrong place, or crashes.
    if state.runs > 0 and (count != 0 or state.counted > 0):
      raiseUnicorn(UC_ERR_ARG, "start inside a hook cannot be combined with an instruction count")
    # Unicorn installs its counter without discarding the code translated
    # before: that code would run without being counted.
    if count == 0: state.counting = false
    elif not state.counting:
      state.counting = true
      state.stale = true
    inc state.runs
    if count != 0: inc state.counted
    try:
      driving(uc, emulation = true): uc_emu_start(h, begin, until, timeout, csize_t(count))
    finally:
      dec state.runs
      if count != 0: dec state.counted

  proc start*(uc: Unicorn; begin, until: uint64; timeout: Duration; count = 0) =
    ## `start` with the time limit as a `Duration` of `std/times`:
    ## `uc.start(entry, 0, initDuration(milliseconds = 100))`. A limit below
    ## one microsecond counts as one; `DurationZero` is no limit.
    if timeout < DurationZero:
      raiseUnicorn(UC_ERR_ARG, "a timeout cannot be negative")
    var micros = uint64(timeout.inMicroseconds)
    if micros == 0 and timeout > DurationZero: micros = 1
    start(uc, begin, until, micros, count)

  proc stop*(uc: Unicorn) =
    ## Stops the emulation: `start` returns once the current instruction is
    ## done. For use inside hooks, or from another thread.
    check uc_emu_stop(uc.handle)

  proc timedOut*(uc: Unicorn): bool =
    ## Whether the last `start` ended because its time limit ran out.
    var answer: csize_t
    check uc_query(uc.handle, UC_QUERY_TIMEOUT, addr answer)
    answer != 0

  # --- hooks ---------------------------------------------------------------
  #
  # Unicorn calls C functions. Each callback signature has one trampoline
  # here; its `user_data` is the record that holds the Nim closure.

  template guarded(Callback: typedesc; h: ptr uc_engine; user: pointer; body: untyped) =
    ## Runs a Nim callback on behalf of C: `hook` is its record and `uc` an
    ## alias of the engine that does not own it. Nothing may propagate into
    ## Unicorn's frames, so whatever is raised is kept for the Nim call that
    ## led here, and an emulation is told to stop.
    let hook {.inject.} = cast[ptr HookRec[Callback]](user)
    # Unicorn compiles the call of a lone code or block hook into the
    # translated block, which goes on calling it after `uc_hook_del` until
    # the block ends.
    if not hook.removed:
      var uc {.inject.}: Unicorn
      uc.st = cast[EngineState](hook.st)   # a counted reference for the duration of the call
      let st = hook.st
      # a callback counts wherever Unicorn calls it from, also from a
      # uc_emu_start that did not come from here: what it removes is kept
      inc st.busy
      inc st.callbacks
      try:
        body
      except Exception as e:
        if st.pending == nil: st.pending = e
        if not st.direct: discard uc_emu_stop(h)
      dec st.callbacks
      dec st.busy
      # The callback has dropped the engine's last owner, and no call from
      # here keeps the engine: letting go now would close it with Unicorn
      # still on the stack.
      if st.busy == 0 and isUniqueRef(uc.st): orphans.add move(uc.st)

  proc codeTrampoline(h: ptr uc_engine; address: uint64; size: uint32; user: pointer) {.cdecl.} =
    guarded(CodeCallback, h, user): hook.cb(uc, address, int(size))

  proc memTrampoline(h: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint;
                     value: int64; user: pointer) {.cdecl.} =
    guarded(MemCallback, h, user): hook.cb(uc, kind, address, int(size), value)

  proc memFaultTrampoline(h: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint;
                          value: int64; user: pointer): bool {.cdecl.} =
    guarded(MemFaultCallback, h, user): result = hook.cb(uc, kind, address, int(size), value)

  proc interruptTrampoline(h: ptr uc_engine; number: uint32; user: pointer) {.cdecl.} =
    guarded(InterruptCallback, h, user): hook.cb(uc, number)

  proc insnTrampoline(h: ptr uc_engine; user: pointer) {.cdecl.} =
    guarded(InsnCallback, h, user): hook.cb(uc)

  proc invalidInsnTrampoline(h: ptr uc_engine; user: pointer): bool {.cdecl.} =
    guarded(InvalidInsnCallback, h, user): result = hook.cb(uc)

  proc portInTrampoline(h: ptr uc_engine; port: uint32; size: cint;
                        user: pointer): uint32 {.cdecl.} =
    guarded(PortInCallback, h, user): result = hook.cb(uc, port, int(size))

  proc portOutTrampoline(h: ptr uc_engine; port: uint32; size: cint; value: uint32;
                         user: pointer) {.cdecl.} =
    guarded(PortOutCallback, h, user): hook.cb(uc, port, int(size), value)

  proc cpuidTrampoline(h: ptr uc_engine; user: pointer): cint {.cdecl.} =
    guarded(CpuidCallback, h, user): result = cint(ord(hook.cb(uc)))

  proc sysTrampoline(h: ptr uc_engine; reg: uc_arm64_reg; cpReg: ptr uc_arm64_cp_reg;
                     user: pointer): uint32 {.cdecl.} =
    guarded(SysCallback, h, user): result = uint32(ord(hook.cb(uc, reg, cpReg[])))

  proc edgeTrampoline(h: ptr uc_engine; current, previous: ptr uc_tb; user: pointer) {.cdecl.} =
    guarded(EdgeCallback, h, user): hook.cb(uc, current[], previous[])

  proc tcgOpcodeTrampoline(h: ptr uc_engine; address, arg1, arg2: uint64; size: uint32;
                           user: pointer) {.cdecl.} =
    guarded(TcgOpcodeCallback, h, user): hook.cb(uc, address, arg1, arg2, int(size))

  proc tlbFillTrampoline(h: ptr uc_engine; address: uint64; kind: uc_mem_type;
                         entry: ptr uc_tlb_entry; user: pointer): bool {.cdecl.} =
    guarded(TlbFillCallback, h, user): result = hook.cb(uc, address, kind, entry[])

  proc mmioReadTrampoline(h: ptr uc_engine; offset: uint64; size: cuint;
                          user: pointer): uint64 {.cdecl.} =
    guarded(MmioReadCallback, h, user): result = hook.cb(uc, offset, int(size))

  proc mmioWriteTrampoline(h: ptr uc_engine; offset: uint64; size: cuint; value: uint64;
                           user: pointer) {.cdecl.} =
    guarded(MmioWriteCallback, h, user): hook.cb(uc, offset, int(size), value)

  proc newHook[Callback](st: EngineState; callback: Callback): ref HookRec[Callback] =
    if callback == nil: raiseUnicorn(UC_ERR_ARG, "the callback is nil")
    result = (ref HookRec[Callback])(cb: callback)
    result.st = addr st[]

  type Translated = enum
    ## How a kind of hook gets into the code Unicorn translates.
    atRunTime     ## looked up when it is due: nothing to do
    whenAdded     ## compiled in: code translated before the hook was added lacks it
    asRecord      ## compiled in as the address of Unicorn's record of the hook

  template register(uc: Unicorn; callback: typed; how: Translated; add: untyped): HookId =
    ## Adds a hook with the C call `add`, which gets the handle as `h`, the
    ## record as `user` and stores the hook's handle in `id`.
    let st = uc.state
    let hook = newHook(st, callback)
    hook.compiled = how == asRecord
    let h {.inject.} = st.handle.p
    let user {.inject.} = cast[pointer](hook)
    var id {.inject.}: uc_hook
    check add
    st.hooks[id] = hook
    if how != atRunTime: st.stale = true   # see `settle`
    HookId(id)

  const
    everywhere = 1'u64 .. 0'u64   # Unicorn's convention: begin > end means no limit
    memAccessHooks = UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE or UC_HOOK_MEM_FETCH or
                     UC_HOOK_MEM_READ_AFTER

  func span(where: Slice[uint64]): Slice[uint64] =
    ## The range a caller gave. An empty one must not reach Unicorn, where it
    ## would mean everywhere.
    if where.a > where.b:
      raise (ref UnicornError)(code: UC_ERR_ARG,
        msg: "the address range " & $where.a & " .. " & $where.b & " is empty")
    where

  proc addCodeHook(uc: Unicorn; kind: uc_hook_type; where: Slice[uint64];
                   callback: CodeCallback): HookId =
    register(uc, callback, whenAdded,
      uc_hook_add(h, addr id, kind, codeTrampoline, user, where.a, where.b))

  proc onCode*(uc: Unicorn; where: Slice[uint64]; callback: CodeCallback): HookId =
    ## Calls `callback` before every instruction in the address range `where`
    ## (inclusive; an empty range raises `UnicornError`, here and for every
    ## other hook that takes one).
    ##
    ## A hook added while a hook runs is called for code that Unicorn
    ## translates from then on, and for all code from the next `start` on;
    ## the same holds for `onBlock`, `onTcgOpcode` and `onSys`.
    addCodeHook(uc, UC_HOOK_CODE, span(where), callback)

  proc onCode*(uc: Unicorn; callback: CodeCallback): HookId =
    ## Calls `callback` before every instruction.
    addCodeHook(uc, UC_HOOK_CODE, everywhere, callback)

  proc onBlock*(uc: Unicorn; where: Slice[uint64]; callback: CodeCallback): HookId =
    ## Calls `callback` at the start of every basic block that begins in
    ## `where`; `size` is the size of the block.
    addCodeHook(uc, UC_HOOK_BLOCK, span(where), callback)

  proc onBlock*(uc: Unicorn; callback: CodeCallback): HookId =
    ## Calls `callback` at the start of every basic block.
    addCodeHook(uc, UC_HOOK_BLOCK, everywhere, callback)

  proc addMemHook(uc: Unicorn; kinds: uc_hook_type; where: Slice[uint64];
                  callback: MemCallback): HookId =
    if kinds == uc_hook_type(0) or (kinds and memAccessHooks) != kinds:
      raiseUnicorn(UC_ERR_HOOK, "onMem takes UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE, " &
        "UC_HOOK_MEM_FETCH and UC_HOOK_MEM_READ_AFTER; got " & $kinds)
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, kinds, memTrampoline, user, where.a, where.b))

  proc onMem*(uc: Unicorn; kinds: uc_hook_type; where: Slice[uint64];
              callback: MemCallback): HookId =
    ## Calls `callback` for memory accesses of emulated code to addresses in
    ## `where`. `kinds` combines `UC_HOOK_MEM_READ` (before the read),
    ## `UC_HOOK_MEM_READ_AFTER` (with the value read) and `UC_HOOK_MEM_WRITE`;
    ## anything but these and `UC_HOOK_MEM_FETCH` raises `UnicornError`.
    ## Accesses that fail go to `onMemFault`.
    ##
    ## Unicorn takes `UC_HOOK_MEM_FETCH` but never reports a fetch. Before
    ## Unicorn 2.1.2, `UC_HOOK_MEM_READ_AFTER` without a `UC_HOOK_MEM_READ`
    ## hook for the same addresses is only reported for the first access to
    ## a page: a read that follows another read or a write there is missed.
    addMemHook(uc, kinds, span(where), callback)

  proc onMem*(uc: Unicorn; kinds: uc_hook_type; callback: MemCallback): HookId =
    ## `onMem` for accesses anywhere.
    addMemHook(uc, kinds, everywhere, callback)

  proc addMemFaultHook(uc: Unicorn; kinds: uc_hook_type; where: Slice[uint64];
                       callback: MemFaultCallback): HookId =
    if kinds == uc_hook_type(0) or (kinds and UC_HOOK_MEM_INVALID) != kinds:
      raiseUnicorn(UC_ERR_HOOK, "onMemFault takes the UC_HOOK_MEM_*_UNMAPPED and " &
        "UC_HOOK_MEM_*_PROT kinds; got " & $kinds)
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, kinds, memFaultTrampoline, user, where.a, where.b))

  proc onMemFault*(uc: Unicorn; kinds: uc_hook_type; where: Slice[uint64];
                   callback: MemFaultCallback): HookId =
    ## Calls `callback` for memory accesses to addresses in `where` that
    ## cannot be carried out. `kinds` combines `UC_HOOK_MEM_READ_UNMAPPED`,
    ## `UC_HOOK_MEM_WRITE_UNMAPPED`, `UC_HOOK_MEM_FETCH_UNMAPPED` (together
    ## `UC_HOOK_MEM_UNMAPPED`), `UC_HOOK_MEM_READ_PROT`,
    ## `UC_HOOK_MEM_WRITE_PROT` and `UC_HOOK_MEM_FETCH_PROT` (together
    ## `UC_HOOK_MEM_PROT`); anything else raises `UnicornError`.
    ##
    ## The callback returns whether it repaired the fault.
    addMemFaultHook(uc, kinds, span(where), callback)

  proc onMemFault*(uc: Unicorn; kinds: uc_hook_type; callback: MemFaultCallback): HookId =
    ## `onMemFault` for accesses anywhere.
    addMemFaultHook(uc, kinds, everywhere, callback)

  proc onInterrupt*(uc: Unicorn; callback: InterruptCallback): HookId =
    ## Calls `callback` for every interrupt and CPU exception: `int 0x80` on
    ## x86, `svc` on ARM, and so on. Without such a hook they end `start`
    ## with `UC_ERR_EXCEPTION`.
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INTR, interruptTrampoline, user, 1, 0))

  proc onInvalidInsn*(uc: Unicorn; callback: InvalidInsnCallback): HookId =
    ## Calls `callback` when the CPU meets bytes that are not an instruction.
    ## The callback returns whether the emulation is to go on.
    ##
    ## Unicorn goes on by itself from 2.1.2 on. Older versions end the run
    ## all the same, 2.0 without an error and 2.1.0 and 2.1.1 with
    ## `UC_ERR_EXCEPTION`; another `start` at `pc` continues it.
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INSN_INVALID, invalidInsnTrampoline, user, 1, 0))

  proc addInsnHook(uc: Unicorn; insn: uc_x86_insn; name: string; where: Slice[uint64];
                   callback: InsnCallback): HookId =
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_HOOK, name)
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INSN, insnTrampoline, user, where.a, where.b, insn))

  proc onSyscall*(uc: Unicorn; where: Slice[uint64]; callback: InsnCallback): HookId =
    ## Calls `callback` for every x86 `syscall` instruction in `where`. The
    ## instruction itself then does nothing but advance.
    addInsnHook(uc, UC_X86_INS_SYSCALL, "onSyscall", span(where), callback)

  proc onSyscall*(uc: Unicorn; callback: InsnCallback): HookId =
    ## Calls `callback` for every x86 `syscall` instruction.
    addInsnHook(uc, UC_X86_INS_SYSCALL, "onSyscall", everywhere, callback)

  proc onSysenter*(uc: Unicorn; where: Slice[uint64]; callback: InsnCallback): HookId =
    ## Calls `callback` for every x86 `sysenter` instruction in `where`. The
    ## instruction itself then does nothing but advance.
    addInsnHook(uc, UC_X86_INS_SYSENTER, "onSysenter", span(where), callback)

  proc onSysenter*(uc: Unicorn; callback: InsnCallback): HookId =
    ## Calls `callback` for every x86 `sysenter` instruction.
    addInsnHook(uc, UC_X86_INS_SYSENTER, "onSysenter", everywhere, callback)

  proc onPortIn*(uc: Unicorn; callback: PortInCallback): HookId =
    ## Calls `callback` for every x86 `in` instruction; what it returns is
    ## what the instruction reads. Without such a hook a port reads as 0.
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_HOOK, "onPortIn")
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INSN, portInTrampoline, user, 1, 0, UC_X86_INS_IN))

  proc onPortOut*(uc: Unicorn; callback: PortOutCallback): HookId =
    ## Calls `callback` for every x86 `out` instruction.
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_HOOK, "onPortOut")
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INSN, portOutTrampoline, user, 1, 0, UC_X86_INS_OUT))

  proc addCpuidHook(uc: Unicorn; where: Slice[uint64]; callback: CpuidCallback): HookId =
    requireArch(uc.state, UC_ARCH_X86, UC_ERR_HOOK, "onCpuid")
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_INSN, cpuidTrampoline, user, where.a, where.b,
                  UC_X86_INS_CPUID))

  proc onCpuid*(uc: Unicorn; where: Slice[uint64]; callback: CpuidCallback): HookId =
    ## Calls `callback` for every x86 `cpuid` instruction in `where`. The
    ## callback returns whether it has answered in Unicorn's place.
    addCpuidHook(uc, span(where), callback)

  proc onCpuid*(uc: Unicorn; callback: CpuidCallback): HookId =
    ## Calls `callback` for every x86 `cpuid` instruction.
    addCpuidHook(uc, everywhere, callback)

  proc addSysHook(uc: Unicorn; insn: uc_arm64_insn; where: Slice[uint64];
                  callback: SysCallback): HookId =
    requireArch(uc.state, UC_ARCH_ARM64, UC_ERR_HOOK, "onSys")
    register(uc, callback, asRecord,
      uc_hook_add(h, addr id, UC_HOOK_INSN, sysTrampoline, user, where.a, where.b, insn))

  proc onSys*(uc: Unicorn; insn: uc_arm64_insn; where: Slice[uint64];
              callback: SysCallback): HookId =
    ## Calls `callback` for the ARM64 system instructions of one kind in
    ## `where`: `UC_ARM64_INS_MRS`, `UC_ARM64_INS_MSR`, `UC_ARM64_INS_SYS` or
    ## `UC_ARM64_INS_SYSL`. The callback returns whether the instruction is
    ## to be skipped. Unicorn calls one hook per instruction, the first that
    ## matches.
    addSysHook(uc, insn, span(where), callback)

  proc onSys*(uc: Unicorn; insn: uc_arm64_insn; callback: SysCallback): HookId =
    ## `onSys` for instructions anywhere.
    addSysHook(uc, insn, everywhere, callback)

  proc addEdgeHook(uc: Unicorn; where: Slice[uint64]; callback: EdgeCallback): HookId =
    register(uc, callback, atRunTime,
      uc_hook_add(h, addr id, UC_HOOK_EDGE_GENERATED, edgeTrampoline, user, where.a, where.b))

  proc onEdgeGenerated*(uc: Unicorn; where: Slice[uint64]; callback: EdgeCallback): HookId =
    ## Calls `callback` when a block that begins in `where` has just been
    ## translated, with the block Unicorn ran before it. That happens once
    ## for as long as the translation is kept, not every time the block
    ## runs. `previous` is what Unicorn remembers as the last block: mostly
    ## the one that jumps to `current`, but not necessarily, and after
    ## `flushTb` it can be `current` itself.
    addEdgeHook(uc, span(where), callback)

  proc onEdgeGenerated*(uc: Unicorn; callback: EdgeCallback): HookId =
    ## `onEdgeGenerated` for blocks anywhere.
    addEdgeHook(uc, everywhere, callback)

  proc addTcgOpcodeHook(uc: Unicorn; opcode: uc_tcg_op_code; flags: set[uc_tcg_op_flag];
                        where: Slice[uint64]; callback: TcgOpcodeCallback): HookId =
    if flags == {UC_TCG_OP_FLAG_CMP, UC_TCG_OP_FLAG_DIRECT}:
      raiseUnicorn(UC_ERR_HOOK, "UC_TCG_OP_FLAG_CMP and UC_TCG_OP_FLAG_DIRECT exclude each other")
    var bits = 0'u32
    for flag in flags: bits = bits or uint32(ord(flag))
    register(uc, callback, asRecord,
      uc_hook_add(h, addr id, UC_HOOK_TCG_OPCODE, tcgOpcodeTrampoline, user, where.a, where.b,
                  opcode, bits))

  proc onTcgOpcode*(uc: Unicorn; opcode: uc_tcg_op_code; flags: set[uc_tcg_op_flag];
                    where: Slice[uint64]; callback: TcgOpcodeCallback): HookId =
    ## Calls `callback` before the instructions in `where` that compute with
    ## `opcode` (`UC_TCG_OP_SUB`: subtractions and comparisons), with the two
    ## operands. `flags` narrows that down: `{UC_TCG_OP_FLAG_CMP}` to
    ## comparisons, `{UC_TCG_OP_FLAG_DIRECT}` to subtractions; `{}` takes
    ## both. The two flags exclude each other.
    addTcgOpcodeHook(uc, opcode, flags, span(where), callback)

  proc onTcgOpcode*(uc: Unicorn; opcode: uc_tcg_op_code; flags: set[uc_tcg_op_flag];
                    callback: TcgOpcodeCallback): HookId =
    ## `onTcgOpcode` for instructions anywhere.
    addTcgOpcodeHook(uc, opcode, flags, everywhere, callback)

  proc removeHook*(uc: Unicorn; id: HookId) =
    ## Removes a hook; its callback is not called again. A hook may remove
    ## itself, or any other, while it runs. Raises `UnicornError` with
    ## `UC_ERR_HOOK` for an id that is not, or no longer, a hook of this
    ## engine.
    let st = uc.state
    if uc_hook(id) notin st.hooks:
      raiseUnicorn(UC_ERR_HOOK, "removeHook: this engine has no such hook")
    check uc_hook_del(st.handle.p, uc_hook(id))
    var hook: Hook
    discard st.hooks.pop(uc_hook(id), hook)
    hook.removed = true
    if hook.compiled:
      st.stale = true
      st.dangling = true
    st.retired.add hook   # it may be the one that is running
    if st.busy == 0: st.settle(flush = false)

  proc mmioMap*(uc: Unicorn; address, size: uint64; read: MmioReadCallback;
                write: MmioWriteCallback) =
    ## Maps a range without memory behind it: emulated reads of it call
    ## `read`, writes call `write`, and so do `memRead` and `memWrite`.
    ## Either may be nil; the range is then not readable, or not writable.
    ##
    ## An exception raised in one of them comes out of the call that led to
    ## the access: `start`, `memRead`, `memWrite`, or the `regWrite` of an
    ## x86 segment register whose descriptor table lies in the range. The
    ## closures are kept until the engine is closed, also when the range is
    ## unmapped: Unicorn can bring an unmapped range back when a context that
    ## holds memory is restored.
    let st = uc.state
    var readHook, writeHook: Hook
    var readProc: uc_cb_mmio_read_t
    var writeProc: uc_cb_mmio_write_t
    if read != nil:
      readHook = newHook(st, read)
      readProc = mmioReadTrampoline
    if write != nil:
      writeHook = newHook(st, write)
      writeProc = mmioWriteTrampoline
    check uc_mmio_map(st.handle.p, address, toSize(size), readProc, cast[pointer](readHook),
                      writeProc, cast[pointer](writeHook))
    if readHook != nil: st.mmio.add readHook
    if writeHook != nil: st.mmio.add writeHook

  # --- contexts ------------------------------------------------------------

  proc `=destroy`*(store: ContextStore) =
    ## Frees the context.
    if store.p != nil: discard uc_context_free(store.p)

  proc `=copy`*(dest: var ContextStore; source: ContextStore) {.error.}

  proc `=copy`*(dest: var Context; source: Context) {.error:
    "a Context cannot be copied; move it or pass it by reference".}

  func handle*(ctx: Context): ptr uc_context {.inline.} =
    ## The underlying `uc_context`, for calling the C API directly. Do not
    ## free it.
    if ctx.store.p == nil:
      raise (ref UnicornError)(code: UC_ERR_HANDLE,
                               msg: "this Context holds nothing (never saved, or moved away)")
    ctx.store.p

  proc save*(uc: Unicorn; ctx: var Context) =
    ## Saves the CPU state into `ctx`, replacing what it holds. The storage
    ## of a context that this engine saved before is used again, unless
    ## memory is involved.
    let st = uc.state
    let memory = UC_CTL_CONTEXT_MEMORY in st.content or UC_CTL_CONTEXT_MEMORY in ctx.content
    if ctx.store.p == nil or ctx.engine != st.identity or memory:
      var p: ptr uc_context
      check uc_context_alloc(st.handle.p, addr p)
      ctx = Context(store: ContextStore(p: p), engine: st.identity, arch: st.arch,
                    mode: st.mode)
    let err = uc_context_save(st.handle.p, ctx.store.p)
    if err != UC_ERR_OK:
      ctx = Context()   # nothing, rather than a state that is half saved
      raiseUnicorn(err)
    ctx.content = st.content
    if UC_CTL_CONTEXT_MEMORY in st.content:
      inc st.lastSnapshot
      ctx.snapshot = st.lastSnapshot
      st.snapshots.add ctx.snapshot

  proc saveContext*(uc: Unicorn): Context =
    ## The CPU state as it is now, for `restore`.
    uc.save(result)

  proc restore*(uc: Unicorn; ctx: Context) =
    ## Puts the engine back into the state `ctx` holds. Raises `UnicornError`
    ## when `ctx` was saved from another engine (the layout of a context
    ## depends on architecture, mode and CPU model), under another
    ## `contextMode`, or when its memory is gone (see `contextMode=`).
    let st = uc.state
    let p = ctx.handle
    if ctx.engine != st.identity:
      raiseUnicorn(UC_ERR_ARG, "a Context can only be restored into the engine it was saved from")
    if ctx.content != st.content:
      raiseUnicorn(UC_ERR_ARG, "this Context was saved with contextMode " & $ctx.content &
        "; the engine is now set to " & $st.content)
    if UC_CTL_CONTEXT_MEMORY in ctx.content:
      # Unicorn keeps the memory of contexts as a stack of snapshots: going
      # back to one drops the later ones.
      let at = st.snapshots.find(ctx.snapshot)
      if at < 0:
        raiseUnicorn(UC_ERR_ARG, "the memory of this Context is gone: a Context saved before " &
          "it has been restored since")
      st.snapshots.setLen(at + 1)
    check uc_context_restore(st.handle.p, p)

  proc needsEngine(ctx: Context; reg: cint; writing: bool): bool =
    ## Whether Unicorn goes beyond the saved state for this access. A context
    ## is a copy of the CPU's registers and nothing else; for the registers
    ## named here Unicorn calls code that expects the CPU itself behind them,
    ## and reads or writes memory that is not the context's. (Found by
    ## reading and writing every register of every architecture through a
    ## context under valgrind, with Unicorn 2.0.0 to 2.1.4.)
    template one(register: untyped): bool = reg == cint(ord(register))
    template within(first, last: untyped): bool =
      reg >= cint(ord(first)) and reg <= cint(ord(last))
    case ctx.arch
    of UC_ARCH_X86:
      one(UC_X86_REG_MSR) or
        (writing and (one(UC_X86_REG_CR0) or one(UC_X86_REG_CR3) or one(UC_X86_REG_CR4) or
          # in protected mode a segment register is loaded from the
          # descriptor table, which is in the engine's memory
          one(UC_X86_REG_CS) or one(UC_X86_REG_DS) or one(UC_X86_REG_ES) or
          one(UC_X86_REG_FS) or one(UC_X86_REG_GS) or one(UC_X86_REG_SS)))
    of UC_ARCH_ARM:
      one(UC_ARM_REG_CP_REG) or
        (writing and (one(UC_ARM_REG_PC) or one(UC_ARM_REG_FPSCR) or one(UC_ARM_REG_CONTROL)))
    of UC_ARCH_ARM64:
      one(UC_ARM64_REG_CP_REG) or
        (writing and (one(UC_ARM64_REG_FPCR) or one(UC_ARM64_REG_FPSR)))
    of UC_ARCH_M68K:
      writing and (one(UC_M68K_REG_SR) or one(UC_M68K_REG_CR_CACR))
    of UC_ARCH_PPC:
      writing and one(UC_PPC_REG_FPSCR)
    of UC_ARCH_RISCV:
      within(UC_RISCV_REG_USTATUS, UC_RISCV_REG_HTIMEDELTAH)   # the CSRs
    of UC_ARCH_SPARC:
      # the window registers are reached through a pointer into the engine
      within(UC_SPARC_REG_I0, UC_SPARC_REG_I7) or within(UC_SPARC_REG_L0, UC_SPARC_REG_O7) or
        (not writing and one(UC_SPARC_REG_PSR)) or
        (UC_MODE_SPARC64 in ctx.mode and
          (within(UC_SPARC_REG_G0, UC_SPARC_REG_G7) or one(UC_SPARC_REG_PC)))
    else:
      false

  proc target(ctx: Context; reg: cint; writing: bool): ptr uc_context =
    ## The `uc_context` for an access that Unicorn can carry out.
    result = ctx.handle
    if UC_CTL_CONTEXT_CPU notin ctx.content:
      raiseUnicorn(UC_ERR_ARG, "this Context was saved without the registers (contextMode)")
    if needsEngine(ctx, reg, writing):
      raiseUnicorn(UC_ERR_ARG, "Unicorn cannot " & (if writing: "write" else: "read") &
        " register " & $reg & " through a context; restore it and use the engine's register")

  proc readInto(ctx: Context; reg: cint; value: pointer; size: int) =
    check readRegister(target(ctx, reg, writing = false), reg, value, size)

  proc writeFrom(ctx: var Context; reg: cint; value: pointer; size: int) =
    let p = target(ctx, reg, writing = true)
    if ctx.arch == UC_ARCH_ARM and reg == cint(ord(UC_ARM_REG_CPSR)):
      var current: uint32
      if readRegister(p, reg, addr current, sizeof(current)) == UC_ERR_OK:
        checkCpsr(ctx.arch, reg, current, value)
    check writeRegister(p, reg, value, size)

  proc regRead*[Reg: enum | cint](ctx: Context; reg: Reg): uint64 =
    ## A register of up to 64 bits as the context holds it; sizes and `reg`
    ## are handled as by `regRead` of the engine.
    ##
    ## Unicorn cannot get at every register without the engine. Those raise
    ## `UnicornError` here instead of crashing there: model-specific and
    ## coprocessor registers, RISC-V's CSRs, SPARC's window registers and a
    ## few more; for writing also the x86 control and segment registers, the
    ## ARM PC and the floating-point control registers of ARM, ARM64 and
    ## PowerPC. So does every register of a context that was saved without
    ## the registers (`contextMode=`).
    readInto(ctx, cint(ord(reg)), addr result, sizeof(result))

  proc regRead*[Reg: enum | cint; T](ctx: Context; reg: Reg; _: typedesc[T]): T =
    ## The saved register as a `T`: `ctx.regRead(UC_X86_REG_XMM0, array[16, byte])`.
    plainData(T)
    readInto(ctx, cint(ord(reg)), addr result, sizeof(T))

  proc regRead*[Reg: enum | cint; T](ctx: Context; reg: Reg; value: var T) =
    ## Reads the saved register into `value`, as the form of the engine that
    ## takes a variable does.
    plainData(T)
    readInto(ctx, cint(ord(reg)), addr value, sizeof(T))

  proc regWrite*[Reg: enum | cint; T: SomeInteger](ctx: var Context; reg: Reg; value: T) =
    ## Changes a register of up to 64 bits in the context; the engine sees it
    ## when the context is restored. Sizes are handled as by `regWrite` of
    ## the engine, and the registers Unicorn cannot write without the engine
    ## raise `UnicornError` (see `regRead`).
    let wide = widened(value)
    writeFrom(ctx, cint(ord(reg)), unsafeAddr wide, sizeof(wide))

  proc regWrite*[Reg: enum | cint; T: not SomeInteger](ctx: var Context; reg: Reg; value: T) =
    ## Changes a register in the context from a `T` of the register's size.
    plainData(T)
    writeFrom(ctx, cint(ord(reg)), unsafeAddr value, sizeof(T))

  # --- control and query ---------------------------------------------------
  #
  # Unicorn finishes setting an engine up the first time it is used: by
  # mapping memory, touching a register, adding a hook, and by most of the
  # queries below. What shapes the CPU has to be set before that, directly
  # after `initUnicorn`: `cpuModel=`, `pageSize=`, `tcgBufferSize=`.

  proc pageSize*(uc: Unicorn): int =
    ## The page size: addresses and sizes of mappings are multiples of it.
    var size: uint32
    check uc_ctl_get_page_size(uc.handle, addr size)
    int(size)

  proc `pageSize=`*(uc: Unicorn; size: int) =
    ## Sets the page size: a power of two from 1024 (the smallest page the
    ## emulated ARM CPUs have) to 64 MB. Only ARM engines take one (ARM64
    ## engines too from Unicorn 2.1.2 on), and only before anything is mapped
    ## or otherwise done with the engine; later, and elsewhere, it raises
    ## `UnicornError`.
    # Unicorn takes any power of two; below 1024 and above 2^26 the engine
    # then aborts, crashes or cannot read its memory.
    if size < 1024 or size > 1 shl 26 or (size and (size - 1)) != 0:
      raiseUnicorn(UC_ERR_ARG, "a page size of " & $size & " bytes is not possible")
    let h = uc.handle
    let v = uc_version()
    # Unicorn before 2.1.2 counts one bit too many and ends up with twice
    # the size it is given.
    let asked = if (v.major, v.minor, v.patch) < (2, 1, 2): size shr 1 else: size
    check uc_ctl_set_page_size(h, uint32(asked))

  proc cpuModel*(uc: Unicorn): int =
    ## The CPU model as its number, `ord` of a member of the architecture's
    ## model enum. Asking fixes the model: it cannot be set afterwards.
    var model: cint
    check uc_ctl_get_cpu_model(uc.handle, addr model)
    int(model)

  proc cpuModel*[Model: enum](uc: Unicorn; T: typedesc[Model]): Model =
    ## The CPU model as a member of the architecture's model enum:
    ## `uc.cpuModel(uc_cpu_x86) == UC_CPU_X86_HASWELL`.
    T(cpuModel(uc))

  proc `cpuModel=`*[Model: enum | SomeInteger](uc: Unicorn; model: Model) =
    ## Selects the CPU to emulate: a member of the architecture's model enum
    ## (`UC_CPU_ARM_CORTEX_M4`, `UC_CPU_X86_SKYLAKE_CLIENT`, ...), or its
    ## number as `cpuModel` returns it. Must be set before anything else is
    ## done with the engine; later it raises `UnicornError`.
    ##
    ## For ARM the mode bits `UC_MODE_MCLASS`, `UC_MODE_ARM926`,
    ## `UC_MODE_ARM946` and `UC_MODE_ARM1176` select a model themselves and
    ## win over this one: an engine opened with `UC_MODE_MCLASS` is a
    ## Cortex-M33 whatever is set here.
    let number = int64(ord(model))
    if number < 0 or number > int64(high(cint)):
      raiseUnicorn(UC_ERR_ARG, "there is no CPU model " & $number)
    check uc_ctl_set_cpu_model(uc.handle, cint(number))

  proc exits*(uc: Unicorn): seq[uint64] =
    ## The exit addresses set with `exits=`, ascending; empty when there are
    ## none or exits are not in use.
    let h = uc.handle
    var count: csize_t
    let err = uc_ctl_get_exits_cnt(h, addr count)
    if err == UC_ERR_ARG: return   # Unicorn's answer while exits are not in use
    check err
    var addresses = newSeq[uint64](int(count))   # not `result`: see `memRead`
    if count > 0:
      check uc_ctl_get_exits(h, addr addresses[0], count)
    addresses

  proc `exits=`*(uc: Unicorn; addresses: openArray[uint64]) =
    ## Addresses at which `start` returns. They replace the ones set before,
    ## and from now on the `until` of `start` is ignored: with no addresses
    ## an emulation ends only by `stop`, a limit or an error. `clearExits`
    ## goes back to `until`.
    let h = uc.handle
    check uc_ctl_exits_enable(h)
    check uc_ctl_set_exits(h, (if addresses.len > 0: unsafeAddr addresses[0] else: nil),
                           csize_t(addresses.len))

  proc clearExits*(uc: Unicorn) =
    ## Stops using exit addresses: `start` ends at its `until` again.
    check uc_ctl_exits_disable(uc.handle)

  proc flushTb*(uc: Unicorn) =
    ## Discards all translated code. Unicorn translates it again when it
    ## runs next. Not inside a hook, where Unicorn would hang or crash; that
    ## raises `UnicornError`, and `removeCache` can be used there.
    let st = uc.state
    if st.callbacks > 0:
      raiseUnicorn(UC_ERR_ARG, "flushTb cannot be used inside a hook; removeCache can")
    st.stale = false
    st.dangling = false
    check uc_ctl_flush_tb(st.handle.p)

  proc removeCache*(uc: Unicorn; where: Slice[uint64]) =
    ## Discards the translated code of the address range `where`. Needed
    ## after `memWrite` has changed code that ran before: Unicorn would go on
    ## running its translation of the old bytes.
    let range = span(where)
    let until = if range.b == high(uint64): range.b else: range.b + 1
    check uc_ctl_remove_cache(uc.handle, range.a, until)

  proc requestCache*(uc: Unicorn; address: uint64): uc_tb =
    ## Translates the block at `address`, unless that is done already, and
    ## says where it begins, how many instructions it has and how many bytes.
    ## `address` must be in mapped, executable memory (`UnicornError`
    ## otherwise). A block that runs off the end of its mapping gives
    ## numbers without meaning, and crashes Unicorn 2.0.1.
    var executable = false
    for region in uc.memRegions:
      if address >= region.first and address <= region.last and UC_PROT_EXEC in region.perms:
        executable = true
    if not executable: raiseUnicorn(UC_ERR_FETCH_UNMAPPED)
    var tb: uc_tb
    driving(uc, emulation = false): uc_ctl_request_cache(h, address, addr tb)
    tb

  template needsUnicorn21(name: untyped; shown: string) =
    template name*(args: varargs[untyped]): untyped =
      {.error: shown & " needs Unicorn 2.1.0 or later; this build is against Unicorn " &
               libVersionText & ".".}

  when libVersion >= (2, 1, 0):
    proc addTlbFillHook(uc: Unicorn; where: Slice[uint64]; callback: TlbFillCallback): HookId =
      register(uc, callback, atRunTime,
        uc_hook_add(h, addr id, UC_HOOK_TLB_FILL, tlbFillTrampoline, user, where.a, where.b))

    proc onTlbFill*(uc: Unicorn; where: Slice[uint64]; callback: TlbFillCallback): HookId =
      ## Calls `callback` when the engine needs the translation of a virtual
      ## page in `where`; it takes the place of the CPU's page tables. Only
      ## called with `uc.tlbMode = UC_TLB_VIRTUAL`. Answers are cached until
      ## `flushTlb`. Unicorn 2.1.
      addTlbFillHook(uc, span(where), callback)

    proc onTlbFill*(uc: Unicorn; callback: TlbFillCallback): HookId =
      ## `onTlbFill` for pages anywhere.
      addTlbFillHook(uc, everywhere, callback)

    proc `tlbMode=`*(uc: Unicorn; mode: uc_tlb_type) =
      ## How virtual addresses are translated: `UC_TLB_CPU`, the default, as
      ## the emulated CPU does it; `UC_TLB_VIRTUAL` by the `onTlbFill` hooks,
      ## and one to one without any. Unicorn 2.1.
      check uc_ctl_tlb_mode(uc.handle, mode)

    proc flushTlb*(uc: Unicorn) =
      ## Forgets the cached address translations, so that `onTlbFill` hooks
      ## are asked again. Unicorn 2.1.
      check uc_ctl_flush_tlb(uc.handle)

    proc `contextMode=`*(uc: Unicorn; content: set[uc_context_content]) =
      ## What `saveContext` saves and `restore` puts back:
      ## `{UC_CTL_CONTEXT_CPU}`, the default, is the registers;
      ## `UC_CTL_CONTEXT_MEMORY` adds, or alone is, a snapshot of the memory.
      ## An empty set raises `UnicornError`. Unicorn 2.1.
      ##
      ## A context is restored under the mode it was saved with. Contexts
      ## with memory form a stack: restoring one makes those saved after it
      ## useless, and restoring one of them raises `UnicornError`.
      ##
      ## Unicorn 2.1.2 cannot restore memory: it reads what it has just
      ## freed, and ends the process when contexts are restored one after
      ## another. With that release in the process `UC_CTL_CONTEXT_MEMORY`
      ## raises `UnicornError`; 2.1.0, 2.1.1 and 2.1.3 on do it right.
      if content == {}:
        raiseUnicorn(UC_ERR_ARG, "contextMode needs something to save")
      if UC_CTL_CONTEXT_MEMORY in content:
        let v = uc_version()
        if (v.major, v.minor, v.patch) == (2, 1, 2):
          raiseUnicorn(UC_ERR_ARG, "Unicorn 2.1.2 cannot restore a context that holds " &
            "memory (it reads memory it has freed); that takes another release of Unicorn 2.1")
      var bits = cint(0)
      for part in content: bits = bits or cint(ord(part))
      let st = uc.state
      check uc_ctl_context_mode(st.handle.p, bits)
      st.content = content

    proc tcgBufferSize*(uc: Unicorn): int =
      ## The size in bytes that the buffer for translated code has, or that
      ## was last set with `tcgBufferSize=`, whether that took effect or
      ## not. Unicorn 2.1.
      var size: uint32
      check uc_ctl_get_tcg_buffer_size(uc.handle, addr size)
      int(size)

    proc `tcgBufferSize=`*(uc: Unicorn; size: int) =
      ## Sets the size of the buffer for translated code. Must be set before
      ## anything else is done with the engine; later it has no effect.
      ## Unicorn 2.1.
      if size < 0 or size > int(high(int32)):
        raiseUnicorn(UC_ERR_ARG, "a buffer of " & $size & " bytes is not possible")
      check uc_ctl_set_tcg_buffer_size(uc.handle, uint32(size))
  else:
    needsUnicorn21(onTlbFill, "onTlbFill")
    needsUnicorn21(`tlbMode=`, "tlbMode=")
    needsUnicorn21(flushTlb, "flushTlb")
    needsUnicorn21(`contextMode=`, "contextMode=")
    needsUnicorn21(tcgBufferSize, "tcgBufferSize")
    needsUnicorn21(`tcgBufferSize=`, "tcgBufferSize=")

else:
  template initUnicorn*(arch: uc_arch; mode: uc_mode): untyped =
    {.error: "libunicorn's Nim API needs --mm:orc or --mm:arc. " &
             "The C API (uc_open, uc_emu_start, ...) works with any memory manager.".}
