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
