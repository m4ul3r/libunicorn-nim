## The guards against a Unicorn the build is not for. Each case builds a small
## program in a temporary directory with a controlled environment and checks
## that the build, or the program, stops with the right diagnosis.
##
## Nothing of the library is imported here: the probes are separate programs,
## so this file builds with any memory manager.

import std/[os, osproc, strtabs, strutils, tempfiles, unittest]

const
  nimExe = getCurrentCompilerExe()
  srcDir = currentSourcePath().parentDir.parentDir / "src"

when defined(posix):
  let
    work = createTempDir("libunicorn_guards_", "")
    probe = work / "probe.nim"
    fakeBin = work / "bin"
  createDir(fakeBin)
  writeFile(probe, """
import libunicorn/raw
var uc = cast[ptr uc_engine](1)
echo uc_open(UC_ARCH_X86, UC_MODE_64, addr uc), " nil=", uc == nil
""")

  proc fakePkgConfig(script: string) =
    ## Makes a `pkg-config` out of `script` for builds with `fake = true`.
    let path = fakeBin / "pkg-config"
    writeFile(path, "#!/bin/sh\n" & script & "\n")
    setFilePermissions(path, {fpUserRead, fpUserWrite, fpUserExec})

  proc fakeVersion(version: string) =
    fakePkgConfig("case \"$1\" in --modversion) echo " & version &
                  ";; --libs) echo -lunicorn;; --cflags) echo;; esac")

  proc pkgConfig(query: string): string =
    ## What the real pkg-config says about the installed Unicorn.
    let (output, exitCode) = execCmdEx("pkg-config " & query & " unicorn")
    doAssert exitCode == 0, output
    output.strip

  type Stage = enum
    nimOnly  ## stop after Nim's own checks
    compileC ## also run the C compiler
    link     ## produce `work/probe`

  proc build(args: openArray[string] = []; fake = true; stage = nimOnly;
             source = probe): tuple[output: string; ok: bool] =
    var cmd = quoteShellCommand([nimExe, "c", "--hints:off",
      (case stage
       of nimOnly: "--compileOnly"
       of compileC: "--noLinking"
       of link: "-o:" & work / "probe"),
      "--nimcache:" & work / "cache", "-p:" & srcDir])
    for arg in args: cmd.add " " & quoteShell(arg)
    cmd.add " " & quoteShell(source)
    let env = newStringTable(modeCaseSensitive)
    for key, value in envPairs(): env[key] = value
    if fake: env["PATH"] = fakeBin & PathSep & getEnv("PATH")
    # The probe's directory, not the one the test happens to run in.
    let (output, exitCode) = execCmdEx(cmd, env = env, workingDir = work)
    (output, exitCode == 0)

  proc refusal(args: openArray[string] = []; fake = true; stage = nimOnly;
               source = probe): string =
    ## The compiler output of a build that must fail.
    let (output, ok) = build(args, fake, stage, source)
    check not ok
    output

  proc accept(args: openArray[string] = []; fake = true; stage = nimOnly; source = probe) =
    ## A build that must succeed. Its failure ends the test with the compiler's
    ## output; `require` would end the program and leave the temporary
    ## directory behind.
    let (output, ok) = build(args, fake, stage, source)
    if not ok: raise newException(CatchableError, "the build failed:\n" & output)

  proc printed(args: openArray[string] = []): string =
    ## What the probe prints when built with `args` against the installed Unicorn.
    accept(args, fake = false, stage = link)
    execCmdEx(quoteShell(work / "probe")).output.strip

  proc doctoredHeaders(name, text: string): string =
    ## Compiler flags that put a `unicorn/unicorn.h` consisting of `text` in
    ## front of the installed headers.
    let dir = work / name
    createDir(dir / "unicorn")
    writeFile(dir / "unicorn" / "unicorn.h", text)
    "-d:unicornCflags=-I" & dir & " " & pkgConfig("--cflags")

  var releases = 0

  proc fakeRelease(pcVersion, headerVersion: string; before = ""; after = "") =
    ## Makes pkg-config report the installed Unicorn as `pcVersion`, with a
    ## `unicorn/unicorn.h` in front of its headers that says `headerVersion`.
    ## `before` and `after` are C text around the installed header.
    inc releases
    let
      dir = work / "release" & $releases # a directory of its own: no object file is reused
      version = headerVersion.split('.')
    createDir(dir / "unicorn")
    writeFile(dir / "unicorn" / "unicorn.h", before & """
#include_next <unicorn/unicorn.h>
#if UC_API_MINOR == 0
/* Every 2.1 header declares this, and the build-time check looks at it. */
typedef struct uc_tlb_entry { uint64_t paddr; uc_prot perms; } uc_tlb_entry;
#endif
#undef UC_API_MAJOR
#undef UC_API_MINOR
#undef UC_API_PATCH
#define UC_API_MAJOR $1
#define UC_API_MINOR $2
#define UC_API_PATCH $3
""" % version & after)
    fakePkgConfig("case \"$1\" in --modversion) echo " & pcVersion &
                  ";; --libs) echo '" & pkgConfig("--libs") &
                  "';; --cflags) echo '-I" & dir & " " & pkgConfig("--cflags") & "';; esac")

  suite "build-time guards":
    test "Unicorn 1 is refused":
      fakeVersion("1.0.3")
      check "Unicorn 1.0.3 is not supported. Bindings exist for Unicorn 2.0.x and 2.1.x." in
        refusal()

    test "a Unicorn newer than the bindings is refused":
      fakeVersion("3.0.0")
      check "Unicorn 3.0.0 is not supported" in refusal()

    test "a missing Unicorn is diagnosed with pkg-config's words and an install hint":
      fakePkgConfig("echo \"Package unicorn was not found in the pkg-config search path.\" >&2" &
                    "; exit 1")
      let output = refusal()
      check "libunicorn: `pkg-config --libs unicorn` failed:" in output
      check "Package unicorn was not found in the pkg-config search path." in output
      check "libunicorn-dev" in output
      check "-d:unicornLibs=\"-L<dir> -lunicorn\" -d:unicornVersion=<x.y.z>" in output

    test "explicit linker flags need the version":
      check "-d:unicornLibs also needs -d:unicornVersion=<x.y.z>" in
        refusal(["-d:unicornLibs=-lunicorn"])

    test "a version that contradicts pkg-config is refused":
      fakeVersion("2.0.1")
      let output = refusal(["-d:unicornVersion=2.1.4"])
      check "-d:unicornVersion=2.1.4 contradicts pkg-config, which reports Unicorn 2.0.1" in
        output
      check "pass -d:unicornLibs as well" in output

    test "headers of another version stop the C compiler":
      let flags = doctoredHeaders("other_version", """
#include_next <unicorn/unicorn.h>
#undef UC_API_PATCH
#define UC_API_PATCH 99
""")
      check "unicorn.h is not the Unicorn version this build was configured for" in
        refusal([flags], fake = false, stage = compileC)

    test "headers whose layout differs from the bindings stop the C compiler":
      # The same version number, a different `uc_mem_region`.
      let flags = doctoredHeaders("other_layout", """
#define uc_mem_region lun_real_uc_mem_region
#include_next <unicorn/unicorn.h>
#undef uc_mem_region
typedef struct { lun_real_uc_mem_region real; char grown[8]; } uc_mem_region;
""")
      check "uc_mem_region layout differs from the Nim bindings" in
        refusal([flags], fake = false, stage = compileC)

    test "a unicorn.pc one patch level behind unicorn.h is accepted for the releases that ship so":
      # Unicorn 2.0.1 installs a unicorn.pc that says 2.0.0, and Unicorn 2.1.2
      # one that says 2.1.1.
      for (pc, header) in [("2.0.0", "2.0.1"), ("2.1.1", "2.1.2")]:
        checkpoint "unicorn.pc " & pc & ", unicorn.h " & header
        fakeRelease(pc, header)
        accept(stage = compileC)

    test "any other difference between unicorn.pc and unicorn.h stops the C compiler":
      for (pc, header) in [("2.1.1", "2.1.3"), ("2.1.2", "2.1.1"), ("2.1.0", "2.1.1"),
                           ("2.0.1", "2.0.2"), ("2.0.0", "2.1.1")]:
        checkpoint "unicorn.pc " & pc & ", unicorn.h " & header
        fakeRelease(pc, header)
        check "unicorn.h is not the Unicorn version this build was configured for" in
          refusal(stage = compileC)

    # Headers of a later Unicorn 2: one register more than the installed ones
    # have, so one more than the bindings know when those are the newest.
    const
      oneRegisterMore = "#define UC_X86_REG_ENDING UC_X86_REG_LUN_ADDED, UC_X86_REG_ENDING\n"
      registerAdded = "#undef UC_X86_REG_ENDING\n" &
        "typedef char lun_added[UC_X86_REG_ENDING == UC_X86_REG_LUN_ADDED + 1 ? 1 : -1];\n"

    test "headers of a Unicorn newer than the bindings build, with a hint":
      fakeRelease("2.2.0", "2.2.0", before = oneRegisterMore, after = registerAdded)
      let (output, ok) = build(["--hints:on"], stage = compileC)
      checkpoint output
      check ok
      check "Unicorn 2.2.0 is newer than these bindings" in output

    test "such headers with another struct layout stop the C compiler":
      fakeRelease("2.2.0", "2.2.0",
        before = oneRegisterMore & "#define uc_mem_region lun_real_uc_mem_region\n",
        after = registerAdded & "#undef uc_mem_region\n" &
          "typedef struct { lun_real_uc_mem_region real; char grown[8]; } uc_mem_region;\n")
      check "uc_mem_region layout differs from the Nim bindings" in refusal(stage = compileC)

    test "a function newer than the library is refused with both versions":
      fakeVersion("2.0.1")
      let newer = work / "newer_probe.nim"
      writeFile(newer, """
import libunicorn/raw
var
  uc: ptr uc_engine
  value: uint64
  size = csize_t(sizeof(value))
echo uc_reg_read2(uc, UC_X86_REG_RAX, addr value, addr size)
""")
      check "uc_reg_read2 needs Unicorn 2.1.0 or later; this build is against Unicorn 2.0.1." in
        refusal(source = newer)
      # The same program is accepted once the library is new enough.
      fakeVersion("2.1.0")
      accept(source = newer)

    test "the C API builds with --mm:refc":
      accept(["--mm:refc"], fake = false)

  suite "run-time guard":
    proc builtForNewer(): seq[string] =
      ## Flags for a program built for a Unicorn newer than the library it
      ## finds: the installed library, declared to the build as 2.9.9.
      @["-d:unicornLibs=" & pkgConfig("--libs"), "-d:unicornVersion=2.9.9"]

    test "uc_open refuses a library older than the one the program was built for":
      check printed(builtForNewer()) == "UC_ERR_VERSION nil=true"

    test "the same program opens the library it was built for":
      check printed() == "UC_ERR_OK nil=false"

    test "a program built for an older Unicorn opens a newer library":
      # The installed library, declared to the build as 2.0.0, the oldest one
      # supported.
      let output = printed(["-d:unicornLibs=" & pkgConfig("--libs"), "-d:unicornVersion=2.0.0"])
      when sizeof(int) == 8:
        check output == "UC_ERR_OK nil=false"
      else:
        # On a 32-bit target Unicorn 2.1.4 changed the type of the size
        # parameters: a program built for an older one must not call it.
        let
          version = pkgConfig("--modversion").split('.')
          installed = (parseInt(version[0]), parseInt(version[1]), parseInt(version[2]))
        check output == (if installed >= (2, 1, 4): "UC_ERR_VERSION nil=true"
                         else: "UC_ERR_OK nil=false")

  removeDir(work)
