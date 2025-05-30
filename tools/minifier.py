import os

lua_custom_require = """
local files = {}
local globalRequire = require
local require = function(path) 
    return files[path]() or globalRequire(path) 
end
local ccmaze = {require = require}
"""

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
    code = f"files['{path.replace("\\", ".").replace("/",".")}'] = function(...)\n"
    skip = False
    with open(path + ".lua", "r") as f:
        code += f.read()
    code += "\nend\n"
    return code


if __name__ == "__main__":
    directory = "ccmaze"
    files = find_files(directory)
    #f.write(f"-- This file was auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Create the merged Lua code of all modules
    lua_code = lua_custom_require
    for path in files:
        lua_code+=lua_file_function(path)
    lua_code += "return ccmaze"

    # save it to a tmp file
    with open("ccmaze-tmp.lua", "w") as f:
        f.write(lua_code)

    # Minify it using luamin
    os.system("luamin -f ccmaze-tmp.lua > ccmaze.lua")

    # Remove the tmp file
    os.remove("ccmaze-tmp.lua")