---@module 'ccmaze.filters.computerCraft'
local computerCraft = {}

--[[ PRIVATE ]]

local builder = require("ccmaze.filters.builder")

---@param updates table Array of StateUpdate.
---@param monitor any The ComputerCraft monitor peripheral to update.
---@param colorMap table A mapping of states to colors for the monitor.
---@return table updates
local function _updateScreen(updates, monitor, colorMap)
    for i = 1, #updates, 1 do
        local u = updates[i]
        monitor.setBackgroundColor(colorMap(u.state))
        monitor.setCursorPos(u.j, u.i)
        monitor.write(" ")
    end
    return updates
end

---@param monitor any The ComputerCraft monitor peripheral to update.
---@param x integer
---@param y integer
---@param txt string The text to display.
---@param maxSize integer The maximum length of the string.
local function _displayText(monitor, x, y, txt, maxSize)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(x, y)
    monitor.write(string.rep(" ", maxSize))
    monitor.setCursorPos(x, y)
    monitor.write(txt)
end

---@param updates table Array of StateUpdate.
---@param monitor any The ComputerCraft monitor peripheral to update.
---@param x integer
---@param y integer
---@param prefix string A prefix string to display.
---@param maxPrefixSize integer The maximum length of the prefix string.
---@return table updates
local function _displayProgress(updates, monitor, x, y, prefix, maxPrefixSize)
    local maxProgress = 0
    for i = 1, #updates, 1 do
        local u = updates[i]
        maxProgress = math.max(maxProgress, u.progress)
    end
    local txt = prefix .. string.format("%.2f", maxProgress * 100) .. "%"
    _displayText(monitor, x, y, txt, maxPrefixSize + 7)
    return updates
end


--[[ PUBLIC ]]

-- Creates a filter that updates a ComputerCraft monitor to display the current state of the maze.
---@param producer thread The coroutine that produces updates.
---@param monitor any The ComputerCraft monitor peripheral to update.
---@param colorMap table A mapping of states to colors for the monitor.
---@return thread # The coroutine acting as a producer with a filter.
function computerCraft.updateScreen(producer, monitor, colorMap)
    return builder.build(producer, _updateScreen, { monitor, colorMap })
end

-- Creates a filter that display the current progress of the generationon on a monitor.
---@param producer thread The coroutine that produces updates.
---@param monitor any The ComputerCraft monitor peripheral to update.
---@param x integer
---@param y integer
---@param prefix string A prefix string to display.
---@param maxPrefixSize integer The maximum length of the prefix string.
---@return thread # The coroutine acting as a producer with a filter.
function computerCraft.displayProgress(producer, monitor, x, y, prefix, maxPrefixSize)
    return builder.build(producer, _displayProgress, { monitor, x, y, prefix, maxPrefixSize })
end

return computerCraft
