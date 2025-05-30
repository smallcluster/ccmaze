import os
from datetime import datetime

lua_custom_require = """local files = {}
local globalRequire = require
local require = function(path) return files[path]() or globalRequire(path) end
local ccmaze = {require = require}"""

def find_files(directory):
    files = []
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
                path = os.path.join(root, filename).replace("\\", "/")
                # Get only lua files
                if not filename.endswith(".lua"):
                    continue
                # Skip files are part of the test suite
                if path.startswith("ccmaze/tests"):
                    continue
                # Skip the init.lua file which is not needed here
                if path.startswith("ccmaze/init.lua"):
                    continue
                files.append(os.path.join(root, "".join(filename.split('.')[:-1])))
    return files

def lua_file_function(path):
    code = f"files['{path.replace("\\", ".").replace("/",".")}'] = function(...) "
    skip = False
    with open(path + ".lua", "r") as f:
        for line in f.readlines():
            line_stripped = line.strip()
            if line_stripped.startswith("--["):
                skip = True
            if line_stripped.find("]]") > -1 and skip:
                skip = False
                continue
            if line_stripped.startswith("--") or skip:
                continue
            if line_stripped.find("--"):
                line_stripped = line_stripped.split("--")[0].strip()
            code += line_stripped +" "
    code += " end "
    return code


if __name__ == "__main__":
    directory = "ccmaze"
    files = find_files(directory)
    with open("ccmaze.lua", "w") as f:
        f.write(f"-- This file was auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(lua_custom_require.replace("\n", " "))
        for path in files:
            f.write(lua_file_function(path))
        f.write("return ccmaze")
