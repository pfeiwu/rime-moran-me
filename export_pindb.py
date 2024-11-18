import os
import shutil
import subprocess
import sys

def decode(x):
    if x >= 0:
        m = x // 16
        n = (x % 16) - 8
    else:
        x_abs = -x
        m = x_abs // 16
        n = (x_abs % 16) - 8
    return n, m

sep = '\\' if sys.platform == 'win32' else '/'

# 小狼毫安装目录
weasel_dir = "C:" + sep + "Program Files (x86)" + sep + "Weasel"

shutil.copytree("." + sep + "moran_pin.userdb" + sep, "." + sep + "_pin_tmp" + sep + "moran_pin.userdb" + sep)

if sys.platform == "darwin":
    env = os.environ.copy()
    env["DYLD_LIBRARY_PATH"] = sep + "Library" + sep + "Input Methods" + sep + "Squirrel.app" + sep + "Contents" + sep + "Frameworks"

    cmd = [
        sep + "Library" + sep + "Input Methods" + sep + "Squirrel.app" + sep + "Contents" + sep + "MacOS" + sep + "rime_dict_manager",
        "-e",
        "moran_pin",
        "." + sep + "moran_pin.txt"
    ]
    subprocess.run(cmd, cwd="." + sep + "_pin_tmp", env=env)
elif sys.platform == "win32":
    cmd = [
        os.path.join(weasel_dir, "rime_dict_manager.exe"),
        "-e",
        "moran_pin",
        "moran_pin.txt"
    ]
    subprocess.run(cmd, cwd="_pin_tmp")
else:
    raise Exception("Unsupported platform:" + sys.platform)

entries = []

with open("." + sep + "_pin_tmp" + sep + "moran_pin.txt", "r") as pin_file:
    while True:
        line = pin_file.readline()
        if not line:
            break
        if line.startswith("#"):
            continue
        parts = line.strip().split("\t")
        if len(parts) != 3:
            continue
        phrase, code, commit = parts
        output_commit, _ = decode(int(commit))
        if int(output_commit) < 0 or phrase == "" or code == "":
            continue
        entries.append((phrase, code, output_commit))

sorted_entries = sorted(entries, key=lambda x: (x[1], -int(x[2])))

with open("moran_pin_export.txt", "w") as export_file:
    for phrase, code, output_commit in sorted_entries:
        export_file.write(f"{phrase}\t{code}\t{output_commit}\n")

shutil.rmtree("." + sep + "_pin_tmp" + sep)
print("已导出到 moran_pin_export.txt")