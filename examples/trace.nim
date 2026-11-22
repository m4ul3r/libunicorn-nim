## libunicorn together with its sibling package libcapstone: runs x86-64 code
## one instruction at a time and prints each instruction disassembled, with the
## registers it changed.
##
## Needs libcapstone on the path, from nimble or with `-p:<libcapstone>/src`:
## `nim c -r -p:src -p:../libcapstone-nim/src examples/trace.nim`.

import std/[strformat, strutils]
import libunicorn, libcapstone

const
  base = 0x1000'u64
  code = "\xb9\x03\x00\x00\x00" & # mov ecx, 3
         "\x31\xc0" &             # xor eax, eax
         "\x48\x01\xc8" &         # again: add rax, rcx
         "\xe2\xfb"               # loop again
  codeEnd = base + uint64(code.len)

let
  uc = initUnicorn(UC_ARCH_X86, UC_MODE_64)
  cs = initCapstone(CS_ARCH_X86, CS_MODE_64, detail = true)
uc.memMap(base, 0x1000)
uc.memWrite(base, code)

var pc = base
while pc != codeEnd:
  # 15 bytes hold any x86 instruction.
  let insns = cs.disasmAll(uc.memRead(pc, min(15, int(codeEnd - pc))), pc, maxCount = 1)
  if insns.len == 0: quit &"the bytes at {pc:#x} do not decode"
  uc.start(pc, codeEnd, count = 1)
  var changes: seq[string]
  for register in cs.regsAccess(insns[0]).written:
    # The two libraries number the registers differently but name them alike.
    let name = $cs.regName(register)
    let id = parseEnum("UC_X86_REG_" & name, UC_X86_REG_INVALID)
    if id != UC_X86_REG_INVALID: changes.add &"{name} = {uc.regRead(id):#x}"
  echo alignLeft($insns[0], 24), changes.join(", ")
  pc = uc.pc

let sum = uc.regRead(UC_X86_REG_RAX)
echo "rax = ", sum
if sum != 6: quit "expected 3 + 2 + 1 = 6"
