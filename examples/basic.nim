## Emulates a few instructions on several architectures and modes, and prints
## the registers involved before and after. A platform the installed Unicorn
## was built without is skipped.
##
## Run it with `nim c -r -p:src examples/basic.nim`.

import std/[sequtils, strformat, strutils]
import libunicorn

type
  Register = tuple[name: string; id: cint; initial: uint64]
  Platform = tuple[name: string; arch: uc_arch; mode: uc_mode; code: string; regs: seq[Register]]

template reg(name: string; id: enum; initial: uint64): Register =
  ## Each architecture has its own register enum; the table holds the numbers.
  (name, cint(ord(id)), uint64(initial))

const
  base = 0x4000'u64      # where the code goes: a page boundary everywhere, in reach of 16-bit code
  scratch = base + 0x100 # some memory for the code to work on

const platforms: seq[Platform] = @[
  ("x86, 16-bit", UC_ARCH_X86, UC_MODE_16, "\x41\x4a", # inc cx; dec dx
   @[reg("cx", UC_X86_REG_CX, 0x1234), reg("dx", UC_X86_REG_DX, 0x7890)]),
  ("x86, 32-bit", UC_ARCH_X86, UC_MODE_32,
   "\x41\x4a\x66\x0f\xef\xc1", # inc ecx; dec edx; pxor xmm0, xmm1
   @[reg("ecx", UC_X86_REG_ECX, 0x1234), reg("edx", UC_X86_REG_EDX, 0x7890)]),
  ("x86, 64-bit", UC_ARCH_X86, UC_MODE_64,
   # mov r12d, 0x2a28b03b; bswap r9; xchg r13, rdi
   "\x41\xbc\x3b\xb0\x28\x2a\x49\x0f\xc9\x49\x87\xfd",
   @[reg("rdi", UC_X86_REG_RDI, 0xe509a57d2571ce96'u64),
     reg("r9", UC_X86_REG_R9, 0x19ec097c8eb618c1'u64),
     reg("r12", UC_X86_REG_R12, 0x80f86a8dc0f6d457'u64),
     reg("r13", UC_X86_REG_R13, 0x48288ca5671c5492'u64)]),
  ("ARM", UC_ARCH_ARM, UC_MODE_ARM,
   "\x37\x00\xa0\xe3\x03\x10\x42\xe0", # mov r0, #0x37; sub r1, r2, r3
   @[reg("r0", UC_ARM_REG_R0, 0x1234), reg("r1", UC_ARM_REG_R1, 0),
     reg("r2", UC_ARM_REG_R2, 0x6789), reg("r3", UC_ARM_REG_R3, 0x3333)]),
  ("ARM, Thumb", UC_ARCH_ARM, UC_MODE_THUMB, "\x83\xb0", # sub sp, #0xc
   @[reg("sp", UC_ARM_REG_SP, 0x1234)]),
  ("ARM64", UC_ARCH_ARM64, UC_MODE_ARM,
   "\xab\x05\x00\xb8\xaf\x05\x40\x38", # str w11, [x13], #0; ldrb w15, [x13], #0
   @[reg("x11", UC_ARM64_REG_X11, 0x12345678), reg("x13", UC_ARM64_REG_X13, scratch),
     reg("x15", UC_ARM64_REG_X15, 0x33)]),
  ("MIPS32, big-endian", UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN,
   "\x34\x21\x34\x56", # ori $at, $at, 0x3456
   @[reg("at", UC_MIPS_REG_AT, 0x6789)]),
  ("MIPS32, little-endian", UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_LITTLE_ENDIAN,
   "\x56\x34\x21\x34", # ori $at, $at, 0x3456
   @[reg("at", UC_MIPS_REG_AT, 0x6789)]),
  ("PowerPC 32, big-endian", UC_ARCH_PPC, UC_MODE_PPC32 or UC_MODE_BIG_ENDIAN,
   "\x7f\x46\x1a\x14", # add r26, r6, r3
   @[reg("r3", UC_PPC_REG_3, 0x1234), reg("r6", UC_PPC_REG_6, 0x6789),
     reg("r26", UC_PPC_REG_26, 0x5555)]),
  ("SPARC32, big-endian", UC_ARCH_SPARC, UC_MODE_SPARC32 or UC_MODE_BIG_ENDIAN,
   "\x86\x00\x40\x02", # add %g1, %g2, %g3
   @[reg("g1", UC_SPARC_REG_G1, 0x1230), reg("g2", UC_SPARC_REG_G2, 0x6789),
     reg("g3", UC_SPARC_REG_G3, 0x5555)]),
  ("RISC-V 64", UC_ARCH_RISCV, UC_MODE_RISCV64,
   "\x13\x05\x10\x00\x93\x85\x05\x02", # addi a0, zero, 1; addi a1, a1, 32
   @[reg("a0", UC_RISCV_REG_A0, 0x1234), reg("a1", UC_RISCV_REG_A1, 0x7890)]),
  ("S390X", UC_ARCH_S390X, UC_MODE_BIG_ENDIAN, "\x18\x23", # lr %r2, %r3
   @[reg("r2", UC_S390X_REG_R2, 2), reg("r3", UC_S390X_REG_R3, 3)]),
  ("M68K", UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, "\x76\xed", # moveq #-19, %d3
   @[reg("d3", UC_M68K_REG_D3, 0)]),
  ("TriCore", UC_ARCH_TRICORE, UC_MODE_LITTLE_ENDIAN,
   "\x82\x11\xbb\x00\x00\x08", # mov d1, #0x1; mov.u d0, #0x8000
   @[reg("d0", UC_TRICORE_REG_D0, 0x1234), reg("d1", UC_TRICORE_REG_D1, 0x5678)]),
]

proc show(uc: Unicorn; label: string; regs: seq[Register]) =
  echo "  ", label, regs.mapIt(&"{it.name} = {uc.regRead(it.id):#x}").join("  ")

for platform in platforms:
  echo platform.name
  if not uc_arch_supported(platform.arch):
    echo "  skipped: this Unicorn library was built without ", platform.arch, "\n"
    continue
  let uc = initUnicorn(platform.arch, platform.mode)
  uc.memMap(base, 0x4000)
  uc.memWrite(base, platform.code)
  for register in platform.regs: uc.regWrite(register.id, register.initial)
  echo "  code:   ", platform.code.mapIt(toHex(ord(it), 2)).join(" ")
  uc.show("before: ", platform.regs)
  # Thumb code is entered at an odd address.
  let entry = if platform.mode == UC_MODE_THUMB: base or 1 else: base
  uc.start(entry, base + uint64(platform.code.len))
  uc.show("after:  ", platform.regs)
  echo ""
