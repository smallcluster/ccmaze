--[[
    A Maze is a grid of cells represented by a 1D array, where the cells are ordered
    by columns. Each cell has an integer "state" representing its condition, such as
    being a wall or a visited space.

    The states are typically set by a maze generator, the state values are incremented
    sequentially, starting from 1.

    The maze structure operates in a consumer-producer pattern, where:
    - The maze acts as a **consumer**, receiving updates from a **producer** coroutine that generates the maze.
    - The **generator** is responsible for producing state updates for each cell in the maze.
    - A maze update consists of modifying the cell states in the grid based on the produced updates.

    This system allows for asynchronous updates to the maze, enabling features such as
    real-time animations or visual feedback during the maze generation process.
--]]

---@module 'ccmaze.maze'
local maze = {}

--[[ PRIVATE ]]

local optFunc = require("ccmaze.utils.optFunc")

---@class Maze A maze is a grid composed of cells represented by a state (integer).
---@field width integer The grid width.
---@field height integer The grid height.
---@field cells table The unidirectional array of cells, represented by their states.
local Maze = {
    width = 0,
    height = 0,
    cells = {}
}

-- Updates the maze grid by consuming state updates produced by a maze generator coroutine.
-- This function iterates through the generator coroutine, retrieves updates for the maze cells,
-- and updates the cell states in the grid accordingly.
-- Note: update are consumed for left to right in the given array by the generator.
---@param producer thread The coroutine of the maze generator that produces updates.
---@param onUpdates function An optional post processing callback on retrieved updates.
function Maze:rebuild(producer, onUpdates)
    repeat
        local status, updates = coroutine.resume(producer)
        if updates ~= nil and status then
            for i = 1, #updates, 1 do
                local u = updates[i]
                self.cells[(u.i - 1) * self.width + u.j] = u.state
            end
            optFunc.create1(onUpdates)(updates)
        end
    until not status
end

-- Constructor for creating a Maze.
-- Initializes it with the specified size and runs the provided
-- generation coroutine to fill the grid with states.
---@param width integer The width of the maze.
---@param height integer The height of the maze.
---@param producer thread The maze producer algorithm that produces state updates.
---@param onUpdates function An optional post processing callback on retrieved updates.
---@return Maze # A new Maze object with the generated maze grid.
function Maze:new(width, height, producer, onUpdates)
    local m = { width = width, height = height, cells = {} }
    setmetatable(m, self)
    self.__index = self
    for i = 1, width*height, 1 do
        m.cells[i] = 0
    end
    m:rebuild(producer, optFunc.create1(onUpdates))
    return m
end

--[[ PUBLIC ]]

-- Returns a new Maze object.
-- Initializes it with the specified size and runs the provided
-- generation coroutine to fill the grid with states.
---@param width integer The width of the maze.
---@param height integer The height of the maze.
---@param producer thread The maze producer algorithm that produces state updates.
---@param onUpdates function An optional post processing callback on retrieved updates.
---@return Maze # A new Maze object with the generated maze grid.
function maze.new(width, height, producer, onUpdates)
    return Maze:new(width, height, producer, optFunc.create1(onUpdates))
end

return maze
