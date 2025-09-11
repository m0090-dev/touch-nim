import builder
import subprocess
from pathlib import Path
import sys

def main():
    mode = None
    source = None

    if len(sys.argv) >= 2:
        mode = sys.argv[1]
    if len(sys.argv) == 3:
        source = sys.argv[2]

    if source:
        builder.build(mode=mode, source=source)
        build_file = Path(builder.DEFAULT_DEST_DIR) / source.replace(".nim", "")
    else:
        builder.build(mode=mode)
        build_file = Path(builder.DEFAULT_DEST_DIR) / builder.DEFAULT_BUILD_FILE
    # デフォルト設定でビル
    builder.build()
    # 実行
    subprocess.run([str(build_file)])

if __name__ == "__main__":
    main()
