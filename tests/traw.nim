## The C API layer (`libunicorn/raw`): versions and what a library version
## makes available, flags, memory, registers, every kind of hook with the
## callback type it takes, contexts, error codes that cannot be dropped,
## queries and the names things print as.
## Each test runs a few x86-64 instructions; tests for another architecture
## are skipped when the library was built without it.

import std/[strutils, unittest]
import libunicorn/raw

const
  codeAddress = 0x1000'u64
  dataAddress = 0x2000'u64

type
  Seen = object
    ## What a hook callback saw; `user_data` points to one.
    calls: int
    addresses: seq[uint64]
    sizes: seq[int]
    kinds: seq[uc_mem_type]
    values: seq[int64]
    repair: bool
    errors: int

template seen(user_data: pointer): var Seen = cast[ptr Seen](user_data)[]

# One callback per callback type.

proc onCode(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add address
  user_data.seen.sizes.add int(size)

proc onInterrupt(uc: ptr uc_engine; intno: uint32; user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.values.add int64(intno)

proc onMem(uc: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint; value: int64;
           user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.kinds.add kind
  user_data.seen.addresses.add address
  user_data.seen.sizes.add int(size)
  user_data.seen.values.add value

proc onFault(uc: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint; value: int64;
             user_data: pointer): bool {.cdecl.} =
  ## Repairs the fault when asked to: maps the page, or lifts the protection.
  ## For an access that succeeds there is nothing to repair, and Unicorn does
  ## not look at the result.
  inc user_data.seen.calls
  user_data.seen.kinds.add kind
  user_data.seen.addresses.add address
  if not user_data.seen.repair: return false
  if kind in {UC_MEM_READ, UC_MEM_WRITE, UC_MEM_FETCH, UC_MEM_READ_AFTER}: return false
  let page = address and not 0xfff'u64
  let err =
    if kind in {UC_MEM_READ_UNMAPPED, UC_MEM_WRITE_UNMAPPED, UC_MEM_FETCH_UNMAPPED}:
      uc_mem_map(uc, page, 0x1000, UC_PROT_ALL)
    else:
      uc_mem_protect(uc, page, 0x1000, UC_PROT_ALL)
  if err != UC_ERR_OK: inc user_data.seen.errors
  if kind == UC_MEM_FETCH_UNMAPPED and uc_mem_write(uc, address, [0x90'u8]) != UC_ERR_OK:
    inc user_data.seen.errors
  true

proc onInvalid(uc: ptr uc_engine; user_data: pointer): bool {.cdecl.} =
  ## Steps over the two-byte instruction when asked to repair.
  inc user_data.seen.calls
  if not user_data.seen.repair: return false
  var rip: uint64
  if uc_reg_read(uc, UC_X86_REG_RIP, addr rip) != UC_ERR_OK: inc user_data.seen.errors
  rip += 2
  if uc_reg_write(uc, UC_X86_REG_RIP, addr rip) != UC_ERR_OK: inc user_data.seen.errors
  true

proc onSyscall(uc: ptr uc_engine; user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls

proc onIn(uc: ptr uc_engine; port: uint32; size: cint; user_data: pointer): uint32 {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add port
  user_data.seen.sizes.add int(size)
  0x42

proc onOut(uc: ptr uc_engine; port: uint32; size: cint; value: uint32;
           user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add port
  user_data.seen.sizes.add int(size)
  user_data.seen.values.add int64(value)

proc onCpuid(uc: ptr uc_engine; user_data: pointer): cint {.cdecl.} =
  ## Answers the instruction itself and has Unicorn skip it.
  inc user_data.seen.calls
  var answer = 0x1234'u64
  if uc_reg_write(uc, UC_X86_REG_RAX, addr answer) != UC_ERR_OK: inc user_data.seen.errors
  1

proc onSys(uc: ptr uc_engine; reg: uc_arm64_reg; cp_reg: ptr uc_arm64_cp_reg;
           user_data: pointer): uint32 {.cdecl.} =
  inc user_data.seen.calls
  var answer = 0x114514'u64
  if uc_reg_write(uc, reg, addr answer) != UC_ERR_OK: inc user_data.seen.errors
  1

proc onTlbFill(uc: ptr uc_engine; vaddr: uint64; kind: uc_mem_type; entry: ptr uc_tlb_entry;
               user_data: pointer): bool {.cdecl.} =
  ## Maps every virtual page to the physical page one page further up.
  inc user_data.seen.calls
  user_data.seen.addresses.add vaddr
  entry.paddr = (vaddr and not 0xfff'u64) + 0x1000
  entry.perms = UC_PROT_ALL
  true

proc onEdge(uc: ptr uc_engine; cur_tb, prev_tb: ptr uc_tb; user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add cur_tb.pc

proc onSub(uc: ptr uc_engine; address, arg1, arg2: uint64; size: uint32;
           user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add address
  user_data.seen.values.add int64(arg1)
  user_data.seen.values.add int64(arg2)
  user_data.seen.sizes.add int(size)

proc onMmioRead(uc: ptr uc_engine; offset: uint64; size: cuint; user_data: pointer): uint64 {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add offset
  user_data.seen.sizes.add int(size)
  0x11223300'u64 + offset

proc onMmioWrite(uc: ptr uc_engine; offset: uint64; size: cuint; value: uint64;
                 user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  user_data.seen.addresses.add offset
  user_data.seen.sizes.add int(size)
  user_data.seen.values.add cast[int64](value)

proc onCodeStop(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  inc user_data.seen.calls
  if uc_emu_stop(uc) != UC_ERR_OK: inc user_data.seen.errors

# What must not be accepted as a `UC_HOOK_CODE` callback.

proc codeWithoutCdecl(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) =
  discard

proc codeWithNimIntegers(uc: ptr uc_engine; address: uint; size: int;
                         user_data: pointer) {.cdecl.} =
  discard

proc codeThatCanRaise(uc: ptr uc_engine; address: uint64; size: uint32;
                      user_data: pointer) {.cdecl.} =
  discard parseInt("not a number")

proc run(uc: ptr uc_engine; code: openArray[byte]; count = 0): uc_err =
  ## Puts `code` at `codeAddress` and runs it to its end, or for `count`
  ## instructions.
  result = uc_mem_write(uc, codeAddress, code)
  if result == UC_ERR_OK:
    result = uc_emu_start(uc, codeAddress, codeAddress + uint64(code.len), 0, csize_t(count))

proc reg(uc: ptr uc_engine; regid: uc_x86_reg): uint64 =
  doAssert uc_reg_read(uc, regid, addr result) == UC_ERR_OK

const
  loadStore = [0x48'u8, 0x8b, 0x04, 0x25, 0x00, 0x20, 0x00, 0x00,  # mov rax, [0x2000]
               0x48, 0x89, 0x04, 0x25, 0x08, 0x20, 0x00, 0x00,     # mov [0x2008], rax
               0x90]                                               # nop
  twoBlocks = [0xeb'u8, 0x00,                                      # jmp to the next instruction
               0x90]                                               # nop
  storeFar = [0x48'u8, 0x89, 0x04, 0x25, 0x10, 0x00, 0x50, 0x00,   # mov [0x500010], rax
              0x90]                                                # nop
  loadFar = [0x48'u8, 0x8b, 0x1c, 0x25, 0x10, 0x00, 0x50, 0x00,    # mov rbx, [0x500010]
             0x90]                                                 # nop

suite "versions":
  test "the library reports major, minor, patch and extra":
    var major, minor: cuint
    let combined = uc_version(addr major, addr minor)
    let v = uc_version()
    check v.major == int(major)
    check v.minor == int(minor)
    check v.major == 2
    check v.extra == int(combined and 0xff)
    check (combined and 0xffff0000'u32) == UC_MAKE_VERSION(v.major, v.minor)

  test "the bindings say what they were generated from":
    check bindingsVersion == (int(UC_API_MAJOR), int(UC_API_MINOR), int(UC_API_PATCH))
    check bindingsVersion >= (2, 1, 4)
    check UC_VERSION_MAJOR == UC_API_MAJOR
    check UC_SECOND_SCALE == 1_000_000
    check UC_MILISECOND_SCALE == 1_000

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
    check compiles(uc_reg_read2(uc, UC_X86_REG_RAX, addr value, addr size)) ==
      (libVersion >= (2, 1, 0))
    check compiles(uc_reg_write2(uc, cint(1), addr value, addr size)) == (libVersion >= (2, 1, 0))
    check compiles(uc_context_reg_read2(ctx, UC_X86_REG_RAX, addr value, addr size)) ==
      (libVersion >= (2, 1, 0))
    check compiles(uc_ctl_flush_tlb(uc)) == (libVersion >= (2, 1, 0))
    check compiles(uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL)) == (libVersion >= (2, 1, 0))
    # Added in Unicorn 2.1.4.
    check compiles(uc_vmem_translate(uc, 0x1000, UC_PROT_READ, addr paddr)) ==
      (libVersion >= (2, 1, 4))
    check compiles(uc_vmem_read(uc, 0x1000, UC_PROT_READ, addr value, 8)) ==
      (libVersion >= (2, 1, 4))
    # There since 2.0.0, and constants are declared whatever the library.
    check compiles(uc_ctl_flush_tb(uc))
    check compiles(uc_reg_read(uc, UC_X86_REG_RAX, addr value))
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
    check UC_HOOK_MEM_READ in UC_HOOK_MEM_VALID
    check UC_HOOK_MEM_WRITE_PROT in UC_HOOK_MEM_INVALID
    check not (UC_PROT_READ == UC_PROT_WRITE)

  test "flag types do not mix":
    var uc {.used.}: ptr uc_engine
    check not compiles(UC_PROT_READ or UC_MODE_64)
    check not compiles(UC_HOOK_CODE == UC_PROT_EXEC)
    check not compiles(uc_open(UC_ARCH_X86, UC_PROT_READ, addr uc))
    check not compiles(uc_mem_map(uc, 0x1000, 0x1000, UC_MODE_64))

suite "memory":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
    require uc_mem_map(uc, codeAddress, 0x2000, UC_PROT_ALL) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "Nim buffers are written and read back":
    const fixed = [1'u8, 2, 3, 4]
    let dynamic = @[5'u8, 6, 7]
    check uc_mem_write(uc, dataAddress, fixed) == UC_ERR_OK
    check uc_mem_write(uc, dataAddress + 4, dynamic) == UC_ERR_OK
    check uc_mem_write(uc, dataAddress + 7, "hi".toOpenArrayByte(0, 1)) == UC_ERR_OK
    var back = newSeq[byte](9)
    check uc_mem_read(uc, dataAddress, back) == UC_ERR_OK
    check back == @[1'u8, 2, 3, 4, 5, 6, 7, byte('h'), byte('i')]
    var part: array[2, byte]
    check uc_mem_read(uc, dataAddress + 2, part) == UC_ERR_OK
    check part == [3'u8, 4]

  test "an empty buffer is no access at all":
    var nothing: seq[byte]
    check uc_mem_write(uc, dataAddress, nothing) == UC_ERR_OK
    check uc_mem_read(uc, dataAddress, nothing) == UC_ERR_OK
    # Not even where nothing is mapped.
    check uc_mem_write(uc, 0x900000, nothing) == UC_ERR_OK
    check uc_mem_read(uc, 0x900000, nothing) == UC_ERR_OK
    check uc_mem_write(uc, 0x900000, [1'u8]) == UC_ERR_WRITE_UNMAPPED
    var one: array[1, byte]
    check uc_mem_read(uc, 0x900000, one) == UC_ERR_READ_UNMAPPED

  test "pointer and length: int, csize_t and uc_size in one module":
    # The C compiler sees one prototype for each function, whatever the Nim
    # type of the length.
    var value = 0x1122334455667788'u64
    check uc_mem_write(uc, dataAddress, addr value, sizeof(value)) == UC_ERR_OK
    check uc_mem_write(uc, dataAddress + 8, addr value, csize_t(4)) == UC_ERR_OK
    check uc_mem_write(uc, dataAddress + 12, addr value, uc_size(2)) == UC_ERR_OK
    var back: array[14, byte]
    check uc_mem_read(uc, dataAddress, addr back[0], back.len) == UC_ERR_OK
    check back == [0x88'u8, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55,
                   0x88, 0x77]
    var again: uint32
    check uc_mem_read(uc, dataAddress, addr again, csize_t(4)) == UC_ERR_OK
    check again == 0x55667788'u32
    check uc_mem_read(uc, dataAddress + 4, addr again, uc_size(sizeof(again))) == UC_ERR_OK
    check again == 0x11223344'u32
    let negative = -1
    check uc_mem_write(uc, dataAddress, addr value, negative) == UC_ERR_ARG
    check uc_mem_read(uc, dataAddress, addr value, negative) == UC_ERR_ARG

  test "protection is flags or a number":
    check uc_mem_map(uc, 0x10000, 0x1000, UC_PROT_READ or UC_PROT_WRITE) == UC_ERR_OK
    check uc_mem_map(uc, 0x11000, 0x1000, 5'u32) == UC_ERR_OK
    check uc_mem_protect(uc, 0x10000, 0x1000, UC_PROT_READ) == UC_ERR_OK
    check uc_mem_protect(uc, 0x11000, 0x1000, uint32(UC_PROT_ALL)) == UC_ERR_OK
    var first: ptr uc_mem_region
    var count: uint32
    require uc_mem_regions(uc, addr first, addr count) == UC_ERR_OK
    var found: seq[string]
    for region in regions(first, count):
      found.add toHex(region.begin, 5) & ".." & toHex(region.last, 5) & " " & $uc_prot(region.perms)
    check found == @["01000..02FFF 0x00000007", "10000..10FFF 0x00000001",
                     "11000..11FFF 0x00000007"]
    check uc_free(first) == UC_ERR_OK
    # What Unicorn refuses comes back as an error code.
    check uc_mem_map(uc, 0x10000, 0x1000, UC_PROT_ALL) == UC_ERR_MAP
    check uc_mem_map(uc, 0x20000, 0x123, UC_PROT_ALL) == UC_ERR_ARG
    check uc_mem_map(uc, 0x20000, 0x1000, 0xff'u32) == UC_ERR_ARG

  test "regions of an engine without memory":
    var empty: ptr uc_engine
    require uc_open(UC_ARCH_X86, UC_MODE_32, addr empty) == UC_ERR_OK
    var first: ptr uc_mem_region
    var count = 7'u32
    require uc_mem_regions(empty, addr first, addr count) == UC_ERR_OK
    check count == 0
    var n = 0
    for region in regions(first, count): inc n
    check n == 0
    check uc_free(first) == UC_ERR_OK
    check uc_close(empty) == UC_ERR_OK

  test "unmapping splits a region":
    check uc_mem_map(uc, 0x40000, 0x3000, UC_PROT_ALL) == UC_ERR_OK
    check uc_mem_unmap(uc, 0x41000, 0x1000) == UC_ERR_OK
    check uc_mem_write(uc, 0x41000, [1'u8]) == UC_ERR_WRITE_UNMAPPED
    check uc_mem_write(uc, 0x42000, [1'u8]) == UC_ERR_OK
    check uc_mem_unmap(uc, 0x41000, 0x1000) == UC_ERR_NOMEM

  test "host memory mapped into the emulator":
    var host = newSeq[byte](0x1000)
    host[0] = 0xaa
    check uc_mem_map_ptr(uc, 0x30000, 0x1000, UC_PROT_READ or UC_PROT_WRITE,
                         addr host[0]) == UC_ERR_OK
    var first: array[1, byte]
    check uc_mem_read(uc, 0x30000, first) == UC_ERR_OK
    check first[0] == 0xaa
    check uc_mem_write(uc, 0x30001, [0xbb'u8]) == UC_ERR_OK
    check host[1] == 0xbb
    check uc_mem_unmap(uc, 0x30000, 0x1000) == UC_ERR_OK
    check uc_mem_map_ptr(uc, 0x30000, 0x1000, 3'u32, addr host[0]) == UC_ERR_OK
    check uc_mem_unmap(uc, 0x30000, 0x1000) == UC_ERR_OK
    check uc_mem_map_ptr(uc, 0x30000, 0x1000, UC_PROT_ALL, nil) == UC_ERR_ARG

  test "memory-mapped I/O goes to the callbacks":
    var reads, writes: Seen
    check uc_mmio_map(uc, 0x8000, 0x1000, onMmioRead, addr reads, onMmioWrite,
                      addr writes) == UC_ERR_OK
    const code = [0x8b'u8, 0x04, 0x25, 0x10, 0x80, 0x00, 0x00,  # mov eax, [0x8010]
                  0x89, 0x04, 0x25, 0x20, 0x80, 0x00, 0x00]     # mov [0x8020], eax
    check uc.run(code) == UC_ERR_OK
    check reads.addresses == @[0x10'u64]
    check reads.sizes == @[4]
    check uc.reg(UC_X86_REG_RAX) == 0x11223310
    check writes.calls == 1
    check writes.addresses == @[0x20'u64]
    check writes.sizes == @[4]
    check writes.values == @[0x11223310'i64]

  test "memory-mapped I/O without a callback lacks that permission":
    var reads, writes: Seen
    check uc_mmio_map(uc, 0x8000, 0x1000, nil, nil, onMmioWrite, addr writes) == UC_ERR_OK
    check uc_mmio_map(uc, 0xa000, 0x1000, onMmioRead, addr reads, nil, nil) == UC_ERR_OK
    var first: ptr uc_mem_region
    var count: uint32
    require uc_mem_regions(uc, addr first, addr count) == UC_ERR_OK
    for region in regions(first, count):
      if region.begin == 0x8000: check uc_prot(region.perms) == UC_PROT_WRITE
      if region.begin == 0xa000: check uc_prot(region.perms) == UC_PROT_READ
    check uc_free(first) == UC_ERR_OK
    const
      load8 = [0x8b'u8, 0x04, 0x25, 0x10, 0x80, 0x00, 0x00]   # mov eax, [0x8010]
      store8 = [0x89'u8, 0x04, 0x25, 0x20, 0x80, 0x00, 0x00]  # mov [0x8020], eax
      loadA = [0x8b'u8, 0x04, 0x25, 0x10, 0xa0, 0x00, 0x00]   # mov eax, [0xa010]
      storeA = [0x89'u8, 0x04, 0x25, 0x20, 0xa0, 0x00, 0x00]  # mov [0xa020], eax
    check uc.run(load8) == UC_ERR_READ_PROT
    check uc.run(store8) == UC_ERR_OK
    check uc.run(loadA) == UC_ERR_OK
    check uc.run(storeA) == UC_ERR_WRITE_PROT
    check reads.calls == 1
    check writes.calls == 1

suite "registers":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "register ids are the enums they come from":
    var rax = 0x1122334455667788'u64
    check uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    var eax: uint32
    check uc_reg_read(uc, UC_X86_REG_EAX, addr eax) == UC_ERR_OK
    check eax == 0x55667788'u32
    var ax: uint16
    check uc_reg_read(uc, UC_X86_REG_AX, addr ax) == UC_ERR_OK
    check ax == 0x7788'u16
    # The C declaration with a plain number is still there.
    var again: uint64
    check uc_reg_read(uc, cint(ord(UC_X86_REG_RAX)), addr again) == UC_ERR_OK
    check again == rax

  test "a wide register needs a variable of its size":
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = byte(i + 1)
    check uc_reg_write(uc, UC_X86_REG_XMM3, addr xmm) == UC_ERR_OK
    var back: array[16, byte]
    check uc_reg_read(uc, UC_X86_REG_XMM3, addr back) == UC_ERR_OK
    check back == xmm
    var gdtr = uc_x86_mmr(base: 0x4000, limit: 0xfff)
    check uc_reg_write(uc, UC_X86_REG_GDTR, addr gdtr) == UC_ERR_OK
    var gdtrBack: uc_x86_mmr
    check uc_reg_read(uc, UC_X86_REG_GDTR, addr gdtrBack) == UC_ERR_OK
    check gdtrBack.base == 0x4000
    check gdtrBack.limit == 0xfff

  test "the register enum of another architecture":
    if not uc_arch_supported(UC_ARCH_ARM):
      skip()
    else:
      var arm: ptr uc_engine
      require uc_open(UC_ARCH_ARM, UC_MODE_ARM, addr arm) == UC_ERR_OK
      var r0 = 0x12345678'u32
      check uc_reg_write(arm, UC_ARM_REG_R0, addr r0) == UC_ERR_OK
      var back: uint32
      check uc_reg_read(arm, UC_ARM_REG_R0, addr back) == UC_ERR_OK
      check back == 0x12345678'u32
      var sp = 0x8000'u32
      check uc_reg_write(arm, UC_ARM_REG_R13, addr sp) == UC_ERR_OK  # an alias of UC_ARM_REG_SP
      check uc_reg_read(arm, UC_ARM_REG_SP, addr back) == UC_ERR_OK
      check back == 0x8000'u32
      check uc_close(arm) == UC_ERR_OK

  test "several registers in one call":
    var
      rax = 1'u64
      rbx = 2'u64
      rcx = 3'u64
    const ids = [UC_X86_REG_RAX, UC_X86_REG_RBX, UC_X86_REG_RCX]
    check uc_reg_write_batch(uc, ids, [pointer(addr rax), addr rbx, addr rcx]) == UC_ERR_OK
    check uc.reg(UC_X86_REG_RBX) == 2
    var a, b, c: uint64
    check uc_reg_read_batch(uc, @ids, @[pointer(addr a), addr b, addr c]) == UC_ERR_OK
    check [a, b, c] == [1'u64, 2, 3]
    # The C declaration takes the arrays as pointers and a count.
    var
      rawIds = [cint(ord(UC_X86_REG_RCX)), cint(ord(UC_X86_REG_RAX))]
      rawVals = [pointer(addr a), addr b]
    check uc_reg_read_batch(uc, addr rawIds[0], addr rawVals[0], 2) == UC_ERR_OK
    check [a, b] == [3'u64, 1]

  test "a batch needs as many values as registers":
    var a, b: uint64
    check uc_reg_read_batch(uc, [UC_X86_REG_RAX, UC_X86_REG_RBX], [pointer(addr a)]) == UC_ERR_ARG
    check uc_reg_write_batch(uc, [UC_X86_REG_RAX], [pointer(addr a), addr b]) == UC_ERR_ARG
    let none: seq[uc_x86_reg] = @[]
    let noValues: seq[pointer] = @[]
    check uc_reg_read_batch(uc, none, noValues) == UC_ERR_OK
    check uc_reg_write_batch(uc, none, noValues) == UC_ERR_OK
    check uc_reg_write_batch(uc, none, [pointer(addr a)]) == UC_ERR_ARG

  test "an enum of another size is not a register enum":
    type Small = enum small0, small1
    var a {.used.}: uint64
    check not compiles(uc_reg_read_batch(uc, [small0, small1], [pointer(addr a), addr a]))
    check compiles(uc_reg_read_batch(uc, [UC_X86_REG_RAX], [pointer(addr a)]))
    check sizeof(uc_x86_reg) == sizeof(cint)
    check sizeof(uc_arm64_reg) == sizeof(cint)

  test "registers with their sizes (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      var rax = 0x1122334455667788'u64
      var size = csize_t(sizeof(rax))
      check uc_reg_write2(uc, UC_X86_REG_RAX, addr rax, addr size) == UC_ERR_OK
      var back: uint64
      size = csize_t(sizeof(back))
      check uc_reg_read2(uc, UC_X86_REG_RAX, addr back, addr size) == UC_ERR_OK
      check back == rax
      check size == 8
      # Too small a variable is an error, not an overrun.
      var small = 0xdeadbeef'u32
      size = csize_t(sizeof(small))
      check uc_reg_read2(uc, UC_X86_REG_RAX, addr small, addr size) == UC_ERR_OVERFLOW
      check small == 0xdeadbeef'u32
      var guarded = [0x11'u64, 0x22]
      size = 8
      check uc_reg_read2(uc, UC_X86_REG_XMM0, addr guarded[0], addr size) == UC_ERR_OVERFLOW
      check guarded == [0x11'u64, 0x22]
      size = 4
      check uc_reg_write2(uc, UC_X86_REG_RAX, addr small, addr size) == UC_ERR_OVERFLOW
      check uc.reg(UC_X86_REG_RAX) == rax
      # The C declaration with a plain number.
      size = 8
      check uc_reg_read2(uc, cint(ord(UC_X86_REG_RAX)), addr back, addr size) == UC_ERR_OK
    else:
      skip()

  test "several registers with their sizes (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      var
        rax = 7'u64
        xmm: array[16, byte]
        sizes = [csize_t(8), 16]
      xmm[15] = 0x99
      const ids = [UC_X86_REG_RAX, UC_X86_REG_XMM1]
      check uc_reg_write_batch2(uc, ids, [pointer(addr rax), addr xmm], sizes) == UC_ERR_OK
      var
        raxBack: uint64
        xmmBack: array[16, byte]
        room = @[csize_t(8), 16]
      check uc_reg_read_batch2(uc, ids, [pointer(addr raxBack), addr xmmBack], room) == UC_ERR_OK
      check raxBack == 7
      check xmmBack == xmm
      check room == @[csize_t(8), 16]
      room = @[csize_t(8), 8]
      check uc_reg_read_batch2(uc, ids, [pointer(addr raxBack), addr xmmBack], room) ==
        UC_ERR_OVERFLOW
      var short = [csize_t(8)]
      check uc_reg_read_batch2(uc, ids, [pointer(addr raxBack), addr xmmBack], short) == UC_ERR_ARG
      check uc_reg_write_batch2(uc, ids, [pointer(addr rax)], sizes) == UC_ERR_ARG
      var noSizes: seq[csize_t]
      let none: seq[uc_x86_reg] = @[]
      let noValues: seq[pointer] = @[]
      check uc_reg_read_batch2(uc, none, noValues, noSizes) == UC_ERR_OK
      check uc_reg_write_batch2(uc, none, noValues, noSizes) == UC_ERR_OK
    else:
      skip()

suite "hooks":
  var
    uc: ptr uc_engine
    hook: uc_hook
    seen: Seen

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
    require uc_mem_map(uc, codeAddress, 0x2000, UC_PROT_ALL) == UC_ERR_OK
    seen = Seen()
    hook = 0

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "UC_HOOK_CODE: every instruction":
    check uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.addresses == @[0x1000'u64, 0x1008, 0x1010]
    check seen.sizes == @[8, 8, 1]

  test "UC_HOOK_BLOCK: every basic block":
    check uc_hook_add(uc, addr hook, UC_HOOK_BLOCK, onCode, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(twoBlocks) == UC_ERR_OK
    check seen.addresses == @[0x1000'u64, 0x1002]
    check seen.sizes == @[2, 1]

  test "one callback for two kinds of the same shape":
    check uc_hook_add(uc, addr hook, UC_HOOK_CODE or UC_HOOK_BLOCK, onCode, addr seen,
                      1, 0) == UC_ERR_OK
    when sizeof(int) == 8:
      check uc.run(twoBlocks) == UC_ERR_OK
      check seen.calls == 4  # two blocks and two instructions
    else:
      # Not run on a 32-bit host: Unicorn itself aborts there (a C program
      # does the same) when it translates code under one hook for both kinds.
      check uc_hook_del(uc, hook) == UC_ERR_OK

  test "a hook is limited to its range and gone once deleted":
    check uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, addr seen, 0x1008, 0x100f) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.addresses == @[0x1008'u64]
    check uc_hook_del(uc, hook) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.calls == 1

  test "a hook can stop the emulation":
    check uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCodeStop, addr seen, 0x1008, 0x1008) ==
      UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.calls == 1
    check seen.errors == 0
    check uc.reg(UC_X86_REG_RIP) == 0x1008
    # So does the instruction count of uc_emu_start.
    check uc_hook_del(uc, hook) == UC_ERR_OK
    check uc.run(loadStore, count = 1) == UC_ERR_OK
    check uc.reg(UC_X86_REG_RIP) == 0x1008

  test "UC_HOOK_MEM_READ and UC_HOOK_MEM_WRITE: successful accesses":
    var value = 0x1122334455667788'u64
    require uc_mem_write(uc, dataAddress, addr value, sizeof(value)) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE, onMem, addr seen,
                      1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.kinds == @[UC_MEM_READ, UC_MEM_WRITE]
    check seen.addresses == @[0x2000'u64, 0x2008]
    check seen.sizes == @[8, 8]
    check seen.values[1] == 0x1122334455667788'i64
    var stored: uint64
    check uc_mem_read(uc, dataAddress + 8, addr stored, sizeof(stored)) == UC_ERR_OK
    check stored == value

  test "UC_HOOK_MEM_READ_AFTER: the value that was read":
    var value = 0x0102030405060708'u64
    require uc_mem_write(uc, dataAddress, addr value, sizeof(value)) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ_AFTER, onMem, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.kinds == @[UC_MEM_READ_AFTER]
    check seen.addresses == @[0x2000'u64]
    check seen.values == @[0x0102030405060708'i64]

  test "UC_HOOK_MEM_VALID takes the same callback":
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_VALID, onMem, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.kinds == @[UC_MEM_READ, UC_MEM_WRITE]

  test "UC_HOOK_MEM_FETCH is accepted and never called":
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_FETCH, onMem, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check seen.calls == 0  # Unicorn 2.0 and 2.1 have no call for this kind

  test "UC_HOOK_MEM_UNMAPPED: the hook maps the page and the access goes through":
    seen.repair = true
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onFault, addr seen, 1, 0) == UC_ERR_OK
    var rax = 0xfeedface'u64
    check uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_OK
    check seen.errors == 0
    check seen.kinds == @[UC_MEM_WRITE_UNMAPPED]
    check seen.addresses == @[0x500010'u64]
    var stored: uint64
    check uc_mem_read(uc, 0x500010, addr stored, sizeof(stored)) == UC_ERR_OK
    check stored == 0xfeedface'u64
    # Mapped now: no fault, and the read finds what was written.
    check uc.run(loadFar) == UC_ERR_OK
    check seen.calls == 1
    check uc.reg(UC_X86_REG_RBX) == 0xfeedface'u64

  test "UC_HOOK_MEM_UNMAPPED: a hook that does not repair ends the run":
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onFault, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_WRITE_UNMAPPED
    check uc.run(loadFar) == UC_ERR_READ_UNMAPPED
    check seen.kinds == @[UC_MEM_WRITE_UNMAPPED, UC_MEM_READ_UNMAPPED]

  test "UC_HOOK_MEM_FETCH_UNMAPPED: code that is not there":
    seen.repair = true
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_FETCH_UNMAPPED, onFault, addr seen,
                      1, 0) == UC_ERR_OK
    check uc_emu_start(uc, 0x700000, 0x700001, 0, 0) == UC_ERR_OK
    check seen.errors == 0
    check seen.kinds == @[UC_MEM_FETCH_UNMAPPED]
    check seen.addresses == @[0x700000'u64]
    check uc.reg(UC_X86_REG_RIP) == 0x700001

  test "UC_HOOK_MEM_WRITE_PROT: the hook lifts the protection":
    require uc_mem_map(uc, 0x500000, 0x1000, UC_PROT_READ) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_WRITE_PROT
    seen.repair = true
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_PROT, onFault, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_OK
    check seen.errors == 0
    check seen.kinds == @[UC_MEM_WRITE_PROT]
    check seen.addresses == @[0x500010'u64]

  test "UC_HOOK_MEM_INVALID covers unmapped and protected":
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_INVALID, onFault, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_WRITE_UNMAPPED
    require uc_mem_map(uc, 0x500000, 0x1000, UC_PROT_READ) == UC_ERR_OK
    check uc.run(storeFar) == UC_ERR_WRITE_PROT
    check seen.kinds == @[UC_MEM_WRITE_UNMAPPED, UC_MEM_WRITE_PROT]

  test "one callback with a result for every memory hook kind":
    # What Unicorn's own samples do: the result counts for the accesses that
    # fail and is ignored for those that succeed.
    seen.repair = true
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_VALID or UC_HOOK_MEM_INVALID, onFault, addr seen,
                      1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK   # the callback's `false` does not stop these
    check seen.kinds == @[UC_MEM_READ, UC_MEM_WRITE]
    check uc.run(storeFar) == UC_ERR_OK    # and its `true` lets this one go on
    check seen.errors == 0
    check UC_MEM_WRITE_UNMAPPED in seen.kinds
    var other: Seen
    check uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ_AFTER or UC_HOOK_MEM_READ_PROT, onFault,
                      addr other, 1, 0) == UC_ERR_OK
    check uc.run(loadStore) == UC_ERR_OK
    check other.kinds == @[UC_MEM_READ_AFTER]

  test "UC_HOOK_INTR: interrupts":
    const code = [0xcd'u8, 0x80,  # int 0x80
                  0x90]           # nop
    check uc.run(code) == UC_ERR_EXCEPTION  # nobody handles it
    check uc_hook_add(uc, addr hook, UC_HOOK_INTR, onInterrupt, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(code) == UC_ERR_OK
    check seen.values == @[0x80'i64]
    check uc.reg(UC_X86_REG_RIP) == 0x1003

  test "UC_HOOK_INSN_INVALID: an instruction the CPU does not know":
    const code = [0x0f'u8, 0x0b,  # ud2, the instruction that is defined to be undefined
                  0x90, 0x90]     # nop; nop
    check uc.run(code) == UC_ERR_INSN_INVALID
    check uc_hook_add(uc, addr hook, UC_HOOK_INSN_INVALID, onInvalid, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(code) == UC_ERR_INSN_INVALID  # the hook says no
    check seen.calls == 1
    seen.repair = true                         # the hook steps over it
    let err = uc.run(code)
    check seen.calls == 2
    check seen.errors == 0
    # What happens next depends on the library.
    let v = uc_version()
    if (v.major, v.minor, v.patch) >= (2, 1, 2):
      check err == UC_ERR_OK
      check uc.reg(UC_X86_REG_RIP) == 0x1004   # went on to the end
    elif (v.major, v.minor) == (2, 1):
      check err == UC_ERR_EXCEPTION            # 2.1.0 and 2.1.1 report the exception anyway
      check uc.reg(UC_X86_REG_RIP) == 0x1002
    else:
      check err == UC_ERR_OK                   # 2.0.x ends the run where the hook left it
      check uc.reg(UC_X86_REG_RIP) == 0x1002

  test "UC_HOOK_INSN: syscall, in, out and cpuid each have their callback":
    const code = [0xb0'u8, 0x07,  # mov al, 7
                  0xe6, 0x20,     # out 0x20, al
                  0xe4, 0x10,     # in al, 0x10
                  0x0f, 0x05,     # syscall
                  0x0f, 0xa2]     # cpuid
    var syscalls, ins, outs, cpuids: Seen
    check uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, addr syscalls, 1, 0,
                      UC_X86_INS_SYSCALL) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_INSN, onIn, addr ins, 1, 0, UC_X86_INS_IN) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_INSN, onOut, addr outs, 1, 0, UC_X86_INS_OUT) ==
      UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_INSN, onCpuid, addr cpuids, 1, 0,
                      UC_X86_INS_CPUID) == UC_ERR_OK
    check uc.run(code[0 ..< 6]) == UC_ERR_OK
    check outs.calls == 1
    check outs.addresses == @[0x20'u64]
    check outs.sizes == @[1]
    check outs.values == @[7'i64]
    check ins.calls == 1
    check ins.addresses == @[0x10'u64]
    check ins.sizes == @[1]
    check (uc.reg(UC_X86_REG_RAX) and 0xff) == 0x42
    check uc.run(code) == UC_ERR_OK
    check syscalls.calls == 1
    check cpuids.calls == 1
    check cpuids.errors == 0
    check uc.reg(UC_X86_REG_RAX) == 0x1234  # the hook's answer; cpuid itself was skipped

  test "UC_HOOK_INSN: sysenter takes the syscall callback":
    # An Intel CPU model: the default one of Unicorn 2.0 is AMD's, which has
    # no sysenter in 64-bit mode.
    var intel: ptr uc_engine
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr intel) == UC_ERR_OK
    require uc_ctl_set_cpu_model(intel, UC_CPU_X86_HASWELL) == UC_ERR_OK
    require uc_mem_map(intel, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    check uc_hook_add(intel, addr hook, UC_HOOK_INSN, onSyscall, addr seen, 1, 0,
                      UC_X86_INS_SYSENTER) == UC_ERR_OK
    check intel.run([0x0f'u8, 0x34]) == UC_ERR_OK
    check seen.calls == 1
    check uc_close(intel) == UC_ERR_OK

  test "UC_HOOK_INSN: rdtsc and rdtscp take the cpuid callback (Unicorn 2.1.2)":
    # A CPU model that has rdtscp: the default one of Unicorn before 2.1.3
    # does not.
    var intel: ptr uc_engine
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr intel) == UC_ERR_OK
    require uc_ctl_set_cpu_model(intel, UC_CPU_X86_HASWELL) == UC_ERR_OK
    require uc_mem_map(intel, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    let v = uc_version()
    var rdtsc, rdtscp: uc_hook = 12345
    let
      first = uc_hook_add(intel, addr rdtsc, UC_HOOK_INSN, onCpuid, addr seen, 1, 0,
                          UC_X86_INS_RDTSC)
      second = uc_hook_add(intel, addr rdtscp, UC_HOOK_INSN, onCpuid, addr seen, 1, 0,
                           UC_X86_INS_RDTSCP)
    if (v.major, v.minor, v.patch) >= (2, 1, 2):
      check first == UC_ERR_OK
      check second == UC_ERR_OK
      check intel.run([0x0f'u8, 0x31]) == UC_ERR_OK        # rdtsc
      check seen.calls == 1
      check intel.reg(UC_X86_REG_RAX) == 0x1234
      check intel.run([0x0f'u8, 0x01, 0xf9]) == UC_ERR_OK  # rdtscp
      check seen.calls == 2
    else:
      # An older Unicorn has no hook for these instructions. It is not even
      # asked (it would refuse, and leak the hook): the handles are untouched.
      check first == UC_ERR_HOOK
      check second == UC_ERR_HOOK
      check rdtsc == 12345
      check rdtscp == 12345
    check uc_close(intel) == UC_ERR_OK

  test "UC_HOOK_INSN: ARM64 system registers":
    if not uc_arch_supported(UC_ARCH_ARM64):
      skip()
    else:
      var arm: ptr uc_engine
      require uc_open(UC_ARCH_ARM64, UC_MODE_ARM, addr arm) == UC_ERR_OK
      require uc_mem_map(arm, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
      check uc_hook_add(arm, addr hook, UC_HOOK_INSN, onSys, addr seen, 1, 0,
                        UC_ARM64_INS_MRS) == UC_ERR_OK
      check arm.run([0x62'u8, 0xd0, 0x3b, 0xd5]) == UC_ERR_OK  # mrs x2, tpidrro_el0
      check seen.calls == 1
      check seen.errors == 0
      var x2: uint64
      check uc_reg_read(arm, UC_ARM64_REG_X2, addr x2) == UC_ERR_OK
      check x2 == 0x114514
      check uc_hook_add(arm, addr hook, UC_HOOK_INSN, onSys, addr seen, 1, 0,
                        UC_ARM64_INS_INVALID) == UC_ERR_HOOK
      check uc_hook_add(arm, addr hook, UC_HOOK_CODE, onSys, addr seen, 1, 0,
                        UC_ARM64_INS_MSR) == UC_ERR_HOOK
      check uc_close(arm) == UC_ERR_OK

  test "UC_HOOK_EDGE_GENERATED: a jump between blocks is translated":
    check uc_hook_add(uc, addr hook, UC_HOOK_EDGE_GENERATED, onEdge, addr seen, 1, 0) == UC_ERR_OK
    check uc.run(twoBlocks) == UC_ERR_OK
    check 0x1002'u64 in seen.addresses

  test "UC_HOOK_TCG_OPCODE: subtractions and comparisons":
    const code = [0x48'u8, 0x29, 0xd8,  # sub rax, rbx
                  0x48, 0x39, 0xd8]     # cmp rax, rbx
    var subs, cmps: Seen
    check uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE, onSub, addr subs, 1, 0, UC_TCG_OP_SUB,
                      UC_TCG_OP_FLAG_DIRECT) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE, onSub, addr cmps, 1, 0, UC_TCG_OP_SUB,
                      UC_TCG_OP_FLAG_CMP) == UC_ERR_OK
    var
      rax = 50'u64
      rbx = 8'u64
    check uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    check uc_reg_write(uc, UC_X86_REG_RBX, addr rbx) == UC_ERR_OK
    check uc.run(code) == UC_ERR_OK
    # Unicorn reports the operands as they are after the instruction: for
    # `sub` the difference has replaced the first one, `cmp` changes nothing.
    check subs.addresses == @[0x1000'u64]
    check subs.values == @[42'i64, 8]
    check subs.sizes == @[64]
    check cmps.addresses == @[0x1003'u64]
    check cmps.values == @[42'i64, 8]
    check cmps.sizes == @[64]
    # Flags are bits, so there may be none: every subtraction the translator
    # emits.
    check uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE, onSub, addr subs, 1, 0, UC_TCG_OP_SUB,
                      0) == UC_ERR_OK
    check uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE, onSub, addr subs, 1, 0, UC_TCG_OP_SUB,
                      uint32(ord(UC_TCG_OP_FLAG_DIRECT))) == UC_ERR_OK

  test "UC_HOOK_TLB_FILL: address translation by callback (Unicorn 2.1)":
    let err = uc_hook_add(uc, addr hook, UC_HOOK_TLB_FILL, onTlbFill, addr seen, 1, 0)
    let v = uc_version()
    if (v.major, v.minor) < (2, 1):
      # Unicorn 2.0 would take the hook and never call it.
      check err == UC_ERR_HOOK
    else:
      check err == UC_ERR_OK
      when libVersion >= (2, 1, 0):
        check uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL) == UC_ERR_OK
        # The callback maps virtual 0x0000 to physical 0x1000, where the code is.
        require uc_mem_write(uc, codeAddress, [0x90'u8, 0x90]) == UC_ERR_OK
        check uc_emu_start(uc, 0, 2, 0, 0) == UC_ERR_OK
        check seen.calls >= 1
        check seen.addresses[0] == 0
        when libVersion >= (2, 1, 4):
          # The functions for virtual addresses ask the same callback.
          var physical: uint64
          check uc_vmem_translate(uc, 0x10, UC_PROT_READ, addr physical) == UC_ERR_OK
          check physical == 0x1010
          var value = 0xabcd'u16
          check uc_vmem_write(uc, 0x100, UC_PROT_WRITE, addr value, 2) == UC_ERR_OK
          var viaPhysical: uint16
          check uc_mem_read(uc, 0x1100, addr viaPhysical, 2) == UC_ERR_OK
          check viaPhysical == 0xabcd'u16
          var viaVirtual: uint16
          check uc_vmem_read(uc, 0x100, UC_PROT_READ, addr viaVirtual, 2) == UC_ERR_OK
          check viaVirtual == 0xabcd'u16

  test "a kind that belongs to another callback type is refused":
    const none = uc_hook_type(0)
    template refused(call: untyped) =
      hook = 12345
      check call == UC_ERR_HOOK
      check hook == 12345  # Unicorn was not called
    refused uc_hook_add(uc, addr hook, UC_HOOK_INTR, onCode, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ, onCode, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE or UC_HOOK_MEM_READ, onCode, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onCode, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onCode, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onInterrupt, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onInterrupt, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onMem, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ or UC_HOOK_MEM_READ_PROT, onMem, addr seen,
                        1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onMem, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onMem, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onFault, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_INVALID or UC_HOOK_INTR, onFault, addr seen,
                        1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN_INVALID, onFault, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onFault, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onInvalid, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onInvalid, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onInvalid, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_BLOCK, onEdge, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onEdge, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onTlbFill, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, none, onTlbFill, addr seen, 1, 0)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onSub, addr seen, 1, 0, UC_TCG_OP_SUB,
                        UC_TCG_OP_FLAG_CMP)
    refused uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE or UC_HOOK_CODE, onSub, addr seen, 1, 0,
                        UC_TCG_OP_SUB, 0)
    refused uc_hook_add(uc, addr hook, none, onSub, addr seen, 1, 0, UC_TCG_OP_SUB, 0)
    # Nothing was added: the program runs without a single callback.
    check uc.run(loadStore) == UC_ERR_OK
    check seen.calls == 0

  test "an instruction that belongs to another callback type is refused":
    template refused(call: untyped) =
      hook = 12345
      check call == UC_ERR_HOOK
      check hook == 12345
    # The instruction decides the signature Unicorn calls.
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, addr seen, 1, 0, UC_X86_INS_IN)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, addr seen, 1, 0, UC_X86_INS_CPUID)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, addr seen, 1, 0, UC_X86_INS_NOP)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onIn, addr seen, 1, 0, UC_X86_INS_OUT)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onIn, addr seen, 1, 0, UC_X86_INS_SYSCALL)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onOut, addr seen, 1, 0, UC_X86_INS_IN)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onOut, addr seen, 1, 0, UC_X86_INS_INVALID)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onCpuid, addr seen, 1, 0, UC_X86_INS_SYSCALL)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onCpuid, addr seen, 1, 0, UC_X86_INS_IN)
    # The kind has to be UC_HOOK_INSN and nothing else.
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onSyscall, addr seen, 1, 0,
                        UC_X86_INS_SYSCALL)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN or UC_HOOK_CODE, onSyscall, addr seen, 1, 0,
                        UC_X86_INS_SYSCALL)
    refused uc_hook_add(uc, addr hook, uc_hook_type(0), onSyscall, addr seen, 1, 0,
                        UC_X86_INS_SYSCALL)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INTR, onIn, addr seen, 1, 0, UC_X86_INS_IN)
    refused uc_hook_add(uc, addr hook, UC_HOOK_BLOCK, onOut, addr seen, 1, 0, UC_X86_INS_OUT)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN_INVALID, onCpuid, addr seen, 1, 0,
                        UC_X86_INS_CPUID)
    refused uc_hook_add(uc, addr hook, UC_HOOK_CODE, onSys, addr seen, 1, 0, UC_ARM64_INS_MRS)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSys, addr seen, 1, 0, UC_ARM64_INS_INVALID)
    refused uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSys, addr seen, 1, 0, UC_ARM64_INS_ENDING)

  test "what is not a callback of the right type does not compile":
    var captured = 0
    let closure {.used.} = proc (uc: ptr uc_engine; address: uint64; size: uint32;
                                 user_data: pointer) = inc captured
    check compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, nil, 1, 0))
    # Without {.cdecl.} the calling convention is Nim's, not C's.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, codeWithoutCdecl, nil, 1, 0))
    # A closure is a pair of pointers.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, closure, nil, 1, 0))
    # `uint` and `int` are not what C passes for uint64_t and uint32_t.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, codeWithNimIntegers, nil, 1, 0))
    # An exception cannot pass through Unicorn.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, codeThatCanRaise, nil, 1, 0))
    # A memory callback that returns nothing is not a fault handler, and the
    # other way round; both kinds are checked at run time as well.
    check compiles(uc_hook_add(uc, addr hook, UC_HOOK_MEM_READ, onMem, nil, 1, 0))
    check compiles(uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onFault, nil, 1, 0))
    # Instruction hooks need the instruction, and only they take one.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, nil, 1, 0))
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_INSN, onIn, nil, 1, 0))
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, nil, 1, 0,
                                   UC_X86_INS_SYSCALL))
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, nil, 1, 0,
                                   UC_ARM64_INS_MRS))
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSys, nil, 1, 0,
                                   UC_X86_INS_SYSCALL))
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_TCG_OPCODE, onSub, nil, 1, 0))
    # Any pointer, or a number for the kind, is the unchecked C function only.
    check not compiles(uc_hook_add(uc, addr hook, UC_HOOK_CODE, cast[pointer](onCode), nil, 1, 0))
    check not compiles(uc_hook_add(uc, addr hook, 4, onCode, nil, 1, 0))
    check not compiles(uc_hook_add(uc, addr hook, UC_PROT_READ, onCode, nil, 1, 0))
    check captured == 0

  test "uc_hook_add_unchecked is the C function":
    check uc_hook_add_unchecked(uc, addr hook, cint(UC_HOOK_CODE), cast[pointer](onCode),
                                addr seen, 1, 0) == UC_ERR_OK
    var syscalls: Seen
    check uc_hook_add_unchecked(uc, addr hook, cint(UC_HOOK_INSN), cast[pointer](onSyscall),
                                addr syscalls, 1, 0, cint(ord(UC_X86_INS_SYSCALL))) == UC_ERR_OK
    check uc.run([0x0f'u8, 0x05, 0x90]) == UC_ERR_OK
    check seen.calls == 2
    check syscalls.calls == 1

suite "contexts":
  var
    uc: ptr uc_engine
    ctx: ptr uc_context

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK
    require uc_context_alloc(uc, addr ctx) == UC_ERR_OK

  teardown:
    check uc_context_free(ctx) == UC_ERR_OK
    check uc_close(uc) == UC_ERR_OK

  test "a context keeps the registers it was saved with":
    var rax = 7'u64
    check uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    check uc_context_save(uc, ctx) == UC_ERR_OK
    rax = 8
    check uc_reg_write(uc, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    var saved: uint64
    check uc_context_reg_read(ctx, UC_X86_REG_RAX, addr saved) == UC_ERR_OK
    check saved == 7
    check uc_context_restore(uc, ctx) == UC_ERR_OK
    check uc.reg(UC_X86_REG_RAX) == 7
    check uc_context_size(uc) > 0

  test "registers of a context can be changed":
    check uc_context_save(uc, ctx) == UC_ERR_OK
    var rbx = 0x99'u64
    check uc_context_reg_write(ctx, UC_X86_REG_RBX, addr rbx) == UC_ERR_OK
    check uc.reg(UC_X86_REG_RBX) == 0
    check uc_context_restore(uc, ctx) == UC_ERR_OK
    check uc.reg(UC_X86_REG_RBX) == 0x99
    # The C declarations with a plain number.
    var back: uint64
    check uc_context_reg_read(ctx, cint(ord(UC_X86_REG_RBX)), addr back) == UC_ERR_OK
    check back == 0x99

  test "several registers of a context in one call":
    check uc_context_save(uc, ctx) == UC_ERR_OK
    var
      rcx = 11'u64
      rdx = 12'u64
    const ids = [UC_X86_REG_RCX, UC_X86_REG_RDX]
    check uc_context_reg_write_batch(ctx, ids, [pointer(addr rcx), addr rdx]) == UC_ERR_OK
    var c, d: uint64
    check uc_context_reg_read_batch(ctx, ids, [pointer(addr c), addr d]) == UC_ERR_OK
    check [c, d] == [11'u64, 12]
    check uc_context_reg_read_batch(ctx, ids, [pointer(addr c)]) == UC_ERR_ARG
    check uc_context_reg_write_batch(ctx, ids, [pointer(addr c)]) == UC_ERR_ARG
    let none: seq[uc_x86_reg] = @[]
    let noValues: seq[pointer] = @[]
    check uc_context_reg_read_batch(ctx, none, noValues) == UC_ERR_OK
    check uc_context_reg_write_batch(ctx, none, noValues) == UC_ERR_OK

  test "registers of a context with their sizes (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      check uc_context_save(uc, ctx) == UC_ERR_OK
      var rsi = 0x55'u64
      var size = csize_t(8)
      check uc_context_reg_write2(ctx, UC_X86_REG_RSI, addr rsi, addr size) == UC_ERR_OK
      var back: uint64
      size = 8
      check uc_context_reg_read2(ctx, UC_X86_REG_RSI, addr back, addr size) == UC_ERR_OK
      check back == 0x55
      var small: uint16
      size = 2
      check uc_context_reg_read2(ctx, UC_X86_REG_RSI, addr small, addr size) == UC_ERR_OVERFLOW
      const ids = [UC_X86_REG_RSI, UC_X86_REG_RDI]
      var
        a = 1'u64
        b = 2'u64
        sizes = [csize_t(8), 8]
      check uc_context_reg_write_batch2(ctx, ids, [pointer(addr a), addr b], sizes) == UC_ERR_OK
      var x, y: uint64
      check uc_context_reg_read_batch2(ctx, ids, [pointer(addr x), addr y], sizes) == UC_ERR_OK
      check [x, y] == [1'u64, 2]
      var short = [csize_t(8)]
      check uc_context_reg_read_batch2(ctx, ids, [pointer(addr x), addr y], short) == UC_ERR_ARG
      check uc_context_reg_write_batch2(ctx, ids, [pointer(addr x)], sizes) == UC_ERR_ARG
    else:
      skip()

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
      ctx {.used.}: ptr uc_context
      hook {.used.}: uc_hook
      value {.used.}: uint64
      buffer {.used.}: array[4, byte]
      size {.used.}: uint32
      answer {.used.}: int
    mustBeUsed uc_open(UC_ARCH_X86, UC_MODE_64, addr uc)
    mustBeUsed uc_close(uc)
    mustBeUsed uc_mem_map(uc, 0x1000, 0x1000, UC_PROT_ALL)
    mustBeUsed uc_mem_map(uc, 0x1000, 0x1000, 7'u32)
    mustBeUsed uc_mem_protect(uc, 0x1000, 0x1000, UC_PROT_READ)
    mustBeUsed uc_mem_unmap(uc, 0x1000, 0x1000)
    mustBeUsed uc_mem_write(uc, 0x1000, buffer)
    mustBeUsed uc_mem_write(uc, 0x1000, addr buffer[0], buffer.len)
    mustBeUsed uc_mem_write(uc, 0x1000, addr buffer[0], uc_size(4))
    mustBeUsed uc_mem_read(uc, 0x1000, buffer)
    mustBeUsed uc_mem_read(uc, 0x1000, addr buffer[0], buffer.len)
    mustBeUsed uc_reg_write(uc, UC_X86_REG_RAX, addr value)
    mustBeUsed uc_reg_write(uc, cint(1), addr value)
    mustBeUsed uc_reg_read(uc, UC_X86_REG_RAX, addr value)
    mustBeUsed uc_reg_read(uc, cint(1), addr value)
    mustBeUsed uc_reg_read_batch(uc, [UC_X86_REG_RAX], [pointer(addr value)])
    mustBeUsed uc_context_reg_read(ctx, UC_X86_REG_RAX, addr value)
    mustBeUsed uc_context_save(uc, ctx)
    mustBeUsed uc_context_free(ctx)
    mustBeUsed uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, nil, 1, 0)
    mustBeUsed uc_hook_add(uc, addr hook, UC_HOOK_MEM_UNMAPPED, onFault, nil, 1, 0)
    mustBeUsed uc_hook_add(uc, addr hook, UC_HOOK_INSN, onSyscall, nil, 1, 0, UC_X86_INS_SYSCALL)
    mustBeUsed uc_hook_add_unchecked(uc, addr hook, cint(4), nil, nil, 1, 0)
    mustBeUsed uc_hook_del(uc, hook)
    mustBeUsed uc_emu_start(uc, 0x1000, 0x1001, 0, 0)
    mustBeUsed uc_emu_stop(uc)
    mustBeUsed uc_ctl_get_page_size(uc, addr size)
    mustBeUsed uc_ctl_exits_enable(uc)
    mustBeUsed uc_ctl_flush_tb(uc)
    mustBeUsed uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_PAGE_SIZE, 1), addr size)
    mustBeUsed uc_query(uc, UC_QUERY_PAGE_SIZE, answer)
    mustBeUsed uc_free(nil)

  test "the check tells a call that needs `discard` from one that does not":
    proc mustUse(): uc_err = UC_ERR_OK
    proc mayDrop(): uc_err {.discardable.} = UC_ERR_OK
    proc nothing() = discard
    check not compilesAsStatement(mustUse())
    check compilesDiscarded(mustUse())
    check compilesAsStatement(mayDrop())
    check compilesAsStatement(nothing())
    check not compilesDiscarded(nothing())
    check not compilesDiscarded(noSuchProc())

suite "queries":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_32, addr uc) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "uc_query answers into a csize_t or an int":
    var answer: csize_t
    check uc_query(uc, UC_QUERY_PAGE_SIZE, addr answer) == UC_ERR_OK
    check answer == 4096
    var value: int
    check uc_query(uc, UC_QUERY_PAGE_SIZE, value) == UC_ERR_OK
    check value == 4096
    check uc_query(uc, UC_QUERY_ARCH, value) == UC_ERR_OK
    check uc_arch(value) == UC_ARCH_X86
    check uc_query(uc, UC_QUERY_MODE, value) == UC_ERR_OK
    check uc_mode(value) == UC_MODE_32
    check uc_query(uc, UC_QUERY_TIMEOUT, value) == UC_ERR_OK
    check value == 0
    value = 77
    check uc_query(uc, cast[uc_query_type](99), value) == UC_ERR_ARG
    check value == 77

  test "memory from the library is released with uc_free":
    require uc_mem_map(uc, 0x1000, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    var first: ptr uc_mem_region
    var count: uint32
    check uc_mem_regions(uc, addr first, addr count) == UC_ERR_OK
    check count == 1
    check first != nil
    check uc_free(first) == UC_ERR_OK

  test "error codes have a description":
    check uc_errno(uc) == UC_ERR_OK
    require uc_mem_map(uc, 0x1000, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    # mov eax, [0x500000]: nothing is mapped there
    let err = uc.run([0xa1'u8, 0x00, 0x00, 0x50, 0x00])
    check err == UC_ERR_READ_UNMAPPED
    check $uc_strerror(err) == "Invalid memory read (UC_ERR_READ_UNMAPPED)"
    check $uc_strerror(UC_ERR_READ_UNMAPPED) == "Invalid memory read (UC_ERR_READ_UNMAPPED)"
    check $uc_strerror(UC_ERR_OK) == "OK (UC_ERR_OK)"

suite "names":
  test "enums print under their C names":
    check $UC_ERR_OK == "UC_ERR_OK"
    check $UC_ERR_READ_UNMAPPED == "UC_ERR_READ_UNMAPPED"
    check $UC_ARCH_ARM64 == "UC_ARCH_ARM64"
    check $UC_X86_REG_RAX == "UC_X86_REG_RAX"
    check $UC_ARM_REG_R13 == "UC_ARM_REG_SP"  # an alias prints as what it stands for
    check $UC_MEM_WRITE_UNMAPPED == "UC_MEM_WRITE_UNMAPPED"
    check $UC_X86_INS_SYSCALL == "UC_X86_INS_SYSCALL"
    check $UC_QUERY_PAGE_SIZE == "UC_QUERY_PAGE_SIZE"

  test "an error code the bindings do not know prints as its number":
    check $cast[uc_err](ord(high(uc_err)) + 1) == "uc_err(" & $(ord(high(uc_err)) + 1) & ")"
    check $cast[uc_err](1000) == "uc_err(1000)"
    check $high(uc_err) == "UC_ERR_OVERFLOW"

  test "the deprecated PTR still gives the address of a buffer":
    var buffer = [1'u8, 2, 3]
    {.push warning[Deprecated]: off.}
    let address = PTR(buffer)
    {.pop.}
    check address == cast[pointer](addr buffer[0])
    check not declared(CPTR)
