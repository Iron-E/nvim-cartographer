--- The Neovim API
local api = vim.api

--- The Cargorapher Lua-callbacks registrant
local Callbacks = require 'cartographer.callbacks'

--- Return an empty table with all necessary fields initialized.
--- @return table
local function new() return {_modes = {}} end

--- Make a deep copy of opts table
--- @param tbl table the table to copy
local function copy(tbl)
	local new_tbl = new()

	for key, val in pairs(tbl) do
		if key ~= '_modes' then new_tbl[key] = val
		else for i, mode in ipairs(tbl._modes) do new_tbl._modes[i] = mode end
		end
	end

	return new_tbl
end

--- The fluent interface `:map`s. Used as a metatable.
local MetaCartographer
MetaCartographer =
{
	--- Set `key` to `true` if it was not already present
	--- @param self table the collection of settings
	--- @param key string the setting to set to `true`
	--- @returns table self so that this function can be called again
	__index = function(self, key)
		self = copy(self)

		if #key < 2 then -- set the mode
			self._modes[#self._modes+1] = key
		elseif #key > 5 and key:sub(1, 1) == 'b' then -- PERF: 'buffer' is the only 6-letter option starting with 'b'
			self.buffer = #key > 6 and tonumber(key:sub(7)) or 0 -- NOTE: 0 is the current buffer
		else -- the fluent interface
			self[key] = true
		end

		return setmetatable(self, MetaCartographer)
	end,

	--- Set a `lhs` combination of keys to some `rhs`
	--- @param self table the collection of settings and the mode
	--- @param lhs string the left-hand side |key-notation| which will execute `rhs` after running this function
	--- @param rhs string if `nil`, |:unmap| lhs. Otherwise, see |:map|.
	__newindex = function(self, lhs, rhs)
		local buffer = rawget(self, 'buffer')
		local modes = rawget(self, '_modes')
		modes = #modes > 0 and modes or {''}

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

			-- Handle term codes
			if opts.expr then
				local original_rhs = rhs
				if type(rhs) == 'string' then
					rhs = function()
						return vim.api.nvim_replace_termcodes(vim.fn.eval(original_rhs), true, false, true)
					end
				elseif type(rhs) == 'function' then
					rhs = function()
						return vim.api.nvim_replace_termcodes(original_rhs(), true, false, true)
					end
				end
			end

			if type(rhs) == 'function' then
				local id = Callbacks.new(rhs)
				rhs = opts.expr and
					'luaeval("require(\'cartographer.callbacks\')['..id..']")()' or
					'<Cmd>lua require("cartographer.callbacks")['..id..']()<CR>'
				opts.noremap = true
			end

			if buffer then
				for _, mode in ipairs(modes) do
					api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
				end
			else
				for _, mode in ipairs(modes) do
					api.nvim_set_keymap(mode, lhs, rhs, opts)
				end
			end
		else
			if buffer then
				for _, mode in ipairs(modes) do
					api.nvim_buf_del_keymap(buffer, mode, lhs)
				end
			else
				for _, mode in ipairs(modes) do
					api.nvim_del_keymap(mode, lhs)
				end
			end
		end
	end,
}

--- A Neovim plugin to create more straightforward syntax for Lua `:map`ping and `:unmap`ping.
--- @module nvim-cartographer
--- @return table Cartographer a fluent interface for `:map` / `:unmap` interaction
return setmetatable(new(),
{
	-- NOTE: For backwards compatability. `__index` is preferred.
	__call = function(_) return setmetatable(new(), MetaCartographer) end,
	__index = function(_, key) return setmetatable(new(), MetaCartographer)[key] end,
	__newindex = MetaCartographer.__newindex,
})
