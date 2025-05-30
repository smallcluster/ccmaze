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
