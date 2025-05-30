-- This file was auto-generated on 2025-05-30 21:25:21

local dirs = {
    "ccmaze/filters",
    "ccmaze/generators",
    "ccmaze/postprocess",
    "ccmaze/tests",
    "ccmaze/utils",
}

local files = {
    "ccmaze/maze.lua",
    "ccmaze/stateUpdate.lua",
    "ccmaze/filters/builder.lua",
    "ccmaze/filters/computerCraft.lua",
    "ccmaze/generators/abstract.lua",
    "ccmaze/generators/deepFirst.lua",
    "ccmaze/generators/kruskal.lua",
    "ccmaze/generators/originShift.lua",
    "ccmaze/postprocess/builder.lua",
    "ccmaze/postprocess/computerCraft.lua",
    "ccmaze/tests/manualCheck.lua",
    "ccmaze/utils/dSet.lua",
    "ccmaze/utils/optFunc.lua",
    "ccmaze/utils/shuffle.lua",
    "ccmaze/utils/stack.lua",
    "example.lua",
}


local base_url = "https://raw.githubusercontent.com/smallcluster/ccmaze/refs/heads/master/"

-- Remove the old ccmaze directory if it exists.
if fs.exists( "ccmaze" ) then
    fs.delete( "ccmaze" )
end

-- Create the directories.
for _, dir in ipairs(dirs) do
    fs.makeDir(dir)
end

-- Download the files.
for _, file in ipairs(files) do
    local sUrl = base_url .. file
    -- Get the file from the URL.
    local response = http.get(sUrl)
    local sResponse = response.readAll()
    response.close()
    -- Write the file to the filesystem.
    local f = fs.open(file, "w")
    f.write(sResponse)
    f.close()
end
