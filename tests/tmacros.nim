## The hand-written macros in `libunicorn/cmacros.nim` and the build-time
## header check against the installed Unicorn headers and library:
##
## * the constants, the `UC_CTL*` encoders and the control code of every
##   `uc_ctl_*` proc equal what the C compiler computes from the headers;
## * every macro the headers define has a Nim counterpart;
## * `private/abi_check.c` accepts the installed headers and those of a later
##   Unicorn 2, and refuses another version, layout or numbering;
## * every `uc_ctl_*` proc does what its name says.
##
## Needs `cc` and pkg-config when it runs.

import std/[macros, os, osproc, sets, strutils, tables, tempfiles, unittest]
import libunicorn/raw

const
  handWritten = staticRead("../src/libunicorn/cmacros.nim")
  generated = staticRead("../src/libunicorn/gen_v2.nim")
  targetFlags = when defined(i386): "-m32 " else: ""
    ## The headers are examined for the target this test is built for.

  # Not part of the API: include guards and compiler attributes.
  notApi = ["UNICORN_ENGINE_H", "UNICORN_M68K_H", "UNICORN_X86_H", "UNICORN_ARM_H",
            "UNICORN_ARM64_H", "UNICORN_MIPS_H", "UNICORN_SPARC_H", "UNICORN_PPC_H",
            "UNICORN_RISCV_H", "UNICORN_S390X_H", "UNICORN_TRICORE_H",
            "DEFAULT_VISIBILITY", "UNICORN_EXPORT", "UNICORN_DEPRECATED"]

  # Uses of the encoders, written so that they read the same in C and in Nim.
  encoderUses = ["UC_CTL(UC_CTL_UC_MODE, 1, UC_CTL_IO_READ)",
                 "UC_CTL(UC_CTL_TB_REQUEST_CACHE, 2, UC_CTL_IO_READ_WRITE)",
                 "UC_CTL(UC_CTL_UC_ARCH, 3, UC_CTL_IO_NONE)",
                 "UC_CTL_NONE(UC_CTL_TB_FLUSH, 0)",
                 "UC_CTL_READ(UC_CTL_UC_EXITS, 2)",
                 "UC_CTL_WRITE(UC_CTL_CPU_MODEL, 1)",
                 "UC_CTL_READ_WRITE(UC_CTL_TB_REQUEST_CACHE, 2)"]

  # The `uc_ctl_*` macros Unicorn 2.1.0 added; the 2.0.x headers lack them.
  # `uc_ctl_flush_tb` is one of them by name only: 2.0.x has the control, as
  # `uc_ctl_flush_tlb`.
  addedIn21 = ["uc_ctl_flush_tb", "uc_ctl_tlb_mode", "uc_ctl_get_tcg_buffer_size",
               "uc_ctl_set_tcg_buffer_size", "uc_ctl_context_mode"]

# --- the Nim side, collected at compile time -------------------------------

func exportedName(line: string): string =
  ## The name a declaration line exports, if it is one.
  var decl = line.strip
  for keyword in ["const ", "let ", "func ", "proc ", "template "]:
    if decl.startsWith(keyword):
      decl = decl[keyword.len .. ^1]
      break
  let star = decl.find('*')
  if star <= 0: return ""
  for c in decl[0 ..< star]:
    if c notin IdentChars: return ""
  decl[0 ..< star]

macro nimConstants(): untyped =
  ## Name and value of every exported constant in `cmacros.nim`.
  result = newStmtList()
  let table = genSym(nskVar, "values")
  result.add quote do:
    var `table`: Table[string, uint64]
  for line in handWritten.splitLines:
    let name = exportedName(line)
    if name.len == 0 or not line.startsWith("  ") or " = " notin line or line.startsWith("   "):
      continue
    let value = ident(name)
    result.add quote do:
      `table`[`name`] = uint64(`value`)
  result.add table

macro nimControlCodes(): untyped =
  ## The control code each `uc_ctl_*` proc in `cmacros.nim` passes to `uc_ctl`,
  ## taken from its source: the `UC_CTL_READ(...)` (or `_WRITE`, ...) in the
  ## call. Overloads that only convert their argument have none of their own.
  result = newStmtList()
  let table = genSym(nskVar, "codes")
  result.add quote do:
    var `table`: Table[string, uint32]
  var current = ""
  var procs, found: seq[string]
  for line in handWritten.splitLines:
    let decl = line.strip
    if decl.startsWith("proc uc_ctl_"):
      current = exportedName(line)
      if current notin procs: procs.add current
    let call = decl.find("uc_ctl(uc, UC_CTL_")
    if call >= 0 and current.len > 0 and not decl.startsWith("proc "):
      let start = call + len("uc_ctl(uc, ")
      let code = parseExpr(decl[start .. decl.find(')', start)])
      let name = current
      found.add name
      result.add quote do:
        `table`[`name`] = cast[uint32](`code`)
  for name in procs:
    if name notin found: error("no control code found for " & name)
  result.add table

macro declaredNames(): untyped =
  ## Every name `cmacros.nim` or the generated module exports that is in fact
  ## declared in this build.
  result = newStmtList()
  let names = genSym(nskVar, "names")
  result.add quote do:
    var `names`: HashSet[string]
  var seen: seq[string]
  for source in [handWritten, generated]:
    for line in source.splitLines:
      let name = exportedName(line)
      if name.len == 0 or name in seen: continue
      if not (name.startsWith("UC_") or name.startsWith("uc_ctl")): continue
      seen.add name
      let symbol = ident(name)
      result.add quote do:
        when declared(`symbol`): `names`.incl `name`
  result.add names

macro nimEncoderValues(): untyped =
  ## `encoderUses` evaluated as Nim.
  result = newNimNode(nnkBracket)
  for use in encoderUses:
    let call = parseExpr(use)
    result.add quote do: cast[uint32](`call`)

# --- the C side, from the installed headers at run time --------------------

type
  Define = object
    name: string
    params: int  ## -1 for an object-like macro

proc pkgConfig(query: string): string =
  let (output, exitCode) = execCmdEx("pkg-config " & query & " unicorn")
  doAssert exitCode == 0, output
  output.strip

proc headerDefines(): seq[Define] =
  ## Every macro the Unicorn headers define, apart from `platform.h` (compiler
  ## plumbing) and what is not API.
  let dir = pkgConfig("--variable=includedir") / "unicorn"
  for file in walkFiles(dir / "*.h"):
    if file.extractFilename == "platform.h": continue
    for line in lines(file):
      let text = line.strip
      if not text.startsWith("#define "): continue
      var rest = text[len("#define ") .. ^1].strip
      var name = ""
      for c in rest:
        if c notin IdentChars: break
        name.add c
      if name in notApi: continue
      var define = Define(name: name, params: -1)
      rest = rest[name.len .. ^1]
      if rest.startsWith("("):  # a parameter list follows the name directly
        define.params = rest[1 ..< rest.find(')')].split(',').len
      var known = false
      for other in result:
        if other.name == name: known = true
      if not known: result.add define

proc cValues(defines: seq[Define]): Table[string, uint64] =
  ## What the C compiler makes of every object-like macro, of the control code
  ## in every `uc_ctl_*` macro, and of `encoderUses` and `UC_MAKE_VERSION`.
  let dir = createTempDir("libunicorn_macros_", "")
  defer: removeDir(dir)
  var source = "#include <stdio.h>\n#include <unicorn/unicorn.h>\n" &
    "/* After the header: every uc_ctl_* macro now evaluates to its control code. */\n" &
    "#define uc_ctl(uc, code, ...) ((unsigned)(code))\n" &
    "#define SHOW(name, value) printf(\"%s|%llu\\n\", name, (unsigned long long)(value))\n" &
    "int main(void) {\n"
  for define in defines:
    if define.params < 0:
      source.add "  SHOW(\"" & define.name & "\", " & define.name & ");\n"
    elif define.name.startsWith("uc_ctl_"):
      var args = newSeq[string](define.params)
      for arg in args.mitems: arg = "0"
      source.add "  SHOW(\"" & define.name & "\", " & define.name & "(" & args.join(", ") & "));\n"
  for use in encoderUses:
    source.add "  SHOW(\"" & use & "\", " & use & ");\n"
  source.add "  SHOW(\"UC_MAKE_VERSION(2, 1)\", UC_MAKE_VERSION(2, 1));\n"
  source.add "  return 0;\n}\n"
  writeFile(dir / "macros.c", source)
  let (log, exitCode) = execCmdEx("cc " & targetFlags & pkgConfig("--cflags") & " -o " &
                                  quoteShell(dir / "macros") & " " & quoteShell(dir / "macros.c"))
  doAssert exitCode == 0, log
  for line in execCmdEx(quoteShell(dir / "macros")).output.splitLines:
    let parts = line.split('|')
    if parts.len == 2: result[parts[0]] = parseBiggestUInt(parts[1])

suite "macros against the installed headers":
  let
    defines = headerDefines()
    c = cValues(defines)
    headerVersion = (int(c.getOrDefault("UC_API_MAJOR")), int(c.getOrDefault("UC_API_MINOR")),
                     int(c.getOrDefault("UC_API_PATCH")))

  test "the headers are the ones this build is against":
    require defines.len > 40
    # The version of the build is pkg-config's. Two releases install a
    # `unicorn.pc` one patch level behind their `unicorn.h`: 2.0.1 (says 2.0.0)
    # and 2.1.2 (says 2.1.1).
    if libVersion == (2, 0, 0) or libVersion == (2, 1, 1):
      check headerVersion == libVersion or
        headerVersion == (libVersion[0], libVersion[1], libVersion[2] + 1)
    else:
      check headerVersion == libVersion

  test "hand-written constants equal the header's":
    let nim = nimConstants()
    check nim.len == 8
    for name, value in nim:
      checkpoint name
      check name in c  # nothing the headers do not define
      if name in c: check c[name] == value

  test "the UC_CTL encoders compute what the C macros do":
    let nim = nimEncoderValues()
    for i, use in encoderUses:
      checkpoint use
      check c[use] == nim[i]

  test "UC_MAKE_VERSION is the definition that matches uc_version":
    if headerVersion >= (2, 1, 0):
      check c["UC_MAKE_VERSION(2, 1)"] == UC_MAKE_VERSION(2, 1)
    else:
      # The macro of the 2.0.x headers computes something uc_version never
      # returns; the Nim one is the corrected definition of 2.1.
      check c["UC_MAKE_VERSION(2, 1)"] == (2'u64 shl 8) + 1
    check UC_MAKE_VERSION(2, 1) == 0x02010000'u32
    var major, minor: cuint
    let combined = uc_version(addr major, addr minor)
    check (combined and 0xffff0000'u32) == UC_MAKE_VERSION(int(major), int(minor))

  test "every uc_ctl_* proc uses the control code of its macro":
    let nim = nimControlCodes()
    check nim.len == 20
    var compared = 0
    for name, code in nim:
      checkpoint name
      if name == "uc_ctl_flush_tlb" and headerVersion < (2, 1, 0):
        # In the 2.0.x headers this name flushes the translated code, which is
        # uc_ctl_flush_tb here; the control for the TLB came with 2.1.0.
        check c[name] == nim["uc_ctl_flush_tb"]
        check code == cast[uint32](UC_CTL_WRITE(UC_CTL_TLB_FLUSH, 0))
        inc compared
      elif name in c:
        check c[name] == code
        inc compared
      else:
        check headerVersion < (2, 1, 0)
        check name in addedIn21
    check compared == (if headerVersion >= (2, 1, 0): 20 else: 15)

  test "every macro of the headers has a Nim counterpart":
    let nim = declaredNames()
    require nim.len > 50
    var missing: seq[string]
    for define in defines:
      if define.name notin nim: missing.add define.name
    check missing.len == 0
    if missing.len > 0: echo "not in the bindings: ", missing.join(", ")

# --- the build-time header check -------------------------------------------

const abiCheckSource = staticRead("../src/libunicorn/private/abi_check.c")

type Assumed = object
  ## What `raw.nim` tells `abi_check.c` about the build and the bindings.
  version: (int, int, int)
  sizeofTb, errException: int

proc assumed(version: (int, int, int)): Assumed =
  Assumed(version: version, sizeofTb: sizeof(uc_tb), errException: ord(UC_ERR_EXCEPTION))

proc flags(a: Assumed): string =
  ## The same macros as in the `compile` pragma of `raw.nim`.
  " -DLUN_LIB_MAJOR=" & $a.version[0] & " -DLUN_LIB_MINOR=" & $a.version[1] &
    " -DLUN_LIB_PATCH=" & $a.version[2] &
    " -DLUN_SIZEOF_MEM_REGION=" & $sizeof(uc_mem_region) &
    " -DLUN_SIZEOF_X86_MMR=" & $sizeof(uc_x86_mmr) &
    " -DLUN_SIZEOF_X86_MSR=" & $sizeof(uc_x86_msr) &
    " -DLUN_SIZEOF_ARM_CP_REG=" & $sizeof(uc_arm_cp_reg) &
    " -DLUN_SIZEOF_ARM64_CP_REG=" & $sizeof(uc_arm64_cp_reg) &
    " -DLUN_SIZEOF_TB=" & $a.sizeofTb &
    " -DLUN_SIZEOF_TLB_ENTRY=" & $sizeof(uc_tlb_entry) &
    " -DLUN_OFFSETOF_TLB_ENTRY_PERMS=" & $offsetOf(uc_tlb_entry, perms) &
    " -DLUN_ERR_EXCEPTION=" & $a.errException &
    " -DLUN_HOOK_TCG_OPCODE=" & $uint32(UC_HOOK_TCG_OPCODE) &
    " -DLUN_MEM_READ_AFTER=" & $ord(UC_MEM_READ_AFTER)

proc headerCopy(dir: string; patch = -1; moreRegisters = false): string =
  ## A copy of the installed headers under `dir`, optionally with another
  ## patch level, or with a register more for x86 and for ARM64 as a later
  ## release would have. Returns the include directory.
  result = dir / ("include_" & $patch & "_" & $moreRegisters)
  createDir(result / "unicorn")
  for file in walkFiles(pkgConfig("--variable=includedir") / "unicorn" / "*.h"):
    var text = readFile(file)
    let name = file.extractFilename
    if patch >= 0 and name == "unicorn.h":
      var lines = text.splitLines
      for line in lines.mitems:
        if line.startsWith("#define UC_API_PATCH "): line = "#define UC_API_PATCH " & $patch
      text = lines.join("\n")
    if moreRegisters and name == "x86.h":
      doAssert text.count("    UC_X86_REG_ENDING") == 1
      text = text.replace("    UC_X86_REG_ENDING", "    UC_X86_REG_LATER,\n    UC_X86_REG_ENDING")
    if moreRegisters and name == "arm64.h":
      doAssert text.count("    UC_ARM64_REG_ENDING") == 1
      text = text.replace("    UC_ARM64_REG_ENDING",
                          "    UC_ARM64_REG_LATER,\n    UC_ARM64_REG_ENDING")
    writeFile(result / "unicorn" / name, text)

proc headerCheck(dir, includeDir: string; a: Assumed): tuple[accepted: bool; log: string] =
  ## Compiles `abi_check.c` the way the build does.
  writeFile(dir / "abi_check.c", abiCheckSource)
  let (log, exitCode) = execCmdEx("cc -c " & targetFlags & "-I" & quoteShell(includeDir) &
                                  a.flags & " -o " & quoteShell(dir / "abi_check.o") & " " &
                                  quoteShell(dir / "abi_check.c"))
  (exitCode == 0, log)

suite "header check":
  let
    dir = createTempDir("libunicorn_abi_", "")
    installed = pkgConfig("--variable=includedir")
    header = block:
      let c = cValues(headerDefines())
      (int(c["UC_API_MAJOR"]), int(c["UC_API_MINOR"]), int(c["UC_API_PATCH"]))

  test "the installed headers are accepted":
    let (accepted, log) = headerCheck(dir, installed, assumed(header))
    checkpoint log
    check accepted

  test "headers of another version are refused":
    for other in [(header[0], header[1], header[2] + 5), (header[0], header[1] + 1, header[2]),
                  (header[0] + 1, header[1], header[2])]:
      let (accepted, log) = headerCheck(dir, installed, assumed(other))
      checkpoint $other
      check not accepted
      check "libunicorn: unicorn.h is not the Unicorn version this build was configured for" in log

  test "a pkg-config file one patch level behind is accepted for 2.0.1 and 2.1.2 only":
    # Those two releases say 2.0.0 and 2.1.1 in their `unicorn.pc`. The
    # headers here are the installed ones with another patch level, so each
    # minor version can try its own pair.
    let oneBehind = (if header[1] == 0: 1 elif header[1] == 1: 2 else: -1)
    for patch in 1 .. 4:
      let
        includeDir = headerCopy(dir, patch = patch)
        (accepted, log) = headerCheck(dir, includeDir, assumed((header[0], header[1], patch - 1)))
      checkpoint "headers " & $header[0] & "." & $header[1] & "." & $patch & ": " & log
      check accepted == (patch == oneBehind)
      # Never the other way round.
      check not headerCheck(dir, includeDir, assumed((header[0], header[1], patch + 1))).accepted

  test "headers with more registers, as of a later Unicorn 2, are accepted":
    let (accepted, log) = headerCheck(dir, headerCopy(dir, moreRegisters = true), assumed(header))
    checkpoint log
    check accepted

  test "another struct layout or enum numbering is refused":
    var wrong = assumed(header)
    wrong.sizeofTb += 8
    var (accepted, log) = headerCheck(dir, installed, wrong)
    check not accepted
    check "libunicorn: uc_tb layout differs from the Nim bindings" in log
    wrong = assumed(header)
    wrong.errException += 1
    (accepted, log) = headerCheck(dir, installed, wrong)
    check not accepted
    check "libunicorn: enum numbering differs from the Nim bindings" in log

  removeDir(dir)

# --- the uc_ctl_* procs against the library --------------------------------

type Seen = object
  calls: int
  timeout: uint64
  errors: int

proc onCode(uc: ptr uc_engine; address: uint64; size: uint32; user_data: pointer) {.cdecl.} =
  let seen = cast[ptr Seen](user_data)
  inc seen.calls
  if uc_ctl_get_timeout(uc, addr seen.timeout) != UC_ERR_OK: inc seen.errors

proc onTlbFill(uc: ptr uc_engine; vaddr: uint64; kind: uc_mem_type; entry: ptr uc_tlb_entry;
               user_data: pointer): bool {.cdecl.} =
  inc cast[ptr Seen](user_data).calls
  entry.paddr = vaddr and not 0xfff'u64
  entry.perms = UC_PROT_ALL
  true

proc rax(uc: ptr uc_engine): uint64 =
  doAssert uc_reg_read(uc, UC_X86_REG_RAX, addr result) == UC_ERR_OK

const
  codeAddress = 0x1000'u64
  setAndHalt = [0xb8'u8, 0x01, 0x00, 0x00, 0x00,  # mov eax, 1
                0xf4]                             # hlt, which ends the emulation
  nops = [0x90'u8, 0x90, 0x90, 0x90]

suite "uc_ctl procs":
  var uc: ptr uc_engine

  setup:
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr uc) == UC_ERR_OK

  teardown:
    check uc_close(uc) == UC_ERR_OK

  test "uc_ctl_get_mode and uc_ctl_get_arch":
    var number: cint
    check uc_ctl_get_mode(uc, addr number) == UC_ERR_OK
    check number == cint(UC_MODE_64)
    var mode: uc_mode
    check uc_ctl_get_mode(uc, mode) == UC_ERR_OK
    check mode == UC_MODE_64
    check uc_ctl_get_arch(uc, addr number) == UC_ERR_OK
    check number == cint(ord(UC_ARCH_X86))
    var arch: uc_arch
    check uc_ctl_get_arch(uc, arch) == UC_ERR_OK
    check arch == UC_ARCH_X86

  test "uc_ctl_get_page_size":
    var size: uint32
    check uc_ctl_get_page_size(uc, addr size) == UC_ERR_OK
    check size == 4096

  test "uc_ctl_set_page_size":
    check uc_ctl_set_page_size(uc, 8192) == UC_ERR_ARG  # x86 pages have one size
    if not uc_arch_supported(UC_ARCH_ARM):
      skip()
    else:
      var arm: ptr uc_engine
      require uc_open(UC_ARCH_ARM, UC_MODE_ARM, addr arm) == UC_ERR_OK
      check uc_ctl_set_page_size(arm, 3000) == UC_ERR_ARG  # not a power of two
      check uc_ctl_set_page_size(arm, 65536) == UC_ERR_OK
      var size: uint32
      check uc_ctl_get_page_size(arm, addr size) == UC_ERR_OK
      let v = uc_version()
      if (v.major, v.minor, v.patch) >= (2, 1, 2):
        check size == 65536
        check uc_mem_map(arm, 0x10000, 0x1000, UC_PROT_ALL) == UC_ERR_ARG  # less than a page
        check uc_mem_map(arm, 0x10000, 0x10000, UC_PROT_ALL) == UC_ERR_OK
      else:
        # Unicorn before 2.1.2 counts one bit too many and sets twice the size.
        check size == 131072
      # Too late once the engine is in use.
      check uc_ctl_set_page_size(arm, 4096) == UC_ERR_ARG
      check uc_close(arm) == UC_ERR_OK

  test "uc_ctl_get_timeout":
    var seen: Seen
    var hook: uc_hook
    var timeout = 99'u64
    check uc_ctl_get_timeout(uc, addr timeout) == UC_ERR_OK
    check timeout == 0  # nothing has run yet
    require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    require uc_mem_write(uc, codeAddress, nops) == UC_ERR_OK
    require uc_hook_add(uc, addr hook, UC_HOOK_CODE, onCode, addr seen, 1, 0) == UC_ERR_OK
    check uc_emu_start(uc, codeAddress, codeAddress + 2, 250 * UC_MILISECOND_SCALE, 0) == UC_ERR_OK
    check seen.calls == 2
    check seen.errors == 0
    # uc_emu_start takes microseconds; the control reports nanoseconds.
    check seen.timeout == 250_000_000'u64

  test "uc_ctl_exits_enable, uc_ctl_set_exits, uc_ctl_get_exits_cnt, uc_ctl_get_exits":
    var count: csize_t
    # Exits have to be enabled first.
    check uc_ctl_get_exits_cnt(uc, addr count) == UC_ERR_ARG
    check uc_ctl_set_exits(uc, [0x1002'u64]) == UC_ERR_ARG
    check uc_ctl_exits_enable(uc) == UC_ERR_OK
    check uc_ctl_get_exits_cnt(uc, addr count) == UC_ERR_OK
    check count == 0
    var exits = [0x2000'u64, 0x1002]
    check uc_ctl_set_exits(uc, addr exits[0], csize_t(exits.len)) == UC_ERR_OK
    check uc_ctl_get_exits_cnt(uc, addr count) == UC_ERR_OK
    check count == 2
    var back: array[3, uint64]
    check uc_ctl_get_exits(uc, addr back[0], csize_t(back.len)) == UC_ERR_OK
    check back == [0x1002'u64, 0x2000, 0]
    var one: array[1, uint64]
    check uc_ctl_get_exits(uc, one) == UC_ERR_ARG  # no room for two
    # The run ends at an exit; `until` (here 0) no longer counts.
    require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    require uc_mem_write(uc, codeAddress, nops) == UC_ERR_OK
    check uc_emu_start(uc, codeAddress, 0, 0, 0) == UC_ERR_OK
    var rip: uint64
    check uc_reg_read(uc, UC_X86_REG_RIP, addr rip) == UC_ERR_OK
    check rip == 0x1002
    # The same with Nim arrays.
    check uc_ctl_set_exits(uc, [0x1003'u64]) == UC_ERR_OK
    var again: array[1, uint64]
    check uc_ctl_get_exits(uc, again) == UC_ERR_OK
    check again == [0x1003'u64]
    check uc_emu_start(uc, codeAddress, 0, 0, 0) == UC_ERR_OK
    check uc_reg_read(uc, UC_X86_REG_RIP, addr rip) == UC_ERR_OK
    check rip == 0x1003
    check uc_ctl_set_exits(uc, newSeq[uint64]()) == UC_ERR_OK
    check uc_ctl_get_exits_cnt(uc, addr count) == UC_ERR_OK
    check count == 0
    var none: seq[uint64]
    check uc_ctl_get_exits(uc, none) == UC_ERR_OK

  test "uc_ctl_exits_disable":
    require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    require uc_mem_write(uc, codeAddress, nops) == UC_ERR_OK
    check uc_ctl_exits_enable(uc) == UC_ERR_OK
    check uc_ctl_set_exits(uc, [0x1001'u64]) == UC_ERR_OK
    check uc_ctl_exits_disable(uc) == UC_ERR_OK
    var count: csize_t
    check uc_ctl_get_exits_cnt(uc, addr count) == UC_ERR_ARG
    # `until` counts again and the exit at 0x1001 does not.
    check uc_emu_start(uc, codeAddress, codeAddress + 3, 0, 0) == UC_ERR_OK
    var rip: uint64
    check uc_reg_read(uc, UC_X86_REG_RIP, addr rip) == UC_ERR_OK
    check rip == 0x1003

  test "uc_ctl_get_cpu_model and uc_ctl_set_cpu_model":
    check uc_ctl_set_cpu_model(uc, UC_CPU_X86_PENTIUM) == UC_ERR_OK
    var model: cint
    check uc_ctl_get_cpu_model(uc, addr model) == UC_ERR_OK
    check model == cint(ord(UC_CPU_X86_PENTIUM))
    # Reading it put the engine to use: too late to change now.
    check uc_ctl_set_cpu_model(uc, UC_CPU_X86_HASWELL) == UC_ERR_ARG
    var other: ptr uc_engine
    require uc_open(UC_ARCH_X86, UC_MODE_64, addr other) == UC_ERR_OK
    check uc_ctl_set_cpu_model(other, cint(9999)) == UC_ERR_ARG
    # Model 0, the first of every list: Unicorn 2.0.0 refuses it.
    let v = uc_version()
    check uc_ctl_set_cpu_model(other, UC_CPU_X86_QEMU64) ==
      (if (v.major, v.minor, v.patch) == (2, 0, 0): UC_ERR_ARG else: UC_ERR_OK)
    check uc_ctl_set_cpu_model(other, cint(ord(UC_CPU_X86_CORE2DUO))) == UC_ERR_OK
    check uc_ctl_get_cpu_model(other, addr model) == UC_ERR_OK
    check model == cint(ord(UC_CPU_X86_CORE2DUO))
    check uc_close(other) == UC_ERR_OK

  test "uc_ctl_request_cache":
    require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
    require uc_mem_write(uc, codeAddress, setAndHalt) == UC_ERR_OK
    var tb: uc_tb
    check uc_ctl_request_cache(uc, codeAddress, addr tb) == UC_ERR_OK
    check tb.pc == codeAddress
    check tb.icount == 2
    check tb.size == 6
    check uc_ctl_request_cache(uc, codeAddress + 5, nil) == UC_ERR_OK

  test "uc_ctl_remove_cache":
    # Memory of our own, so that it can change behind Unicorn's back.
    var host = newSeq[byte](0x1000)
    for i, b in setAndHalt: host[i] = b
    require uc_mem_map_ptr(uc, codeAddress, 0x1000, UC_PROT_ALL, addr host[0]) == UC_ERR_OK
    check uc_ctl_request_cache(uc, codeAddress, nil) == UC_ERR_OK
    host[1] = 2  # now `mov eax, 2`
    check uc_emu_start(uc, codeAddress, codeAddress + 0x800, 0, 0) == UC_ERR_OK
    check uc.rax == 1  # the translation made before the change
    check uc_ctl_remove_cache(uc, codeAddress, codeAddress) == UC_ERR_ARG  # an empty range
    check uc_ctl_remove_cache(uc, codeAddress, codeAddress + 6) == UC_ERR_OK
    check uc_emu_start(uc, codeAddress, codeAddress + 0x800, 0, 0) == UC_ERR_OK
    check uc.rax == 2  # translated again

  test "uc_ctl_flush_tb":
    var host = newSeq[byte](0x1000)
    for i, b in setAndHalt: host[i] = b
    require uc_mem_map_ptr(uc, codeAddress, 0x1000, UC_PROT_ALL, addr host[0]) == UC_ERR_OK
    check uc_ctl_request_cache(uc, codeAddress, nil) == UC_ERR_OK
    host[1] = 2
    check uc_emu_start(uc, codeAddress, codeAddress + 0x800, 0, 0) == UC_ERR_OK
    check uc.rax == 1
    check uc_ctl_flush_tb(uc) == UC_ERR_OK
    check uc_emu_start(uc, codeAddress, codeAddress + 0x800, 0, 0) == UC_ERR_OK
    check uc.rax == 2

  test "uc_ctl_tlb_mode and uc_ctl_flush_tlb (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      var seen: Seen
      var hook: uc_hook
      require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
      require uc_mem_write(uc, codeAddress, nops) == UC_ERR_OK
      require uc_hook_add(uc, addr hook, UC_HOOK_TLB_FILL, onTlbFill, addr seen, 1, 0) == UC_ERR_OK
      check uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL) == UC_ERR_OK
      check uc_emu_start(uc, codeAddress, codeAddress + 2, 0, 0) == UC_ERR_OK
      check seen.calls == 1
      # The answer is cached in the TLB ...
      check uc_emu_start(uc, codeAddress, codeAddress + 2, 0, 0) == UC_ERR_OK
      check seen.calls == 1
      # ... until that is emptied.
      check uc_ctl_flush_tlb(uc) == UC_ERR_OK
      check uc_emu_start(uc, codeAddress, codeAddress + 2, 0, 0) == UC_ERR_OK
      check seen.calls == 2
      check uc_ctl_tlb_mode(uc, cint(7)) == UC_ERR_ARG
      # With the CPU's own translation, which is the default, the hook is not
      # asked.
      var other: ptr uc_engine
      var unasked: Seen
      require uc_open(UC_ARCH_X86, UC_MODE_64, addr other) == UC_ERR_OK
      require uc_mem_map(other, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
      require uc_mem_write(other, codeAddress, nops) == UC_ERR_OK
      require uc_hook_add(other, addr hook, UC_HOOK_TLB_FILL, onTlbFill, addr unasked,
                          1, 0) == UC_ERR_OK
      check uc_ctl_tlb_mode(other, cint(ord(UC_TLB_CPU))) == UC_ERR_OK
      check uc_emu_start(other, codeAddress, codeAddress + 2, 0, 0) == UC_ERR_OK
      check unasked.calls == 0
      check uc_close(other) == UC_ERR_OK
    else:
      check not compiles(uc_ctl_tlb_mode(uc, UC_TLB_VIRTUAL))
      check not compiles(uc_ctl_flush_tlb(uc))

  test "uc_ctl_get_tcg_buffer_size and uc_ctl_set_tcg_buffer_size (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      const wanted = 64'u32 * 1024 * 1024
      check uc_ctl_set_tcg_buffer_size(uc, wanted) == UC_ERR_OK
      var size: uint32
      check uc_ctl_get_tcg_buffer_size(uc, addr size) == UC_ERR_OK
      check size == wanted
      require uc_mem_map(uc, codeAddress, 0x1000, UC_PROT_ALL) == UC_ERR_OK
      require uc_mem_write(uc, codeAddress, setAndHalt) == UC_ERR_OK
      check uc_emu_start(uc, codeAddress, codeAddress + 0x800, 0, 0) == UC_ERR_OK
      check uc.rax == 1
    else:
      var size {.used.}: uint32
      check not compiles(uc_ctl_get_tcg_buffer_size(uc, addr size))
      check not compiles(uc_ctl_set_tcg_buffer_size(uc, 1'u32))

  test "uc_ctl_context_mode (Unicorn 2.1)":
    when libVersion >= (2, 1, 0):
      require uc_mem_map(uc, 0x4000, 0x1000, UC_PROT_ALL) == UC_ERR_OK
      var ctx: ptr uc_context
      var memory: array[1, byte]
      var value = 1'u64

      template saveChangeRestore() =
        ## Saves with register and memory holding 1, sets both to 2, restores.
        value = 1
        require uc_reg_write(uc, UC_X86_REG_RAX, addr value) == UC_ERR_OK
        require uc_mem_write(uc, 0x4000, [1'u8]) == UC_ERR_OK
        require uc_context_alloc(uc, addr ctx) == UC_ERR_OK
        require uc_context_save(uc, ctx) == UC_ERR_OK
        value = 2
        require uc_reg_write(uc, UC_X86_REG_RAX, addr value) == UC_ERR_OK
        require uc_mem_write(uc, 0x4000, [2'u8]) == UC_ERR_OK
        require uc_context_restore(uc, ctx) == UC_ERR_OK
        require uc_context_free(ctx) == UC_ERR_OK
        require uc_mem_read(uc, 0x4000, memory) == UC_ERR_OK

      saveChangeRestore()  # the default: registers only
      check uc.rax == 1
      check memory[0] == 2
      check uc_ctl_context_mode(uc, UC_CTL_CONTEXT_MEMORY) == UC_ERR_OK
      saveChangeRestore()
      check uc.rax == 2
      check memory[0] == 1
      check uc_ctl_context_mode(uc, cint(ord(UC_CTL_CONTEXT_CPU) or
                                         ord(UC_CTL_CONTEXT_MEMORY))) == UC_ERR_OK
      saveChangeRestore()
      check uc.rax == 1
      check memory[0] == 1
      check uc_ctl_context_mode(uc, UC_CTL_CONTEXT_CPU) == UC_ERR_OK
      saveChangeRestore()
      check uc.rax == 1
      check memory[0] == 2
    else:
      check not compiles(uc_ctl_context_mode(uc, UC_CTL_CONTEXT_CPU))

  test "uc_ctl itself, for a control without a proc":
    var size: uint32
    check uc_ctl(uc, UC_CTL_READ(UC_CTL_UC_PAGE_SIZE, 1), addr size) == UC_ERR_OK
    check size == 4096
    # The direction is part of the code: the mode cannot be written.
    check uc_ctl(uc, UC_CTL_WRITE(UC_CTL_UC_MODE, 1), cint(0)) == UC_ERR_ARG
    check uc_ctl(uc, UC_CTL_NONE(UC_CTL_TB_FLUSH, 0)) == UC_ERR_ARG
    check uc_ctl(uc, cast[uc_control_type](999)) == UC_ERR_ARG
