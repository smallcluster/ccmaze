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
