--[[
    This Lua module defines a specialized maze generator that uses
    recursive backtracking algorithm to generate a maze.
    It builds the maze by progressively visiting random unvisited neighbor.

    This algorithm is essentially a randomized deep first search.
    The recursive part is replaced by a stack based approach to
    prevent a stack overflow.

    Internally, an other maze modeling is used where wall cells are
    ignored.

    The generator produces updates on the state of the maze during the generation process,
    which can be used to visualize the maze construction in a step by step manner.
]]
---@module 'libmaze.generators.deepSearch'
local deepFirstGenerator = {}

--[[ PRIVATE ]]

local stateUpdate = require("libmaze.stateUpdate")
local abstractGenerator = require("libmaze.generators.abstract")
local stack = require("libmaze.utils.stack")

---@enum CELL_STATES Define all possible cell states for the generator.
local CELL_STATES = {
    VISITED = 1,
    WALL = 2,
    UNVISITED = 3,
    SELECTED = 4
}

---@class DFSGenerator: Generator Implements a maze generator using a recursive backtracking algorithm.
---@field private _internalWidth integer Width of the internal maze (excluding wall cells).
---@field private _internalHeight integer Height of the internal maze (excluding wall cells).
---@field private _cells table States of the internal cells.
---@field private _path Stack A stack of coordinates to tack the path to the starting cell.
---@field private _count integer The number of remaining cells to visit.
---@field private _startCoords table The coordinates of the starting cell.
local DFSGenerator = {
    _internalWidth = 0,
    _internalHeight = 0,
    _cells = {},
    _path = {},
    _count = 0,
    _startCoords = {}
}

---@return number # The normalized generation progression.
function DFSGenerator:_progression()
    return 1.0 - self._count / (self._internalWidth * self._internalHeight - 1)
end

--[[
    Initializes the DFSGenerator, setting up the internal maze states and path.
]]
function DFSGenerator:_init()
    self._internalWidth = math.floor((self.width - 1) / 2)
    self._internalHeight = math.floor((self.height - 1) / 2)
    self._count = self._internalWidth * self._internalHeight - 1 -- 1st cell is visited
    self._path = stack.new()
    -- All cells are unvisited
    for i = 1, self._internalHeight, 1 do
        for j = 1, self._internalWidth, 1 do
            self:_setState({ i = i, j = j }, CELL_STATES.UNVISITED)
        end
    end
    -- Set the first cell coordinates (top-left) to be the start of the path
    self._startCoords = { i = math.random(self._internalHeight), j = math.random(self._internalWidth) }
    self:_setState(self._startCoords, CELL_STATES.VISITED)
    self._path:push(self._startCoords)
end

-- Creates a new DFSGenerator object with the specified width and height.
---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@return DFSGenerator # A new DFSGenerator object for the specified maze dimensions.
function DFSGenerator:new(width, height)
    local obj = abstractGenerator.new(width, height)
    DFSGenerator.__index = DFSGenerator
    setmetatable(DFSGenerator, { __index = getmetatable(obj) })
    setmetatable(obj, DFSGenerator)
    obj.cellStates = CELL_STATES
    return obj
end

-- Creates the maze state update based on the wall between two internal cells.
---@param coords1 table The coordinates of the first cell.
---@param coords2 table The coordinates of the second cell.
---@param state integer The new state of the real maze cell.
---@return StateUpdate # A StateUpdate object for the cell corresponding to the wall in the real maze.
function DFSGenerator:_updateWall(coords1, coords2, state)
    return stateUpdate.new(coords1.i + coords2.i, coords1.j + coords2.j, state, self:_progression())
end

-- Creates the maze state update based on an internal cell.
---@param coords table The coordinates of the cell.
---@param state integer The new state for the cells in the real maze.
---@return StateUpdate # A StateUpdate object for the cell in the real maze.
function DFSGenerator:_updateCell(coords, state)
    return stateUpdate.new(coords.i * 2, coords.j * 2, state, self:_progression())
end

-- Get the state of a cell in the internal maze.
---@param coords table The coordinates of the cell.
---@return CELL_STATES # The state for the corresponding cell.
function DFSGenerator:_getState(coords)
    return self._cells[(coords.i - 1) * self._internalWidth + coords.j]
end

-- Set the state of a cell in the internal maze.
---@param coords table The coordinates of the cell.
---@param state CELL_STATES The new state for the cell.
function DFSGenerator:_setState(coords, state)
    self._cells[(coords.i - 1) * self._internalWidth + coords.j] = state
end

-- Check if a cell in the internal maze is unvisited or not.
---@param coords table The coordinates of the cell.
---@return boolean # True if the cell is unvisited.
function DFSGenerator:_isUnvisited(coords)
    return self:_getState(coords) == CELL_STATES.UNVISITED
end

-- Try to get the position of a random unvisited neighbor cell.
---@param coords table The coordinates of the cell.
---@return table | nil # The coordinates of a random unvisited neighbor cell if possible.
function DFSGenerator:_getRandomNeighbor(coords)
    local top = { i = coords.i - 1, j = coords.j }
    local bottom = { i = coords.i + 1, j = coords.j }
    local left = { i = coords.i, j = coords.j - 1 }
    local right = { i = coords.i, j = coords.j + 1 }

    local neighbors = {}

    if coords.i > 1 and self:_isUnvisited(top) then
        table.insert(neighbors, top)
    end
    if coords.i < self._internalHeight and self:_isUnvisited(bottom) then
        table.insert(neighbors, bottom)
    end
    if coords.j > 1 and self:_isUnvisited(left) then
        table.insert(neighbors, left)
    end
    if coords.j < self._internalWidth and self:_isUnvisited(right) then
        table.insert(neighbors, right)
    end

    if #neighbors == 0 then
        return nil
    else
        return neighbors[math.random(#neighbors)]
    end
end

function DFSGenerator:generate()
    -- Issue initial maze state
    local updates = {}
    for i = 1, self.height, 1 do
        for j = 1, self.width, 1 do
            if (i % 2 == 0) and (j % 2 == 0) and i < self.height and j < self.width then
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.UNVISITED, 0))
            else
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.WALL, 0))
            end
        end
    end
    -- Select the starting position
    table.insert(updates, self:_updateCell(self._path:peek(), CELL_STATES.SELECTED))
    coroutine.yield(updates)

    -- Generation loop
    while self._count > 0 do
        -- Get the current active cell in the path
        local coords = self._path:pop()

        -- Visit the selected cell in the internal maze
        if self:_isUnvisited(coords) then
            self._count = self._count - 1
            self:_setState(coords, CELL_STATES.VISITED)
        end

        -- Gets an unvisited neighbors
        local nextCoords = self:_getRandomNeighbor(coords)
        if nextCoords ~= nil then
            -- Extends to the path
            self._path:push(coords)
            self._path:push(nextCoords)
            -- Break the wall, deselect the current cell and select the next one
            coroutine.yield({
                self:_updateWall(coords, nextCoords, CELL_STATES.VISITED),
                self:_updateCell(coords, CELL_STATES.VISITED),
                self:_updateCell(nextCoords, CELL_STATES.SELECTED),
            })
        else
            -- Deselect the current cell and select the previous one in the path
            coroutine.yield({
                self:_updateCell(coords, CELL_STATES.VISITED),
                self:_updateCell(self._path:peekOr(self._startCoords), CELL_STATES.SELECTED),
            })
        end
    end
    -- Deselect the last selected cell
    coroutine.yield({ self:_updateCell(self._path:popOr(self._startCoords), CELL_STATES.VISITED) })
end

--[[ PUBLIC ]]

---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@return DFSGenerator # A new DFSGenerator object for the specified maze dimensions.
function deepFirstGenerator.new(width, height)
    return DFSGenerator:new(width, height)
end

return deepFirstGenerator
