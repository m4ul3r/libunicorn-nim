## C macros of the Unicorn headers that the generator cannot translate: it
## only understands macros that are plain literals. Included by `raw.nim`.
## Written from the Unicorn 2.1.4 `unicorn.h`; `tests/tmacros.nim` compares the
## values with the installed headers and checks that no macro is missing.

const
  # Combinations of UC_HOOK_MEM_* bits.
  UC_HOOK_MEM_UNMAPPED* = UC_HOOK_MEM_READ_UNMAPPED or UC_HOOK_MEM_WRITE_UNMAPPED or
                          UC_HOOK_MEM_FETCH_UNMAPPED
    ## Every access to memory that is not mapped.
  UC_HOOK_MEM_PROT* = UC_HOOK_MEM_READ_PROT or UC_HOOK_MEM_WRITE_PROT or UC_HOOK_MEM_FETCH_PROT
    ## Every access the protection of the memory forbids.
  UC_HOOK_MEM_READ_INVALID* = UC_HOOK_MEM_READ_PROT or UC_HOOK_MEM_READ_UNMAPPED
    ## Every read that fails.
  UC_HOOK_MEM_WRITE_INVALID* = UC_HOOK_MEM_WRITE_PROT or UC_HOOK_MEM_WRITE_UNMAPPED
    ## Every write that fails.
  UC_HOOK_MEM_FETCH_INVALID* = UC_HOOK_MEM_FETCH_PROT or UC_HOOK_MEM_FETCH_UNMAPPED
    ## Every fetch of an instruction that fails.
  UC_HOOK_MEM_INVALID* = UC_HOOK_MEM_UNMAPPED or UC_HOOK_MEM_PROT
    ## Every memory access that fails.
  UC_HOOK_MEM_VALID* = UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE or UC_HOOK_MEM_FETCH
    ## Every memory access that succeeds: reads and writes. (Unicorn 2.0 and
    ## 2.1 accept the `UC_HOOK_MEM_FETCH` in it and never call a hook for it;
    ## `UC_HOOK_CODE` sees the instructions that run.)

  UC_CTL_IO_READ_WRITE* = UC_CTL_IO_WRITE or UC_CTL_IO_READ
    ## Direction of a control that both takes and returns something.

func UC_MAKE_VERSION*(major, minor: int): uint32 =
  ## The number the C `uc_version` returns for `major.minor`, patch and extra
  ## being zero. (The macro in the 2.0.x headers computes `(major shl 8) +
  ## minor`, which is not what `uc_version` of 2.0.x returns; this is the
  ## 2.1 definition, which is.)
  uint32((major shl 24) + (minor shl 16))

# uc_ctl. The control code packs the kind, the number of arguments and the
# direction: (type) | (nr << 26) | (rw << 30).

func UC_CTL*(kind: uc_control_type; nr, rw: int): uc_control_type =
  ## The code `uc_ctl` takes for the control `kind` with `nr` arguments and
  ## the direction `rw` (`UC_CTL_IO_NONE`, `_READ`, `_WRITE`, `_READ_WRITE`).
  ## The result is a number, not one of the names of `uc_control_type`.
  cast[uc_control_type](uint32(ord(kind)) or (uint32(nr) shl 26) or (uint32(rw) shl 30))

func UC_CTL_NONE*(kind: uc_control_type; nr: int): uc_control_type =
  ## `UC_CTL` for a control that neither takes nor returns a value.
  UC_CTL(kind, nr, UC_CTL_IO_NONE)

func UC_CTL_READ*(kind: uc_control_type; nr: int): uc_control_type =
  ## `UC_CTL` for a control that returns a value through a pointer.
  UC_CTL(kind, nr, UC_CTL_IO_READ)

func UC_CTL_WRITE*(kind: uc_control_type; nr: int): uc_control_type =
  ## `UC_CTL` for a control that takes a value.
  UC_CTL(kind, nr, UC_CTL_IO_WRITE)

func UC_CTL_READ_WRITE*(kind: uc_control_type; nr: int): uc_control_type =
  ## `UC_CTL` for a control that takes a value and returns one.
  UC_CTL(kind, nr, UC_CTL_IO_READ_WRITE)

proc uc_ctl*(uc: ptr uc_engine; control: uc_control_type): uc_err {.cdecl, varargs, importc: "uc_ctl".}
  ## The C function as it is, for a control that has no `uc_ctl_*` proc.
  ## `control` comes from `UC_CTL_READ` and its siblings. Unicorn reads the
  ## arguments with `va_arg`, so each must have exactly the C type the control
  ## expects (`cint(1)`, not `1`; `uint64`, not `int`); a wrong one is not
  ## diagnosed. Prefer the `uc_ctl_*` procs, which see to that.

# One proc per `uc_ctl_*` macro. The argument types are the ones `uc_ctl` in
# uc.c reads with `va_arg` for that control.

proc uc_ctl_get_mode*(uc: ptr uc_engine; mode: ptr cint): uc_err =
  ## The mode the engine was opened with, as a C `int`.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_MODE, 1), mode)

proc uc_ctl_get_mode*(uc: ptr uc_engine; mode: var uc_mode): uc_err =
  ## The mode the engine was opened with.
  var value: cint
  result = uc_ctl_get_mode(uc, addr value)
  if result == UC_ERR_OK: mode = uc_mode(cast[uint32](value))

proc uc_ctl_get_arch*(uc: ptr uc_engine; arch: ptr cint): uc_err =
  ## The architecture of the engine, as a C `int`.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_ARCH, 1), arch)

proc uc_ctl_get_arch*(uc: ptr uc_engine; arch: var uc_arch): uc_err =
  ## The architecture of the engine.
  var value: cint
  result = uc_ctl_get_arch(uc, addr value)
  if result == UC_ERR_OK: arch = cast[uc_arch](value)

proc uc_ctl_get_page_size*(uc: ptr uc_engine; pageSize: ptr uint32): uc_err =
  ## The page size of the emulated CPU in bytes.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_PAGE_SIZE, 1), pageSize)

proc uc_ctl_set_page_size*(uc: ptr uc_engine; pageSize: uint32): uc_err =
  ## Sets the page size, a power of two. Only for ARM (and ARM64 from Unicorn
  ## 2.1.2 on), and only before the engine is first used for anything else;
  ## `UC_ERR_ARG` otherwise. Unicorn before 2.1.2 sets twice the size given.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_UC_PAGE_SIZE, 1), pageSize)

proc uc_ctl_get_timeout*(uc: ptr uc_engine; timeout: ptr uint64): uc_err =
  ## The timeout of the most recent `uc_emu_start` that had one, in
  ## nanoseconds (the parameter of `uc_emu_start` is in microseconds); 0 when
  ## there has been none.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_TIMEOUT, 1), timeout)

proc uc_ctl_exits_enable*(uc: ptr uc_engine): uc_err =
  ## Makes `uc_emu_start` stop at the addresses given to `uc_ctl_set_exits`
  ## and ignore its `until` parameter.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_UC_USE_EXITS, 1), cint(1))

proc uc_ctl_exits_disable*(uc: ptr uc_engine): uc_err =
  ## Makes `uc_emu_start` stop at its `until` parameter again.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_UC_USE_EXITS, 1), cint(0))

proc uc_ctl_get_exits_cnt*(uc: ptr uc_engine; count: ptr csize_t): uc_err =
  ## The number of exits set. `UC_ERR_ARG` unless exits are enabled.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_EXITS_CNT, 1), count)

proc uc_ctl_get_exits*(uc: ptr uc_engine; buffer: ptr uint64; len: csize_t): uc_err =
  ## Copies the exits to `buffer`, which has room for `len` addresses.
  ## `UC_ERR_ARG` when that is fewer than `uc_ctl_get_exits_cnt` reports or
  ## exits are not enabled.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_EXITS, 2), buffer, len)

proc uc_ctl_get_exits*(uc: ptr uc_engine; exits: var openArray[uint64]): uc_err =
  ## Copies the exits into `exits`, which must have room for at least
  ## `uc_ctl_get_exits_cnt` addresses.
  var none: uint64
  uc_ctl_get_exits(uc, (if exits.len > 0: addr exits[0] else: addr none), csize_t(exits.len))

proc uc_ctl_set_exits*(uc: ptr uc_engine; buffer: ptr uint64; len: csize_t): uc_err =
  ## Replaces the exits by the `len` addresses at `buffer`. `UC_ERR_ARG`
  ## unless exits are enabled.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_UC_EXITS, 2), buffer, len)

proc uc_ctl_set_exits*(uc: ptr uc_engine; exits: openArray[uint64]): uc_err =
  ## Replaces the exits by `exits`; an empty array leaves none, and the
  ## emulation then runs until something stops it.
  var none: uint64
  uc_ctl_set_exits(uc, (if exits.len > 0: unsafeAddr exits[0] else: addr none),
                   csize_t(exits.len))

proc uc_ctl_get_cpu_model*(uc: ptr uc_engine; model: ptr cint): uc_err =
  ## The CPU model, a member of the `uc_cpu_*` enum of the architecture.
  uc_ctl(uc, UC_CTL_READ(UC_CTL_CPU_MODEL, 1), model)

proc uc_ctl_set_cpu_model*(uc: ptr uc_engine; model: cint): uc_err =
  ## Selects the CPU model. Only before the engine is first used for anything
  ## else; `UC_ERR_ARG` afterwards or for a model the architecture lacks.
  ## Unicorn 2.0.0 also answers `UC_ERR_ARG` for model 0, the first member of
  ## each `uc_cpu_*` enum (`UC_CPU_X86_QEMU64`, ...).
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_CPU_MODEL, 1), model)

proc uc_ctl_set_cpu_model*[Model: enum](uc: ptr uc_engine; model: Model): uc_err =
  ## `uc_ctl_set_cpu_model` for the `uc_cpu_*` enums:
  ## `uc_ctl_set_cpu_model(uc, UC_CPU_X86_HASWELL)`.
  uc_ctl_set_cpu_model(uc, cint(ord(model)))

proc uc_ctl_remove_cache*(uc: ptr uc_engine; address, until: uint64): uc_err =
  ## Drops the translations of the code in `address ..< until` (`end` in C;
  ## the address itself is not included), so that it is translated again when
  ## next run. `UC_ERR_ARG` for an empty range.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_TB_REMOVE_CACHE, 2), address, until)

proc uc_ctl_request_cache*(uc: ptr uc_engine; address: uint64; tb: ptr uc_tb): uc_err =
  ## Translates the block at `address` now, keeps the translation for when
  ## the code is run, and describes it in `tb`, which may be nil.
  uc_ctl(uc, UC_CTL_READ_WRITE(UC_CTL_TB_REQUEST_CACHE, 2), address, tb)

proc uc_ctl_flush_tb*(uc: ptr uc_engine): uc_err =
  ## Drops every translation. Works with every Unicorn 2, although the 2.0.x
  ## headers have no macro of this name: they call it `uc_ctl_flush_tlb`.
  uc_ctl(uc, UC_CTL_WRITE(UC_CTL_TB_FLUSH, 0))

when libVersion >= (2, 1, 0):
  proc uc_ctl_flush_tlb*(uc: ptr uc_engine): uc_err =
    ## Empties the TLB, the cache of address translations (Unicorn 2.1). Not
    ## the macro of this name in the 2.0.x headers: that one drops the
    ## translated code, which is `uc_ctl_flush_tb` here.
    uc_ctl(uc, UC_CTL_WRITE(UC_CTL_TLB_FLUSH, 0))

  proc uc_ctl_tlb_mode*(uc: ptr uc_engine; mode: cint): uc_err =
    ## Selects how addresses are translated, as a C `int`.
    uc_ctl(uc, UC_CTL_WRITE(UC_CTL_TLB_TYPE, 1), mode)

  proc uc_ctl_tlb_mode*(uc: ptr uc_engine; mode: uc_tlb_type): uc_err =
    ## Selects how addresses are translated: `UC_TLB_CPU`, the page tables of
    ## the emulated CPU (the default), or `UC_TLB_VIRTUAL`, the `UC_HOOK_TLB_FILL`
    ## hooks.
    uc_ctl_tlb_mode(uc, cint(ord(mode)))

  proc uc_ctl_get_tcg_buffer_size*(uc: ptr uc_engine; size: ptr uint32): uc_err =
    ## The size of the buffer for translated code in bytes.
    uc_ctl(uc, UC_CTL_READ(UC_CTL_TCG_BUFFER_SIZE, 1), size)

  proc uc_ctl_set_tcg_buffer_size*(uc: ptr uc_engine; size: uint32): uc_err =
    ## Sets the size of the buffer for translated code. It takes effect when
    ## the engine is first used for anything else.
    uc_ctl(uc, UC_CTL_WRITE(UC_CTL_TCG_BUFFER_SIZE, 1), size)

  proc uc_ctl_context_mode*(uc: ptr uc_engine; mode: cint): uc_err =
    ## Selects what `uc_context_save` and `uc_context_restore` cover: a
    ## combination of `UC_CTL_CONTEXT_*` values, as a C `int`
    ## (`cint(ord(UC_CTL_CONTEXT_CPU) or ord(UC_CTL_CONTEXT_MEMORY))`).
    uc_ctl(uc, UC_CTL_WRITE(UC_CTL_CONTEXT_MODE, 1), mode)

  proc uc_ctl_context_mode*(uc: ptr uc_engine; mode: uc_context_content): uc_err =
    ## Selects what `uc_context_save` and `uc_context_restore` cover:
    ## `UC_CTL_CONTEXT_CPU`, the registers (the default), or
    ## `UC_CTL_CONTEXT_MEMORY`, the memory. For both use the `cint` overload.
    uc_ctl_context_mode(uc, cint(ord(mode)))
else:
  unavailable(uc_ctl_flush_tlb, "2.1.0",
              "(In the Unicorn 2.0 headers this name drops the translated code; that is " &
              "uc_ctl_flush_tb here.)")
  unavailable(uc_ctl_tlb_mode, "2.1.0")
  unavailable(uc_ctl_get_tcg_buffer_size, "2.1.0")
  unavailable(uc_ctl_set_tcg_buffer_size, "2.1.0")
  unavailable(uc_ctl_context_mode, "2.1.0")
