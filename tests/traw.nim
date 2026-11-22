## The C API layer (`libunicorn/raw`): versions and what a library version
## makes available, flags, the C declarations for memory, registers and
## running code as they are, and error codes that cannot be dropped.
## Each test runs on an x86-64 engine; tests for another architecture are
## skipped when the library was built without it.

import std/[strutils, unittest]
import libunicorn/raw

const
  codeAddress = 0x1000'u64
  dataAddress = 0x2000'u64
  rax = cint(ord(UC_X86_REG_RAX))
  eax = cint(ord(UC_X86_REG_EAX))

suite "versions":
  test "the library reports major, minor, patch and extra":
    var major, minor: cuint
    let combined = uc_version(addr major, addr minor)
    let v = uc_version()
    check v.major == int(major)
    check v.minor == int(minor)
    check v.major == 2
    check v.patch == int((combined shr 8) and 0xff)
    check v.extra == int(combined and 0xff)

  test "the bindings say what they were generated from":
    check bindingsVersion == (int(UC_API_MAJOR), int(UC_API_MINOR), int(UC_API_PATCH))
    check bindingsVersion >= (2, 1, 4)
    check UC_VERSION_MAJOR == UC_API_MAJOR

  test "the loaded library is one this build can use":
    let v = uc_version()
    check libraryMatchesBindings()
    check (v.major, v.minor, v.patch) >= libVersion
    check libVersionText.startsWith($libVersion[0] & "." & $libVersion[1])
    var uc: ptr uc_engine
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
    check uc != nil
    check uc_close(uc) == UC_ERR_OK

  test "which library versions this build accepts":
    check libraryVersionFits(uc_version())
    check libraryVersionFits((libVersion[0], libVersion[1], libVersion[2], 255))
    # Another major version, or older than what the program was built against.
    check not libraryVersionFits((1, 0, 3, 0))
    check not libraryVersionFits((3, 0, 0, 255))
    if libVersion > (2, 0, 0):
      check not libraryVersionFits((2, 0, 0, 255))
    when sizeof(csize_t) == 8:
      # Newer is fine.
      check libraryVersionFits((2, 99, 0, 255))
      if libVersion < (2, 1, 4):
        check libraryVersionFits((2, 1, 4, 255))
    else:
      # On a 32-bit target Unicorn 2.1.4 has other size parameters than the
      # releases before it; newer is fine on the same side of that change only.
      if libVersion < (2, 1, 4):
        check libraryVersionFits((2, 1, 3, 255))
        check not libraryVersionFits((2, 1, 4, 255))
        check not libraryVersionFits((2, 99, 0, 255))
      else:
        check libraryVersionFits((2, 99, 0, 255))

  test "what the library is too old for does not compile":
    var
      uc {.used.}: ptr uc_engine
      ctx {.used.}: ptr uc_context
      value {.used.}: uint64
      size {.used.} = csize_t(8)
      paddr {.used.}: uint64
    # Added in Unicorn 2.1.0.
    check compiles(uc_reg_read2(uc, rax, addr value, addr size)) == (libVersion >= (2, 1, 0))
    check compiles(uc_reg_write2(uc, rax, addr value, addr size)) == (libVersion >= (2, 1, 0))
    check compiles(uc_context_reg_read2(ctx, rax, addr value, addr size)) ==
      (libVersion >= (2, 1, 0))
    # Added in Unicorn 2.1.4.
    check compiles(uc_vmem_translate(uc, 0x1000, UC_PROT_READ, addr paddr)) ==
      (libVersion >= (2, 1, 4))
    check compiles(uc_vmem_read(uc, 0x1000, UC_PROT_READ, addr value, 8)) ==
      (libVersion >= (2, 1, 4))
    # There since 2.0.0, and constants are declared whatever the library.
    check compiles(uc_reg_read(uc, rax, addr value))
    check declared(UC_ERR_OVERFLOW)
    check declared(UC_HOOK_TLB_FILL)

  test "an architecture or mode the library lacks is an error code":
    var uc: ptr uc_engine
    check uc_open(UC_ARCH_MAX, UC_MODE_32, addr uc) == UC_ERR_ARCH
    check uc_open(UC_ARCH_X86, UC_MODE_THUMB, addr uc) == UC_ERR_MODE
    check uc_arch_supported(UC_ARCH_X86)
    check not uc_arch_supported(UC_ARCH_MAX)

suite "flags":
  test "modes combine with `or`":
    if not uc_arch_supported(UC_ARCH_ARM):
      skip()
    else:
      var uc: ptr uc_engine
      require uc_open(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_BIG_ENDIAN, addr uc) == UC_ERR_OK
      var mode: csize_t
      check uc_query(uc, UC_QUERY_MODE, addr mode) == UC_ERR_OK
      check UC_MODE_BIG_ENDIAN in uc_mode(mode)
      check uc_close(uc) == UC_ERR_OK

  test "flags print as their bits and compare":
    check $UC_MODE_64 == "0x00000008"
    check $(UC_MODE_ARM or UC_MODE_BIG_ENDIAN) == "0x40000000"
    check $(UC_PROT_READ or UC_PROT_EXEC) == "0x00000005"
    check $(UC_HOOK_CODE or UC_HOOK_BLOCK) == "0x0000000C"
    check (UC_PROT_READ or UC_PROT_WRITE or UC_PROT_EXEC) == UC_PROT_ALL
    check (UC_PROT_ALL and UC_PROT_WRITE) == UC_PROT_WRITE
    check UC_PROT_WRITE in UC_PROT_ALL
    check UC_PROT_WRITE notin (UC_PROT_READ or UC_PROT_EXEC)
    check UC_PROT_NONE in UC_PROT_READ
    check not (UC_PROT_READ == UC_PROT_WRITE)

  test "flag types do not mix":
    var uc {.used.}: ptr uc_engine
    check not compiles(UC_PROT_READ or UC_MODE_64)
    check not compiles(UC_HOOK_CODE == UC_PROT_EXEC)
    check not compiles(uc_open(UC_ARCH_X86, UC_PROT_READ, addr uc))

suite "memory":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
    require uc_mem_map(uc, codeAddress, 0x2000, uint32(UC_PROT_ALL)) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "sizes have the type the library takes":
    # `uint64_t` from Unicorn 2.1.4 on, `size_t` before.
    check sizeof(uc_size) == (if libVersion >= (2, 1, 4): 8 else: sizeof(csize_t))

  test "bytes are written and read back":
    var data = [1'u8, 2, 3, 4]
    check uc_mem_write(uc, dataAddress, addr data[0], uc_size(data.len)) == UC_ERR_OK
    var back: array[4, byte]
    check uc_mem_read(uc, dataAddress, addr back[0], uc_size(back.len)) == UC_ERR_OK
    check back == data
    # What Unicorn refuses comes back as an error code.
    check uc_mem_write(uc, 0x900000, addr data[0], uc_size(data.len)) == UC_ERR_WRITE_UNMAPPED
    check uc_mem_read(uc, 0x900000, addr back[0], uc_size(back.len)) == UC_ERR_READ_UNMAPPED
    check uc_mem_map(uc, codeAddress, 0x1000, uint32(UC_PROT_ALL)) == UC_ERR_MAP

  test "protecting and unmapping change the regions":
    check uc_mem_protect(uc, dataAddress, 0x1000, uint32(UC_PROT_READ)) == UC_ERR_OK
    var first: ptr uc_mem_region
    var count: uint32
    require uc_mem_regions(uc, addr first, addr count) == UC_ERR_OK
    require count == 2
    let regions = cast[ptr UncheckedArray[uc_mem_region]](first)
    check regions[0].begin == codeAddress
    check regions[0].last == codeAddress + 0xfff
    check uc_prot(regions[0].perms) == UC_PROT_ALL
    check regions[1].begin == dataAddress
    check regions[1].last == dataAddress + 0xfff
    check uc_prot(regions[1].perms) == UC_PROT_READ
    check uc_free(first) == UC_ERR_OK
    check uc_mem_unmap(uc, dataAddress, 0x1000) == UC_ERR_OK
    var one = 1'u8
    check uc_mem_write(uc, dataAddress, addr one, 1) == UC_ERR_WRITE_UNMAPPED

suite "registers":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "a register is written and read back":
    var value = 0x1122334455667788'u64
    check uc_reg_write(uc, rax, addr value) == UC_ERR_OK
    var low: uint32
    check uc_reg_read(uc, eax, addr low) == UC_ERR_OK
    check low == 0x55667788'u32
    var again: uint64
    check uc_reg_read(uc, rax, addr again) == UC_ERR_OK
    check again == value

  test "an instruction that runs changes its register":
    var code = [0x48'u8, 0xff, 0xc0]  # inc rax
    require uc_mem_map(uc, codeAddress, 0x1000, uint32(UC_PROT_ALL)) == UC_ERR_OK
    require uc_mem_write(uc, codeAddress, addr code[0], uc_size(code.len)) == UC_ERR_OK
    var value = 41'u64
    require uc_reg_write(uc, rax, addr value) == UC_ERR_OK
    check uc_emu_start(uc, codeAddress, codeAddress + uint64(code.len), 0, 0) == UC_ERR_OK
    check uc_reg_read(uc, rax, addr value) == UC_ERR_OK
    check value == 42

suite "error codes":
  # Whether `call` can stand as a statement of its own, followed by another
  # one. (`compiles(call)` alone would not tell: there it is an expression.)
  template compilesAsStatement(call: untyped): bool =
    compiles:
      call
      discard 0

  # The control: the same call with its result discarded.
  template compilesDiscarded(call: untyped): bool =
    compiles:
      discard call
      discard 0

  template mustBeUsed(call: untyped) =
    check compilesDiscarded(call)        # the call itself is right ...
    check not compilesAsStatement(call)  # ... and its error code cannot be dropped

  test "an error code is a value that must be used":
    var
      uc {.used.}: ptr uc_engine
      value {.used.}: uint64
    mustBeUsed uc_open(UC_ARCH_X86, UC_MODE_64, addr uc)
    mustBeUsed uc_close(uc)
    mustBeUsed uc_mem_map(uc, 0x1000, 0x1000, 7'u32)
    mustBeUsed uc_mem_unmap(uc, 0x1000, 0x1000)
    mustBeUsed uc_mem_write(uc, 0x1000, addr value, uc_size(8))
    mustBeUsed uc_reg_write(uc, rax, addr value)
    mustBeUsed uc_reg_read(uc, rax, addr value)
    mustBeUsed uc_emu_start(uc, 0x1000, 0x1001, 0, 0)
    mustBeUsed uc_emu_stop(uc)
    mustBeUsed uc_free(nil)
