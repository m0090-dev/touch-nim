import docopt
import options
import touch_doc
import touch
type 
  TouchConfig = object
    access:bool = false
    modify:bool = false
    no_create:bool = false
    date:Option[string] = none(string)
    time:Option[string] = none(string)
    reference:Option[string] = none(string)
    file:seq[string] = @[]



proc argsToTouchConfig(args: Table[string, Value]): TouchConfig =
  result.access    = args["--access"].bool
  result.modify    = args["--modify"].bool
  result.no_create = args["--no-create"].bool

  if args["--date"]:
    result.date = some($args["--date"])
  else:
    result.date = none(string)

  if args["--time"]:
    result.time = some($args["--time"])
  else:
    result.time = none(string)

  if args["--reference"]:
    result.reference = some($args["--reference"])
  else:
    result.reference = none(string)

  if args["<file>"]:
    result.file = @(args["<file>"])
  else:
    result.file = @[]




if isMainModule:
  let args = docopt(doc, version = "touch 0.1")
  let cfg = argsToTouchConfig(args)
  echo cfg
