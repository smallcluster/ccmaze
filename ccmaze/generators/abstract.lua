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
