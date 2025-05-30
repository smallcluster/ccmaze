
local files = {}
local globalRequire = require
local require = function(path) 
    return files[path]() or globalRequire(path) 
end
local ccmaze = {require = require}
files['ccmaze.maze'] = function(...)
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
function Maze:update_grid(producer, onUpdates)
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
    m:update_grid(producer, optFunc.create1(onUpdates))
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

end
files['ccmaze.stateUpdate'] = function(...)
---@module 'ccmaze.stateUpdate'
local stateUpdate = {}

--[[ PRIVATE ]]

---@class StateUpdate Holds the information for updating the state of a single cell in the maze.
---@field i integer The row index of the cell to be updated.
---@field j integer The column index of the cell to be updated.
---@field state integer The new state of the cell.
---@field progress number The normalized total generation progression.
local StateUpdate = {
    i = 0,
    j = 0,
    state = 0,
    progress = 0
}

-- Creates a new StateUpdate object with the provided cell position and state.
---@param i integer The row index of the cell to be updated.
---@param j integer The column index of the cell to be updated.
---@param state integer The new state of the cell.
---@param progress number The normalized total generation progression.
---@return StateUpdate # A new StateUpdate object containing the cell's position and state.
function StateUpdate:new(i, j, state, progress)
    local s = { i = i, j = j, state = state, progress = progress }
    setmetatable(s, self)
    self.__index = self
    return s
end

--[[ PUBLIC ]]

-- Creates a new StateUpdate object with the provided cell position and state.
---@param i integer The row index of the cell to be updated.
---@param j integer The column index of the cell to be updated.
---@param state integer The new state of the cell.
---@param progress number The normalized total generation progression.
---@return StateUpdate # A new StateUpdate object containing the cell's position and state.
function stateUpdate.new(i, j, state, progress)
    return StateUpdate:new(i, j, state, progress)
end

return stateUpdate

end
files['ccmaze.filters.builder'] = function(...)
---@module 'ccmaze.filters.builder'
local builder = {}

--[[ PUBLIC ]]

-- Creates a filter from a function operating on updates.
---@param producer thread The coroutine that produces updates.
---@param f function A filter function operating on updates.
---@param args table The other arguments needed by the filter function.
---@return thread # The coroutine acting as a producer with a filter.
function builder.build(producer, f, args)
    return coroutine.create(function()
        repeat
            local status, updates = coroutine.resume(producer)
            if updates ~= nil and status then
                updates = f(updates, unpack(args or {}))
                coroutine.yield(updates)
            end
        until not status
    end)
end

return builder

end
files['ccmaze.filters.computerCraft'] = function(...)
---@module 'ccmaze.filters.computerCraft'
local computerCraft = {}

--[[ PRIVATE ]]

local builder = require("ccmaze.filters.builder")

---@param updates table Array of StateUpdate.
---@param monitor any The ComputerCraft monitor peripheral to update.
---@param color_table table A mapping of states to colors for the monitor.
---@return table updates
local function _updateScreen(updates, monitor, color_table)
    for i = 1, #updates, 1 do
        local u = updates[i]
        monitor.setBackgroundColor(color_table[u.state])
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
---@param color_table table A mapping of states to colors for the monitor.
---@return thread # The coroutine acting as a producer with a filter.
function computerCraft.updateScreen(producer, monitor, color_table)
    return builder.build(producer, _updateScreen, { monitor, color_table })
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

end
files['ccmaze.generators.abstract'] = function(...)
---@module 'ccmaze.generators.abstract'
local abstractGenerator = {}

--[[ PRIVATE ]]

---@class Generator Represents the generator for a maze with specified width and height.
---@field width integer The width of the maze.
---@field height integer The height of the maze.
---@field cellStates table Enum of the possible state of a cell.
local Generator = {
    width = 0,
    height = 0,
    cellStates = {}
}

-- Constructor for creating a generator with the specified width and height of the maze.
---@param width integer The width of the maze.
---@param height integer The height of the maze.
---@return Generator # A new Generator object ready to produce maze updates.
function Generator:new(width, height)
    Generator.__index = Generator
    local obj = { width = width, height = height, cellStates = {} }
    setmetatable(obj, Generator)
    return obj
end

-- Initializes the generator and returns a coroutine that can be used
-- to run the maze generation process asynchronously.
---@return thread # A coroutine for the maze generation process.
function Generator:producer()
    return coroutine.create(function()
        self:_init()
        self:generate()
    end)
end

-- An abstract method that should be implemented in a subclass to
-- define the maze generation algorithm.
function Generator:generate()
    error("Abstract method Generator:generate called", 1)
end

-- An abstract method intended for internal initialization before
-- the maze generation starts. It must be implemented in a subclass.
function Generator:_init()
    error("Abstract method Generator:_init called", 1)
end

-- An abstract method intended that returns the normalized generation progression .
-- It must be implemented in a subclass.
function Generator:_progression()
    error("Abstract method Generator:_progression called", 1)
end

--[[ PUBLIC ]]

-- Returns a new generator with the specified width and height of the maze.
---@param width integer The width of the maze.
---@param height integer The height of the maze.
---@return Generator # A new Generator object ready to produce maze updates.
function abstractGenerator.new(width, height)
    return Generator:new(width, height)
end

return abstractGenerator

end
files['ccmaze.generators.deepFirst'] = function(...)
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
---@module 'ccmaze.generators.deepSearch'
local deepFirstGenerator = {}

--[[ PRIVATE ]]

local stateUpdate = require("ccmaze.stateUpdate")
local abstractGenerator = require("ccmaze.generators.abstract")
local stack = require("ccmaze.utils.stack")

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

end
files['ccmaze.generators.kruskal'] = function(...)
--[[
    This Lua module defines a specialized maze generator that uses
    Kruskal's algorithm to generate a maze.
    It builds the maze by progressively removing walls between cells,
    ensuring that all path are connected while avoiding cycles.

    The KruskalGenerator generator uses a disjoint-set data structure
    to track sets of connected cells and a stack of walls to randomly choose
    from.

    Internally, an other maze modeling is used where wall cells are
    ignored. Instead, cells have implicit walls (top and left walls).

    The generator produces updates on the state of the maze during the generation process,
    which can be used to visualize the maze construction in a step by step manner.
]]
---@module 'ccmaze.generators.Kruskal'
local kruskalGenerator = {}

---[[ PRIVATE ]]

local stateUpdate = require("ccmaze.stateUpdate")
local abstractGenerator = require("ccmaze.generators.abstract")
local dSet = require("ccmaze.utils.dSet")
local stack = require("ccmaze.utils.stack")


---@enum DIRECTIONS Define possible wall orientations.
local DIRECTIONS = {
    VERTICAL = 0,
    HORIZONTAL = 1
}

-- Each cell have exactly 2 walls: the top and left walls.
---@class Wall Represents a wall between two cells in the maze.
---@field i integer The row index of the associated cell's position.
---@field j integer The column index of the associated cell's position.
---@field direction integer The direction of the wall (VERTICAL or HORIZONTAL).
local Wall = {
    i = 0,
    j = 0,
    direction = DIRECTIONS.VERTICAL
}

-- Creates a new Wall object representing a wall between two cells.
---@param i integer The row index of the associated cell's position.
---@param j integer The column index of the associated cell's position.
---@param direction integer The direction of the wall (VERTICAL or HORIZONTAL).
---@return Wall # A new Wall object.
function Wall.new(i, j, direction)
    return { i = i, j = j, direction = direction }
end

---@enum CELL_STATES Define all possible cell states for the generator.
local CELL_STATES = {
    VISITED = 1,
    WALL = 2,
    UNVISITED = 3,
    SELECTED = 4
}


---@class KruskalGenerator : Generator Implements a maze generator using Kruskal's algorithm.
---@field private _internalWidth integer Width of the internal maze (excluding wall cells).
---@field private _internalHeight integer Height of the internal maze (excluding wall cells).
---@field private _sets table A table containing disjoint sets to track connected components of the maze.
---@field private _walls Stack A stack of walls to be removed during maze generation.
---@field private _count integer The number of remaining walls to be removed.
local KruskalGenerator = {
    _internalWidth = 0,
    _internalHeight = 0,
    _sets = {},
    _walls = {},
    _count = 0,
}

---@return number # The normalized generation progression.
function KruskalGenerator:_progression()
    return 1.0 - self._count / (self._internalWidth * self._internalHeight - 1)
end

--[[
    Initializes the KruskalGenerator, setting up the maze dimensions, wall stack, and disjoint sets.

    This method sets up the internal representation of the maze, creates a stack of walls, and initializes
    the disjoint sets to track connected cells. It also randomizes the order of walls for later removal.
]]
function KruskalGenerator:_init()
    self._internalWidth = math.floor((self.width - 1) / 2)
    self._internalHeight = math.floor((self.height - 1) / 2)
    self._count = self._internalWidth * self._internalHeight - 1
    self._walls = stack.new()
    self._sets = {}
    -- Fill the stack of walls and the disjoint sets
    for i = 1, self._internalHeight, 1 do
        for j = 1, self._internalWidth, 1 do
            self._sets[(i - 1) * self._internalWidth + j] = dSet.makeSet({ i = i, j = j })
            -- Wall Anchor: top-right
            if i > 1 then
                self._walls:push(Wall.new(i, j, DIRECTIONS.VERTICAL))
            end
            if j > 1 then
                self._walls:push(Wall.new(i, j, DIRECTIONS.HORIZONTAL))
            end
        end
    end
    -- Randomize walls order
    self._walls:shuffle()
end

-- KruskalGenerator's constructor.
---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@return KruskalGenerator # A new KruskalGenerator object for the specified maze dimensions.
function KruskalGenerator:new(width, height)
    local obj = abstractGenerator.new(width, height)
    KruskalGenerator.__index = KruskalGenerator
    setmetatable(KruskalGenerator, { __index = getmetatable(obj) })
    setmetatable(obj, KruskalGenerator)
    obj.cellStates = CELL_STATES
    return obj
end

-- Retrieves the disjoint sets of cells for the two sides of a wall.
---@param wall Wall The wall to check.
---@return DSet, DSet # Two disjoint sets corresponding to the regions separated by the wall.
function KruskalGenerator:_getSets(wall)
    if wall.direction == DIRECTIONS.VERTICAL then
        return self._sets[(wall.i - 2) * self._internalWidth + wall.j], self._sets
        [(wall.i - 1) * self._internalWidth + wall.j]
    else
        return self._sets[(wall.i - 1) * self._internalWidth + wall.j - 1],
            self._sets[(wall.i - 1) * self._internalWidth + wall.j]
    end
end

-- Creates the maze state update based on the specified wall and state.
---@param wall Wall The wall to update.
---@param state integer The new state of the real maze cell.
---@return StateUpdate # A StateUpdate object for the cell corresponding to the wall in the real maze.
function KruskalGenerator:_updateFromWall(wall, state)
    local ci = wall.i * 2
    local cj = wall.j * 2
    if wall.direction == DIRECTIONS.VERTICAL then
        ci = ci - 1
    end
    if wall.direction == DIRECTIONS.HORIZONTAL then
        cj = cj - 1
    end
    return stateUpdate.new(ci, cj, state, self:_progression())
end

-- Creates the maze state update based on a internal cell and state.
---@param set DSet The disjoint set of the internal cell.
---@param state integer The new state for the cells in the real maze.
---@return StateUpdate # A StateUpdate object for the cell in the real maze.
function KruskalGenerator:_updateFromSet(set, state)
    local ci = set.data.i * 2
    local cj = set.data.j * 2
    return stateUpdate.new(ci, cj, state, self:_progression())
end

function KruskalGenerator:generate()
    -- Issue initial maze state
    local updates = {}
    for i = 1, self.height, 1 do
        for j = 1, self.width, 1 do
            if (i % 2 == 0) and (j % 2 == 0) and i < self.height and j < self.width  then
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.UNVISITED, 0))
            else
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.WALL, 0))
            end
        end
    end
    -- Select the first wall
    coroutine.yield({ self:_updateFromWall(self._walls:peek(), CELL_STATES.SELECTED) })
    coroutine.yield(updates)

    -- Generation loop
    local startCoord = { i = 0, j = 0 }
    while self._count > 0 do
        local wall = self._walls:pop()

        local sa, sb = self:_getSets(wall)

        -- Can't break an edge inside the same set of cells
        if sa:connected(sb) then
            -- Deselect this wall and select the next wall
            local updates = { self:_updateFromWall(wall, CELL_STATES.WALL) }
            if not self._walls:isEmpty() then
                table.insert(updates, self:_updateFromWall(self._walls:peek(), CELL_STATES.SELECTED))
            end
            coroutine.yield(updates)
        else
            -- Decrease the number of walls to open
            self._count = self._count - 1
            local updates = {
                -- Break the wall
                self:_updateFromWall(wall, CELL_STATES.VISITED),
                -- Makes sure the separating cells are visited
                self:_updateFromSet(sa, CELL_STATES.VISITED),
                self:_updateFromSet(sb, CELL_STATES.VISITED)
            }
            -- Select the next wall if possible
            if not self._walls:isEmpty() then
                table.insert(updates, self:_updateFromWall(self._walls:peek(), CELL_STATES.SELECTED))
            end
            coroutine.yield(updates)
            -- Merge regions
            sa:union(sb)
        end
    end
    -- Remove selection
    if not self._walls:isEmpty() then
        coroutine.yield({ self:_updateFromWall(self._walls:peek(), CELL_STATES.WALL) })
    end
end

--[[ PUBLIC ]]

---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@return KruskalGenerator # A new KruskalGenerator object for the specified maze dimensions.
function kruskalGenerator.new(width, height)
    return KruskalGenerator:new(width, height)
end

return kruskalGenerator

end
files['ccmaze.generators.originShift'] = function(...)
--[[
    This Lua module defines a specialized maze generator that uses
    an origin shifting algorithm to generate a maze.
    It builds the maze by progressively moving the root of an spanning tree.

    This algorithm essentially start with an initial directed tree where its overall
    flow always leads to the root. Then we promote a random neighbor of the root to
    become the new root, while ensuring the connectivity and flow of the tree :

     - The new root loose it's parent node
     - The current root connects to the new root

    Internally, an other maze modeling is used where wall cells are
    ignored.

    The generator produces updates on the state of the maze during the generation process,
    which can be used to visualize the maze construction in a step by step manner.
]]
---@module 'ccmaze.generators.originShift'
local originShiftGenerator = {}

--[[ PRIVATE ]]

local stateUpdate = require("ccmaze.stateUpdate")
local abstractGenerator = require("ccmaze.generators.abstract")

---@class Node A node to represent a tree structure. Each node point to only one parent, up to the root.
---@field parent Node | nil The optional parent node. A root node do not have a parent (nil value).
local Node = {
    parent = {},
    coords = { i = 0, j = 0 }
}

---@return Node # A new node object.
---@param i integer The row index.
---@param j integer The column index.
function Node.new(i, j)
    return { parent = nil, coords = { i = i, j = j } }
end

---@enum CELL_STATES Define all possible cell states for the generator.
local CELL_STATES = {
    VISITED = 1,
    WALL = 2,
    SELECTED = 3
}

---@class OSGenerator: Generator Implements a maze generator using a recursive backtracking algorithm.
---@field private _internalWidth integer Width of the internal maze (excluding wall cells).
---@field private _internalHeight integer Height of the internal maze (excluding wall cells).
---@field private _nodes table Nodes of each cells in the pre made tree.
---@field private _count integer The number of remaining moves to perform.
---@field private _nbSteps integer The number of total moves to perform.
---@field private _root Node Node representing the tree root.
local OSGenerator = {
    _internalWidth = 0,
    _internalHeight = 0,
    _nodes = {},
    _count = 0,
    _nbSteps = 0,
    _root = {}
}

---@return number # The normalized generation progression.
function OSGenerator:_progression()
    return 1.0 - self._count / self._nbSteps
end

--[[
    Initializes the OSGenerator, setting up the internal maze states and path.
]]
function OSGenerator:_init()
    self._internalWidth = math.floor((self.width - 1) / 2)
    self._internalHeight = math.floor((self.height - 1) / 2)
    self._count = self._nbSteps
    -- Create all nodes
    for i = 1, self._internalHeight, 1 do
        for j = 1, self._internalWidth, 1 do
            self._nodes[(i - 1) * self._internalWidth + j] = Node.new(i, j)
        end
    end

    -- Now initialize a default tree with a left to right flow on rows
    -- and a top to bottom flow on the last column.
    for i = 1, self._internalHeight, 1 do
        for j = 1, self._internalWidth - 1, 1 do
            self._nodes[(i - 1) * self._internalWidth + j].parent = self._nodes[(i - 1) * self._internalWidth + j + 1]
        end
        if i < self._internalHeight then
            self._nodes[i * self._internalWidth].parent = self._nodes[(i + 1) * self._internalWidth]
        end
    end

    -- Set the root coordinates to the bottom-right of the maze.
    self._root = self:_getNode({ i = self._internalHeight, j = self._internalWidth })
end

-- Creates a new OSGenerator object with the specified width and height.
---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@param nbSteps integer The number of total moves to perform.
---@return OSGenerator # A new OSGenerator object for the specified maze dimensions.
function OSGenerator:new(width, height, nbSteps)
    local obj = abstractGenerator.new(width, height)
    OSGenerator.__index = OSGenerator
    setmetatable(OSGenerator, { __index = getmetatable(obj) })
    setmetatable(obj, OSGenerator)
    obj.cellStates = CELL_STATES
    obj._nbSteps = nbSteps
    return obj
end

-- Creates the maze state update based on the wall between two internal cells.
---@param coords1 table The coordinates of the first cell.
---@param coords2 table The coordinates of the second cell.
---@param state integer The new state of the real maze cell.
---@return StateUpdate # A StateUpdate object for the cell corresponding to the wall in the real maze.
function OSGenerator:_updateWall(coords1, coords2, state)
    return stateUpdate.new(coords1.i + coords2.i, coords1.j + coords2.j, state, self:_progression())
end

-- Creates the maze state update based on an internal cell.
---@param coords table The coordinates of the cell.
---@param state integer The new state for the cells in the real maze.
---@return StateUpdate # A StateUpdate object for the cell in the real maze.
function OSGenerator:_updateCell(coords, state)
    return stateUpdate.new(coords.i * 2, coords.j * 2, state, self:_progression())
end

-- Get the node of a cell in the internal maze.
---@param coords table The coordinates of the cell.
---@return Node # The node for the corresponding cell.
function OSGenerator:_getNode(coords)
    return self._nodes[(coords.i - 1) * self._internalWidth + coords.j]
end

-- Gets the position of a random neighbor node.
---@param coords table The coordinates of the cell.
---@return table # The coordinates of a random neighbor node.
function OSGenerator:_getRandomNeighbor(coords)
    local top = { i = coords.i - 1, j = coords.j }
    local bottom = { i = coords.i + 1, j = coords.j }
    local left = { i = coords.i, j = coords.j - 1 }
    local right = { i = coords.i, j = coords.j + 1 }

    local neighbors = {}

    if coords.i > 1 then
        table.insert(neighbors, top)
    end
    if coords.i < self._internalHeight then
        table.insert(neighbors, bottom)
    end
    if coords.j > 1 then
        table.insert(neighbors, left)
    end
    if coords.j < self._internalWidth then
        table.insert(neighbors, right)
    end

    return neighbors[math.random(#neighbors)]
end

function OSGenerator:generate()
    -- Issue initial maze state
    local updates = {}
    for i = 1, self.height, 1 do
        for j = 1, self.width, 1 do
            local rowsCond = (i % 2 == 0 and j > 1 and j < self.width and i < self.height)
            local lastColCond = (i > 1 and i < self.height and j == self.width - 1)
            if rowsCond or lastColCond then
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.VISITED, 0))
            else
                table.insert(updates, stateUpdate.new(i, j, CELL_STATES.WALL, 0))
            end
        end
    end
    table.insert(updates, self:_updateCell(self._root.coords, CELL_STATES.SELECTED))
    coroutine.yield(updates)

    -- Generation loop
    while self._count > 0 do
        -- Get the next root
        local nextRootCoords = self:_getRandomNeighbor(self._root.coords)
        local nextRoot = self:_getNode(nextRootCoords)

        coroutine.yield({
            -- Close the wall between the new root and its parent
            self:_updateWall(nextRootCoords, nextRoot.parent.coords, CELL_STATES.WALL),
            -- THEN break the wall between the previous root and the new root
            self:_updateWall(self._root.coords, nextRootCoords, CELL_STATES.VISITED),
            -- Deselect the previous root
            self:_updateCell(self._root.coords, CELL_STATES.VISITED),
            -- Select the next root
            self:_updateCell(nextRootCoords, CELL_STATES.SELECTED),
        })

        -- Update nodes linking
        nextRoot.parent = nil
        self._root.parent = nextRoot
        self._root = nextRoot

        -- Update counter
        self._count = self._count - 1
    end
    -- Deselect the root
    coroutine.yield({ self:_updateCell(self._root.coords, CELL_STATES.VISITED) })
end

--[[ PUBLIC ]]

---@param width integer The width of the real maze (including wall cells).
---@param height integer The height of the real maze (including wall cells).
---@param nbSteps integer The number of total moves to perform.
---@return OSGenerator # A new OSGenerator object for the specified maze dimensions.
function originShiftGenerator.new(width, height, nbSteps)
    return OSGenerator:new(width, height, nbSteps)
end

return originShiftGenerator

end
files['ccmaze.postprocess.builder'] = function(...)
---@module 'ccmaze.postprocess.builder'
local builder = {}

--[[ PRIVATE ]]

local optFunc = require("ccmaze.utils.optFunc")

--[[ PUBLIC ]]

-- Creates a filter from a function operating on updates.
---@param f function A filter function operating on updates.
---@param args table The arguments needed by the filter function.
---@param onUpdates function Next optional post processing callback.
---@return function # The post processing callback.
function builder.build(f, args, onUpdates)
    return function(updates)
        optFunc.create1(onUpdates)(f(updates, unpack(args)))
    end
end

return builder

end
files['ccmaze.postprocess.computerCraft'] = function(...)
---@module 'ccmaze.postprocess.computerCraft'
local computerCraft = {}

--[[ PRIVATE ]]

local builder = require("ccmaze.postprocess.builder")

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

end
files['ccmaze.utils.dSet'] = function(...)
--[[
  Simple disjoint sets based on Union-find algorithms.

  This implementation balance each union by its rank to reduce search time.
  Each find will also perform a path compression to accelerate future lookups.

  See https://en.wikipedia.org/wiki/Disjoint-set_data_structure
--]]
local dSet = {}

--[[ PRIVATE ]]

---@class DSet The disjoint set structure.
---@field data any The user data associated with the set.
---@field private _parent DSet The representative disjoint set.
---@field private _rang integer The rank of the node.
local DSet = {
    -- Public
    data = nil,
    -- Private
    _parent = {},
    _rang = 0
}

-- Constructor for creating a new representative disjoint set.
---@return DSet # A new disjoint set.
function DSet:new(o)
    o = o or { data = nil, _parent = nil, _rang = 0 }
    o._parent = o
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Constructor for creating a new representative disjoint set with user data.
---@param data any The user data associated with the set.
---@return DSet # A new disjoint set.
function DSet:makeSet(data)
    return DSet:new { data = data, _parent = nil, _rang = 0 }
end

-- Union operation to merge two disjoint sets under a unique representative disjoint set.
---@param other DSet The other disjoint set to be united with the current set.
function DSet:union(other)
    local root = self:find()
    local other_root = other:find()
    -- The underlying tree is balanced by rank
    if root ~= other_root then
        if root._rang < other._rang then
            root._parent = other_root
        else
            other_root._parent = root
            if root._rang == other_root._rang then
                root._rang = root._rang + 1
            end
        end
    end
end

-- Find operation to get the representative disjoint set of this set.
---@return DSet # The representative disjoint set of this set.
function DSet:find()
    -- Find the root of the set and applies path compression,
    -- making future lookups faster by making the entire path point to the root.
    if self._parent ~= self then
        self._parent = self._parent:find()
    end
    return self._parent
end

-- Check to see if two sets are effectively merged together.
---@param other DSet The other disjoint set to compare with the current set.
---@return boolean # True if both sets are connected (i.e., have the same representative disjoint set), false otherwise.
function DSet:connected(other)
    return self:find() == other:find()
end

--[[ PUBLIC ]]

-- Returns a new representative disjoint set.
---@return DSet # A new disjoint set.
function dSet.new()
    return DSet:new()
end

-- Returns a new representative disjoint set with user data.
---@param data any The user data associated with the set.
---@return DSet # A new disjoint set.
function dSet.makeSet(data)
    return DSet:makeSet(data)
end

return dSet

end
files['ccmaze.utils.optFunc'] = function(...)
---@module 'ccmaze.utils.optFunc'
local optFunc = {}

--[[ PUBLIC ]]

---@param f function An optional function with one argument.
---@return function # A callable function with one argument.
function optFunc.create1(f)
    return (f or function(_) end)
end

return optFunc

end
files['ccmaze.utils.shuffle'] = function(...)
---@module 'ccmaze.utils.shuffle'
local shuffle = {}

--[[ PRIVATE ]]

-- Randomize order of element in a list
---@param t table The table to shuffle.
local function _shuffleInPlace(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

--[[ PUBLIC ]]

-- Randomize order of element in a list
---@param t table The table to shuffle.
function shuffle.inPlace(t)
  _shuffleInPlace(t)
end

return shuffle

end
files['ccmaze.utils.stack'] = function(...)
--[[
    A small wrapper around lua table to use them as
    a stack.
--]]

local stack = {}

--[[ PRIVATE ]]

local shuffle = require "ccmaze.utils.shuffle"

---@class Stack A simple stack object.
---@field private _data table The underlying stack storage.
local Stack = {
    _data = {}
}

-- Constructor for creating a new stack.
---@return Stack # A new empty stack.
function Stack:new(o)
    o = o or { _data = {} }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Constructor for creating a new prefilled stack.
---@param t table The data to use with this stack.
---@return Stack # A new prefilled stack.
function Stack:makeStack(t)
    return Stack:new { _data = t }
end

-- Check if the stack is empty.
---@return boolean # True if the stack is empty.
function Stack:isEmpty()
    return #self._data == 0
end

-- Get the number of elements in the stack.
---@return integer size The number of elements in the stack.
function Stack:size()
    return #self._data
end

-- Add an element to the top of the stack.
---@param elem any The thing to add on the stack.
function Stack:push(elem)
    table.insert(self._data, elem)
end

-- Removes and returns the top element in the stack.
---@return any head The top element in the stack.
function Stack:pop()
    return table.remove(self._data)
end

-- Removes and returns the top element in the stack if possible
-- or return the provided default value.
---@param default any The default value to return if the stack is empty.
---@return any head The top element in the stack.
function Stack:popOr(default)
    if #self._data > 0 then
        return table.remove(self._data)
    else
        return default
    end
end

-- Returns the top element without altering the stack.
---@return any head The last element in the stack.
function Stack:peek()
    return self._data[#self._data]
end

-- Returns the top element without altering the stack if possible
-- or return the provided default value.
---@param default any The default value to return if the stack is empty.
---@return any head The last element in the stack.
function Stack:peekOr(default)
    if #self._data > 0 then
        return self._data[#self._data]
    else
        return default
    end
end

-- Randomize the element order in the stack.
function Stack:shuffle()
    shuffle.inPlace(self._data)
end

--[[ PUBLIC ]]

---@return Stack # A new empty stack.
function stack.new()
    return Stack:new()
end

---@param t table The data to use with this stack.
---@return Stack # A new prefilled stack.
function stack.makeStack(t)
    return Stack:makeStack(t)
end

return stack

end
return ccmaze