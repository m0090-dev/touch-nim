
import times, os, strutils
when defined(windows):
  import winim/lean, winim/mean, winim/com, winim/utils
  #import winlean
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
  let ts = timestampStr.strip()
  case ts.len
  of 12: # YYYYMMDDHHMM
    # 文字列を "YYYY-MM-DD HH:MM" 形式に変換して parseTime
    let s = ts[0..3] & "-" & ts[4..5] & "-" & ts[6..7] & " " & ts[8..9] & ":" & ts[10..11]
    result = parseTime(s, "yyyy-MM-dd HH:mm",local())
  of 15: # YYYYMMDDHHMM.SS
    if ts[12] != '.':
      raise newException(ValueError, "形式が不正です: " & ts)
    let s = ts[0..3] & "-" & ts[4..5] & "-" & ts[6..7] & " " &
            ts[8..9] & ":" & ts[10..11] & ":" & ts[13..14]
    result = parseTime(s, "yyyy-MM-dd HH:mm:ss",local())
  else:
    raise newException(ValueError, "形式が不正です: " & ts)


# Unix(秒) -> FILETIME (UTC)
proc unixToFileTime(unixSec: int64): FILETIME =
  var ft: FILETIME
  let ll = unixSec * 10_000_000'i64 + 116444736000000000'i64
  ft.dwLowDateTime  = cast[int32](ll and 0xFFFFFFFF'i64)
  ft.dwHighDateTime = cast[int32]((ll shr 32) and 0xFFFFFFFF'i64)
  return ft
# Time -> FILETIME
proc timeToFileTimeUTC(t: Time): FILETIME =
  # let ut = utc(t)  # もう t は UTC なので不要
  let unix = int64(t.toUnix())
  result = unixToFileTime(unix)
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
      let ftAccess = timeToFileTimeUTC(atime)
      let ftModify = timeToFileTimeUTC(mtime)
      

      #let h = CreateFileW(path, GENERIC_WRITE or GENERIC_READ,
                          #FILE_SHARE_READ or FILE_SHARE_WRITE,
                          #nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nil)
      
      


      #let widePath: WideCString =toWideCString(newWideCString(path))  # string -> WideCString

      let h = CreateFileW(
        path,
        GENERIC_WRITE or GENERIC_READ,   # DWORD
        FILE_SHARE_READ or FILE_SHARE_WRITE,  # DWORD
        nil,                             # lpSecurityAttributes
        OPEN_EXISTING,                   # DWORD
        FILE_ATTRIBUTE_NORMAL,           # DWORD
        nil                              # hTemplateFile
      )


      let ft = timeToFileTimeUTC(mtime)

      if h == INVALID_HANDLE_VALUE:
        raise newException(OSError, "Failed to open file: " & path)
      #if SetFileTime(h, addr ftAccess, addr ftModify, addr ftModify) == 0:
      if SetFileTime(h, nil, addr ft, addr ft) == 0:
      #if SetFileTime(h, nil, addr ftAccess, addr ftModify) == 0:
        #raise newException(OSError, "Failed to set file time: " & path)
        echo "SetFileTime failed, GetLastError=", GetLastError()
        discard CloseHandle(h)
        return
      discard CloseHandle(h)
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
