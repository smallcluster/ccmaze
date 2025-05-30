import os
from datetime import datetime

lua_body_code = """
local base_url = "https://raw.githubusercontent.com/smallcluster/ccmaze/refs/heads/master/"

-- Remove the old ccmaze directory if it exists.
if fs.exists( "ccmaze" ) then
    print( "Removing old ccmaze directory..." )
    fs.delete( "ccmaze" )
end

-- Create the directories.
print("Creating ccmaze directory...")
for _, dir in ipairs(dirs) do
    fs.makeDir(dir)
end

-- Download the files.
local currentFile = 0
local totalFiles = #files
for _, file in ipairs(files) do
    currentFile = currentFile + 1
    local sUrl = base_url .. file
    -- Get the file from the URL.
    print("Downloading (" .. currentFile .. "/" .. totalFiles .. "): " .. sUrl)
    local response = http.get(sUrl)
    local sResponse = response.readAll()
    response.close()
    -- Write the file to the filesystem.
    local f = fs.open(file, "w")
    f.write(sResponse)
    f.close()
end

print("All files downloaded successfully!")
"""

# find all files in the ccmaze directory and its subdirectories
def find_files(directory):
    files = []
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
                files.append(os.path.join(root, filename))
    return files

def find_dirs(directory):
    dirs = []
    for root, subdirs, filenames in os.walk(directory):
        for subdir in subdirs:
            dirs.append(os.path.join(root, subdir))
    return dirs

# Convert a list of files or directories to a Lua list of strings
def files_to_lua(files, var_name):
    lua_list = "local "+f"{var_name}"+" = {\n"
    for f in files: 
        formatted_f = f.replace("\\", "/")
        lua_list += f'    "{formatted_f}",\n'
    lua_list += "}\n"
    return lua_list

if __name__ == "__main__":
    directory = "ccmaze"

    dirs = find_dirs(directory)
    files = find_files(directory)

    files_array = files_to_lua(files, "files")
    dirs_array = files_to_lua(dirs, "dirs")

    # Create the Lua code
    with open("ccmaze-dl.lua", "w") as f:
        f.write(f"-- This file was auto-generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(dirs_array+"\n")
        f.write(files_array+"\n")
        f.write(lua_body_code)