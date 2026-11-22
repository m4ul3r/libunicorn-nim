## The generated declarations against the installed Unicorn headers. This is
## what a bad regeneration, or headers the bindings do not fit, would get
## wrong:
##
## * every struct: size, alignment, and the name, offset and size of each
##   field, against the record layout clang computes (skipped without `clang`)
##   and against what the C compiler says;
## * every enumerator of the headers: its value.
##
## The headers may be older than the bindings (Unicorn 2.0 has no
## `uc_tlb_entry`, fewer registers and CPU models): what only the bindings
## have is not compared. What only the headers have fails the test.

import std/[macros, os, osproc, sets, strutils, tables, tempfiles, unittest]
import libunicorn/raw

type
  Field = tuple[name: string; offset, size: int]
  Layout = object
    size, align: int
    fields: seq[Field] ## Leaf fields, in declaration order.

const
  generated = staticRead("../src/libunicorn/gen_v2.nim")
  targetFlags = when defined(i386): "-m32 " else: ""
    ## The headers are examined for the target this test is built for.

# --- the Nim side ------------------------------------------------------------

proc addLeaves[T](record: var T; base: pointer; fields: var seq[Field]) =
  for name, field in fieldPairs(record):
    when field is object:
      addLeaves(field, base, fields)
    else:
      fields.add (name, int(cast[uint](addr field) - cast[uint](base)), sizeof(field))

proc layoutOf(T: typedesc): Layout =
  var record: T
  result = Layout(size: sizeof(T), align: alignof(T))
  addLeaves(record, addr record, result.fields)

macro nimLayouts(): untyped =
  ## A table from C tag ("struct uc_tb") to `layoutOf` the Nim type, for every
  ## struct the generated module declares.
  result = newStmtList()
  let table = genSym(nskVar, "layouts")
  result.add quote do:
    var `table`: Table[string, Layout]
  for line in generated.splitLines:
    let decl = line.strip
    if not (decl.startsWith("struct_") and decl.endsWith("= object")): continue
    let
      name = decl[0 ..< decl.find('*')]
      tag = "struct " & name["struct_".len .. ^1]
      nimType = ident(name)
    result.add quote do:
      `table`[`tag`] = layoutOf(`nimType`)
  result.add table

func cFieldName(tag, nimName: string): string =
  ## The generator renames the field that is a Nim keyword.
  if tag == "struct uc_mem_region" and nimName == "last": "end" else: nimName

macro nimEnumerators(): untyped =
  ## A table from name to value for every enumerator of the generated module,
  ## as the compiler sees them: enum members, the constants that stand for
  ## enumerators C gives a value another one already has
  ## (`UC_ARM_REG_R13* = enum_uc_arm_reg.UC_ARM_REG_SP`), and the members of
  ## the flag enums, which are constants of a distinct type
  ## (`UC_MODE_ARM* = cast[uc_mode](0'i64)`).
  result = newStmtList()
  let table = genSym(nskVar, "values")
  result.add quote do:
    var `table`: Table[string, int64]
  var
    seen: HashSet[string]
    at = 0
  while true:
    at = generated.find("UC_", at)
    if at < 0: break
    var stop = at
    while stop < generated.len and generated[stop] in IdentChars: inc stop
    let
      name = generated[at ..< stop]
      wholeWord = at == 0 or generated[at - 1] notin IdentChars
      member = generated.continuesWith(" = ", stop) and stop + 3 < generated.len and
               generated[stop + 3] in Digits + {'-'}
      alias = generated.continuesWith("* = enum_", stop)
      flag = generated.continuesWith("* = cast[uc_", stop)
    at = stop
    if not wholeWord or not (member or alias or flag) or seen.containsOrIncl(name): continue
    let
      symbol = ident(name)
      value = if flag: newCall(bindSym"uint32", symbol) else: newCall(bindSym"ord", symbol)
    result.add quote do:
      `table`[`name`] = int64(`value`)
  result.add table

# --- the C side --------------------------------------------------------------

proc run(command: string): string =
  let (output, exitCode) = execCmdEx(command)
  doAssert exitCode == 0, command & "\n" & output
  output

proc headerText(cc, cflags, dir: string): string =
  ## What the preprocessor makes of the Unicorn headers themselves, without
  ## the system headers they include.
  writeFile(dir / "headers.c", "#include <unicorn/unicorn.h>\n")
  var ours = false
  for line in run(cc & " -E " & cflags & " " & quoteShell(dir / "headers.c")).splitLines:
    if line.startsWith("#"):
      # A line marker: # 62 "/usr/include/unicorn/x86.h" 2
      let parts = line.split('"')
      if parts.len >= 2: ours = "unicorn" in parts[1].splitPath.head.lastPathPart
    elif ours:
      result.add line & " "

proc headerStructs(text: string): seq[string] =
  ## The tags of the structs the headers define ("struct uc_tb").
  let words = text.replace("{", " { ").splitWhitespace
  for i in 0 ..< words.len - 2:
    if words[i] == "struct" and words[i + 2] == "{": result.add "struct " & words[i + 1]

proc headerEnumerators(text: string): seq[string] =
  ## The names of all enumerators the headers define.
  var at = 0
  while true:
    at = text.find("enum", at)
    if at < 0: break
    let
      open = text.find('{', at)
      between = if open < 0: "" else: text[at + 4 ..< open].strip
    inc at, 4
    # `enum {` or `enum tag {`; anything else is a use of an enum type.
    if open < 0 or not between.allCharsInSet(IdentChars): continue
    let close = text.find('}', open)
    for item in text[open + 1 ..< close].split(','):
      let name = item.split('=')[0].strip
      if name.len > 0: result.add name
    at = close

proc cValues(cc, cflags, dir: string; expressions: seq[string]): seq[int64] =
  ## The values the C compiler gives to `expressions`, by compiling and
  ## running a program that prints them.
  var source = "#include <stddef.h>\n#include <stdio.h>\n#include <unicorn/unicorn.h>\n" &
               "int main(void) {\n"
  for expression in expressions:
    source.add "  printf(\"%lld\\n\", (long long)(" & expression & "));\n"
  source.add "  return 0;\n}\n"
  writeFile(dir / "values.c", source)
  discard run(cc & " " & cflags & " -o " & quoteShell(dir / "values") & " " &
              quoteShell(dir / "values.c"))
  for line in run(quoteShell(dir / "values")).splitLines:
    if line.len > 0: result.add parseBiggestInt(line)
  doAssert result.len == expressions.len

proc clangLayouts(tags: seq[string]; cflags, dir: string): Table[string, Layout] =
  ## The record layouts clang computes; the size of a field is not part of
  ## what it prints and stays 0.
  var source = "#include <unicorn/unicorn.h>\nunsigned long total(void) { return 0"
  for tag in tags: source.add " + sizeof(" & tag & ")"
  source.add "; }\n"
  writeFile(dir / "layout.c", source)
  let dump = run("clang " & cflags & " -fsyntax-only -Xclang -fdump-record-layouts " &
                 quoteShell(dir / "layout.c"))
  for record in dump.split("*** Dumping AST Record Layout"):
    # "       16 |   uint16_t size": offset, then the field indented by nesting depth.
    var
      tag = ""
      layout: Layout
      previousDepth = -1
      previous: Field
    for line in record.splitLines:
      let bar = line.find('|')
      if bar < 0: continue
      let text = line[bar + 1 .. ^1]
      if text.strip.startsWith("[sizeof="):
        let numbers = text.strip(chars = {' ', '[', ']'}).split(", ")
        layout.size = parseInt(numbers[0].split('=')[1])
        layout.align = parseInt(numbers[1].split('=')[1])
        continue
      let depth = text.len - text.strip(trailing = false).len
      if tag.len == 0:
        tag = text.strip
      else:
        # The previous line was a leaf unless this one is nested inside it.
        if previousDepth >= 0 and depth <= previousDepth: layout.fields.add previous
        previousDepth = depth
        previous = (text.splitWhitespace[^1], parseInt(line[0 ..< bar].strip), 0)
    if previousDepth >= 0: layout.fields.add previous
    if tag.len > 0: result[tag] = layout

# --- the comparison ----------------------------------------------------------

template need(condition: bool) =
  ## Ends the test, as failed, when `condition` does not hold. Unlike
  ## `require` it does not end the program: the temporary directory is
  ## removed at the end.
  if not condition: raise newException(CatchableError, astToStr(condition) & " does not hold")

suite "the bindings against the installed headers":
  let
    cc = getEnv("CC", "cc")
    dir = createTempDir("libunicorn_layout_", "")
    actual = nimLayouts()
  var
    cflags, text: string
    tags: seq[string]

  test "the headers are found":
    # The tests below work on what this one reads; they give up without it.
    cflags = targetFlags & run("pkg-config --cflags unicorn").strip
    text = headerText(cc, cflags, dir)
    tags = headerStructs(text)
    # uc_x86_mmr, uc_x86_msr, uc_arm_cp_reg, uc_arm64_cp_reg, uc_tb,
    # uc_mem_region; uc_tlb_entry from Unicorn 2.1 on.
    need tags.len >= 6
    need "struct uc_mem_region" in tags
    for tag in tags:
      checkpoint tag
      check tag in actual

  test "struct layouts match clang's record layouts":
    need tags.len > 0
    if findExe("clang").len == 0:
      skip()
    else:
      let expected = clangLayouts(tags, cflags, dir)
      for tag in tags:
        checkpoint tag
        need tag in expected
        if tag in actual:
          var layout = actual[tag]
          for field in layout.fields.mitems:
            field.name = cFieldName(tag, field.name)
            field.size = 0
          check layout == expected[tag]

  test "structs and fields have the sizes and offsets the C compiler gives them":
    need tags.len > 0
    var
      expressions: seq[string]
      values: seq[int64]
    for tag in tags:
      if tag notin actual: continue
      let layout = actual[tag]
      expressions.add ["sizeof(" & tag & ")", "_Alignof(" & tag & ")"]
      values.add [int64(layout.size), int64(layout.align)]
      for field in layout.fields:
        let name = cFieldName(tag, field.name)
        expressions.add ["offsetof(" & tag & ", " & name & ")",
                         "sizeof(((" & tag & " *)0)->" & name & ")"]
        values.add [int64(field.offset), int64(field.size)]
    let expected = cValues(cc, cflags, dir, expressions)
    var different: seq[string]
    for i, expression in expressions:
      if values[i] != expected[i]:
        different.add expression & " is " & $values[i] & ", in C " & $expected[i]
    checkpoint "not as in C: " & different.join("; ")
    check different.len == 0

  test "enumerators have the values of the headers":
    let names = headerEnumerators(text)
    # Unicorn 2.0.0 defines 3469 of them.
    need names.len > 3000
    let
      expected = cValues(cc, cflags, dir, names)
      values = nimEnumerators()
    var missing, different: seq[string]
    for i, name in names:
      if name notin values:
        missing.add name
      elif name.endsWith("_ENDING"):
        # The marker after the last member of a list: it moves up when a newer
        # Unicorn appends members, so older headers have a smaller one.
        if values[name] < expected[i]:
          different.add name & " is " & $values[name] & ", in C already " & $expected[i]
      elif values[name] != expected[i]:
        different.add name & " is " & $values[name] & ", in C " & $expected[i]
    checkpoint "in the headers and not in the bindings: " & missing.join(" ")
    check missing.len == 0
    checkpoint "another value than in the headers: " & different.join("; ")
    check different.len == 0

  removeDir(dir)
