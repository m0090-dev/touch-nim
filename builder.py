# builder.py 
import subprocess
import os

DEFAULT_DEST_DIR = "build"
DEFAULT_SOURCE_NAME = "main.nim"
DEFAULT_BUILD_FILE = DEFAULT_SOURCE_NAME.replace(".nim","")
DEFAULT_BUILD_MODE = "debug"

def build(mode=DEFAULT_BUILD_MODE, source=DEFAULT_SOURCE_NAME, options=[]):
    # 出力先ディレクトリを作る
    os.makedirs(DEFAULT_DEST_DIR, exist_ok=True)

    out_path = os.path.join(DEFAULT_DEST_DIR, source.replace(".nim",""))

    # コマンドリスト作成
    cmd = ["nim", "compile"]
    
    # モード指定
    if mode in ("release", "r"):
        cmd.append("-d:release")
    # debug はデフォルトなのでオプション不要
    # cmd.append("-d:debug")  # 必要なら追加可能

    # --out: をまとめて追加
    cmd.append(f"--out:{out_path}")

    # コンパイル対象ファイル
    cmd.append(source)

    # 追加オプションがあれば追加
    cmd.extend(options)

    # 実行
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)

    return out_path  # 呼び出し元で実行ファイルパスとして使える
