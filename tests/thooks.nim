## Hooks of the Nim API: every kind, address ranges, removal (also from
## inside the hook that runs), exceptions and defects raised in hooks, nested
## `start`, the lifetime of the closures, and the closures of `mmioMap`.

import std/[strutils, unittest]
import libunicorn

const
  base = 0x1000'u64
  data = 0x3000'u64
  # mov rax, 0x1234; mov [0x3000], rax; mov rbx, [0x3000]; inc rcx; nop
  code = [0x48'u8, 0xC7, 0xC0, 0x34, 0x12, 0x00, 0x00,
          0x48, 0x89, 0x04, 0x25, 0x00, 0x30, 0x00, 0x00,
          0x48, 0x8B, 0x1C, 0x25, 0x00, 0x30, 0x00, 0x00,
          0x48, 0xFF, 0xC1, 0x90]
  stop = base + uint64(code.len)
  insns = [base, base + 7, base + 15, base + 23, base + 26]   # where its instructions are
  nops = [0x90'u8, 0x90, 0x90, 0x90, 0x90, 0x90]

let library = uc_version()   # of the Unicorn in this process
# Unicorn 2.1.2 reads freed memory when it restores a context with memory;
# `contextMode=` refuses that there (see tapi)
let memoryContexts = (library.major, library.minor, library.patch) != (2, 1, 2)

proc newX64(mapData = true): Unicorn =
  ## An x86-64 engine with `code` at `base` and, unless told not to, a data
  ## page at `data`.
  result = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  result.memMap(base, 0x1000)
  if mapData: result.memMap(data, 0x1000, UC_PROT_READ or UC_PROT_WRITE)
  result.memWrite(base, code)

proc newX64(program: openArray[byte]): Unicorn =
  ## An x86-64 engine with `program` at `base` and nothing else.
  result = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  result.memMap(base, 0x1000)
  result.memWrite(base, program)

template expectCode(expected: uc_err; body: untyped) =
  ## `body` raises `UnicornError` with this code.
  try:
    body
    checkpoint "nothing was raised; expected " & $expected
    fail()
  except UnicornError as e:
    check e.code == expected

# A closure that captures a `Witness` shows when it is freed: that is how
# these tests see an engine let go of its hooks.
var released = 0

type
  Witness = object
    armed: bool
  DeviceError = object of CatchableError
    offset: uint64

proc `=destroy`(witness: Witness) =
  if witness.armed: inc released

proc `=copy`(dest: var Witness; source: Witness) {.error.}

proc onCodeWitnessed(uc: Unicorn; callback: CodeCallback): HookId =
  ## A code hook whose closure holds a `Witness`. Nothing but the engine
  ## refers to that closure once this proc has returned.
  let witness = Witness(armed: true)
  uc.onCode do (uc: Unicorn; address: uint64; size: int):
    doAssert witness.armed
    callback(uc, address, size)

proc onMemWitnessed(uc: Unicorn; kinds: uc_hook_type; callback: MemCallback): HookId =
  ## The same for a memory hook.
  let witness = Witness(armed: true)
  uc.onMem(kinds) do (uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
    doAssert witness.armed
    callback(uc, kind, address, size, value)

proc hex(address: uint64): string = toHex(address, 4)

suite "hook kinds":
  test "code: every instruction, with its address and size; the hook sees the engine":
    let uc = newX64()
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add hex(address) & "/" & $size & " rax=" & $uc.regRead(UC_X86_REG_RAX)
      check uc.pc == address
    uc.start(base, stop)
    check trace == @["1000/7 rax=0", "1007/8 rax=4660", "100F/8 rax=4660", "1017/3 rax=4660",
                     "101A/1 rax=4660"]

  test "block: once per basic block, with the size of the block":
    let uc = newX64([0x90'u8, 0xEB, 0x00, 0x90, 0xEB, 0x00, 0x90])   # nop; jmp; nop; jmp; nop
    var blocks: seq[string]
    discard uc.onBlock do (uc: Unicorn; address: uint64; size: int):
      blocks.add hex(address) & "/" & $size
    uc.start(base, base + 7)
    check blocks == @["1000/3", "1003/3", "1006/1"]

  test "mem: reads and writes, with address, size and value":
    let uc = newX64()
    var accesses: seq[string]
    discard uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      accesses.add $kind & "@" & hex(address) & "/" & $size & "=" & $value
    uc.start(base, stop)
    check accesses == @["UC_MEM_WRITE@3000/8=4660", "UC_MEM_READ@3000/8=0"]

  test "mem: UC_HOOK_MEM_READ_AFTER has the value that was read":
    # together with UC_HOOK_MEM_READ, which makes every release report every read
    let uc = newX64()
    var accesses: seq[string]
    discard uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_READ_AFTER) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      accesses.add $kind & "@" & hex(address) & "/" & $size & "=" & $value
    uc.start(base, stop)
    check accesses == @["UC_MEM_READ@3000/8=0", "UC_MEM_READ_AFTER@3000/8=4660"]

  test "mem: UC_HOOK_MEM_READ_AFTER alone misses reads before Unicorn 2.1.2":
    # there only the first access to a page comes by the hook: the program
    # writes to the page and then reads it
    let uc = newX64()
    var reads: seq[string]
    discard uc.onMem(UC_HOOK_MEM_READ_AFTER) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      reads.add $kind & "@" & hex(address) & "/" & $size & "=" & $value
    uc.start(base, stop)
    if (library.major, library.minor, library.patch) >= (2, 1, 2):
      check reads == @["UC_MEM_READ_AFTER@3000/8=4660"]
    else:
      check reads.len == 0

  test "onMem takes the kinds of accesses that succeed, onMemFault the others":
    let uc = newX64()
    let access = proc (uc: Unicorn; kind: uc_mem_type; address: uint64; size: int;
                       value: int64) = discard
    let fault = proc (uc: Unicorn; kind: uc_mem_type; address: uint64; size: int;
                      value: int64): bool = false
    expectCode(UC_ERR_HOOK): discard uc.onMem(UC_HOOK_MEM_UNMAPPED, access)
    expectCode(UC_ERR_HOOK): discard uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_READ_PROT, access)
    expectCode(UC_ERR_HOOK): discard uc.onMem(UC_HOOK_CODE, access)
    expectCode(UC_ERR_HOOK): discard uc.onMem(uc_hook_type(0), access)
    expectCode(UC_ERR_HOOK): discard uc.onMemFault(UC_HOOK_MEM_READ, fault)
    expectCode(UC_ERR_HOOK): discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED or UC_HOOK_MEM_WRITE, fault)
    expectCode(UC_ERR_HOOK): discard uc.onMemFault(UC_HOOK_INTR, fault)
    expectCode(UC_ERR_HOOK): discard uc.onMemFault(uc_hook_type(0), fault)
    try:
      discard uc.onMem(UC_HOOK_MEM_UNMAPPED, access)
    except UnicornError as e:
      check "onMem takes" in e.msg
    for kinds in [UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE, UC_HOOK_MEM_FETCH, UC_HOOK_MEM_READ_AFTER,
                  UC_HOOK_MEM_VALID]:
      uc.removeHook uc.onMem(kinds, access)
    for kinds in [UC_HOOK_MEM_READ_UNMAPPED, UC_HOOK_MEM_WRITE_UNMAPPED, UC_HOOK_MEM_FETCH_UNMAPPED,
                  UC_HOOK_MEM_READ_PROT, UC_HOOK_MEM_WRITE_PROT, UC_HOOK_MEM_FETCH_PROT,
                  UC_HOOK_MEM_UNMAPPED, UC_HOOK_MEM_PROT, UC_HOOK_MEM_INVALID]:
      uc.removeHook uc.onMemFault(kinds, fault)

  test "mem fault: a hook that maps the page lets the emulation go on":
    let uc = newX64(mapData = false)
    var faults: seq[string]
    discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      faults.add $kind & "@" & hex(address) & "/" & $size & "=" & $value
      uc.memMap(address and not 0xfff'u64, 0x1000)
      true
    uc.start(base, stop)
    check faults == @["UC_MEM_WRITE_UNMAPPED@3000/8=4660"]
    check uc.regRead(UC_X86_REG_RBX) == 0x1234

  test "mem fault: a hook that returns false lets the emulation fail":
    let uc = newX64(mapData = false)
    var faults = 0
    discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      inc faults
      false
    expectCode(UC_ERR_WRITE_UNMAPPED): uc.start(base, stop)
    check faults == 1
    check uc.regRead(UC_X86_REG_RBX) == 0

  test "mem fault: protection faults, and fetching from nowhere":
    let uc = newX64()
    uc.memProtect(data, 0x1000, UC_PROT_READ)
    var faults: seq[string]
    discard uc.onMemFault(UC_HOOK_MEM_PROT or UC_HOOK_MEM_FETCH_UNMAPPED) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      faults.add $kind & "@" & hex(address)
      if kind == UC_MEM_WRITE_PROT:
        uc.memProtect(data, 0x1000, UC_PROT_READ or UC_PROT_WRITE)
        return true
    uc.start(base, stop)
    check faults == @["UC_MEM_WRITE_PROT@3000"]
    check uc.pc == stop                            # the emulation went on
    expectCode(UC_ERR_FETCH_UNMAPPED): uc.start(0x7000, 0x7010)
    check faults == @["UC_MEM_WRITE_PROT@3000", "UC_MEM_FETCH_UNMAPPED@7000"]

  test "interrupt: the number, and the emulation goes on":
    let uc = newX64([0xCD'u8, 0x80, 0x48, 0xFF, 0xC1, 0xCD, 0x03])   # int 0x80; inc rcx; int 3
    var numbers: seq[uint32]
    discard uc.onInterrupt do (uc: Unicorn; number: uint32):
      numbers.add number
    uc.start(base, base + 7)
    check numbers == @[0x80'u32, 3]
    check uc.regRead(UC_X86_REG_RCX) == 1

  test "syscall: the hook stands in for the kernel":
    let uc = newX64([0x0F'u8, 0x05, 0x48, 0xFF, 0xC1])   # syscall; inc rcx
    var calls: seq[uint64]
    discard uc.onSyscall do (uc: Unicorn):
      calls.add uc.regRead(UC_X86_REG_RAX)
      uc.regWrite(UC_X86_REG_RAX, 99)
    uc.regWrite(UC_X86_REG_RAX, 60)
    uc.start(base, base + 5)
    check calls == @[60'u64]
    check uc.regRead(UC_X86_REG_RAX) == 99
    check uc.regRead(UC_X86_REG_RCX) == 1

  test "sysenter":
    let uc = initUnicorn(UC_ARCH_X86, UC_MODE_32)
    uc.memMap(base, 0x1000)
    uc.memWrite(base, [0x0F'u8, 0x34, 0x41])       # sysenter; inc ecx
    var calls = 0
    discard uc.onSysenter do (uc: Unicorn):
      inc calls
      check uc.pc == base
    uc.start(base, base + 3)
    check calls == 1
    check uc.regRead(UC_X86_REG_ECX) == 1

  test "port in: the hook says what the port delivers":
    let uc = newX64([0xE4'u8, 0x60, 0x66, 0xED, 0xED])   # in al, 0x60; in ax, dx; in eax, dx
    var reads: seq[string]
    discard uc.onPortIn do (uc: Unicorn; port: uint32; size: int) -> uint32:
      reads.add $port & "/" & $size
      0xA1B2C3D4'u32
    uc.regWrite(UC_X86_REG_RDX, 0x3f8)
    uc.start(base, base + 2)
    check uc.regRead(UC_X86_REG_RAX) == 0xD4
    uc.start(base + 2, base + 4)
    check uc.regRead(UC_X86_REG_RAX) == 0xC3D4
    uc.start(base + 4, base + 5)
    check uc.regRead(UC_X86_REG_RAX) == 0xA1B2C3D4'u64
    check reads == @["96/1", "1016/2", "1016/4"]

  test "port out: port, size and value":
    let uc = newX64([0xE6'u8, 0x70, 0x66, 0xEF, 0xEF])   # out 0x70, al; out dx, ax; out dx, eax
    var writes: seq[string]
    discard uc.onPortOut do (uc: Unicorn; port: uint32; size: int; value: uint32):
      writes.add $port & "/" & $size & "=" & toHex(value)
    uc.regWrite(UC_X86_REG_RAX, 0x11223344)
    uc.regWrite(UC_X86_REG_RDX, 0x3f8)
    uc.start(base, base + 5)
    check writes == @["112/1=00000044", "1016/2=00003344", "1016/4=11223344"]

  test "cpuid: the hook answers itself, or lets Unicorn":
    let uc = newX64([0x0F'u8, 0xA2])
    var answer = true
    discard uc.onCpuid do (uc: Unicorn) -> bool:
      uc.regWrite(UC_X86_REG_RBX, 0x1234)
      answer
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 2)
    check uc.regRead(UC_X86_REG_RBX) == 0x1234     # the instruction was skipped
    check uc.pc == base + 2
    answer = false
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 2)
    check uc.regRead(UC_X86_REG_RBX) != 0x1234     # Unicorn put the vendor string there
    check uc.regRead(UC_X86_REG_RAX) > 0

  test "invalid instruction: the hook can step over it":
    let uc = newX64([0x90'u8, 0x0F, 0x0B, 0x48, 0xFF, 0xC1, 0x90])   # nop; ud2; inc rcx; nop
    var calls = 0
    discard uc.onInvalidInsn do (uc: Unicorn) -> bool:
      inc calls
      check uc.pc == base + 1
      uc.pc = base + 3
      true
    let version = (library.major, library.minor, library.patch)
    if version >= (2, 1, 2):
      uc.start(base, base + 7)
      check uc.pc == base + 7
    else:
      # older versions do not go on by themselves: the run ends, without an
      # error in Unicorn 2.0 and with one in 2.1.0 and 2.1.1
      if version >= (2, 1, 0):
        expectCode(UC_ERR_EXCEPTION): uc.start(base, base + 7)
      else:
        uc.start(base, base + 7)
      check uc.pc == base + 3
      uc.start(uc.pc, base + 7)
    check calls == 1
    check uc.regRead(UC_X86_REG_RCX) == 1

  test "invalid instruction: a hook that returns false lets the emulation fail":
    let uc = newX64([0x90'u8, 0x0F, 0x0B])
    var calls = 0
    discard uc.onInvalidInsn do (uc: Unicorn) -> bool:
      inc calls
      false
    expectCode(UC_ERR_INSN_INVALID): uc.start(base, base + 3)
    check calls == 1

  test "edge generated: a block is translated and entered from another":
    let uc = newX64([0x90'u8, 0xEB, 0x00, 0x90, 0xEB, 0x00, 0x90])   # nop; jmp; nop; jmp; nop
    var edges: seq[string]
    discard uc.onEdgeGenerated do (uc: Unicorn; current, previous: uc_tb):
      edges.add hex(previous.pc) & "->" & hex(current.pc) & ", " & $current.size & " bytes"
    uc.start(base, base + 7)
    check edges == @["1000->1003, 3 bytes", "1003->1006, 1 bytes"]

  test "tcg opcode: the operands of subtractions and comparisons":
    # sub rax, rbx; cmp rax, rcx; sub eax, 1
    const subs = [0x48'u8, 0x29, 0xD8, 0x48, 0x39, 0xC8, 0x83, 0xE8, 0x01]
    proc run(flags: set[uc_tcg_op_flag]): seq[string] =
      let uc = newX64(subs)
      var ops: seq[string]
      discard uc.onTcgOpcode(UC_TCG_OP_SUB, flags) do (
          uc: Unicorn; address, arg1, arg2: uint64; size: int):
        ops.add hex(address) & ": " & $arg1 & ", " & $arg2
        doAssert size in [32, 64]                  # a 32-bit host computes in halves
      uc.regWrite(UC_X86_REG_RAX, 100)
      uc.regWrite(UC_X86_REG_RBX, 30)
      uc.regWrite(UC_X86_REG_RCX, 7)
      uc.start(base, base + uint64(subs.len))
      check uc.regRead(UC_X86_REG_RAX) == 69
      ops
    check run({}) == @["1000: 100, 30", "1003: 70, 7", "1006: 70, 1"]
    check run({UC_TCG_OP_FLAG_CMP}) == @["1003: 70, 7"]
    check run({UC_TCG_OP_FLAG_DIRECT}).len == 2    # the two `sub`
    let uc = newX64(subs)
    expectCode(UC_ERR_HOOK):
      discard uc.onTcgOpcode(UC_TCG_OP_SUB, {UC_TCG_OP_FLAG_CMP, UC_TCG_OP_FLAG_DIRECT},
        proc (uc: Unicorn; address, arg1, arg2: uint64; size: int) = discard)

  test "tlb fill: the hook translates virtual addresses":
    when libVersion >= (2, 1, 0):
      # mov rax, [0x4008]; the page at 0x4000 does not exist, the hook points it at `data`
      let uc = newX64([0x48'u8, 0x8B, 0x04, 0x25, 0x08, 0x40, 0x00, 0x00, 0x90])
      uc.memMap(data, 0x1000)
      uc.memWrite(data + 8, [0x11'u8, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88])
      uc.tlbMode = UC_TLB_VIRTUAL
      var lookups: seq[string]
      discard uc.onTlbFill do (uc: Unicorn; address: uint64; kind: uc_mem_type;
                               entry: var uc_tlb_entry) -> bool:
        lookups.add hex(address) & " " & $kind
        entry.paddr = (if address == 0x4000: data else: address)
        entry.perms = UC_PROT_ALL
        true
      uc.start(base, base + 9)
      check lookups == @["1000 UC_MEM_FETCH", "4000 UC_MEM_READ"]
      check uc.regRead(UC_X86_REG_RAX) == 0x8877665544332211'u64
      uc.start(base, base + 9)
      check lookups.len == 2                       # the answers are cached
      uc.flushTlb()
      uc.start(base, base + 9)
      check lookups.len == 4
    else:
      skip()

  test "tlb fill: a hook that knows no translation makes the access fault":
    when libVersion >= (2, 1, 0):
      let uc = newX64()
      uc.tlbMode = UC_TLB_VIRTUAL
      discard uc.onTlbFill do (uc: Unicorn; address: uint64; kind: uc_mem_type;
                               entry: var uc_tlb_entry) -> bool:
        if address == data: return false
        entry.paddr = address
        entry.perms = UC_PROT_ALL
        true
      expectCode(UC_ERR_EXCEPTION): uc.start(base, stop)   # a page fault nobody handles
      check uc.regRead(UC_X86_REG_RAX) == 0x1234
      check uc.regRead(UC_X86_REG_RBX) == 0
    else:
      skip()

  test "ARM64 system instructions: MRS and MSR, skipped or not":
    if not uc_arch_supported(UC_ARCH_ARM64):
      skip()
    else:
      let uc = initUnicorn(UC_ARCH_ARM64, UC_MODE_ARM)
      uc.memMap(0x10000, 0x1000)
      uc.memWrite(0x10000, [0x42'u8, 0xd0, 0x3b, 0xd5,     # mrs x2, tpidr_el0
                            0x43, 0xd0, 0x1b, 0xd5,        # msr tpidr_el0, x3
                            0x1f, 0x20, 0x03, 0xd5])       # nop
      var seen: seq[string]
      proc describe(reg: uc_arm64_reg; cp: uc_arm64_cp_reg): string =
        $reg & " S" & $cp.op0 & "_" & $cp.op1 & "_C" & $cp.crn & "_C" & $cp.crm & "_" & $cp.op2 &
          " val=" & $cp.val
      discard uc.onSys(UC_ARM64_INS_MRS) do (uc: Unicorn; reg: uc_arm64_reg;
                                             cpReg: uc_arm64_cp_reg) -> bool:
        seen.add "mrs " & describe(reg, cpReg)
        uc.regWrite(reg, 0x1337)                   # the hook supplies the value
        true
      discard uc.onSys(UC_ARM64_INS_MSR) do (uc: Unicorn; reg: uc_arm64_reg;
                                             cpReg: uc_arm64_cp_reg) -> bool:
        seen.add "msr " & describe(reg, cpReg)
        false                                      # Unicorn carries it out
      uc.regWrite(UC_ARM64_REG_X3, 0x77)
      uc.start(0x10000, 0x1000c)
      check seen == @["mrs UC_ARM64_REG_X2 S3_3_C13_C0_2 val=0",
                      "msr UC_ARM64_REG_X3 S3_3_C13_C0_2 val=119"]
      check uc.regRead(UC_ARM64_REG_X2) == 0x1337
      check uc.regRead(UC_ARM64_REG_TPIDR_EL0) == 0x77
      check uc.pc == 0x1000c

  test "a hook for an instruction of another architecture is refused":
    let uc = newX64()
    expectCode(UC_ERR_HOOK):
      discard uc.onSys(UC_ARM64_INS_MRS,
        proc (uc: Unicorn; reg: uc_arm64_reg; cpReg: uc_arm64_cp_reg): bool = false)
    if uc_arch_supported(UC_ARCH_ARM64):
      let arm64 = initUnicorn(UC_ARCH_ARM64, UC_MODE_ARM)
      expectCode(UC_ERR_HOOK): discard arm64.onSyscall(proc (uc: Unicorn) = discard)
      expectCode(UC_ERR_HOOK): discard arm64.onSysenter(proc (uc: Unicorn) = discard)
      expectCode(UC_ERR_HOOK): discard arm64.onCpuid(proc (uc: Unicorn): bool = false)
      expectCode(UC_ERR_HOOK):
        discard arm64.onPortIn(proc (uc: Unicorn; port: uint32; size: int): uint32 = 0)
      expectCode(UC_ERR_HOOK):
        discard arm64.onPortOut(proc (uc: Unicorn; port: uint32; size: int;
                                      value: uint32) = discard)

  test "a nil callback is refused":
    let uc = newX64()
    var none: CodeCallback
    expectCode(UC_ERR_ARG): discard uc.onCode(none)
    uc.start(base, stop)

  test "a hook can set the program counter to change where the emulation goes on":
    # inc rax; inc rbx; inc rcx; inc rdx; nop
    const incs = [0x48'u8, 0xFF, 0xC0, 0x48, 0xFF, 0xC3, 0x48, 0xFF, 0xC1, 0x48, 0xFF, 0xC2,
                  0x90]
    proc run(jump: proc (uc: Unicorn; address: uint64)): seq[uint64] =
      let uc = newX64(incs)
      var seen: seq[uint64]
      discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
        seen.add address
        if address == base + 3: jump(uc, base + 9)    # over `inc rbx; inc rcx`
      uc.start(base, base + 13, count = 50)
      check uc.regReadBatch([UC_X86_REG_RAX, UC_X86_REG_RBX, UC_X86_REG_RCX, UC_X86_REG_RDX]) ==
        @[1'u64, 0, 0, 1]
      check uc.pc == base + 13
      seen
    let expected = @[base, base + 3, base + 9, base + 12]
    check run(proc (uc: Unicorn; address: uint64) = uc.pc = address) == expected
    check run(proc (uc: Unicorn; address: uint64) =
      uc.regWrite(UC_X86_REG_RIP, address)) == expected
    check run(proc (uc: Unicorn; address: uint64) =
      uc.regWrite(cint(ord(UC_X86_REG_RIP)), address)) == expected
    check run(proc (uc: Unicorn; address: uint64) =
      uc.regWriteBatch([UC_X86_REG_RSI, UC_X86_REG_RIP], [5'u64, address])) == expected

  test "several hooks of one kind all run, in the order they were added":
    let uc = newX64(nops)
    var order: seq[int]
    for i in 1 .. 3:
      closureScope:
        let n = i
        discard uc.onCode(proc (uc: Unicorn; address: uint64; size: int) = order.add n)
    uc.start(base, base + 2)
    check order == @[1, 2, 3, 1, 2, 3]

suite "ranges":
  test "code and block hooks are limited to their range":
    let uc = newX64()
    var seen: seq[uint64]
    discard uc.onCode(base + 7 .. base + 15) do (uc: Unicorn; address: uint64; size: int):
      seen.add address
    discard uc.onBlock(base + 1 .. stop) do (uc: Unicorn; address: uint64; size: int):
      seen.add 0                                   # the block starts at `base`: never
    uc.start(base, stop)
    check seen == @[base + 7, base + 15]

  test "a range is inclusive, and a single address is a range":
    let uc = newX64()
    var seen: seq[uint64]
    discard uc.onCode(base + 23 .. base + 23) do (uc: Unicorn; address: uint64; size: int):
      seen.add address
    uc.start(base, stop)
    check seen == @[base + 23]

  test "memory hooks are limited by the address accessed":
    let uc = newX64()
    var hits = 0
    var misses = 0
    discard uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE, data .. data + 7) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      inc hits
    discard uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE, data + 8 .. data + 0xfff) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      inc misses
    uc.start(base, stop)
    check hits == 2
    check misses == 0

  test "memory fault hooks are limited by the address accessed":
    let uc = newX64(mapData = false)
    var elsewhere = 0
    discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED, 0x8000'u64 .. 0x8fff'u64) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      inc elsewhere
      true
    expectCode(UC_ERR_WRITE_UNMAPPED): uc.start(base, stop)
    check elsewhere == 0
    discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED, data .. data + 0xfff) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      uc.memMap(data, 0x1000)
      true
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RBX) == 0x1234

  test "syscall and cpuid hooks are limited by the address of the instruction":
    let uc = newX64([0x0F'u8, 0x05, 0x0F, 0x05, 0x0F, 0xA2, 0x0F, 0xA2])   # 2 syscall, 2 cpuid
    var syscalls: seq[uint64]
    var cpuids: seq[uint64]
    discard uc.onSyscall(base + 2 .. base + 3) do (uc: Unicorn):
      syscalls.add uc.pc
    discard uc.onCpuid(base + 4 .. base + 5) do (uc: Unicorn) -> bool:
      cpuids.add uc.pc
      true
    uc.start(base, base + 8)
    check syscalls == @[base + 2]
    check cpuids == @[base + 4]

  test "sysenter hooks are limited by the address of the instruction":
    let uc = initUnicorn(UC_ARCH_X86, UC_MODE_32)
    uc.memMap(base, 0x1000)
    uc.memWrite(base, [0x0F'u8, 0x34, 0x0F, 0x34])
    var calls: seq[uint64]
    discard uc.onSysenter(base + 2 .. base + 3) do (uc: Unicorn):
      calls.add uc.pc
    uc.start(base, base + 4)
    check calls == @[base + 2]

  test "edge and tcg opcode hooks are limited by the address of the code":
    # sub rax, rbx; jmp; sub rax, rbx; jmp; sub rax, rbx
    let uc = newX64([0x48'u8, 0x29, 0xD8, 0xEB, 0x00, 0x48, 0x29, 0xD8, 0xEB, 0x00,
                     0x48, 0x29, 0xD8])
    var edges: seq[uint64]
    var subs: seq[uint64]
    discard uc.onEdgeGenerated(base + 10 .. base + 12) do (uc: Unicorn; current, previous: uc_tb):
      edges.add current.pc
    discard uc.onTcgOpcode(UC_TCG_OP_SUB, {}, base + 5 .. base + 9) do (
        uc: Unicorn; address, arg1, arg2: uint64; size: int):
      subs.add address
    uc.start(base, base + 13)
    check edges == @[base + 10]
    check subs == @[base + 5]

  test "tlb fill hooks are limited by the virtual address":
    when libVersion >= (2, 1, 0):
      let uc = newX64()
      uc.tlbMode = UC_TLB_VIRTUAL
      var lookups: seq[uint64]
      discard uc.onTlbFill(data .. data + 0xfff) do (
          uc: Unicorn; address: uint64; kind: uc_mem_type; entry: var uc_tlb_entry) -> bool:
        lookups.add address
        entry.paddr = address
        entry.perms = UC_PROT_ALL
        true
      uc.start(base, stop)                         # the code page is mapped one to one
      check lookups == @[data]
      check uc.regRead(UC_X86_REG_RBX) == 0x1234
    else:
      skip()

  test "ARM64 system instruction hooks are limited by the address of the instruction":
    if not uc_arch_supported(UC_ARCH_ARM64):
      skip()
    else:
      let uc = initUnicorn(UC_ARCH_ARM64, UC_MODE_ARM)
      uc.memMap(0x10000, 0x1000)
      # mrs x2, tpidr_el0; mrs x2, tpidr_el0
      uc.memWrite(0x10000, [0x42'u8, 0xd0, 0x3b, 0xd5, 0x42, 0xd0, 0x3b, 0xd5])
      var seen: seq[uint64]
      discard uc.onSys(UC_ARM64_INS_MRS, 0x10004'u64 .. 0x10007'u64) do (
          uc: Unicorn; reg: uc_arm64_reg; cpReg: uc_arm64_cp_reg) -> bool:
        seen.add uc.pc
        false
      uc.start(0x10000, 0x10008)
      check seen == @[0x10004'u64]

  test "an empty range is refused instead of meaning everywhere":
    let uc = newX64()
    let nothing = base + 0x100 .. base + 0xff      # as `first .. first + len - 1` with len 0
    let code = proc (uc: Unicorn; address: uint64; size: int) = discard
    expectCode(UC_ERR_ARG): discard uc.onCode(nothing, code)
    expectCode(UC_ERR_ARG): discard uc.onBlock(nothing, code)
    expectCode(UC_ERR_ARG):
      discard uc.onMem(UC_HOOK_MEM_READ, nothing, proc (uc: Unicorn; kind: uc_mem_type;
        address: uint64; size: int; value: int64) = discard)
    expectCode(UC_ERR_ARG):
      discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED, nothing, proc (uc: Unicorn; kind: uc_mem_type;
        address: uint64; size: int; value: int64): bool = false)
    expectCode(UC_ERR_ARG): discard uc.onSyscall(nothing, proc (uc: Unicorn) = discard)
    expectCode(UC_ERR_ARG): discard uc.onSysenter(nothing, proc (uc: Unicorn) = discard)
    expectCode(UC_ERR_ARG): discard uc.onCpuid(nothing, proc (uc: Unicorn): bool = false)
    expectCode(UC_ERR_ARG):
      discard uc.onEdgeGenerated(nothing, proc (uc: Unicorn; current, previous: uc_tb) = discard)
    expectCode(UC_ERR_ARG):
      discard uc.onTcgOpcode(UC_TCG_OP_SUB, {}, nothing,
        proc (uc: Unicorn; address, arg1, arg2: uint64; size: int) = discard)
    when libVersion >= (2, 1, 0):
      expectCode(UC_ERR_ARG):
        discard uc.onTlbFill(nothing, proc (uc: Unicorn; address: uint64; kind: uc_mem_type;
          entry: var uc_tlb_entry): bool = false)
    var steps = 0
    discard uc.onCode(base .. base, proc (uc: Unicorn; address: uint64; size: int) = inc steps)
    uc.start(base, stop)
    check steps == 1                               # none of the refused ones was added

suite "hooks and translated code":
  # sub rax, rbx; inc rcx; jmp +0; sub rax, rbx; nop; nop: the first block
  # does not end where the run ends, so its translation is kept
  const
    subs = [0x48'u8, 0x29, 0xD8, 0x48, 0xFF, 0xC1, 0xEB, 0x00, 0x48, 0x29, 0xD8, 0x90, 0x90]
    subsEnd = base + uint64(subs.len)

  test "a hook added after the code has run is called for that code":
    # Unicorn compiles these hooks into its translations and keeps the old ones
    let uc = newX64(subs)
    uc.start(base, subsEnd)
    var code, blocks, ops = 0
    discard uc.onCode(proc (uc: Unicorn; address: uint64; size: int) = inc code)
    discard uc.onBlock(proc (uc: Unicorn; address: uint64; size: int) = inc blocks)
    discard uc.onTcgOpcode(UC_TCG_OP_SUB, {}, proc (uc: Unicorn; address, arg1, arg2: uint64;
                                                    size: int) = inc ops)
    uc.start(base, subsEnd)
    check (code, blocks, ops) == (6, 2, 2)

  test "a hook added inside a hook is called for all code from the next start on":
    let uc = newX64(subs)
    var late = 0
    var added = false
    discard uc.onBlock do (uc: Unicorn; address: uint64; size: int):
      if not added:
        added = true
        discard uc.onCode(proc (uc: Unicorn; address: uint64; size: int) = inc late)
    uc.start(base, subsEnd)
    late = 0
    uc.start(base, subsEnd)
    check late == 6

  test "removing a TCG opcode hook discards the code that calls it":
    # Unicorn leaves the address of its record of the hook in the translated
    # code and frees the record: the code has to go.
    let uc = newX64(subs)
    var translations = 0                           # of the first block
    discard uc.onEdgeGenerated(base .. base) do (uc: Unicorn; current, previous: uc_tb):
      inc translations
    var ops = 0
    let id = uc.onTcgOpcode(UC_TCG_OP_SUB, {}, proc (uc: Unicorn; address, arg1, arg2: uint64;
                                                     size: int) = inc ops)
    uc.start(base, subsEnd)
    uc.start(base, subsEnd)
    check ops == 4
    let before = translations                      # the block is kept from run to run
    uc.start(base, subsEnd)
    check translations == before
    uc.removeHook(id)
    uc.start(base, subsEnd)
    check translations == before + 1               # it was translated anew, without the hook
    check ops == 6
    uc.start(base, subsEnd)
    check ops == 6

  test "the code that calls a removed TCG opcode hook is gone before the C API can run it":
    let uc = newX64(subs)
    var translations = 0                           # of the first block
    discard uc.onEdgeGenerated(base .. base) do (uc: Unicorn; current, previous: uc_tb):
      inc translations
    var ops = 0
    let id = uc.onTcgOpcode(UC_TCG_OP_SUB, {}, proc (uc: Unicorn; address, arg1, arg2: uint64;
                                                     size: int) = inc ops)
    uc.start(base, subsEnd)
    uc.start(base, subsEnd)
    let before = translations
    uc.removeHook(id)
    check uc_emu_start(uc.handle, base, subsEnd, 0, 0) == UC_ERR_OK
    check translations == before + 1
    check ops == 4

  test "removing an ARM64 system instruction hook discards the code that calls it":
    if not uc_arch_supported(UC_ARCH_ARM64):
      skip()
    else:
      let uc = initUnicorn(UC_ARCH_ARM64, UC_MODE_ARM)
      uc.memMap(0x10000, 0x1000)
      uc.memWrite(0x10000, [0x42'u8, 0xd0, 0x3b, 0xd5,     # mrs x2, tpidr_el0
                            0x01, 0x00, 0x00, 0x14,        # b +4
                            0x1f, 0x20, 0x03, 0xd5,        # nop
                            0x1f, 0x20, 0x03, 0xd5])       # nop
      var translations = 0
      discard uc.onEdgeGenerated(0x10000'u64 .. 0x10000'u64) do (
          uc: Unicorn; current, previous: uc_tb):
        inc translations
      var calls = 0
      let id = uc.onSys(UC_ARM64_INS_MRS) do (uc: Unicorn; reg: uc_arm64_reg;
                                              cpReg: uc_arm64_cp_reg) -> bool:
        inc calls
        false
      uc.start(0x10000, 0x10010)
      uc.start(0x10000, 0x10010)
      check calls == 2
      let before = translations
      uc.removeHook(id)
      uc.start(0x10000, 0x10010)
      check translations == before + 1
      check calls == 2

  test "flushTb is refused inside a hook, removeCache works there":
    # Unicorn hangs or crashes when all translations go while one of them runs
    # a loop: inc rax; inc rbx; jmp +0; inc rcx; cmp rax, 50; jne start; nop
    let uc = newX64([0x48'u8, 0xFF, 0xC0, 0x48, 0xFF, 0xC3, 0xEB, 0x00,
                     0x48, 0xFF, 0xC1, 0x48, 0x83, 0xF8, 0x32, 0x75, 0xEF, 0x90])
    var calls, refused = 0
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
      if address == base + 3 and calls mod 7 == 2:
        try:
          uc.flushTb()
        except UnicornError as e:
          if e.code == UC_ERR_ARG: inc refused
        uc.removeCache(base .. base + 0x11)
    uc.start(base, base + 0x12, timeout = 20_000_000)
    check not uc.timedOut
    check uc.regRead(UC_X86_REG_RAX) == 50
    check uc.regRead(UC_X86_REG_RCX) == 50
    check refused > 0
    uc.flushTb()                                   # outside a hook it is fine

suite "removing hooks":
  test "a removed hook is not called again":
    let uc = newX64()
    var calls = 0
    let id = uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
    uc.start(base, stop)
    check calls == 5
    uc.removeHook(id)
    uc.start(base, stop)
    check calls == 5

  test "a hook can remove itself while it runs":
    let uc = newX64()
    var id: HookId
    var calls = 0
    id = uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
      uc.removeHook(id)
      check uc.regRead(UC_X86_REG_RCX) == 0        # its closure is still intact
    uc.start(base, stop)
    check calls == 1
    check uc.regRead(UC_X86_REG_RCX) == 1          # the emulation went on without it
    uc.start(base, stop)
    check calls == 1

  test "a hook can remove another hook, and add one":
    let uc = newX64()
    var first, second, third: seq[uint64]
    var secondId: HookId
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      first.add address
      if address == insns[1]:
        uc.removeHook(secondId)
        discard uc.onCode(insns[3] .. insns[4]) do (uc: Unicorn; address: uint64; size: int):
          third.add address
    secondId = uc.onCode do (uc: Unicorn; address: uint64; size: int):
      second.add address
    uc.start(base, stop)
    check first == @insns
    check second == @[insns[0]]
    check third == @[insns[3], insns[4]]

  test "removing twice, or a hook of another engine, raises":
    let uc = newX64()
    let other = newX64()
    let id = uc.onCode(proc (uc: Unicorn; address: uint64; size: int) = discard)
    let otherId = other.onBlock(proc (uc: Unicorn; address: uint64; size: int) = discard)
    check not (id == otherId)
    expectCode(UC_ERR_HOOK): uc.removeHook(otherId)
    uc.removeHook(id)
    expectCode(UC_ERR_HOOK): uc.removeHook(id)
    other.removeHook(otherId)
    uc.start(base, stop)
    other.start(base, stop)

  test "every kind of hook can be removed":
    let uc = newX64()
    var calls = 0
    var ids: seq[HookId]
    ids.add uc.onCode(proc (uc: Unicorn; address: uint64; size: int) = inc calls)
    ids.add uc.onBlock(proc (uc: Unicorn; address: uint64; size: int) = inc calls)
    ids.add uc.onMem(UC_HOOK_MEM_VALID, proc (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                               size: int; value: int64) = inc calls)
    ids.add uc.onMemFault(UC_HOOK_MEM_INVALID, proc (uc: Unicorn; kind: uc_mem_type;
                                                    address: uint64; size: int;
                                                    value: int64): bool = (inc calls))
    ids.add uc.onInterrupt(proc (uc: Unicorn; number: uint32) = inc calls)
    ids.add uc.onInvalidInsn(proc (uc: Unicorn): bool = (inc calls))
    ids.add uc.onSyscall(proc (uc: Unicorn) = inc calls)
    ids.add uc.onSysenter(proc (uc: Unicorn) = inc calls)
    ids.add uc.onPortIn(proc (uc: Unicorn; port: uint32; size: int): uint32 = (inc calls))
    ids.add uc.onPortOut(proc (uc: Unicorn; port: uint32; size: int; value: uint32) = inc calls)
    ids.add uc.onCpuid(proc (uc: Unicorn): bool = (inc calls))
    ids.add uc.onEdgeGenerated(proc (uc: Unicorn; current, previous: uc_tb) = inc calls)
    ids.add uc.onTcgOpcode(UC_TCG_OP_SUB, {}, proc (uc: Unicorn; address, arg1, arg2: uint64;
                                                    size: int) = inc calls)
    when libVersion >= (2, 1, 0):
      ids.add uc.onTlbFill(proc (uc: Unicorn; address: uint64; kind: uc_mem_type;
                                 entry: var uc_tlb_entry): bool = (inc calls))
    for id in ids: uc.removeHook(id)
    uc.start(base, stop)
    check calls == 0
    check uc.regRead(UC_X86_REG_RBX) == 0x1234

suite "exceptions in hooks":
  test "an exception stops the emulation and comes out of start":
    let uc = newX64()
    var calls = 0
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
      if address == insns[1]: raise newException(ValueError, "stop at " & hex(address))
    try:
      uc.start(base, stop)
      fail()
    except ValueError as e:
      check e.msg == "stop at 1007"
    check calls == 2                               # nothing ran after the raise
    check uc.regRead(UC_X86_REG_RAX) == 0x1234     # the first instruction did
    check uc.regRead(UC_X86_REG_RBX) == 0          # the third did not

  test "the engine stays usable, and the exception is raised once":
    let uc = newX64()
    var fail = true
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      if fail and address == insns[2]: raise newException(IOError, "no")
    expect IOError: uc.start(base, stop)
    fail = false
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RCX) == 1
    uc.start(base, stop)
    check uc.regRead(UC_X86_REG_RCX) == 2

  test "it is the same exception object, with its fields":
    let uc = newX64()
    let error = (ref DeviceError)(msg: "device", offset: 42)
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      raise error
    try:
      uc.start(base, stop)
      fail()
    except DeviceError as e:
      check e.offset == 42
      check cast[pointer](e) == cast[pointer](error)

  test "a defect comes out of start too":
    let uc = newX64()
    var calls = 0
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
      raise newException(AssertionDefect, "broken")
    try:
      uc.start(base, stop)
      fail()
    except AssertionDefect as e:
      check e.msg == "broken"
    check calls == 1

  test "an index error in a hook comes out of start":
    when compileOption("boundChecks"):
      let uc = newX64()
      var values = @[1, 2, 3]
      var index = 5
      discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
        values[index] = 0
      expect IndexDefect: uc.start(base, stop)
      index = 1
      uc.start(base, stop)
      check values == @[1, 0, 3]
    else:
      skip()

  test "hooks that return a value: the exception wins over the value":
    let uc = newX64(mapData = false)
    discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
      raise newException(KeyError, "no page at " & hex(address))
    try:
      uc.start(base, stop)                         # not UC_ERR_WRITE_UNMAPPED
      fail()
    except KeyError as e:
      check e.msg == "no page at 3000"
    let ports = newX64([0xE4'u8, 0x60, 0x48, 0xFF, 0xC1])   # in al, 0x60; inc rcx
    discard ports.onPortIn do (uc: Unicorn; port: uint32; size: int) -> uint32:
      raise newException(IOError, "port " & $port)
    expect IOError: ports.start(base, base + 5)
    check ports.regRead(UC_X86_REG_RAX) == 0       # nothing arrived from the port

  test "a hook that raises while the C API runs the emulation: the next start raises it":
    let uc = newX64()
    var failing = true
    var calls = 0
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      inc calls
      if failing: raise newException(ValueError, "during uc_emu_start")
    check uc_emu_start(uc.handle, base, stop, 0, 0) == UC_ERR_OK
    check calls == 1                               # the emulation was stopped
    failing = false
    try:
      uc.start(base, stop)
      fail()
    except ValueError as e:
      check e.msg == "during uc_emu_start"
    check calls == 1                               # and this one did not begin
    uc.start(base, stop)
    check calls == 6

  test "an exception stays with the run it stops, whatever later hooks do":
    # After `out` has raised, Unicorn finishes the block and still reports
    # the memory access in it.
    # out 0x70, al; mov [0x3000], rax; nop
    let uc = newX64([0xE6'u8, 0x70, 0x48, 0x89, 0x04, 0x25, 0x00, 0x30, 0x00, 0x00, 0x90])
    uc.memMap(data, 0x1000)
    var seen: seq[string]
    discard uc.onPortOut do (uc: Unicorn; port: uint32; size: int; value: uint32):
      raise newException(IOError, "out failed")
    discard uc.onMem(UC_HOOK_MEM_WRITE) do (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                            size: int; value: int64):
      try:
        discard uc.memRead(data, 1)                # the engine is no longer to be used
        seen.add "read"
      except CatchableError as e:
        seen.add "caught " & e.msg
      raise newException(ValueError, "a later one")
    try:
      uc.start(base, base + 11)
      fail()
    except IOError as e:
      check e.msg == "out failed"                  # not swallowed, and not replaced
    except ValueError:
      fail()
    check seen == @["caught out failed"]
    uc.memWrite(data, [1'u8])                      # nothing is left over

  test "of several exceptions the first is kept":
    let uc = newX64()
    var calls: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      calls.add "first"
      raise newException(ValueError, "first")
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      calls.add "second"
      raise newException(KeyError, "second")
    try:
      uc.start(base, stop)
      fail()
    except ValueError as e:
      check e.msg == "first"
    except KeyError:
      fail()
    check calls[0] == "first"

  test "an exception from every kind of hook":
    type Boom = object of CatchableError
    proc boom() = raise newException(Boom, "boom")
    const program = [0x90'u8,                                  # 1000 nop
                     0xCD, 0x80,                               # 1001 int 0x80
                     0x0F, 0x05,                               # 1003 syscall
                     0xE4, 0x60,                               # 1005 in al, 0x60
                     0xE6, 0x70,                               # 1007 out 0x70, al
                     0x0F, 0xA2,                               # 1009 cpuid
                     0x48, 0x29, 0xD8,                         # 100B sub rax, rbx
                     0xEB, 0x00,                               # 100E jmp 0x1010
                     0x0F, 0x0B,                               # 1010 ud2
                     0x48, 0x8B, 0x04, 0x25, 0x00, 0x10, 0x00, 0x00]   # 1012 mov rax, [0x1000]
    template raises(first, last: uint64; hook: untyped) =
      block:
        let uc {.inject.} = newX64(program)
        let id = hook
        expect Boom: uc.start(first, last)
        uc.removeHook(id)
        uc.start(base, base + 1)                   # usable afterwards; nothing is left over
    raises(base, base + 1):
      uc.onBlock(proc (uc: Unicorn; address: uint64; size: int) = boom())
    raises(base + 1, base + 3):
      uc.onInterrupt(proc (uc: Unicorn; number: uint32) = boom())
    raises(base + 3, base + 5):
      uc.onSyscall(proc (uc: Unicorn) = boom())
    raises(base + 5, base + 7):
      uc.onPortIn(proc (uc: Unicorn; port: uint32; size: int): uint32 = boom())
    raises(base + 7, base + 9):
      uc.onPortOut(proc (uc: Unicorn; port: uint32; size: int; value: uint32) = boom())
    raises(base + 9, base + 11):
      uc.onCpuid(proc (uc: Unicorn): bool = boom())
    raises(base + 11, base + 14):
      uc.onTcgOpcode(UC_TCG_OP_SUB, {}, proc (uc: Unicorn; address, arg1, arg2: uint64;
                                              size: int) = boom())
    raises(base + 11, base + 0x12):
      uc.onEdgeGenerated(proc (uc: Unicorn; current, previous: uc_tb) = boom())
    raises(base + 0x10, base + 0x12):
      uc.onInvalidInsn(proc (uc: Unicorn): bool = boom())
    raises(base + 0x12, base + 0x1a):
      uc.onMem(UC_HOOK_MEM_READ, proc (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                       size: int; value: int64) = boom())

suite "callbacks outside start":
  # A 32-bit x86 engine whose descriptor table is in emulated memory:
  # loading a segment register makes Unicorn read the table, through the
  # memory hooks and the closures of `mmioMap`.
  const table = 0x8000'u64

  proc newProtected(mapTable = true): Unicorn =
    result = initUnicorn(UC_ARCH_X86, UC_MODE_32)
    result.memMap(base, 0x1000)
    result.memWrite(base, nops)
    if mapTable:
      result.memMap(table, 0x1000)
      # entry 2: a flat data segment
      result.memWrite(table + 0x10, [0xff'u8, 0xff, 0x00, 0x00, 0x00, 0x93, 0xcf, 0x00])
    result.regWrite(UC_X86_REG_GDTR, uc_x86_mmr(base: table, limit: 0x1f))

  test "a memory hook that runs under regWrite may remove itself":
    let uc = newProtected()
    var id: HookId
    var calls, freedWhileRunning = 0
    released = 0
    id = uc.onMemWitnessed(UC_HOOK_MEM_READ) do (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                                 size: int; value: int64):
      inc calls
      uc.removeHook(id)
      freedWhileRunning += released                # its closure is the one that runs
    uc.regWrite(UC_X86_REG_DS, 0x10)
    check calls == 1
    check freedWhileRunning == 0
    check released == 1                            # let go when the write had returned
    check uc.regRead(UC_X86_REG_DS) == 0x10

  test "such a hook runs once per access, as with the C API":
    let viaC = newProtected()
    var expected = 0
    discard viaC.onMem(UC_HOOK_MEM_READ) do (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                             size: int; value: int64):
      inc expected
    var selector = 0x10'u16
    check uc_reg_write(viaC.handle, UC_X86_REG_DS, addr selector) == UC_ERR_OK
    let uc = newProtected()
    var calls = 0
    discard uc.onMem(UC_HOOK_MEM_READ) do (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                           size: int; value: int64):
      inc calls
    uc.regWrite(UC_X86_REG_DS, 0x10)
    check expected > 0
    check calls == expected

  test "an exception raised under regWrite comes out of regWrite":
    let uc = newProtected()
    var failing = true
    discard uc.onMem(UC_HOOK_MEM_READ) do (uc: Unicorn; kind: uc_mem_type; address: uint64;
                                           size: int; value: int64):
      if failing: raise newException(ValueError, "while reading the descriptor table")
    try:
      uc.regWrite(UC_X86_REG_DS, 0x10)
      fail()
    except ValueError as e:
      check e.msg == "while reading the descriptor table"
    failing = false
    uc.start(base, base + 2)                       # nothing is left over for the next call
    check uc.pc == base + 2

  test "the closures of mmioMap run under regWrite too":
    let uc = newProtected(mapTable = false)
    var reads = 0
    var failing = false
    uc.mmioMap(table, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        inc reads
        if failing: raise (ref DeviceError)(msg: "table", offset: offset)
        if offset == 0x10: 0x0000ffff'u64 elif offset == 0x14: 0x00cf9300'u64 else: 0'u64,
      nil)
    uc.regWrite(UC_X86_REG_DS, 0x10)
    check uc.regRead(UC_X86_REG_DS) == 0x10
    check reads > 0
    failing = true
    expect DeviceError: uc.regWrite(UC_X86_REG_ES, 0x10)
    failing = false
    uc.regWrite(UC_X86_REG_ES, 0x10)
    check uc.regRead(UC_X86_REG_ES) == 0x10

  test "a hook may remove itself while the C API runs the emulation":
    let uc = newX64()
    var id: HookId
    var calls, freedWhileRunning = 0
    released = 0
    id = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      inc calls
      uc.removeHook(id)
      freedWhileRunning += released
    check uc_emu_start(uc.handle, base, stop, 0, 0) == UC_ERR_OK
    check calls == 1                               # Unicorn goes on calling it for the block
    check freedWhileRunning == 0
    check uc.regRead(UC_X86_REG_RCX) == 1          # the next call from here lets go of it
    check released == 1

  test "hooks removed under the C API are kept until the engine is used from here again":
    let uc = newX64()
    var first, second: HookId
    var calls = 0
    released = 0
    first = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      inc calls
      if calls == 2:
        uc.removeHook(second)
        uc.removeHook(first)
    second = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      discard
    check uc_emu_start(uc.handle, base, stop, 0, 0) == UC_ERR_OK
    check calls == 2
    check released == 0                            # nothing says that Unicorn has returned
    uc.start(base, stop)
    check released == 2

  test "an engine that loses its last owner inside a hook under the C API stays open":
    var engines: seq[Unicorn]
    engines.add newX64()
    var steps = 0
    released = 0
    discard engines[0].onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      inc steps
      if steps == 2: engines.setLen(0)             # the seq owned the engine
      discard uc.regRead(UC_X86_REG_RAX)
    check uc_emu_start(engines[0].handle, base, stop, 0, 0) == UC_ERR_OK
    check steps == 5
    check released == 0                            # closing it there would crash Unicorn

  test "an engine that loses its last owner under regWrite is closed when the write returns":
    var engines: seq[Unicorn]
    engines.add newProtected()
    var closedWhileRunning = 0
    released = 0
    discard engines[0].onMemWitnessed(UC_HOOK_MEM_READ) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      engines.setLen(0)
      closedWhileRunning += released
    let writing = addr engines[0]
    writing[].regWrite(UC_X86_REG_DS, 0x10)
    check closedWhileRunning == 0
    check released == 1

  test "an engine that loses its last owner under regWriteBatch is there for all of the batch":
    var calls, closedWhileRunning = 0
    block:                                         # how often one segment load reads the table
      let probe = newProtected()
      discard probe.onMem(UC_HOOK_MEM_READ) do (
          uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
        inc calls
      probe.regWrite(UC_X86_REG_DS, 0x10)
    let perLoad = calls
    check perLoad > 0
    var engines: seq[Unicorn]
    engines.add newProtected()
    calls = 0
    released = 0
    discard engines[0].onMemWitnessed(UC_HOOK_MEM_READ) do (
        uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
      inc calls
      if calls == 1: engines.setLen(0)             # under the first write
      closedWhileRunning += released
    let writing = addr engines[0]
    # the first and the last load a segment register
    writing[].regWriteBatch([UC_X86_REG_DS, UC_X86_REG_EAX, UC_X86_REG_EBX, UC_X86_REG_ES],
                            [0x10'u64, 5, 6, 0x10])
    check calls == 2 * perLoad                     # the hook ran under the last write too
    check closedWhileRunning == 0
    check released == 1

  test "start inside a hook and an instruction count exclude each other":
    # Unicorn counts the instructions of all runs together: the outer run
    # would end in the wrong place, or crash.
    # a loop: inc rax; inc rbx; jmp +0; inc rcx; cmp rax, 50; jne start; nop
    let uc = newX64([0x48'u8, 0xFF, 0xC0, 0x48, 0xFF, 0xC3, 0xEB, 0x00,
                     0x48, 0xFF, 0xC1, 0x48, 0x83, 0xF8, 0x32, 0x75, 0xEF, 0x90])
    uc.memMap(0x2000, 0x1000)
    uc.memWrite(0x2000, [0x48'u8, 0xFF, 0xC7, 0x48, 0xFF, 0xC7, 0x90])   # inc rdi; inc rdi; nop
    var innerCount = 0
    var depth, tried, refused = 0
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      if address == base + 3 and depth == 0:
        inc depth
        inc tried
        try:
          uc.start(0x2000, 0x2007, count = innerCount)
        except UnicornError as e:
          if e.code == UC_ERR_ARG: inc refused
        dec depth
    uc.start(base, base + 0x12, count = 1000)      # the run around the hook has a count
    check tried == 50
    check refused == 50
    check uc.regRead(UC_X86_REG_RAX) == 50         # and ends where it should
    check uc.pc == base + 0x12
    check uc.regRead(UC_X86_REG_RDI) == 0
    innerCount = 5                                 # the run inside has one
    tried = 0
    refused = 0
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 0x12)
    check (tried, refused) == (50, 50)
    check uc.regRead(UC_X86_REG_RAX) == 50
    innerCount = 0                                 # neither has: that is fine
    refused = 0
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 0x12)
    check refused == 0
    check uc.regRead(UC_X86_REG_RAX) == 50
    check uc.regRead(UC_X86_REG_RDI) == 100
    uc.regWrite(UC_X86_REG_RAX, 0)
    uc.start(base, base + 0x12, count = 3)         # a count alone, and the counter went back
    check uc.pc == base + 8

  test "start nests 63 deep and refuses the 64th":
    # Unicorn itself crashes in the 64th
    let uc = newX64(nops)
    var depth, deepest = 0
    var refusal = UC_ERR_OK
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      if address == base + 1 and depth < 70:
        inc depth
        deepest = max(deepest, depth)
        try:
          uc.start(base, base + 4)
        except UnicornError as e:
          if refusal == UC_ERR_OK: refusal = e.code
        dec depth
    uc.start(base, base + 4)
    check deepest == 63
    check refusal == UC_ERR_RESOURCE
    check uc.pc == base + 4
    uc.start(base, base + 4)                       # and again: the count went back
    check deepest == 63

suite "start inside a hook":
  const
    inner = 0x2000'u64
    outerCode = [0x48'u8, 0xFF, 0xC0, 0x48, 0xFF, 0xC0, 0x90, 0x90]   # inc rax; inc rax; nop; nop
    innerCode = [0x48'u8, 0xFF, 0xC3, 0x48, 0xFF, 0xC3, 0x90]         # inc rbx; inc rbx; nop

  proc newNested(): Unicorn =
    result = initUnicorn(UC_ARCH_X86, UC_MODE_64)
    result.memMap(base, 0x2000)
    result.memWrite(base, outerCode)
    result.memWrite(inner, innerCode)

  test "a hook can run other code and the outer run goes on":
    let uc = newNested()
    var depth = 0
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add $depth & ":" & hex(address)
      if address == base + 3 and depth == 0:
        inc depth
        uc.start(inner, inner + 7)
        dec depth
    uc.start(base, base + 8)
    check trace == @["0:1000", "0:1003", "1:2000", "1:2003", "1:2006", "0:1006", "0:1007"]
    check uc.regRead(UC_X86_REG_RAX) == 2
    check uc.regRead(UC_X86_REG_RBX) == 2

  test "stopping the inner run does not stop the outer one":
    let uc = newNested()
    var depth = 0
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add $depth & ":" & hex(address)
      if address == base + 3 and depth == 0:
        inc depth
        uc.start(inner, inner + 7)
        dec depth
      if address == inner + 3: uc.stop()
    uc.start(base, base + 8)
    check trace == @["0:1000", "0:1003", "1:2000", "1:2003", "0:1006", "0:1007"]
    check uc.regRead(UC_X86_REG_RBX) == 1

  test "an exception in the inner run ends both when the hook lets it pass":
    let uc = newNested()
    var depth = 0
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add $depth & ":" & hex(address)
      if address == base + 3 and depth == 0:
        inc depth
        try:
          uc.start(inner, inner + 7)
        finally:
          dec depth
      if address == inner + 3: raise newException(ValueError, "inner")
    try:
      uc.start(base, base + 8)
      fail()
    except ValueError as e:
      check e.msg == "inner"
    check trace == @["0:1000", "0:1003", "1:2000", "1:2003"]
    check uc.regRead(UC_X86_REG_RAX) == 1
    check uc.regRead(UC_X86_REG_RBX) == 1
    check depth == 0

  test "a hook that catches the inner exception lets the outer run go on":
    let uc = newNested()
    var depth = 0
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add $depth & ":" & hex(address)
      if address == base + 3 and depth == 0:
        inc depth
        try:
          uc.start(inner, inner + 7)
        except ValueError as e:
          trace.add "caught " & e.msg
        dec depth
      if address == inner + 3: raise newException(ValueError, "inner")
    uc.start(base, base + 8)
    check trace == @["0:1000", "0:1003", "1:2000", "1:2003", "caught inner", "0:1006", "0:1007"]
    check uc.regRead(UC_X86_REG_RAX) == 2
    check uc.regRead(UC_X86_REG_RBX) == 1

  test "an inner run that fails raises in the hook":
    let uc = newNested()
    var depth = 0
    var failure = UC_ERR_OK
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      if address == base + 3 and depth == 0:
        inc depth
        try:
          uc.start(0x900000, 0x900010)
        except UnicornError as e:
          failure = e.code
        dec depth
    uc.start(base, base + 8)
    check failure == UC_ERR_FETCH_UNMAPPED
    check uc.regRead(UC_X86_REG_RAX) == 2

  test "hooks removed in an inner run are let go when the outermost returns":
    let uc = newNested()
    var id: HookId
    var depth = 0
    var freedWhileRunning = 0
    released = 0
    id = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      if address == base + 3 and depth == 0:
        inc depth
        uc.start(inner, inner + 7)
        dec depth
        freedWhileRunning += released              # this closure is still running
      if address == inner: uc.removeHook(id)
    uc.start(base, base + 8)
    check freedWhileRunning == 0
    check released == 1
    check uc.regRead(UC_X86_REG_RAX) == 2

suite "lifetime of the closures":
  test "the engine keeps its hooks alive and lets go of them when it closes":
    proc run() =
      let uc = newX64()
      var steps = 0
      discard uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
        inc steps
      uc.start(base, stop)
      doAssert steps == 5
      doAssert released == 0
    released = 0
    run()
    check released == 1

  test "removing a hook lets go of its closure at once":
    let uc = newX64()
    released = 0
    let id = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      discard
    uc.start(base, stop)
    check released == 0
    uc.removeHook(id)
    check released == 1
    uc.start(base, stop)

  test "a hook that removes itself is let go when start returns":
    let uc = newX64()
    var id: HookId
    var freedWhileRunning = 0
    released = 0
    id = uc.onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      uc.removeHook(id)
      freedWhileRunning += released                # not while it runs
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      freedWhileRunning += released                # and not while the emulation goes on
    uc.start(base, stop)
    check freedWhileRunning == 0
    check released == 1

  test "a hook that is refused is let go at once":
    proc refused(uc: Unicorn) =
      let witness = Witness(armed: true)
      try:
        discard uc.onMem(UC_HOOK_MEM_UNMAPPED) do (
            uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
          doAssert witness.armed
        doAssert false
      except UnicornError as e:
        doAssert e.code == UC_ERR_HOOK
    let uc = newX64()
    released = 0
    refused(uc)
    check released == 1

  test "every engine lets go of its own hooks":
    var engines: seq[Unicorn]
    released = 0
    for i in 0 .. 2:
      engines.add newX64()
      discard engines[i].onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
        discard
    for uc in engines: uc.start(base, stop)
    check released == 0
    engines.setLen(2)
    check released == 1
    engines.delete(0)
    check released == 2
    engines.setLen(0)
    check released == 3

  test "an engine that loses its owner inside a hook is closed when start returns":
    var engines: seq[Unicorn]
    engines.add newX64()
    var steps = 0
    var closedWhileRunning = 0
    released = 0
    discard engines[0].onCodeWitnessed do (uc: Unicorn; address: uint64; size: int):
      inc steps
      if steps == 2: engines.setLen(0)             # the seq owned the engine
      discard uc.regRead(UC_X86_REG_RAX)           # the engine is still there
      closedWhileRunning += released
    let running = addr engines[0]
    running[].start(base, stop)
    check steps == 5
    check closedWhileRunning == 0
    check released == 1

  test "a hook that captures its own engine keeps it open until cycles are collected":
    # The hook uses the engine variable instead of its parameter: the engine
    # owns the closure and the closure owns the engine. Only ORC's cycle
    # collector can free that; under ARC it would leak, so nothing is run.
    when defined(gcOrc):
      proc run() =
        let uc = newX64()
        let witness = Witness(armed: true)
        var pages = 0
        discard uc.onCode do (parameter: Unicorn; address: uint64; size: int):
          doAssert witness.armed
          pages += uc.pageSize
        uc.start(base, stop)
        doAssert pages == 5 * 4096
      released = 0
      GC_disableOrc()                              # no collection at a moment of its own choosing
      run()
      check released == 0                          # leaving the scope did not close the engine
      GC_enableOrc()
      GC_fullCollect()
      check released == 1
    else:
      skip()

suite "memory-mapped I/O":
  # mov rax, [0x4008]; mov [0x4010], rbx
  const io = [0x48'u8, 0x8B, 0x04, 0x25, 0x08, 0x40, 0x00, 0x00,
              0x48, 0x89, 0x1C, 0x25, 0x10, 0x40, 0x00, 0x00]

  test "emulated reads and writes of the range call the closures":
    let uc = newX64(io)
    var log: seq[string]
    uc.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        log.add "read " & $offset & "/" & $size
        0x1000 + offset,
      proc (uc: Unicorn; offset: uint64; size: int; value: uint64) =
        log.add "write " & $offset & "/" & $size & "=" & toHex(value, 8))
    uc.regWrite(UC_X86_REG_RBX, 0x1122_3344_5566_7788'u64)
    uc.start(base, base + uint64(io.len))
    # Unicorn splits an 8-byte access into two of 4 bytes
    check log == @["read 8/4", "read 12/4", "write 16/4=55667788", "write 20/4=11223344"]
    check uc.regRead(UC_X86_REG_RAX) == 0x0000_100C_0000_1008'u64
    check uc.memRegions[1] ==
      (first: 0x4000'u64, last: 0x4fff'u64, perms: UC_PROT_READ or UC_PROT_WRITE)

  test "memRead and memWrite call them as well":
    let uc = newX64(io)
    var log: seq[string]
    uc.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        log.add "read " & $offset & "/" & $size
        0xAABBCCDD'u64,
      proc (uc: Unicorn; offset: uint64; size: int; value: uint64) =
        log.add "write " & $offset & "/" & $size & "=" & toHex(value, 4))
    check uc.memRead(0x4000, 4) == @[0xDD'u8, 0xCC, 0xBB, 0xAA]
    uc.memWrite(0x4004, [1'u8, 2])
    check log == @["read 0/4", "write 4/2=0201"]

  test "a range without a read closure cannot be read, without a write closure not written":
    let uc = newX64(io)
    var writes = 0
    uc.mmioMap(0x4000, 0x1000, nil,
      proc (uc: Unicorn; offset: uint64; size: int; value: uint64) = inc writes)
    check uc.memRegions[1].perms == UC_PROT_WRITE
    expectCode(UC_ERR_READ_PROT): uc.start(base, base + uint64(io.len))
    uc.start(base + 8, base + uint64(io.len))
    check writes == 2
    let readOnly = newX64(io)
    readOnly.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 = 7, nil)
    check readOnly.memRegions[1].perms == UC_PROT_READ
    expectCode(UC_ERR_WRITE_PROT): readOnly.start(base, base + uint64(io.len))
    check readOnly.regRead(UC_X86_REG_RAX) == 0x0000_0007_0000_0007'u64

  test "an exception in a closure comes out of start":
    let uc = newX64(io)
    uc.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        raise (ref DeviceError)(msg: "no such register", offset: offset),
      nil)
    try:
      uc.start(base, base + uint64(io.len))
      fail()
    except DeviceError as e:
      check e.offset == 8
    check uc.pc == base                            # the instruction did not complete

  test "an exception in a closure comes out of memRead and memWrite":
    let uc = newX64(io)
    var broken = true
    uc.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        if broken: raise (ref DeviceError)(msg: "read", offset: offset)
        5,
      proc (uc: Unicorn; offset: uint64; size: int; value: uint64) =
        if broken: raise (ref DeviceError)(msg: "write", offset: offset))
    try:
      discard uc.memRead(0x4020, 4)
      fail()
    except DeviceError as e:
      check e.msg == "read"
      check e.offset == 0x20
    try:
      uc.memWrite(0x4030, [1'u8])
      fail()
    except DeviceError as e:
      check e.msg == "write"
      check e.offset == 0x30
    broken = false
    check uc.memRead(0x4020, 1) == @[5'u8]         # nothing is left over
    uc.start(base, base + uint64(io.len))
    check uc.regRead(UC_X86_REG_RAX) == 0x0000_0005_0000_0005'u64

  test "a hook that reads the range and catches the exception lets the run go on":
    let uc = newX64(io)
    uc.memWrite(base, nops)
    uc.mmioMap(0x4000, 0x1000,
      proc (uc: Unicorn; offset: uint64; size: int): uint64 =
        raise (ref DeviceError)(msg: "read", offset: offset),
      nil)
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add hex(address)
      if address == base + 1:
        try:
          discard uc.memRead(0x4000, 4)
        except DeviceError as e:
          trace.add "caught " & e.msg
    uc.start(base, base + 3)
    check trace == @["1000", "1001", "caught read", "1002"]

  test "a hook that lets the exception of a closure pass ends the run with it":
    let uc = newX64(io)
    uc.memWrite(base, nops)
    uc.mmioMap(0x4000, 0x1000, nil,
      proc (uc: Unicorn; offset: uint64; size: int; value: uint64) =
        raise (ref DeviceError)(msg: "write", offset: offset))
    var trace: seq[string]
    discard uc.onCode do (uc: Unicorn; address: uint64; size: int):
      trace.add hex(address)
      if address == base + 1: uc.memWrite(0x4000, [1'u8])
    expect DeviceError: uc.start(base, base + 3)
    check trace == @["1000", "1001"]

  test "the closures are kept until the engine closes, also when the range is unmapped":
    proc mapped(uc: Unicorn) =
      let reading = Witness(armed: true)
      let writing = Witness(armed: true)
      uc.mmioMap(0x4000, 0x1000,
        proc (uc: Unicorn; offset: uint64; size: int): uint64 =
          doAssert reading.armed
          1,
        proc (uc: Unicorn; offset: uint64; size: int; value: uint64) =
          doAssert writing.armed)
    proc run() =
      let uc = newX64(io)
      mapped(uc)
      uc.start(base, base + uint64(io.len))
      uc.memUnmap(0x4000, 0x1000)
      doAssert released == 0
    released = 0
    run()
    check released == 2

  test "a context that holds memory brings an unmapped range back, closures and all":
    when libVersion >= (2, 1, 0):
      if memoryContexts:
        let uc = newX64(io)
        uc.contextMode = {UC_CTL_CONTEXT_CPU, UC_CTL_CONTEXT_MEMORY}
        var reads = 0
        uc.mmioMap(0x4000, 0x1000,
          proc (uc: Unicorn; offset: uint64; size: int): uint64 =
            inc reads
            7,
          nil)
        let ctx = uc.saveContext()
        uc.memUnmap(0x4000, 0x1000)
        expectCode(UC_ERR_READ_UNMAPPED): uc.start(base, base + 8)
        uc.restore(ctx)
        check uc.memRegions.len == 2
        uc.start(base, base + 8)
        check reads == 2
      else:
        skip()   # see `memoryContexts`
    else:
      skip()

  test "a range that cannot be mapped keeps no closure":
    proc refused(uc: Unicorn) =
      let witness = Witness(armed: true)
      try:
        uc.mmioMap(base, 0x1000,                   # overlaps the code
          proc (uc: Unicorn; offset: uint64; size: int): uint64 =
            doAssert witness.armed
            1,
          nil)
        doAssert false
      except UnicornError as e:
        doAssert e.code == UC_ERR_MAP
    let uc = newX64(io)
    released = 0
    refused(uc)
    check released == 1
