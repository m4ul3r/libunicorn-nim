import std/[strformat]
import libunicorn

let 
  ARM64_CODE =  "\xab\x05\x00\xb8\xaf\x05\x40\x38" # str w11, [x13], #0; ldrb w15, [x13], #0
  ADDRESS       = 0x1000'u

proc hook_block(uc: ptr uc_engine, address: uint, size: int, user_data: pointer) =
  ## callback for tracing basic blocks
  echo &">>> Tracing basic block at {address:#X} block size = {size}"

proc hook_code(uc: ptr uc_engine, address: uint, size: int, user_data: pointer) = 
  ## callback for tracing instruction
  echo &">>> Tracing instruction at {address:#X} instruction size = {size}"


proc test_arm64(): bool = 
  var
    uc:  ptr uc_engine
    err: uc_err
    trace1, trace2: uc_hook
    x11 = 0x12345678'u
    x13 = 0x1000'u + 0x8'u
    x15 = 0x33'u

  echo "[i] Emulate ARM64 code"

  # initialize emulator in ARM mode
  err = uc_open(UC_ARCH_ARM64, UC_MODE_ARM, uc.addr)
  if err.bool:
    echo &"[!] Failed on uc_open() with error returned: {err} {uc_strerror(err)}"
    return false

  # map 2MB memory for this emulation
  uc_mem_map(uc, ADDRESS, 2*1024*1024, UC_PROT_ALL)

  # write machine code to be emulated to memory
  uc_mem_write(uc, ADDRESS, PTR(ARM64_CODE), ARM64_CODE.len)

  # init machine regs
  uc_reg_write(uc, UC_ARM64_REG_X11, x11.addr)
  uc_reg_write(uc, UC_ARM64_REG_X13, x13.addr)
  uc_reg_write(uc, UC_ARM64_REG_X15, x15.addr)

  # tracing all basic blocks with customized callback
  uc_hook_add(uc, trace1.addr, UC_HOOK_BLOCK, hook_block, nil, 1, 0)

  # tracing one instruction at ADDRESS with customized callback
  uc_hook_add(uc, trace2.addr, UC_HOOK_CODE, hook_code, nil, ADDRESS, ADDRESS)

  # emulate machine code in infinite time or when finishing all the code
  err = uc_emu_start(uc, ADDRESS, (ADDRESS + ARM64_CODE.len.uint), 0, 0)
  if err.bool:
    echo &"[!] Failed on uc_emu_start() with error returned: {err}"
    return false

  echo ">>> Emulation done. Below is the CPU context"
  echo ">>> As little endian, x16 should be 0x78"

  uc_reg_read(uc, UC_ARM64_REG_X15, x15.addr)
  echo &">>> X15 = {x15:#X}"

  uc_close(uc)

  return true


proc main() =
  discard test_arm64()

when isMainModule:
  main()