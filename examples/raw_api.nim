## The C API, for code ported from C or for calls the Nim API does not cover:
## Unicorn's own x86-64 and ARM64 samples, call for call. The names and
## signatures are Unicorn's. Callbacks are `{.cdecl.}` procs with the parameter
## types of the C header, a register is read into a variable of its size, and
## every call returns a `uc_err` that has to be looked at.
##
## Run it with `nim c -r -p:src examples/raw_api.nim`; any `--mm` will do.

import std/strutils
import libunicorn/raw

const
  address = 0x1000000'u64
  x86Code = "\x41\xBC\x3B\xB0\x28\x2A\x49\x0F\xC9\x90\x4D\x0F\xAD\xCF\x49\x87\xFD\x90\x48\x81" &
    "\xD2\x8A\xCE\x77\x35\x48\xF7\xD9\x4D\x29\xF4\x49\x81\xC9\xF6\x8A\xC6\x53\x4D\x87\xED\x48" &
    "\x0F\xAD\xD2\x49\xF7\xD4\x48\xF7\xE1\x4D\x19\xC5\x4D\x89\xC5\x48\xF7\xD6\x41\xB8\x4F\x8D" &
    "\x6B\x59\x4D\x87\xD0\x68\x6A\x1E\x09\x3C\x59"
  syscallCode = "\x0f\x05"                       # syscall
  arm64Code = "\xab\x05\x00\xb8\xaf\x05\x40\x38" # str w11, [x13], #0; ldrb w15, [x13], #0
  x86Registers = [
    (UC_X86_REG_RAX, 0x71f3029efd49d41d'u64), (UC_X86_REG_RBX, 0xd87b45277f133ddb'u64),
    (UC_X86_REG_RCX, 0xab40d1ffd8afc461'u64), (UC_X86_REG_RDX, 0x0919317b4a733f01'u64),
    (UC_X86_REG_RSI, 0x4c24e753a17ea358'u64), (UC_X86_REG_RDI, 0xe509a57d2571ce96'u64),
    (UC_X86_REG_R8, 0xea5b108cc2b9ab1f'u64), (UC_X86_REG_R9, 0x19ec097c8eb618c1'u64),
    (UC_X86_REG_R10, 0xec45774f00c5f682'u64), (UC_X86_REG_R11, 0xe17e9dbec8c074aa'u64),
    (UC_X86_REG_R12, 0x80f86a8dc0f6d457'u64), (UC_X86_REG_R13, 0x48288ca5671c5492'u64),
    (UC_X86_REG_R14, 0x595f72f6e4017f6e'u64), (UC_X86_REG_R15, 0x1efd97aea331cccc'u64),
    (UC_X86_REG_RSP, address + 0x200000)]

template check(call: uc_err) =
  ## Leaves the enclosing proc when a call fails, as the C samples do.
  let err = call
  if err != UC_ERR_OK:
    echo "failed: ", astToStr(call), ": ", uc_strerror(err)
    return false

proc hex(value: uint64; digits = 16): string = "0x" & toHex(value, digits)

proc hookBlock(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  echo ">>> Tracing basic block at ", hex(address, 8), ", block size = ", size

proc hookCode(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  echo ">>> Tracing instruction at ", hex(address, 8), ", instruction size = ", size

proc hookCode64(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  # A callback cannot return an error: it leaves it where `user_data` points.
  var rip: uint64
  let err = uc_reg_read(uc, UC_X86_REG_RIP, addr rip)
  if err != UC_ERR_OK: cast[ptr uc_err](user_data)[] = err
  echo ">>> Tracing instruction at ", hex(address, 8), ", instruction size = ", size
  echo ">>> RIP is ", hex(rip, 8)

proc hookMem64(uc: ptr uc_engine; kind: uc_mem_type; address: uint64; size: cint; value: int64;
               user_data: pointer) {.cdecl.} =
  if kind == UC_MEM_READ:
    echo ">>> Memory is being READ at ", hex(address, 8), ", data size = ", size
  elif kind == UC_MEM_WRITE:
    echo ">>> Memory is being WRITE at ", hex(address, 8), ", data size = ", size,
         ", data value = ", hex(cast[uint64](value))

proc hookSyscall(uc: ptr uc_engine; user_data: pointer) {.cdecl.} =
  var rax: uint64
  var err = uc_reg_read(uc, UC_X86_REG_RAX, addr rax)
  if err == UC_ERR_OK and rax == 0x100:
    rax = 0x200
    err = uc_reg_write(uc, UC_X86_REG_RAX, addr rax)
  elif err == UC_ERR_OK:
    echo ">>> was not expecting rax = ", hex(rax), " in syscall"
  if err != UC_ERR_OK: cast[ptr uc_err](user_data)[] = err

proc x86_64(uc: ptr uc_engine): bool =
  var trace1, trace2, trace3, trace4: uc_hook
  var inHook = UC_ERR_OK
  check uc_mem_map(uc, address, 2 * 1024 * 1024, UC_PROT_ALL)
  check uc_mem_write(uc, address, x86Code.toOpenArrayByte(0, x86Code.high))
  for (reg, initial) in x86Registers:
    var value = initial
    check uc_reg_write(uc, reg, addr value)
  # `begin > last` stands for all of memory; the code hook sees the first 20 bytes only.
  check uc_hook_add(uc, addr trace1, UC_HOOK_BLOCK, hookBlock, nil, 1, 0)
  check uc_hook_add(uc, addr trace2, UC_HOOK_CODE, hookCode64, addr inHook, address, address + 20)
  check uc_hook_add(uc, addr trace3, UC_HOOK_MEM_WRITE, hookMem64, nil, 1, 0)
  check uc_hook_add(uc, addr trace4, UC_HOOK_MEM_READ, hookMem64, nil, 1, 0)
  check uc_emu_start(uc, address, address + uint64(x86Code.len), 0, 0)
  check inHook
  echo ">>> Emulation done. Below is the CPU context"
  for (reg, _) in x86Registers:
    var value: uint64
    check uc_reg_read(uc, reg, addr value)
    echo ">>> ", alignLeft(($reg)[len("UC_X86_REG_") .. ^1], 3), " = ", hex(value)
  true

proc x86_64Syscall(uc: ptr uc_engine): bool =
  var trace1: uc_hook
  var inHook = UC_ERR_OK
  var rax = 0x100'u64
  check uc_mem_map(uc, address, 2 * 1024 * 1024, UC_PROT_ALL)
  check uc_mem_write(uc, address, syscallCode.toOpenArrayByte(0, syscallCode.high))
  check uc_hook_add(uc, addr trace1, UC_HOOK_INSN, hookSyscall, addr inHook, 1, 0,
                    UC_X86_INS_SYSCALL)
  check uc_reg_write(uc, UC_X86_REG_RAX, addr rax)
  check uc_emu_start(uc, address, address + uint64(syscallCode.len), 0, 0)
  check inHook
  check uc_reg_read(uc, UC_X86_REG_RAX, addr rax)
  echo ">>> Emulation done. Below is the CPU context"
  echo ">>> RAX = ", hex(rax)
  rax == 0x200

proc arm64(uc: ptr uc_engine): bool =
  var trace1, trace2: uc_hook
  var x11 = 0x12345678'u64
  var x13 = address + 0x8
  var x15 = 0x33'u64
  check uc_mem_map(uc, address, 2 * 1024 * 1024, UC_PROT_ALL)
  check uc_mem_write(uc, address, arm64Code.toOpenArrayByte(0, arm64Code.high))
  check uc_reg_write(uc, UC_ARM64_REG_X11, addr x11)
  check uc_reg_write(uc, UC_ARM64_REG_X13, addr x13)
  check uc_reg_write(uc, UC_ARM64_REG_X15, addr x15)
  check uc_hook_add(uc, addr trace1, UC_HOOK_BLOCK, hookBlock, nil, 1, 0)
  check uc_hook_add(uc, addr trace2, UC_HOOK_CODE, hookCode, nil, address, address)
  check uc_emu_start(uc, address, address + uint64(arm64Code.len), 0, 0)
  check uc_reg_read(uc, UC_ARM64_REG_X15, addr x15)
  echo ">>> Emulation done. Below is the CPU context"
  echo ">>> As little endian, X15 should be 0x78"
  echo ">>> X15 = ", hex(x15)
  x15 == 0x78

proc run(title: string; arch: uc_arch; mode: uc_mode;
         emulate: proc (uc: ptr uc_engine): bool {.nimcall.}): bool =
  ## Opens an engine for `emulate` and closes it whatever happens in there.
  ## Unicorn can be built without an architecture; that part is then skipped.
  echo title
  if not uc_arch_supported(arch):
    echo "skipped: this Unicorn library was built without ", arch, "\n"
    return true
  var uc: ptr uc_engine
  check uc_open(arch, mode, addr uc)
  result = emulate(uc)
  check uc_close(uc)
  echo ""

var failures = 0
if not run("Emulate x86_64 code", UC_ARCH_X86, UC_MODE_64, x86_64): inc failures
if not run("Emulate x86_64 code with 'syscall' instruction", UC_ARCH_X86, UC_MODE_64,
           x86_64Syscall): inc failures
if not run("Emulate ARM64 code", UC_ARCH_ARM64, UC_MODE_ARM, arm64): inc failures
quit(if failures == 0: QuitSuccess else: QuitFailure)
