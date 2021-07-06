--- The Neovim API
local api = vim.api

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
		local mode = self:mode()

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
--- @alias Cartographer function
--- @return table Cartographer a builder for `:map` / `:unmap` interation
return function()
	return setmetatable(
		{
			--- @param self table this table, which contains the current mode.
			--- @return string mode the current mode being mapped too.
			mode = function(self)
				local primary_mode = rawget(self, 'c') and 'c'
					or rawget(self, 'i') and 'i'
					or rawget(self, 'ic') and 'ic'
					or rawget(self, 'l') and 'l'
					or rawget(self, 'n') and 'n'
					or rawget(self, 'nvo') and 'nvo'
					or rawget(self, 'o') and 'o'
					or rawget(self, 's') and 's'
					or rawget(self, 't') and 't'
					or rawget(self, 'v') and 'v'
					or rawget(self, 'x') and 'x'
					or ''

				return rawget(self, '!') and primary_mode..'!' or primary_mode
			end,
		},
		MetaCartographer
	)
end
