## The Nim API apart from hooks: the engine and its lifetime, memory,
## registers and their sizes, running, errors, contexts, control and query,
## versions. Hooks are in `thooks.nim`.

import std/[envvars, random, strutils, times, unittest]
import libunicorn

const
  base = 0x1000'u64
  data = 0x3000'u64
  readWrite = UC_PROT_READ or UC_PROT_WRITE
  # mov rax, 0x1234; mov [0x3000], rax; mov rbx, [0x3000]; inc rcx; nop
  code = [0x48'u8, 0xC7, 0xC0, 0x34, 0x12, 0x00, 0x00,
          0x48, 0x89, 0x04, 0x25, 0x00, 0x30, 0x00, 0x00,
          0x48, 0x8B, 0x1C, 0x25, 0x00, 0x30, 0x00, 0x00,
          0x48, 0xFF, 0xC1, 0x90]
  stop = base + uint64(code.len)
  nops = [0x90'u8, 0x90, 0x90, 0x90, 0x90, 0x90]
  forever = [0xEB'u8, 0xFE]                              # jmp to itself

let library = uc_version()   # of the Unicorn in this process
# Unicorn 2.1.2 reads freed memory when it restores a context with memory
# (uc_context_restore drops the pages written since, then copies a memory
# map that still names them; 2.1.3 turned the two around): refused there.
let memoryContexts = (library.major, library.minor, library.patch) != (2, 1, 2)

proc newX64(): Unicorn =
  ## An x86-64 engine with `code` at `base` and a data page at `data`.
  result = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  result.memMap(base, 0x1000)
  result.memMap(data, 0x1000, readWrite)
  result.memWrite(base, code)

proc newX64(program: openArray[byte]): Unicorn =
  ## An x86-64 engine with `program` at `base` and nothing else.
  result = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  result.memMap(base, 0x1000)
  result.memWrite(base, program)

template expectCode(expected: uc_err; body: untyped) =
  ## `body` raises `UnicornError` with this code and Unicorn's text for it.
  try:
    body
    checkpoint "nothing was raised; expected " & $expected
    fail()
  except UnicornError as e:
    check e.code == expected
    check e.msg.len > 0

suite "engine":
  test "an engine runs code and gives its results":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RCX, 41)
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RAX) == 0x1234
    check uc.regRead(UC_X86_REG_RBX) == 0x1234
    check uc.regRead(UC_X86_REG_RCX) == 42
    check uc.memRead(data, 2) == @[0x34'u8, 0x12]

  test "arch and mode are the ones it was opened with; modes combine with `or`":
    let uc = newX64()
    check uc.arch == UC_ARCH_X86
    check uc.mode == UC_MODE_64
    if uc_arch_supported(UC_ARCH_ARM):
      let arm = initUnicorn(UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_MCLASS)
      check arm.arch == UC_ARCH_ARM
      check arm.mode == (UC_MODE_THUMB or UC_MODE_MCLASS)
      check UC_MODE_THUMB in arm.mode

  test "the C API can be mixed in through the handle":
    let uc = newX64()
    var rax = 77'u64
    check uc_reg_write(uc.handle, UC_X86_REG_RAX, addr rax) == UC_ERR_OK
    check uc.regRead(UC_X86_REG_RAX) == 77
    var size: csize_t
    check uc_query(uc.handle, UC_QUERY_PAGE_SIZE, addr size) == UC_ERR_OK
    check int(size) == uc.pageSize

  test "many engines can be open at once and are independent":
    var engines: seq[Unicorn]
    for i in 0 .. 7:
      engines.add newX64()
      engines[i].regWrite(UC_X86_REG_RCX, i)
    for uc in engines: uc.start(base, stop)
    for i in 0 .. 7: check engines[i].regRead(UC_X86_REG_RCX) == uint64(i + 1)

  test "an object that holds no engine raises instead of crashing":
    var empty: Unicorn
    expectCode(UC_ERR_HANDLE): empty.memMap(base, 0x1000)
    expectCode(UC_ERR_HANDLE): discard empty.regRead(UC_X86_REG_RAX)
    expectCode(UC_ERR_HANDLE): empty.start(base, stop)
    expectCode(UC_ERR_HANDLE): discard empty.handle
    expectCode(UC_ERR_HANDLE): discard empty.arch

suite "memory":
  test "bytes go in and out through openArray, seq and string":
    let uc = newX64()
    uc.memWrite(data, [1'u8, 2, 3, 4])
    check uc.memRead(data, 4) == @[1'u8, 2, 3, 4]
    var two: array[2, byte]
    uc.memRead(data + 1, two)
    check two == [2'u8, 3]
    uc.memWrite(data, "AB")
    check uc.memRead(data, 3) == @[byte('A'), byte('B'), 3]
    uc.memWrite(data, @[9'u8])
    check uc.memRead(data, 1) == @[9'u8]

  test "empty buffers are fine":
    let uc = newX64()
    uc.memWrite(data, newSeq[byte]())
    uc.memWrite(data, "")
    check uc.memRead(data, 0).len == 0
    var none: seq[byte]
    uc.memRead(data, none)

  test "regions list what is mapped, with the last byte and the permissions":
    let uc = newX64()
    check uc.memRegions == @[(first: base, last: base + 0xfff, perms: UC_PROT_ALL),
                             (first: data, last: data + 0xfff, perms: readWrite)]
    check initUnicorn(UC_ARCH_X86, UC_MODE_64).memRegions.len == 0

  test "unmapping takes a range away, also from the middle of a mapping":
    let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    uc.memMap(0x10000, 0x3000)
    uc.memUnmap(0x11000, 0x1000)
    check uc.memRegions == @[(first: 0x10000'u64, last: 0x10fff'u64, perms: UC_PROT_ALL),
                             (first: 0x12000'u64, last: 0x12fff'u64, perms: UC_PROT_ALL)]
    expectCode(UC_ERR_READ_UNMAPPED): discard uc.memRead(0x11000, 1)
    uc.memUnmap(0x10000, 0x1000)
    uc.memUnmap(0x12000, 0x1000)
    check uc.memRegions.len == 0

  test "permissions are enforced on emulated code and can be changed":
    let uc = newX64()
    uc.memProtect(data, 0x1000, UC_PROT_READ)
    check uc.memRegions[1].perms == UC_PROT_READ
    expectCode(UC_ERR_WRITE_PROT): uc.start(base, stop)
    uc.memWrite(data, [5'u8])                      # the host may write all the same
    check uc.memRead(data, 1) == @[5'u8]
    uc.memProtect(data, 0x1000, readWrite)
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RBX) == 0x1234

  test "host memory can be mapped in; both sides see the same bytes":
    var host = newSeq[byte](0x2000)                # declared first: it outlives the engine
    host[0] = 0xAA
    let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    uc.memMap(base, 0x1000)
    uc.memWrite(base, code)
    uc.memMapPtr(data, 0x2000, addr host[0], readWrite)
    check uc.memRegions[1] == (first: data, last: data + 0x1fff, perms: readWrite)
    check uc.memRead(data, 1) == @[0xAA'u8]
    uc.start(base, stop)                           # stores rax at `data`
    check host[0 .. 1] == @[0x34'u8, 0x12]
    host[0] = 0x35
    uc.start(base + 15, stop)                      # loads rbx from `data`
    check uc.regRead(UC_X86_REG_RBX) == 0x1235
    expectCode(UC_ERR_ARG): uc.memMapPtr(0x9000, 0x1000, nil)

  test "what Unicorn refuses is an exception":
    let uc = newX64()
    expectCode(UC_ERR_ARG): uc.memMap(0x5001, 0x1000)       # not page-aligned
    expectCode(UC_ERR_ARG): uc.memMap(0x5000, 0x123)
    expectCode(UC_ERR_MAP): uc.memMap(base, 0x1000)         # already mapped
    expectCode(UC_ERR_NOMEM): uc.memUnmap(0x800000, 0x1000) # not mapped
    expectCode(UC_ERR_NOMEM): uc.memProtect(0x800000, 0x1000, UC_PROT_READ)
    expectCode(UC_ERR_READ_UNMAPPED): discard uc.memRead(0x800000, 4)
    expectCode(UC_ERR_WRITE_UNMAPPED): uc.memWrite(0x800000, [1'u8])

suite "registers":
  test "integers of any type are written; signed ones are sign-extended":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 60)
    check uc.regRead(UC_X86_REG_RAX) == 60
    uc.regWrite(UC_X86_REG_RAX, 0xFFFF_FFFF_0000_0001'u64)
    check uc.regRead(UC_X86_REG_RAX) == 0xFFFF_FFFF_0000_0001'u64
    uc.regWrite(UC_X86_REG_RAX, -2)
    check uc.regRead(UC_X86_REG_RAX) == 0xFFFF_FFFF_FFFF_FFFE'u64
    uc.regWrite(UC_X86_REG_RBX, -2'i8)
    check uc.regRead(UC_X86_REG_RBX) == 0xFFFF_FFFF_FFFF_FFFE'u64
    uc.regWrite(UC_X86_REG_RCX, 0xFE'u8)
    check uc.regRead(UC_X86_REG_RCX) == 0xFE
    uc.regWrite(UC_X86_REG_RDX, high(int64))
    check uc.regRead(UC_X86_REG_RDX) == uint64(high(int64))

  test "a register narrower than 64 bits takes the low bits and reads zero-extended":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 0x1122_3344_5566_7788'u64)
    check uc.regRead(UC_X86_REG_EAX) == 0x5566_7788'u64
    check uc.regRead(UC_X86_REG_AX) == 0x7788
    check uc.regRead(UC_X86_REG_AL) == 0x88
    check uc.regRead(UC_X86_REG_AH) == 0x77
    uc.regWrite(UC_X86_REG_AX, -1)                 # 16 of the 64 bits
    check uc.regRead(UC_X86_REG_RAX) == 0x1122_3344_5566_FFFF'u64
    uc.regWrite(UC_X86_REG_EAX, 0x1_0000_0002'u64) # 32 of them; Unicorn keeps the upper half
    check uc.regRead(UC_X86_REG_RAX) == 0x1122_3344_0000_0002'u64

  test "a register can be read as a type of its own size":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 0x1122_3344_5566_7788'u64)
    check uc.regRead(UC_X86_REG_RAX, uint64) == 0x1122_3344_5566_7788'u64
    check uc.regRead(UC_X86_REG_RAX, int64) == 0x1122_3344_5566_7788'i64
    check uc.regRead(UC_X86_REG_EAX, uint32) == 0x5566_7788'u32
    check uc.regRead(UC_X86_REG_AX, uint16) == 0x7788'u16
    check uc.regRead(UC_X86_REG_AL, uint8) == 0x88'u8
    check uc.regRead(UC_X86_REG_EAX, array[4, byte]) == [0x88'u8, 0x77, 0x66, 0x55]

  test "XMM, YMM and ZMM registers are arrays":
    let uc = newX64()
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = byte(i + 1)
    uc.regWrite(UC_X86_REG_XMM3, xmm)
    check uc.regRead(UC_X86_REG_XMM3, array[16, byte]) == xmm
    check uc.regRead(UC_X86_REG_XMM3, array[2, uint64]) ==
      [0x0807060504030201'u64, 0x100F0E0D0C0B0A09'u64]
    check uc.regRead(UC_X86_REG_XMM4, array[16, byte]) == default(array[16, byte])
    var ymm: array[32, byte]
    for i in 0 .. 31: ymm[i] = byte(0x80 + i)
    uc.regWrite(UC_X86_REG_YMM5, ymm)
    check uc.regRead(UC_X86_REG_YMM5, array[32, byte]) == ymm
    check uc.regRead(UC_X86_REG_XMM5, array[16, byte])[15] == 0x8F   # its low half
    if (library.major, library.minor, library.patch) >= (2, 1, 2):   # ZMM came with 2.1.2
      var zmm: array[64, byte]
      for i in 0 .. 63: zmm[i] = byte(i)
      uc.regWrite(UC_X86_REG_ZMM6, zmm)
      check uc.regRead(UC_X86_REG_ZMM6, array[64, byte]) == zmm

  test "the 10-byte x87 registers are arrays too":
    let uc = newX64()
    let one = [0'u8, 0, 0, 0, 0, 0, 0, 0x80, 0xFF, 0x3F]   # 1.0 as an 80-bit float
    uc.regWrite(UC_X86_REG_FP0, one)
    check uc.regRead(UC_X86_REG_FP0, array[10, byte]) == one
    uc.regWrite(UC_X86_REG_ST0, one)
    check uc.regRead(UC_X86_REG_ST0, array[10, byte]) == one
    check uc.regRead(UC_X86_REG_FP1, array[10, byte]) == default(array[10, byte])
    # run `fld1` and find the same bits on top of the stack
    uc.memWrite(base, [0xD9'u8, 0xE8])
    uc.removeCache(base .. base + 1)
    uc.start(base, base + 2)
    check uc.regRead(UC_X86_REG_ST0, array[10, byte]) == one

  test "a type smaller than the register is never overrun":
    type Guarded[T] = object
      before: uint64
      value: T
      after: uint64
    let uc = newX64()
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = byte(i + 1)
    uc.regWrite(UC_X86_REG_XMM3, xmm)
    uc.regWrite(UC_X86_REG_RAX, 0x1122_3344_5566_7788'u64)

    const
      before = 0x1111_1111_1111_1111'u64
      after = 0x2222_2222_2222_2222'u64
    var wide = Guarded[uint64](before: before, after: after)
    var narrow = Guarded[uint16](before: before, after: after)
    when libVersion >= (2, 1, 0):
      # Unicorn 2.1 is told the size and refuses
      expectCode(UC_ERR_OVERFLOW): uc.regRead(UC_X86_REG_XMM3, wide.value)
      expectCode(UC_ERR_OVERFLOW): uc.regRead(UC_X86_REG_RAX, narrow.value)
      expectCode(UC_ERR_OVERFLOW): discard uc.regRead(UC_X86_REG_XMM3)
      expectCode(UC_ERR_OVERFLOW): discard uc.regRead(UC_X86_REG_RAX, uint32)
      expectCode(UC_ERR_OVERFLOW): discard uc.regRead(UC_X86_REG_YMM3, array[16, byte])
      expectCode(UC_ERR_OVERFLOW): discard uc.regRead(UC_X86_REG_FP0, uint64)
      check wide.value == 0
      check narrow.value == 0
    else:
      # Unicorn 2.0 cannot be told: the low part arrives
      uc.regRead(UC_X86_REG_XMM3, wide.value)
      uc.regRead(UC_X86_REG_RAX, narrow.value)
      check wide.value == 0x0807060504030201'u64
      check narrow.value == 0x7788
      check uc.regRead(UC_X86_REG_XMM3) == 0x0807060504030201'u64
      check uc.regRead(UC_X86_REG_RAX, uint32) == 0x5566_7788'u32
    check (wide.before, wide.after) == (before, after)
    check (narrow.before, narrow.after) == (before, after)

  test "a value smaller than the register is not read beyond its end":
    let uc = newX64()
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = 0xEE
    uc.regWrite(UC_X86_REG_XMM3, xmm)
    when libVersion >= (2, 1, 0):
      expectCode(UC_ERR_OVERFLOW): uc.regWrite(UC_X86_REG_XMM3, 0x55'u64)
      expectCode(UC_ERR_OVERFLOW): uc.regWrite(UC_X86_REG_XMM3, [1'u8, 2, 3])
      check uc.regRead(UC_X86_REG_XMM3, array[16, byte]) == xmm
    else:
      uc.regWrite(UC_X86_REG_XMM3, 0x55'u64)       # the rest of the register becomes zero
      var expected: array[16, byte]
      expected[0] = 0x55
      check uc.regRead(UC_X86_REG_XMM3, array[16, byte]) == expected

  test "a type larger than the register is zero where the register ends":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 0x1122_3344_5566_7788'u64)
    check uc.regRead(UC_X86_REG_AX, array[8, byte]) == [0x88'u8, 0x77, 0, 0, 0, 0, 0, 0]
    check uc.regRead(UC_X86_REG_RAX, array[12, byte])[8 .. 11] == @[0'u8, 0, 0, 0]

  test "model-specific registers: by id, and through the in/out struct":
    let uc = newX64()
    const
      efer = 0xC000_0080'u32
      fsBase = 0xC000_0100'u32
    check uc.msrRead(efer) == 0x500                # long mode enabled and active
    uc.msrWrite(fsBase, 0x1234_5678_9ABC'u64)
    check uc.msrRead(fsBase) == 0x1234_5678_9ABC'u64
    check uc.regRead(UC_X86_REG_FS_BASE) == 0x1234_5678_9ABC'u64
    var msr = uc_x86_msr(rid: fsBase)              # `rid` goes in, `value` comes out
    uc.regRead(UC_X86_REG_MSR, msr)
    check msr.value == 0x1234_5678_9ABC'u64
    msr.value = 0x42
    uc.regWrite(UC_X86_REG_MSR, msr)
    check uc.msrRead(fsBase) == 0x42

  test "descriptor table registers are structs":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_GDTR, uc_x86_mmr(base: 0x8000, limit: 0x7F))
    let gdtr = uc.regRead(UC_X86_REG_GDTR, uc_x86_mmr)
    check gdtr.base == 0x8000
    check gdtr.limit == 0x7F

  test "ARM coprocessor registers are read through the struct that names them":
    if not uc_arch_supported(UC_ARCH_ARM) or not uc_arch_supported(UC_ARCH_ARM64):
      skip()
    else:
      let arm = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      var tpidr = uc_arm_cp_reg(cp: 15, crn: 13, crm: 0, opc1: 0, opc2: 3, val: 0x4242)  # TPIDRURO
      arm.regWrite(UC_ARM_REG_CP_REG, tpidr)
      tpidr.val = 0
      arm.regRead(UC_ARM_REG_CP_REG, tpidr)
      check tpidr.val == 0x4242
      check arm.regRead(UC_ARM_REG_C13_C0_3) == 0x4242
      expectCode(UC_ERR_ARCH): discard arm.msrRead(0)
      expectCode(UC_ERR_ARCH): arm.msrWrite(0, 1)

      let arm64 = initUnicorn(UC_ARCH_ARM64, UC_MODE_ARM)
      arm64.regWrite(UC_ARM64_REG_TPIDR_EL0, 0x77)
      var tpidrEl0 = uc_arm64_cp_reg(crn: 13, crm: 0, op0: 3, op1: 3, op2: 2)
      arm64.regRead(UC_ARM64_REG_CP_REG, tpidrEl0)
      check tpidrEl0.val == 0x77
      tpidrEl0.val = 0x99
      arm64.regWrite(UC_ARM64_REG_CP_REG, tpidrEl0)
      check arm64.regRead(UC_ARM64_REG_TPIDR_EL0) == 0x99
      var vector: array[16, byte]
      for i in 0 .. 15: vector[i] = byte(i)
      arm64.regWrite(UC_ARM64_REG_V3, vector)
      check arm64.regRead(UC_ARM64_REG_V3, array[16, byte]) == vector

  test "a register is also named by its number, in every form":
    let uc = newX64()
    let
      rax = cint(ord(UC_X86_REG_RAX))
      eax = cint(ord(UC_X86_REG_EAX))
      xmm0 = cint(ord(UC_X86_REG_XMM0))
    uc.regWrite(rax, -1)                           # signed values are sign-extended here too
    check uc.regRead(rax) == high(uint64)
    uc.regWrite(eax, 0x1234'u16)
    check uc.regRead(eax, uint32) == 0x1234
    check uc.regRead(rax) == 0xFFFF_FFFF_0000_1234'u64
    var bytes: array[16, byte]
    for i in 0 .. 15: bytes[i] = byte(0xA0 + i)
    uc.regWrite(xmm0, bytes)
    check uc.regRead(xmm0, array[16, byte]) == bytes
    var msr = uc_x86_msr(rid: 0xC000_0080'u32)
    uc.regRead(cint(ord(UC_X86_REG_MSR)), msr)
    check msr.value == 0x500
    uc.regWriteBatch([rax, cint(ord(UC_X86_REG_RBX))], [1'u64, 2])
    check uc.regReadBatch([cint(ord(UC_X86_REG_RBX)), rax]) == @[2'u64, 1]
    var ctx = uc.saveContext()
    ctx.regWrite(rax, -2)
    check ctx.regRead(rax) == high(uint64) - 1
    check ctx.regRead(eax, uint32) == 0xFFFF_FFFE'u32
    var low: uint16
    ctx.regRead(cint(ord(UC_X86_REG_AX)), low)
    check low == 0xFFFE
    check ctx.regRead(xmm0, array[16, byte]) == bytes

  test "a register value is plain data without pointers":
    type Callback = proc () {.nimcall.}
    let uc = newX64()
    var ctx = uc.saveContext()
    var anywhere: pointer
    var text: cstring = "abcdefgh"
    check not compiles(uc.regWrite(UC_X86_REG_RAX, text))        # would write the pointer
    check not compiles(uc.regWrite(UC_X86_REG_RAX, anywhere))
    check not compiles(uc.regWrite(UC_X86_REG_RAX, addr anywhere))
    check not compiles(ctx.regWrite(UC_X86_REG_RAX, text))
    check not compiles(uc.regRead(UC_X86_REG_RAX, pointer))
    check not compiles(uc.regRead(UC_X86_REG_RAX, ptr int))
    check not compiles(uc.regRead(UC_X86_REG_RAX, ref int))
    check not compiles(uc.regRead(UC_X86_REG_RAX, Callback))
    check not compiles(uc.regRead(UC_X86_REG_RAX, string))
    check not compiles(ctx.regRead(UC_X86_REG_RAX, seq[byte]))
    check compiles(uc.regRead(UC_X86_REG_RAX, float64))
    check compiles(ctx.regRead(UC_X86_REG_RAX, array[8, byte]))

  test "a register that Unicorn writes without looking at the size overruns nothing":
    # Unicorn 2.1.0 and 2.1.1 write the four bytes of SPARC's %i0 to %i7
    # whatever room they are told there is (and then report an error).
    if not uc_arch_supported(UC_ARCH_SPARC):
      skip()
    else:
      type Guarded = object
        before: uint64
        value: uint8
        after: array[7, byte]
        last: uint64
      let uc = initUnicorn(UC_ARCH_SPARC, UC_MODE_SPARC32 or UC_MODE_BIG_ENDIAN)
      try: uc.regWrite(UC_SPARC_REG_I0, 0x11223344)
      except UnicornError: discard
      var guarded = Guarded(before: 0x1111_1111_1111_1111'u64, last: 0x2222_2222_2222_2222'u64)
      for b in guarded.after.mitems: b = 0xBB
      for reg in [UC_SPARC_REG_I0, UC_SPARC_REG_I3, UC_SPARC_REG_I7]:
        try: uc.regRead(reg, guarded.value)
        except UnicornError: discard
      check guarded.after == [0xBB'u8, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB, 0xBB]
      check guarded.before == 0x1111_1111_1111_1111'u64
      check guarded.last == 0x2222_2222_2222_2222'u64

  test "the CPSR of an ARM CPU in user mode refuses mode bits that are no mode":
    # Unicorn would abort the process
    if not uc_arch_supported(UC_ARCH_ARM):
      skip()
    else:
      let uc = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      uc.regWrite(UC_ARM_REG_CPSR, 0x05)           # in supervisor mode Unicorn ignores them
      check (uc.regRead(UC_ARM_REG_CPSR) and 0x1f) == 0x13
      uc.regWrite(UC_ARM_REG_CPSR, 0x10)           # user mode
      expectCode(UC_ERR_ARG): uc.regWrite(UC_ARM_REG_CPSR, 0x05)
      expectCode(UC_ERR_ARG): uc.regWrite(cint(ord(UC_ARM_REG_CPSR)), 0x1e'u32)
      var ctx = uc.saveContext()
      expectCode(UC_ERR_ARG): ctx.regWrite(UC_ARM_REG_CPSR, 0x05)
      ctx.regWrite(UC_ARM_REG_CPSR, 0x1f)          # system mode is one
      check (ctx.regRead(UC_ARM_REG_CPSR) and 0x1f) == 0x1f
      uc.regWrite(UC_ARM_REG_CPSR, 0x13)
      check (uc.regRead(UC_ARM_REG_CPSR) and 0x1f) == 0x13

  test "a read that fails leaves nothing behind":
    # Nim 2.0, and 2.2 as C++, do not free the `result` of a proc that is
    # left by an exception.
    let uc = newX64()
    var wide = newSeq[uc_x86_reg](2048)
    for reg in wide.mitems: reg = UC_X86_REG_RAX
    wide.add UC_X86_REG_XMM0                       # fails where sizes are checked
    when defined(useMalloc):
      skip()                                       # the heap in use is not known there
    else:
      let before = getOccupiedMem()
      for round in 1 .. 200:
        try: discard uc.memRead(0x800000, 1 shl 16)
        except UnicornError: discard
        try: discard uc.regReadBatch(wide)
        except UnicornError: discard
      check getOccupiedMem() - before < 1 shl 20

  test "several registers at once":
    let uc = newX64()
    uc.regWriteBatch([UC_X86_REG_RAX, UC_X86_REG_EBX, UC_X86_REG_CX],
                     [1'u64, 0x1_0000_0002'u64, 0xFFFF_0003'u64])
    check uc.regReadBatch([UC_X86_REG_RAX, UC_X86_REG_RBX, UC_X86_REG_RCX, UC_X86_REG_AL]) ==
      @[1'u64, 2, 3, 1]
    check uc.regReadBatch(newSeq[uc_x86_reg]()).len == 0
    uc.regWriteBatch(newSeq[uc_x86_reg](), newSeq[uint64]())
    expectCode(UC_ERR_ARG): uc.regWriteBatch([UC_X86_REG_RAX, UC_X86_REG_RBX], [1'u64])
    when libVersion >= (2, 1, 0):
      expectCode(UC_ERR_OVERFLOW): discard uc.regReadBatch([UC_X86_REG_RAX, UC_X86_REG_XMM0])
      expectCode(UC_ERR_OVERFLOW):
        uc.regWriteBatch([UC_X86_REG_RDX, UC_X86_REG_XMM0], [7'u64, 8])
      check uc.regRead(UC_X86_REG_RDX) == 7        # the ones before the failure are written
    else:
      check uc.regReadBatch([UC_X86_REG_RAX, UC_X86_REG_XMM0]) == @[1'u64, 0]

  test "register ids computed at run time":
    # a table that spans architectures cannot hold their different enums
    type Platform = tuple[arch: uc_arch; mode: uc_mode; result, counter: cint]
    let platforms: seq[Platform] = @[
      (UC_ARCH_X86, UC_MODE_64, cint(ord(UC_X86_REG_RAX)), cint(ord(UC_X86_REG_RCX))),
      (UC_ARCH_X86, UC_MODE_32, cint(ord(UC_X86_REG_EAX)), cint(ord(UC_X86_REG_ECX))),
      (UC_ARCH_ARM64, UC_MODE_ARM, cint(ord(UC_ARM64_REG_X0)), cint(ord(UC_ARM64_REG_X1))),
      (UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, cint(ord(UC_MIPS_REG_2)),
       cint(ord(UC_MIPS_REG_4)))]
    for platform in platforms:
      if not uc_arch_supported(platform.arch): continue
      let uc = initUnicorn(platform.arch, platform.mode)
      uc.regWrite(platform.result, 0x1234)
      uc.regWrite(platform.counter, 0xFFFF_FFFF'u64)
      check uc.regRead(platform.result) == 0x1234
      check uc.regRead(platform.counter) == 0xFFFF_FFFF'u64
    let uc = newX64()
    when libVersion >= (2, 1, 0):
      expectCode(UC_ERR_OVERFLOW): discard uc.regRead(cint(ord(UC_X86_REG_XMM0)))
      expectCode(UC_ERR_OVERFLOW): uc.regWrite(cint(ord(UC_X86_REG_XMM0)), 1)
    else:
      uc.regWrite(cint(ord(UC_X86_REG_XMM0)), 0x55)
      check uc.regRead(cint(ord(UC_X86_REG_XMM0))) == 0x55
      check uc.regRead(UC_X86_REG_XMM0, array[2, uint64]) == [0x55'u64, 0]

  test "pc is the program counter of every architecture and mode":
    type Case = tuple[arch: uc_arch; mode: uc_mode; address: uint64]
    let cases: seq[Case] = @[
      (UC_ARCH_X86, UC_MODE_16, 0x5678'u64),       # IP has 16 bits
      (UC_ARCH_X86, UC_MODE_32, 0x1234_5678'u64),
      (UC_ARCH_X86, UC_MODE_64, 0x12_3456_789A'u64),
      (UC_ARCH_ARM, UC_MODE_ARM, 0x1234_5678'u64),
      (UC_ARCH_ARM, UC_MODE_THUMB, 0x1234_5678'u64),
      (UC_ARCH_ARM64, UC_MODE_ARM, 0x12_3456_7898'u64),
      (UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, 0x1234_5678'u64),
      (UC_ARCH_MIPS, UC_MODE_MIPS64, 0x12_3456_7898'u64),
      (UC_ARCH_PPC, UC_MODE_PPC32 or UC_MODE_BIG_ENDIAN, 0x1234_5678'u64),
      (UC_ARCH_PPC, UC_MODE_PPC64 or UC_MODE_BIG_ENDIAN, 0x12_3456_7898'u64),
      # SPARC64 works the same, but Unicorn leaks memory when such an engine is closed
      (UC_ARCH_SPARC, UC_MODE_SPARC32 or UC_MODE_BIG_ENDIAN, 0x1234_5678'u64),
      (UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, 0x1234_5678'u64),
      (UC_ARCH_RISCV, UC_MODE_RISCV32, 0x1234_5678'u64),
      (UC_ARCH_RISCV, UC_MODE_RISCV64, 0x12_3456_7898'u64),
      (UC_ARCH_S390X, UC_MODE_BIG_ENDIAN, 0x12_3456_7898'u64),
      (UC_ARCH_TRICORE, UC_MODE_LITTLE_ENDIAN, 0x1234_5678'u64)]
    var tried = 0
    for c in cases:
      if not uc_arch_supported(c.arch): continue
      let uc = initUnicorn(c.arch, c.mode)
      uc.pc = c.address
      checkpoint $c.arch & " " & $c.mode
      check uc.pc == c.address
      inc tried
    check tried >= 3

  test "pc follows the emulation and can be set to choose where it goes on":
    let uc = newX64()
    uc.start(base, base + 7)
    check uc.pc == base + 7
    check uc.regRead(UC_X86_REG_RIP) == base + 7
    uc.pc = base + 23
    uc.start(uc.pc, stop)                          # only `inc rcx; nop`
    check uc.pc == stop
    check uc.regRead(UC_X86_REG_RCX) == 1
    check uc.regRead(UC_X86_REG_RBX) == 0
    let x32 = initUnicorn(UC_ARCH_X86, UC_MODE_32)
    x32.memMap(base, 0x1000)
    x32.memWrite(base, nops)
    x32.start(base, base + 3)
    check x32.pc == base + 3
    check x32.regRead(UC_X86_REG_EIP) == base + 3
    if uc_arch_supported(UC_ARCH_ARM):
      let thumb = initUnicorn(UC_ARCH_ARM, UC_MODE_THUMB)
      thumb.memMap(0x10000, 0x1000)
      thumb.memWrite(0x10000, [0x00'u8, 0xbf, 0x00, 0xbf])   # nop; nop
      thumb.start(0x10001, 0x10004)                # the odd address selects Thumb
      check thumb.pc == 0x10004

suite "running":
  test "an instruction count holds for code that has run before without one":
    # a loop: inc rax; inc rbx; jmp +0; inc rcx; cmp rax, 50; jne start; nop
    let uc = newX64([0x48'u8, 0xFF, 0xC0, 0x48, 0xFF, 0xC3, 0xEB, 0x00,
                     0x48, 0xFF, 0xC1, 0x48, 0x83, 0xF8, 0x32, 0x75, 0xEF, 0x90])
    uc.start(base, base + 0x12)
    check uc.regRead(UC_X86_REG_RAX) == 50
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 0x12, count = 3)         # Unicorn alone runs the loop to its end
    check uc.regRead(UC_X86_REG_RAX) == 1
    check uc.pc == base + 8
    uc.start(uc.pc, base + 0x12, count = 2)        # and one count after another
    check uc.pc == base + 0xf
    uc.start(uc.pc, base + 0x12)                   # the rest without
    check uc.regRead(UC_X86_REG_RAX) == 50
    check uc.pc == base + 0x12

  test "count limits the number of instructions":
    let uc = newX64()
    uc.start(base, stop, count = 1)
    check uc.pc == base + 7
    check uc.regRead(UC_X86_REG_RAX) == 0x1234
    check uc.regRead(UC_X86_REG_RBX) == 0
    uc.start(uc.pc, stop, count = 2)
    check uc.regRead(UC_X86_REG_RBX) == 0x1234
    check uc.regRead(UC_X86_REG_RCX) == 0

  test "a timeout ends a run that would not end, and says so":
    let uc = newX64(forever)
    uc.start(base, 0, timeout = 20_000)            # microseconds
    check uc.timedOut
    check uc.pc == base
    uc.start(base, 0, initDuration(milliseconds = 20))
    check uc.timedOut
    uc.start(base, 0, timeout = initDuration(milliseconds = 20), count = 0)
    check uc.timedOut

  test "a run that ends in time has not timed out":
    let uc = newX64()
    uc.start(base, stop, initDuration(seconds = 30))
    check not uc.timedOut
    check uc.regRead(UC_X86_REG_RBX) == 0x1234
    uc.start(base, stop, DurationZero)             # no limit
    check not uc.timedOut
    uc.start(base, stop, timeout = 30_000_000, count = 2)
    check not uc.timedOut
    expectCode(UC_ERR_ARG): uc.start(base, stop, initDuration(milliseconds = -1))

  test "a Duration is handed to Unicorn in microseconds, rounded up to one":
    let uc = newX64()
    var nanoseconds: uint64
    uc.start(base, stop, initDuration(seconds = 2, milliseconds = 5))
    check uc_ctl_get_timeout(uc.handle, addr nanoseconds) == UC_ERR_OK
    check nanoseconds == 2_005_000_000'u64
    uc.start(base, stop, initDuration(nanoseconds = 300))
    check uc_ctl_get_timeout(uc.handle, addr nanoseconds) == UC_ERR_OK
    check nanoseconds == 1000

suite "errors":
  test "a failed call raises UnicornError with Unicorn's code and text":
    let uc = newX64()
    try:
      uc.memMap(0x5001, 0x1000)
      fail()
    except UnicornError as e:
      check e.code == UC_ERR_ARG
      check e.msg == $uc_strerror(UC_ERR_ARG)
      check "Invalid argument" in e.msg

  test "opening what the library does not have":
    expectCode(UC_ERR_MODE): discard initUnicorn(UC_ARCH_X86, UC_MODE_THUMB or UC_MODE_MCLASS)
    expectCode(UC_ERR_ARCH): discard initUnicorn(UC_ARCH_MAX, UC_MODE_32)

  test "an emulation that fails says why, and the engine stays usable":
    let uc = newX64()
    expectCode(UC_ERR_FETCH_UNMAPPED): uc.start(0x900000, 0x900010)
    uc.memUnmap(data, 0x1000)
    expectCode(UC_ERR_WRITE_UNMAPPED): uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RAX) == 0x1234     # the instruction before the fault ran
    uc.memMap(data, 0x1000)
    uc.start(base + 7, stop)
    check uc.regRead(UC_X86_REG_RBX) == 0x1234

  test "an instruction that is none, and an interrupt nobody handles":
    let ud2 = newX64([0x90'u8, 0x0F, 0x0B])
    expectCode(UC_ERR_INSN_INVALID): ud2.start(base, base + 3)
    check ud2.pc == base + 1
    let interrupt = newX64([0xCD'u8, 0x80])        # int 0x80
    expectCode(UC_ERR_EXCEPTION): interrupt.start(base, base + 2)

suite "contexts":
  test "a context brings the registers back":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 7)
    uc.regWrite(UC_X86_REG_RCX, 8)
    let ctx = uc.saveContext()
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RAX) == 0x1234
    uc.restore(ctx)
    check uc.regRead(UC_X86_REG_RAX) == 7
    check uc.regRead(UC_X86_REG_RCX) == 8
    uc.restore(ctx)                                # as often as wanted
    check uc.regRead(UC_X86_REG_RAX) == 7

  test "its registers can be read and changed":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 0x1122_3344_5566_7788'u64)
    var ctx = uc.saveContext()
    uc.regWrite(UC_X86_REG_RAX, 9)
    check ctx.regRead(UC_X86_REG_RAX) == 0x1122_3344_5566_7788'u64
    check ctx.regRead(UC_X86_REG_EAX) == 0x5566_7788'u64
    check ctx.regRead(UC_X86_REG_AX, uint16) == 0x7788
    ctx.regWrite(UC_X86_REG_RBX, -1)
    ctx.regWrite(UC_X86_REG_CX, 0xABCD)
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = byte(0xF0 + i)
    ctx.regWrite(UC_X86_REG_XMM7, xmm)
    check ctx.regRead(UC_X86_REG_XMM7, array[16, byte]) == xmm
    check uc.regRead(UC_X86_REG_RBX) == 0          # the engine is untouched until restore
    uc.restore(ctx)
    check uc.regRead(UC_X86_REG_RAX) == 0x1122_3344_5566_7788'u64
    check uc.regRead(UC_X86_REG_RBX) == high(uint64)
    check uc.regRead(UC_X86_REG_RCX) == 0xABCD
    check uc.regRead(UC_X86_REG_XMM7, array[16, byte]) == xmm

  test "a type smaller than the register is not overrun through a context either":
    type Guarded = object
      before: uint64
      value: uint32
      after: uint64
    let uc = newX64()
    var xmm: array[16, byte]
    for i in 0 .. 15: xmm[i] = byte(i + 1)
    uc.regWrite(UC_X86_REG_XMM3, xmm)
    var ctx = uc.saveContext()
    var guarded = Guarded(before: 0x1111_1111_1111_1111'u64, after: 0x2222_2222_2222_2222'u64)
    when libVersion >= (2, 1, 0):
      expectCode(UC_ERR_OVERFLOW): discard ctx.regRead(UC_X86_REG_XMM3)
      expectCode(UC_ERR_OVERFLOW): ctx.regRead(UC_X86_REG_XMM3, guarded.value)
      expectCode(UC_ERR_OVERFLOW): ctx.regWrite(UC_X86_REG_XMM3, 5)
      expectCode(UC_ERR_OVERFLOW): ctx.regWrite(UC_X86_REG_XMM3, [1'u8, 2])
      check ctx.regRead(UC_X86_REG_XMM3, array[16, byte]) == xmm
    else:
      check ctx.regRead(UC_X86_REG_XMM3) == 0x0807060504030201'u64
      ctx.regRead(UC_X86_REG_XMM3, guarded.value)   # reads into the variable between the guards
      check guarded.value == 0x04030201'u32
      ctx.regWrite(UC_X86_REG_XMM3, 5)
      check ctx.regRead(UC_X86_REG_XMM3, array[2, uint64]) == [5'u64, 0]
    check guarded.before == 0x1111_1111_1111_1111'u64
    check guarded.after == 0x2222_2222_2222_2222'u64

  test "registers that Unicorn cannot reach without the engine are refused":
    let uc = newX64()
    uc.msrWrite(0xC000_0100'u32, 0x55)
    var ctx = uc.saveContext()
    expectCode(UC_ERR_ARG): discard ctx.regRead(UC_X86_REG_MSR, uc_x86_msr)
    expectCode(UC_ERR_ARG): ctx.regWrite(UC_X86_REG_MSR, uc_x86_msr(rid: 0xC000_0100'u32))
    expectCode(UC_ERR_ARG): ctx.regWrite(UC_X86_REG_CR0, 1)
    check ctx.regRead(UC_X86_REG_CR0) == uc.regRead(UC_X86_REG_CR0)   # reading is fine
    # in protected mode a segment register is loaded from the descriptor
    # table, which is in the engine's memory: Unicorn crashes on that
    let protected = initUnicorn(UC_ARCH_X86, UC_MODE_32)
    protected.memMap(0x8000, 0x1000)
    protected.memWrite(0x8010, [0xff'u8, 0xff, 0x00, 0x00, 0x00, 0x93, 0xcf, 0x00])
    protected.regWrite(UC_X86_REG_GDTR, uc_x86_mmr(base: 0x8000, limit: 0x1f))
    var protectedCtx = protected.saveContext()
    for reg in [UC_X86_REG_CS, UC_X86_REG_DS, UC_X86_REG_ES, UC_X86_REG_FS, UC_X86_REG_GS,
                UC_X86_REG_SS]:
      expectCode(UC_ERR_ARG): protectedCtx.regWrite(reg, 0x10)
      discard protectedCtx.regRead(reg)
    protected.regWrite(UC_X86_REG_DS, 0x10)        # the engine can
    check protected.regRead(UC_X86_REG_DS) == 0x10
    check ctx.regRead(UC_X86_REG_FS_BASE) == 0x55
    if uc_arch_supported(UC_ARCH_ARM):
      let arm = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      arm.pc = 0x2000
      var armCtx = arm.saveContext()
      check armCtx.regRead(UC_ARM_REG_PC) == 0x2000
      expectCode(UC_ERR_ARG): armCtx.regWrite(UC_ARM_REG_PC, 0x3000)
      expectCode(UC_ERR_ARG): discard armCtx.regRead(UC_ARM_REG_CP_REG, uc_arm_cp_reg)
      armCtx.regWrite(UC_ARM_REG_R0, 7)
      arm.restore(armCtx)
      arm.pc = 0x3000                              # the engine's register does it
      check arm.regRead(UC_ARM_REG_R0) == 7

  test "every register of a context is refused or harmless without its engine":
    # A random walk over the registers of a context whose engine is closed:
    # reads and writes of every register id with assorted values, so that
    # what one write sets up another can trip over (a descriptor table
    # register and then a segment register, for example). What goes wrong
    # inside Unicorn shows as a crash here, or as an invalid access when this
    # runs under valgrind.
    putEnv("UC_IGNORE_REG_BREAK", "1")             # Unicorn 2.1.3 warns about ids it does not have
    var refused = 0
    var rng = initRand(20261121)
    template walk(arch: uc_arch; mode: uc_mode; Reg: typedesc; last: untyped) =
      if uc_arch_supported(arch):
        var ctx = block:
          let uc = initUnicorn(arch, mode)
          uc.saveContext()
        for step in 1 .. 4000:
          let reg = cast[Reg](int32(rng.rand(1 .. ord(last) - 1)))
          var value: array[64, byte]
          case rng.rand(0 .. 5)
          of 0: discard
          of 1:
            for b in value.mitems: b = 0xFF
          of 2: value[0] = byte(rng.rand(0 .. 255))
          of 3: value[rng.rand(0 .. 7)] = byte(1 shl rng.rand(0 .. 7))
          of 4:
            for i in 0 .. 7: value[i] = byte(rng.rand(0 .. 255))
          else:
            for b in value.mitems: b = byte(rng.rand(0 .. 255))
          var number: uint64
          copyMem(addr number, addr value, 8)
          try:
            case rng.rand(0 .. 7)
            of 0: discard ctx.regRead(reg, array[64, byte])
            of 1: discard ctx.regRead(reg)
            of 2: discard ctx.regRead(reg, uint32)
            of 3: ctx.regWrite(reg, value)
            of 4: ctx.regWrite(reg, number)
            of 5: ctx.regWrite(reg, uint32(number and 0xFFFF_FFFF'u64))
            of 6: ctx.regWrite(reg, uint16(number and 0xFFFF))
            else: ctx.regWrite(reg, uint8(number and 0xFF))
          except UnicornError:
            inc refused
    walk(UC_ARCH_X86, UC_MODE_16, uc_x86_reg, UC_X86_REG_ENDING)
    walk(UC_ARCH_X86, UC_MODE_32, uc_x86_reg, UC_X86_REG_ENDING)
    walk(UC_ARCH_X86, UC_MODE_64, uc_x86_reg, UC_X86_REG_ENDING)
    check refused > 0
    walk(UC_ARCH_ARM, UC_MODE_ARM, uc_arm_reg, UC_ARM_REG_ENDING)
    walk(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_BIG_ENDIAN, uc_arm_reg, UC_ARM_REG_ENDING)
    walk(UC_ARCH_ARM, UC_MODE_THUMB, uc_arm_reg, UC_ARM_REG_ENDING)
    walk(UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_MCLASS, uc_arm_reg, UC_ARM_REG_ENDING)
    walk(UC_ARCH_ARM64, UC_MODE_ARM, uc_arm64_reg, UC_ARM64_REG_ENDING)
    walk(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, uc_mips_reg, UC_MIPS_REG_ENDING)
    walk(UC_ARCH_MIPS, UC_MODE_MIPS32, uc_mips_reg, UC_MIPS_REG_ENDING)
    walk(UC_ARCH_MIPS, UC_MODE_MIPS64, uc_mips_reg, UC_MIPS_REG_ENDING)
    walk(UC_ARCH_PPC, UC_MODE_PPC32 or UC_MODE_BIG_ENDIAN, uc_ppc_reg, UC_PPC_REG_ENDING)
    walk(UC_ARCH_PPC, UC_MODE_PPC64 or UC_MODE_BIG_ENDIAN, uc_ppc_reg, UC_PPC_REG_ENDING)
    # SPARC64 is left out: Unicorn leaks memory when such an engine is closed
    walk(UC_ARCH_SPARC, UC_MODE_SPARC32 or UC_MODE_BIG_ENDIAN, uc_sparc_reg, UC_SPARC_REG_ENDING)
    walk(UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, uc_m68k_reg, UC_M68K_REG_ENDING)
    walk(UC_ARCH_RISCV, UC_MODE_RISCV32, uc_riscv_reg, UC_RISCV_REG_ENDING)
    walk(UC_ARCH_RISCV, UC_MODE_RISCV64, uc_riscv_reg, UC_RISCV_REG_ENDING)
    walk(UC_ARCH_S390X, UC_MODE_BIG_ENDIAN, uc_s390x_reg, UC_S390X_REG_ENDING)
    walk(UC_ARCH_TRICORE, UC_MODE_LITTLE_ENDIAN, uc_tricore_reg, UC_TRICORE_REG_ENDING)

  test "save fills an existing context again":
    let uc = newX64()
    uc.regWrite(UC_X86_REG_RAX, 1)
    var ctx = uc.saveContext()
    let storage = ctx.handle
    uc.regWrite(UC_X86_REG_RAX, 2)
    uc.save(ctx)
    check ctx.handle == storage                    # nothing new was allocated
    check ctx.regRead(UC_X86_REG_RAX) == 2
    var fresh: Context
    expectCode(UC_ERR_HANDLE): discard fresh.regRead(UC_X86_REG_RAX)
    expectCode(UC_ERR_HANDLE): uc.restore(fresh)
    uc.save(fresh)
    check fresh.regRead(UC_X86_REG_RAX) == 2

  test "a context outlives its engine":
    proc saved(): Context =
      let uc = newX64()
      uc.regWrite(UC_X86_REG_RAX, 0x77)
      uc.saveContext()
    var ctx = saved()                              # the engine is closed by now
    check ctx.regRead(UC_X86_REG_RAX) == 0x77
    ctx.regWrite(UC_X86_REG_RAX, 0x78)
    check ctx.regRead(UC_X86_REG_RAX) == 0x78
    check ctx.regRead(UC_X86_REG_XMM0, array[16, byte]) == default(array[16, byte])

  test "a context belongs to the engine that saved it":
    let first = newX64()
    let second = newX64()
    first.regWrite(UC_X86_REG_RAX, 1)
    second.regWrite(UC_X86_REG_RAX, 2)
    var ctx = first.saveContext()
    expectCode(UC_ERR_ARG): second.restore(ctx)
    check second.regRead(UC_X86_REG_RAX) == 2
    second.save(ctx)                               # now it is the second engine's
    check ctx.regRead(UC_X86_REG_RAX) == 2
    expectCode(UC_ERR_ARG): first.restore(ctx)
    second.regWrite(UC_X86_REG_RAX, 3)
    second.restore(ctx)
    check second.regRead(UC_X86_REG_RAX) == 2
    # the C API is there for restoring into another engine of the same kind
    check uc_context_restore(first.handle, ctx.handle) == UC_ERR_OK
    check first.regRead(UC_X86_REG_RAX) == 2

  test "contexts can be kept in a seq and moved":
    let uc = newX64()
    var history: seq[Context]
    for i in 1 .. 4:
      uc.regWrite(UC_X86_REG_RAX, i)
      history.add uc.saveContext()
    var third = move history[2]
    history.setLen(1)
    uc.restore(third)
    check uc.regRead(UC_X86_REG_RAX) == 3
    uc.restore(history[0])
    check uc.regRead(UC_X86_REG_RAX) == 1

  test "with contextMode a context holds the memory as well":
    when libVersion >= (2, 1, 0):
      if memoryContexts:
        let uc = newX64()
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        uc.memWrite(data, "before")
        uc.regWrite(UC_X86_REG_RAX, 1)
        var ctx = uc.saveContext()
        uc.memWrite(data, "after!")
        uc.regWrite(UC_X86_REG_RAX, 2)
        uc.restore(ctx)
        check cast[string](uc.memRead(data, 6)) == "before"
        check uc.regRead(UC_X86_REG_RAX) == 1
        uc.memWrite(data, "third!")
        uc.save(ctx)
        uc.memWrite(data, "fourth")
        uc.restore(ctx)
        check uc.memRead(data, 1) == @[byte('t')]
        expectCode(UC_ERR_ARG): uc.contextMode = {}
      else:
        skip()   # see `memoryContexts`
    else:
      check not compiles((newX64().contextMode = {UC_CTL_CONTEXT_CPU}))

  test "contexts with memory are a stack: restoring one ends those saved after it":
    # Unicorn crashes, or brings back other memory, when asked for a later one
    when libVersion >= (2, 1, 0):
      if memoryContexts:
        let uc = newX64()
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        var saved: seq[Context]
        for i in 0 .. 4:
          uc.memWrite(data, [byte(i)])
          saved.add uc.saveContext()
        uc.restore(saved[3])
        check uc.memRead(data, 1) == @[3'u8]
        expectCode(UC_ERR_ARG): uc.restore(saved[4])
        check uc.memRead(data, 1) == @[3'u8]
        uc.restore(saved[1])
        check uc.memRead(data, 1) == @[1'u8]
        expectCode(UC_ERR_ARG): uc.restore(saved[3])
        expectCode(UC_ERR_ARG): uc.restore(saved[2])
        uc.restore(saved[1])                         # the same one again is fine
        uc.memWrite(data, [9'u8])
        saved.add uc.saveContext()                   # and saving goes on from there
        uc.memWrite(data, [10'u8])
        uc.restore(saved[5])
        check uc.memRead(data, 1) == @[9'u8]
        uc.restore(saved[0])
        check uc.memRead(data, 1) == @[0'u8]
      else:
        skip()   # see `memoryContexts`
    else:
      skip()

  test "a context is restored under the contextMode it was saved with":
    when libVersion >= (2, 1, 0):
      if memoryContexts:
        let uc = newX64()
        uc.regWrite(UC_X86_REG_RAX, 1)
        var registers = uc.saveContext()
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        expectCode(UC_ERR_ARG): uc.restore(registers)    # Unicorn 2.1.3 crashes on this
        uc.memWrite(data, "both")
        var both = uc.saveContext()
        uc.contextMode = {UC_CTL_CONTEXT_MEMORY}
        expectCode(UC_ERR_ARG): uc.restore(both)
        uc.memWrite(data, "only")
        uc.regWrite(UC_X86_REG_RAX, 7)
        var memory = uc.saveContext()
        # without the registers there is nothing to read: Unicorn hands out
        # whatever the storage held
        expectCode(UC_ERR_ARG): discard memory.regRead(UC_X86_REG_RAX)
        expectCode(UC_ERR_ARG): memory.regWrite(UC_X86_REG_RAX, 1)
        uc.memWrite(data, "gone")
        uc.regWrite(UC_X86_REG_RAX, 9)
        uc.restore(memory)
        check cast[string](uc.memRead(data, 4)) == "only"
        check uc.regRead(UC_X86_REG_RAX) == 9          # the registers stay as they are
        uc.contextMode = {UC_CTL_CONTEXT_CPU}
        uc.restore(registers)
        check uc.regRead(UC_X86_REG_RAX) == 1
        check cast[string](uc.memRead(data, 4)) == "only"
      else:
        skip()   # see `memoryContexts`
    else:
      skip()

  test "Unicorn 2.1.2 cannot restore memory, so contextMode refuses it there":
    when libVersion >= (2, 1, 0):
      let uc = newX64()
      if memoryContexts:
        uc.contextMode = {UC_CTL_CONTEXT_MEMORY}
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
      else:                                        # see `memoryContexts`
        expectCode(UC_ERR_ARG): uc.contextMode = {UC_CTL_CONTEXT_MEMORY}
        expectCode(UC_ERR_ARG): uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        try:
          uc.contextMode = {UC_CTL_CONTEXT_MEMORY}
        except UnicornError as e:
          check "2.1.2" in e.msg
        expectCode(UC_ERR_ARG): uc.contextMode = {}
      uc.contextMode = {UC_CTL_CONTEXT_CPU}        # the registers work with every release
      uc.regWrite(UC_X86_REG_RAX, 5)
      uc.memWrite(data, [5'u8])
      let ctx = uc.saveContext()
      uc.regWrite(UC_X86_REG_RAX, 6)
      uc.memWrite(data, [6'u8])
      uc.restore(ctx)
      check uc.regRead(UC_X86_REG_RAX) == 5
      check uc.memRead(data, 1) == @[6'u8]
    else:
      skip()

  test "whatever restore accepts brings back exactly what was saved":
    # random saves, restores and freed contexts, checked against a model
    when libVersion >= (2, 1, 0):
      if memoryContexts:
        const size = 0x2000
        var rng = initRand(7)
        let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
        uc.memMap(0x10000, size)
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        var model = newSeq[byte](size)
        var saved: seq[tuple[ctx: Context; memory: seq[byte]; rax: uint64]]
        var restores, refusals, wrong = 0
        for step in 1 .. 300:
          case rng.rand(0 .. 9)
          of 0 .. 4:
            let at = rng.rand(0 ..< size)
            let value = byte(rng.rand(1 .. 255))
            uc.memWrite(0x10000'u64 + uint64(at), [value])
            model[at] = value
            uc.regWrite(UC_X86_REG_RAX, step)
          of 5 .. 6:
            if saved.len < 10: saved.add (uc.saveContext(), model, uc.regRead(UC_X86_REG_RAX))
          of 7:
            if saved.len > 0 and rng.rand(0 .. 3) == 0: saved.delete(rng.rand(0 ..< saved.len))
          else:
            if saved.len > 0:
              let i = rng.rand(0 ..< saved.len)
              try:
                uc.restore(saved[i].ctx)
                inc restores
                model = saved[i].memory
                if uc.memRead(0x10000, size) != model or uc.regRead(UC_X86_REG_RAX) != saved[i].rax:
                  inc wrong
                  model = uc.memRead(0x10000, size)
              except UnicornError:
                inc refusals
        check wrong == 0
        check restores > 5
        check refusals > 5
      else:
        skip()   # see `memoryContexts`
    else:
      skip()

suite "control and query":
  test "the page size is 4096 for x86; other architectures have their own":
    check newX64().pageSize == 4096
    if uc_arch_supported(UC_ARCH_ARM):
      check initUnicorn(UC_ARCH_ARM, UC_MODE_ARM).pageSize == 1024

  test "an ARM engine takes another page size, before anything else is done":
    if not uc_arch_supported(UC_ARCH_ARM):
      skip()
    else:
      let arm = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      arm.pageSize = 16384
      check arm.pageSize == 16384
      arm.memMap(0x4000, 0x4000)
      expectCode(UC_ERR_ARG): arm.memMap(0x9000, 0x1000)   # 4 KB pages no longer fit
      expectCode(UC_ERR_ARG): arm.pageSize = 4096          # too late
      let odd = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      expectCode(UC_ERR_ARG): odd.pageSize = 5000           # not a power of two
      expectCode(UC_ERR_ARG): odd.pageSize = 3
      expectCode(UC_ERR_ARG): odd.pageSize = 0
      expectCode(UC_ERR_ARG): odd.pageSize = -4096
      # powers of two that Unicorn takes, to abort or crash later
      for size in [1, 2, 512, 1 shl 27, 1 shl 30]:
        expectCode(UC_ERR_ARG): odd.pageSize = size
      odd.pageSize = 1024                          # the smallest
      check odd.pageSize == 1024
      let large = initUnicorn(UC_ARCH_ARM, UC_MODE_ARM)
      large.pageSize = 1 shl 26                    # the largest
      check large.pageSize == 1 shl 26
    let x86 = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    expectCode(UC_ERR_ARG): x86.pageSize = 16384           # x86 has one page size

  test "the CPU model can be chosen first and read back":
    let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    uc.cpuModel = UC_CPU_X86_SKYLAKE_CLIENT
    check uc.cpuModel == ord(UC_CPU_X86_SKYLAKE_CLIENT)
    check uc.cpuModel(uc_cpu_x86) == UC_CPU_X86_SKYLAKE_CLIENT
    let byNumber = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    byNumber.cpuModel = uc.cpuModel                # the number that `cpuModel` returns
    check byNumber.cpuModel(uc_cpu_x86) == UC_CPU_X86_SKYLAKE_CLIENT
    expectCode(UC_ERR_ARG): initUnicorn(UC_ARCH_X86, UC_MODE_64).cpuModel = -1
    expectCode(UC_ERR_ARG): uc.cpuModel = UC_CPU_X86_QEMU64   # reading it fixed it
    # the default differs between Unicorn versions (QEMU64 up to 2.1.1, HASWELL later)
    check newX64().cpuModel(uc_cpu_x86) in {UC_CPU_X86_QEMU64, UC_CPU_X86_HASWELL}

  test "exit addresses replace the end address":
    let uc = newX64(nops)
    check uc.exits.len == 0
    uc.exits = [base + 4, base + 2]
    check uc.exits == @[base + 2, base + 4]
    uc.start(base, base + 6)
    check uc.pc == base + 2
    uc.start(base + 3, base + 6)
    check uc.pc == base + 4
    uc.exits = [base + 5]                          # replaces the list
    check uc.exits == @[base + 5]
    uc.start(base, 0)
    check uc.pc == base + 5

  test "exits can be emptied and switched off again":
    let uc = newX64(nops)
    uc.exits = [base + 2]
    uc.exits = newSeq[uint64]()
    check uc.exits.len == 0
    uc.start(base, base + 2, count = 4)            # no exit: `until` is ignored
    check uc.pc == base + 4
    uc.exits = [base + 2]
    uc.clearExits()
    check uc.exits.len == 0
    uc.start(base, base + 5)
    check uc.pc == base + 5
    uc.clearExits()                                # switching off twice is fine

  test "translated code is kept until it is discarded":
    let uc = newX64(forever)
    uc.start(base, 0, initDuration(milliseconds = 10))
    check uc.timedOut
    uc.memWrite(base, nops)                        # the loop is still in the cache
    uc.removeCache(base .. base + 1)
    uc.start(base, base + 2, initDuration(seconds = 30))
    check not uc.timedOut
    check uc.pc == base + 2
    uc.memWrite(base, forever)
    uc.flushTb()
    uc.start(base, 0, initDuration(milliseconds = 10))
    check uc.timedOut
    expectCode(UC_ERR_ARG): uc.removeCache(base + 1 .. base - 1)   # an empty range
    uc.memWrite(base, nops)
    uc.removeCache(base .. base)                   # the range ends with its last address
    uc.start(base, base + 2, initDuration(seconds = 30))
    check not uc.timedOut

  test "a block can be translated ahead of time":
    let uc = newX64([0x90'u8, 0x90, 0xEB, 0x00, 0x90, 0xEB, 0x00])   # nop; nop; jmp; nop; jmp
    let tb = uc.requestCache(base)
    check tb.pc == base
    check tb.icount == 3
    check tb.size == 4
    check uc.requestCache(base + 4) == uc_tb(pc: base + 4, icount: 2, size: 3)
    expectCode(UC_ERR_FETCH_UNMAPPED): discard uc.requestCache(0x900000)   # not mapped
    uc.memMap(data, 0x1000, readWrite)
    expectCode(UC_ERR_FETCH_UNMAPPED): discard uc.requestCache(data)       # not executable

  test "the translation buffer size is a property of Unicorn 2.1":
    when libVersion >= (2, 1, 0):
      let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
      uc.tcgBufferSize = 64 * 1024 * 1024
      check uc.tcgBufferSize == 64 * 1024 * 1024
      uc.memMap(base, 0x1000)
      uc.memWrite(base, nops)
      uc.start(base, base + 6)
      check uc.pc == base + 6
      check newX64().tcgBufferSize > 0
      expectCode(UC_ERR_ARG): uc.tcgBufferSize = -1
    else:
      check not compiles(newX64().tcgBufferSize)
      check not compiles((newX64().tcgBufferSize = 1))

  test "virtual TLB mode maps addresses one to one without a hook":
    when libVersion >= (2, 1, 0):
      let uc = newX64()
      uc.tlbMode = UC_TLB_VIRTUAL
      uc.start(base, stop)
      check uc.regRead(UC_X86_REG_RBX) == 0x1234
      uc.flushTlb()
      uc.tlbMode = UC_TLB_CPU
      uc.start(base, stop)
      check uc.regRead(UC_X86_REG_RCX) == 2
    else:
      check not compiles((newX64().tlbMode = UC_TLB_VIRTUAL))
      check not compiles(newX64().flushTlb())

suite "moving the engine":
  test "an engine can be returned, moved and kept in a seq":
    proc make(rcx: int): Unicorn =
      result = newX64()
      result.regWrite(UC_X86_REG_RCX, rcx)
    var engines: seq[Unicorn]
    for i in 0 .. 2: engines.add make(i * 10)
    var second = move engines[1]
    engines.setLen(1)                              # closes the third
    second.start(base, stop)
    engines[0].start(base, stop)
    check second.regRead(UC_X86_REG_RCX) == 11
    check engines[0].regRead(UC_X86_REG_RCX) == 1

  test "what was moved from holds no engine":
    var first = newX64()
    let second = move first
    expectCode(UC_ERR_HANDLE): first.start(base, stop)
    second.start(base, stop)
    check second.regRead(UC_X86_REG_RBX) == 0x1234
    first = newX64()                               # and can be given one again
    first.start(base, stop)
    check first.regRead(UC_X86_REG_RBX) == 0x1234

  test "hooks go with the engine":
    var engines: seq[Unicorn]
    var steps = [0, 0]
    proc counting(index: int): Unicorn =
      result = newX64()
      discard result.onCode(proc (uc: Unicorn; address: uint64; size: int) = inc steps[index])
    for i in 0 .. 1: engines.add counting(i)
    var moved = move engines[1]
    engines.setLen(1)
    engines[0].start(base, stop)
    moved.start(base, stop)
    moved.start(base, stop)
    check steps == [5, 10]

suite "versions":
  test "the library in the process can run what this build was made for":
    check library.major == 2
    check (library.major, library.minor, library.patch) >= libVersion
    check libraryMatchesBindings()
    check libVersionText.startsWith($libVersion[0] & "." & $libVersion[1] & "." & $libVersion[2])
    check bindingsVersion >= (2, 0, 0)

  test "what Unicorn 2.1 added is there exactly when the build is against 2.1":
    let uc = newX64()
    let fill = proc (uc: Unicorn; address: uint64; kind: uc_mem_type;
                     entry: var uc_tlb_entry): bool = false
    check compiles(uc.onTlbFill(fill)) == (libVersion >= (2, 1, 0))
    check compiles((uc.tlbMode = UC_TLB_CPU)) == (libVersion >= (2, 1, 0))
    check compiles((uc.contextMode = {UC_CTL_CONTEXT_CPU})) == (libVersion >= (2, 1, 0))
    check compiles(uc.tcgBufferSize) == (libVersion >= (2, 1, 0))
