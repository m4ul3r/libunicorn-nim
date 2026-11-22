## Hooks as Nim closures, on a small x86-64 program that builds a line of text
## in memory nobody mapped and prints it with Linux system calls:
##
## * `onCode` and `onMem` trace the instructions and the memory accesses;
## * `onMemFault` maps a page the moment the program touches it;
## * `onSyscall` carries out `write` and `exit`, and ends the run with `stop`;
## * an exception raised in a hook comes out of `start`.
##
## Run it with `nim c -r -p:src examples/hooks.nim`.

import std/[sequtils, strformat, strutils]
import libunicorn

const
  base = 0x1000'u64
  buffer = 0x200000'u64 # not mapped: the fault hook provides it
  code =
    "\xbe\x00\x00\x20\x00" &     # mov esi, 0x200000
    "\x48\xb8hello, w" &         # mov rax, "hello, w"
    "\x48\x89\x06" &             # mov [rsi], rax
    "\x48\xb8orld!\n\x00\x00" &  # mov rax, "orld!\n"
    "\x48\x89\x46\x08" &         # mov [rsi + 8], rax
    "\xb8\x01\x00\x00\x00" &     # mov eax, 1          ; write
    "\xbf\x01\x00\x00\x00" &     # mov edi, 1          ; to standard output
    "\xba\x0e\x00\x00\x00" &     # mov edx, 14         ; that many bytes from rsi
    "\x0f\x05" &                 # syscall
    "\xb8\x3c\x00\x00\x00" &     # mov eax, 60         ; exit
    "\x8b\x7e\x10" &             # mov edi, [rsi + 16] ; with the status found there
    "\x0f\x05" &                 # syscall
    "\xeb\xfe"                   # jmp $               ; never reached
  lastSyscall = base + uint64(code.len) - 4

let uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
uc.memMap(base, 0x1000)
uc.memWrite(base, code)

let codeTrace = uc.onCode do (uc: Unicorn; address: uint64; size: int):
  echo &"  {address:#x}: ", uc.memRead(address, size).mapIt(toHex(it)).join(" ")

let memTrace = uc.onMem(UC_HOOK_MEM_READ or UC_HOOK_MEM_WRITE) do (
    uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64):
  if kind == UC_MEM_WRITE:
    echo &"    writes {size} bytes at {address:#x}: {cast[uint64](value):#x}"
  else:
    echo &"    reads {size} bytes at {address:#x}"

discard uc.onMemFault(UC_HOOK_MEM_UNMAPPED) do (
    uc: Unicorn; kind: uc_mem_type; address: uint64; size: int; value: int64) -> bool:
  let page = address and not 0xfff'u64
  echo &"    {address:#x} is not mapped: mapping a page at {page:#x}"
  uc.memMap(page, 0x1000, UC_PROT_READ or UC_PROT_WRITE)
  true # handled: the access is tried again

var exitStatus = -1
discard uc.onSyscall do (uc: Unicorn):
  let number = uc.regRead(UC_X86_REG_RAX)
  case number
  of 1: # write(fd, text, count)
    let text = uc.memRead(uc.regRead(UC_X86_REG_RSI), int(uc.regRead(UC_X86_REG_RDX)))
    stdout.write cast[string](text)
    uc.regWrite(UC_X86_REG_RAX, uint64(text.len))
  of 60: # exit(status)
    exitStatus = int(uc.regRead(UC_X86_REG_RDI))
    uc.stop()
  else:
    raise newException(ValueError, &"system call {number} is not implemented")

echo "running the program"
uc.start(base, base + uint64(code.len))
echo "the program exited with status ", exitStatus
if exitStatus != 0: quit "expected status 0"

# An exception raised in a hook stops the emulation and is raised by `start`.
uc.removeHook(codeTrace)
uc.removeHook(memTrace)
uc.regWrite(UC_X86_REG_RAX, 39)
try:
  uc.start(lastSyscall, base + uint64(code.len))
  quit "expected the system call hook to raise"
except ValueError as e:
  echo "start raised ", e.name, ": ", e.msg
