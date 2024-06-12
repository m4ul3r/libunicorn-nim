import std/[endians, strformat, strutils]
import libunicorn

let 
  X86_CODE64 = "\x41\xBC\x3B\xB0\x28\x2A\x49\x0F\xC9\x90\x4D\x0F\xAD\xCF\x49\x87\xFD\x90\x48\x81\xD2\x8A\xCE\x77\x35\x48\xF7\xD9\x4D\x29\xF4\x49\x81\xC9\xF6\x8A\xC6\x53\x4D\x87\xED\x48\x0F\xAD\xD2\x49\xF7\xD4\x48\xF7\xE1\x4D\x19\xC5\x4D\x89\xC5\x48\xF7\xD6\x41\xB8\x4F\x8D\x6B\x59\x4D\x87\xD0\x68\x6A\x1E\x09\x3C\x59"
  X86_CODE64_SYSCALL = "\x0f\x05" # syscall
  ADDRESS       = 0x1000000'u

proc hook_block(uc: ptr uc_engine, address: uint, size: int, user_data: pointer) =
  ## callback for tracing basic blocks
  echo &">>> Tracing basic block at {address:#X} block size = {size}"

proc hook_code64(uc: ptr uc_engine, address: uint, size: int, user_data: pointer) = 
  ## callback for tracing instruction
  var rip: uint
  uc_reg_read(uc, UC_X86_REG_RIP, rip.addr)
  echo &">>> Tracing instruction at {address:#X} instruction size = {size}"
  echo &">>> RIP is {rip:#X}"

  # Uncomment below code to stop the emulation using uc_emu_stop()
  # if (address == 0x1000009):
  #   uc_emu_stop(uc)

proc hook_mem64(uc: ptr uc_engine, typ: uc_mem_type, address: uint, size: int, value: int, user_data: pointer) = 
  ## callback for memory reads/writes
  case typ:
  of UC_MEM_READ:
    echo &">>> Memory is being READ at {address:#X}, data size = {size}"
  of UC_MEM_WRITE:
    echo &">>> Memory is being WRITE at {address:#X}, data size = {size}, data value = {value:#X}"
  else:
    discard

proc hook_syscall(uc: ptr uc_engine, user_data: pointer) = 
  ## callback for syscall instruction (x86_64)
  var rax: uint
  uc_reg_read(uc, UC_X86_REG_RAX, rax.addr)
  if (rax == 0x100):
    rax = 0x200
    uc_reg_write(uc, UC_X86_REG_RAX, rax.addr)
  else:
    echo &"[!] was not expecting rax={rax:#X} in syscall"


proc test_x86_64(): bool =
  var
    uc:  ptr uc_engine
    err: uc_err
    trace1, trace2, trace3, trace4: uc_hook

    rax = 0x71f3029efd49d41d'u
    rbx = 0xd87b45277f133ddb'u
    rcx = 0xab40d1ffd8afc461'u
    rdx = 0x0919317b4a733f01'u
    rsi = 0x4c24e753a17ea358'u
    rdi = 0xe509a57d2571ce96'u
    r8  = 0xea5b108cc2b9ab1f'u
    r9  = 0x19ec097c8eb618c1'u
    r10 = 0xec45774f00c5f682'u
    r11 = 0xe17e9dbec8c074aa'u
    r12 = 0x80f86a8dc0f6d457'u
    r13 = 0x48288ca5671c5492'u
    r14 = 0x595f72f6e4017f6e'u
    r15 = 0x1efd97aea331cccc'u

    rsp = ADDRESS + 0x200000

  echo "[i] Emulate x86_64 code"

  err = uc_open(UC_ARCH_x86, UC_MODE_64, uc.addr)
  if err.bool:
    echo "[!] Failed on uc_open() with error: ", err
    return false

  # Map 2MB memory for emulation
  uc_mem_map(uc, ADDRESS, 2*1024*1024, UC_PROT_ALL)

  # write machine code to emulated memory
  if (uc_mem_write(uc, ADDRESS, PTR(X86_CODE64), X86_CODE64.len.csize_t).bool):
    echo "[!] Failed to write emulation code to memory"
    return false

  # initialize machine registers
  uc_reg_write(uc, UC_X86_REG_RSP, rsp.addr)
  uc_reg_write(uc, UC_X86_REG_RAX, rax.addr)
  uc_reg_write(uc, UC_X86_REG_RBX, rbx.addr)
  uc_reg_write(uc, UC_X86_REG_RCX, rcx.addr)
  uc_reg_write(uc, UC_X86_REG_RDX, rdx.addr)
  uc_reg_write(uc, UC_X86_REG_RSI, rsi.addr)
  uc_reg_write(uc, UC_X86_REG_RDI, rdi.addr)
  uc_reg_write(uc, UC_X86_REG_R8,  r8.addr)
  uc_reg_write(uc, UC_X86_REG_R9,  r9.addr)
  uc_reg_write(uc, UC_X86_REG_R10, r10.addr)
  uc_reg_write(uc, UC_X86_REG_R11, r11.addr)
  uc_reg_write(uc, UC_X86_REG_R12, r12.addr)
  uc_reg_write(uc, UC_X86_REG_R13, r13.addr)
  uc_reg_write(uc, UC_X86_REG_R14, r14.addr)
  uc_reg_write(uc, UC_X86_REG_R15, r15.addr)

  # tracing all basic blocks with customized callback
  uc_hook_add(uc, trace1.addr, UC_HOOK_BLOCK, hook_block, nil, 1, 0)

  # tracing all instructions in the range [ADDRESS, ADDRESS+20]
  uc_hook_add(uc, trace2.addr, UC_HOOK_CODE, hook_code64, nil, ADDRESS, ADDRESS+20)
    
  # tracing all memory WRITE access (with @begin > @end)
  uc_hook_add(uc, trace3.addr, UC_HOOK_MEM_WRITE, hook_mem64, nil, 1, 0)

  # tracing all memory READ access (with @begin > @end)
  uc_hook_add(uc, trace4.addr, UC_HOOK_MEM_READ, hook_mem64, nil, 1, 0)

  # emulate machine code in infinite time (last param = 0) or when finishing all the code
  err = uc_emu_start(uc, ADDRESS, ADDRESS + X86_CODE64.len.uint, 0, 0)
  if err.bool:
    echo "[!] Failed on uc_emu_start() with error: ", uc_strerror(err)
    return false

  # print out some registers
  echo ">>> Emulation done. Below is the CPU context"
  uc_reg_read(uc, UC_X86_REG_RAX, rax.addr)
  uc_reg_read(uc, UC_X86_REG_RBX, rbx.addr)
  uc_reg_read(uc, UC_X86_REG_RCX, rcx.addr)
  uc_reg_read(uc, UC_X86_REG_RDX, rdx.addr)
  uc_reg_read(uc, UC_X86_REG_RSI, rsi.addr)
  uc_reg_read(uc, UC_X86_REG_RDI, rdi.addr)
  uc_reg_read(uc, UC_X86_REG_R8,  r8.addr)
  uc_reg_read(uc, UC_X86_REG_R9,  r9.addr)
  uc_reg_read(uc, UC_X86_REG_R10, r10.addr)
  uc_reg_read(uc, UC_X86_REG_R11, r11.addr)
  uc_reg_read(uc, UC_X86_REG_R12, r12.addr)
  uc_reg_read(uc, UC_X86_REG_R13, r13.addr)
  uc_reg_read(uc, UC_X86_REG_R14, r14.addr)
  uc_reg_read(uc, UC_X86_REG_R15, r15.addr)

  echo &">>> RAX = {rax:#X}"
  echo &">>> RBX = {rbx:#X}"
  echo &">>> RCX = {rcx:#X}"
  echo &">>> RDX = {rdx:#X}"
  echo &">>> RSI = {rsi:#X}"
  echo &">>> RDI = {rdi:#X}"
  echo &">>> R8  = {r8:#X}"
  echo &">>> R9  = {r9:#X}"
  echo &">>> R10 = {r10:#X}"
  echo &">>> R11 = {r11:#X}"
  echo &">>> R12 = {r12:#X}"
  echo &">>> R13 = {r13:#X}"
  echo &">>> R14 = {r14:#X}"
  echo &">>> R15 = {r15:#X}"

  uc_close(uc)
  return true

proc test_x86_64_syscall(): bool =
  var
    uc:     ptr uc_engine
    trace1: uc_hook
    err:    uc_err
    rax   = 0x100'u
  
  echo "\n================================================"
  echo "[i] Emulate x86_64 code with 'syscall' instructon"

  # initialize emulator in x86_64bit mode
  err = uc_open(UC_ARCH_X86, UC_MODE_64, uc.addr)
  if err.bool:
    echo "[!] Failed on uc_open() with error: ", err
    return false

  # map 2MB memory for this emulation
  uc_mem_map(uc, ADDRESS, 2*1024*1024, UC_PROT_ALL)

  # write machine code to be emulated to memory
  if (uc_mem_write(uc, ADDRESS, PTR(X86_CODE64_SYSCALL), X86_CODE64_SYSCALL.len.csize_t).bool):
    echo "[!] Failed to write emulation code to memory"
    return false

  # hook interrupts for syscall
  uc_hook_add(uc, trace1.addr, UC_HOOK_INSN, hook_syscall, nil, 1, 0, UC_X86_INS_SYSCALL)

  # initialize machine registers
  uc_reg_write(uc, UC_X86_REG_RAX, rax.addr)

  # emulate machine code in infinite time (last param = 0) or when finishing all the code
  err = uc_emu_start(uc, ADDRESS, ADDRESS + X86_CODE64_SYSCALL.len.uint, 0, 0)
  if err.bool:
    echo &"[!] Failed on uc_emu_start() with error returned {err}: {uc_strerror(err)}"

  # now print out some registers
  echo ">>> Emulation done. Below is the CPU context"

  uc_reg_read(uc, UC_X86_REG_RAX, rax.addr)

  echo &">>> RAX = {rax:#X}"

  uc_close(uc)

  return true

proc main() =
  discard test_x86_64()
  discard test_x86_64_syscall()


when isMainModule:
  main()