# import builder
# import subprocess
# from pathlib import Path
# import sys


# def main():
    # mode = None
    # source = None
    # extra_args = []

    # # `--` を探して、それ以降を実行ファイルに渡す引数にする
    # if "--" in sys.argv:
        # sep_index = sys.argv.index("--")
        # script_args = sys.argv[1:sep_index]
        # extra_args = sys.argv[sep_index + 1 :]
    # else:
        # script_args = sys.argv[1:]

    # # mode, source を拾う
    # if len(script_args) >= 1:
        # mode = script_args[0]
    # if len(script_args) >= 2:
        # source = script_args[1]

    # # ビルド処理
    # if source:
        # builder.build(mode=mode, source=source)
        # build_file = Path(builder.DEFAULT_DEST_DIR) / source.replace(".nim", "")
    # else:
        # if mode:
          # builder.build(mode=mode)
        # else: 
          # builder.build()
        # build_file = Path(builder.DEFAULT_DEST_DIR) / builder.DEFAULT_BUILD_FILE.replace(".nim","")
    # #print("mode=",mode)
    # #print("source=",source)
    # #print("build_file=" , build_file)
    # # 実行 (extra_args を追加して渡す)
    # subprocess.run([str(build_file), *extra_args])


# if __name__ == "__main__":
    # main()




# run.py
import builder
import subprocess
from pathlib import Path
import sys
import os
import platform

def is_executable(path: Path) -> bool:
    if not path.is_file():
        return False
    system = platform.system()
    if system == "Windows":
        return path.suffix.lower() == ".exe"
    else:  # Linux / macOS
        return os.access(path, os.X_OK)

def main():
    mode = None
    source = None
    app_type = "console"
    extra_args = []
    build_options = []

    if "--" in sys.argv:
        sep_index = sys.argv.index("--")
        script_args = sys.argv[1:sep_index]
        extra_args = sys.argv[sep_index + 1 :]
    else:
        script_args = sys.argv[1:]

    if len(script_args) >= 1:
        mode = script_args[0]
    if len(script_args) >= 2:
        source = script_args[1]
    if len(script_args) >= 3:
        app_type = script_args[2]
    if len(script_args) >= 4:
        build_options = script_args[3:]

    build_file_path = builder.build(
        mode=mode if mode else None,
        source=source if source else None,
        app_type=app_type,
        options=build_options
    )

    build_path = Path(build_file_path)
    # 実行可能ファイルかどうかチェック
    if is_executable(build_path) and app_type in ("console", "gui"):
      subprocess.run([str(build_path), *extra_args])
    else:
      print(f"ビルド完了: {build_file_path} （実行はスキップ）")

if __name__ == "__main__":
    main()
