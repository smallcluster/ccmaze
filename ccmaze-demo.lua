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
local maze = require("ccmaze.maze")
local kg = require("ccmaze.generators.kruskal")
local dsg = require("ccmaze.generators.deepFirst")
local osg = require("ccmaze.generators.originShift")
local ccFilters = require("ccmaze.filters.computerCraft")
local ccPostProcess = require("ccmaze.postprocess.computerCraft")

-- Monitor settings.
local m = peripheral.find("monitor")
m.setBackgroundColor(colors.black)
m.setTextScale(TEXT_SCALE)
m.clear()
local w, h = m.getSize()

-- Some generators and display settings
local scenes = {
    {
        name = "Kruskal",
        generator = kg.new(w, h),
        color_table = {
            colors.lime,
            colors.black,
            colors.gray,
            colors.blue
        }
    },
    {
        name = "Deep-first",
        generator = dsg.new(w, h),
        color_table = {
            colors.lime,
            colors.black,
            colors.gray,
            colors.blue
        }
    },
    {
        name = "Origin-shift",
        generator = osg.new(w, h, w * h * 2),
        color_table = {
            colors.lime,
            colors.black,
            colors.blue
        }
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
    local drawFilter = ccFilters.updateScreen(producer, m, scene.color_table)
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
