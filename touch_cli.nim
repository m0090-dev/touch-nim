import cligen
import options
import core
import os
import version

proc climain(
  access: bool = false,
  modify: bool = false,
  no_create: bool = false,
  date: string = "",
  timestamp: string = "",
  reference: string = "",
  file: seq[string]
) = 
  touch(access,modify,no_create,date,timestamp,reference,file)


if isMainModule:
  if paramCount() < 1:
    echo "touch: missing file operand" 
    echo "Try 'touch --help' for more information."

  clCfg.version = VERSION
  dispatch(climain,cmdName = "touch",short = {"no_create":'c'})
