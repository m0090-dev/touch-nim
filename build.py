import subprocess
import sys

if len(sys.argv) > 2:
  mode = sys.argv[1]
  source = sys.argv[2]
  options = None
  if len(sys.argv) > 3:
    options = sys.argv[:2]
  if mode == "release" or mode == "r":
    subprocess.run(["nim","compile","-d:release",source])
  elif mode == "debug" or mode == "d":
    subprocess.run(["nim","compile",source])
