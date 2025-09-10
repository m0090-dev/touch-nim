import docopt
import options
import touch_doc
type 
  TouchConfig = object
    access:bool = false
    modify:bool = false
    no_create:bool = false
    date:Option[string] = none(string)
    time:Option[string] = none(string)
    reference:Option[string] = none(string)
    file:seq[string] = @[]


if isMainModule:
  echo "hello world こんにちは、世界"
