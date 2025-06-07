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
    return Stack:new { _data = t }
end

return stack
