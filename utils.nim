
import times, os, strutils
when defined(windows):
  #import winim/lean, winim/mean, winim/com, winim/utils
  import winlean
else:
  import posix

type
  FileTimeUpdateMode* = enum
    AccessTimeOnly,          # アクセス時刻だけ更新
    ModificationTimeOnly,    # 修正時刻だけ更新
    FromReference,           # 参照ファイルに合わせる
    FromDateTimeString,      # 任意日時文字列に設定
    FromTimestampString      # YYYYMMDDHHMM.SS形式のタイムスタンプ

proc parseDateTime(dateStr: string): Time =
  try:
    result = dateStr.parse("yyyy-MM-dd HH:mm").toTime
  except CatchableError as e:
    raise newException(ValueError, "日時文字列の解析に失敗: " & e.msg)

proc parseTimestamp(timestampStr: string): Time =
  try:
    if timestampStr.len != 15 or timestampStr[12] != '.':
      raise newException(ValueError, "形式が不正です: " & timestampStr)
    let datePart = timestampStr[0..11]
    let secPart = parseInt(timestampStr[13..14])
    result = datePart.parse("yyyyMMddHHMM").toTime + initDuration(secPart,0,0,0)
  except CatchableError as e:
    raise newException(ValueError, "タイムスタンプ文字列の解析に失敗: " & timestampStr & " -> " & e.msg)

proc updateFileTime*(path: string;
                     mode: FileTimeUpdateMode;
                     dateStr: string = "";
                     timestampStr: string = "";
                     refPath: string = "") =
  try:
    var atime, mtime: Time
    case mode
    of AccessTimeOnly:
      atime = now().toTime()
      mtime = getFileInfo(path).lastWriteTime
    of ModificationTimeOnly:
      atime = getFileInfo(path).lastAccessTime
      mtime = now().toTime()
    of FromReference:
      let refInfo = getFileInfo(refPath)
      atime = refInfo.lastAccessTime
      mtime = refInfo.lastWriteTime
    of FromDateTimeString:
      let t = parseDateTime(dateStr)
      atime = t
      mtime = t
    of FromTimestampString:
      let t = parseTimestamp(timestampStr)
      atime = t
      mtime = t

    when defined(windows):
      proc timeToFileTime(t: Time): FILETIME =
        var ft: FILETIME
        let ll = int64(t.toUnix()) * 10000000 + 116444736000000000
        ft.dwLowDateTime  = int32(ll and 0xFFFFFFFF'i64)
        ft.dwHighDateTime = int32((ll shr 32) and 0xFFFFFFFF'i64)
        return ft
      let ftAccess = timeToFileTime(atime)
      let ftModify = timeToFileTime(mtime)
      

      #let h = createFileW(path, GENERIC_WRITE or GENERIC_READ,
                          #FILE_SHARE_READ or FILE_SHARE_WRITE,
                          #nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nil)
      
      


      let widePath: WideCString =toWideCString(newWideCString(path))  # string -> WideCString

      let h = createFileW(
        widePath,
        GENERIC_WRITE or GENERIC_READ,   # DWORD
        FILE_SHARE_READ or FILE_SHARE_WRITE,  # DWORD
        nil,                             # lpSecurityAttributes
        OPEN_EXISTING,                   # DWORD
        FILE_ATTRIBUTE_NORMAL,           # DWORD
        cast[Handle](nil)                              # hTemplateFile
      )




      if h == INVALID_HANDLE_VALUE:
        raise newException(OSError, "Failed to open file: " & path)
      if setFileTime(h, addr ftAccess, addr ftModify, addr ftModify) == 0:
        raise newException(OSError, "Failed to set file time: " & path)
      discard closeHandle(h)
    else:
      var tv: array[2, timespec]
      tv[0] = timespec(sec = atime.toUnix(), nsec = 0)
      tv[1] = timespec(sec = mtime.toUnix(), nsec = 0)
      if utimensat(0, path.cstring, tv.addr, 0) != 0:
        raise newException(OSError, "utimensat failed for file: " & path)

  except OSError as e:
    echo "ファイル時刻の更新に失敗: ", path, " -> ", e.msg
  except ValueError as e:
    echo "入力文字列の解析に失敗 -> ", e.msg

proc touch*(path: string;
           mode: FileTimeUpdateMode = AccessTimeOnly;
           dateStr: string = "";
           timestampStr: string = "";
           refPath: string = "") =
  # ファイルが存在しなければ新規作成
  if not fileExists(path):
    discard open(path, fmWrite)  # 空ファイル作成

  # 既存ファイルの時刻更新
  updateFileTime(path, mode, dateStr, timestampStr, refPath)
