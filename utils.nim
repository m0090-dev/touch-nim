#type
  #FileTimeUpdateMode* = enum
    #AccessTimeOnly,          # アクセス時刻だけ更新
    #ModificationTimeOnly,    # 修正時刻だけ更新
    #FromReference,           # 参照ファイルに合わせる
    #FromDateTimeString,      # 任意日時文字列に設定
    #FromTimestampString      # YYYYMMDDHHMM.SS形式のタイムスタンプ


#proc updateFileTime*(path: string;
                     #mode: FileTimeUpdateMode;
                     #dateStr: string = "";
                     #timestampStr: string = "";
                     #refPath: string = "") =
  #try:
    #var atime, mtime: Time
    #case mode
    #of AccessTimeOnly:
      #atime = now().toTime()
      #mtime = getFileInfo(path).lastWriteTime
    #of ModificationTimeOnly:
      #atime = getFileInfo(path).lastAccessTime
      #mtime = now().toTime()
    #of FromReference:
      #let refInfo = getFileInfo(refPath)
      #atime = refInfo.lastAccessTime
      #mtime = refInfo.lastWriteTime
    #of FromDateTimeString:
      #let t = parseDateTime(dateStr)
      #atime = t
      #mtime = t
    #of FromTimestampString:
      #let t = parseTimestamp(timestampStr)
      #atime = t
      #mtime = t

    #when defined(windows):
      #let ftAccess = timeToFileTimeUTC(atime)
      #let ftModify = timeToFileTimeUTC(mtime)
      

      #let h = CreateFileW(path, GENERIC_WRITE or GENERIC_READ,
                          #FILE_SHARE_READ or FILE_SHARE_WRITE,
                          #nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nil)
      
      


      #let widePath: WideCString =toWideCString(newWideCString(path))  # string -> WideCString

      #let h = CreateFileW(
        #path,
        #GENERIC_WRITE or GENERIC_READ,   # DWORD
        #FILE_SHARE_READ or FILE_SHARE_WRITE,  # DWORD
        #nil,                             # lpSecurityAttributes
        #OPEN_EXISTING,                   # DWORD
        #FILE_ATTRIBUTE_NORMAL,           # DWORD
        #nil                              # hTemplateFile
      #)


      #let ft = timeToFileTimeUTC(mtime)

      #if h == INVALID_HANDLE_VALUE:
        #raise newException(OSError, "Failed to open file: " & path)
      #if SetFileTime(h, addr ftAccess, addr ftModify, addr ftModify) == 0:
      #if SetFileTime(h, nil, addr ft, addr ft) == 0:
      #if SetFileTime(h, nil, addr ftAccess, addr ftModify) == 0:
        #raise newException(OSError, "Failed to set file time: " & path)
        #echo "SetFileTime failed, GetLastError=", GetLastError()
        #discard CloseHandle(h)
        #return
      #discard CloseHandle(h)
    #else:
      #var tv: array[2, timespec]
      #tv[0] = timespec(sec = atime.toUnix(), nsec = 0)
      #tv[1] = timespec(sec = mtime.toUnix(), nsec = 0)
      #if utimensat(0, path.cstring, tv.addr, 0) != 0:
        #raise newException(OSError, "utimensat failed for file: " & path)

  #except OSError as e:
    #echo "ファイル時刻の更新に失敗: ", path, " -> ", e.msg
  #except ValueError as e:
    #echo "入力文字列の解析に失敗 -> ", e.msg

#proc updateFileTime*(path: string;
                     #mode: FileTimeUpdateMode;
                     #dateStr: string = "";
                     #timestampStr: string = "";
                     #refPath: string = "") =
  #try:
    #var atime, mtime: Time
    #let info = getFileInfo(path)

    # --- デフォルト値は元の時刻 ---
    #atime = info.lastAccessTime
    #mtime = info.lastWriteTime

    # --- 参照ファイル指定 ---
    #if UseReference in mode:
      #let refInfo = getFileInfo(refPath)
      #atime = refInfo.lastAccessTime
      #mtime = refInfo.lastWriteTime

    # --- 日付文字列指定 ---
    #if UseDateStr in mode:
      #let t = parseDateTime(dateStr)
      #atime = t
      #mtime = t

    # --- タイムスタンプ指定 ---
    #if UseTimestamp in mode:
      #let t = parseTimestamp(timestampStr)
      #atime = t
      #mtime = t

    # --- Access/Modify フラグで上書き対象を決定 ---
    #if AccessTime notin mode:
      #atime = info.lastAccessTime
    #if ModifyTime notin mode:
      #mtime = info.lastWriteTime

    #when defined(windows):
      #let ftAccess = timeToFileTimeUTC(atime)
      #let ftModify = timeToFileTimeUTC(mtime)

      #let h = CreateFileW(
        #path,
        #GENERIC_WRITE or GENERIC_READ,
        #FILE_SHARE_READ or FILE_SHARE_WRITE,
        #nil,
        #OPEN_EXISTING,
        #FILE_ATTRIBUTE_NORMAL,
        #nil
      #)

      #if h == INVALID_HANDLE_VALUE:
        #raise newException(OSError, "Failed to open file: " & path)

      #if SetFileTime(h, addr ftAccess, addr ftModify, addr ftModify) == 0:
        #echo "SetFileTime failed, GetLastError=", GetLastError()
        #discard CloseHandle(h)
        #return
      #discard CloseHandle(h)
    #else:
      #var tv: array[2, timespec]
      #tv[0] = timespec(sec = atime.toUnix(), nsec = 0)
      #tv[1] = timespec(sec = mtime.toUnix(), nsec = 0)
      #if utimensat(0, path.cstring, tv.addr, 0) != 0:
        #raise newException(OSError, "utimensat failed for file: " & path)

  #except OSError as e:
    #echo "ファイル時刻の更新に失敗: ", path, " -> ", e.msg
  #except ValueError as e:
    #echo "入力文字列の解析に失敗 -> ", e.msg

#proc updateFileTime*(path: string;
                     #mode: FileTimeUpdateMode;
                     #dateStr: string = "";
                     #timestampStr: string = "";
                     #refPath: string = "") =
  #try:
    #let info = getFileInfo(path)
    #var atime = info.lastAccessTime
    #var mtime = info.lastWriteTime

    #var newTime: Time


    # timestamp 指定でアクセス/修正フラグが空なら両方追加
    #if UseTimestamp in mode and not (AccessTime in mode or ModifyTime in mode):
      #mode.incl(AccessTime)
      #mode.incl(ModifyTime)
    # 参照ファイル
    #if UseReference in mode:
      #let refInfo = getFileInfo(refPath)
      #newTime = refInfo.lastWriteTime
      #if AccessTime in mode: atime = refInfo.lastAccessTime
      #if ModifyTime in mode: mtime = refInfo.lastWriteTime

    # 日付文字列
    #if UseDateStr in mode:
      #let t = parseDateTime(dateStr)
      #if AccessTime in mode: atime = t
      #if ModifyTime in mode: mtime = t

    # タイムスタンプ
    #if UseTimestamp in mode:
      #let t = parseTimestamp(timestampStr)
      #if AccessTime in mode: atime = t
      #if ModifyTime in mode: mtime = t

    #when defined(windows):
      #let ftAccess = timeToFileTimeUTC(atime)
      #let ftModify = timeToFileTimeUTC(mtime)

      #let h = CreateFileW(
        #path,
        #GENERIC_WRITE or GENERIC_READ,
        #FILE_SHARE_READ or FILE_SHARE_WRITE,
        #nil,
        #OPEN_EXISTING,
        #FILE_ATTRIBUTE_NORMAL,
        #nil
      #)

      #if h == INVALID_HANDLE_VALUE:
        #raise newException(OSError, "Failed to open file: " & path)

     # if SetFileTime(h, addr ftAccess, addr ftModify, addr ftModify) == 0:
        #echo "SetFileTime failed, GetLastError=", GetLastError()
        #discard CloseHandle(h)
        #return
      #discard CloseHandle(h)

      # CreationTime は変更しないので nil
      #if SetFileTime(h,
        #if AccessTime in mode: addr ftAccess else: nil,
        #nil,
        #if ModifyTime in mode: addr ftModify else: nil) == 0:
          #echo "SetFileTime failed, GetLastError=", GetLastError()
          #discard CloseHandle(h)
          #return

    #else:
      #var tv: array[2, timespec]
      #tv[0] = timespec(sec = atime.toUnix(), nsec = 0)
      #tv[1] = timespec(sec = mtime.toUnix(), nsec = 0)
      #if utimensat(0, path.cstring, tv.addr, 0) != 0:
        #raise newException(OSError, "utimensat failed for file: " & path)

  #except OSError as e:
    #echo "ファイル時刻の更新に失敗: ", path, " -> ", e.msg
  #except ValueError as e:
    #echo "入力文字列の解析に失敗 -> ", e.msg
#proc touch*(path: string;
           #mode: FileTimeUpdateMode = AccessTimeOnly;
           #dateStr: string = "";
           #timestampStr: string = "";
           #refPath: string = "") =
  # ファイルが存在しなければ新規作成
  #if not fileExists(path):
    #discard open(path, fmWrite)  # 空ファイル作成

  # 既存ファイルの時刻更新
  #updateFileTime(path, mode, dateStr, timestampStr, refPath)


import times, os, strutils
when defined(windows):
  import winim/lean, winim/mean, winim/com, winim/utils
  #import winlean
else:
  import posix

type
  FileTimeFlag* = enum
    AccessTime, ModifyTime, UseReference, UseDateStr, UseTimestamp
  FileTimeUpdateMode* = set[FileTimeFlag]




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
    let info = getFileInfo(path)
    var atime = info.lastAccessTime
    var mtime = info.lastWriteTime

    var newTime: Time

    # mode をローカルコピーにして mutable にする
    var modeLocal = mode

    # timestamp 指定でアクセス/修正フラグが空なら両方追加
    if UseTimestamp in modeLocal and not (AccessTime in modeLocal or ModifyTime in modeLocal):
      modeLocal = modeLocal + {AccessTime, ModifyTime}

    # 参照ファイルモードでアクセス/修正が空なら両方追加
    if UseReference in modeLocal and not (AccessTime in modeLocal or ModifyTime in modeLocal):
      modeLocal = modeLocal + {AccessTime, ModifyTime}
    if modeLocal == {}:
      modeLocal = {AccessTime, ModifyTime}
    # 参照ファイル
    if UseReference in modeLocal:
      let refInfo = getFileInfo(refPath)
      if AccessTime in modeLocal: atime = refInfo.lastAccessTime
      if ModifyTime in modeLocal: mtime = refInfo.lastWriteTime

    # 日付文字列
    if UseDateStr in modeLocal:
      let t = parseDateTime(dateStr)
      if AccessTime in modeLocal: atime = t
      if ModifyTime in modeLocal: mtime = t

    # タイムスタンプ
    if UseTimestamp in modeLocal:
      let t = parseTimestamp(timestampStr)
      if AccessTime in modeLocal: atime = t
      if ModifyTime in modeLocal: mtime = t

    # 7. 単体指定や何も指定されていない場合、modeLocal のフィールドを現在時刻に更新
    let n = now().toTime()  # Time型
    if AccessTime in modeLocal and not (UseDateStr in modeLocal or UseTimestamp in modeLocal or UseReference in modeLocal):
      atime = n
    if ModifyTime in modeLocal and not (UseDateStr in modeLocal or UseTimestamp in modeLocal or UseReference in modeLocal):
      mtime = n

    when defined(windows):
      let ftAccess = timeToFileTimeUTC(atime)
      let ftModify = timeToFileTimeUTC(mtime)

      let h = CreateFileW(
        path,
        GENERIC_WRITE or GENERIC_READ,
        FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        nil
      )

      if h == INVALID_HANDLE_VALUE:
        raise newException(OSError, "Failed to open file: " & path)

      # CreationTime は変更しないので nil
    
      if SetFileTime(h,
        nil,  # CreationTime は変更しない
        if AccessTime in modeLocal: addr ftAccess else: nil,  # ここでアクセス時刻
        if ModifyTime in modeLocal: addr ftModify else: nil) == 0:
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




#proc touch*(path: string;
           #mode: FileTimeUpdateMode = {AccessTime, ModifyTime};
           #dateStr: string = "";
           #timestampStr: string = "";
           #refPath: string = "") =
  #if not fileExists(path):
    #discard open(path, fmWrite)  # 空ファイル作成

  #updateFileTime(path, mode, dateStr, timestampStr, refPath)

proc touch*(
  access: bool = false,
  modify: bool = false,
  no_create: bool = false,
  date: string,
  timestamp: string,
  reference: string,
  files: seq[string]
) =
  for f in files:
    var mode: FileTimeUpdateMode = {}

    # フラグ設定
    if access: mode.incl(AccessTime)
    if modify: mode.incl(ModifyTime)
    if reference != "": mode.incl(UseReference)
    if date != "": mode.incl(UseDateStr)
    if timestamp != "": mode.incl(UseTimestamp)

    # -t がある場合、-a/-m が指定されなければ両方更新
    if UseTimestamp in mode and not (AccessTime in mode or ModifyTime in mode):
      mode.incl(AccessTime)
      mode.incl(ModifyTime)

    # それ以外のデフォルト
    if mode == {}:
      mode = {AccessTime, ModifyTime}

    # ファイル存在チェック
    if not fileExists(f):
      if no_create:
        continue
      else:
        discard open(f, fmWrite)  # 空ファイル作成

    try:
      updateFileTime(f, mode, dateStr = date, timestampStr = timestamp, refPath = reference)
    except OSError as e:
      echo "ファイル更新失敗: ", f, " -> ", e.msg







proc ctouch*(access: cint,
             modify: cint,
             no_create: cint,
             date: cstring,
             timestamp: cstring,
             reference: cstring,
             files: cstringArray) {.cdecl, exportc, dynlib.} =
  var i = 0
  while files[i] != nil:
    #let f = files[i].cstring
    let f = $files[i]
    var mode: FileTimeUpdateMode = {}

    # フラグ設定
    if access != 0: mode.incl(AccessTime)
    if modify != 0: mode.incl(ModifyTime)
    if reference != "": mode.incl(UseReference)
    if date != "": mode.incl(UseDateStr)
    if timestamp != "": mode.incl(UseTimestamp)

    # -t がある場合、-a/-m が指定されなければ両方更新
    if UseTimestamp in mode and not (AccessTime in mode or ModifyTime in mode):
      mode.incl(AccessTime)
      mode.incl(ModifyTime)

    # それ以外のデフォルト
    if mode == {}:
      mode = {AccessTime, ModifyTime}

    # ファイル存在チェック
    if not fileExists(f):
      if no_create != 0:
        i.inc()
        continue
      else:
        discard open(f, fmWrite)  # 空ファイル作成

    try:

      updateFileTime(f, mode,
        dateStr = if date != nil: $date else: "",
        timestampStr = if timestamp != nil: $timestamp else: "",
        refPath = if reference != nil: $reference else: ""
      )
      #updateFileTime(f, mode, dateStr = date, timestampStr = timestamp, refPath = reference)
    except OSError as e:
      stderr.write("ファイル更新失敗: " & f & " -> " & e.msg & "\n")
    
    i.inc()
