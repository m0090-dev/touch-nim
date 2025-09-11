import docopt
import options
import clidoc
import utils
import os
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

  for f in cfg.file:
    var mode: FileTimeUpdateMode = AccessTimeOnly

    if cfg.access and not cfg.modify:
      mode = AccessTimeOnly
    elif cfg.modify and not cfg.access:
      mode = ModificationTimeOnly
    elif cfg.reference.isSome:
      mode = FromReference
    elif cfg.date.isSome:
      mode = FromDateTimeString
    elif cfg.time.isSome:
      mode = FromTimestampString
    else:
      # デフォルトは両方更新
      mode = AccessTimeOnly

    # ファイル存在チェック
    if not fileExists(f):
      if cfg.no_create:
        echo "スキップ: ファイルが存在しません -> ", f
        continue
      else:
        discard open(f, fmWrite)  # 空ファイル作成

    # touch 実行
    try:
      case mode
      of AccessTimeOnly, ModificationTimeOnly:
        touch(f, mode)
      of FromReference:
        touch(f, mode, refPath = cfg.reference.get)
      of FromDateTimeString:
        touch(f, mode, dateStr = cfg.date.get)
      of FromTimestampString:
        touch(f, mode, timestampStr = cfg.time.get)
    except OSError as e:
      echo "ファイル更新失敗: ", f, " -> ", e.msg
