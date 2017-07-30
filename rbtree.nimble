# Package

version       = "0.3.0"
author        = "Nycto"
description   = "Red/Black Tree"
license       = "MIT"
skipDirs      = @["test", ".build"]

# Deps

requires "nim >= 0.11.2"

exec "test -d .build/ExtraNimble || git clone https://github.com/Nycto/ExtraNimble.git .build/ExtraNimble"
when existsDir(thisDir() & "/.build"):
    include ".build/ExtraNimble/extranimble.nim"
