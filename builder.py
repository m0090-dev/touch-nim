# builder.py 
# import subprocess
# import os

# DEFAULT_DEST_DIR = "build"
# DEFAULT_SOURCE_NAME = "main.nim"
# DEFAULT_BUILD_FILE = DEFAULT_SOURCE_NAME.replace(".nim","")
# DEFAULT_BUILD_MODE = "debug"

# def build(mode=DEFAULT_BUILD_MODE, source=DEFAULT_SOURCE_NAME, options=[]):
    # # 出力先ディレクトリを作る
    # os.makedirs(DEFAULT_DEST_DIR, exist_ok=True)

    # out_path = os.path.join(DEFAULT_DEST_DIR, source.replace(".nim",""))

    # # コマンドリスト作成
    # cmd = ["nim", "compile"]
    
    # # モード指定
    # if mode in ("release", "r"):
        # cmd.append("-d:release")
    # # debug はデフォルトなのでオプション不要
    # # cmd.append("-d:debug")  # 必要なら追加可能

    # # --out: をまとめて追加
    # cmd.append(f"--out:{out_path}")

    # # コンパイル対象ファイル
    # cmd.append(source)

    # # 追加オプションがあれば追加
    # cmd.extend(options)

    # # 実行
    # print("Running:", " ".join(cmd))
    # subprocess.run(cmd, check=True)

    # return out_path  # 呼び出し元で実行ファイルパスとして使える






# builder.py
import argparse
import subprocess
import os
import sys

DEFAULT_DEST_DIR = "build"
DEFAULT_SOURCE_NAME = "main.nim"
DEFAULT_BUILD_FILE = DEFAULT_SOURCE_NAME.replace(".nim", "")
DEFAULT_BUILD_MODE = "debug"
DEFAULT_APP_TYPE = "console"  # console, gui, lib, dll など

def build(
    mode=DEFAULT_BUILD_MODE,
    source=DEFAULT_SOURCE_NAME,
    dest_dir=DEFAULT_DEST_DIR,
    app_type=DEFAULT_APP_TYPE,
    options=None
):
    if options is None:
        options = []

    # 出力先ディレクトリを作成
    os.makedirs(dest_dir, exist_ok=True)

    # 出力ファイル名（OS + app_type に応じた拡張子付与）
    build_file_name = source.replace(".nim", "")
    if app_type in ("lib", "dll", "s"):
        if sys.platform.startswith("win"):
            build_file_name += ".dll"
        elif sys.platform.startswith("linux"):
            build_file_name += ".so"
        elif sys.platform.startswith("darwin"):
            build_file_name += ".dylib"
    elif app_type in ("console", "c", "gui", "g"):
        if sys.platform.startswith("win"):
            build_file_name += ".exe"

    out_path = os.path.join(dest_dir, build_file_name)

    # Nimコンパイルコマンド作成
    cmd = ["nim", "compile"]

    # モード指定
    if mode in ("release", "r"):
        cmd.append("-d:release")
    elif mode in ("debug", "d"):
        cmd.append("-d:debug")
    # 追加オプション
    cmd.extend(options)

    # アプリ/ライブラリタイプ指定
    if app_type in ("console", "c"):
        cmd.append("--app:console")
    elif app_type in ("gui", "g"):
        cmd.append("--app:gui")
    elif app_type in ("lib", "dll", "s"):
        cmd.append(f"--app:{app_type}")

    # 出力先
    cmd.append(f"--out:{out_path}")

    # コンパイル対象
    cmd.append(source)



    # ビルド実行
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)

    return out_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Nim build script")
    parser.add_argument("-m", "--mode", default=DEFAULT_BUILD_MODE, help="Build mode: debug/release")
    parser.add_argument("-s", "--source", default=DEFAULT_SOURCE_NAME, help="Source file")
    parser.add_argument("-d", "--dest", default=DEFAULT_DEST_DIR, help="Output directory")
    parser.add_argument("-a", "--apptype", default=DEFAULT_APP_TYPE, help="Application type: console/gui/lib/dll")
    parser.add_argument("-o", "--options", nargs="*", default=[], help="Additional Nim compiler options")

    args = parser.parse_args()

    build(
        mode=args.mode,
        source=args.source,
        dest_dir=args.dest,
        app_type=args.apptype,
        options=args.options
    )
