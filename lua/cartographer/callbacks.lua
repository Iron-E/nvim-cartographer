--- A Neovim plugin to create more straightforward syntax for Lua `:map`ping and `:unmap`ping.
--- @class Cartographer.Callbacks
local Callbacks = {}

--- Register a callback to be
--- @param cb function the callback
--- @return number id the handle of the callback
function Callbacks.new(cb)
	Callbacks[#Callbacks+1] = cb
	return #Callbacks
end

return Callbacks
