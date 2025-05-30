local maze = require("libmaze.maze")
local kg = require("libmaze.generators.kruskal")

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

local m = maze.new(20, 20, kg.new(20,20):producer())

print(dump(m.cells))