---@module 'libmaze.utils.optFunc'
local optFunc = {}

--[[ PUBLIC ]]

---@param f function An optional function with one argument.
---@return function # A callable function with one argument.
function optFunc.create1(f)
    return (f or function(_) end)
end

return optFunc
