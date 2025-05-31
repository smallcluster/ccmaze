--[[ Args:
 1st, number, Time to sleep between each generation update.
 2nd, number, Text scale of the monitor.

 THIS RUNS ONLY ON A COMPUTERCRAFT WITH A CONNECTED MONITOR.

 Description: A simple example that continuously run through all available
 generator and display the generation process on a computerCraft monitor.
]]
local args = { ... }


local WAIT_TIME = tonumber(args[1] or "0.05")
local TEXT_SCALE = tonumber(args[2] or "1.0")

-- Imports
local ccmaze = require("ccmaze")

-- ccmaze exists in two versions: modular and single file.
-- To ensure compatibility with both, we use ccmaze.require instead of Lua's built-in require.
-- In the modular version, ccmaze.require is the same as the standard require.
-- In the single file version, it uses an internal lookup table to simulate module loading.
-- By following this pattern, your code will work seamlessly with either version.
local maze = ccmaze.require("ccmaze.maze")
local kg = ccmaze.require("ccmaze.generators.kruskal")
local dsg = ccmaze.require("ccmaze.generators.deepFirst")
local osg = ccmaze.require("ccmaze.generators.originShift")
local ccFilters = ccmaze.require("ccmaze.filters.computerCraft")
local ccPostProcess = ccmaze.require("ccmaze.postprocess.computerCraft")

-- Monitor settings.
local m = peripheral.find("monitor")
m.setBackgroundColor(colors.black)
m.setTextScale(TEXT_SCALE)
m.clear()
local w, h = m.getSize()

-- Some generators and display settings

-- Define the color palettes for each generator.
local colorPalettes = {
    kg = {
        [kg.CELL_STATES.VISITED]   = colors.lime,
        [kg.CELL_STATES.UNVISITED] = colors.lime,
        [kg.CELL_STATES.WALL]      = colors.black,
        [kg.CELL_STATES.SELECTED]  = colors.blue
    },
    dsg = {
        [dsg.CELL_STATES.VISITED]   = colors.lime,
        [dsg.CELL_STATES.UNVISITED] = colors.gray,
        [dsg.CELL_STATES.WALL]      = colors.black,
        [dsg.CELL_STATES.SELECTED]  = colors.blue
    },
    osg = {
        [osg.CELL_STATES.VISITED]  = colors.lime,
        [osg.CELL_STATES.WALL]     = colors.black,
        [osg.CELL_STATES.SELECTED] = colors.blue
    } 
}

-- Each scene is a table with a name, a generator, and a colorMap function.
local scenes = {
    {
        name = "Kruskal",
        generator = kg.new(w, h),
        -- The colorMap function maps the generator's cell states to colors.
        colorMap = function(state)
            return colorPalettes.kg[state] or colors.white
        end
    },
    {
        name = "Deep-first",
        generator = dsg.new(w, h),
        colorMap = function(state)
            return colorPalettes.dsg[state] or colors.white
        end
    },
    {
        name = "Origin-shift",
        generator = osg.new(w, h, w * h * 2),
        colorMap = function(state)
            return colorPalettes.osg[state] or colors.white
        end
    }
}

-- Find the largest generator name.
local maxNameSize = 0
for i = 1, #scenes, 1 do
    maxNameSize = math.max(maxNameSize, #scenes[i].name)
end

--- Main loop ---
local index = 0
while true do
    -- Fetch the next scene :
    index = (index % #scenes) + 1
    local scene = scenes[index]

    -- We get the production coroutine from the generator.
    local producer = scene.generator:producer()
    -- To display each maze update, we can use a special filter that wraps
    -- our generator producer :
    local drawFilter = ccFilters.updateScreen(producer, m, scene.colorMap)
    -- We can also show the progression by composing our wrapper with an other filter:
    local finalProducer = ccFilters.displayProgress(
        drawFilter,
        m,
        1, 1,
        scene.name .. ": ", maxNameSize + 2)
    -- Note: See "ccmaze.filters.computerCraft" to see how filters can be user created.

    -- Let's wait a little after each update to be able to visualize the generation.
    -- Since a computer is a coroutine by itself, we can't sleep inside an other
    -- sub-coroutine, which make the use of filters impossible here.

    -- Instead we use a postprocessing callback called on this "thread" after each updates.
    -- Since the minimal sleep time possible is 1 game tick (0.05s), we remove the wait postprocess
    -- if it's lower (beware, now the generation can't run more than 30seconds before computerCraft terminate this program).
    local postProcess = function (_) return _ end -- A callback that do nothing
    if WAIT_TIME >= 0.05 then
        postProcess = ccPostProcess.wait(WAIT_TIME)
    end
    -- Note: callback chaining is possible by composing them on the last optional argument.
    -- See "ccmaze.postprocess.computerCraft" to see how postprocess can be user created.

    -- We create a new maze, each update will run through our filters and postprocessing.
    maze.new(w, h, finalProducer, postProcess)

    sleep(3) -- Wait a little before switching to the next scene.
end
