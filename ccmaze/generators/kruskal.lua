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
