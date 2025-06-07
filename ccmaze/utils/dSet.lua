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
    return DSet:new { data = data, _parent = nil, _rang = 0 }
end

return dSet
