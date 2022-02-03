--- The current
local version = vim.version()

--- The Cargorapher Lua-callbacks registrant
--- TODO: delete this module when `0.7` is stabilized
--- @type Cartographer.Callbacks|nil
local Callbacks = (version.major == 0 and version.minor < 7) and require 'cartographer.callbacks'

--- Return an empty table with all necessary fields initialized.
--- @return table
local function new() return {_modes = {}, _opts = {}} end

--- Make a deep copy of opts table
--- @param tbl table the table to copy
--- @return table copy
local function copy(tbl)
	local new_tbl = new()

	new_tbl._hook = rawget(tbl, '_hook')
	for i, val in ipairs(rawget(tbl, '_modes')) do
		new_tbl._modes[i] = val
	end

	for key, val in pairs(rawget(tbl, '_opts')) do
		new_tbl._opts[key] = val
	end

	return new_tbl
end

--- A fluent interface to create more straightforward syntax for Lua |:map|ping and |:unmap|ping.
--- @class Cartographer
--- @field buffer number the buffer to apply the keymap to.
--- @field _hook function|nil something to call after creating the keymap.
--- @field _modes table the modes to apply a keymap to.
--- @field _opts table the options to use when creating the keymapping.
local Cartographer = {}

--- Register some `fn` to be called when creating a new keymapping.
--- Has the same parameters as |nvim_buf_set_keymap|.
--- The first parameter passed to `fn` will be `nil` when the mapping is not buffer-local.
--- @param fn function the function to call when setting a keymapping.
function Cartographer:hook(fn)
	self = copy(self)
	self._hook = fn
	return setmetatable(self, Cartographer)
end

--- Set `key` to `true` if it was not already present
--- @param key string the setting to set to `true`
--- @returns table self so that this function can be called again
function Cartographer:__index(key)
	if key ~= 'hook' then
		self = copy(self)

		if #key < 2 then -- set the mode
			self._modes[#self._modes+1] = key
		elseif #key > 5 and key:sub(1, 1) == 'b' then -- PERF: 'buffer' is the only 6-letter option starting with 'b'
			self = copy(self)
			self.buffer = #key > 6 and tonumber(key:sub(7)) or 0 -- NOTE: 0 is the current buffer
		else -- the fluent interface
			self = copy(self)
			self._opts[key] = true
		end

		return setmetatable(self, Cartographer)
	end

	return Cartographer.hook
end

--- Set a `lhs` combination of keys to some `rhs`
--- @param lhs string the left-hand side |key-notation| which will execute `rhs` after running this function
--- @param rhs string|nil if `nil`, |:unmap| lhs. Otherwise, see |:map|.
function Cartographer:__newindex(lhs, rhs)
	local buffer = rawget(self, 'buffer')
	local hook = rawget(self, '_hook')

	local modes = rawget(self, '_modes')
	modes = #modes > 0 and modes or {''}

	local opts = rawget(self, '_opts')
	opts.noremap = opts.nore
	opts.nore = nil

	if rhs then
		if type(rhs) == 'function' then
			if Callbacks then -- TODO: remove when `0.7` is stabilized
				local id = Callbacks.new(rhs)
				rhs = opts.expr and
					'luaeval("require(\'cartographer.callbacks\')['..id..']")()' or
					'<Cmd>lua require("cartographer.callbacks")['..id..']()<CR>'
			else
				opts.callback = rhs
				rhs = ''
			end
			opts.noremap = true
		end

		if buffer then
			for _, mode in ipairs(modes) do
				vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
			end
		else
			for _, mode in ipairs(modes) do
				vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
			end
		end
	else
		if buffer then
			for _, mode in ipairs(modes) do
				vim.api.nvim_buf_del_keymap(buffer, mode, lhs)
			end
		else
			for _, mode in ipairs(modes) do
				vim.api.nvim_del_keymap(mode, lhs)
			end
		end
	end

	if hook then
		hook(buffer, modes, lhs, rhs, opts)
	end
end

return setmetatable(new(), Cartographer)
