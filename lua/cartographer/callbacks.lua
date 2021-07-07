--- A Neovim plugin to create more straightforward syntax for Lua `:map`ping and `:unmap`ping.
--- @module callbacks
--- @alias Callbacks table
local Callbacks = setmetatable({register = {}},
{
	__index = function(self, k) return rawget(self, k) or self.register[k] end
})

--- Register a callback to be
--- @param cb function the callback
--- @return number id the handle of the callback
function Callbacks.new(cb)
	table.insert(Callbacks.register, cb)
	return #Callbacks.register
end

return Callbacks
