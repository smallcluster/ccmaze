---@module 'libmaze.filters.builder'
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
