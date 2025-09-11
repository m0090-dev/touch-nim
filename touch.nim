import times, os, strutils

# 日時文字列を Time に変換する関数
proc parseDatetime(dateStr: string): Time =
  try:
    result = parseTime(dateStr, "yyyy-MM-dd HH:mm")
  except CatchableError as e:
    echo "日時文字列の解析に失敗: ", e.msg
    raise

# ファイルの時刻を指定日時に変更
proc changeFileTime(filePath: string, datetimeStr: string) =
  try:
    let t = parseDatetime(datetimeStr)
    setFileTimes(filePath, t, t)
  except OSError as e:
    echo "ファイル時刻の変更に失敗: ", filePath, " -> ", e.msg

# ファイルのアクセス時刻を現在時刻に変更
proc updateAccessTime(path: string) =
  try:
    let nowTime = now()
    let mtime = getFileInfo(path).mtime
    setFileTimes(path, nowTime, mtime)
  except OSError as e:
    echo "アクセス時刻の更新に失敗: ", path, " -> ", e.msg

# ファイルの修正時刻を現在時刻に変更
proc updateModificationTime(path: string) =
  try:
    let nowTime = now()
    let atime = getFileInfo(path).atime
    setFileTimes(path, atime, nowTime)
  except OSError as e:
    echo "修正時刻の更新に失敗: ", path, " -> ", e.msg

# ファイルの時刻を参照ファイルの時刻に変更
proc updateTimeFromReference(path, reference: string) =
  try:
    let refInfo = getFileInfo(reference)
    setFileTimes(path, refInfo.atime, refInfo.mtime)
  except OSError as e:
    echo "参照ファイルからの時刻更新に失敗: ", path, " -> ", e.msg

# ファイルの時刻を指定タイムスタンプに変更 (YYYYMMDDHHMM.SS形式)
proc updateTimestamp(path: string, timestampStr: string) =
  try:
    let datePart = timestampStr[0..11]
    let secPart = parseInt(timestampStr[13..14])
    let t = parseTime(datePart, "yyyyMMddHHMM") + initDuration(secPart, 0, 0, 0)
    setFileTimes(path, t, t)
  except OSError as e:
    echo "タイムスタンプ更新に失敗: ", path, " -> ", e.msg
  except ValueError as e:
    echo "タイムスタンプ文字列の解析に失敗: ", timestampStr, " -> ", e.msg
