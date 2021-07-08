--- The Neovim API
local api = vim.api
local Callbacks = require 'cartographer.callbacks'

--- The tool for building `:map`s. Used as a metatable.
local MetaCartographer
MetaCartographer =
{
	--- Set `key` to `true` if it was not already present
	--- @param self table the collection of settings
	--- @param key string the setting to set to `true`
	--- @returns table self so that this function can be called again
	__index = function(self, key)
		local opts = rawget(self, 'opts')
		if #key < 2 then -- set the mode
			if not opts._mode[key] then
				opts = vim.deepcopy(opts)
				opts._mode[key] = true
				return setmetatable({opts = opts}, MetaCartographer)
			end
		else -- the builder
			if not opts[key] then -- the builder
				opts = vim.deepcopy(opts)
				if not vim.startswith(key, 'buffer') then
					opts[key] = true
				else
					local bufnr = tonumber(key:sub(7))
					opts.buffer = bufnr or 0
				end
				return setmetatable({opts = opts}, MetaCartographer)
			end
		end
		return self
	end,

	--- Set a `lhs` combination of keys to some `rhs`
	--- @param self table the collection of settings and the mode
	--- @param lhs string the left-hand side |key-notation| which will execute `rhs` after running this function
	--- @param rhs string if `nil`, |:unmap| lhs. Otherwise, see |:map|.
	__newindex = function(self, lhs, rhs)
		local opts = rawget(self, 'opts')
		local buffer = opts.buffer
		local modes = next(opts._mode) and opts._mode or {[''] = true}

		if rhs then
			local keymap_opts = {
				expr = opts.expr,
				noremap = opts.nore,
				nowait = opts.nowait,
				script = opts.script,
				silent = opts.silent,
				unique = opts.unique,
			}

			if type(rhs) == 'function' then
				local id = Callbacks.new(rhs)
				rhs = '<Cmd>lua require("cartographer.callbacks")['..id..']()<CR>'
				keymap_opts.noremap = true
			end

			for mode, _ in pairs(modes) do
				if buffer then
					api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, keymap_opts)
			else
					api.nvim_set_keymap(mode, lhs, rhs, keymap_opts)
				end
			end
		else
			for mode, _ in pairs(modes) do
				if buffer then
					api.nvim_buf_del_keymap(buffer, mode, lhs)
				else
				api.nvim_del_keymap(mode, lhs)
				end
			end
		end
	end,
}

--- A Neovim plugin to create more straightforward syntax for Lua `:map`ping and `:unmap`ping.
--- @module nvim-cartographer
--- @return table Cartographer a builder for `:map` / `:unmap` interaction
return setmetatable({},
{
	-- NOTE: For backwards compatability. `__index` is preferred.
	__call = function(_) return setmetatable({opts={_mode = {}}}, MetaCartographer) end,
	__index = function(_, key) return setmetatable({opts={_mode = {}}}, MetaCartographer)[key] end,
})
