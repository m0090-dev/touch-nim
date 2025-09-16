import subprocess
import os
# 実行するコマンドをリストで準備
cmd = [
    "dlltool",
    "-d", "core.def",
    "-l", "core.lib",
    "-D", "core.dll"
]
os.chdir("build")
# 実行（エラーがあれば例外を投げる）
subprocess.run(cmd, check=True)
