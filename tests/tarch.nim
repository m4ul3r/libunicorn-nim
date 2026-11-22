## Architectures and modes other than x86-64, through the Nim API: a few
## instructions with a known effect on each, that `pc` is the program counter
## of each, and that the mode constants select what they say. The code of the
## first suite comes from Unicorn's own samples (`samples/sample_*.c`). What
## the installed library cannot emulate is skipped.

import std/unittest
import libunicorn

const
  base = 0x8000'u64
    ## Where the code goes: below 64 KB for 16-bit x86, and a multiple of
    ## TriCore's 16 KB pages.
  mapped = 0x4000'u64 ## How much is mapped there.

proc run(uc: Unicorn; code: string; begin = base) =
  ## Maps memory, puts `code` at its start and emulates all of it.
  uc.memMap(base, mapped)
  uc.memWrite(base, code)
  uc.start(begin, base + uint64(code.len))

proc usable(arch: uc_arch; mode: uc_mode): bool =
  ## Whether the library in this process can emulate `arch` in `mode`.
  if not uc_arch_supported(arch): return false
  # 64-bit MIPS stops with a CPU exception at the first instruction before
  # Unicorn 2.1.3, which picked a 32-bit CPU model for it.
  let v = uc_version()
  not (arch == UC_ARCH_MIPS and UC_MODE_MIPS64 in mode and
       (v.major, v.minor, v.patch) < (2, 1, 3))

template modeTest(name: string; arch: uc_arch; mode: uc_mode; body: untyped) =
  ## A test that is skipped when the library cannot do `arch` and `mode`.
  test name:
    if not usable(arch, mode):
      skip()
    else:
      body

template archTest(name: string; arch: uc_arch; mode: uc_mode; body: untyped) =
  ## A `modeTest` with an engine `uc` for `arch` and `mode`.
  modeTest name, arch, mode:
    let uc {.inject.} = initUnicorn(arch, mode)
    body

proc effect[Reg: enum](arch: uc_arch; mode: uc_mode; code: string; reg: Reg;
                       initial = 0'u64; begin = base; last = 0'u64): uint64 =
  ## What `reg`, set to `initial`, holds after `code` ran in `mode` (up to
  ## the address `last`, when given).
  let uc = initUnicorn(arch, mode)
  uc.memMap(base, mapped)
  uc.memWrite(base, code)
  uc.regWrite(reg, initial)
  uc.start(begin, if last != 0: last else: base + uint64(code.len))
  uc.regRead(reg)

const elsewhere = base + 0x40 ## An address to send the program counter to.

template checkPc(uc: Unicorn; reg: untyped; stateBit = 0'u64) =
  ## Checks that `uc.pc` is the register `reg`: it reads what the run left
  ## there, and an address written to it arrives there. `stateBit` goes into
  ## the address written: on ARM the lowest bit selects Thumb and is not kept
  ## in the register.
  check uc.pc == uc.regRead(reg)
  uc.pc = elsewhere or stateBit
  check uc.regRead(reg) == elsewhere
  check uc.pc == elsewhere

template checkPcAt(uc: Unicorn; reg: untyped; ending: uint64; stateBit = 0'u64) =
  ## `checkPc` after a run that leaves the program counter at `ending`.
  check uc.regRead(reg) == ending
  check uc.pc == ending
  checkPc(uc, reg, stateBit)

suite "architectures":
  archTest "x86 16-bit", UC_ARCH_X86, UC_MODE_16:
    # add byte ptr [bx + si], al
    uc.regWrite(UC_X86_REG_AX, 7)
    uc.regWrite(UC_X86_REG_BX, 0x8800)
    uc.regWrite(UC_X86_REG_SI, 6)
    uc.run("\x00\x00")
    check uc.memRead(0x8806, 1) == @[7'u8]
    # The program counter of 16-bit code is IP, the offset in the code
    # segment. That segment begins at 0 here, so it is the linear address too.
    checkPcAt(uc, UC_X86_REG_IP, base + 2)

  archTest "x86 16-bit, code segment elsewhere", UC_ARCH_X86, UC_MODE_16:
    # add byte ptr [bx + si], al; in a code segment that begins at 0x7f00.
    # `run` starts and ends at linear addresses; the program counter is the
    # offset in the segment.
    uc.regWrite(UC_X86_REG_CS, 0x7f0)
    uc.regWrite(UC_X86_REG_AX, 7)
    uc.regWrite(UC_X86_REG_BX, 0x8800)
    uc.regWrite(UC_X86_REG_SI, 6)
    uc.run("\x00\x00")
    check uc.memRead(0x8806, 1) == @[7'u8]
    checkPcAt(uc, UC_X86_REG_IP, base - 0x7f00 + 2)
    check uc.regRead(UC_X86_REG_CS) == 0x7f0

  archTest "x86 32-bit", UC_ARCH_X86, UC_MODE_32:
    # inc ecx; dec edx
    uc.regWrite(UC_X86_REG_ECX, 0x1234)
    uc.regWrite(UC_X86_REG_EDX, 0x7890)
    uc.run("\x41\x4a")
    check uc.regRead(UC_X86_REG_ECX) == 0x1235
    check uc.regRead(UC_X86_REG_EDX) == 0x788f
    checkPcAt(uc, UC_X86_REG_EIP, base + 2)

  archTest "ARM", UC_ARCH_ARM, UC_MODE_ARM:
    # mov r0, #0x37; sub r1, r2, r3
    uc.regWrite(UC_ARM_REG_R0, 0x1234)
    uc.regWrite(UC_ARM_REG_R2, 0x6789)
    uc.regWrite(UC_ARM_REG_R3, 0x3333)
    uc.run("\x37\x00\xa0\xe3\x03\x10\x42\xe0")
    check uc.regRead(UC_ARM_REG_R0) == 0x37
    check uc.regRead(UC_ARM_REG_R1) == 0x3456
    checkPcAt(uc, UC_ARM_REG_PC, base + 8)

  archTest "ARM big-endian", UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_BIG_ENDIAN:
    # mov r0, #0x37; sub r1, r2, r3
    uc.regWrite(UC_ARM_REG_R0, 0x1234)
    uc.regWrite(UC_ARM_REG_R2, 0x6789)
    uc.regWrite(UC_ARM_REG_R3, 0x3333)
    uc.run("\xe3\xa0\x00\x37\xe0\x42\x10\x03")
    check uc.regRead(UC_ARM_REG_R0) == 0x37
    check uc.regRead(UC_ARM_REG_R1) == 0x3456
    checkPcAt(uc, UC_ARM_REG_PC, base + 8)

  archTest "Thumb", UC_ARCH_ARM, UC_MODE_THUMB:
    # sub sp, #0xc; the lowest bit of the start address selects Thumb
    uc.regWrite(UC_ARM_REG_SP, 0x1234)
    uc.run("\x83\xb0", begin = base or 1)
    check uc.regRead(UC_ARM_REG_SP) == 0x1228
    # The register holds the address without the Thumb bit it was started with.
    checkPcAt(uc, UC_ARM_REG_PC, base + 2, stateBit = 1)

  archTest "Thumb big-endian", UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_BIG_ENDIAN:
    # sub sp, #0xc
    uc.regWrite(UC_ARM_REG_SP, 0x1234)
    uc.run("\xb0\x83", begin = base or 1)
    check uc.regRead(UC_ARM_REG_SP) == 0x1228
    checkPcAt(uc, UC_ARM_REG_PC, base + 2, stateBit = 1)

  archTest "Thumb on a Cortex-M", UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_MCLASS:
    # cmp r2, r3; ite ne; movne r2, #0x68; moveq r2, #0x4d
    const code = "\x9a\x42\x14\xbf\x68\x22\x4d\x22"
    uc.regWrite(UC_ARM_REG_R2, 0x3333)
    uc.regWrite(UC_ARM_REG_R3, 0x3333)
    uc.run(code, begin = base or 1)
    check uc.regRead(UC_ARM_REG_R2) == 0x4d
    checkPcAt(uc, UC_ARM_REG_PC, base + 8, stateBit = 1)
    # r3 is 0 here, so the registers differ.
    check effect(UC_ARCH_ARM, UC_MODE_THUMB or UC_MODE_MCLASS, code, UC_ARM_REG_R2, 0x3333,
                 begin = base or 1) == 0x68

  archTest "ARM64", UC_ARCH_ARM64, UC_MODE_ARM:
    # str w11, [x13], #0; ldrb w15, [x13], #0
    uc.regWrite(UC_ARM64_REG_X11, 0x12345678)
    uc.regWrite(UC_ARM64_REG_X13, base + 0x800)
    uc.regWrite(UC_ARM64_REG_X15, 0x33)
    uc.run("\xab\x05\x00\xb8\xaf\x05\x40\x38")
    check uc.regRead(UC_ARM64_REG_X15) == 0x78
    check uc.memRead(base + 0x800, 4) == @[0x78'u8, 0x56, 0x34, 0x12]
    checkPcAt(uc, UC_ARM64_REG_PC, base + 8)

  archTest "MIPS32 big-endian", UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN:
    # ori $at, $at, 0x3456
    uc.regWrite(UC_MIPS_REG_1, 0x6789)
    uc.run("\x34\x21\x34\x56")
    check uc.regRead(UC_MIPS_REG_1) == 0x77df
    # Unicorn does not bring the MIPS PC up to date when a run stops at its
    # end address (in every release up to 2.1.4 it still holds the start
    # address), so what the register holds after the run is not stated here.
    checkPc(uc, UC_MIPS_REG_PC)

  archTest "MIPS32 little-endian", UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_LITTLE_ENDIAN:
    # ori $at, $at, 0x3456
    uc.regWrite(UC_MIPS_REG_AT, 0x6789)
    uc.run("\x56\x34\x21\x34")
    check uc.regRead(UC_MIPS_REG_AT) == 0x77df
    checkPc(uc, UC_MIPS_REG_PC) # not the end address: see MIPS32 big-endian

  archTest "MIPS64 big-endian", UC_ARCH_MIPS, UC_MODE_MIPS64 or UC_MODE_BIG_ENDIAN:
    # ori $at, $at, 0x3456; the upper half of the 64-bit register stays
    uc.regWrite(UC_MIPS_REG_AT, 0x1234_5678_0000_6789'u64)
    uc.run("\x34\x21\x34\x56")
    check uc.regRead(UC_MIPS_REG_AT) == 0x1234_5678_0000_77df'u64
    checkPc(uc, UC_MIPS_REG_PC) # not the end address: see MIPS32 big-endian

  archTest "MIPS64 little-endian", UC_ARCH_MIPS, UC_MODE_MIPS64 or UC_MODE_LITTLE_ENDIAN:
    # ori $at, $at, 0x3456
    uc.regWrite(UC_MIPS_REG_AT, 0x1234_5678_0000_6789'u64)
    uc.run("\x56\x34\x21\x34")
    check uc.regRead(UC_MIPS_REG_AT) == 0x1234_5678_0000_77df'u64
    checkPc(uc, UC_MIPS_REG_PC) # not the end address: see MIPS32 big-endian

  archTest "SPARC", UC_ARCH_SPARC, UC_MODE_SPARC32 or UC_MODE_BIG_ENDIAN:
    # add %g1, %g2, %g3
    uc.regWrite(UC_SPARC_REG_G1, 0x1230)
    uc.regWrite(UC_SPARC_REG_G2, 0x6789)
    uc.regWrite(UC_SPARC_REG_G3, 0x5555)
    uc.run("\x86\x00\x40\x02")
    check uc.regRead(UC_SPARC_REG_G3) == 0x79b9
    checkPcAt(uc, UC_SPARC_REG_PC, base + 4)

  archTest "PowerPC", UC_ARCH_PPC, UC_MODE_PPC32 or UC_MODE_BIG_ENDIAN:
    # add r26, r6, r3
    uc.regWrite(UC_PPC_REG_3, 0x1234)
    uc.regWrite(UC_PPC_REG_6, 0x6789)
    uc.regWrite(UC_PPC_REG_26, 0x8877)
    uc.run("\x7f\x46\x1a\x14")
    check uc.regRead(UC_PPC_REG_26) == 0x79bd
    checkPcAt(uc, UC_PPC_REG_PC, base + 4)

  archTest "m68k", UC_ARCH_M68K, UC_MODE_BIG_ENDIAN:
    # moveq #-19, %d3
    uc.regWrite(UC_M68K_REG_D3, 0x1234)
    uc.run("\x76\xed")
    check uc.regRead(UC_M68K_REG_D3) == 0xffff_ffed'u64
    checkPcAt(uc, UC_M68K_REG_PC, base + 2)

  archTest "RISC-V 32", UC_ARCH_RISCV, UC_MODE_RISCV32:
    # addi a0, zero, 1; addi a1, a1, 0x20
    uc.regWrite(UC_RISCV_REG_A0, 0x1234)
    uc.regWrite(UC_RISCV_REG_A1, 0x7890)
    uc.run("\x13\x05\x10\x00\x93\x85\x05\x02")
    check uc.regRead(UC_RISCV_REG_A0) == 1
    check uc.regRead(UC_RISCV_REG_A1) == 0x78b0
    checkPcAt(uc, UC_RISCV_REG_PC, base + 8)

  archTest "RISC-V 64", UC_ARCH_RISCV, UC_MODE_RISCV64:
    # addi a0, zero, 1; addi a1, a1, 0x20; the addition carries into the upper half
    uc.regWrite(UC_RISCV_REG_A0, 0x1234)
    uc.regWrite(UC_RISCV_REG_A1, 0x1234_5678_ffff_fff0'u64)
    uc.run("\x13\x05\x10\x00\x93\x85\x05\x02")
    check uc.regRead(UC_RISCV_REG_A0) == 1
    check uc.regRead(UC_RISCV_REG_A1) == 0x1234_5679_0000_0010'u64
    checkPcAt(uc, UC_RISCV_REG_PC, base + 8)

  archTest "S390x", UC_ARCH_S390X, UC_MODE_BIG_ENDIAN:
    # lr %r2, %r3
    uc.regWrite(UC_S390X_REG_R2, 2)
    uc.regWrite(UC_S390X_REG_R3, 3)
    uc.run("\x18\x23")
    check uc.regRead(UC_S390X_REG_R2) == 3
    check uc.regRead(UC_S390X_REG_R3) == 3
    checkPcAt(uc, UC_S390X_REG_PC, base + 2)

  archTest "TriCore", UC_ARCH_TRICORE, UC_MODE_LITTLE_ENDIAN:
    # mov d1, #1; mov.u d0, #0x8000
    uc.regWrite(UC_TRICORE_REG_D0, 0x1234)
    uc.regWrite(UC_TRICORE_REG_D1, 0x5678)
    uc.run("\x82\x11\xbb\x00\x00\x08")
    check uc.regRead(UC_TRICORE_REG_D0) == 0x8000
    check uc.regRead(UC_TRICORE_REG_D1) == 1
    let v = uc_version()
    if (v.major, v.minor, v.patch) >= (2, 0, 1):
      checkPcAt(uc, UC_TRICORE_REG_PC, base + 6)
    else:
      # Unicorn 2.0.0 stops TriCore at the end address with a return from
      # exception. Nothing was saved to return to, so the CPU takes a context
      # management trap (class 3): PC is that trap's vector, 3 * 32 bytes
      # after BTV, and A11 the address the trap would return to, the one
      # the emulation reached.
      check uc.regRead(UC_TRICORE_REG_PC) == uc.regRead(UC_TRICORE_REG_BTV) + 3 * 32
      check uc.regRead(UC_TRICORE_REG_A11) == base + 6
      checkPc(uc, UC_TRICORE_REG_PC)

suite "the mode selects how the same bytes are read":
  modeTest "x86: operand size", UC_ARCH_X86, UC_MODE_32:
    # 40: inc ax in a 16-bit segment, inc eax in a 32-bit one
    check effect(UC_ARCH_X86, UC_MODE_16, "\x40", UC_X86_REG_EAX, 0x1_ffff) == 0x1_0000
    check effect(UC_ARCH_X86, UC_MODE_32, "\x40", UC_X86_REG_EAX, 0x1_ffff) == 0x2_0000

  modeTest "x86: address size", UC_ARCH_X86, UC_MODE_32:
    # 8d 40 01 is `lea ax, [bx + si + 1]` in 16-bit code and
    # `lea eax, [eax + 1]` in 32-bit code.
    check effect(UC_ARCH_X86, UC_MODE_16, "\x8d\x40\x01", UC_X86_REG_EAX, 0x10) == 1
    check effect(UC_ARCH_X86, UC_MODE_32, "\x8d\x40\x01", UC_X86_REG_EAX, 0x10) == 0x11

  modeTest "ARM and Thumb", UC_ARCH_ARM, UC_MODE_ARM:
    # 01 30 81 e2 is `add r3, r1, #1` as an ARM instruction; its first half
    # is `adds r0, #1` in Thumb.
    const code = "\x01\x30\x81\xe2"
    check effect(UC_ARCH_ARM, UC_MODE_ARM, code, UC_ARM_REG_R0, 0x10) == 0x10
    check effect(UC_ARCH_ARM, UC_MODE_ARM, code, UC_ARM_REG_R3, 0x10) == 1
    check effect(UC_ARCH_ARM, UC_MODE_THUMB, code, UC_ARM_REG_R0, 0x10,
                 begin = base or 1, last = base + 2) == 0x11
    check effect(UC_ARCH_ARM, UC_MODE_THUMB, code, UC_ARM_REG_R3, 0x10,
                 begin = base or 1, last = base + 2) == 0x10

  modeTest "ARM: byte order", UC_ARCH_ARM, UC_MODE_ARM:
    # e3 a0 b0 e3 is `mov r11, #0xe3` read big-endian and `movs r10, #0xe3`
    # read little-endian.
    const code = "\xe3\xa0\xb0\xe3"
    check effect(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_BIG_ENDIAN, code, UC_ARM_REG_R11) == 0xe3
    check effect(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_BIG_ENDIAN, code, UC_ARM_REG_R10) == 0
    check effect(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_LITTLE_ENDIAN, code, UC_ARM_REG_R10) == 0xe3
    check effect(UC_ARCH_ARM, UC_MODE_ARM or UC_MODE_LITTLE_ENDIAN, code, UC_ARM_REG_R11) == 0

  modeTest "MIPS: byte order", UC_ARCH_MIPS, UC_MODE_MIPS32:
    # 34 02 01 34 is `ori $v0, $zero, 0x134` read big-endian and
    # `ori $at, $zero, 0x234` read little-endian.
    const code = "\x34\x02\x01\x34"
    check effect(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, code, UC_MIPS_REG_V0) == 0x134
    check effect(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, code, UC_MIPS_REG_AT) == 0
    check effect(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_LITTLE_ENDIAN, code,
                 UC_MIPS_REG_AT) == 0x234
    check effect(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_LITTLE_ENDIAN, code,
                 UC_MIPS_REG_V0) == 0

  modeTest "MIPS: register width", UC_ARCH_MIPS, UC_MODE_MIPS64:
    # 00 21 08 2d is `daddu $at, $at, $at`, which only a 64-bit MIPS has.
    const code = "\x00\x21\x08\x2d"
    check effect(UC_ARCH_MIPS, UC_MODE_MIPS64 or UC_MODE_BIG_ENDIAN, code, UC_MIPS_REG_AT,
                 0x8000_0000'u64) == 0x1_0000_0000'u64
    expect UnicornError:
      discard effect(UC_ARCH_MIPS, UC_MODE_MIPS32 or UC_MODE_BIG_ENDIAN, code, UC_MIPS_REG_AT,
                     0x8000_0000'u64)

  modeTest "RISC-V: register width", UC_ARCH_RISCV, UC_MODE_RISCV32:
    # 93 85 05 02: addi a1, a1, 0x20; a 32-bit register wraps
    const code = "\x93\x85\x05\x02"
    check effect(UC_ARCH_RISCV, UC_MODE_RISCV32, code, UC_RISCV_REG_A1, 0xffff_fff0'u64) == 0x10
    check effect(UC_ARCH_RISCV, UC_MODE_RISCV64, code, UC_RISCV_REG_A1, 0xffff_fff0'u64) ==
      0x1_0000_0010'u64

suite "what the library was built with":
  test "an architecture it lacks is refused with UC_ERR_ARCH":
    var lacking = 0
    for arch in [UC_ARCH_ARM, UC_ARCH_ARM64, UC_ARCH_MIPS, UC_ARCH_X86, UC_ARCH_PPC,
                 UC_ARCH_SPARC, UC_ARCH_M68K, UC_ARCH_RISCV, UC_ARCH_S390X, UC_ARCH_TRICORE]:
      if uc_arch_supported(arch): continue
      inc lacking
      checkpoint $arch
      try:
        discard initUnicorn(arch, UC_MODE_LITTLE_ENDIAN)
        fail()
      except UnicornError as e:
        check e.code == UC_ERR_ARCH
    if lacking == 0: skip()
