
import ctypes
import os

# DLL のフルパス（環境に合わせて変更）
dll_path = r"build\touch.dll"

# DLL ロード
# PATH に DLL フォルダを追加して依存DLLも見つかるようにする
dll_dir = os.path.dirname(dll_path)
os.environ["PATH"] = dll_dir + ";" + os.environ["PATH"]

touch = ctypes.CDLL(dll_path)

# ctouch の引数型を設定
touch.ctouch.argtypes = [
    ctypes.c_int,          # access
    ctypes.c_int,          # modify
    ctypes.c_int,          # no_create
    ctypes.c_char_p,       # date
    ctypes.c_char_p,       # timestamp
    ctypes.c_char_p,       # reference
    ctypes.POINTER(ctypes.c_char_p)  # files (NULL終端)
]
touch.ctouch.restype = None

# 更新するファイルの配列を作成（NULL終端）
file_list = [b"test1.txt", b"test2.txt", None]  # b"" で bytes に
FilesArray = ctypes.c_char_p * len(file_list)
files = FilesArray(*file_list)

# ctouch 呼び出し
touch.ctouch(
    1,      # access
    1,      # modify
    0,      # no_create
    None,   # date
    r"202509161234",   # timestamp
    None,   # reference
    files
)

print("ctouch 呼び出し完了")
