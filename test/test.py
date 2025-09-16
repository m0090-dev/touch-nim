import ctypes
import os

dll_path = os.path.abspath("core.dll")
touch = ctypes.CDLL(dll_path)

touch.ctouch.argtypes = [
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_int,
    ctypes.c_char_p,
    ctypes.c_char_p,
    ctypes.c_char_p,
    ctypes.POINTER(ctypes.c_char_p)
]
touch.ctouch.restype = None

file_list = [b"test1.txt", b"test2.txt", ctypes.c_char_p(0)]
FilesArray = ctypes.c_char_p * len(file_list)
files = FilesArray(*file_list)

touch.ctouch(
    1,              # access
    1,              # modify
    0,              # no_create
    b"",            # date
    b"199009161234",# timestamp
    b"",            # reference
    files
)

print("ctouch 呼び出し完了 (Python)")
