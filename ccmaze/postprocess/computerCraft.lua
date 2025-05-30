---@module 'libmaze.postprocess.computerCraft'
local computerCraft = {}

--[[ PRIVATE ]]

local builder = require("libmaze.postprocess.builder")

---@param updates table Array of StateUpdate.
---@param time number The time to wait.
---@return table # Array of StateUpdate.
local function _wait(updates, time)
    sleep(time)
    return updates
end

---@param updates table Array of StateUpdate.
---@param monitor any The computer craft monitor.
---@param color_table table A mapping of states to colors for the monitor.
---@return table # Array of StateUpdate.
local function _updateScreen(updates, monitor, color_table)
    for i = 1, #updates, 1 do
        local u = updates[i]
        monitor.setBackgroundColor(color_table[u.state])
        monitor.setCursorPos(u.j, u.i)
        monitor.write(" ")
    end
    return updates
end

--[[ PUBLIC ]]

---@param time number The time to wait.
---@param onUpdates function Next optional post processing callback.
---@return function # The post processing callback.
function computerCraft.wait(time, onUpdates)
    return builder.build(_wait, { time }, onUpdates)
end

---@param monitor any The computer craft monitor.
---@param color_table table A mapping of states to colors for the monitor.
---@param onUpdates function Next optional post processing callback.
---@return function # The post processing callback.
function computerCraft.updateScreen(monitor, color_table, onUpdates)
    return builder.build(_updateScreen, { monitor, color_table }, onUpdates)
end

return computerCraft
