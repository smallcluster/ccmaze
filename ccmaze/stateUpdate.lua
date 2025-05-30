---@module 'libmaze.stateUpdate'
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
