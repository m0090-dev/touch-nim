import builder
import subprocess
from pathlib import Path
import sys


def main():
    mode = None
    source = None
    extra_args = []

    # `--` を探して、それ以降を実行ファイルに渡す引数にする
    if "--" in sys.argv:
        sep_index = sys.argv.index("--")
        script_args = sys.argv[1:sep_index]
        extra_args = sys.argv[sep_index + 1 :]
    else:
        script_args = sys.argv[1:]

    # mode, source を拾う
    if len(script_args) >= 1:
        mode = script_args[0]
    if len(script_args) >= 2:
        source = script_args[1]

    # ビルド処理
    if source:
        builder.build(mode=mode, source=source)
        build_file = Path(builder.DEFAULT_DEST_DIR) / source.replace(".nim", "")
    else:
        builder.build(mode=mode)
        build_file = Path(builder.DEFAULT_DEST_DIR) / builder.DEFAULT_BUILD_FILE

    # デフォルト設定でビルド
    builder.build()

    # 実行 (extra_args を追加して渡す)
    subprocess.run([str(build_file), *extra_args])


if __name__ == "__main__":
    main()
