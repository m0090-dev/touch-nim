#import docopt
#import clidoc
#type 
  #TouchConfig = object
    #access:bool = false
    #modify:bool = false
    #no_create:bool = false
    #date:Option[string] = none(string)
    #timestamp:Option[string] = none(string)
    #reference:Option[string] = none(string)
    #file:seq[string] = @[]



#proc argsToTouchConfig(args: Table[string, Value]): TouchConfig =
  #result.access    = args["--access"].bool
  #result.modify    = args["--modify"].bool
  #result.no_create = args["--no-create"].bool

  #if args["--date"]:
  #  result.date = some($args["--date"])
  #else:
  #  result.date = none(string)

  #if args["--timestamp"]:
  #  result.timestamp = some($args["--timestamp"])
  #else:
  #  result.timestamp = none(string)

  #if args["--reference"]:
  #  result.reference = some($args["--reference"])
  #else:
  #  result.reference = none(string)

  #if args["<file>"]:
  #  result.file = @(args["<file>"])
  #else:
  #  result.file = @[]





# -- test --
#import times, os, strutils
#when defined(windows):
  #import winim/lean, winim/mean, winim/com, winim/utils
  #import winlean
#else:
  #import posix

# Unix(秒) -> FILETIME (UTC) を作る（確実に int64 演算で）
#proc unixToFileTime(unixSec: int64): FILETIME =
  #var ft: FILETIME
  #let ll = unixSec * 10_000_000'i64 + 116444736000000000'i64
  # FILETIMEフィールドのcastはbindingsに合わせておく（元の定義に合わせて）
  #ft.dwLowDateTime  = cast[int32](ll and 0xFFFFFFFF'i64)
  #ft.dwHighDateTime = cast[int32]((ll shr 32) and 0xFFFFFFFF'i64)
  #return ft

# Time -> FILETIME を作る（UTCに揃えてから）
#proc timeToFileTimeUtc(t: Time): FILETIME =
  #let ut = utc(t)                      # UTC基準にする（重要）
  #let unix = int64(ut.toTime().toUnix())        # 秒（int64で）
  #result = unixToFileTime(unix)

# デバッグして表示するユーティリティ
#proc dumpFileTime(fmt: string, ft: FILETIME) =
  #echo fmt, " FILETIME.dwHigh=", ft.dwHighDateTime, " dwLow=", ft.dwLowDateTime
  #var stUtc: SYSTEMTIME
  #if FileTimeToSystemTime(addr ft, addr stUtc) == 0:
    #echo "  -> FileTimeToSystemTime(UTC) failed, GetLastError=", GetLastError()
  #else:
    #echo &"  -> as UTC SYSTEMTIME: {wYear={stUtc.wYear} wMonth={stUtc.wMonth} wDay={stUtc.wDay} wHour={stUtc.wHour} wMin={stUtc.wMinute} wSec={stUtc.wSecond} wMS={stUtc.wMilliseconds}}"
  #var ftLocal: FILETIME
  #if FileTimeToLocalFileTime(addr ft, addr ftLocal) == 0:
    #echo "  -> FileTimeToLocalFileTime failed, GetLastError=", GetLastError()
  #else:
    #var stLocal: SYSTEMTIME
    #if FileTimeToSystemTime(addr ftLocal, addr stLocal) == 0:
      #echo "  -> FileTimeToSystemTime(local) failed, GetLastError=", GetLastError()
    #else:
      #echo &"  -> as LOCAL SYSTEMTIME: {wYear={stLocal.wYear} wMonth={stLocal.wMonth} wDay={stLocal.wDay} wHour={stLocal.wHour} wMin={stLocal.wMinute} wSec={stLocal.wSecond} wMS={stLocal.wMilliseconds}}"

# ファイルに設定して、Set/Getで確認するデバッグ関数
#proc debugSetAndReadFileTime(path: string; t: Time) =
  #echo "===== debugSetAndReadFileTime ====="
  #echo "input Time (toString): ", t
  #echo "utc(t).toUnix(): ", utc(t).toTime().toUnix()
  #let ft = timeToFileTimeUtc(t)
  #dumpFileTime("computed FT", ft)

  # ハンドルの開き方: FILE_WRITE_ATTRIBUTES を明示で試す（権限問題を避ける）
  #let desired = FILE_WRITE_ATTRIBUTES
  #let share = FILE_SHARE_READ or FILE_SHARE_WRITE
  #let h = CreateFileW(path,
        #GENERIC_WRITE or GENERIC_READ,   # DWORD
        #FILE_SHARE_READ or FILE_SHARE_WRITE,  # DWORD
        #nil,                             # lpSecurityAttributes
        #OPEN_EXISTING,                   # DWORD
        #FILE_ATTRIBUTE_NORMAL,           # DWORD
        #nil                              # hTemplateFile
  #)
  #if h == INVALID_HANDLE_VALUE:
    #echo "CreateFileW failed, GetLastError=", GetLastError()
    #return

  # SetFileTime: creation=nil (触らない)、access=ft, write=ft
  #if SetFileTime(h, nil, addr ft, addr ft) == 0:
    #echo "SetFileTime failed, GetLastError=", GetLastError()
    #discard CloseHandle(h)
    #return
  #else:
    #echo "SetFileTime succeeded."

  # すぐに GetFileTime で読み出して確認
  #var cr, ac, wr: FILETIME
  #if GetFileTime(h, addr cr, addr ac, addr wr) == 0:
    #echo "GetFileTime failed, GetLastError=", GetLastError()
  #else:
    #dumpFileTime("read back ac", ac)
    #dumpFileTime("read back wr", wr)

  #discard CloseHandle(h)
  #echo "===== end debug ====="
#proc climain(  
  #access:bool = false,
  #modify:bool = false,
  #no_create:bool = false,
  #date:string = "",
  #timestamp:string = "",
  #reference:string = "",
  #file:seq[string]
#) = 
  #writeFile("test.txt", "hello")  # 確実に存在するファイルを用意
  #let t = "2024-05-01 12:34:56".parse("yyyy-MM-dd HH:mm:ss").toTime()
  #debugSetAndReadFileTime("test.txt", t)

  #quit()
  #let args = docopt(doc, version = "touch 0.1")
  #let cfg = argsToTouchConfig(args)
  #echo cfg # TODO: debug only
  #touch("test.txt",mode=FromTimestampString,timestampStr="202509112000")  
  #quit()
  #echo "timestamp=",timestamp
  #for f in file:
    #var mode: FileTimeUpdateMode = AccessTimeOnly
    #if access and not modify:
      #mode = AccessTimeOnly
    #elif modify and not access:
      #mode = ModificationTimeOnly
    #elif reference != "":
      #mode = FromReference
    #elif date != "":
      #mode = FromDateTimeString
    #elif timestamp != "":
      #mode = FromTimestampString
    #else:
      # デフォルトは両方更新
      #mode = AccessTimeOnly

    # ファイル存在チェック
    #if not fileExists(f):
      #if no_create:
        #echo "スキップ: ファイルが存在しません -> ", f
        #continue
      #else:
        #discard open(f, fmWrite)  # 空ファイル作成

    # touch 実行
    #try:
      #case mode
      #of AccessTimeOnly, ModificationTimeOnly:
        #touch(f, mode)
      #of FromReference:
        #touch(f, mode, refPath = reference)
      #of FromDateTimeString:
        #touch(f, mode, dateStr = date)
      #of FromTimestampString:
        #touch(f, mode, timestampStr = timestamp)
    #except OSError as e:
      #echo "ファイル更新失敗: ", f, " -> ", e.msg



import cligen
import options
import utils
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
  when defined(release): discard
  else:
    echo "== DEBUG TEXT =="
    echo "access=",access
    echo "modify=",modify
    echo "no_create=",no_create
    echo "date=",date
    echo "timestamp=",timestamp
    echo "reference=",reference
    echo "file=",file
    echo "== END TEXT =="
  for f in file:
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

    # それ以外のデフォルト（何も指定されていない場合）
    if mode == {}:
      mode = {AccessTime, ModifyTime}

    # ファイル存在チェック
    if not fileExists(f):
      if no_create:
        echo "スキップ: ファイルが存在しません -> ", f
        continue
      else:
        discard open(f, fmWrite)  # 空ファイル作成

    # touch 実行
    try:
      touch(f, mode, dateStr = date, timestampStr = timestamp, refPath = reference)
    except OSError as e:
      echo "ファイル更新失敗: ", f, " -> ", e.msg

if isMainModule:
  clCfg.version = VERSION
  dispatch climain
