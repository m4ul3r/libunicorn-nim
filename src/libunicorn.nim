{.passL: "`pkg-config --libs unicorn`".}
{.passL: "`pkg-config --cflags unicorn`".}
from os import parentDir, `/`

template CPTR*(s: untyped): cstring = cast[cstring](s[0].addr)
template PTR*(s: untyped): pointer  = s[0].addr

when defined(useFuthark) or defined(useFutharkForLibunicorn):
  import futhark

  importc:
    outputPath currentSourcePath.parentDir / "libunicorn_generated.nim"
    path "/usr/local/include/unicorn"
    "unicorn.h"
else:
  include "libunicorn_generated.nim"