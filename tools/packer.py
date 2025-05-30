import os

# Emulate the Lua require function by using a lookup table
# that store each lua module as a function.
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

def generate_lua_code(files):
    lua_code = lua_custom_require
    for path in files:
        lua_code += lua_file_function(path)
    lua_code += "return ccmaze"
    return lua_code

def save_lua_file():
    directory = "ccmaze"
    files = find_files(directory)
    # Create the merged Lua code of all modules
    lua_code = generate_lua_code(files)
    # save it
    with open("ccmaze.lua", "w") as f:
        f.write(lua_code)