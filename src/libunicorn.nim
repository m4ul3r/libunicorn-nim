## Nim bindings for the `Unicorn <https://www.unicorn-engine.org>`_ CPU
## emulator.

import libunicorn/raw
export raw

template CPTR*(s: untyped): cstring = cast[cstring](s[0].addr)
template PTR*(s: untyped): pointer  = s[0].addr
