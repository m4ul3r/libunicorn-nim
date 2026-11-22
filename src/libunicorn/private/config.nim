## Build configuration: where the Unicorn library is and which version it is.
##
## By default everything comes from `pkg-config unicorn`; `-d:unicornStatic`
## then links `libunicorn.a` from its library directory, together with the
## libraries the archive itself needs, instead of the shared library.
##
## For cross builds or systems without pkg-config, pass the linker flags
## yourself; pkg-config is then not consulted at all:
##
## * `-d:unicornLibs="-L/opt/uc/lib -lunicorn"`: linker flags, used as they
##   are (also with `-d:unicornStatic`: name the archive and what it needs).
## * `-d:unicornVersion=2.1.4`: version of that library; required with
##   `unicornLibs`, because it decides which functions exist.
## * `-d:unicornCflags="-I/opt/uc/include"`: where its headers are. Without it
##   the build-time header check is skipped. Given on its own, it replaces
##   pkg-config's C flags.
##
## `-d:unicornVersion` without `-d:unicornLibs` states which version pkg-config
## is expected to find; the build stops when it finds another.

import std/[macros, strutils]

const
  unicornLibs {.strdefine.} = ""
  unicornCflags {.strdefine.} = ""
  unicornVersion {.strdefine.} = ""

const installHint =
  "Install the Unicorn development package (Debian/Ubuntu: libunicorn-dev, " &
  "Fedora: unicorn-devel, Arch/Homebrew: unicorn), or pass " &
  "-d:unicornLibs=\"-L<dir> -lunicorn\" -d:unicornVersion=<x.y.z>."

proc pkgConfig(query: string): string {.compileTime.} =
  let (output, exitCode) = gorgeEx("pkg-config " & query & " unicorn")
  if exitCode != 0:
    error("libunicorn: `pkg-config " & query & " unicorn` failed:\n" &
          output.strip & "\n" & installHint)
  output.strip

proc versionPart(version: string; index: int): int {.compileTime.} =
  ## Numeric value of the dot-separated component `index`; 0 when absent.
  let parts = version.split('.')
  if index >= parts.len: return 0
  var digits = ""
  for c in parts[index]:
    if c notin Digits: break
    digits.add c
  if digits.len == 0: 0 else: parseInt(digits)

proc versionTriple(version: string): (int, int, int) {.compileTime, used.} =
  (versionPart(version, 0), versionPart(version, 1), versionPart(version, 2))

proc staticLibs(dynamicLibs, libdir: string): string {.compileTime, used.} =
  ## The archive instead of `-lunicorn`, plus what the archive itself needs
  ## (`Libs.private`: libm and pthread), which plain `--libs` leaves out.
  ## (The pkg-config calls are made by the caller: a compile-time proc called
  ## with literal arguments inside another proc is evaluated as soon as that
  ## proc is defined, whether or not it is ever called.)
  for flag in dynamicLibs.splitWhitespace:
    if flag == "-lunicorn": result.add libdir & "/libunicorn.a "
    else: result.add flag & " "

when unicornLibs.len > 0:
  when unicornVersion.len == 0:
    {.error: "libunicorn: -d:unicornLibs also needs -d:unicornVersion=<x.y.z>, " &
             "the version of that Unicorn library.".}
  const
    linkFlags* = unicornLibs
    headerFlags* = unicornCflags
    headersKnown* = unicornCflags.len > 0
    pkgVersion* = ""          ## Version reported by pkg-config; empty when it was not consulted.
    libVersionText* = unicornVersion
elif defined(nimcheck) or defined(nimsuggest):
  # `nim check` and nimsuggest do not run external programs, so pkg-config
  # cannot be asked. Nothing is compiled or linked in these modes either; all
  # that matters is which version the code is checked against: the one given,
  # or else the one the bindings were generated from, where everything exists.
  from ../gen_v2 import UC_API_MAJOR, UC_API_MINOR, UC_API_PATCH
  const
    linkFlags* = ""
    headerFlags* = ""
    headersKnown* = false
    pkgVersion* = ""
    libVersionText* = (if unicornVersion.len > 0: unicornVersion
                       else: $UC_API_MAJOR & "." & $UC_API_MINOR & "." & $UC_API_PATCH)
else:
  const
    linkFlags* = (when defined(unicornStatic):
                    staticLibs(pkgConfig("--libs --static"), pkgConfig("--variable=libdir"))
                  else: pkgConfig("--libs"))
    headerFlags* = (if unicornCflags.len > 0: unicornCflags else: pkgConfig("--cflags"))
    headersKnown* = true
    pkgVersion* = pkgConfig("--modversion")
    libVersionText* = pkgVersion
  when unicornVersion.len > 0 and versionTriple(unicornVersion) != versionTriple(pkgVersion):
    {.error: "libunicorn: -d:unicornVersion=" & unicornVersion & " contradicts pkg-config, " &
             "which reports Unicorn " & pkgVersion & ". To link a different library pass " &
             "-d:unicornLibs as well.".}

const
  libMajor* = versionPart(libVersionText, 0)
  libMinor* = versionPart(libVersionText, 1)
  libPatch* = versionPart(libVersionText, 2)
  libVersion* = (libMajor, libMinor, libPatch)
    ## The Unicorn version this program is built against, as a tuple to compare
    ## with: `when libVersion >= (2, 1, 0)`.
