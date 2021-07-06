--- The Neovim API
local api = vim.api

--- @param self table this table, which contains the current mode.
--- @return string mode the current mode being mapped too.
local function get_mode(cartographer)
	local primary_mode = rawget(cartographer, 'c') and 'c'
		or rawget(cartographer, 'i') and 'i'
		or rawget(cartographer, 'ic') and 'ic'
		or rawget(cartographer, 'l') and 'l'
		or rawget(cartographer, 'n') and 'n'
		or rawget(cartographer, 'nvo') and 'nvo'
		or rawget(cartographer, 'o') and 'o'
		or rawget(cartographer, 's') and 's'
		or rawget(cartographer, 't') and 't'
		or rawget(cartographer, 'v') and 'v'
		or rawget(cartographer, 'x') and 'x'
		or ''

	return rawget(cartographer, '!') and primary_mode..'!' or primary_mode
end

--- The tool for building `:map`s. Used as a metatable.
local MetaCartographer =
{
	--- Set `key` to `true` if it was not already present
	--- @param self table the collection of settings
	--- @param key string the setting to set to `true`
	--- @returns table self so that this function can be called again
	__index = function(self, key)
		if not rawget(self, key) then -- the builder
			rawset(self, key, true)
		end
		return self
	end,

	--- Set a `lhs` combination of keys to some `rhs`
	--- @param self table the collection of settings and the mode
	--- @param lhs string the left-hand side |key-notation| which will execute `rhs` after running this function
	--- @param rhs string if `nil`, |:unmap| lhs. Otherwise, see |:map|.
	__newindex = function(self, lhs, rhs)
		local buffer = rawget(self, 'buffer')
		local mode = get_mode(self)

		if rhs then
			local opts =
			{
				expr = rawget(self, 'expr'),
				noremap = rawget(self, 'nore'),
				nowait = rawget(self, 'nowait'),
				script = rawget(self, 'script'),
				silent = rawget(self, 'silent'),
				unique = rawget(self, 'unique'),
			}

			if buffer then
				return api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
			else
				return api.nvim_set_keymap(mode, lhs, rhs, opts)
			end
		else
			if buffer then
				return api.nvim_buf_del_keymap(0, mode, lhs)
			else
				return api.nvim_del_keymap(mode, lhs)
			end
		end
	end,
}

--- A Neovim plugin to create more straightforward syntax for Lua `:map`ping and `:unmap`ping.
--- @module nvim-cartographer
--- @return table Cartographer a builder for `:map` / `:unmap` interaction
return function() return setmetatable({}, MetaCartographer) end
