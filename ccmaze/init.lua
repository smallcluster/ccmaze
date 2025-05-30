--[[
    This provide an interface to require modules in the ccmaze package.
    This is useful to replace the modularised library with the minified version
    without changing the require statements in the user code.
--]]

return {require = require}