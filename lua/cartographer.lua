--- The Neovim API
local api = vim.api
local Callbacks = require 'cartographer.callbacks'

-- Make a deep copy of opts table
local function copy_opts(tbl)
	local new_tbl = {_mode = {}}
	for key, val in pairs(tbl) do
		if key ~= '_mode' then new_tbl[key] = val
		else for k, v in pairs(tbl._mode) do new_tbl._mode[k] = v end
		end
	end
	return new_tbl
end

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
				opts = copy_opts(opts)
				opts._mode[key] = true
				return setmetatable({opts = opts}, MetaCartographer)
			end
		else -- the builder
			if not opts[key] then -- the builder
			-- if true then return self end
				opts = copy_opts(opts)
				if key:sub(1,6) ~= 'buffer' then
					opts[key] = true
				else -- Handels buffer option
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
		else -- Remove keymap
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
