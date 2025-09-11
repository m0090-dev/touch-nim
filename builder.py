import subprocess
import os
DEFAULT_DEST_DIR = "build"
DEFAULT_SOURCE_NAME = "main.nim"
DEFAULT_BUILD_FILE = DEFAULT_SOURCE_NAME.replace(".nim","")
DEFAULT_BUILD_MODE = "debug"


def build(mode=DEFAULT_BUILD_MODE,source=DEFAULT_SOURCE_NAME,options=[]):
  if mode == "release" or mode == "r":
    subprocess.run(["nim","compile","-d:release","--out:",os.path.join(DEFAULT_DEST_DIR,DEFAULT_BUILD_FILE),source])
  elif mode == "debug" or mode == "d":
    subprocess.run(["nim","compile","--out:",os.path.join(DEFAULT_DEST_DIR,DEFAULT_BUILD_FILE),source])
